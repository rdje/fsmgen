"""Metadata frame projection; inherited API and full trace meaning stay open."""
import copy
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-metadata-frames-20261005')
VALUE = Path('docs/audits/record-value-original-value-frames-20261005')
REVISION = 'd7358d27c3fd89f8debcc378ede785d7c8946276'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.2.1'
SOURCE = 'perl/FSM/Support/ISFInterfacePortMetadata.pm'


def module(path):
    namespace = {'__name__': 'metadata_frame_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


value = module(VALUE / 'verify.py')
primary = value['primary']
require, load, same, sealed = (value[key] for key in ('require', 'load', 'same', 'sealed'))
frame_model = module(BASE / 'frame_model.py')


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact completed direct Value owner intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed metadata-frame intake task')
    start = task.index('- ID: `' + OWNER + '`'); end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end], 'whole done direct Value owner')
    require(set(binding['archives']) == set(load(VALUE / 'binding.json')['archives']) | {str(VALUE)},
            'complete metadata-frame prerequisite domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole metadata-frame prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
                    == (Path(path) / name).read_bytes(), 'whole committed metadata-frame prerequisite bytes')
    value['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def source_contracts():
    return {'metadata': load(primary['result_reader']['CAPTURE'] / 'binding.json')['sources'][SOURCE]['body'],
            'cause_model': (primary['BASE'] / 'cause_model.py').read_text()}


def check_source(source):
    declarations = list(re.finditer(r'^sub ([A-Za-z_]\w*)\s*\{', source['metadata'], re.MULTILINE))
    bodies = {match[1]: source['metadata'][match.start():declarations[index + 1].start() if index + 1 < len(declarations) else len(source['metadata'])]
              for index, match in enumerate(declarations)}
    for statement in frame_model['GUARDS'].values():
        require(source['metadata'].count(statement) == bodies['_collect_scalar_paths'].count(statement) == 1,
                'exact metadata source guard statement')
    for key, statement in frame_model['CALLS'].items():
        caller = 'capture_interface_port_metadata' if key == 'capture_paths' else '_collect_scalar_paths'
        require(source['metadata'].count(statement) == bodies[caller].count(statement) == 1,
                'exact metadata source recursion statement')
    require(source['cause_model'] == (primary['BASE'] / 'cause_model.py').read_text(), 'whole qualified metadata predicate model')


def expected_models(source):
    check_source(source)
    intervention, _, _ = primary['graph']['source_interventions']()
    _, _, _, products = primary['context']['source_models']()
    qualified = load(primary['BASE'] / 'proofs.json')['proofs']
    direct = load(VALUE / 'proofs.json')['models']
    result = []
    for mode, partition in zip(qualified, direct, strict=True):
        cases = []
        require(mode['mode'] == partition['mode'], 'metadata source mode identity')
        for index in partition['metadata_successors']:
            row = mode['complete_source_API_primary_models'][index]
            require(row['kind'] in ('scope', 'capture') and row['primary'] is not None, 'finite metadata input source family')
            arguments = intervention[index] if mode['mode'] != 'storable' and index in intervention else primary['graph']['thaw'](products['apis'][index]['whole_native']['before'])
            modeled = frame_model['derive'](source['cause_model'], row['kind'], arguments)
            require(modeled['primary'] == row['primary'], 'metadata path joins independent full primary cause')
            cases.append({'index': index, 'kind': row['kind'], **modeled})
        result.append({'mode': mode['mode'], 'cases': cases})
    return result


def check(models, expected, inventories, source):
    check_source(source)
    require(same(models, expected), 'complete metadata source path models')
    proof = []
    for modeled, raw in zip(models, inventories, strict=True):
        require(modeled['mode'] == raw['mode'], 'metadata capture mode identity')
        native = {row['index']: row for row in raw['domains']['api']['nonempty']}
        rows = []
        for case in modeled['cases']:
            captured = native[case['index']]
            own = [row for row in captured['segments'] if row['kind'] == 'frame'
                   and row['call'].startswith(frame_model['PACKAGE'])]
            require([row['call'].split('(', 1)[0] for row in own] == [row['function'] for row in case['frames']],
                    'source-derived metadata active frame order')
            visible = []
            for got, wanted in zip(own, case['frames'], strict=True):
                footprint = value['arguments'](got['call'], wanted['function'])
                value['check_footprint'](footprint, wanted['arguments'])
                visible.append(footprint)
            rows.append({'index': case['index'], 'raw_error': captured['body_identity'], 'visible_argument_footprints': visible})
        proof.append({'mode': modeled['mode'], 'cases': rows})
    return proof


def metadata_frames(native, index):
    return [row for row in native[0]['domains']['api']['nonempty'] if row['index'] == index][0]['segments']


def mutate_frame(native, index, ordinal, change):
    own = [row for row in metadata_frames(native, index) if row['kind'] == 'frame'
           and row['call'].startswith(frame_model['PACKAGE'])]
    change(own[ordinal])


def main():
    authenticate()
    source = source_contracts()
    expected = expected_models(source)
    inventories = load(value['classes']['RAW'] / 'proofs.json')['inventories']
    observed = check(expected, expected, inventories, source)
    controls = []
    mutations = [
        ('wrong-metadata-guard', lambda m, n, s: s.update(metadata=s['metadata'].replace(frame_model['GUARDS']['metadata_type.2'], '_require(1, "ignored cycle");')), 'exact metadata source guard statement'),
        ('wrong-member-recursion', lambda m, n, s: s.update(metadata=s['metadata'].replace(frame_model['CALLS']['member_paths'], '_collect_scalar_paths($spec, "", $paths, $active);')), 'exact metadata source recursion statement'),
        ('changed-intended-path-role', lambda m, n, s: m[0]['cases'][0]['frames'][1]['arguments'][0].update(role='unrelated_type'), 'complete metadata source path models'),
        ('omitted-metadata-case', lambda m, n, s: m[0]['cases'].pop(), 'complete metadata source path models'),
        ('wrong-active-metadata-function', lambda m, n, s: mutate_frame(n, 7750, 1, lambda row: row.update(call=row['call'].replace('::_collect_scalar_paths(', '::_field_metadata('))), 'source-derived metadata active frame order'),
        ('omitted-recursive-frame', lambda m, n, s: metadata_frames(n, 7840).__setitem__(slice(None), [row for row in metadata_frames(n, 7840) if not (row['kind'] == 'frame' and row['call'].startswith(frame_model['PACKAGE'] + '_collect_scalar_paths') and '".data"' in row['call'])]), 'source-derived metadata active frame order'),
        ('wrong-recursive-path', lambda m, n, s: mutate_frame(n, 7840, 1, lambda row: row.update(call=row['call'].replace('".data"', '".borrowed"'))), 'direct Value source scalar argument footprint'),
        ('wrong-path-sink-kind', lambda m, n, s: mutate_frame(n, 7840, 1, lambda row: row.update(call=row['call'].replace('ARRAY(', 'HASH(', 1))), 'direct Value reference argument footprint'),
    ]
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(item) for item in (expected, inventories, source)]
        mutate(*changed)
        try:
            check(changed[0], expected, changed[1], changed[2])
        except ValueError as error:
            require(str(error) == cause, 'intended metadata path control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green metadata path control: ' + name)
    proof = {'models': expected, 'footprints': observed, 'controls': controls,
             'scope': 'Finite metadata frame projection and visible footprints; inherited API, actual reference identity and full display/trace meanings remain open.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved metadata source path proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed metadata producer cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS finite metadata guard/recursion paths and visible argument footprints; inherited API and full display/trace meanings remain open.')


if __name__ == '__main__':
    main()
