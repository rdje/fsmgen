"""Independent coordinator prefix, conservative-state and descriptor oracle."""
from __future__ import annotations

from collections import Counter
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT/'.artifacts/logs/native-proxy-observation-coordinator-cuts-20260911'
PLAN_SHA = '4b3bfcb6f1f1d9c938cc95561620928e8b50572cb9e132426c7c72c7967a1e10'


def module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


PLAN = module('coordinator_cut_plan', BASE/'plan.py')
SNAPSHOT = module('coordinator_snapshot_oracle', BASE.parent/'native-proxy-observation-snapshot-cuts-20260910/audit.py')
FRESH = SNAPSHOT.FRESH
equal = SNAPSHOT.equal


def integer(value, minimum=0) -> None:
    assert type(value) is int and value >= minimum


def reference_paths(row: dict, phase: str) -> list[str]:
    store = row['context']['store']['path']
    paths = {store+'/'+name for name in row['before']['store'] if name.startswith('references/')}
    if phase == 'post': paths.add(SNAPSHOT.path_roles(row['context'])['hold'])
    assert len(paths) == (3 if phase == 'pre' and row['route'] == 'fresh' else 4)
    return sorted(paths)


def completed_flow(row: dict, cut: str | None) -> list[dict]:
    flow = PLAN.flow(row['route'])
    return flow if cut is None else flow[:[r['event'] for r in flow].index(cut)]


def resource_counts(row: dict, cut: str | None) -> dict[str, Counter]:
    context = row['context']; store = context['store']['path']
    paths = SNAPSHOT.path_roles(context)
    targets = [paths[name] for name in ('wrapper', 'private', 'global_', 'c', 'image')]
    if row['route'] == 'reuse': targets.append(paths['hold'])
    counts = {kind: Counter() for kind in ('source', 'directory', 'writer', 'lock')}
    directories = dict(store=store, images=store+'/images', references=store+'/references')
    for entry in completed_flow(row, cut):
        effect = entry['effect'] or {}
        if 'directory' in effect: counts['directory'][directories[effect['directory']]] += 1
        if effect.get('lock'): counts['lock'][store+'/coordination.lock'] += 1
        if 'reference' in effect:
            counts['source'][reference_paths(row, effect['reference'])[effect['index']]] += 1
        if 'semantic' in effect:
            for path in reference_paths(row, effect['semantic']): counts['source'][path] += 2
            counts['directory'][directories['references']] += 1
            for runtime in (context['runtime'], context['other_runtime']):
                for source, count in zip(runtime['image']['snapshots'], (4, 4, 2)):
                    counts['source'][source['identity']['path']] += count
                counts['directory'][store+'/images/'+runtime['image']['key']] += 4
        for path in targets: counts['source'][path] += effect.get('target_reads', 0)
        if effect.get('publication'):
            counts['writer'][paths['hold']] += 1
            counts['source'][paths['hold']] += 1
        if effect.get('hold_read'): counts['source'][paths['hold']] += 1
    return counts


def custody(row: dict, spec: dict, allow_mutant=False) -> None:
    context = row['context']; cut = spec.get('cut'); handles = row['handles']
    counts = resource_counts(row, cut)
    assert all(entry['kind'] in counts for entry in handles)
    for kind, expected in counts.items():
        assert Counter(h['path'] for h in handles if h['kind'] == kind) == +expected, (row['id'], kind, 'handle roster differs')
    completed = {entry['event'] for entry in completed_flow(row, cut)}
    if 'coordinator:lock:flags:set' in completed:
        integer(row['lock_cloexec_after_set']); assert row['lock_cloexec_after_set'] == 1
    else: assert 'lock_cloexec_after_set' not in row
    selected = None
    if allow_mutant:
        kind, path = {
            'omit_lock_close': ('lock', context['store']['path']+'/coordination.lock'),
            'omit_reference_close': ('source', reference_paths(row, 'pre')[0]),
            'omit_directory_close': ('directory', context['store']['path']),
        }[spec['guard']]
        selected = next(index for index, entry in enumerate(handles) if entry['kind'] == kind and entry['path'] == path)
    integer(row['omitted_close_calls']); assert row['omitted_close_calls'] == int(allow_mutant)
    values = SNAPSHOT.all_bytes(context)
    for index, entry in enumerate(handles):
        integer(entry['descriptor']); FRESH.native(entry['identity'])
        roots = [name for name in SNAPSHOT.KINDS if entry['path'] == context[name]['path']]
        node = row['after'][roots[0]][''] if roots else FRESH.node_for(row['after'], context, entry['path'])
        if entry['kind'] == 'directory':
            assert node['kind'] == 'directory'
            equal(entry['identity'], {key: node[key] for key in ('device', 'inode', 'mode', 'uid')})
            integer(entry['observer_descriptor']); assert entry['observer_descriptor'] != entry['descriptor']
            for field in ('observer_close_ok', 'observer_closed'):
                integer(entry[field]); assert entry[field] == 1
        else:
            assert node['kind'] == 'file'
            identity = {key: node[key] for key in ('device', 'inode', 'mode', 'links', 'uid')}
            identity['size_bytes'] = 0 if entry['kind'] == 'writer' else node['bytes']
            equal(entry['identity'], identity)
        if entry['kind'] == 'source':
            integer(entry['cloexec']); assert entry['cloexec'] == 1
            FRESH.observed_source(entry['snapshot'], entry['path'], values[entry['path']], node['mode'], row['after'], context)
        else: assert 'snapshot' not in entry and 'cloexec' not in entry
        integer(entry['closed_before_recovery']); assert entry['closed_before_recovery'] == int(index != selected)
        integer(entry['closed_after_recovery']); assert entry['closed_after_recovery'] == 1
        if index == selected:
            integer(entry['recovery_close_ok']); assert entry['recovery_close_ok'] == 1
            if entry['kind'] != 'directory':
                integer(entry['open_cloexec']); assert entry['open_cloexec'] == 1
                equal(entry['current_identity'], entry['identity'])
        else:
            assert entry['recovery_close_ok'] is None
            assert 'current_identity' not in entry and 'open_cloexec' not in entry


def row_valid(row: dict, spec: dict, allocations: dict, mutant: bool) -> None:
    assert row['id'] == spec['id'] and row['route'] == spec['route']
    SNAPSHOT.context_valid(row, allocations)
    cut = spec.get('cut'); events = [entry['event'] for entry in PLAN.flow(row['route'])]
    equal(row['trace'], events if cut is None else events[:events.index(cut)+1])
    integer(row['cut_fired']); assert row['cut_fired'] == int(cut is not None)
    integer(row['returned']); assert row['returned'] == int(cut is None)
    assert row['error'] == ('' if cut is None else 'injected coordinator cut: '+cut+'\n')
    expected = copy.deepcopy(row['before']); record = FRESH.expected_observation(row['context'])
    relative = 'references/'+record['reference_key']+'.json'
    if spec['hold'] == 'complete':
        node = row['after']['store'][relative]
        SNAPSHOT.file_node(node, FRESH.canonical(record), 0o400)
        if row['route'] == 'fresh':
            assert relative not in expected['store']; expected['store'][relative] = node
    else: assert row['route'] == 'fresh' and relative not in expected['store']
    equal(expected, row['after'])
    if cut is None:
        FRESH.check_success(dict(row, name='fresh acquisition'))
        if row['route'] == 'reuse': equal(row['result'], row['context']['previous'])
    else: assert 'result' not in row
    custody(row, spec, mutant)
    if mutant:
        try: custody(row, spec)
        except AssertionError: pass
        else: raise AssertionError('strict oracle accepted omitted coordinator close')


def validate(result: dict, plan: dict) -> None:
    assert result['schema'] == 'fsmgen.inactive_observation_coordinator_cuts_qualification.v1'
    assert result['success'] is True and 'first_failure' not in result and 'unexpected_error' not in result
    integer(result['forbidden_process_attempts']); assert result['forbidden_process_attempts'] == 0
    ledger = [json.loads(line) for line in (LOG/'admission.jsonl').read_text().splitlines()]
    equal(ledger, result['allocated'])
    allocations = {entry['path']: entry for entry in ledger}
    assert len(ledger) == len(allocations) == 4*(len(plan['cases'])+len(plan['mutants']))
    for path, entry in allocations.items():
        assert set(entry) == {'kind', 'path', 'device', 'inode'}
        prefix = {'store': '.artifacts/tmp/native-proxy-image-custody/cases/',
            'workspace': '.artifacts/tmp/process-supervisor-tests/',
            'evidence': '.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/'}[entry['kind']]
        assert re.fullmatch(re.escape(prefix)+r'fsmgen-[A-Za-z0-9_]+', path)
        FRESH.native(entry)
        assert not (ROOT/path).exists() and not (ROOT/path).is_symlink()
    used = []
    for category in ('cases', 'mutants'):
        assert [row['id'] for row in result[category]] == [spec['id'] for spec in plan[category]]
        for row, spec in zip(result[category], plan[category]):
            row_valid(row, spec, allocations, category == 'mutants')
            used.extend(row['context'][kind]['path'] for kind in SNAPSHOT.KINDS)
    assert len(used) == len(set(used)) and set(used) == set(allocations)


def main() -> None:
    raw = (BASE/'plan.json').read_bytes(); assert hashlib.sha256(raw).hexdigest() == PLAN_SHA
    plan = json.loads(raw); equal(plan, PLAN.build())
    result = json.loads((LOG/'qualification.json').read_bytes()); validate(result, plan)
    rows = [json.loads(line) for line in (LOG/'rows.jsonl').read_text().splitlines()]
    equal(rows, [dict(category=c, row=r) for c in ('cases', 'mutants') for r in result[c]])
    equal(json.loads((LOG/'progress.json').read_bytes()), dict(schema='fsmgen.inactive_coordinator_cut_progress.v1',
        success=True, allocations=len(result['allocated']), cases=len(result['cases']), mutants=len(result['mutants']), forbidden_process_attempts=0))
    assertions = FRESH.RUNTIME.tap_count((LOG/'qualify.tap').read_text())
    assert assertions == 2*(len(plan['cases'])+len(plan['mutants']))+1
    falsifiers = []
    for name, change in [
        ('hidden failure', lambda x: x.update(success=False)),
        ('lost boundary', lambda x: x['cases'].pop()),
        ('lost call', lambda x: x['cases'][0]['trace'].pop()),
        ('lost directory', lambda x: x['cases'][0]['handles'].remove(next(h for h in x['cases'][0]['handles'] if h['kind'] == 'directory'))),
        ('lost source', lambda x: x['cases'][0]['handles'].remove(next(h for h in x['cases'][0]['handles'] if h['kind'] == 'source'))),
        ('lost observer close', lambda x: next(h for h in x['cases'][0]['handles'] if h['kind'] == 'directory').update(observer_closed=0)),
        ('invented lock identity', lambda x: x['cases'][0]['handles'][0]['identity'].update(inode=1)),
        ('lost lock inheritance seal', lambda x: x['cases'][0].update(lock_cloexec_after_set=0)),
        ('lost other owner', lambda x: x['cases'][0]['after']['store'].pop('references/'+x['cases'][0]['context']['seeded_record']['reference_key']+'.json')),
        ('lost failed hold', lambda x: next(r for r in x['cases'] if r['id'] == 'fresh:operation:finish:enter')['after']['store'].pop('references/'+FRESH.expected_observation(next(r for r in x['cases'] if r['id'] == 'fresh:operation:finish:enter')['context'])['reference_key']+'.json')),
        ('lost omitted close', lambda x: x['mutants'][0].update(omitted_close_calls=0)),
        ('authority type changed', lambda x: x['cases'][0]['result'].update(runtime_authorized=False)),
        ('lost allocation', lambda x: x['allocated'].pop()),
        ('forbidden process', lambda x: x.update(forbidden_process_attempts=1)),
    ]:
        changed = copy.deepcopy(result); change(changed)
        try: validate(changed, plan)
        except (AssertionError, KeyError): falsifiers.append(name)
        else: raise AssertionError('coordinator oracle missed falsifier: '+name)
    report = dict(schema='fsmgen.inactive_observation_coordinator_cut_audit.v1', success=True,
        assertions=assertions, cases=len(plan['cases']), allocations=len(result['allocated']),
        cut_counts={route: len(flow) for route, flow in plan['flows'].items()},
        mutants=[spec['id'] for spec in plan['mutants']], falsifiers=falsifiers,
        complete_handles={route: {kind: sum(counts.values()) for kind, counts in resource_counts(
            next(row for row in result['cases'] if row['id'] == route+':complete'), None).items()}
            for route in ('fresh', 'reuse')}, limits=plan['limits'])
    (LOG/'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2)+'\n')
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()
