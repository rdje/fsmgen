"""Verify complete selected close-report coverage using unchanged row oracles."""
from collections import Counter
import ast
import copy
import errno
import importlib.util
import inspect
import json
import os
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


SHARED = module('close_join_qualified_composition_helpers', BASE.with_name('native-proxy-release-composition-join-20260913') / 'audit.py')
load, signature, rejects, receipt = SHARED.load, SHARED.signature, SHARED.rejects, SHARED.receipt


def source_list(function, name):
    """Read a literal historical roster from its canonical function body."""
    tree = ast.parse(inspect.getsource(function))
    values = [node.value for node in ast.walk(tree) if isinstance(node, ast.Assign)
              and any(isinstance(target, ast.Name) and target.id == name for target in node.targets)]
    value, = values
    result = ast.literal_eval(value)
    assert isinstance(result, list) and all(isinstance(item, str) for item in result)
    assert len(result) == len(set(result))
    return result


def authenticate_single_epoch(prepare, directory, current, index, catalog, versions, audit):
    revision = current['source_revision']
    if revision not in versions:
        versions[revision] = prepare.tree(revision)
    version = versions[revision]
    predecessor = BASE.parent / (prepare.SINGLE_SELECTION if index == 0 else prepare.SINGLES[index - 1])
    prior = load(predecessor / 'plan.json')
    paths = {r['path'] for r in prior['inputs']} | set(current['previous_root_reports'])
    if index == 0:
        prefix = str(predecessor.relative_to(ROOT)) + '/'
        paths.update(path for path in version if path.startswith(prefix))
        paths.update(str((audit.PREPARE.CALLS / n).relative_to(ROOT)) for n in ('CallPlan.pm', 'CallFaultTrace.pm', 'audit.py'))
    else:
        paths.update(r['path'] for r in load(predecessor / 'preflight-pins.json'))
        paths.update(str((predecessor / n).relative_to(ROOT)) for n in
            ('plan.json', 'preflight-pins.json', 'result/qualification.json', 'result/audit.json', 'result/recovery-copies.json'))
        state = audit.PREPARE.EQUAL if index == 1 else audit.PREPARE.ACTIVE if index == 2 else audit.PREPARE.LAST
        paths.add(str((state / 'audit.py').relative_to(ROOT)))
        if index == 3:
            paths.add(str((state / 'qualify.t').relative_to(ROOT)))
    assert [r['path'] for r in current['inputs']] == sorted(paths)
    for record in current['inputs']:
        receipt(record, catalog)
        historical = version[record['path']]
        assert historical['kind'] == 'blob' and historical['mode'] in ('100644', '100755')
        assert historical['oid'] == catalog[record['path']]['git_blob']
    names = source_list(audit.authenticate, 'names') if index == 0 else audit.PIN_NAMES
    pins = load(directory / 'preflight-pins.json')
    assert [r['path'] for r in pins] == [str((directory / name).relative_to(ROOT)) for name in names]
    extra_name = 'flow-preflight-pins.json' if index == 0 else 'oracle-pins.json'
    extra_names = source_list(audit.prerequisites, 'pin_names') if index == 0 else audit.ORACLE.PIN_NAMES
    extra = load(directory / extra_name)
    assert [r['path'] for r in extra] == [str((directory / name).relative_to(ROOT)) for name in extra_names]
    for record in pins + extra:
        receipt(record, catalog)
    prepare_pin = load(directory / 'prepare-pin.json')
    assert prepare_pin['path'] == str((directory / 'prepare.py').relative_to(ROOT))
    receipt(prepare_pin, catalog)
    return pins


def single_prerequisites(core, audit, directory, current, index, baseline, inherited):
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
    assert saved['success'] is True and saved['fixture_allocations'] == 0
    flag = ['prior_identity_verified', 'prior_runtime_state_verified', 'prior_last_state_verified'][index - 1]
    assert saved[flag] is True and saved['source_revision'] == current['source_revision']
    assert saved['prospective_pins'] == load(directory / 'oracle-pins.json')
    spec, _ = core.OLD.setup(baseline)
    calls = core.FLOW.derive(baseline['context'], baseline['operation']['before'], spec)
    healthy = core.SUPPORT.TRACE.derive(calls, baseline['context'], current['sealed_symbols'], None)
    bindings = core.SELECT.ownership(calls, baseline['context'])
    by_address = {r['address']: r for r in bindings}
    assert len(by_address) == len(bindings) == len(current['cases']) - 1
    predictions = []
    for case in current['cases']:
        resolved = [by_address[r['address']] for r in case['reports']]
        a = core.TRACE.derive(calls, baseline['context'], current['sealed_symbols'], resolved, os.strerror(errno.EIO))
        b = core.PREFIX.reference(calls, current['sealed_symbols'], healthy, bindings, resolved[0] if resolved else None)
        assert a == b
        predictions.append(dict(index=case['index'], name=case['name'], resolved=resolved,
            prediction_sha256=core.SIGNATURE(b), success=b['success'], effects=b['effects'],
            handles=len(b['handles']), calls=len(b['calls'])))
    assert saved['predictions'] == predictions
    assert saved['falsifiers'] and len(saved['falsifiers']) == len(set(saved['falsifiers']))
    assert load(output / 'oracle.stdout') == audit.ORACLE.summary(saved)
    return dict(inherited=inherited, baseline_predictions=len(predictions),
        baseline_falsifiers=len(saved['falsifiers']), copies=len(copies))


def independent_single_counts(row):
    op = row['operation']; handles = op['handles']; reports = op['close_reports']
    assert all(h['actual_close_ok'] == h['closed_after_call'] == h['closed_at_return'] == 1 for h in handles)
    assert all(r['actual_return'] == r['closed_after_call'] == 1 and r['actual_errno'] == 0 for r in reports)
    success = op['result']['success']; unlinks = sum(r['actual_count'] for r in op['unlinks'])
    return dict(cases=1, calls=len(op['boundary_calls']), events=len(op['events']), handles=len(handles),
        sources=sum(h['kind'] == 'source' for h in handles), directories=sum(h['kind'] == 'directory' for h in handles),
        locks=sum(h['kind'] == 'lock' for h in handles), reads=len(op['reads']), close_reports=len(reports),
        modeled_reports=sum(r['report_applied'] for r in reports), healthy=success, failures=1 - success,
        unlinks=unlinks, post_unlink_failures=unlinks * (1 - success))


def key(domain, profile, case):
    if domain == 'single':
        return (domain, profile, case['name'], None, None)
    return (domain, *SHARED.case_key(profile, case['recipe']))


def verify_recovery(directory):
    recovery = module('close_join_copy_' + directory.name.replace('-', '_'), directory / 'recover.py')
    records = load(directory / 'result/recovery-copies.json')
    assert records == load(directory / 'result/recovery-plan.json')
    recovery.verify(records)
    return dict(copies=len(records), bytes=sum(r['size_bytes'] for r in records))


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'], ['--admit-only'])
    prepare = module('close_join_prepare', BASE / 'prepare.py')
    plan = load(BASE / 'plan.json'); assert plan == prepare.build()
    pins = load(BASE / 'preflight-pins.json')
    assert pins == [prepare.pin(BASE / n) for n in ('prepare.py', 'prepare-pins.json', 'plan.json', 'audit.py')]
    if sys.argv[1:] == ['--admit-only']:
        print(json.dumps(dict(admitted=True, inputs=len(plan['inputs']), new_fixture_roots=0)))
        return
    core = module('close_join_single_rows', BASE.parent / prepare.SINGLES[0] / 'audit.py')
    composed = module('close_join_composed_rows', BASE.parent / prepare.PROFILES[0] / 'audit.py')
    single_selection = load(BASE.parent / prepare.SINGLE_SELECTION / 'plan.json')
    composition_selection = load(BASE.parent / prepare.SELECTION / 'plan.json')
    selector = composed.PREPARE.SELECTION_AUDIT
    boundary = load(core.PREPARE.BOUNDARY / 'plan.json')
    baseline = load(core.PREPARE.BOUNDARY / 'result/qualification.json')
    inherited_single = core.prerequisites(load(core.BASE / 'plan.json'))
    inherited_composed = composed.prerequisites(load(composed.BASE / 'flow-vectors.json'))
    assert load(composed.BASE / 'trace-adaptation.json') == composed.trace_adaptation()
    catalog = {r['path']: r for r in plan['inputs']}
    contracts = core.SELECT.source_contracts(prepare)
    for record in contracts.values():
        receipt(record['source_pin'], catalog)
    required, required_compositions = {}, {}
    for single, composition, original, row in zip(single_selection['profiles'], composition_selection['profiles'], boundary['profiles'], baseline['cases'], strict=True):
        spec, _ = core.OLD.setup(row)
        calls = core.FLOW.derive(row['context'], row['operation']['before'], spec)
        bindings = core.SELECT.ownership(calls, row['context'])
        core.SELECT.domain(single, bindings, original)
        selector.domain(composition, original, calls, row['context'], composition_selection['sealed_symbols'])
        for domain, profile in [('single', single), ('composition', composition)]:
            for case in profile['cases']:
                ident = key(domain, profile['id'], case)
                assert ident not in required
                success = not case['reports'] if domain == 'single' else case['recipe']['kind'] == 'healthy'
                required[ident] = success
                if domain == 'composition':
                    required_compositions[ident[1:]] = success
    first_plan = load(core.BASE / 'plan.json')
    previous_reports = first_plan['previous_root_reports']
    previous = [r['path'] for path in previous_reports for r in load(ROOT / path)['allocated']]
    all_reports = list(previous_reports)
    roots, observed, partitions, versions = [], [], [], {}
    totals, physical_totals = Counter(), Counter()
    observed_compositions, composition_parts = [], []
    compositions_roots = []; reversals = 0; single_epoch = pair_witness = None
    for partition in plan['partitions']:
        domain = partition['domain']; directory = ROOT / partition['directory']
        index = (prepare.SINGLES if domain == 'single' else prepare.PROFILES).index(directory.name)
        current = load(directory / 'plan.json')
        shared = core if domain == 'single' else composed
        audit = shared if index == 0 else module('close_join_' + domain + '_' + str(index), directory / 'audit.py')
        audit.domain(current)
        selected = (single_selection if domain == 'single' else composition_selection)['profiles'][index]
        assert current['profile_id'] == partition['profile_id'] == selected['id']
        assert current['owner'] == partition['owner'] == selected['owner']
        assert current['source_revision'] == partition['source_revision']
        assert current['previous_root_reports'] == all_reports
        if domain == 'single':
            current_pins = authenticate_single_epoch(prepare, directory, current, index, catalog, versions, audit)
            prerequisite = single_prerequisites(core, audit, directory, current, index, baseline['cases'][index], inherited_single)
            if single_epoch is None:
                single_epoch = directory, current, index, audit
        else:
            current_pins = SHARED.authenticate_epoch(prepare, directory, current, index, catalog, versions, audit)
            prerequisite = SHARED.retained_prerequisites(composed, audit, directory, current, index, baseline['cases'][index], inherited_composed)
        report = load(directory / 'result/qualification.json'); audit.header(current, report, current_pins)
        counts, physical, current_roots = Counter(), Counter(), []
        for case, saved in zip(current['cases'], report['case_files'], strict=True):
            row = core.SUPPORT.read_case(directory / 'result', saved)
            values, allocated = audit.verify_row(current, case, row)
            measured = independent_single_counts(row) if domain == 'single' else SHARED.independent_counts(row)
            assert all(values[k] == v for k, v in measured.items())
            counts.update(values); physical.update(measured); current_roots.extend(allocated)
            ident = key(domain, current['profile_id'], case); success = bool(row['operation']['result']['success'])
            observed.append((ident, success))
            if domain == 'composition':
                observed_compositions.append((ident[1:], success))
                pair = SHARED.reversal(composed, current, case, row)
                if pair is not None:
                    reversals += 1
                    if pair_witness is None:
                        pair_witness = pair
        assert report['allocated'] == current_roots
        assert [json.loads(line) for line in (directory / 'result/admission.jsonl').read_text().splitlines()] == current_roots
        assert {p.name for p in (directory / 'result/cases').iterdir()} == {'case-%04d.json' % c['index'] for c in current['cases']}
        assertions = 25 + (12 if domain == 'single' else 13) * len(current['cases'])
        core.SUPPORT.tap(directory / 'result/qualify.tap', assertions)
        for name in ('prepare', 'syntax', 'admission', 'qualify', 'audit'):
            assert (directory / ('result/' + name + '.exit')).read_bytes() == b'0\n'
        published = load(directory / 'result/audit.json')
        assert published['success'] is True and published['totals'] == dict(counts)
        assert published['source_revision'] == current['source_revision'] and published['prospective_pins'] == current_pins
        assert published['input_files'] == len(current['inputs']) and published['assertions'] == assertions
        assert published['roots_absent'] == len(current_roots) and published['prior_roots_absent'] == len(previous) + len(roots)
        assert published['prerequisites'] == prerequisite and published['scope'] == current['scope']
        case_bytes = sum(r['size_bytes'] for r in report['case_files']); assert published['case_bytes'] == case_bytes
        for field in ('row_falsifiers', 'domain_falsifiers', 'header_falsifiers'):
            assert published[field] and len(published[field]) == len(set(published[field]))
        entry = dict(profile_id=current['profile_id'], directory=partition['directory'], totals=dict(counts),
            independent_counts=dict(physical), assertions=assertions, case_bytes=case_bytes,
            recovery=verify_recovery(directory), retained_row_falsifiers=len(published['row_falsifiers']), prerequisites=prerequisite)
        partitions.append(dict(entry, domain=domain))
        if domain == 'composition':
            composition_parts.append(entry); compositions_roots.extend(current_roots)
        roots.extend(current_roots); totals.update(counts); physical_totals.update(physical)
        all_reports.append(str((directory / 'result/qualification.json').relative_to(ROOT)))
        print(json.dumps(dict(domain=domain, profile=current['profile_id'], verified=True, cases=len(current['cases']))), file=sys.stderr, flush=True)
    SHARED.coverage(required, observed); SHARED.coverage(required_compositions, observed_compositions)
    SHARED.root_closure(roots, previous)
    # Reconstruct the already-qualified composition partition from original rows.
    prior_join = load(BASE.parent / prepare.JOIN / 'result/join.json')
    assert prior_join['success'] is True and prior_join['partitions'] == composition_parts
    assert prior_join['domain_sha256'] == signature(sorted(observed_compositions))
    assert prior_join['cases'] == len(observed_compositions) and prior_join['same_input_reversal_predictions'] == reversals
    assert prior_join['selected_roots_absent'] == len(compositions_roots)
    assert prior_join['prior_roots_absent'] == len(previous) + len(roots) - len(compositions_roots)
    assert prior_join['assertions'] == sum(p['assertions'] for p in composition_parts)
    prior_totals, prior_physical = Counter(), Counter()
    for part in composition_parts:
        prior_totals.update(part['totals']); prior_physical.update(part['independent_counts'])
    assert prior_join['totals'] == dict(prior_totals) and prior_join['independent_counts'] == dict(prior_physical)
    verify_recovery(BASE.parent / prepare.JOIN)
    controls = []
    for name, mutate in (
        ('omitted-single', lambda rows: rows.pop(1)),
        ('omitted-composition', lambda rows: rows.pop()),
        ('duplicate-single', lambda rows: rows.__setitem__(1, rows[0])),
        ('duplicate-composition', lambda rows: rows.__setitem__(-1, rows[-2])),
        ('wrong-success', lambda rows: rows.__setitem__(0, (rows[0][0], False))),
        ('wrong-domain', lambda rows: rows.__setitem__(0, (('composition', *rows[0][0][1:]), rows[0][1]))),
        ('wrong-profile', lambda rows: rows.__setitem__(0, ((rows[0][0][0], 'foreign', *rows[0][0][2:]), rows[0][1]))),
    ):
        bad = copy.deepcopy(observed); mutate(bad)
        assert rejects(lambda: SHARED.coverage(required, bad)), name
        controls.append(name)
    assert rejects(lambda: SHARED.root_closure(roots + roots[:1], previous)); controls.append('duplicated-root')
    assert rejects(lambda: SHARED.root_closure(roots, previous + [roots[0]['path']])); controls.append('predecessor-overlap')
    directory, current, index, audit = single_epoch
    bad = copy.deepcopy(current); bad['inputs'].pop()
    assert rejects(lambda: authenticate_single_epoch(prepare, directory, bad, index, catalog, versions, audit))
    controls.append('missing-historical-input')
    source = current['inputs'][0]['path']; changed = dict(catalog)
    changed[source] = dict(changed[source], sha256='0' * 64)
    assert rejects(lambda: authenticate_single_epoch(prepare, directory, current, index, changed, versions, audit))
    controls.append('changed-input-digest')
    altered = dict(versions); revision = current['source_revision']; altered[revision] = dict(versions[revision])
    altered[revision][source] = dict(altered[revision][source], oid='0' * 40)
    assert rejects(lambda: authenticate_single_epoch(prepare, directory, current, index, catalog, altered, audit))
    controls.append('changed-historical-git-identity')
    bad = copy.deepcopy(pair_witness); bad[1]['witness']['winner'] = None
    assert rejects(lambda: SHARED.compare_reversal(*bad)); controls.append('declaration-dependent-winner')
    result = dict(schema='fsmgen.release_close_report_join.v1', success=True, runtime_authorized=False,
        source_revision=prepare.REVISION, prospective_pins=pins, input_files=len(plan['inputs']),
        input_bytes=sum(r['size_bytes'] for r in plan['inputs']), cases=len(observed),
        totals=dict(totals), independent_counts=dict(physical_totals), partitions=partitions,
        single_cases=sum(p['totals']['cases'] for p in partitions if p['domain'] == 'single'),
        composition_cases=len(observed_compositions), assertions=sum(p['assertions'] for p in partitions),
        domain_sha256=signature(sorted(observed)), composition_domain_sha256=prior_join['domain_sha256'],
        same_input_reversal_predictions=reversals, selected_roots_absent=len(roots), prior_roots_absent=len(previous),
        source_contracts=contracts, join_falsifiers=controls, new_fixture_roots=0,
        earlier_falsifiers=prior_join['earlier_falsifiers'], scope=plan['scope'])
    if sys.argv[1:] == ['--verify-saved']:
        assert result == load(BASE / 'result/join.json')
    else:
        with (LOG / 'join.json').open('x') as stream:
            stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps({k: v for k, v in result.items() if k not in ('partitions', 'prospective_pins', 'source_contracts')}, sort_keys=True))


if __name__ == '__main__':
    main()
