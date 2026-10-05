"""Own named-helper inputs/active paths; compiled refusal paths remain open."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-named-helpers-20261005')
PRIOR = Path('docs/audits/record-value-original-observer-boundaries-20261005')
REVISION = 'd9583a614bedc312b25ff4d652a1a1d868503f7c'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.2'


def module(path):
    namespace = {'__name__': 'named_helper_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


prior = module(PRIOR / 'verify.py')
api, primary, direct = (prior[key] for key in ('api', 'primary', 'direct'))
require, load, same, sealed = (prior[key] for key in ('require', 'load', 'same', 'sealed'))
helper_model = module(BASE / 'helper_model.py')
freeze = api['inherited']['nested']['freeze']


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact done observer-boundary intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed named-helper intake task')
    start = task.index('- ID: `' + OWNER + '`')
    end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end], 'whole completed observer-boundary owner')
    require(set(binding['archives']) == set(load(PRIOR / 'binding.json')['archives']) | {str(PRIOR)}, 'complete named-helper prerequisite domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole named-helper prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
                    == (Path(path) / name).read_bytes(), 'whole committed named-helper prerequisite bytes')
    require(binding['auxiliary_receipts'] == load(PRIOR / 'binding.json')['auxiliary_receipts'], 'whole inherited receipt-control authority')
    for path, body in binding['auxiliary_receipts'].items():
        require(subprocess.check_output(['git', 'show', REVISION + ':' + path]) == Path(path).read_bytes() == body.encode(), 'whole committed receipt-control bytes')
    prior['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def sources():
    return prior['sources']()


def check_sources(source):
    prior['check_sources'](source)
    for function, statements in helper_model['CONTRACTS'].items():
        body = source['test'][source['test'].index('sub ' + function + ' {'):]
        body = body[:body.index('\nsub ', 1)]
        require(all(body.count(statement) == 1 for statement in statements), 'exact named-helper formal/default/delegate source')
    test, _, _, _ = primary['context']['source_models']()
    require(source['test'] == test, 'whole qualified named-helper callback source authority')


def named(arguments):
    require(len(arguments) % 2 == 0 and all(type(name) is str for name in arguments[::2]), 'complete finite named operation arguments')
    result = dict(zip(arguments[::2], arguments[1::2]))
    require(len(result) * 2 == len(arguments), 'distinct finite named operation argument roles')
    return result


def expected_models(source):
    check_sources(source)
    _, helpers, _, products = primary['context']['source_models']()
    boundary_modes = prior['expected_models'](source)
    intervention, _, _ = primary['graph']['source_interventions']()
    primary_modes = {mode['mode']: mode for mode in load(primary['BASE'] / 'proofs.json')['proofs']}
    argument = direct['frame_model']['argument']
    result = []
    for mode in boundary_modes:
        causes = {row['index']: row['primary'] for row in primary_modes[mode['mode']]['complete_source_API_primary_models']}
        def inputs(index):
            return (intervention[index] if mode['mode'] != 'storable' and index in intervention
                    else primary['graph']['thaw'](products['apis'][index]['whole_native']['before']))

        recipes = []
        for helper in helpers:
            shape = helper_model['calls'](helper, require)
            by_kind = {}
            for index in helper['api_members']:
                by_kind.setdefault(products['apis'][index]['whole_native']['kind'], []).append(index)
            active, completed = shape['active'], shape['completed']
            function = active['function'] if active else None
            tokens = active['tokens'] if active else []
            supplied, defaults = [], {}
            operations = []

            def reference_args(call, index):
                require(call['function'] == 'reference' and 2 <= len(call['tokens']) <= 4, 'finite supplied reference argument count')
                tokens = call['tokens']
                facts = named(inputs(index))
                token = helper['label'] if tokens[1] == '$pair->[0]' else helper_model['literal'](tokens[1], require)
                access = helper_model['literal'](tokens[2], require) if len(tokens) > 2 else 'read'
                whole = helper_model['literal'](tokens[3], require) if len(tokens) > 3 else 0
                require(type(facts['scope']) is dict and facts['token'] == token and facts['access'] == access
                        and type(facts['allow_whole']) is int and facts['allow_whole'] == whole
                        and facts['context'] == 'control', 'complete source supplied/default reference input roles')
                supplied = [facts['scope'], token]
                supplied += ([access] if len(tokens) > 2 else []) + ([whole] if len(tokens) > 3 else [])
                return supplied, {key: value for key, value in (('access', 'read'), ('whole', 0))
                                  if helper_model['FORMALS']['reference'].index(key) >= len(tokens)}

            if function == 'reference' or completed:
                require(len(by_kind.get('reference', [])) == 1, 'complete direct/completed reference operation allocation')
                index = by_kind['reference'][0]
                call = active if active else completed[0]
                args, ref_defaults = reference_args(call, index)
                operations.append({'index': index, 'kind': 'reference', 'source_call': call,
                                   'supplied': freeze(args), 'defaults': ref_defaults,
                                   'normalized_operation_inputs': freeze(inputs(index)),
                                   'phase': 'active' if active else 'returned_before_outer_operation'})
                if active:
                    supplied, defaults = args, ref_defaults
            elif function == 'copy':
                require(len(tokens) == 3 and len(by_kind.get('reference', [])) == 2
                        and len(by_kind.get('copy', [])) == 1, 'complete source copy helper operation allocation')
                source_token, target_token = (helper_model['literal'](token, require) for token in tokens[1:])
                refs = [named(inputs(index)) for index in by_kind['reference']]
                require(same(freeze(refs[0]['scope']), freeze(refs[1]['scope']))
                        and refs[0]['token'] == source_token and refs[1]['token'] == target_token
                        and [facts['access'] for facts in refs] == ['read', 'write']
                        and all(type(facts['allow_whole']) is int and facts['allow_whole'] == 1
                                and facts['context'] == 'control' for facts in refs), 'complete source copy helper read/write/whole input roles')
                supplied = [refs[0]['scope'], source_token, target_token]
                for index, facts in zip(by_kind['reference'], refs, strict=True):
                    operations.append({'index': index, 'kind': 'reference', 'phase': 'returned_before_outer_operation',
                                       'supplied': freeze([facts['scope'], facts['token'], facts['access'], 1]),
                                       'normalized_operation_inputs': freeze(inputs(index))})
                index = by_kind['copy'][0]
                require(named(inputs(index))['context'] == 'copy control', 'source copy helper context role')
                operations.append({'index': index, 'kind': 'copy', 'phase': 'active', 'normalized_operation_inputs': freeze(inputs(index))})
            elif function == 'scope_for':
                require(tokens == ['$spec', '$types{frame}'] and len(by_kind.get('scope', [])) == 1, 'finite source supplied scope helper arguments')
                index = by_kind['scope'][0]
                facts = named(inputs(index))
                outer = facts['outer']
                require(set(facts) == {'outer', 'local'} and set(outer) == {'packet', 'held', 'output', 'scalar'}
                        and [outer[key]['role'] for key in ('packet', 'held', 'output', 'scalar')] == ['input', 'storage', 'output', 'output']
                        and outer['held']['type_spec'] is outer['output']['type_spec'] and facts['local'] == {},
                        'complete source scope helper root/target-sharing/local-default roles')
                supplied = [outer['packet']['type_spec'], outer['held']['type_spec']]
                defaults = {'local': freeze({})}
                operations.append({'index': index, 'kind': 'scope', 'phase': 'active', 'normalized_operation_inputs': freeze(inputs(index))})
            else:
                require(function is None, 'complete finite named helper source family')
            for operation in operations:
                require((causes[operation['index']] is None) == (operation['phase'] == 'returned_before_outer_operation'),
                        'named helper return/throw joins independent source primary truth')
            frames = [] if function is None else [{'function': 'main::' + function, 'call_site': 'original_compiled_callback',
                                                   'arguments': [argument(value, formal) for value, formal in zip(supplied, helper_model['FORMALS'][function], strict=False)]}]
            recipes.append({'index': helper['index'], 'label': helper['label'], 'source_statement': helper['source_statement'],
                            'source_declaration': helper['source_declaration'], 'call_shape': shape,
                            'api_members': helper['api_members'], 'parse_members': helper['parse_members'],
                            'supplied_tokens': tokens, 'supplied_arguments': freeze(supplied), 'defaults': defaults,
                            'unsupplied_formals': helper_model['FORMALS'][function][len(supplied):] if function else [],
                            'named_operations': operations, 'active_frames': frames})
        cases = []
        for domain in ('api', 'parses'):
            for boundary_case in mode[domain]:
                recipe = recipes[boundary_case['helper']]
                outer_kind = recipe['call_shape']['outer_operation']
                phases = sum(b['kind'] == outer_kind for b in boundary_case['boundaries'])
                require(phases in (1, 2), 'complete source callback outer-operation throw phases')
                cases.append({'domain': domain, 'index': boundary_case['index'], 'helper': recipe['index'],
                              'phases': phases, 'frames': recipe['active_frames'] * phases})
        result.append({'mode': mode['mode'], 'helpers': recipes, 'cases': cases})
    return result


PACKAGES = tuple('main::' + name + '(' for name in helper_model['NAMED'])


def check(models, expected, inventories, source):
    check_sources(source)
    require(same(models, expected), 'complete source named-helper input/default/operation/phase models')
    proof = []
    for modeled, inventory in zip(models, inventories, strict=True):
        require(modeled['mode'] == inventory['mode'], 'named-helper native mode identity')
        observed = []
        for domain in ('api', 'parses'):
            native = {row['index']: row for row in inventory['domains'][domain]['nonempty']}
            cases = [case for case in modeled['cases'] if case['domain'] == domain]
            require(len(native) == len(inventory['domains'][domain]['nonempty'])
                    and set(native) == {case['index'] for case in cases}, 'complete named-helper native refusal population')
            for case in cases:
                row = native[case['index']]
                require(row['context']['helper'] == case['helper'], 'source named-helper refusal allocation')
                actual = [frame for frame in row['segments'] if frame['kind'] == 'frame' and frame['call'].startswith(PACKAGES)]
                require([frame['call'].split('(', 1)[0] for frame in actual] == [frame['function'] for frame in case['frames']], 'complete source-derived named-helper active frame order')
                visible = []
                for got, want in zip(actual, case['frames'], strict=True):
                    footprint = prior['arguments'](got['call'], want['function'])
                    direct['check_footprint'](footprint, want['arguments'])
                    visible.append(footprint)
                observed.append({'domain': domain, 'index': case['index'], 'body': row['body_identity'], 'visible_named_helper_footprints': visible})
        proof.append({'mode': modeled['mode'], 'cases': observed})
    return proof


def native_case(inventories, index):
    return next(row for row in inventories[0]['domains']['api']['nonempty'] if row['index'] == index)


def named_frames(inventories, index):
    return [frame for frame in native_case(inventories, index)['segments'] if frame['kind'] == 'frame' and frame['call'].startswith(PACKAGES)]


def main():
    authenticate()
    source = sources()
    expected = expected_models(source)
    inventories = load(direct['classes']['RAW'] / 'proofs.json')['inventories']
    observed = check(expected, expected, inventories, source)
    sample = next(case for case in expected[0]['cases'] if case['domain'] == 'api' and case['frames'])
    index = sample['index']
    controls = []
    mutations = [
        ('wrong-source-access-default', lambda m, n, s: s.update(test=s['test'].replace("access => $access || 'read'", "access => $access || 'write'")), 'exact named-helper formal/default/delegate source'),
        ('wrong-source-copy-target-access', lambda m, n, s: s.update(test=s['test'].replace("reference($scope, $target, 'write', 1)", "reference($scope, $target, 'read', 1)")), 'exact named-helper formal/default/delegate source'),
        ('wrong-source-callback-token', lambda m, n, s: s.update(test=s['test'].replace("reference($scope, 'packet', 'write', 1) }, qr/cannot write", "reference($scope, 'held', 'write', 1) }, qr/cannot write")), 'whole qualified named-helper callback source authority'),
        ('borrowed-helper-input', lambda m, n, s: m[0]['helpers'][1].update(supplied_arguments=m[0]['helpers'][2]['supplied_arguments']), 'complete source named-helper input/default/operation/phase models'),
        ('supplied-invented-default', lambda m, n, s: m[0]['helpers'][2].update(unsupplied_formals=[]), 'complete source named-helper input/default/operation/phase models'),
        ('borrowed-completed-call-phase', lambda m, n, s: m[0]['helpers'][24]['named_operations'][0].update(phase='active'), 'complete source named-helper input/default/operation/phase models'),
        ('omitted-source-helper', lambda m, n, s: m[0]['helpers'].pop(), 'complete source named-helper input/default/operation/phase models'),
        ('wrong-source-throw-phase', lambda m, n, s: next(case for case in m[0]['cases'] if case['phases']==2).update(phases=1), 'complete source named-helper input/default/operation/phase models'),
        ('omitted-native-refusal', lambda m, n, s: n[0]['domains']['api']['nonempty'].pop(), 'complete named-helper native refusal population'),
        ('wrong-native-helper', lambda m, n, s: native_case(n, index)['context'].update(helper=0), 'source named-helper refusal allocation'),
        ('wrong-native-helper-frame', lambda m, n, s: named_frames(n, index)[0].update(call='main::copy()'), 'complete source-derived named-helper active frame order'),
        ('wrong-actual-helper-token', lambda m, n, s: named_frames(n, index)[0].update(call=named_frames(n, index)[0]['call'].replace('"packet"', '"held"', 1)), 'direct Value source scalar argument footprint'),
        ('wrong-actual-helper-scope-kind', lambda m, n, s: named_frames(n, index)[0].update(call=named_frames(n, index)[0]['call'].replace('HASH(', 'ARRAY(', 1)), 'direct Value reference argument footprint'),
    ]
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(item) for item in (expected, inventories, source)]
        mutate(*changed)
        try:
            check(changed[0], expected, changed[1], changed[2])
        except ValueError as error:
            require(str(error) == cause, 'intended named-helper control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green own named-helper qualification: ' + name)
    proof = {'models': expected, 'footprints': observed, 'controls': controls,
             'scope': 'Complete finite source named-helper supplied/default/operation inputs and active paths; compiled callback/refuses/framework/display/identity remain open.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved named-helper proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed named-helper producer cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete own named-helper supplied/default inputs and active source paths; compiled callback/framework/display/native identity remains open.')


if __name__ == '__main__':
    main()
