"""Bind qualified source topology to statements without original trace intake.

Argument payloads, serialized errors and caller coordinate snapshots are never
selected. The finite callee meanings are trusted predecessor inputs; this slice
qualifies their ordered allocation to independently reconstructed statements.
"""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path('docs/audits/coordinate-refusal-phases-20261009')
REVISION = '485275db33d4fe96576b1782f44708be66963fc1'
RECIPES = Path('docs/audits/coordinate-statement-recipes-20261009')
PATHS = Path('docs/audits/coordinate-refusal-path-inputs-20261009')
SOURCE = Path('docs/audits/record-value-class-frame-join-20261006/source-models.json')
PUBLICATION = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.3.2.2.3.3'
ROLE = 'Ordered own-source refusal-phase statement hypotheses; original coordinates, private runtime meanings and alias downstream remain unmeasured.'
VALUE = 'FSM::Support::ISFRecordPortValues::'
META = 'FSM::Support::ISFInterfacePortMetadata::'
PARSER = 'FSM::Adapter::ISF::Parser::'
CONTEXT = 'FSM::Support::ISFRecordPortContexts::'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def identity(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def fixed(path):
    run = subprocess.run(['git', '--no-replace-objects', 'show', REVISION + ':' + str(path)],
                         cwd=ROOT, capture_output=True)
    need(run.returncode == 0 and not run.stderr, 'whole fixed phase input')
    live = ROOT / path
    need(live.resolve() == live and live.is_file() and live.stat().st_dev == ROOT.stat().st_dev
         and live.read_bytes() == run.stdout, 'unchanged regular same-volume phase input')
    for parent in live.parents:
        if parent == ROOT:
            break
        need(not (parent / '.git').exists(), 'own phase input repository boundary')
    return run.stdout


def inputs():
    authorities = {}
    for folder in (RECIPES, PATHS):
        seal = fixed(folder / 'seal.json')
        authorities[str(folder / 'seal.json')] = pin(seal)
        members = json.loads(seal)
        need({p.name for p in (ROOT / folder).iterdir()} == set(members) | {'seal.json'},
             'complete fixed phase input namespace')
        for name, expected in members.items():
            need(pin(fixed(folder / name)) == expected, 'whole fixed sealed phase input')
    raw = fixed(SOURCE)
    authorities[str(SOURCE)] = pin(raw)
    return json.loads(fixed(RECIPES / 'recipes.json')), json.loads(fixed(PATHS / 'paths.json')), json.loads(raw), authorities


def topology(source):
    """Select source roles only, excluding arguments, caller snapshots and public traces."""
    result = []
    for mode in source['modes']:
        cases = []
        for case in mode['cases']:
            phases = []
            for phase in case['phases']:
                own = phase['own']
                frame = lambda row: {key: row[key] for key in ('function', 'call_site', 'role') if key in row}
                phases.append({key: copy.deepcopy(phase[key]) for key in ('phase', 'family', 'inferred_class', 'guard_source')} | {
                    'core': [frame(row) for row in own['core']],
                    'operations': [{'kind': row['kind'], 'operation_lookup': row['operation_lookup'],
                                    'frames': [frame(f) for f in row['frames']]} for row in own['operations']],
                    **{key: [frame(row) for row in own[key]] for key in ('helper', 'body', 'entry')},
                    'load_marker': own['load']})
            cases.append({key: case[key] for key in ('domain', 'index', 'helper', 'kind', 'subtest')} | {'phases': phases})
        result.append({'mode': mode['mode'], 'cases': cases})
    return result


def derive(recipes, paths, source, authorities):
    owner = (ROOT / BASE / 'scope.txt').read_text().strip()
    need(owner == recipes['unresolved']['statement_hypotheses'], 'exact phase binding owner')
    source_modes = topology(source)
    need([row['mode'] for row in source_modes] == ['ordinary', 'storable', 'controls'], 'whole phase source mode order')
    admitted = {(row['mode'], row['domain'], row['index']): row for row in paths['allocations']}
    need(len(admitted) == len(paths['allocations']), 'unique complete admitted refusal keys')
    statements = {row['id']: row for row in recipes['statements']}
    used = set()

    def caller(recipe_id):
        need(recipe_id in statements, 'qualified caller recipe exists: ' + recipe_id)
        used.add(recipe_id)
        return {'kind': 'own_statement', 'recipe_id': recipe_id, 'original_selection': None}

    def bind(callee, role, links, recipe_id=None, call_kind='direct'):
        site = caller(recipe_id) if recipe_id else {
            'kind': 'opaque_external_framework_interval', 'owner': paths['unresolved']['original_coordinates'],
            'original_selection': None}
        return {'callee': callee, 'role': role, 'model_links': links, 'call_kind': call_kind, 'caller': site}

    def core_recipe(frame):
        function, label = frame['function'], frame.get('call_site')
        if label == 'failed_Value_capture_eval_guard':
            return 'value-capture-guard'
        if function.startswith((VALUE, META)):
            unit = 'value' if function.startswith(VALUE) else 'metadata'
            if function.endswith('::_require'):
                return 'admitted/guard-call/' + unit + '/GUARDS.' + label
            need(label not in ('observer_operation', 'original_scope_operation'), 'public core handled as operation')
            return 'admitted/guard-call/' + unit + '/CALLS.' + ('scope_type' if label == 'scope_private_root_type' else label)
        mapping = {
            CONTEXT + '_require': 'context-write-guard', CONTEXT + '_reference': 'context-reference',
            CONTEXT + '_assignment': 'context-assignment', CONTEXT + '_clauses': 'context-clauses',
            CONTEXT + 'validate_actor_record_contexts': 'parser-context',
            PARSER + '_resolve_typed_width_entry': 'parser-port',
            PARSER + '_finalize_actor_type_references': 'parser-finalize',
            PARSER + '_build_actor': 'parser-build', PARSER + 'parse_source': 'facade-parse'}
        need(function in mapping, 'complete finite parser/context caller')
        return mapping[function]

    refusals = []
    for mode in source_modes:
        for case in mode['cases']:
            key = (mode['mode'], case['domain'], case['index'])
            need(key in admitted, 'source refusal belongs to complete admitted domain')
            allocation = admitted[key]
            need(case['helper'] == allocation['helper']['index'] and case['subtest'] == allocation['subtest']['name']
                 and len(case['phases']) == allocation['helper_case']['phases'], 'source helper/subtest/phase join')
            helper_index = case['helper']
            named = [frame['function'].split('::')[-1] for frame in case['phases'][0]['helper']
                     if frame.get('call_site') == 'original_compiled_callback']
            need(len(named) <= 1, 'finite outer named test helper')
            outer = 'helper-return/' + named[0] if named else 'callback/' + str(helper_index)
            phases = []
            for phase in case['phases']:
                need(type(phase['phase']) is int and phase['phase'] == len(phases), 'ordered complete throw phases')
                need([{k: f[k] for k in ('function', 'call_site') if k in f}
                      for f in allocation['helper_case']['paths'][phase['phase']]] == phase['helper'],
                     'complete source helper path conservation')
                operation_by_function = {op['frames'][0]['function']: (i, op)
                                         for i, op in enumerate(phase['operations'])}
                need(len(operation_by_function) == len(phase['operations']), 'unique active source operation roles')
                active = []
                consumed = set()
                for i, frame in enumerate(phase['core']):
                    callee = frame['function']
                    if callee not in operation_by_function:
                        active.append(bind(callee, 'core', [['core', i]], core_recipe(frame)))
                        continue
                    oi, operation = operation_by_function[callee]
                    consumed.add(oi)
                    parser = operation['kind'] == 'source'
                    function = 'parse' if parser else 'call_api'
                    locations = ['observer-operation/' + function, 'observer-eval/' + function,
                                 'wrapper-delegate/' + callee + '/0',
                                 'value-capture' if operation['kind'] == 'capture' else outer]
                    for fi, (op_frame, location) in enumerate(zip(operation['frames'], locations, strict=True)):
                        links = [['operations', oi, 'frames', fi]]
                        if fi == 0:
                            links.insert(0, ['core', i])
                        active.append(bind(op_frame['function'], 'core_operation' if fi == 0 else 'observer', links,
                                           location, ('dynamic_code', 'eval', 'direct', 'direct')[fi]))
                    if operation['kind'] == 'capture':
                        active.append(bind('eval {...}', 'nested_capture_eval', [], 'value-capture-eval', 'eval'))
                need(consumed == set(range(len(phase['operations']))), 'complete phase operation consumption')
                helper_locations = {'original_compiled_callback': 'callback/' + str(helper_index),
                                    'compiled_original_parameterless_callback': 'admitted/qualified/95',
                                    'original_refuses_callback_eval': 'admitted/qualified/95',
                                    'compiled_original_helper': 'admitted/qualified/92',
                                    'installed_observer_helper_wrapper': 'helper-invocation/' + str(helper_index)}
                for i, frame in enumerate(phase['helper']):
                    label = frame['call_site']
                    active.append(bind(frame['function'], 'helper', [['helper', i]], helper_locations[label],
                                       'eval' if label == 'original_refuses_callback_eval' else
                                       'dynamic_code' if label in ('compiled_original_helper', 'compiled_original_parameterless_callback') else 'direct'))
                for i, frame in enumerate(phase['body']):
                    active.append(bind(frame['function'], 'body', [['body', i]],
                                       'admitted/qualified/91' if frame['role'] == 'authored_body' else None,
                                       'dynamic_code' if frame['role'] == 'authored_body' else 'opaque_external'))
                for i, frame in enumerate(phase['entry']):
                    active.append(bind(frame['function'], 'entry', [['entry', i]],
                                       'saved-subtest-delegate' if frame['role'] == 'saved_public_delegate' else
                                       'subtest-invocation/' + case['subtest'],
                                       'saved_public_delegate' if frame['role'] == 'saved_public_delegate' else 'direct'))
                origin = {'value': 'admitted/qualified/0', 'metadata': 'admitted/qualified/1',
                          'context': 'admitted/qualified/2', 'parser': 'parser-confess-statement'}[phase['family']]
                phases.append({'phase': phase['phase'], 'family': phase['family'],
                               'source_topology_identity': identity(phase),
                               'origin': {'thrower': phase['core'][0]['function'], 'caller': caller(origin)},
                               'active_path_inner_to_outer': active,
                               'load': {'source_operator': 'do', 'caller': caller('admitted/qualified/99'),
                                        'model_marker': phase['load_marker'],
                                        'marker_role': 'qualified source model label; distinct from lexical do operator'}})
            refusals.append({'mode': key[0], 'domain': key[1], 'index': key[2], 'helper': helper_index,
                             'subtest': case['subtest'], 'admitted_allocation_identity': identity(allocation),
                             'phases': phases, 'original_selection': None})
    need({(row['mode'], row['domain'], row['index']) for row in refusals} == set(admitted),
         'complete disjoint source refusal domain')
    unresolved = {k: v for k, v in recipes['unresolved'].items() if k != 'statement_hypotheses'}
    unresolved['whole_source_publication'] = PUBLICATION
    return {'role': ROLE, 'revision': REVISION, 'owner': owner, 'authorities': authorities,
            'source_topology_identity': identity(source_modes), 'refusals': refusals,
            'statements': [copy.deepcopy(statements[key]) for key in sorted(used)],
            'generation_custody': recipes['generation_custody'], 'invocation_custody': recipes['invocation_custody'],
            'public_examples': recipes['public_examples'], 'unresolved': unresolved}


def main():
    need(Path.cwd().resolve() == ROOT, 'invoke refusal phase binding from repository root')
    need(not (BASE / 'seal.json').exists(), 'sealed phase producer never reruns')
    product = derive(*inputs())
    (BASE / 'phases.json').write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete ordered source-only refusal phases bound to statement recipes; original coordinates remain pending.')


if __name__ == '__main__':
    main()
