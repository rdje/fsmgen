"""Independent canonical-order binding, semantic prefix and handle-custody oracle."""
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
LOG = ROOT/'.artifacts/logs/native-proxy-observation-semantic-cuts-20260911'
PLAN_SHA = '05f781422d4e029bac906ed5a8b30f49c9682f756953cc2213e2255ebcfd7c55'


def module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


PLAN = module('semantic_cut_plan', BASE/'plan.py')
COORD = module('semantic_coordinator_oracle', BASE.parent/'native-proxy-observation-coordinator-cuts-20260911/audit.py')
SNAPSHOT = COORD.SNAPSHOT
FRESH = COORD.FRESH
equal = COORD.equal
integer = COORD.integer
IMAGE_KEYS = PLAN.image_keys()


def binding(row: dict) -> tuple[list[dict], list[dict], str]:
    context = row['context']
    records = [context['runtime']['reference']['record'], context['other_runtime']['reference']['record'],
               SNAPSHOT.seed_record(context)]
    if row['route'] == 'reuse' or row['phase'] == 'post': records.append(FRESH.expected_observation(context))
    records = sorted(records, key=lambda record: record['reference_key'])
    assert len(records) == len({record['reference_key'] for record in records})
    assert len(records) == (3 if row['route'] == 'fresh' and row['phase'] == 'pre' else 4)
    assert context['runtime']['image']['key'] == IMAGE_KEYS['primary']
    assert context['other_runtime']['image']['key'] == IMAGE_KEYS['other']
    roles = {key: name for name, key in IMAGE_KEYS.items()}
    order = tuple(roles[record['image_key']] for record in records)
    return records, PLAN.flow(order, sorted(IMAGE_KEYS, key=IMAGE_KEYS.get)), ','.join(order)


def resource_counts(row: dict, cut: str | None) -> dict[str, Counter]:
    if cut is None: return COORD.resource_counts(row, None)
    counts = COORD.resource_counts(row, 'semantic:'+row['phase']+':enter')
    records, flow, _ = binding(row)
    context = row['context']; store = context['store']['path']
    runtimes = dict(primary=context['runtime'], other=context['other_runtime'])
    prefix = flow[:[entry['event'] for entry in flow].index(cut)]
    for entry in prefix:
        effect = entry['effect'] or {}
        if 'reference' in effect:
            counts['source'][store+'/references/'+records[effect['reference']]['reference_key']+'.json'] += 1
        if 'image' in effect:
            runtime = runtimes[effect['image']]
            index = 0 if effect['source'] == 'c' else 1
            counts['source'][runtime['image']['snapshots'][index]['identity']['path']] += 1
        if 'reader' in effect:
            runtime = runtimes[effect['reader']]
            for source in runtime['image']['snapshots']: counts['source'][source['identity']['path']] += 1
            counts['directory'][store+'/images/'+runtime['image']['key']] += 2
        if effect.get('reference_directory'): counts['directory'][store+'/references'] += 1
    return counts


def selected_occurrence(row: dict, guard: str) -> tuple[str, int]:
    records, flow, _ = binding(row)
    store = row['context']['store']['path']
    if guard == 'omit_original_reference_close':
        event = 'reference:initial:0:read'
        path = store+'/references/'+records[0]['reference_key']+'.json'
    elif guard == 'omit_fresh_reference_close':
        event = 'reference:closure:0:read'
        path = store+'/references/'+records[0]['reference_key']+'.json'
    else:
        assert guard == 'omit_image_input_close'
        event = next(entry['event'] for entry in flow if entry['event'].startswith('image:initial:')
                     and entry['event'].endswith(':input:c:read'))
        role = event.split(':')[2]
        runtime = row['context']['runtime' if role == 'primary' else 'other_runtime']
        path = runtime['image']['snapshots'][0]['identity']['path']
    # The selected read has not completed at this prefix. Its resulting handle
    # is exactly the next occurrence of that path in the full returned roster.
    return path, resource_counts(row, event)['source'][path]


def custody(row: dict, spec: dict, allow_mutant=False) -> None:
    context = row['context']; handles = row['handles']; counts = resource_counts(row, spec.get('cut'))
    assert all(entry['kind'] in counts for entry in handles)
    for kind, expected in counts.items():
        assert Counter(h['path'] for h in handles if h['kind'] == kind) == +expected, (row['id'], kind, 'handle roster differs')
    integer(row['lock_cloexec_after_set']); assert row['lock_cloexec_after_set'] == 1
    selected = None
    if allow_mutant:
        path, occurrence = selected_occurrence(row, spec['guard'])
        selected = [index for index, entry in enumerate(handles) if entry['kind'] == 'source' and entry['path'] == path][occurrence]
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
            integer(entry['open_cloexec']); assert entry['open_cloexec'] == 1
            equal(entry['current_identity'], entry['identity'])
        else:
            assert entry['recovery_close_ok'] is None
            assert 'current_identity' not in entry and 'open_cloexec' not in entry


def row_valid(row: dict, spec: dict, allocations: dict, mutant: bool) -> None:
    assert row['id'] == spec['id'] and row['route'] == spec['route'] and row['phase'] == spec['phase']
    SNAPSHOT.context_valid(row, allocations)
    _, flow, expected_binding = binding(row)
    assert row['binding'] == expected_binding
    events = [entry['event'] for entry in flow]; cut = spec.get('cut')
    equal(row['trace'], events if cut is None else events[:events.index(cut)+1])
    integer(row['cut_fired']); assert row['cut_fired'] == int(cut is not None)
    integer(row['returned']); assert row['returned'] == int(cut is None)
    integer(row['omitted_close_calls']); assert row['omitted_close_calls'] == int(mutant)
    assert row['error'] == ('' if cut is None else 'injected semantic cut: '+row['phase']+':'+cut+'\n')
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
        # Strict custody deliberately ignores the self-reported omitted-call
        # marker: the independently identified actual open handle must fail it.
        try: custody(row, spec)
        except AssertionError: pass
        else: raise AssertionError('strict oracle accepted omitted semantic close')


def validate(result: dict, plan: dict) -> None:
    assert result['schema'] == 'fsmgen.inactive_observation_semantic_cuts_qualification.v1'
    assert result['success'] is True and 'first_failure' not in result and 'unexpected_error' not in result
    integer(result['forbidden_process_attempts']); assert result['forbidden_process_attempts'] == 0
    ledger = [json.loads(line) for line in (LOG/'admission.jsonl').read_text().splitlines()]
    equal(ledger, result['allocated']); allocations = {entry['path']: entry for entry in ledger}
    assert len(ledger) == len(allocations) == 4*(len(plan['cases'])+len(plan['mutants']))
    for path, entry in allocations.items():
        assert set(entry) == {'kind', 'path', 'device', 'inode'}
        prefix = {'store': '.artifacts/tmp/native-proxy-image-custody/cases/',
            'workspace': '.artifacts/tmp/process-supervisor-tests/',
            'evidence': '.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/'}[entry['kind']]
        assert re.fullmatch(re.escape(prefix)+r'fsmgen-[A-Za-z0-9_]+', path)
        FRESH.native(entry); assert not (ROOT/path).exists() and not (ROOT/path).is_symlink()
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
    equal([json.loads(line) for line in (LOG/'rows.jsonl').read_text().splitlines()],
          [dict(category=c, row=r) for c in ('cases', 'mutants') for r in result[c]])
    equal(json.loads((LOG/'progress.json').read_bytes()), dict(schema='fsmgen.inactive_semantic_cut_progress.v1',
        success=True, allocations=len(result['allocated']), cases=len(result['cases']), mutants=len(result['mutants']), forbidden_process_attempts=0))
    assertions = FRESH.RUNTIME.tap_count((LOG/'qualify.tap').read_text())
    assert assertions == 2*(len(plan['cases'])+len(plan['mutants']))+1
    falsifiers = []

    def wrong_occurrence(value):
        row = value['mutants'][0]
        opened = next(h for h in row['handles'] if not h['closed_before_recovery'])
        other = next(h for h in row['handles'] if h is not opened and h['kind'] == 'source' and h['path'] == opened['path'])
        for field in ('closed_before_recovery', 'recovery_close_ok', 'current_identity', 'open_cloexec'):
            other[field] = opened.pop(field)
        opened.update(closed_before_recovery=1, recovery_close_ok=None)

    for name, change in [
        ('hidden failure', lambda x: x.update(success=False)),
        ('lost semantic boundary', lambda x: x['cases'].pop()),
        ('wrong order binding', lambda x: x['cases'][0].update(binding='unplanned')),
        ('lost call', lambda x: x['cases'][0]['trace'].pop()),
        ('lost directory', lambda x: x['cases'][0]['handles'].remove(next(h for h in x['cases'][0]['handles'] if h['kind'] == 'directory'))),
        ('lost source', lambda x: x['cases'][0]['handles'].remove(next(h for h in x['cases'][0]['handles'] if h['kind'] == 'source'))),
        ('lost observer close', lambda x: next(h for h in x['cases'][0]['handles'] if h['kind'] == 'directory').update(observer_closed=0)),
        ('invented lock identity', lambda x: x['cases'][0]['handles'][0]['identity'].update(inode=1)),
        ('lost lock seal', lambda x: x['cases'][0].update(lock_cloexec_after_set=0)),
        ('lost other owner', lambda x: x['cases'][0]['after']['store'].pop('references/'+x['cases'][0]['context']['seeded_record']['reference_key']+'.json')),
        ('lost failed hold', lambda x: next(r for r in x['cases'] if r['id'] == 'fresh:post:inspect:enter')['after']['store'].pop('references/'+FRESH.expected_observation(next(r for r in x['cases'] if r['id'] == 'fresh:post:inspect:enter')['context'])['reference_key']+'.json')),
        ('wrong actual mutant occurrence', wrong_occurrence),
        ('lost omitted close report', lambda x: x['mutants'][0].update(omitted_close_calls=0)),
        ('authority type changed', lambda x: x['cases'][0]['result'].update(runtime_authorized=False)),
        ('lost allocation', lambda x: x['allocated'].pop()),
        ('forbidden process', lambda x: x.update(forbidden_process_attempts=1)),
    ]:
        changed = copy.deepcopy(result); change(changed)
        try: validate(changed, plan)
        except (AssertionError, KeyError, IndexError): falsifiers.append(name)
        else: raise AssertionError('semantic oracle missed falsifier: '+name)
    report = dict(schema='fsmgen.inactive_observation_semantic_cut_audit.v1', success=True,
        assertions=assertions, cases=len(plan['cases']), allocations=len(result['allocated']),
        cut_counts={route: {phase: len(next(iter(variants.values()))) for phase, variants in phases.items()}
                    for route, phases in plan['flows'].items()},
        mutants=[spec['id'] for spec in plan['mutants']], falsifiers=falsifiers,
        observed_bindings={route: {phase: sorted({row['binding'] for row in result['cases']+result['mutants']
            if row['route'] == route and row['phase'] == phase}) for phase in ('pre', 'post')} for route in ('fresh', 'reuse')},
        limits=plan['limits'])
    (LOG/'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2)+'\n')
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()
