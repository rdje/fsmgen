"""Own observer API/parser boundary paths; full display remains open."""
import copy
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-observer-boundaries-20261005')
PRIOR = Path('docs/audits/record-value-original-observer-sources-20261005')
REVISION = 'd0db4ee6c79789875d96d0f648922f698ffe06ca'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.1'


def module(path):
    namespace = {'__name__': 'observer_boundary_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


prior = module(PRIOR / 'verify.py')
api, primary = prior['api'], prior['primary']
require, load, same, sealed = (prior[key] for key in ('require', 'load', 'same', 'sealed'))
frame_model = module(BASE / 'frame_model.py')
inherited, direct = api['inherited'], api['direct']


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact done observer-source intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed observer-boundary intake task')
    start = task.index('- ID: `' + OWNER + '`')
    end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end], 'whole completed observer-source owner')
    require(set(binding['archives']) == set(load(PRIOR / 'binding.json')['archives']) | {str(PRIOR)}, 'complete observer-boundary prerequisite domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole observer-boundary prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
                    == (Path(path) / name).read_bytes(), 'whole committed observer-boundary prerequisite bytes')
    require(binding['auxiliary_receipts'] == load(PRIOR / 'binding.json')['auxiliary_receipts'], 'whole inherited receipt-control authority')
    for path, body in binding['auxiliary_receipts'].items():
        require(subprocess.check_output(['git', 'show', REVISION + ':' + path]) == Path(path).read_bytes() == body.encode(), 'whole committed receipt-control bytes')
    prior['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def sources():
    test, _, _, _ = primary['context']['source_models']()
    original = load(primary['result_reader']['CAPTURE'] / 'binding.json')['sources']
    return {'observer': inherited['nested']['sources']()['observer'], 'test': test,
            'facade': original['perl/FSM/Adapter/ISF.pm']['body']}


def check_sources(source):
    observer = source['observer']
    for parser, wrappers in ((False, frame_model['API_WRAPPERS']), (True, frame_model['PARSER_WRAPPERS'])):
        for kind, (function, operation) in wrappers.items():
            name = 'parse' if parser else 'call_api'
            wrapper = 'local *' + function + " = sub {\n        return " + name + "('" + kind + "', " + operation + ', [caller], @_);\n    };'
            require(observer.count(wrapper) == 1, 'exact observer installed operation wrapper')
            lookup = frame_model['VALUE_LOOKUP'] if operation.startswith('$value{') else frame_model['LOOKUPS'][operation]
            require(observer.count(lookup) == 1 and observer.index(lookup) < observer.index(wrapper), 'original operation lookup precedes installed wrapper')
    for function, end, statement in (('call_api', 'copy_value', frame_model['API_EVAL']), ('parse', None, frame_model['PARSER_EVAL'])):
        body = observer[observer.index('sub ' + function + ' {'):]
        body = body[:body.index('sub ' + end + ' {')] if end else body[:body.index("\n{\n    no warnings 'redefine';")]
        require(body.count(frame_model['PARAMETERS']) == body.count(statement) == 1, 'exact observer operation parameters/eval source')
        require(body.count('die $error unless $ok;') == 1, 'explicit observer operation rethrow source')
        if function == 'parse':
            require(body.count(frame_model['PARSER_INPUTS']) == 1, 'parser graph excludes receiver but operation retains all arguments')
    require(source['test'].count(frame_model['PARSER_CONSTRUCTION']) == 1, 'source parser facade construction role')
    for statement in frame_model['FACADE_CONTRACTS']:
        require(source['facade'].count(statement) == 1, 'exact own parser facade receiver/delegate source')


def expected_models(source):
    check_sources(source)
    api_source = api['sources']()
    own = api['expected_models'](api_source)
    direct_modes = direct['expected_models'](api_source['direct'])
    metadata_modes = api['metadata']['expected_models'](api_source['metadata'])
    nested_modes = inherited['expected_models'](api_source['inherited'])
    _, _, _, products = primary['context']['source_models']()
    qualified = load(primary['BASE'] / 'proofs.json')['proofs']
    result = []
    for joined, value, metadata, nested, first in zip(own, direct_modes, metadata_modes, nested_modes, qualified, strict=True):
        require(len({m['mode'] for m in (joined, value, metadata, nested, first)}) == 1, 'observer boundary source mode identity')
        direct_cases = {case['index']: case for case in value['cases']}
        metadata_cases = {case['index']: case for case in metadata['cases']}
        pairs = {pair[key]: pair for pair in nested['pairs'] for key in ('scope_api', 'capture_api')}
        cases = []
        for case in joined['cases']:
            index = case['index']
            if index in direct_cases:
                operation = direct_cases[index]['frames'][-1]
                boundaries = [frame_model['boundary'](case['kind'], operation['arguments'])]
                require(boundaries[0]['frames'][0]['function'] == operation['function'], 'direct original operation/source role joins')
            else:
                pair = pairs[index]
                path = metadata_cases[index]['frames'] + pair['inner_path']
                if index == pair['scope_api']:
                    path += pair['new_outer_path']
                boundaries = []
                for position, frame in enumerate(path):
                    if frame['function'] != 'main::call_api':
                        continue
                    kind = frame['arguments'][0]['value']
                    original_arguments = path[position - 2]['arguments']
                    delegated_arguments = frame['arguments'][3:]
                    boundary = frame_model['boundary'](kind, delegated_arguments, original_arguments=original_arguments)
                    require(path[position - 2]['function'] == boundary['frames'][0]['function']
                            and path[position - 1]['function'] == 'eval {...}'
                            and path[position + 1]['function'] == 'main::__ANON__', 'nested original source operation boundary joins')
                    require(len(original_arguments) == len(delegated_arguments), 'nested complete operation argument role joins')
                    for original_arg, delegated_arg in zip(original_arguments, delegated_arguments, strict=True):
                        require(same({k: v for k, v in original_arg.items() if k != 'role'},
                                     {k: v for k, v in delegated_arg.items() if k != 'role'}), 'nested complete operation argument role joins')
                        # The independently qualified metadata and inherited
                        # models name the same full interface at different
                        # boundaries. Preserve both names and its whole graph
                        # authority; do not erase role metadata to join them.
                        if original_arg['role'] != delegated_arg['role']:
                            require(kind == 'capture' and original_arg['role'] == 'declared_interface'
                                    and delegated_arg['role'] == 'constructed_metadata_interface', 'declared nested argument role bridge')
                            boundary['role_bridge_authority'] = pair['source_argument_authority']['metadata_interface']
                    boundaries.append(boundary)
            cases.append({'index': index, 'kind': case['kind'], 'boundaries': boundaries,
                          'helper': products['apis'][index]['whole_native']['helper'],
                          'caller_context': products['apis'][index]['whole_native']['caller']})
        parsers = []
        for parsed in first['parsers']:
            if parsed['primary'] is None:
                continue
            index = parsed['index']
            product = products['actors'][index]
            arguments = primary['graph']['thaw'](product['whole_native']['before'])
            # The receiver was deliberately excluded from graph publication.
            # Its declared role comes from this repository's constructor/call,
            # not from the rendered address or an invented old object census.
            args = [frame_model['reference']('declared_facade_receiver', 'FSM::Adapter::ISF=HASH'),
                    frame_model['scalar']('whole_source_text', arguments[0]),
                    frame_model['scalar']('source_filename', arguments[1])]
            parsers.append({'index': index, 'kind': 'source', 'helper': product['whole_native']['helper'],
                            'caller_context': product['whole_native']['caller'],
                            'boundaries': [frame_model['boundary']('source', args, True)]})
        result.append({'mode': joined['mode'], 'api': cases, 'parses': parsers})
    return result


TOKEN = re.compile(r'FSM::Adapter::ISF=HASH\(0x[0-9a-fA-F]+\)|(?:HASH|ARRAY|CODE)\(0x[0-9a-fA-F]+\)|undef|-?[0-9]+|"(?:\\.|[^"\\])*"(?:\.\.\.)?|\.\.\.')


def arguments(call, function):
    require(call.startswith(function + '(') and call.endswith(')'), 'observer boundary function header')
    body, offset, result = call[len(function) + 1:-1], 0, []
    while offset < len(body):
        match = TOKEN.match(body, offset)
        require(match is not None, 'finite observer boundary argument grammar')
        raw, offset = match.group(), match.end()
        if raw == '...':
            result.append({'kind': 'remaining_arguments'})
        elif raw.endswith(')') and not raw.startswith('"'):
            result.append({'kind': 'reference', 'reference_kind': raw.split('(')[0]})
        elif raw.startswith('"'):
            truncated = raw.endswith('...')
            result.append({'kind': 'scalar', 'value': json.loads(raw[:-3] if truncated else raw), 'truncated': truncated})
        else:
            result.append({'kind': 'scalar', 'value': None if raw == 'undef' else raw, 'truncated': False})
        if offset < len(body):
            require(body[offset:offset + 2] == ', ', 'observer boundary argument separator')
            offset += 2
    return result


def check(models, expected, inventories, source):
    check_sources(source)
    require(same(models, expected), 'complete observer boundary source operation/argument/member models')
    proof = []
    for modeled, inventory in zip(models, inventories, strict=True):
        require(modeled['mode'] == inventory['mode'], 'observer boundary actual mode identity')
        cases = []
        for domain in ('api', 'parses'):
            native = {row['index']: row for row in inventory['domains'][domain]['nonempty']}
            require(len(native) == len(inventory['domains'][domain]['nonempty'])
                    and set(native) == {case['index'] for case in modeled[domain]}, 'complete observer boundary native refusal population')
            for case in modeled[domain]:
                row = native[case['index']]
                require(row['context']['kind'] == case['kind'] and row['context']['helper'] == case['helper']
                        and same(row['context']['caller'], case['caller_context']), 'observer boundary source family/helper/caller allocation')
                frames = [segment for segment in row['segments'] if segment['kind'] == 'frame']
                function = 'main::call_api' if domain == 'api' else 'main::parse'
                positions = [i for i, frame in enumerate(frames) if frame['call'].startswith(function + '(')]
                require(len(positions) == len(case['boundaries']), 'complete observer operation boundary membership')
                footprints = []
                for position, boundary in zip(positions, case['boundaries'], strict=True):
                    require(position >= 2 and position + 1 < len(frames), 'complete adjacent observer operation boundary')
                    actual = frames[position - 2:position + 2]
                    wanted = boundary['frames']
                    require([frame['call'].split('(', 1)[0] for frame in actual]
                            == [frame['function'] for frame in wanted], 'source-derived observer original/eval/delegate/wrapper order')
                    visible = []
                    for got, want in zip(actual, wanted, strict=True):
                        if want['function'] == 'eval {...}':
                            require(got['call'] == 'eval {...}' and want['arguments'] == [], 'observer source eval footprint')
                            visible.append([])
                        else:
                            parsed = arguments(got['call'], want['function'])
                            direct['check_footprint'](parsed, want['arguments'])
                            visible.append(parsed)
                    footprints.append(visible)
                cases.append({'domain': domain, 'index': case['index'], 'body': row['body_identity'], 'visible_boundary_footprints': footprints})
        proof.append({'mode': modeled['mode'], 'cases': cases})
    return proof


def raw_case(inventories, domain, index):
    return next(row for row in inventories[0]['domains'][domain]['nonempty'] if row['index'] == index)


def boundary_frames(inventories, domain, index):
    frames = [segment for segment in raw_case(inventories, domain, index)['segments'] if segment['kind'] == 'frame']
    name = 'main::call_api' if domain == 'api' else 'main::parse'
    position = next(i for i, frame in enumerate(frames) if frame['call'].startswith(name + '('))
    return frames[position - 2:position + 2]


def main():
    authenticate()
    source = sources()
    expected = expected_models(source)
    inventories = load(direct['classes']['RAW'] / 'proofs.json')['inventories']
    observed = check(expected, expected, inventories, source)
    api_index, parser_index = expected[0]['api'][0]['index'], expected[0]['parses'][0]['index']
    controls = []
    mutations = [
        ('wrong-installed-operation', lambda m, n, s: s.update(observer=s['observer'].replace("return call_api('reference', $value{record_value_reference}", "return call_api('reference', $value{record_value_scope}")), 'exact observer installed operation wrapper'),
        ('wrong-observer-eval', lambda m, n, s: s.update(observer=s['observer'].replace(frame_model['API_EVAL'], '$ok = 1;')), 'exact observer operation parameters/eval source'),
        ('wrong-parser-receiver-source', lambda m, n, s: s.update(test=s['test'].replace(frame_model['PARSER_CONSTRUCTION'], 'my $parser = {};')), 'source parser facade construction role'),
        ('wrong-source-operation-role', lambda m, n, s: m[0]['api'][0]['boundaries'][0].update(operation_lookup='$borrowed'), 'complete observer boundary source operation/argument/member models'),
        ('borrowed-nested-role-bridge', lambda m, n, s: next(b for c in m[0]['api'] for b in c['boundaries'] if 'role_bridge_authority' in b).update(role_bridge_authority='borrowed graph'), 'complete observer boundary source operation/argument/member models'),
        ('omitted-source-parser', lambda m, n, s: m[0]['parses'].pop(), 'complete observer boundary source operation/argument/member models'),
        ('omitted-native-API', lambda m, n, s: n[0]['domains']['api']['nonempty'].pop(), 'complete observer boundary native refusal population'),
        ('wrong-native-caller', lambda m, n, s: raw_case(n, 'api', api_index)['context'].update(caller=['borrowed', 'wrong.t', 0]), 'observer boundary source family/helper/caller allocation'),
        ('wrong-original-operation-frame', lambda m, n, s: boundary_frames(n, 'api', api_index)[0].update(call='borrowed::operation()'), 'source-derived observer original/eval/delegate/wrapper order'),
        ('wrong-observer-eval-frame', lambda m, n, s: boundary_frames(n, 'api', api_index)[1].update(call='borrowed::eval()'), 'source-derived observer original/eval/delegate/wrapper order'),
        ('wrong-installed-wrapper-frame', lambda m, n, s: boundary_frames(n, 'api', api_index)[3].update(call='borrowed::wrapper()'), 'source-derived observer original/eval/delegate/wrapper order'),
        ('wrong-API-kind-operand', lambda m, n, s: boundary_frames(n, 'api', api_index)[2].update(call=boundary_frames(n, 'api', api_index)[2]['call'].replace('"copy"', '"scope"', 1)), 'direct Value source scalar argument footprint'),
        ('wrong-parser-source-operand', lambda m, n, s: boundary_frames(n, 'parses', parser_index)[2].update(call='main::parse("source", CODE(0x1), ARRAY(0x2), FSM::Adapter::ISF=HASH(0x3), "wrong source", "still-refused.isf")'), 'direct Value source scalar argument footprint'),
        ('wrong-parser-receiver-footprint', lambda m, n, s: boundary_frames(n, 'parses', parser_index)[2].update(call=boundary_frames(n, 'parses', parser_index)[2]['call'].replace('FSM::Adapter::ISF=HASH(', 'HASH(', 1)), 'direct Value reference argument footprint'),
    ]
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(item) for item in (expected, inventories, source)]
        mutate(*changed)
        try:
            check(changed[0], expected, changed[1], changed[2])
        except ValueError as error:
            require(str(error) == cause, 'intended observer-boundary control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green observer operation boundary: ' + name)
    proof = {'models': expected, 'footprints': observed, 'controls': controls,
             'scope': 'Complete finite own observer API/parser operation/eval/delegate/wrapper and visible roles; receiver object identity and full framework/display/trace remain open.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved observer-boundary proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed observer-boundary producer cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete finite observer API/parser operation boundaries and visible roles; full callback/framework/display/native identity stays open.')


if __name__ == '__main__':
    main()
