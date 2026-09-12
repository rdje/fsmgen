"""Join retained cases without invoking any old main or fixture producer."""
from collections import Counter
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name


def load(path):
    return json.loads(path.read_bytes())


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


def signature(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def rejects(action):
    try:
        action()
    except (AssertionError, KeyError, TypeError, ValueError, IndexError):
        return True
    return False


def key(domain, profile, control, occurrence=None, phase=None, role='primary'):
    return (domain, profile, control, occurrence, phase, role)


def required_domain(original, corrected):
    required = {}
    for profile, correction in zip(original['profiles'], corrected['profiles'], strict=True):
        assert profile['id'] == correction['id']
        for control, occurrence in [('healthy', None), ('one-byte', 0)]:
            required[key('readback', profile['id'], control, occurrence)] = True
        for source, body in zip(profile['sources'], correction['body_xor'], strict=True):
            assert source['occurrence'] == body['occurrence']
            for control in ('first-eio', 'partial-eio', 'early-eof', 'body-xor'):
                required[key('readback', profile['id'], control, source['occurrence'])] = bool(
                    control == 'body-xor' and body['expected_success'])
    for profile in original['syscall_healthy_profiles']:
        required[key('syscall', profile, 'healthy')] = True
    for report in original['syscall_reports']:
        required[key('syscall', report['profile'], report['control'], phase=report['phase'])] = False
    assert len(required) == corrected['total_proposed_cases']
    assert sum(required.values()) == corrected['expected_successes']
    return required


def case_key(partition, plan, case):
    selector = case['selector']
    if partition['domain'] == 'syscall':
        return key('syscall', case['profile_id'], 'healthy' if selector is None else selector['control'],
                   phase=None if selector is None else selector['phase'])
    return key('readback', plan['profile_id'], 'healthy' if selector is None else selector['control'],
               None if selector is None else selector['occurrence'], role=case['role'])


def coverage(required, observed, counterexamples):
    assert len(observed) == len(required) and len(dict(observed)) == len(observed)
    assert dict(observed) == required
    assert len(counterexamples) == 1
    ident, success = counterexamples[0]
    assert ident == key('readback', 'ordinary_retired_other_observation', 'first-eio', 0, role='seam_counterexample')
    assert success is False and ident not in required


def independent_counts(row, partition):
    """Count physical records directly, without using the scope oracle's totals."""
    op = row['operation']; reader = op.get('readback')
    counts = Counter(cases=1, calls=len(op['boundary_calls']), events=len(op['events']),
        handles=len(op['handles']), reads=len(op['reads']),
        sources=sum(h['kind'] == 'source' for h in op['handles']),
        directories=sum(h['kind'] == 'directory' for h in op['handles']),
        locks=sum(h['kind'] == 'lock' for h in op['handles']))
    assert all(h['actual_close_ok'] == h['closed_after_call'] == h['closed_at_return'] == 1 for h in op['handles'])
    counts['unlinks'] = sum(u['actual_count'] for u in op['unlinks'])
    if partition['domain'] == 'readback':
        primary = row['matrix_case']['role'] == 'primary'
        counts.update(primary_cases=int(primary), primary_successes=int(primary and op['result']['success']),
            primary_rejections=int(primary and not op['result']['success']), seam_counterexamples=int(not primary))
        if reader is not None:
            selected = row['matrix_case']['selector']; strong = selected['strong_alias']
            failed = not reader['reader_returned']
            counts.update(selected_reader_calls=1, failed_reader_calls=int(failed), returned_reader_calls=int(not failed),
                unreturned_reader_lexical_closes=int(failed and not strong), observed_read_calls=len(reader['reads']),
                strong_counterexample_recoveries=len(reader['recovery']), strong_bias_detected=int(bool(strong)))
            for read in reader['reads']:
                actual = read['actual']
                counts['controlled_read_reports'] += int(actual is None)
                if actual is not None:
                    counts['actual_read_syscalls'] += 1
                    counts['actual_read_bytes'] += len(bytes.fromhex(actual['buffer']['bytes_hex']))
                    assert actual['count'] == len(bytes.fromhex(actual['buffer']['bytes_hex']))
            counts['observer_duplicates_closed'] += sum(
                p is not None and p['duplicate'] is not None and p['duplicate_close']['returned'] == 1
                for p in (reader['at_reader_return'], reader['at_release_return'], reader['after_recovery']))
    else:
        trace = op['syscall_trace']
        counts.update(successes=op['result']['success'], rejections=1 - op['result']['success'],
            unlink_syscalls=trace['unlink']['actual']['executed'],
            suppressed_unlinks=1 - trace['unlink']['actual']['executed'],
            absence_syscalls=len(trace['absence']), modeled_reports=trace['hits'])
    return counts


def authenticate_saved_copies(directory, prepare):
    records = load(directory / 'result/recovery-copies.json')
    assert len({r['destination'] for r in records}) == len(records)
    for record in records:
        path = ROOT / record['destination']
        assert path.is_relative_to(directory)
        raw = prepare.safe_bytes(path)
        assert len(raw) == record['size_bytes'] and hashlib.sha256(raw).hexdigest() == record['sha256']
    return dict(copies=len(records), bytes=sum(r['size_bytes'] for r in records))


def root_closure(roots, previous):
    paths = [r['path'] for r in roots]
    assert len(paths) == len(set(paths)) and not set(paths) & set(previous)
    assert len(previous) == len(set(previous))
    for relative in paths + previous:
        path = Path(relative)
        assert not path.is_absolute() and '..' not in path.parts and relative.startswith('.artifacts/')
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'], ['--admit-only'])
    prepare = module('joined_source_preparation', BASE / 'prepare.py')
    plan = load(BASE / 'plan.json')
    assert plan == prepare.build()
    pins = load(BASE / 'preflight-pins.json')
    assert pins == [prepare.pin(BASE / n) for n in ('prepare.py', 'prepare-pins.json', 'plan.json', 'audit.py')]
    if sys.argv[1:] == ['--admit-only']:
        print(json.dumps(dict(admitted=True, inputs=len(plan['inputs']), allocated_fixtures=0)))
        return
    original_path = BASE.parent / prepare.SELECTION
    original = load(original_path / 'plan.json')
    healthy = load(ROOT / original['healthy_input'])
    original_audit = module('joined_original_domain', original_path / 'audit.py')
    original_audit.authenticate(original); original_audit.domain(original, healthy)
    original_falsifiers = original_audit.falsify(original, healthy)
    correction_path = BASE.parent / prepare.APPLICABILITY
    corrected = load(correction_path / 'applicability.json')
    correction_audit = module('joined_corrected_applicability', correction_path / 'audit.py')
    correction_audit.authenticate(corrected, original); correction_audit.domain(corrected, original, healthy)
    correction_falsifiers = correction_audit.falsify(corrected, original, healthy)
    required = required_domain(original, corrected)
    support = module('joined_source_support', BASE.parent / 'native-proxy-observation-archive-release-ordinary-before-20260911/audit.py')
    ordinary_dir = BASE.parent / prepare.READBACK[0]
    shared = module('joined_shared_readback_audit', ordinary_dir / 'audit-corrected.py')
    read_oracle = module('joined_readback_scope', ordinary_dir / 'expected_trace.py')
    observed, counters, roots, partitions, root_reports = [], [], [], [], []
    first_short = None
    for partition in plan['partitions']:
        directory = ROOT / partition['directory']
        current = load(directory / 'plan.json'); report = load(directory / 'result/qualification.json')
        audit = shared if directory == ordinary_dir else module('joined_' + directory.name.replace('-', '_'), directory / partition['audit'])
        audit.domain(current); current_pins = audit.authenticate(current)
        if partition['domain'] == 'readback':
            audit.SHARED = shared
            if directory == ordinary_dir: audit.authenticate_correction()
            prerequisite = audit.prerequisites(support)
            audit.header(current, report, support)
            oracle = read_oracle
        else:
            audit.header(current, report, current_pins, support)
            first_header = module('joined_first_syscall_header', directory / 'audit.py')
            assert rejects(lambda: first_header.header(current, report, current_pins, support))
            correction = load(directory / 'result/correction-preflight.json')
            assert correction['success'] is True and correction['source_diff_exact'] is True
            assert correction['original_header_rejects'] is True and correction['corrected_header_accepts'] is True
            oracle = module('joined_syscall_scope', directory / 'expected_trace.py')
            prerequisite = load(directory / 'result/oracle-preflight/oracle-preflight.json')
            assert prerequisite['success'] is True and prerequisite['prospective_pins'] == current_pins
            assert [c['case'] for c in prerequisite['comparisons']] == [c['name'] for c in current['cases']]
        totals, independent, current_roots = Counter(), Counter(), []
        for case, receipt in zip(current['cases'], report['case_files'], strict=True):
            row = support.read_case(directory / 'result', receipt)
            counts, allocated = audit.verify_row(current, case, row, support, oracle)
            direct = independent_counts(row, partition)
            for field, value in direct.items():
                if field == 'cases' or (partition['domain'] == 'syscall' and field == 'unlinks'):
                    continue
                assert counts[field] == value, (directory.name, case['index'], field)
            totals.update(counts); independent.update(direct); current_roots.extend(allocated)
            ident = case_key(partition, current, case)
            success = bool(row['operation']['result']['success'])
            assert int(success) == case['expected_success']
            (observed if ident[-1] == 'primary' else counters).append((ident, success))
            if directory == ordinary_dir and case['index'] == 1:
                first_short = (current, case, row)
        assert report['allocated'] == current_roots
        assert [json.loads(line) for line in (directory / 'result/admission.jsonl').read_text().splitlines()] == current_roots
        expected_files = {'case-%04d.json' % c['index'] for c in current['cases']}
        assert {p.name for p in (directory / 'result/cases').iterdir()} == expected_files
        assertions = 25 + len(current['cases']) * 11
        support.tap(directory / 'result/qualify.tap', assertions)
        assert (directory / 'result/qualify.exit').read_bytes() == b'0\n'
        published = load(directory / 'result/audit.json')
        assert published['success'] is True and published['assertions'] == assertions
        reference = published['totals'] if partition['domain'] == 'syscall' else published
        assert all(reference[field] == value for field, value in totals.items())
        recovery = authenticate_saved_copies(directory, prepare)
        row_falsifiers = published['falsifiers'] if partition['domain'] == 'syscall' else published['row_falsifiers']
        assert row_falsifiers and len(row_falsifiers) == len(set(row_falsifiers))
        partitions.append(dict(directory=partition['directory'], totals=dict(totals), independent_counts=dict(independent),
            assertions=assertions, case_bytes=sum(r['size_bytes'] for r in report['case_files']),
            recovery=recovery, retained_row_falsifiers=len(row_falsifiers), prerequisite=prerequisite if partition['domain'] == 'readback' else dict(comparisons=len(prerequisite['comparisons']))))
        roots.extend(current_roots)
        for path in current['previous_root_reports']:
            if path not in root_reports: root_reports.append(path)
    coverage(required, observed, counters)
    current_reports = {p['directory'] + '/result/qualification.json' for p in plan['partitions']}
    previous = [r['path'] for path in root_reports if path not in current_reports for r in load(ROOT / path)['allocated']]
    root_closure(roots, previous)
    # Preserve and re-demonstrate the original successful-open errno correction.
    first = module('joined_first_errno_audit', ordinary_dir / 'audit.py')
    assert rejects(lambda: first.verify_row(*first_short, support, read_oracle))
    shared.verify_row(*first_short, support, read_oracle)
    controls = []
    for name, mutate in [('omitted-primary', lambda o: o.pop()),
                         ('duplicated-primary', lambda o: o.__setitem__(1, o[0])),
                         ('wrong-success-allocation', lambda o: o.__setitem__(0, (o[0][0], not o[0][1])))]:
        bad = copy.deepcopy(observed); mutate(bad)
        assert rejects(lambda: coverage(required, bad, counters)); controls.append(name)
    assert rejects(lambda: coverage(required, observed + counters, [])); controls.append('counterexample-as-primary')
    assert rejects(lambda: coverage(required, observed, counters * 2)); controls.append('repeated-strong-witness')
    assert rejects(lambda: root_closure(roots + roots[:1], previous)); controls.append('duplicate-current-root')
    assert rejects(lambda: root_closure(roots, previous + [roots[0]['path']])); controls.append('old-new-root-overlap')
    result = dict(schema='fsmgen.release_readback_join.v1', success=True, execution_qualified=True,
        runtime_authorized=False, source_revision=prepare.REVISION, prospective_pins=pins,
        input_files=len(plan['inputs']), input_bytes=sum(r['size_bytes'] for r in plan['inputs']),
        primary_cases=len(observed), primary_successes=sum(v for _, v in observed),
        primary_rejections=sum(not v for _, v in observed), seam_counterexamples=len(counters),
        assertions=sum(p['assertions'] for p in partitions), primary_domain_sha256=signature(sorted(observed)),
        partitions=partitions, selected_roots_absent=len(roots), prior_roots_absent=len(previous),
        original_domain_falsifiers=original_falsifiers, corrected_applicability_falsifiers=correction_falsifiers,
        join_falsifiers=controls, earlier_falsifiers='Source and exact saved verdicts authenticated; selected per-row oracles rerun. Earlier main routines and their full embedded falsifier loops are not rerun.',
        new_fixture_roots=0, scope=plan['scope'])
    if sys.argv[1:] == ['--verify-saved']:
        assert result == load(BASE / 'result/join.json')
    else:
        with (LOG / 'join.json').open('x') as output: output.write(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps({k: v for k, v in result.items() if k not in ('partitions', 'prospective_pins')}, sort_keys=True))


if __name__ == '__main__':
    main()
