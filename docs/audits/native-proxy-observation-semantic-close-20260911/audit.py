"""Independent census close occurrence, complete cleanup and error oracle."""
from __future__ import annotations

import copy
import errno
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT/'.artifacts/logs/native-proxy-observation-semantic-close-20260911'
PLAN_SHA = 'd2f3c20d2389c43b38bec715e825c34928237b01ce70a42b376a14702c89b934'


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


PLAN = module('semantic_close_plan', BASE/'plan.py')
SEM = module('semantic_close_prior_oracle', BASE.parent/'native-proxy-observation-semantic-cuts-20260911/audit.py')
COORD, SNAPSHOT, FRESH = SEM.COORD, SEM.SNAPSHOT, SEM.FRESH
equal, integer = SEM.equal, SEM.integer


def error_text(expected, phase):
    if expected is None: return ''
    if expected['kind'] == 'primary':
        return 'injected semantic close primary: '+phase+':'+expected['event']+'\n'
    label = expected['label']
    kind = 'reference' if label.startswith('original:') else 'fresh reference' if label.startswith('fresh:') else 'image input'
    return 'cannot close '+kind+': '+os.strerror(getattr(errno, expected['errno']))+'\n'


def occurrence(row, label):
    records, flow, _ = SEM.binding(row)
    event = next(item['event'] for item in flow if PLAN.source_label(item['event']) == label)
    if label.startswith(('original:', 'fresh:')):
        path = row['context']['store']['path']+'/references/'+records[int(label.split(':')[1])]['reference_key']+'.json'
    else:
        _, _, role, member = label.split(':')
        runtime = row['context']['runtime' if role == 'primary' else 'other_runtime']
        path = runtime['image']['snapshots'][0 if member == 'c' else 1]['identity']['path']
    number = SEM.resource_counts(row, event)['source'][path]
    candidates = [index for index, entry in enumerate(row['handles']) if entry['kind'] == 'source' and entry['path'] == path]
    return path, candidates[number]


def close_calls(row, spec, expected, mutant):
    calls = row['close_calls']
    equal([call['label'] for call in calls], expected['closes'])
    omitted = None
    if mutant:
        path, number = SEM.selected_occurrence(row, spec['guard'])
        omitted = [i for i,h in enumerate(row['handles']) if h['kind'] == 'source' and h['path'] == path][number]
    for call in calls:
        assert set(call) == {'label', 'path', 'handle_index', 'descriptor', 'actual_attempted',
            'actual_close_ok', 'actual_errno', 'reported_errno', 'returned', 'closed_after_call'}
        path, index = occurrence(row, call['label'])
        assert call['path'] == path
        integer(call['handle_index']); assert call['handle_index'] == index
        integer(call['descriptor']); assert call['descriptor'] == row['handles'][index]['descriptor']
        skipped = index == omitted
        for field, value in dict(actual_attempted=int(not skipped), closed_after_call=int(not skipped)).items():
            integer(call[field]); assert call[field] == value
        if skipped:
            assert call['actual_close_ok'] is None and call['actual_errno'] is None
        else:
            integer(call['actual_close_ok']); assert call['actual_close_ok'] == 1
            integer(call['actual_errno']); assert call['actual_errno'] == 0
        report = getattr(errno, spec['reports'][call['label']]) if call['label'] in spec['reports'] else 0
        integer(call['reported_errno']); assert call['reported_errno'] == report
        integer(call['returned']); assert call['returned'] == int(report == 0)


def row_valid(row, spec, allocations, mutant):
    assert row['id'] == spec['id'] and row['route'] == spec['route'] and row['phase'] == spec['phase']
    SNAPSHOT.context_valid(row, allocations)
    _, flow, binding = SEM.binding(row)
    assert row['binding'] == binding
    expected = PLAN.execution(flow, spec)
    equal(expected, spec['expectations'][binding])
    equal(row['trace'], expected['trace'])
    integer(row['cut_fired']); assert row['cut_fired'] == int(spec['cut'] is not None)
    healthy = expected['error'] is None
    integer(row['returned']); assert row['returned'] == int(healthy)
    integer(row['omitted_close_calls']); assert row['omitted_close_calls'] == int(mutant)
    assert row['error'] == error_text(expected['error'], row['phase'])
    after = copy.deepcopy(row['before']); record = FRESH.expected_observation(row['context'])
    relative = 'references/'+record['reference_key']+'.json'
    if spec['hold'] == 'complete':
        node = row['after']['store'][relative]
        SNAPSHOT.file_node(node, FRESH.canonical(record), 0o400)
        if row['route'] == 'fresh':
            assert relative not in after['store']; after['store'][relative] = node
    else: assert row['route'] == 'fresh' and relative not in after['store']
    equal(after, row['after'])
    if healthy:
        FRESH.check_success(dict(row, name='fresh acquisition'))
        if row['route'] == 'reuse': equal(row['result'], row['context']['previous'])
    else: assert 'result' not in row
    resource_spec = dict(spec)
    if not healthy and spec['cut'] is None:
        # Reported failure follows a completed final directory/fresh-reference/
        # census-return boundary. Each has no resource effect of its own, so
        # its already-qualified pre-call count equals the failure's count.
        boundary = expected['completed_calls'][-1]
        assert next(item for item in flow if item['event'] == boundary)['effect'] is None
        resource_spec['cut'] = boundary
    SEM.custody(row, resource_spec, mutant)
    close_calls(row, spec, expected, mutant)
    if mutant:
        for check in (lambda: SEM.custody(row, resource_spec), lambda: close_calls(row, spec, expected, False)):
            try: check()
            except AssertionError: pass
            else: raise AssertionError('strict custody accepted actual omitted close')


def validate(result, plan):
    assert result['schema'] == 'fsmgen.inactive_observation_semantic_close_qualification.v1'
    assert result['success'] is True and 'first_failure' not in result and 'unexpected_error' not in result
    integer(result['forbidden_process_attempts']); assert result['forbidden_process_attempts'] == 0
    ledger = [json.loads(line) for line in (LOG/'admission.jsonl').read_text().splitlines()]
    equal(ledger, result['allocated']); allocations = {entry['path']:entry for entry in ledger}
    assert len(ledger) == len(allocations) == 4*(len(plan['cases'])+len(plan['mutants']))
    for path, entry in allocations.items():
        assert set(entry) == {'kind', 'path', 'device', 'inode'}
        prefix = {'store':'.artifacts/tmp/native-proxy-image-custody/cases/',
            'workspace':'.artifacts/tmp/process-supervisor-tests/',
            'evidence':'.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/'}[entry['kind']]
        assert re.fullmatch(re.escape(prefix)+r'fsmgen-[A-Za-z0-9_]+', path)
        FRESH.native(entry); assert not (ROOT/path).exists() and not (ROOT/path).is_symlink()
    used = []
    for category in ('cases', 'mutants'):
        assert [row['id'] for row in result[category]] == [spec['id'] for spec in plan[category]]
        for row, spec in zip(result[category], plan[category]):
            row_valid(row, spec, allocations, category == 'mutants')
            used.extend(row['context'][kind]['path'] for kind in SNAPSHOT.KINDS)
    assert len(used) == len(set(used)) and set(used) == set(allocations)


def main():
    raw = (BASE/'plan.json').read_bytes(); assert hashlib.sha256(raw).hexdigest() == PLAN_SHA
    plan = json.loads(raw); equal(plan, PLAN.build())
    result = json.loads((LOG/'qualification.json').read_bytes()); validate(result, plan)
    equal([json.loads(line) for line in (LOG/'rows.jsonl').read_text().splitlines()],
          [dict(category=c, row=r) for c in ('cases', 'mutants') for r in result[c]])
    equal(json.loads((LOG/'progress.json').read_bytes()), dict(schema='fsmgen.inactive_semantic_close_progress.v1',
        success=True, allocations=len(result['allocated']), cases=len(result['cases']), mutants=len(result['mutants']), forbidden_process_attempts=0))
    assertions = FRESH.RUNTIME.tap_count((LOG/'qualify.tap').read_text())
    assert assertions == 2*(len(plan['cases'])+len(plan['mutants']))+1
    falsifiers = []
    changes = [
        ('hidden failure', lambda x:x.update(success=False)),
        ('lost case', lambda x:x['cases'].pop()),
        ('lost close attempt', lambda x:x['cases'][0]['close_calls'].pop()),
        ('invented actual close', lambda x:x['cases'][0]['close_calls'][0].update(actual_close_ok=0)),
        ('close still open', lambda x:x['cases'][0]['close_calls'][0].update(closed_after_call=0)),
        ('wrong source occurrence', lambda x:x['cases'][0]['close_calls'][0].update(handle_index=0)),
        ('suppressed close report', lambda x:x['cases'][1]['close_calls'][-3].update(reported_errno=0)),
        ('changed first report', lambda x:next(r for r in x['cases'] if r['id']=='fresh:pre:all_originals').update(error='cannot close reference: '+os.strerror(errno.ENOSPC)+'\n')),
        ('lost primary precedence', lambda x:next(r for r in x['cases'] if r['id']=='fresh:pre:original_primary:0').update(error='cannot close reference: '+os.strerror(errno.EIO)+'\n')),
        ('lost call', lambda x:x['cases'][0]['trace'].pop()),
        ('lost source', lambda x:x['cases'][0]['handles'].remove(next(h for h in x['cases'][0]['handles'] if h['kind']=='source'))),
        ('lost directory', lambda x:x['cases'][0]['handles'].remove(next(h for h in x['cases'][0]['handles'] if h['kind']=='directory'))),
        ('lost other owner', lambda x:x['cases'][0]['after']['store'].pop('references/'+x['cases'][0]['context']['seeded_record']['reference_key']+'.json')),
        ('lost failed hold', lambda x:next(r for r in x['cases'] if r['id']=='fresh:post:original:0')['after']['store'].pop('references/'+FRESH.expected_observation(next(r for r in x['cases'] if r['id']=='fresh:post:original:0')['context'])['reference_key']+'.json')),
        ('wrong binding', lambda x:x['cases'][0].update(binding='unplanned')),
        ('authority type changed', lambda x:x['cases'][0]['result'].update(runtime_authorized=False)),
        ('lost allocation', lambda x:x['allocated'].pop()),
        ('forbidden process', lambda x:x.update(forbidden_process_attempts=1)),
    ]
    for name, change in changes:
        altered = copy.deepcopy(result); change(altered)
        try: validate(altered, plan)
        except (AssertionError, KeyError, IndexError): falsifiers.append(name)
        else: raise AssertionError('oracle missed falsifier: '+name)
    report = dict(schema='fsmgen.inactive_observation_semantic_close_audit.v1', success=True,
        cases=len(plan['cases']), mutants=[row['id'] for row in plan['mutants']],
        assertions=assertions, allocations=len(result['allocated']), falsifiers=falsifiers,
        modeled_reports=sum(bool(row['reports']) for row in plan['cases']),
        competing_primary_errors=sum(row['cut'] is not None for row in plan['cases']), limits=plan['limits'])
    (LOG/'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2)+'\n')
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()
