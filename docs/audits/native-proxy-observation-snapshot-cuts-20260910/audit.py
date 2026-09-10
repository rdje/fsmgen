"""Independent source-flow, descriptor multiset and unchanged-owner oracle."""
from __future__ import annotations

from collections import Counter
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-snapshot-cuts-20260910'
PLAN_SHA = 'e1bc62c41afefe8a694d03eb4152dbf07d5818d436e7607af7f82a21d6a4397d'


def module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


PLAN = module('snapshot_cut_plan', BASE/'plan.py')
FRESH = module('snapshot_fresh_oracle', BASE.parent/'native-proxy-observation-acquisition-20260910/audit.py')
KINDS = ('store','workspace','other_workspace','evidence')


def equal(a, b) -> None:
    # JSON booleans, strings and integers remain distinct in comparisons.
    assert FRESH.canonical(a) == FRESH.canonical(b)


def file_node(node: dict, raw: bytes, mode: int) -> None:
    FRESH.native(node)
    equal(node, dict(FRESH.file_fields(raw,mode),device=node['device'],inode=node['inode'],uid=os.getuid()))


def seed_record(context: dict) -> dict:
    value = FRESH.expected_observation(context)
    value['image_key'] = context['other_runtime']['image']['key']
    value['selected_sources'] = context['other_runtime']['reference']['record']['selected_sources']
    for name in ('observer_birth','target_birth'): value[name]['pid'] += 1000
    value['reference_key'] = FRESH.OBSERVATION.key(value)
    FRESH.OBSERVATION.validate(context['store']['path'],FRESH.canonical(value).decode('ascii'))
    return value


def context_valid(row: dict, allocations: dict) -> None:
    context = row['context']
    for kind in KINDS: equal(context[kind], allocations[context[kind]['path']])
    FRESH.ACQUISITION.acquisition(context['runtime'],allocations,FRESH.IMAGE)
    FRESH.ACQUISITION.acquisition(context['other_runtime'],allocations,FRESH.IMAGE+b'other')
    equal(context['request'],dict(workspace_identity=FRESH.identity(context['workspace']),
        evidence_directory_identity=FRESH.identity(context['evidence']),
        observer_birth=dict(pid=101,ppid=100,uid=501,ruid=501,start_sec=123,start_usec=456),
        target_birth=dict(pid=201,ppid=200,uid=501,ruid=501,start_sec=124,start_usec=789)))
    FRESH.check_before(dict(context=context,before=context['before_seed'],name='fresh acquisition'))
    seeded = seed_record(context)
    equal(context['seeded_record'],seeded)
    path = 'references/'+seeded['reference_key']+'.json'
    expected = copy.deepcopy(context['before_seed'])
    node = context['before_acquisition']['store'][path]
    file_node(node,FRESH.canonical(seeded),0o400)
    assert path not in expected['store']
    expected['store'][path] = node
    equal(expected,context['before_acquisition'])
    if row['route'] == 'reuse':
        FRESH.check_success(dict(context=context,name='fresh acquisition',returned=1,error='',
            before=context['before_acquisition'],after=context['after_acquisition'],result=context['previous']))
    else:
        assert 'previous' not in context
        equal(context['before_acquisition'],context['after_acquisition'])
    equal(row['before'],context['after_acquisition'])
    equal(row['request_after'],context['request'])
    equal(row['previous_after'],context.get('previous'))


def path_roles(context: dict) -> dict:
    runtime = context['runtime']
    own = FRESH.expected_observation(context)
    return dict(wrapper=context['workspace']['path']+'/rust-tool-resolution',
        private=runtime['reference']['private']['identity']['path'],
        global_=runtime['reference']['global']['identity']['path'],
        c=runtime['image']['snapshots'][0]['identity']['path'],
        image=runtime['image']['snapshots'][1]['identity']['path'],
        hold=context['store']['path']+'/references/'+own['reference_key']+'.json')


def expected_sources(row: dict, cut: str | None) -> Counter:
    context = row['context']
    roles = path_roles(context)
    roles['global'] = roles.pop('global_')
    counts = Counter()

    def census(footprint: dict) -> None:
        store = context['store']['path']
        for relative in footprint['store']:
            if relative.startswith('references/'):
                counts[store+'/'+relative] += 3
        for runtime in (context['runtime'],context['other_runtime']):
            for snapshot, count in zip(runtime['image']['snapshots'], (4,4,2)):
                counts[snapshot['identity']['path']] += count

    census(row['before'])
    # A finish entry is called only after publication/reuse and both complete
    # post-operation censuses. Those operations are outside this cut domain.
    if cut is None or cut.startswith('finish:'):
        census(row['after'])
        if row['route'] == 'fresh': counts[roles['hold']] += 1  # Writer readback.
    events = PLAN.trace(row['route'])
    completed = events if cut is None else events[:events.index(cut)]
    for event in completed:
        fields = event.split(':')
        if ':sources:read:' in event or event.startswith('admit:read:'):
            counts[roles[fields[-1]]] += 1
        elif event == 'finish:hold:read': counts[roles['hold']] += 1
    return counts


def all_bytes(context: dict) -> dict:
    values = {}
    for kind, runtime in [('workspace',context['runtime']),('other_workspace',context['other_runtime'])]:
        values[context[kind]['path']+'/rust-tool-resolution'] = FRESH.WRAPPER
        for snapshot in runtime['image']['snapshots']:
            values[snapshot['identity']['path']] = snapshot['bytes'].encode('latin1')
        for field in ('global','private'):
            values[runtime['reference'][field]['identity']['path']] = FRESH.canonical(runtime['reference']['record'])
    for record in (seed_record(context), FRESH.expected_observation(context)):
        values[context['store']['path']+'/references/'+record['reference_key']+'.json'] = FRESH.canonical(record)
    return values


def custody(row: dict, cut: str | None, allow_mutant: bool = False) -> None:
    context = row['context']
    handles = row['handles']
    sources = [h for h in handles if h['kind'] == 'source']
    locks = [h for h in handles if h['kind'] == 'lock']
    writers = [h for h in handles if h['kind'] == 'writer']
    assert len(handles) == len(sources)+len(locks)+len(writers)
    assert len(locks) == 1
    assert locks[0]['path'] == context['store']['path']+'/coordination.lock'
    has_publication = row['route'] == 'fresh' and (cut is None or cut.startswith('finish:'))
    assert len(writers) == int(has_publication)
    if writers: assert writers[0]['path'] == path_roles(context)['hold']
    assert Counter(h['path'] for h in sources) == expected_sources(row,cut),(row['id'],'source roster differs')
    values = all_bytes(context)
    opened = []
    for entry in handles:
        assert type(entry['descriptor']) is int and entry['descriptor'] >= 0
        FRESH.native(entry['identity'])
        node = FRESH.node_for(row['after'],context,entry['path'])
        identity = {key:node[key] for key in ('device','inode','mode','links','uid')}
        identity['size_bytes'] = 0 if entry['kind'] == 'writer' else node['bytes']
        equal(entry['identity'],identity)
        if entry['kind'] == 'source':
            assert type(entry['cloexec']) is int and entry['cloexec'] == 1
            FRESH.observed_source(entry['snapshot'],entry['path'],values[entry['path']],node['mode'],row['after'],context)
        else:
            assert 'snapshot' not in entry and 'cloexec' not in entry
        assert type(entry['closed_before_recovery']) is int and entry['closed_before_recovery'] in (0,1)
        assert type(entry['closed_after_recovery']) is int and entry['closed_after_recovery'] == 1
        if entry['closed_before_recovery']:
            assert entry['recovery_close_ok'] is None
            assert 'current_identity' not in entry and 'open_cloexec' not in entry
        else:
            assert allow_mutant and entry['kind'] == 'source'
            assert type(entry['recovery_close_ok']) is int and entry['recovery_close_ok'] == 1
            assert type(entry['open_cloexec']) is int and entry['open_cloexec'] == 1
            equal(entry['current_identity'],entry['identity'])
            opened.append(entry)
    roles = path_roles(context)
    expected_open = {roles[name] for name in ('wrapper','private','global_','c','image')}
    if row['route'] == 'reuse': expected_open.add(roles['hold'])
    if allow_mutant:
        assert len(opened) == len(expected_open) and {h['path'] for h in opened} == expected_open
        assert len({h['descriptor'] for h in opened}) == len(opened)
    else:
        assert opened == []


def row_valid(row: dict, spec: dict, allocations: dict, mutant: bool) -> None:
    assert row['id'] == spec['id'] and row['route'] == spec['route']
    context_valid(row,allocations)
    context = row['context']
    cut = spec.get('cut')
    events = PLAN.trace(row['route'])
    equal(row['trace'],events if cut is None else events[:events.index(cut)+1])
    assert type(row['cut_fired']) is int and row['cut_fired'] == int(cut is not None)
    assert type(row['returned']) is int and row['returned'] == int(cut is None)
    assert row['error'] == ('' if cut is None else 'injected snapshot cut: '+cut+'\n')
    record = FRESH.expected_observation(context)
    relative = 'references/'+record['reference_key']+'.json'
    expected = copy.deepcopy(row['before'])
    hold = 'complete' if mutant else spec['hold']
    if hold == 'complete':
        node = row['after']['store'][relative]
        file_node(node,FRESH.canonical(record),0o400)
        if row['route'] == 'fresh':
            assert relative not in expected['store']
            expected['store'][relative] = node
    else:
        assert row['route'] == 'fresh' and relative not in expected['store']
    equal(expected,row['after'])
    if cut is None:
        FRESH.check_success(dict(row,name='fresh acquisition'))
        if row['route'] == 'reuse': equal(row['result'],context['previous'])
    else:
        assert 'result' not in row
    custody(row,cut,mutant)
    if mutant:
        try:
            custody(row,cut)
        except AssertionError:
            pass
        else:
            raise AssertionError('missing close mutant passed strict custody')


def validate(result: dict, plan: dict) -> None:
    assert result['schema'] == 'fsmgen.inactive_observation_snapshot_cuts_qualification.v1'
    assert result['success'] is True and 'first_failure' not in result and 'unexpected_error' not in result
    assert type(result['forbidden_process_attempts']) is int and result['forbidden_process_attempts'] == 0
    ledger = [json.loads(line) for line in (LOG/'admission.jsonl').read_text().splitlines()]
    equal(result['allocated'],ledger)
    allocations = {row['path']:row for row in ledger}
    assert len(allocations) == len(ledger) == 4*(len(plan['cases'])+len(plan['mutants']))
    for path, entry in allocations.items():
        assert set(entry) == {'kind','path','device','inode'}
        prefix = {'store':'.artifacts/tmp/native-proxy-image-custody/cases/',
            'workspace':'.artifacts/tmp/process-supervisor-tests/',
            'evidence':'.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/'}[entry['kind']]
        assert re.fullmatch(re.escape(prefix)+r'fsmgen-[A-Za-z0-9_]+',path)
        FRESH.native(entry)
        assert not (ROOT/path).exists() and not (ROOT/path).is_symlink()
    used = []
    for category in ('cases','mutants'):
        assert [r['id'] for r in result[category]] == [s['id'] for s in plan[category]]
        for row,spec in zip(result[category],plan[category]):
            row_valid(row,spec,allocations,category == 'mutants')
            used.extend(row['context'][kind]['path'] for kind in KINDS)
    assert len(used) == len(set(used)) and set(used) == set(allocations)


def main() -> None:
    raw = (BASE/'plan.json').read_bytes()
    assert hashlib.sha256(raw).hexdigest() == PLAN_SHA
    plan = json.loads(raw)
    equal(plan,PLAN.build())
    result = json.loads((LOG/'qualification.json').read_bytes())
    validate(result,plan)
    rows = [json.loads(line) for line in (LOG/'rows.jsonl').read_text().splitlines()]
    equal(rows,[dict(category=category,row=row) for category in ('cases','mutants') for row in result[category]])
    equal(json.loads((LOG/'progress.json').read_bytes()),dict(schema='fsmgen.inactive_snapshot_cut_progress.v1',
        success=True,allocations=len(result['allocated']),cases=len(result['cases']),mutants=len(result['mutants']),
        forbidden_process_attempts=0))
    assertions = FRESH.RUNTIME.tap_count((LOG/'qualify.tap').read_text())
    assert assertions == 2*(len(plan['cases'])+len(plan['mutants']))+1
    falsifiers = []
    for name,change in [
        ('hidden failure', lambda x:x.update(success=False)),
        ('lost cut', lambda x:x['cases'].pop()),
        ('lost executed event', lambda x:x['cases'][0]['trace'].pop()),
        ('lost source handle', lambda x:x['cases'][0]['handles'].pop()),
        ('wrong handle path', lambda x:x['cases'][0]['handles'][1].update(path=x['cases'][0]['handles'][2]['path'])),
        ('masked missing close', lambda x:x['cases'][0]['handles'][0].update(closed_before_recovery=0)),
        ('invented source identity', lambda x:x['cases'][0]['handles'][1]['identity'].update(inode=1)),
        ('lost unrelated owner', lambda x:x['cases'][0]['after']['store'].pop('references/'+x['cases'][0]['context']['seeded_record']['reference_key']+'.json')),
        ('extra stored member', lambda x:x['cases'][0]['after']['store'].update(extra={})),
        ('authority type changed', lambda x:x['cases'][0]['result'].update(runtime_authorized=False)),
        ('lost failed hold', lambda x:next(r for r in x['cases'] if r['id']=='fresh:finish:enter')['after']['store'].pop('references/'+FRESH.expected_observation(next(r for r in x['cases'] if r['id']=='fresh:finish:enter')['context'])['reference_key']+'.json',None)),
        ('lost mutant evidence', lambda x:x['mutants'][0]['handles'][0].update(closed_before_recovery=0)),
        ('lost allocation', lambda x:x['allocated'].pop()),
        ('forbidden process', lambda x:x.update(forbidden_process_attempts=1)),
    ]:
        altered = copy.deepcopy(result)
        change(altered)
        try:
            validate(altered,plan)
        except (AssertionError,KeyError):
            falsifiers.append(name)
        else:
            raise AssertionError('snapshot oracle missed falsifier: '+name)
    report = dict(schema='fsmgen.inactive_observation_snapshot_cuts_audit.v1',success=True,
        assertions=assertions,cases=len(plan['cases']),cut_counts={r:len(t) for r,t in plan['traces'].items()},
        allocations=len(result['allocated']),mutants=[r['id'] for r in result['mutants']],falsifiers=falsifiers,
        limits=plan['limits'])
    (LOG/'audit.json').write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print(json.dumps(report,sort_keys=True))


if __name__ == '__main__':
    main()
