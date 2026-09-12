"""Join retained composition evidence without invoking old mains or fixtures."""
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


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


def load(path):
    return json.loads(path.read_bytes())


def signature(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def rejects(action):
    try:
        action()
    except (AssertionError, KeyError, TypeError, ValueError, IndexError, StopIteration):
        return True
    return False


def case_key(profile, recipe):
    return (profile, recipe['kind'], recipe['scope'], recipe['order'])


def coverage(required, observed):
    assert len(observed) == len(required) == len(dict(observed))
    assert dict(observed) == required


def receipt(record, catalog):
    expected = catalog[record['path']]
    assert record == {k: expected[k] for k in ('path', 'size_bytes', 'sha256')}


def authenticate_epoch(prepare, directory, current, index, catalog, versions, audit):
    """Recheck original input rosters and Git identities with a flat catalog.

    This replaces recursive admission traversal only. Original domain, row,
    state and native-close oracles remain unchanged; no global is replaced.
    """
    revision = current['source_revision']
    if revision not in versions:
        versions[revision] = prepare.tree(revision)
    version = versions[revision]
    previous = BASE.parent / (prepare.SELECTION if index == 0 else prepare.PROFILES[index - 1])
    prior = load(previous / 'plan.json')
    prefix = str(previous.relative_to(ROOT)) + '/'
    paths = {r['path'] for r in prior['inputs']} | {p for p in version if p.startswith(prefix)}
    if index:
        state = (audit.PREPARE.EQUAL if index == 1 else audit.PREPARE.ACTIVE if index == 2 else audit.PREPARE.LAST)
        paths.add(str((state / 'audit.py').relative_to(ROOT)))
        if index == 3:
            paths.add(str((state / 'qualify.t').relative_to(ROOT)))
        paths.update(current['previous_root_reports'])
    assert [r['path'] for r in current['inputs']] == sorted(paths)
    for record in current['inputs']:
        receipt(record, catalog)
        historical = version[record['path']]
        assert historical['kind'] == 'blob' and historical['mode'] in ('100644', '100755')
        assert historical['oid'] == catalog[record['path']]['git_blob']
    names = audit.MAIN_NAMES if index == 0 else audit.PIN_NAMES
    pins = load(directory / 'preflight-pins.json')
    assert [r['path'] for r in pins] == [str((directory / n).relative_to(ROOT)) for n in names]
    extra_name = 'flow-preflight-pins.json' if index == 0 else 'oracle-pins.json'
    extra_names = audit.PURE_NAMES if index == 0 else audit.ORACLE.PIN_NAMES
    extra = load(directory / extra_name)
    assert [r['path'] for r in extra] == [str((directory / n).relative_to(ROOT)) for n in extra_names]
    single = [('prepare-pin.json', 'prepare.py'), ('qualifier-pin.json', 'qualify.t')]
    for manifest, source in single:
        record = load(directory / manifest)
        assert record['path'] == str((directory / source).relative_to(ROOT))
        receipt(record, catalog)
    for record in pins + extra:
        receipt(record, catalog)
    recover_pins = load(directory / 'recovery-pins.json')
    assert [r['path'] for r in recover_pins] == [str((directory / 'recover.py').relative_to(ROOT))]
    for record in recover_pins:
        receipt(record, catalog)
    return pins


def independent_counts(row):
    """Count actual physical records, independently of predicted aggregates."""
    op = row['operation']
    handles = op['handles']
    assert all(h['actual_close_ok'] == h['closed_after_call'] == h['closed_at_return'] == 1 for h in handles)
    reports = op['close_reports']
    assert all(r['actual_return'] == r['closed_after_call'] == 1 and r['actual_errno'] == 0 for r in reports)
    success = op['result']['success']
    unlinks = sum(r['actual_count'] for r in op['unlinks'])
    return dict(cases=1, calls=len(op['boundary_calls']), events=len(op['events']), handles=len(handles),
        sources=sum(h['kind'] == 'source' for h in handles),
        directories=sum(h['kind'] == 'directory' for h in handles), locks=sum(h['kind'] == 'lock' for h in handles),
        reads=len(op['reads']), close_reports=len(reports), modeled_reports=sum(r['report_applied'] for r in reports),
        healthy=success, failures=1 - success, unlinks=unlinks, post_unlink_failures=unlinks * (1 - success),
        call_primaries=op['injected_hits'], directory_primaries=sum(r['report_applied'] for r in op['directory_read_reports']))


def compare_reversal(left, right, left_trace, right_trace):
    a, b = copy.deepcopy(left), copy.deepcopy(right)
    assert a.pop('resolved_reports') == list(reversed(b.pop('resolved_reports')))
    assert a['witness'].pop('reports') == list(reversed(b['witness'].pop('reports')))
    assert a == b
    assert left_trace == right_trace


def reversal(core, current, case, row):
    if case['recipe']['kind'] == 'healthy':
        return None
    spec, _ = core.OLD.setup(row)
    calls = core.FLOW.derive(row['context'], row['operation']['before'], spec)
    recipe = dict(case['recipe'], order='reversed' if case['recipe']['order'] == 'observed' else 'observed')
    left = core.PREPARE.resolve(calls, row['context'], current['sealed_symbols'], case['recipe'])
    right = core.PREPARE.resolve(calls, row['context'], current['sealed_symbols'], recipe)
    a = core.TRACE.derive(calls, row['context'], current['sealed_symbols'], left, core.ERROR_TEXT)
    b = core.TRACE.derive(calls, row['context'], current['sealed_symbols'], right, core.ERROR_TEXT)
    assert a == core.PREFLIGHT.reference(calls, row['context'], current['sealed_symbols'], left)
    assert b == core.PREFLIGHT.reference(calls, row['context'], current['sealed_symbols'], right)
    compare_reversal(left, right, a, b)
    return left, right, a, b


def root_closure(roots, previous):
    paths = [r['path'] for r in roots]
    assert len(paths) == len(set(paths)) and len(previous) == len(set(previous))
    assert not set(paths) & set(previous)
    for relative in paths + previous:
        path = Path(relative)
        assert not path.is_absolute() and '..' not in path.parts and relative.startswith('.artifacts/')
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()


def retained_prerequisites(core, audit, directory, current, index, baseline, inherited):
    if index == 0:
        return inherited
    output = directory / 'result/preflight'
    copies = load(output / 'recovery.json')
    names = ['oracle.json', 'oracle.stdout', 'oracle.stderr', 'oracle.exit']
    assert [(r['source'], r['destination']) for r in copies] == [
        (str((ROOT / '.artifacts/logs' / directory.name / n).relative_to(ROOT)),
         str((output / n).relative_to(ROOT))) for n in names]
    for record in copies:
        actual = core.PREPARE.pin(ROOT / record['destination'])
        assert {k: record[k] for k in ('size_bytes', 'sha256')} == {k: actual[k] for k in ('size_bytes', 'sha256')}
    assert (output / 'oracle.exit').read_bytes() == b'0\n' and (output / 'oracle.stderr').read_bytes() == b''
    saved = load(output / 'oracle.json')
    assert saved['success'] is True and saved['fixture_allocations'] == 0 and saved['prior_identity_verified'] is True
    assert saved['source_revision'] == current['source_revision']
    assert saved['prospective_pins'] == load(directory / 'oracle-pins.json') and saved['inherited'] == inherited
    spec, _ = core.OLD.setup(baseline)
    calls = core.FLOW.derive(baseline['context'], baseline['operation']['before'], spec)
    predictions = []
    for case in current['cases']:
        resolved = core.PREPARE.resolve(calls, baseline['context'], current['sealed_symbols'], case['recipe'])
        a = core.TRACE.derive(calls, baseline['context'], current['sealed_symbols'], resolved, core.ERROR_TEXT)
        b = core.PREFLIGHT.reference(calls, baseline['context'], current['sealed_symbols'], resolved)
        assert a == b
        predictions.append(dict(index=case['index'], name=case['name'], resolved=resolved,
            prediction_sha256=core.SIGNATURE(b), success=b['success'], effects=b['effects'],
            handles=len(b['handles']), calls=len(b['calls'])))
    assert saved['predictions'] == predictions
    assert len(saved['falsifiers']) == len(set(saved['falsifiers'])) and saved['falsifiers']
    assert load(output / 'oracle.stdout') == audit.ORACLE.summary(saved)
    return dict(inherited=inherited, baseline_predictions=len(predictions),
        baseline_falsifiers=len(saved['falsifiers']), copies=len(copies))


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'], ['--admit-only'])
    prepare = module('composition_join_prepare', BASE / 'prepare.py')
    plan = load(BASE / 'plan.json')
    assert plan == prepare.build()
    pins = load(BASE / 'preflight-pins.json')
    assert pins == [prepare.pin(BASE / n) for n in ('prepare.py', 'prepare-pins.json', 'plan.json', 'audit.py')]
    if sys.argv[1:] == ['--admit-only']:
        print(json.dumps(dict(admitted=True, inputs=len(plan['inputs']), new_fixture_roots=0)))
        return
    selection_dir = BASE.parent / prepare.SELECTION
    selected = load(selection_dir / 'plan.json')
    selector = module('composition_join_selection', selection_dir / 'audit.py')
    boundary = load(selector.P.BOUNDARY / 'plan.json')
    baseline = load(selector.P.BOUNDARY / 'result/qualification.json')
    core = module('composition_join_shared_rows', BASE.parent / prepare.PROFILES[0] / 'audit.py')
    assert load(core.BASE / 'trace-adaptation.json') == core.trace_adaptation()
    inherited = core.prerequisites(load(core.BASE / 'flow-vectors.json'))
    required = {}
    for profile, original, row in zip(selected['profiles'], boundary['profiles'], baseline['cases'], strict=True):
        spec, _ = core.OLD.setup(row)
        calls = core.FLOW.derive(row['context'], row['operation']['before'], spec)
        selector.domain(profile, original, calls, row['context'], selected['sealed_symbols'])
        for case in profile['cases']:
            key = case_key(profile['id'], case['recipe'])
            assert key not in required
            required[key] = case['recipe']['kind'] == 'healthy'
    catalog = {r['path']: r for r in plan['inputs']}
    versions, observed, roots, partitions = {}, [], [], []
    totals, direct = Counter(), Counter()
    previous_reports = selected['previous_root_reports']
    previous = [r['path'] for path in previous_reports for r in load(ROOT / path)['allocated']]
    all_reports = list(previous_reports)
    pair_witness = epoch_witness = None
    reversal_count = 0
    for index, partition in enumerate(plan['partitions']):
        directory = ROOT / partition['directory']
        current = load(directory / 'plan.json')
        audit = core if index == 0 else module('composition_join_profile_' + str(index), directory / 'audit.py')
        audit.domain(current)
        assert current['profile_id'] == selected['profiles'][index]['id'] == partition['profile_id']
        assert current['owner'] == partition['owner'] == selected['profiles'][index]['owner']
        assert current['source_revision'] == partition['source_revision']
        assert current['previous_root_reports'] == all_reports
        current_pins = authenticate_epoch(prepare, directory, current, index, catalog, versions, audit)
        report = load(directory / 'result/qualification.json')
        audit.header(current, report, current_pins)
        prerequisite = retained_prerequisites(core, audit, directory, current, index, baseline['cases'][index], inherited)
        counts, independent, current_roots = Counter(), Counter(), []
        for case, saved in zip(current['cases'], report['case_files'], strict=True):
            row = core.SUPPORT.read_case(directory / 'result', saved)
            values, allocated = audit.verify_row(current, case, row)
            physical = independent_counts(row)
            assert all(values[k] == v for k, v in physical.items())
            counts.update(values); independent.update(physical); current_roots.extend(allocated)
            observed.append((case_key(current['profile_id'], case['recipe']), bool(row['operation']['result']['success'])))
            pair = reversal(core, current, case, row)
            if pair is not None:
                reversal_count += 1
                if pair_witness is None:
                    pair_witness = pair
        assert report['allocated'] == current_roots
        assert [json.loads(line) for line in (directory / 'result/admission.jsonl').read_text().splitlines()] == current_roots
        assert {p.name for p in (directory / 'result/cases').iterdir()} == {'case-%04d.json' % c['index'] for c in current['cases']}
        assertions = 25 + 13 * len(current['cases'])
        core.SUPPORT.tap(directory / 'result/qualify.tap', assertions)
        for name in ('prepare', 'syntax', 'admission', 'qualify', 'audit'):
            assert (directory / ('result/' + name + '.exit')).read_bytes() == b'0\n'
        published = load(directory / 'result/audit.json')
        assert published['success'] is True and published['totals'] == dict(counts)
        assert published['assertions'] == assertions and published['prospective_pins'] == current_pins
        assert published['source_revision'] == current['source_revision'] and published['input_files'] == len(current['inputs'])
        assert published['prerequisites'] == prerequisite and published['roots_absent'] == len(current_roots)
        assert published['prior_roots_absent'] == len(previous) + len(roots)
        case_bytes = sum(r['size_bytes'] for r in report['case_files'])
        assert published['case_bytes'] == case_bytes and published['scope'] == current['scope']
        for field in ('row_falsifiers', 'domain_falsifiers', 'header_falsifiers'):
            assert published[field] and len(published[field]) == len(set(published[field]))
        recover = module('composition_join_recovery_' + str(index), directory / 'recover.py')
        copies = load(directory / 'result/recovery-copies.json')
        assert copies == load(directory / 'result/recovery-plan.json')
        recover.verify(copies)
        partitions.append(dict(profile_id=current['profile_id'], directory=partition['directory'],
            totals=dict(counts), independent_counts=dict(independent), assertions=assertions, case_bytes=case_bytes,
            recovery=dict(copies=len(copies), bytes=sum(r['size_bytes'] for r in copies)),
            retained_row_falsifiers=len(published['row_falsifiers']), prerequisites=prerequisite))
        totals.update(counts); direct.update(independent); roots.extend(current_roots)
        all_reports.append(str((directory / 'result/qualification.json').relative_to(ROOT)))
        if epoch_witness is None:
            epoch_witness = directory, current, index, audit
        print(json.dumps(dict(profile=current['profile_id'], verified=True, cases=len(current['cases']))), file=sys.stderr, flush=True)
    coverage(required, observed)
    root_closure(roots, previous)
    assert reversal_count == sum(k[1] != 'healthy' for k, _ in observed)
    controls = []
    for name, mutate in (
        ('omitted-case', lambda rows: rows.pop()),
        ('duplicated-case', lambda rows: rows.__setitem__(1, rows[0])),
        ('wrong-outcome', lambda rows: rows.__setitem__(0, (rows[0][0], False))),
        ('foreign-profile', lambda rows: rows.__setitem__(0, (('foreign', *rows[0][0][1:]), rows[0][1]))),
        ('case-redistribution', lambda rows: rows.__setitem__(1, ((rows[1][0][0], 'healthy', *rows[1][0][2:]), rows[1][1]))),
    ):
        bad = copy.deepcopy(observed); mutate(bad)
        assert rejects(lambda: coverage(required, bad)), name
        controls.append(name)
    for name, mutate in (
        ('declaration-dependent-winner', lambda pair: pair[1]['witness'].update(winner=None)),
        ('changed-report-errno', lambda pair: pair[1]['resolved_reports'][0].update(errno='EIO' if pair[1]['resolved_reports'][0]['errno'] == 'ENOSPC' else 'ENOSPC')),
        ('changed-cleanup-order', lambda pair: pair[1]['witness']['cleanup_order'].reverse()),
        ('declaration-dependent-events', lambda pair: pair[3]['events'].pop()),
    ):
        bad = copy.deepcopy(pair_witness); mutate(bad)
        assert rejects(lambda: compare_reversal(*bad)), name
        controls.append(name)
    assert rejects(lambda: root_closure(roots + roots[:1], previous)); controls.append('duplicate-current-root')
    assert rejects(lambda: root_closure(roots, previous + [roots[0]['path']])); controls.append('predecessor-root-overlap')
    directory, current, index, audit = epoch_witness
    bad = copy.deepcopy(current); bad['inputs'].pop()
    assert rejects(lambda: authenticate_epoch(prepare, directory, bad, index, catalog, versions, audit))
    controls.append('missing-historical-input')
    source = current['inputs'][0]['path']
    changed = dict(catalog); changed[source] = dict(changed[source], sha256='0' * 64)
    assert rejects(lambda: authenticate_epoch(prepare, directory, current, index, changed, versions, audit))
    controls.append('changed-input-receipt')
    altered = dict(versions); revision = current['source_revision']; altered[revision] = dict(versions[revision])
    altered[revision][source] = dict(altered[revision][source], oid='0' * 40)
    assert rejects(lambda: authenticate_epoch(prepare, directory, current, index, catalog, altered, audit))
    controls.append('changed-historical-git-identity')
    result = dict(schema='fsmgen.release_composition_join.v1', success=True, runtime_authorized=False,
        source_revision=prepare.REVISION, prospective_pins=pins, input_files=len(plan['inputs']),
        input_bytes=sum(r['size_bytes'] for r in plan['inputs']), cases=len(observed),
        totals=dict(totals), independent_counts=dict(direct), partitions=partitions,
        assertions=sum(p['assertions'] for p in partitions), domain_sha256=signature(sorted(observed)),
        same_input_reversal_predictions=reversal_count, selected_roots_absent=len(roots),
        prior_roots_absent=len(previous), join_falsifiers=controls, new_fixture_roots=0,
        earlier_falsifiers='Original source and saved verdicts authenticated; unchanged row/state/header oracles rerun. Earlier main routines and their complete embedded falsifier loops are not replayed.',
        scope=plan['scope'])
    if sys.argv[1:] == ['--verify-saved']:
        assert result == load(BASE / 'result/join.json')
    else:
        with (LOG / 'join.json').open('x') as stream:
            stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps({k: v for k, v in result.items() if k not in ('partitions', 'prospective_pins')}, sort_keys=True))


if __name__ == '__main__':
    main()
