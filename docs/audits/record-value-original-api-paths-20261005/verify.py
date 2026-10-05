"""Complete finite own API frame-path join; full observer/display stays open."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-api-paths-20261005')
INHERITED = Path('docs/audits/record-value-original-inherited-frames-20261005')
REVISION = '70ad725a35b96a09e92305970363fcd862bfdb85'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.2.3.3'


def module(path):
    namespace = {'__name__': 'api_path_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


inherited = module(INHERITED / 'verify.py')
direct, metadata, primary = (inherited[key] for key in ('direct', 'metadata', 'primary'))
require, load, same, sealed = (inherited[key] for key in ('require', 'load', 'same', 'sealed'))
receipt_reader = module(INHERITED / 'verify_receipt.py')
PACKAGES = (inherited['frame_model']['VALUE'], inherited['frame_model']['METADATA'])
RECEIPTS = {str(receipt_reader['CHECKS'] / name) for name in ('initial-reader.json', 'sealed-reader.json', 'receipt-reader.json')}


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact done inherited owner intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed API-path intake task')
    start = task.index('- ID: `' + OWNER + '`')
    end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end], 'whole completed inherited owner')
    require(set(binding['archives']) == set(load(INHERITED / 'binding.json')['archives']) | {str(INHERITED)},
            'complete API-path prerequisite domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole API-path prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
                    == (Path(path) / name).read_bytes(), 'whole committed API-path prerequisite bytes')
    require(set(binding['auxiliary_receipts']) == RECEIPTS, 'complete inherited receipt-control input domain')
    for path, body in binding['auxiliary_receipts'].items():
        require(subprocess.check_output(['git', 'show', REVISION + ':' + path]) == Path(path).read_bytes() == body.encode(),
                'whole committed inherited receipt-control input bytes')
    inherited['main']()
    receipt_reader['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def sources():
    return {'direct': direct['source_contracts'](), 'metadata': metadata['source_contracts'](),
            'inherited': inherited['nested']['sources']()}


def check_sources(source):
    direct['check_source'](source['direct'])
    metadata['check_source'](source['metadata'])
    inherited['check_sources'](source['inherited'])
    require(source['direct']['value'] == source['inherited']['value'], 'whole joined own Value source identity')


def own(frames):
    return [frame for frame in frames if frame['function'].startswith(PACKAGES)]


def expected_models(source):
    check_sources(source)
    value_models = direct['expected_models'](source['direct'])
    metadata_models = metadata['expected_models'](source['metadata'])
    inherited_models = inherited['expected_models'](source['inherited'])
    primary_models = load(primary['BASE'] / 'proofs.json')['proofs']
    result = []
    for value_mode, metadata_mode, inherited_mode, primary_mode in zip(
            value_models, metadata_models, inherited_models, primary_models, strict=True):
        mode = value_mode['mode']
        require(mode == metadata_mode['mode'] == inherited_mode['mode'] == primary_mode['mode'], 'joined API source mode identity')
        direct_cases = {case['index']: case for case in value_mode['cases']}
        metadata_cases = {case['index']: case for case in metadata_mode['cases']}
        nested_cases = {pair[key]: pair for pair in inherited_mode['pairs'] for key in ('scope_api', 'capture_api')}
        primary_cases = {case['index']: case for case in primary_mode['complete_source_API_primary_models'] if case['primary'] is not None}
        require(not set(direct_cases) & set(metadata_cases) and set(metadata_cases) == set(nested_cases)
                and set(primary_cases) == set(direct_cases) | set(metadata_cases)
                and set(value_mode['metadata_successors']) == set(metadata_cases), 'complete disjoint own API source-refusal partition')
        cases = []
        for index in sorted(primary_cases):
            first = primary_cases[index]
            if index in direct_cases:
                case = direct_cases[index]
                path, family, guards = case['frames'], 'direct_Value', [case['guard']]
                allocation = None
            else:
                case, pair = metadata_cases[index], nested_cases[index]
                path = case['frames'] + own(pair['inner_path'])
                family, guards = 'nested_Metadata', [case['guard']]
                if index == pair['scope_api']:
                    path += own(pair['new_outer_path'])
                    guards.append('Value.failed_capture_eval')
                allocation = {'scope_api': pair['scope_api'], 'capture_api': pair['capture_api'],
                              'source_argument_authority': pair['source_argument_authority']}
            require(first['kind'] == case['kind'] and first['primary'] == case['primary'], 'joined own path/independent primary identity')
            cases.append({'index': index, 'kind': case['kind'], 'primary': case['primary'], 'family': family,
                          'guards': guards, 'nested_allocation': allocation, 'frames': path})
        result.append({'mode': mode, 'source_refusal_members': sorted(primary_cases), 'cases': cases})
    return result


def check(models, expected, inventories, source):
    check_sources(source)
    require(same(models, expected), 'complete joined own API guard/path/role/member models')
    proof = []
    for modeled, inventory in zip(models, inventories, strict=True):
        require(modeled['mode'] == inventory['mode'], 'joined own API native mode identity')
        native = {row['index']: row for row in inventory['domains']['api']['nonempty']}
        require(set(native) == set(modeled['source_refusal_members'])
                and len(native) == len(inventory['domains']['api']['nonempty']), 'complete joined own API native refusal population')
        cases = []
        for case in modeled['cases']:
            row = native[case['index']]
            require(row['context']['kind'] == case['kind'], 'joined own API actual family allocation')
            actual = [segment for segment in row['segments'] if segment['kind'] == 'frame' and segment['call'].startswith(PACKAGES)]
            require([frame['call'].split('(', 1)[0] for frame in actual] == [frame['function'] for frame in case['frames']],
                    'complete source-derived own API frame order')
            footprints = []
            for got, wanted in zip(actual, case['frames'], strict=True):
                parsed = direct['arguments'](got['call'], wanted['function'])
                direct['check_footprint'](parsed, wanted['arguments'])
                footprints.append(parsed)
            cases.append({'index': case['index'], 'body': row['body_identity'], 'visible_argument_footprints': footprints})
        proof.append({'mode': modeled['mode'], 'cases': cases})
    return proof


def first_frames(inventories, index):
    row = next(row for row in inventories[0]['domains']['api']['nonempty'] if row['index'] == index)
    return [segment for segment in row['segments'] if segment['kind'] == 'frame' and segment['call'].startswith(PACKAGES)]


def main():
    authenticate()
    source = sources()
    expected = expected_models(source)
    inventories = load(direct['classes']['RAW'] / 'proofs.json')['inventories']
    observed = check(expected, expected, inventories, source)
    sample = next(case for case in expected[0]['cases'] if case['family'] == 'direct_Value')
    index, function = sample['index'], sample['frames'][0]['function']
    controls = []
    mutations = [
        ('wrong-own-source-guard', lambda m, n, s: s['direct'].update(value=s['direct']['value'].replace(direct['frame_model']['GUARDS']['values.16'], '_require(1, "ignored role");')), 'exact direct Value guard statement'),
        ('wrong-guard-model', lambda m, n, s: m[0]['cases'][0].update(guards=['borrowed_guard']), 'complete joined own API guard/path/role/member models'),
        ('changed-source-role', lambda m, n, s: m[0]['cases'][0]['frames'][0]['arguments'][1].update(role='borrowed_message'), 'complete joined own API guard/path/role/member models'),
        ('omitted-source-refusal', lambda m, n, s: m[0]['cases'].pop(), 'complete joined own API guard/path/role/member models'),
        ('borrowed-nested-allocation', lambda m, n, s: next(case for case in m[0]['cases'] if case['nested_allocation'] is not None)['nested_allocation'].update(scope_api=0), 'complete joined own API guard/path/role/member models'),
        ('omitted-native-refusal', lambda m, n, s: n[0]['domains']['api']['nonempty'].pop(), 'complete joined own API native refusal population'),
        ('wrong-native-family', lambda m, n, s: next(row for row in n[0]['domains']['api']['nonempty'] if row['index']==index)['context'].update(kind='borrowed-api'), 'joined own API actual family allocation'),
        ('wrong-native-function', lambda m, n, s: first_frames(n, index)[0].update(call=first_frames(n, index)[0]['call'].replace('::_require(', '::_keys(')), 'complete source-derived own API frame order'),
        ('reordered-native-frames', lambda m, n, s: (first_frames(n, index)[0].update(call=first_frames(inventories, index)[1]['call']), first_frames(n, index)[1].update(call=first_frames(inventories, index)[0]['call'])), 'complete source-derived own API frame order'),
        ('changed-actual-guard-operand', lambda m, n, s: first_frames(n, index)[0].update(call=function+'("", "borrowed guard")'), 'direct Value source scalar argument footprint'),
    ]
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(item) for item in (expected, inventories, source)]
        mutate(*changed)
        try:
            check(changed[0], expected, changed[1], changed[2])
        except ValueError as error:
            require(str(error) == cause, 'intended own API path-join control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green complete own API path join: ' + name)
    proof = {'models': expected, 'footprints': observed, 'controls': controls,
             'scope': 'Complete finite own API source-frame/guard/visible-role join; full observer/parser/framework/display/coordinates/live identity remain open.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved own API path-join proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed own API path join cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete finite own API refusal source-frame/guard/visible-role partition and join; full observer/parser/framework/display/coordinate/address meaning stays open.')


if __name__ == '__main__':
    main()
