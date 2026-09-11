"""Independent full-operation counts, close occurrences and cleanup precedence."""
from __future__ import annotations

from collections import Counter
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
LOG = ROOT/'.artifacts/logs/native-proxy-observation-remaining-close-20260911'
PLAN_SHA = 'f1e73b163a51eb3628f6bf95bc40cb486e4c7c62c96d9a00dea911ebde56c4ee'


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


PLAN = module('remaining_close_plan', BASE/'plan.py')
SNAPSHOT = module('remaining_corrected_snapshot', BASE.parent/'native-proxy-snapshot-occurrence-20260911/audit.py')
COORD = module('remaining_coordinator', BASE.parent/'native-proxy-observation-coordinator-cuts-20260911/audit.py')
FRESH = SNAPSHOT.FRESH
equal, integer = COORD.equal, COORD.integer


def paths_for(row):
    paths = SNAPSHOT.path_roles(row['context'])
    paths['global'] = paths.pop('global_')
    return paths


def resource_counts(row, completed):
    context = row['context']; store = context['store']['path']; paths = paths_for(row)
    counts = {kind:Counter() for kind in ('source','writer','lock','directory')}
    directories = dict(store=store, images=store+'/images', references=store+'/references')
    flow = PLAN.flow(row['route'])
    assert [item['event'] for item in flow[:len(completed)]] == completed
    for item in flow[:len(completed)]:
        effect = item['effect'] or {}
        if effect.get('lock'): counts['lock'][store+'/coordination.lock'] += 1
        if 'directory' in effect: counts['directory'][directories[effect['directory']]] += 1
        if 'reference' in effect:
            counts['source'][COORD.reference_paths(row, effect['reference'])[effect['index']]] += 1
        if 'semantic' in effect:
            for path in COORD.reference_paths(row, effect['semantic']): counts['source'][path] += 2
            counts['directory'][directories['references']] += 1
            for runtime in (context['runtime'], context['other_runtime']):
                for source, count in zip(runtime['image']['snapshots'], (4,4,2)):
                    counts['source'][source['identity']['path']] += count
                counts['directory'][store+'/images/'+runtime['image']['key']] += 4
        if 'target' in effect: counts['source'][paths[effect['target']]] += 1
        if effect.get('publication'):
            counts['writer'][paths['hold']] += 1
            counts['source'][paths['hold']] += 1
    return counts


def occurrence(row, label):
    flow = PLAN.flow(row['route'])
    matches = [i for i,item in enumerate(flow) if PLAN.source_label(item['event']) == label]
    assert len(matches) == 1
    before = [item['event'] for item in flow[:matches[0]]]
    if label == 'lock': kind, path = 'lock', row['context']['store']['path']+'/coordination.lock'
    elif label.startswith('census:'):
        _, phase, index = label.split(':')
        kind, path = 'source', COORD.reference_paths(row, phase)[int(index)]
    else: kind, path = 'source', paths_for(row)[label.split(':')[-1]]
    ordinal = resource_counts(row, before)[kind][path]
    candidates = [i for i,h in enumerate(row['handles']) if h['kind'] == kind and h['path'] == path]
    return path, candidates[ordinal]


def error_text(reason):
    if reason is None: return ''
    if reason['kind'] == 'primary': return 'injected remaining close primary: '+reason['event']+'\n'
    label = reason['label']
    kind = ('permanent lock' if label == 'lock' else 'observation hold' if label == 'hold'
            else 'observation source' if label.startswith('target:')
            else 'fresh observation source' if label.startswith('fresh:') else 'census reference')
    return 'cannot close '+kind+': '+os.strerror(getattr(errno, reason['errno']))+'\n'


def custody(row, expected, omitted=None):
    context = row['context']; handles = row['handles']
    counts = resource_counts(row, expected['completed_calls'])
    assert all(h['kind'] in counts for h in handles)
    for kind, count in counts.items():
        assert Counter(h['path'] for h in handles if h['kind'] == kind) == +count, (row['id'],kind)
    if expected['error'] is None:
        # Independently qualified complete coordinator totals must agree with
        # the composed granular source flow, not merely its event count.
        equal({k:dict(+v) for k,v in counts.items()},
              {k:dict(+v) for k,v in COORD.resource_counts(row, None).items()})
    integer(row['lock_cloexec_after_set']); assert row['lock_cloexec_after_set'] == 1
    selected = occurrence(row, omitted)[1] if omitted else None
    values = SNAPSHOT.all_bytes(context)
    for index, entry in enumerate(handles):
        integer(entry['descriptor']); FRESH.native(entry['identity'])
        roots = [kind for kind in SNAPSHOT.KINDS if entry['path'] == context[kind]['path']]
        node = row['after'][roots[0]][''] if roots else FRESH.node_for(row['after'],context,entry['path'])
        if entry['kind'] == 'directory':
            assert node['kind'] == 'directory'
            equal(entry['identity'],{key:node[key] for key in ('device','inode','mode','uid')})
            integer(entry['observer_descriptor']); assert entry['observer_descriptor'] != entry['descriptor']
            for field in ('observer_close_ok','observer_closed'):
                integer(entry[field]); assert entry[field] == 1
        else:
            assert node['kind'] == 'file'
            identity = {key:node[key] for key in ('device','inode','mode','links','uid')}
            identity['size_bytes'] = 0 if entry['kind'] == 'writer' else node['bytes']
            equal(entry['identity'],identity)
        if entry['kind'] == 'source':
            integer(entry['cloexec']); assert entry['cloexec'] == 1
            FRESH.observed_source(entry['snapshot'],entry['path'],values[entry['path']],node['mode'],row['after'],context)
        else: assert 'snapshot' not in entry and 'cloexec' not in entry
        integer(entry['closed_before_recovery']); assert entry['closed_before_recovery'] == int(index != selected)
        integer(entry['closed_after_recovery']); assert entry['closed_after_recovery'] == 1
        if index == selected:
            integer(entry['recovery_close_ok']); assert entry['recovery_close_ok'] == 1
            integer(entry['open_cloexec']); assert entry['open_cloexec'] == 1
            equal(entry['current_identity'],entry['identity'])
        else:
            assert entry['recovery_close_ok'] is None
            assert 'current_identity' not in entry and 'open_cloexec' not in entry


def close_calls(row, spec, expected, omitted=None):
    equal([call['label'] for call in row['close_calls']], expected['closes'])
    for call in row['close_calls']:
        assert set(call) == {'label','path','handle_index','descriptor','actual_attempted',
            'actual_close_ok','actual_errno','reported_errno','returned','closed_after_call'}
        path, index = occurrence(row,call['label'])
        assert call['path'] == path
        integer(call['handle_index']); assert call['handle_index'] == index
        integer(call['descriptor']); assert call['descriptor'] == row['handles'][index]['descriptor']
        skipped = call['label'] == omitted
        for field in ('actual_attempted','closed_after_call'):
            integer(call[field]); assert call[field] == int(not skipped)
        if skipped: assert call['actual_close_ok'] is None and call['actual_errno'] is None
        else:
            integer(call['actual_close_ok']); assert call['actual_close_ok'] == 1
            integer(call['actual_errno']); assert call['actual_errno'] == 0
        report = getattr(errno,spec['reports'][call['label']]) if call['label'] in spec['reports'] else 0
        integer(call['reported_errno']); assert call['reported_errno'] == report
        integer(call['returned']); assert call['returned'] == int(report == 0)


def row_valid(row, spec, allocations, mutant):
    assert row['id'] == spec['id'] and row['route'] == spec['route']
    SNAPSHOT.context_valid(row,allocations)
    expected = PLAN.execution(row['route'],spec); equal(expected,spec['expectation'])
    equal(row['trace'],expected['trace'])
    for field, value in dict(cut_fired=int(spec['cut'] is not None),
            returned=int(expected['error'] is None), omitted_close_calls=int(mutant),
            fault_seen=int(bool(spec['reports']))).items():
        integer(row[field]); assert row[field] == value
    assert row['error'] == error_text(expected['error'])
    after = copy.deepcopy(row['before']); record = FRESH.expected_observation(row['context'])
    relative = 'references/'+record['reference_key']+'.json'
    if expected['hold'] == 'complete':
        node = row['after']['store'][relative]; SNAPSHOT.file_node(node,FRESH.canonical(record),0o400)
        if row['route'] == 'fresh':
            assert relative not in after['store']; after['store'][relative] = node
    else: assert row['route'] == 'fresh' and relative not in after['store']
    equal(after,row['after'])
    if expected['error'] is None:
        FRESH.check_success(dict(row,name='fresh acquisition'))
        if row['route'] == 'reuse': equal(row['result'],row['context']['previous'])
    else: assert 'result' not in row
    omitted = spec['omit'] if mutant else None
    custody(row,expected,omitted); close_calls(row,spec,expected,omitted)
    if mutant:
        for check in (lambda:custody(row,expected),lambda:close_calls(row,spec,expected)):
            try: check()
            except AssertionError: pass
            else: raise AssertionError('strict oracle accepted an actual omitted close')


def validate(result,plan):
    assert result['schema'] == 'fsmgen.inactive_observation_remaining_close_qualification.v1'
    assert result['success'] is True and 'first_failure' not in result and 'unexpected_error' not in result
    for flow in plan['flows'].values(): assert len(flow) == len({row['event'] for row in flow})
    for collection in (plan,result):
        rows = collection['cases']+collection['mutants']; assert len(rows) == len({row['id'] for row in rows})
    integer(result['forbidden_process_attempts']); assert result['forbidden_process_attempts'] == 0
    ledger = [json.loads(line) for line in (LOG/'admission.jsonl').read_text().splitlines()]
    equal(ledger,result['allocated']); allocations = {row['path']:row for row in ledger}
    assert len(ledger) == len(allocations) == 4*(len(plan['cases'])+len(plan['mutants']))
    for path,entry in allocations.items():
        assert set(entry) == {'kind','path','device','inode'}
        prefix = {'store':'.artifacts/tmp/native-proxy-image-custody/cases/',
            'workspace':'.artifacts/tmp/process-supervisor-tests/',
            'evidence':'.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/'}[entry['kind']]
        assert re.fullmatch(re.escape(prefix)+r'fsmgen-[A-Za-z0-9_]+',path)
        FRESH.native(entry); assert not (ROOT/path).exists() and not (ROOT/path).is_symlink()
    used = []
    for category in ('cases','mutants'):
        assert [row['id'] for row in result[category]] == [spec['id'] for spec in plan[category]]
        for row,spec in zip(result[category],plan[category]):
            row_valid(row,spec,allocations,category == 'mutants')
            used.extend(row['context'][kind]['path'] for kind in SNAPSHOT.KINDS)
    assert len(used) == len(set(used)) and set(used) == set(allocations)


def main():
    raw = (BASE/'plan.json').read_bytes(); assert hashlib.sha256(raw).hexdigest() == PLAN_SHA
    plan = json.loads(raw); equal(plan,PLAN.build())
    result = json.loads((LOG/'qualification.json').read_bytes()); validate(result,plan)
    equal([json.loads(line) for line in (LOG/'rows.jsonl').read_text().splitlines()],
          [dict(category=c,row=r) for c in ('cases','mutants') for r in result[c]])
    equal(json.loads((LOG/'progress.json').read_bytes()),dict(schema='fsmgen.inactive_remaining_close_progress.v1',
        success=True,allocations=len(result['allocated']),cases=len(result['cases']),mutants=len(result['mutants']),forbidden_process_attempts=0))
    assertions = FRESH.RUNTIME.tap_count((LOG/'qualify.tap').read_text())
    assert assertions == 2*(len(plan['cases'])+len(plan['mutants']))+1
    falsifiers = []

    def earlier_occurrence(value):
        row = value['cases'][0]; call = next(c for c in row['close_calls'] if c['label']=='target:global')
        call['handle_index'] = next(i for i,h in enumerate(row['handles']) if h['kind']=='source' and h['path']==call['path'])

    for name,change in [
        ('hidden failure',lambda x:x.update(success=False)),
        ('lost close site',lambda x:x['cases'].pop()),
        ('aliased case',lambda x:x['cases'][1].update(id=x['cases'][0]['id'])),
        ('lost close attempt',lambda x:x['cases'][0]['close_calls'].pop()),
        ('invented actual close',lambda x:x['cases'][0]['close_calls'][0].update(actual_close_ok=0)),
        ('close still open',lambda x:x['cases'][0]['close_calls'][0].update(closed_after_call=0)),
        ('earlier same-path occurrence',earlier_occurrence),
        ('suppressed lock report',lambda x:x['cases'][1]['close_calls'][-1].update(reported_errno=0)),
        ('changed first report',lambda x:next(r for r in x['cases'] if r['id']=='fresh:all_targets').update(error='cannot close observation source: '+os.strerror(errno.ENOSPC)+'\n')),
        ('lost primary precedence',lambda x:next(r for r in x['cases'] if r['id']=='fresh:admit_primary').update(error='cannot close observation source: '+os.strerror(errno.EIO)+'\n')),
        ('lost call',lambda x:x['cases'][0]['trace'].pop()),
        ('lost source',lambda x:x['cases'][0]['handles'].remove(next(h for h in x['cases'][0]['handles'] if h['kind']=='source'))),
        ('lost directory',lambda x:x['cases'][0]['handles'].remove(next(h for h in x['cases'][0]['handles'] if h['kind']=='directory'))),
        ('lost lock seal',lambda x:x['cases'][0].update(lock_cloexec_after_set=0)),
        ('lost other owner',lambda x:x['cases'][0]['after']['store'].pop('references/'+x['cases'][0]['context']['seeded_record']['reference_key']+'.json')),
        ('lost failed hold',lambda x:x['cases'][1]['after']['store'].pop('references/'+FRESH.expected_observation(x['cases'][1]['context'])['reference_key']+'.json')),
        ('authority type changed',lambda x:x['cases'][0]['result'].update(runtime_authorized=False)),
        ('lost omitted marker',lambda x:x['mutants'][0].update(omitted_close_calls=0)),
        ('lost allocation',lambda x:x['allocated'].pop()),
        ('forbidden process',lambda x:x.update(forbidden_process_attempts=1)),
    ]:
        changed = copy.deepcopy(result); change(changed)
        try: validate(changed,plan)
        except (AssertionError,KeyError,IndexError): falsifiers.append(name)
        else: raise AssertionError('remaining close oracle missed falsifier: '+name)
    report = dict(schema='fsmgen.inactive_observation_remaining_close_audit.v1',success=True,
        cases=len(plan['cases']),mutants=[case['id'] for case in plan['mutants']],
        assertions=assertions,allocations=len(result['allocated']),falsifiers=falsifiers,
        flow_lengths={route:len(flow) for route,flow in plan['flows'].items()},
        modeled_report_cases=sum(bool(case['reports']) for case in plan['cases']),
        competing_primary_cases=sum(case['cut'] is not None for case in plan['cases']),limits=plan['limits'])
    (LOG/'audit.json').write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
    print(json.dumps(report,sort_keys=True))


if __name__ == '__main__':
    main()
