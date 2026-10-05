"""Direct finite Value frame paths; metadata and display semantics stay open."""
import copy
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-value-frames-20261005')
CLASS = Path('docs/audits/record-value-original-class-20261005')
REVISION = 'b1d00a72c8e4e8ae2685434cfa9a33b2b6c07f72'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.1'
VALUE_SOURCE = 'perl/FSM/Support/ISFRecordPortValues.pm'


def module(path):
    namespace = {'__name__': 'value_frame_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


classes = module(CLASS / 'verify.py')
primary = classes['primary']
require, load, same, sealed, identity = (classes[key] for key in ('require', 'load', 'same', 'sealed', 'identity'))
frame_model = module(BASE / 'frame_model.py')


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact completed class owner intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed Value-frame intake task')
    start = task.index('- ID: `' + OWNER + '`'); end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end], 'whole done class owner')
    require(set(binding['archives']) == set(load(CLASS / 'binding.json')['archives']) | {str(CLASS)},
            'complete Value-frame prerequisite domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole Value-frame prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
                    == (Path(path) / name).read_bytes(), 'whole committed Value-frame prerequisite bytes')
    classes['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def source_contracts():
    source = load(primary['result_reader']['CAPTURE'] / 'binding.json')['sources'][VALUE_SOURCE]['body']
    return {'value': source, 'cause_model': (primary['BASE'] / 'cause_model.py').read_text()}


def check_source(source):
    for statement in frame_model['GUARDS'].values():
        require(source['value'].count(statement) == 1, 'exact direct Value guard statement')
    for statement in frame_model['CALLS'].values():
        require(source['value'].count(statement) == 1, 'exact direct Value call statement')
    require(source['cause_model'] == (primary['BASE'] / 'cause_model.py').read_text(),
            'whole independently qualified predicate model')


def expected_models(source):
    check_source(source)
    graph = primary['graph']
    intervention, _, _ = graph['source_interventions']()
    _, _, _, products = primary['context']['source_models']()
    qualified = load(primary['BASE'] / 'proofs.json')['proofs']
    result = []
    for mode in qualified:
        cases, excluded = [], []
        for row in mode['complete_source_API_primary_models']:
            if row['primary'] is None:
                continue
            index = row['index']
            if row['kind'] == 'capture' or ' has invalid resolved type: ' in row['primary']:
                excluded.append(index)
                continue
            require(row['kind'] in frame_model['ENTRY'], 'complete direct Value source family')
            arguments = intervention[index] if mode['mode'] != 'storable' and index in intervention else graph['thaw'](products['apis'][index]['whole_native']['before'])
            modeled = frame_model['derive'](source['cause_model'], row['kind'], arguments)
            require(modeled['primary'] == row['primary'], 'direct path joins independent primary cause')
            cases.append({'index': index, 'kind': row['kind'], **modeled})
        result.append({'mode': mode['mode'], 'cases': cases, 'metadata_successors': excluded})
    return result


TOKEN = re.compile(r'(?:HASH|ARRAY)\(0x[0-9a-fA-F]+\)|undef|-?[0-9]+|"(?:\\.|[^"\\])*"(?:\.\.\.)?|\.\.\.')


def arguments(call, function):
    require(call.startswith(function + '(') and call.endswith(')'), 'direct Value function header')
    text, offset, result = call[len(function) + 1:-1], 0, []
    while offset < len(text):
        token = TOKEN.match(text, offset)
        require(token is not None, 'finite direct Value argument footprint grammar')
        raw = token.group(); offset = token.end()
        if raw == '...':
            result.append({'kind': 'remaining_arguments'})
        elif re.fullmatch(r'(HASH|ARRAY)\(0x[0-9a-fA-F]+\)', raw):
            result.append({'kind': 'reference', 'reference_kind': raw.split('(')[0]})
        elif raw.startswith('"'):
            truncated = raw.endswith('...')
            result.append({'kind': 'scalar', 'value': json.loads(raw[:-3] if truncated else raw), 'truncated': truncated})
        else:
            result.append({'kind': 'scalar', 'value': None if raw == 'undef' else raw, 'truncated': False})
        if offset < len(text):
            require(text[offset:offset + 2] == ', ', 'direct Value argument separator')
            offset += 2
    return result


def check_footprint(actual, wanted):
    remaining = bool(actual and actual[-1]['kind'] == 'remaining_arguments')
    visible = actual[:-1] if remaining else actual
    require(len(visible) < len(wanted) if remaining else len(visible) == len(wanted),
            'direct Value visible argument membership')
    for got, want in zip(visible, wanted):
        if want['kind'] == 'false_predicate':
            require(got['kind'] == 'scalar' and got['value'] in ('', '0'), 'direct Value failed predicate footprint')
        elif want['kind'] == 'reference':
            require(got['kind'] == 'reference' and got['reference_kind'] == want['reference_kind'],
                    'direct Value reference argument footprint')
        else:
            require(got['kind'] == 'scalar', 'direct Value scalar argument footprint')
            value = None if want['value'] is None else str(want['value'])
            require((type(value) is str and value.startswith(got['value'])) if got['truncated'] else got['value'] == value,
                    'direct Value source scalar argument footprint')


def check(models, expected, inventories, source):
    check_source(source)
    require(same(models, expected), 'complete direct Value source path models')
    footprints = []
    for modeled, raw in zip(models, inventories, strict=True):
        require(modeled['mode'] == raw['mode'], 'direct Value mode identity')
        native = {row['index']: row for row in raw['domains']['api']['nonempty']}
        require(set(native) == {row['index'] for row in modeled['cases']} | set(modeled['metadata_successors']),
                'complete direct and deferred API refusal partition')
        rows = []
        for case in modeled['cases']:
            captured = native[case['index']]
            own = [row for row in captured['segments'] if row['kind'] == 'frame'
                   and row['call'].startswith(frame_model['PACKAGE'])]
            require([row['call'].split('(', 1)[0] for row in own] == [row['function'] for row in case['frames']],
                    'source-derived direct Value active frame order')
            visible = []
            for got, wanted in zip(own, case['frames'], strict=True):
                footprint = arguments(got['call'], wanted['function'])
                check_footprint(footprint, wanted['arguments'])
                visible.append(footprint)
            rows.append({'index': case['index'], 'raw_error': captured['body_identity'], 'visible_argument_footprints': visible})
        footprints.append({'mode': modeled['mode'], 'cases': rows})
    return footprints


def main():
    authenticate()
    source = source_contracts()
    expected = expected_models(source)
    inventories = load(classes['RAW'] / 'proofs.json')['inventories']
    observed = check(expected, expected, inventories, source)
    controls = []
    mutations = [
        ('wrong-source-guard', lambda m, n, s: s.update(value=s['value'].replace(frame_model['GUARDS']['values.16'], '_require(1, "wrong role");')), 'exact direct Value guard statement'),
        ('wrong-source-call', lambda m, n, s: s.update(value=s['value'].replace(frame_model['CALLS']['closed_recursion'], '_closed_type($spec, $context);')), 'exact direct Value call statement'),
        ('changed-intended-role', lambda m, n, s: m[0]['cases'][0]['frames'][1]['arguments'][1].update(role='target'), 'complete direct Value source path models'),
        ('omitted-source-case', lambda m, n, s: m[0]['cases'].pop(), 'complete direct Value source path models'),
        ('wrong-active-frame', lambda m, n, s: n[0]['domains']['api']['nonempty'][0]['segments'][2].update(call=n[0]['domains']['api']['nonempty'][0]['segments'][2]['call'].replace('::_require(', '::_keys(')), 'source-derived direct Value active frame order'),
        ('reordered-active-frames', lambda m, n, s: n[0]['domains']['api']['nonempty'][0]['segments'].__setitem__(slice(2, 4), list(reversed(n[0]['domains']['api']['nonempty'][0]['segments'][2:4]))), 'source-derived direct Value active frame order'),
        ('wrong-context-argument', lambda m, n, s: n[0]['domains']['api']['nonempty'][0]['segments'][3].update(call=n[0]['domains']['api']['nonempty'][0]['segments'][3]['call'].replace('"forged write"', '"borrowed context"')), 'direct Value source scalar argument footprint'),
        ('wrong-reference-kind', lambda m, n, s: n[0]['domains']['api']['nonempty'][0]['segments'][3].update(call=n[0]['domains']['api']['nonempty'][0]['segments'][3]['call'].replace('HASH(', 'ARRAY(', 1)), 'direct Value reference argument footprint'),
    ]
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(value) for value in (expected, inventories, source)]
        mutate(*changed)
        try:
            check(changed[0], expected, changed[1], changed[2])
        except ValueError as error:
            require(str(error) == cause, 'intended direct Value control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green direct Value frame control: ' + name)
    proof = {'models': expected, 'footprints': observed, 'controls': controls,
             'scope': 'Direct source path and visible type/scalar footprints; exact display, coordinates and live reference identity remain open.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved direct Value path proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed direct Value producer cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS direct finite Value source paths and visible argument footprints; metadata/inherited/display/coordinate/address meanings remain open.')


if __name__ == '__main__':
    main()
