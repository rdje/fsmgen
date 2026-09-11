"""Read-only authentication, applicability and domain join over saved receipts."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import re

import applicability
import domains
import inventory

BASE, ROOT, LOG = inventory.BASE, inventory.ROOT, inventory.LOG
COMPONENTS = {'snapshot', 'publication', 'coordinator', 'semantic_calls',
              'semantic_close', 'remaining_close', 'namespace', 'members',
              'handoff', 'fresh', 'reuse'}
PROGRESS = {
    'snapshot':'snapshot_occurrence', 'publication':'publication_cut',
    'coordinator':'coordinator_cut', 'semantic_calls':'semantic_cut',
    'semantic_close':'semantic_close', 'remaining_close':'remaining_close',
}


def equal(left, right):
    assert json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def selected_components(plan):
    names = [row['name'] for row in plan['components']]
    assert len(names) == len(set(names)) and set(names) == COMPONENTS
    snapshot = next(row for row in plan['components'] if row['name'] == 'snapshot')
    assert snapshot['source'] == 'docs/audits/native-proxy-snapshot-occurrence-20260911'
    assert snapshot['receipt'] == snapshot['source']+'/result'
    assert snapshot['source_epoch'] == 'b2e382b393784ea6b0bf48c3345fa05a919dff97'


def check_pin(raw, record):
    assert type(record['size_bytes']) is int
    assert len(raw) == record['size_bytes']
    assert hashlib.sha256(raw).hexdigest() == record['sha256']


def authenticate(component):
    path = component['manifest']
    raw = inventory.direct_bytes(path)
    assert raw == applicability.historical(component['source_epoch'], path)
    manifest = json.loads(raw)
    assert manifest['all_copies_byte_exact'] is True
    records = {row['destination']:row for row in manifest['files']}
    assert len(records) == len(manifest['files'])
    receipts = []
    for name in component['files']:
        path = component['receipt']+'/'+name
        raw = inventory.direct_bytes(path)
        check_pin(raw, records[path])
        receipts.append(dict(path=path, **applicability.fingerprint(raw)))
    return receipts


def tap_count(raw):
    assert not re.search(r'^(?:not ok|Bail out!)', raw, re.M)
    assert not re.search(r'#\s*(?:SKIP|TODO)\b', raw, re.I)
    plans = re.findall(r'^1\.\.(\d+)$', raw, re.M)
    assert len(plans) == 1
    count = int(plans[0])
    assert re.findall(r'^ok (\d+) - ', raw, re.M) == [str(n) for n in range(1, count+1)]
    return count


def absent_roots(paths):
    assert len(paths) == len(set(paths)), 'overlapping matrix allocation rosters'
    for relative in paths:
        assert relative.startswith('.artifacts/') and '..' not in relative.split('/')
        path = ROOT/relative
        assert not path.exists() and not path.is_symlink(), 'fixture root remains'
        while path != ROOT:
            assert not path.is_symlink()
            if path.exists():
                assert path.stat().st_dev == ROOT.stat().st_dev
            path = path.parent


def join_counts(rows, roots):
    assert set(rows) == COMPONENTS
    contexts = sum(len(row['case_ids']) for row in rows.values())
    assertions = sum(row['assertions'] for row in rows.values())
    allocations = sum(row['allocations'] for row in rows.values())
    assert assertions == 2*contexts+len(rows)
    assert allocations == len(roots)
    absent_roots(roots)
    return dict(components=len(rows), contexts=contexts, assertions=assertions,
                disjoint_absent_roots=allocations)


def reject(name, check, rejected):
    try:
        check()
    except (AssertionError, KeyError, IndexError):
        rejected.append(name)
    else:
        raise AssertionError('acquisition join accepted falsifier: '+name)


def component_check(component, rejected):
    name = component['name']
    receipts = authenticate(component)
    oracle = inventory.module('acquisition_join_'+name, ROOT/component['source']/'audit.py')
    oracle.LOG = ROOT/component['receipt']
    raw = inventory.direct_bytes(component['source']+'/plan.json')
    assert hashlib.sha256(raw).hexdigest() == oracle.PLAN_SHA
    plan = json.loads(raw)
    if hasattr(oracle, 'PLAN') and hasattr(oracle.PLAN, 'build'):
        equal(plan, oracle.PLAN.build())
    result = json.loads(inventory.direct_bytes(component['receipt']+'/qualification.json'))
    names = domains.exact_records(plan, result)
    coverage = domains.coverage(component['kind'], plan)
    if component['kind'] in ('directory', 'handoff'):
        oracle.validate(result, plan, 'qualification')
        tap_name = 'qualification.tap'
    else:
        oracle.validate(result, plan)
        tap_name = 'qualify.tap'
    assertions = tap_count(inventory.direct_bytes(component['receipt']+'/'+tap_name).decode())
    assert assertions == 2*len(names)+1
    if 'rows.jsonl' in component['files']:
        journal = [json.loads(line) for line in
                   inventory.direct_bytes(component['receipt']+'/rows.jsonl').splitlines()]
        equal(journal, [dict(category=category, row=row)
                        for category in ('cases', 'mutants') for row in result[category]])
        progress = json.loads(inventory.direct_bytes(component['receipt']+'/progress.json'))
        equal(progress, dict(schema='fsmgen.inactive_'+PROGRESS[name]+'_progress.v1',
                             success=True, allocations=len(result['allocated']),
                             cases=len(result['cases']), mutants=len(result['mutants']),
                             forbidden_process_attempts=0))
    if 'execution.json' in component['files']:
        execution = json.loads(inventory.direct_bytes(component['receipt']+'/execution.json'))
        assert type(execution['exit_code']) is int and execution['exit_code'] == 0

    # Falsify the exact selector join without copying or editing the large
    # historical receipts on disk. Each independent oracle already checks the
    # full original evidence above, including actual omitted-close mutants.
    changed = dict(result, cases=result['cases'][:-1])
    reject(name+': missing recorded case', lambda:domains.exact_records(plan, changed), rejected)
    changed = dict(result, cases=[result['cases'][0]]+result['cases'][:-1])
    reject(name+': repeated recorded case', lambda:domains.exact_records(plan, changed), rejected)
    if component['kind'] in ('snapshot', 'coordinator', 'semantic_calls', 'semantic_close', 'remaining_close'):
        changed_plan = copy.deepcopy(plan)
        # Remove a real cut/single-close case from the declared plan itself,
        # which tests coverage beyond merely matching its result array.
        changed_plan['cases'].pop(1)
        reject(name+': missing declared selector',
               lambda:domains.coverage(component['kind'], changed_plan), rejected)
    print(json.dumps(dict(component=name, contexts=len(names), assertions=assertions,
                          allocations=len(result['allocated']), verified=True)), flush=True)
    return dict(source_epoch=component['source_epoch'], receipts=receipts,
                case_ids=names, assertions=assertions, allocations=len(result['allocated']),
                coverage=coverage), [row['path'] for row in result['allocated']]


def main():
    plan = json.loads((BASE/'plan.json').read_bytes())
    selected_components(plan)
    source_inventory = inventory.build(plan)
    # The initial inventory survived a lost tool return; rederive its complete
    # contents here instead of assigning an invented exit status to that job.
    equal(source_inventory, json.loads((LOG/'source-inventory.json').read_bytes()))
    applicability_rows = applicability.verify(plan, source_inventory)
    rejected = applicability.falsify(plan)
    rows, roots = {}, []
    for component in plan['components']:
        rows[component['name']], paths = component_check(component, rejected)
        roots.extend(paths)
    counts = join_counts(rows, roots)

    changed = copy.deepcopy(plan); changed['components'].pop()
    reject('missing required matrix', lambda:selected_components(changed), rejected)
    changed = copy.deepcopy(plan); changed['components'][1] = changed['components'][0]
    reject('duplicate matrix', lambda:selected_components(changed), rejected)
    changed = copy.deepcopy(plan)
    changed['components'][0]['source'] = 'docs/audits/native-proxy-observation-snapshot-cuts-20260910'
    reject('historical aliased snapshot selected as current', lambda:selected_components(changed), rejected)
    old_path = 'docs/audits/native-proxy-observation-snapshot-cuts-20260910/plan.json'
    old_raw = inventory.direct_bytes(old_path)
    assert old_raw == applicability.historical('5bb1b2366cc652416283d8959d12a9d44616498c', old_path)
    reject('authentic historical snapshot aliases',
           lambda:domains.coverage('snapshot', json.loads(old_raw)), rejected)
    reject('overlapping allocation rosters', lambda:absent_roots(roots+[roots[0]]), rejected)
    reject('existing root accepted as removed', lambda:absent_roots(['.artifacts/logs']), rejected)
    changed_rows = copy.deepcopy(rows); changed_rows['snapshot']['allocations'] -= 1
    reject('wrong joined resource total', lambda:join_counts(changed_rows, roots), rejected)
    changed_rows = copy.deepcopy(rows); changed_rows['snapshot']['assertions'] -= 1
    reject('wrong joined assertion total', lambda:join_counts(changed_rows, roots), rejected)
    raw = inventory.direct_bytes(plan['components'][0]['receipt']+'/qualify.tap')
    pin = applicability.fingerprint(raw)
    reject('receipt byte changed', lambda:check_pin(raw+b'\n', pin), rejected)
    reject('receipt hash changed', lambda:check_pin(raw, dict(pin, sha256='0'*64)), rejected)
    changed = copy.deepcopy(plan['components'][0]); changed['files'].append('missing-receipt.json')
    reject('missing required receipt', lambda:authenticate(changed), rejected)
    changed = copy.deepcopy(plan); changed['components'][0]['source_epoch'] = plan['components'][1]['source_epoch']
    reject('wrong occurrence source epoch', lambda:selected_components(changed), rejected)
    assert len(rejected) == len(set(rejected))
    # Recheck all inventoried bytes after the join; the evidence applies to one
    # unchanged local source state, never to a moving source checkout.
    for pin in source_inventory['source_pins']:
        check_pin(inventory.direct_bytes(pin['path']), pin)
    report = dict(schema='fsmgen.inactive_observation_acquisition_join.v1', success=True,
        owner=plan['owner'], source_revision=plan['source_revision'], counts=counts,
        components=rows, source_applicability=applicability_rows,
        source_inventory=inventory.pin(str((LOG/'source-inventory.json').relative_to(ROOT))),
        historical_snapshot_plan=inventory.pin(old_path),
        falsifiers=rejected, no_fixture_or_native_execution=True,
        inventory_recovery='Initial inventory completion output and complete report survived; original tool exit status unavailable. Recorded supervisor PID was absent. This completed join independently regenerated and compared the entire inventory.',
        limits=plan['limits'], coverage_limit=plan['coverage'])
    (LOG/'audit.json').write_text(json.dumps(report, indent=2, sort_keys=True)+'\n')
    print(json.dumps(dict(success=True, **counts,
        source_comparisons=len(applicability_rows),
        qualified_function_replacements=sum(row['status'] != 'exact' for row in applicability_rows),
        authenticated_receipts=sum(len(row['receipts']) for row in rows.values()),
        falsifiers=len(rejected)), sort_keys=True), flush=True)


if __name__ == '__main__':
    main()
