"""Join original omission evidence with independent domain and native counts."""
from collections import Counter
import ast
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
MAIN_NAMES = ['prepare.py', 'prepare-pins.json', 'plan.json', 'audit.py',
              'recover.py', 'recovery-pins.json']


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
    return profile, recipe['kind'], recipe['scope'], recipe['handle_kind']


def coverage(required, observed):
    assert len(observed) == len(required) == len(dict(observed))
    assert dict(observed) == required


def receipt(record, catalog):
    expected = catalog[record['path']]
    assert record == {k: expected[k] for k in ('path', 'size_bytes', 'sha256')}


def function_body(path, name):
    source = path.read_text()
    node = next(n for n in ast.parse(source).body if isinstance(n, ast.FunctionDef) and n.name == name)
    return '\n'.join(source.splitlines()[node.lineno - 1:node.end_lineno])


def source_proofs(prepare):
    ordinary = BASE.parent / prepare.PROFILES[0]
    path = ordinary / 'native-trace-source-review.json'
    proof = load(path)
    original = function_body(ROOT / proof['original_source'], 'trace')
    adapted = function_body(ordinary / 'audit.py', 'native_trace')
    # The original receipt includes its terminal LF; the adapted receipt does
    # not. Compare function text under that explicitly retained convention.
    assert hashlib.sha256((original + '\n').encode()).hexdigest() == proof['original_function_sha256']
    assert hashlib.sha256(adapted.encode()).hexdigest() == proof['adapted_function_sha256']
    for change in proof['changes']:
        assert original.count(change['before']) == 1
        original = original.replace(change['before'], change['after'])
    assert original == adapted
    verified = [str(path.relative_to(ROOT))]
    for name in prepare.PROFILES[2:]:
        directory = BASE.parent / name
        path = directory / 'row-source-review.json'
        proof = load(path)
        original = function_body(ROOT / proof['source_path'], proof['original_function']) + '\n'
        adapted = function_body(directory / 'audit.py', proof['adapted_function']) + '\n'
        assert hashlib.sha256(original.encode()).hexdigest() == proof['original_sha256']
        assert hashlib.sha256(adapted.encode()).hexdigest() == proof['adapted_sha256']
        for change in proof['changes']:
            assert original.count(change['original']) == 1
            original = original.replace(change['original'], change['replacement'])
        assert original == adapted
        verified.append(str(path.relative_to(ROOT)))
    return verified


def authenticate_epoch(prepare, directory, current, index, catalog, versions, audit):
    """Reconstruct each original flat input roster at its own source epoch."""
    revision = current['source_revision']
    if revision not in versions:
        versions[revision] = prepare.tree(revision)
    version = versions[revision]
    previous = BASE.parent / (prepare.SELECTION if index == 0 else prepare.PROFILES[index - 1])
    prior = load(previous / 'plan.json')
    prefix = str(previous.relative_to(ROOT)) + '/'
    paths = {r['path'] for r in prior['inputs']} | {p for p in version if p.startswith(prefix)}
    assert [r['path'] for r in current['inputs']] == sorted(paths)
    for record in current['inputs']:
        assert record == catalog[record['path']]
        historical = version[record['path']]
        assert historical['kind'] == 'blob' and historical['mode'] in ('100644', '100755')
        assert historical['oid'] == record['git_blob']
    pins = load(directory / 'preflight-pins.json')
    assert [r['path'] for r in pins] == [str((directory / n).relative_to(ROOT)) for n in audit.MAIN_NAMES]
    pure = load(directory / 'source-pins.json')
    assert [r['path'] for r in pure] == [str((directory / n).relative_to(ROOT)) for n in audit.PREPARE.PURE_NAMES]
    recovery = load(directory / 'recovery-pins.json')
    assert [r['path'] for r in recovery] == [str((directory / 'recover.py').relative_to(ROOT))]
    for record in pins + pure + recovery:
        receipt(record, catalog)
    return pins


def independent_counts(row):
    """Count physical records without using the profile auditor's totals."""
    operation = row['operation']
    handles = operation['handles']
    opened = [h for h in handles if h['closed_at_return'] == 0]
    omitted = [h for h in handles if h.get('actual_close_performed', 1) == 0]
    assert opened == omitted and len(opened) <= 1
    fault = len(opened)
    assert operation['all_observed_handles_closed'] == 1 - fault
    for handle in handles:
        missing = handle in opened
        assert handle['actual_close_ok'] == handle['closed_after_call'] == handle['closed_at_return'] == int(not missing)
        assert handle['actual_errno'] == handle['reported_errno'] == 0 and handle['reported_return'] == 1
    evidence = row['omission']
    assert len(evidence['open_witnesses']) == len(evidence['observer_recovery']) == len(evidence['omission_hits']) == fault
    assert evidence['recovery_complete'] == evidence['observation_returned'] == 1
    assert evidence['observer_errors'] == []
    for handle, witness, recovery in zip(opened, evidence['open_witnesses'], evidence['observer_recovery'], strict=True):
        assert witness['label'] == recovery['label'] == handle['label']
        assert witness['object_address'] == recovery['object_address'] == handle['omitted_object_address']
        assert witness['descriptor'] == recovery['descriptor_before'] == handle['descriptor']
        assert (witness['device'], witness['inode']) == (handle['device'], handle['inode'])
        assert witness['open_after_original_return'] == 1
        assert recovery['performed'] == recovery['actual_return'] == recovery['closed_after'] == 1
        assert recovery['actual_errno'] == 0
    original = {k: v for k, v in operation.items() if k not in ('before', 'after')}
    assert signature(original) == evidence['original_sha256_before_recovery'] == evidence['original_sha256_after_recovery']
    assert operation['result']['success'] == 1 and operation['result']['error'] == ''
    counts = dict(cases=1, handles=len(handles), sources=sum(h['kind'] == 'source' for h in handles),
        directories=sum(h['kind'] == 'directory' for h in handles), locks=sum(h['kind'] == 'lock' for h in handles),
        calls=len(operation['boundary_calls']), events=len(operation['events']), reads=len(operation['reads']),
        healthy=1-fault, original_open_verdicts=fault, original_auditor_rejections=fault,
        separately_recovered=fault, unlinks=sum(r['actual_count'] for r in operation['unlinks']))
    kinds = Counter(h['kind'] + '_omissions' for h in opened)
    return counts, kinds


def root_closure(roots, previous):
    paths = [r['path'] for r in roots]
    assert len(paths) == len(set(paths)) and len(previous) == len(set(previous))
    assert not set(paths) & set(previous)
    for relative in paths + previous:
        path = Path(relative)
        assert not path.is_absolute() and '..' not in path.parts and relative.startswith('.artifacts/')
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()


def selected_domain(prepare, ordinary):
    """Reconstruct original selected cases from source-owned baseline closes."""
    directory = BASE.parent / prepare.SELECTION
    selected = load(directory / 'plan.json')
    audit = module('omission_join_original_selection_audit', directory / 'audit.py')
    source = module('omission_join_original_selection_prepare', directory / 'prepare.py')
    audit.protocol(selected)
    observer = audit.original_observer(source)
    original = load(source.BOUNDARY / 'plan.json')
    saved = load(source.BOUNDARY / 'result/qualification.json')
    boundary = module('omission_join_original_boundaries', source.BOUNDARY / 'audit.py')
    boundary_counts, _ = boundary.verify(original, saved)
    adapter = module('omission_join_archived_selector_adapter', source.JOIN / 'audit-corrected.py')
    correction = module('omission_join_retained_selector_correction', source.JOIN / 'correction-preflight.py')
    correction.verify_saved()
    core = ordinary.CORE
    contracts = core.SELECT.source_contracts(prepare)
    assert contracts == load(directory / 'result/audit.json')['source_contracts']
    required = {}
    for index, (profile, original_profile, row) in enumerate(zip(selected['profiles'], original['profiles'], saved['cases'], strict=True)):
        spec, _ = core.OLD.setup(row)
        calls = core.FLOW.derive(row['context'], row['operation']['before'], spec)
        selectors = adapter.single_selectors(core, calls, row, contracts)
        cases = audit.expected_cases(selectors)
        assert {c['recipe']['scope'] for c in cases[1:]} == set(contracts)
        owner = prepare.OWNER.rsplit('.', 1)[0] + '.' + str(index + 2)
        audit.domain(profile, original_profile, cases, owner)
        for case in cases:
            key = case_key(profile['id'], case['recipe'])
            assert key not in required
            required[key] = case
    return selected, required, dict(original_observer=observer, source_contracts=contracts,
        original_boundary=boundary_counts, prior_roots_absent=audit.previous_roots(selected, source))


def main():
    assert sys.argv[1:] in ([], ['--admit-only'], ['--verify-saved'])
    prepare = module('omission_join_prepare', BASE / 'prepare.py')
    plan = load(BASE / 'plan.json')
    assert plan == prepare.build()
    pins = load(BASE / 'preflight-pins.json')
    assert pins == [prepare.pin(BASE / n) for n in MAIN_NAMES]
    catalog = {r['path']: r for r in plan['inputs']}
    assert len(catalog) == len(plan['inputs'])
    ordinary_directory = BASE.parent / prepare.PROFILES[0]
    sys.path.insert(0, str(ordinary_directory))
    ordinary = module('omission_join_ordinary_oracles', ordinary_directory / 'audit.py')
    selected, required, selection_evidence = selected_domain(prepare, ordinary)
    selection_evidence['source_adaptation_proofs'] = source_proofs(prepare)
    inherited = ordinary.prerequisites(load(ordinary_directory / 'plan.json'))
    assert [p['directory'] for p in plan['partitions']] == [str((BASE.parent / n).relative_to(ROOT)) for n in prepare.PROFILES]
    versions = {}
    admissions = []
    for index, partition in enumerate(plan['partitions']):
        directory = ROOT / partition['directory']
        audit = ordinary if index == 0 else module('omission_join_profile_' + str(index), directory / 'audit.py')
        current = load(directory / 'plan.json')
        audit.domain(current)
        profile = selected['profiles'][index]
        assert partition == dict(directory=str(directory.relative_to(ROOT)), profile_id=profile['id'],
            owner=profile['owner'], source_revision=current['source_revision'])
        assert current['cases'] == profile['cases']
        assert current['previous_root_reports'] == selected['previous_root_reports'] + [
            str((BASE.parent / name / 'result/qualification.json').relative_to(ROOT)) for name in prepare.PROFILES[:index]]
        original_pins = authenticate_epoch(prepare, directory, current, index, catalog, versions, audit)
        recovery = module('omission_join_recovery_' + str(index), directory / 'recover.py')
        copies = load(directory / 'result/recovery-copies.json')
        assert copies == load(directory / 'result/recovery-plan.json')
        recovery.verify(copies)
        admissions.append((directory, audit, current, original_pins, copies))
    if sys.argv[1:] == ['--admit-only']:
        print(json.dumps(dict(admitted=True, inputs=len(catalog), partitions=len(admissions),
            selected_cases=len(required), inherited_binding=inherited, new_fixture_roots=0), sort_keys=True))
        return
    totals = Counter()
    omission_kinds = Counter()
    roots, observed, partitions, witnesses = [], [], [], {}
    for index, (directory, audit, current, original_pins, copies) in enumerate(admissions):
        storage = directory / 'result'
        report = load(storage / 'qualification.json')
        audit.header(current, report, original_pins)
        subtotal = Counter()
        profile_roots = []
        for case, saved in zip(current['cases'], report['case_files'], strict=True):
            row = audit.SUPPORT.read_case(storage, saved)
            counts, allocated = audit.verify_row(current, case, row)
            independent, kinds = independent_counts(row)
            assert all(counts[key] == value for key, value in independent.items())
            if index == 3:
                context = row['context']
                remaining = [node for name, node in row['operation']['after']['store'].items()
                    if name.startswith('references/') and node['kind'] == 'file'
                    and json.loads(bytes.fromhex(node['bytes_hex']))['image_key'] == context['runtime']['image']['key']]
                assert counts['unreferenced_image_cases'] == int(not remaining)
            subtotal.update(counts)
            omission_kinds.update(kinds)
            profile_roots.extend(allocated)
            observed.append((case_key(current['profile_id'], row['matrix_case']['recipe']), row['matrix_case']))
            kind = case['recipe']['handle_kind'] or 'healthy'
            witnesses.setdefault(kind, row)
        assert report['allocated'] == profile_roots
        assert [json.loads(line) for line in (storage / 'admission.jsonl').read_text().splitlines()] == profile_roots
        assert {p.name for p in (storage / 'cases').iterdir()} == {'case-%04d.json' % c['index'] for c in current['cases']}
        assertions = 25 + 14 * len(current['cases'])
        audit.SUPPORT.tap(storage / 'qualify.tap', assertions)
        assert (storage / 'qualify.exit').read_bytes() == b'0\n'
        saved_audit = load(storage / 'audit.json')
        assert saved_audit['success'] is True and saved_audit['totals'] == dict(subtotal)
        assert saved_audit['assertions'] == assertions and saved_audit['prospective_pins'] == original_pins
        assert saved_audit['new_roots_absent'] == len(profile_roots)
        expected_prior = [r['path'] for p in current['previous_root_reports'] for r in load(ROOT / p)['allocated']]
        root_closure(profile_roots, expected_prior)
        assert saved_audit['prior_roots_absent'] == len(expected_prior)
        totals.update(subtotal)
        roots.extend(profile_roots)
        partitions.append(dict(plan['partitions'][index], counts=dict(subtotal), assertions=assertions,
            copies=len(copies), copy_bytes=sum(r['size_bytes'] for r in copies), roots_absent=len(profile_roots)))
    coverage(required, observed)
    prior = [r['path'] for p in selected['previous_root_reports'] for r in load(ROOT / p)['allocated']]
    root_closure(roots, prior)
    assert len(prior) == selection_evidence['prior_roots_absent']
    selected_counts = load(BASE.parent / prepare.SELECTION / 'result/audit.json')['totals']
    assert totals['cases'] == selected_counts['prospective_cases']
    assert totals['healthy'] == selected_counts['healthy_controls']
    assert dict(omission_kinds) == {k: v for k, v in selected_counts.items() if k.endswith('_omissions')}
    controls = []
    for name, mutate in [('missing-case', lambda r: r.pop()),
                         ('duplicate-case', lambda r: r.append(copy.deepcopy(r[1]))),
                         ('wrong-profile', lambda r: r.__setitem__(0, (('foreign', *r[0][0][1:]), r[0][1]))),
                         ('wrong-scope', lambda r: r[1][1]['recipe'].update(scope='foreign')),
                         ('changed-baseline', lambda r: r[1][1]['baseline'].update(baseline_close_event=-1))]:
        changed = copy.deepcopy(observed)
        mutate(changed)
        assert rejects(lambda: coverage(required, changed)), name
        controls.append(name)
    for name, kind, mutate in [
        ('original-closure-rewritten', 'source', lambda r: next(h for h in r['operation']['handles'] if h.get('actual_close_performed') == 0).update(closed_at_return=1)),
        ('lost-open-witness', 'lock', lambda r: r['omission']['open_witnesses'].clear()),
        ('duplicate-recovery', 'source', lambda r: r['omission']['observer_recovery'].append(copy.deepcopy(r['omission']['observer_recovery'][0]))),
        ('wrong-recovery-object', 'directory', lambda r: r['omission']['observer_recovery'][0].update(object_address=7)),
        ('recovery-still-open', 'source', lambda r: r['omission']['observer_recovery'][0].update(closed_after=0)),
        ('changed-original-snapshot', 'source', lambda r: r['omission'].update(original_sha256_after_recovery='0' * 64))]:
        changed = copy.deepcopy(witnesses[kind])
        mutate(changed)
        if name == 'original-closure-rewritten':
            digest = signature({k: v for k, v in changed['operation'].items() if k not in ('before', 'after')})
            changed['omission'].update(original_sha256_before_recovery=digest, original_sha256_after_recovery=digest)
        assert rejects(lambda: independent_counts(changed)), name
        controls.append(name)
    assert rejects(lambda: root_closure(roots + [roots[0]], prior))
    assert rejects(lambda: root_closure(roots, prior + [roots[0]['path']]))
    controls += ['repeated-root', 'overlapping-root']
    result = dict(schema='fsmgen.release_omission_join.v1', success=True, owner=prepare.OWNER,
        source_revision=prepare.REVISION, prospective_pins=pins, partitions=partitions,
        totals=dict(totals), omission_kinds=dict(omission_kinds), assertions=sum(p['assertions'] for p in partitions),
        selected_roots_absent=len(roots), prior_roots_absent=len(prior), inherited_binding=inherited,
        domain_sha256=signature([dict(profile=k[0], case=v) for k, v in observed]),
        falsifiers=controls, selection_evidence=selection_evidence, input_files=len(catalog),
        input_bytes=sum(r['size_bytes'] for r in plan['inputs']), new_fixture_roots=0,
        original_main_calls=0, native_executions=0, scope=plan['scope'])
    storage = BASE / 'result' if sys.argv[1:] else LOG
    if sys.argv[1:]:
        assert load(storage / 'join.json') == result
    else:
        with (storage / 'join.json').open('x') as stream:
            stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps({k: v for k, v in result.items() if k not in ('prospective_pins', 'partitions', 'selection_evidence')}, sort_keys=True))


if __name__ == '__main__':
    main()
