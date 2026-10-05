"""Nested inherited API path roles/order; full observer/display meaning stays open."""
import copy
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-inherited-frames-20261005')
FORWARDING = Path('docs/audits/record-value-original-forwarding-20261005')
REVISION = '2d2bac938684e0580a5c77da266928b669ed4923'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.2.3.2'


def module(path):
    namespace = {'__name__': 'inherited_frame_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


forwarding = module(FORWARDING / 'verify.py')
nested = forwarding['nested']
metadata = nested['metadata']
direct = metadata['value']
primary = nested['primary']
require, load, same, sealed = (nested[key] for key in ('require', 'load', 'same', 'sealed'))
frame_model = module(BASE / 'frame_model.py')


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact done forwarding owner intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed inherited-frame intake task')
    start = task.index('- ID: `' + OWNER + '`')
    end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end], 'whole completed forwarding owner')
    require(set(binding['archives']) == set(load(FORWARDING / 'binding.json')['archives']) | {str(FORWARDING)},
            'complete inherited-frame prerequisite domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole inherited-frame prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
                    == (Path(path) / name).read_bytes(), 'whole committed inherited-frame prerequisite bytes')
    forwarding['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def check_sources(source):
    forwarding['check_sources'](source)
    contracts = frame_model['CONTRACTS']
    observer, value = source['observer'], source['value']
    call_api = observer[observer.index('sub call_api {'):observer.index('sub copy_value {')]
    scope = value[value.index('sub record_value_scope {'):value.index('sub record_value_reference {')]
    validate = value[value.index('sub _validate_type {'):value.index('sub _closed_type {')]
    for key, statement in contracts.items():
        body = scope if key == 'scope_parameters' else validate if key == 'type_parameters' else call_api if key == 'observer_parameters' else observer
        require(body.count(statement) == 1, 'exact inherited source lookup/wrapper/parameter contract')
    require(observer.index(contracts['capture_lookup']) < observer.index(nested['CONTRACTS']['capture_wrapper'])
            < observer.index(nested['CONTRACTS']['wrapper_before_import']) < observer.index(contracts['scope_lookup'])
            < observer.index(contracts['scope_wrapper']), 'original operation lookup/import/wrapper ordering')


def expected_models(source):
    check_sources(source)
    scopes = {row['index']: row for row in load(nested['SCOPES'])['rows']}
    forwarded = load(FORWARDING / 'proofs.json')['models']
    inputs = load(nested['BASE'] / 'proofs.json')['models']
    result = []
    for mode, input_mode in zip(forwarded, inputs, strict=True):
        require(mode['mode'] == input_mode['mode'], 'inherited source mode identity')
        qualified = {pair['scope_api']: pair for pair in input_mode['pairs']}
        pairs = []
        for pair in mode['pairs']:
            input_pair = qualified[pair['scope_api']]
            require(pair['capture_api'] == input_pair['capture_api'] and pair['context'] == input_pair['context'],
                    'source input/forwarding inherited allocation join')
            arguments = primary['graph']['thaw'](scopes[pair['scope_api']]['recipe']['arguments'])
            require(len(arguments) == 4 and arguments[::2] == ['outer', 'local']
                    and all(type(value) is dict for value in arguments[1::2]), 'finite qualified source Scope argument profile')
            paths = frame_model['derive'](pair, arguments, direct['frame_model']['argument'], pair['inner_value'])
            pairs.append({'scope_api': pair['scope_api'], 'capture_api': pair['capture_api'], 'helper': pair['helper'],
                          'context': pair['context'], 'outer_prefix_bytes': pair['prefix_identity']['bytes'],
                          'source_argument_authority': {'scope': primary['digest'](scopes[pair['scope_api']]['recipe']['arguments']),
                                'private_root': primary['digest'](input_pair['private_result_model']),
                                'metadata_interface': primary['digest'](input_pair['capture_input_model'])}, **paths})
        require(set(qualified) == {pair['scope_api'] for pair in pairs}, 'complete inherited source pair domain')
        result.append({'mode': mode['mode'], 'pairs': pairs})
    return result


TOKEN = re.compile(r'(?:HASH|ARRAY|CODE)\(0x[0-9a-fA-F]+\)|undef|-?[0-9]+|"(?:\\.|[^"\\])*"(?:\.\.\.)?|\.\.\.')


def arguments(call, function):
    # Same qualified finite grammar as direct Value, extended explicitly for
    # the observer's published CODE operand. No pointer identity is inferred.
    require(call.startswith(function + '(') and call.endswith(')'), 'inherited function header')
    body, offset, result = call[len(function) + 1:-1], 0, []
    while offset < len(body):
        match = TOKEN.match(body, offset)
        require(match is not None, 'finite inherited argument footprint grammar')
        raw, offset = match.group(), match.end()
        if raw == '...':
            result.append({'kind': 'remaining_arguments'})
        elif re.fullmatch(r'(HASH|ARRAY|CODE)\(0x[0-9a-fA-F]+\)', raw):
            result.append({'kind': 'reference', 'reference_kind': raw.split('(')[0]})
        elif raw.startswith('"'):
            truncated = raw.endswith('...')
            result.append({'kind': 'scalar', 'value': json.loads(raw[:-3] if truncated else raw), 'truncated': truncated})
        else:
            result.append({'kind': 'scalar', 'value': None if raw == 'undef' else raw, 'truncated': False})
        if offset < len(body):
            require(body[offset:offset + 2] == ', ', 'inherited argument separator')
            offset += 2
    return result


def check_path(actual, wanted):
    functions = [row['call'].split('(', 1)[0] for row in actual]
    require(functions == [row['function'] for row in wanted], 'source-derived inherited active frame ordering')
    footprints = []
    for got, want in zip(actual, wanted, strict=True):
        if want['function'] == 'eval {...}':
            require(got['call'] == 'eval {...}' and want['arguments'] == [], 'source eval frame footprint')
            footprints.append([])
        else:
            parsed = arguments(got['call'], want['function'])
            direct['check_footprint'](parsed, want['arguments'])
            footprints.append(parsed)
    return footprints


def frames(row):
    return [segment for segment in row['segments'] if segment['kind'] == 'frame']


def check(models, expected, inventories, source):
    check_sources(source)
    require(same(models, expected), 'complete inherited pair/source-role/path models')
    result = []
    for mode, inventory in zip(models, inventories, strict=True):
        require(mode['mode'] == inventory['mode'], 'inherited native mode identity')
        native = {row['index']: row for row in inventory['domains']['api']['nonempty']}
        pairs = []
        for pair in mode['pairs']:
            child, parent = (native[pair[key]] for key in ('capture_api', 'scope_api'))
            require(child['context']['helper'] == parent['context']['helper'] == pair['helper'], 'actual inherited pair/helper allocation')
            inner = frames(child)
            starts = [i for i, row in enumerate(inner) if row['call'].startswith(frame_model['METADATA'] + 'capture_interface_port_metadata(')]
            require(len(starts) == 1, 'qualified metadata public-frame anchor')
            selected = inner[starts[0] + 1:starts[0] + 1 + len(pair['inner_path'])]
            inner_footprints = check_path(selected, pair['inner_path'])
            outer = [row for row in frames(parent) if row['offset_bytes'] >= pair['outer_prefix_bytes']]
            outer_footprints = check_path(outer[:len(pair['new_outer_path'])], pair['new_outer_path'])
            for phase, path in ((inner, pair['inner_path']), (outer, pair['new_outer_path'])):
                require([row['call'].split('(', 1)[0] for row in phase if row['call'].startswith(frame_model['VALUE'])]
                        == [row['function'] for row in path if row['function'].startswith(frame_model['VALUE'])],
                        'complete inherited own Value function projection')
                require(sum(row['call'].startswith('main::call_api(') for row in phase)
                        == sum(row['function'] == 'main::call_api' for row in path), 'complete inherited observer API boundary population')
            pairs.append({'scope_api': pair['scope_api'], 'capture_api': pair['capture_api'],
                          'inner_visible_footprints': inner_footprints, 'new_outer_visible_footprints': outer_footprints,
                          'inner_body': child['body_identity'], 'outer_body': parent['body_identity']})
        result.append({'mode': mode['mode'], 'pairs': pairs})
    return result


def mutate_frame(native, index, phase, position, change):
    row = next(row for row in native[0]['domains']['api']['nonempty'] if row['index'] == index)
    rows = frames(row)
    if phase == 'inner':
        start = next(i for i, row in enumerate(rows) if row['call'].startswith(frame_model['METADATA'] + 'capture_interface_port_metadata(')) + 1
        change(rows[start + position])
    else:
        start = next(i for i, row in enumerate(rows) if row['call'].startswith(frame_model['VALUE'] + '_require('))
        change(rows[start + position])


def omit_wrapper(native, index):
    row = next(row for row in native[0]['domains']['api']['nonempty'] if row['index'] == index)
    own = frames(row)
    start = next(i for i, frame in enumerate(own) if frame['call'].startswith(frame_model['METADATA'] + 'capture_interface_port_metadata('))
    row['segments'].remove(own[start + 3])


def reorder_boundary(native, index):
    row = next(row for row in native[0]['domains']['api']['nonempty'] if row['index'] == index)
    own = frames(row)
    start = next(i for i, frame in enumerate(own) if frame['call'].startswith(frame_model['METADATA'] + 'capture_interface_port_metadata('))
    own[start + 1]['call'], own[start + 2]['call'] = own[start + 2]['call'], own[start + 1]['call']


def main():
    authenticate()
    source = nested['sources']()
    expected = expected_models(source)
    inventories = load(direct['classes']['RAW'] / 'proofs.json')['inventories']
    observed = check(expected, expected, inventories, source)
    controls = []
    first = expected[0]['pairs'][0]
    child, parent = first['capture_api'], first['scope_api']
    mutations = [
        ('wrong-scope-wrapper', lambda m, n, s: s.update(observer=s['observer'].replace(frame_model['CONTRACTS']['scope_wrapper'], frame_model['CONTRACTS']['scope_wrapper'].replace("'scope'", "'copy'"))), 'exact inherited source lookup/wrapper/parameter contract'),
        ('wrong-operation-lookup', lambda m, n, s: s.update(observer=s['observer'].replace(frame_model['CONTRACTS']['capture_lookup'], frame_model['CONTRACTS']['capture_lookup'].replace("'capture_interface_port_metadata'", "'snapshot_interface_port_metadata'"))), 'exact inherited source lookup/wrapper/parameter contract'),
        ('changed-intended-role', lambda m, n, s: m[0]['pairs'][0]['inner_path'][4]['arguments'][0].update(role='caller_root'), 'complete inherited pair/source-role/path models'),
        ('omitted-source-pair', lambda m, n, s: m[0]['pairs'].pop(), 'complete inherited pair/source-role/path models'),
        ('wrong-model-phase', lambda m, n, s: m[0]['pairs'][0]['inner_path'].reverse(), 'complete inherited pair/source-role/path models'),
        ('wrong-native-function', lambda m, n, s: mutate_frame(n, child, 'inner', 4, lambda r: r.update(call=r['call'].replace('::_validate_type(', '::_closed_type('))), 'source-derived inherited active frame ordering'),
        ('missing-eval-role', lambda m, n, s: mutate_frame(n, child, 'inner', 3, lambda r: r.update(call='main::__ANON__()')), 'source-derived inherited active frame ordering'),
        ('omitted-wrapper-frame', lambda m, n, s: omit_wrapper(n, child), 'source-derived inherited active frame ordering'),
        ('reordered-eval-boundary', lambda m, n, s: reorder_boundary(n, child), 'source-derived inherited active frame ordering'),
        ('wrong-capture-API-kind', lambda m, n, s: mutate_frame(n, child, 'inner', 1, lambda r: r.update(call=r['call'].replace('"capture"', '"scope"', 1))), 'direct Value source scalar argument footprint'),
        ('wrong-operation-kind', lambda m, n, s: mutate_frame(n, child, 'inner', 1, lambda r: r.update(call=r['call'].replace('CODE(', 'HASH(', 1))), 'direct Value reference argument footprint'),
        ('wrong-caller-kind', lambda m, n, s: mutate_frame(n, child, 'inner', 1, lambda r: r.update(call=r['call'].replace('ARRAY(', 'HASH(', 1))), 'direct Value reference argument footprint'),
        ('wrong-wrapped-interface-kind', lambda m, n, s: mutate_frame(n, child, 'inner', 2, lambda r: r.update(call=r['call'].replace('HASH(', 'ARRAY(', 1))), 'direct Value reference argument footprint'),
        ('wrong-root-context', lambda m, n, s: mutate_frame(n, child, 'inner', 4, lambda r: r.update(call=r['call'].replace("root 'packet'", "root 'held'"))), 'direct Value source scalar argument footprint'),
        ('wrong-Scope-argument', lambda m, n, s: mutate_frame(n, child, 'inner', 5, lambda r: r.update(call=r['call'].replace('"outer"', '"local"', 1))), 'direct Value source scalar argument footprint'),
        ('wrong-failed-eval-result', lambda m, n, s: mutate_frame(n, parent, 'outer', 0, lambda r: r.update(call=r['call'].replace('undef,', '0,', 1))), 'direct Value source scalar argument footprint'),
        ('wrong-new-throw-context', lambda m, n, s: mutate_frame(n, parent, 'outer', 0, lambda r: r.update(call=r['call'].replace("root 'packet'", "root 'held'"))), 'direct Value source scalar argument footprint'),
    ]
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(item) for item in (expected, inventories, source)]
        mutate(*changed)
        try:
            check(changed[0], expected, changed[1], changed[2])
        except ValueError as error:
            require(str(error) == cause, 'intended inherited control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green inherited source path control: ' + name)
    proof = {'models': expected, 'footprints': observed, 'controls': controls,
             'scope': 'Own nested API frame order/source argument roles and visible footprints; full observer, exact display/coordinates/live identity remain open.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved inherited frame proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed inherited producer cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS finite inherited Value/capture/eval source path roles and visible footprints; full observer/display/coordinate/address meaning stays open.')


if __name__ == '__main__':
    main()
