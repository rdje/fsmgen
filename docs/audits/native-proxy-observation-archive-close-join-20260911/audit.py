"""Independent source/domain/cleanup join over authenticated saved close evidence."""
from __future__ import annotations

import builtins
from collections import Counter
from contextlib import contextmanager
import copy
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import re

import inventory

BASE, ROOT, LOG = inventory.BASE, inventory.ROOT, inventory.LOG
REVISION = '254e3e1af3f061e7720112ded0d9337c3b13c31b'
EXPECTED = [dict(name='reports', source='docs/audits/native-proxy-observation-archive-close-reports-20260911',
                 adapter='CloseReports.pm', source_epoch='7e1f2daa01c9ef5760954089c36ec6c778c25f17',
                 completed_revision='2ad652d308348e8ce82bb8e4e11a968c731a8ebe'),
            dict(name='omissions', source='docs/audits/native-proxy-observation-archive-omitted-closes-20260911',
                 adapter='OmittedCloses.pm', source_epoch='2ad652d308348e8ce82bb8e4e11a968c731a8ebe',
                 completed_revision=REVISION)]
BOUNDARY = 'docs/audits/native-proxy-observation-archive-boundaries-20260911'
RAW = ['plan.stdout', 'plan.stderr', 'plan.exit', 'syntax.stdout', 'syntax.stderr', 'syntax.exit',
       'preflight-pins.json', 'qualification.json', 'admission.jsonl', 'qualify.tap', 'qualify.stderr',
       'qualify.exit', 'audit.json', 'audit.stdout', 'audit.stderr', 'audit.exit']


def decoded(path): return json.loads(inventory.read(path)[0])
def digest(raw): return dict(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def plan_domain(plan):
    assert plan['schema'] == 'fsmgen.inactive_archive_close_join_plan.v1'
    assert plan['source_revision'] == REVISION and plan['matrices'] == EXPECTED
    assert plan['owner'] == 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.3.3'
    assert plan['input_limits'] == dict(files=128, file_bytes=33554432, total_bytes=134217728)


def source_inventory(plan, observed, original):
    plan_domain(plan)
    dependencies = {pin['path'] for pin in original['inputs']}
    dependencies.update(BOUNDARY + '/' + name for name in ['plan.json', 'ArchiveTrace.pm', 'ArchiveFixture.pm',
                        'extraction.json', 'audit.py', 'result/qualification.json', 'result/recovery-copies.json'])
    dependencies.update('docs/audits/native-proxy-observation-archive-' + name + '-20260911/audit.py'
                        for name in ['fresh-calls', 'partial-writes'])
    paths = set(dependencies)
    paths.add(EXPECTED[0]['source'] + '/audit.py')
    applicability = []
    for matrix in EXPECTED:
        base = matrix['source']; child = decoded(base + '/plan.json')
        expected_dependencies = sorted(dependencies | ({EXPECTED[0]['source'] + '/audit.py'} if matrix['name'] == 'omissions' else set()))
        assert [pin['path'] for pin in child['inputs']] == expected_dependencies
        assert child['source_revision'] == matrix['source_epoch']
        for pin in child['inputs']:
            raw = inventory.read(pin['path'])[0]
            assert digest(raw) == {key: pin[key] for key in ('size_bytes', 'sha256')}
            assert raw == inventory.historical(matrix['source_epoch'], pin['path'])
            applicability.append(dict(matrix=matrix['name'], source_epoch=matrix['source_epoch'], path=pin['path'], **digest(raw), status='exact'))
        sources = [base + '/' + name for name in ['plan.py', 'plan.json', matrix['adapter'], 'qualify.t', 'audit.py']]
        pins = decoded(base + '/preflight-pins.json')
        assert [pin['path'] for pin in pins] == sources
        for pin in pins:
            assert digest(inventory.read(pin['path'])[0]) == {key: pin[key] for key in ('size_bytes', 'sha256')}
        assert inventory.read(base + '/preflight-pins.json')[0] == inventory.read(base + '/result/preflight-pins.json')[0]
        member_paths = sources + [base + '/preflight-pins.json'] + [base + '/result/' + name for name in RAW + ['recovery-copies.json']]
        paths.update(member_paths)
        for path in member_paths:
            assert inventory.read(path)[0] == inventory.historical(matrix['completed_revision'], path)
    assert observed['schema'] == 'fsmgen.inactive_archive_close_join_inventory.v1' and observed['source_revision'] == REVISION
    assert [row['path'] for row in observed['inputs']] == sorted(paths)
    assert len(paths) <= plan['input_limits']['files']
    records = []
    for path in sorted(paths):
        raw, identity = inventory.read(path)
        assert raw == inventory.historical(REVISION, path)
        records.append(dict(path=path, **identity))
    assert observed['inputs'] == records and observed['applicability'] == applicability
    total = sum(row['size_bytes'] for row in records)
    assert observed['source_files'] == len(records) and observed['total_bytes'] == total <= plan['input_limits']['total_bytes']
    assert observed['epoch_comparisons'] == len(applicability)
    return records, applicability


@contextmanager
def saved_only():
    """Reject old ignored content before opening it; metadata absence is allowed."""
    original_builtin, original_io = builtins.open, io.open
    def wrapped(original):
        def call(path, *args, **kwargs):
            if isinstance(path, (str, bytes, Path)):
                candidate = Path(path).absolute()
                if candidate.is_relative_to(ROOT / '.artifacts') and not candidate.is_relative_to(LOG):
                    raise AssertionError('forbidden legacy artifact content')
            return original(path, *args, **kwargs)
        return call
    builtins.open, io.open = wrapped(original_builtin), wrapped(original_io)
    try: yield
    finally: builtins.open, io.open = original_builtin, original_io


def module(matrix):
    specification = importlib.util.spec_from_file_location('close_join_' + matrix['name'], ROOT / matrix['source'] / 'audit.py')
    result = importlib.util.module_from_spec(specification); specification.loader.exec_module(result)
    return result


def authenticate_receipts(matrix, manifest=None):
    base = matrix['source']
    if manifest is None: manifest = decoded(base + '/result/recovery-copies.json')
    assert manifest['all_copies_byte_exact'] is True
    expected = [base + '/result/' + name for name in RAW]
    assert [row['destination'] for row in manifest['files']] == expected
    receipts = []
    for name, row in zip(RAW, manifest['files'], strict=True):
        assert row['source'] == '.artifacts/logs/' + base.rsplit('/', 1)[-1] + '/' + name
        actual = digest(inventory.read(row['destination'])[0])
        assert actual == {key: row[key] for key in ('size_bytes', 'sha256')}
        receipts.append(dict(path=row['destination'], **actual))
    for name in ['plan.exit', 'syntax.exit', 'qualify.exit', 'audit.exit']:
        assert inventory.read(base + '/result/' + name)[0] == b'0\n'
    return receipts


def tap_assertions(raw):
    assert not re.search(r'^(?:not ok|Bail out!)|#\s*(?:SKIP|TODO)\b', raw, re.M | re.I)
    plans = re.findall(r'^1\.\.([0-9]+)$', raw, re.M); assert len(plans) == 1
    count = int(plans[0]); assert re.findall(r'^ok ([0-9]+) - ', raw, re.M) == [str(index) for index in range(1, count + 1)]
    return count


def coverage(children, original):
    rows = []
    for profile, number in [('ordinary', 4), ('equal_reference', 3)]:
        for route in ['fresh', 'existing']:
            flow = profile + ':' + route
            labels = [row['event'][6:-6] for row in original['flows'][flow]['events'] if re.fullmatch(r'close:.+:after', row['event'])]
            selected = {}
            for name, child in children.items():
                cases = [case for case in child['cases'] if case['profile'] == profile and case['route'] == route]
                singles = [case for case in cases if case['kind'] == 'single']
                actual = [case['reports'][0]['label'] if name == 'reports' else case['omissions'][0] for case in singles]
                assert actual == labels and len(actual) == len(set(actual))
                assert all(len(case['reports'] if name == 'reports' else case['omissions']) == 1 for case in singles)
                selected[name] = [case['name'] for case in singles]
            omission_groups = [case for case in children['omissions']['cases'] if case['profile'] == profile and case['route'] == route and case['kind'] == 'all-group']
            assert len(omission_groups) == 1 and omission_groups[0]['omissions'] == labels[::-1]
            rows.append(dict(flow=flow, archive_files=number, labels=labels, single_report_cases=selected['reports'],
                             single_omission_cases=selected['omissions'], all_omission_case=omission_groups[0]['name']))
    return rows


def derive_counts(reports):
    totals = Counter(); kinds = Counter(); roots = []
    for name in ['reports', 'omissions']:
        report = reports[name]
        totals['cases'] += len(report['cases']); roots.extend(report['allocated'])
        for row in report['cases']:
            operations = ([row['preparation']] if 'preparation' in row else []) + [row['operation']]
            totals['preparations'] += 'preparation' in row
            totals['primary_failures'] += row['selection']['primary'] is not None
            totals['healthy_controls'] += row['selection']['kind'] == 'healthy'
            for operation in operations:
                totals['operations'] += 1; totals['events'] += len(operation['events'])
                for handle in operation['handles']:
                    kinds[handle['kind']] += 1; totals['handles'] += 1
                    if handle['closed_at_return']:
                        assert handle['actual_close_ok'] == handle['closed_after_call'] == 1 and handle['actual_errno'] == 0
                        totals['closed_by_implementation'] += 1
                    else:
                        assert name == 'omissions' and operation is row['operation']
                        assert handle['actual_close_performed'] == handle['actual_close_ok'] == handle['closed_after_call'] == 0
                        totals['omitted_handles'] += 1
            operation = row['operation']
            if name == 'reports':
                totals['close_reports'] += len(operation['close_reports'])
                totals['modeled_errors'] += sum(item['report_applied'] for item in operation['close_reports'])
                assert not operation.get('observer_recovery')
            else:
                totals['recovered_handles'] += len(operation['observer_recovery'])
                totals['closure_rejections'] += not operation['all_observed_handles_closed']
                totals['counterimplementation_returns'] += bool(row['selection']['omissions']) and bool(operation['returned'])
                assert not operation.get('close_reports')
    assert totals['handles'] == totals['closed_by_implementation'] + totals['omitted_handles']
    assert totals['omitted_handles'] == totals['recovered_handles']
    paths = [row['path'] for row in roots]
    assert len(paths) == len(set(paths)), 'overlapping close-domain allocations'
    totals.update(dict(matrices=len(reports), roots=len(paths)))
    return dict(totals, **{kind + '_handles': kinds[kind] for kind in ('source', 'writer', 'directory')}), roots


def absence(roots):
    for row in roots:
        path = ROOT / row['path']
        assert row['path'].startswith('.artifacts/') and all(part not in ('', '.', '..') for part in row['path'].split('/'))
        assert not path.exists() and not path.is_symlink()
        while path != ROOT:
            assert not path.is_symlink()
            if path.exists(): assert path.stat().st_dev == ROOT.stat().st_dev
            path = path.parent


def reject(name, callback, rejected):
    try: callback()
    except (AssertionError, KeyError, IndexError): rejected.append(name)
    else: raise AssertionError('close join accepted falsifier: ' + name)


def main():
    plan = decoded(str((BASE / 'plan.json').relative_to(ROOT))); plan_domain(plan)
    pins = decoded(str((BASE / 'preflight-pins.json').relative_to(ROOT)))
    expected_pins = [str((BASE / name).relative_to(ROOT)) for name in ['plan.json', 'inventory.py', 'audit.py']]
    assert [pin['path'] for pin in pins] == expected_pins
    for pin in pins:
        assert digest(inventory.read(pin['path'])[0]) == {key: pin[key] for key in ('size_bytes', 'sha256')}
    original = decoded(BOUNDARY + '/plan.json'); baseline = decoded(BOUNDARY + '/result/qualification.json')
    observed = json.loads((LOG / 'source-inventory.json').read_bytes())
    records, epochs = source_inventory(plan, observed, original)
    reports, children, receipts, child_counts, oracles = {}, {}, {}, {}, {}
    assertions = 0; rejected = []
    with saved_only():
        reject('old ignored content access', lambda: (ROOT / '.artifacts/logs/forbidden-close-join-content').read_bytes(), rejected)
        for matrix in EXPECTED:
            name, base = matrix['name'], matrix['source']
            receipts[name] = authenticate_receipts(matrix)
            oracle = module(matrix); oracles[name] = oracle
            child, report = decoded(base + '/plan.json'), decoded(base + '/result/qualification.json')
            oracle.domain(child, original, baseline)
            counts = oracle.verify(child, report, original, baseline)
            saved = decoded(base + '/result/audit.json')
            assert saved['success'] is True and saved['all_allocations_absent'] is True
            assert all(saved[key] == value for key, value in counts.items())
            assert saved['predecessor_inputs_unchanged'] == len(child['inputs']) and saved['prospective_inputs_unchanged'] == 5
            tap = tap_assertions(inventory.read(base + '/result/qualify.tap')[0].decode())
            expected_tap = len(child['cases']) * (5 if name == 'reports' else 6) + 2 * sum(case['route'] == 'existing' for case in child['cases']) + 1
            assert tap == saved['tap_assertions'] == expected_tap; assertions += tap
            journal = [json.loads(line) for line in inventory.read(base + '/result/admission.jsonl')[0].splitlines()]
            assert journal == report['allocated']
            children[name], reports[name], child_counts[name] = child, report, counts
            changed = dict(report, cases=report['cases'][:-1])
            reject(name + ': missing saved case', lambda: oracle.verify(child, changed, original, baseline), rejected)
            changed = dict(report, cases=[report['cases'][0]] + report['cases'][:-1])
            reject(name + ': duplicate saved case', lambda: oracle.verify(child, changed, original, baseline), rejected)
            changed_child = copy.deepcopy(child); changed_child['cases'].pop(1)
            reject(name + ': omitted declared close', lambda: oracle.domain(changed_child, original, baseline), rejected)
    # Challenge the same original evidence oracles at the distinct boundaries
    # joined here; change only in-memory copies, never the preserved inputs.
    for name in ['reports', 'omissions']:
        oracle = oracles[name]; child = children[name]; report = reports[name]
        selected = next(index for index, row in enumerate(report['cases'])
                        if row['selection']['kind'] == ('retained-group' if name == 'reports' else 'all-group'))
        primary_index = next(index for index, row in enumerate(report['cases']) if row['selection']['primary'])
        if name == 'reports':
            changes = [('modeled error hides failed actual close', lambda op: next(row for row in op['close_reports'] if row['report_applied']).update(actual_return=0)),
                       ('modeled error lost', lambda op: next(row for row in op['close_reports'] if row['report_applied']).update(reported_errno=0)),
                       ('retained close omitted', lambda op: next(row for row in op['handles'] if row['kind'] == 'source').update(closed_at_return=0))]
        else:
            changes = [('original omission verdict healed', lambda op: op.update(all_observed_handles_closed=1)),
                       ('foreign open witness', lambda op: op['open_witnesses'][0].update(inode=7)),
                       ('recovery close omitted', lambda op: op['observer_recovery'][0].update(performed=0))]
        for label, change in changes:
            altered = dict(report, cases=list(report['cases']))
            altered['cases'][selected] = copy.deepcopy(report['cases'][selected])
            change(altered['cases'][selected]['operation'])
            reject(name + ': ' + label, lambda: oracle.verify(child, altered, original, baseline), rejected)
        altered = dict(report, cases=list(report['cases']))
        altered['cases'][primary_index] = copy.deepcopy(report['cases'][primary_index])
        altered['cases'][primary_index]['operation']['error'] = 'lost primary error\n'
        reject(name + ': replaced primary error', lambda: oracle.verify(child, altered, original, baseline), rejected)
    for matrix in EXPECTED:
        manifest = decoded(matrix['source'] + '/result/recovery-copies.json')
        for name in ['missing recovery copy', 'changed recovery digest', 'foreign original source']:
            changed = copy.deepcopy(manifest)
            if name == 'missing recovery copy': changed['files'].pop()
            elif name == 'changed recovery digest': changed['files'][0]['sha256'] = '0' * 64
            else: changed['files'][0]['source'] = '.artifacts/logs/foreign-source'
            reject(matrix['name'] + ': ' + name, lambda: authenticate_receipts(matrix, changed), rejected)
    domains = coverage(children, original)
    counts, roots = derive_counts(reports); counts['tap_assertions'] = assertions
    absence(roots)
    for name in ['missing matrix', 'duplicate matrix', 'wrong source epoch', 'wrong completion epoch']:
        changed = copy.deepcopy(plan)
        if name == 'missing matrix': changed['matrices'].pop()
        elif name == 'duplicate matrix': changed['matrices'][1] = changed['matrices'][0]
        elif name == 'wrong source epoch': changed['matrices'][0]['source_epoch'] = REVISION
        else: changed['matrices'][0]['completed_revision'] = REVISION
        reject(name, lambda: plan_domain(changed), rejected)
    for name in ['missing source', 'extra source', 'changed source digest', 'changed source identity', 'lost epoch comparison', 'changed epoch result', 'wrong source total']:
        changed = copy.deepcopy(observed)
        if name == 'missing source': changed['inputs'].pop()
        elif name == 'extra source': changed['inputs'].append(copy.deepcopy(changed['inputs'][0]))
        elif name == 'changed source digest': changed['inputs'][0]['sha256'] = '0' * 64
        elif name == 'changed source identity': changed['inputs'][0]['inode'] = 7
        elif name == 'lost epoch comparison': changed['applicability'].pop()
        elif name == 'changed epoch result': changed['applicability'][0]['status'] = 'unqualified'
        else: changed['total_bytes'] += 1
        reject(name, lambda: source_inventory(plan, changed, original), rejected)
    for name in ['lost single report', 'aliased single omission', 'incomplete omission group']:
        changed = copy.deepcopy(children)
        if name == 'lost single report': changed['reports']['cases'].pop(1)
        elif name == 'aliased single omission': changed['omissions']['cases'][2] = changed['omissions']['cases'][1]
        else: next(case for case in changed['omissions']['cases'] if case['kind'] == 'all-group')['omissions'].pop()
        reject(name, lambda: coverage(changed, original), rejected)
    changed = dict(reports); changed['omissions'] = dict(reports['omissions'], allocated=reports['omissions']['allocated'] + reports['reports']['allocated'][:1])
    reject('overlapping allocation rosters', lambda: derive_counts(changed), rejected)
    reject('false root absence', lambda: absence([dict(path='.artifacts/logs')]), rejected)
    for name, raw in [('lost TAP assertion', b'ok 1 - present\n1..2\n'), ('skipped TAP assertion', b'ok 1 - skipped # SKIP\n1..1\n'), ('failed TAP assertion', b'not ok 1 - failed\n1..1\n')]:
        reject(name, lambda: tap_assertions(raw.decode()), rejected)
    # The full current catalogue, including the raw original qualifications,
    # retains both its content and native identities after all pure checks.
    assert [dict(path=row['path'], **inventory.read(row['path'])[1]) for row in records] == records
    output = dict(schema='fsmgen.inactive_archive_close_join_audit.v1', success=True, counts=counts,
        source_files=len(records), source_bytes=sum(row['size_bytes'] for row in records),
        predecessor_perl_modules=len({row['path'] for row in epochs if row['path'].endswith('.pm')}),
        epoch_comparisons=len(epochs), prospective_inputs_unchanged=len(pins),
        child_counts=child_counts, coverage=domains, receipts=receipts, falsifiers=rejected,
        all_inputs_unchanged=True, all_allocations_absent=True, limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(counts=counts, source_files=len(records), epoch_comparisons=len(epochs), falsifiers=len(rejected)), sort_keys=True))


if __name__ == '__main__':
    main()
