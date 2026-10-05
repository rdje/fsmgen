"""Qualify finite own subtest/load roles with opaque framework intervals."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-own-subtest-boundaries-20261005')
PRIOR = Path('docs/audits/record-value-original-helper-join-20261005')
SOURCES = Path('docs/audits/record-value-original-observer-sources-20261005')
REVISION = 'eaf93f672d437da104dc4e5ebac23713be9592a2'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.3.3'


def module(path):
    namespace = {'__name__': 'own_subtest_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


prior = module(PRIOR / 'verify.py')
callback = prior['prior']
require, load, same, sealed = (prior[key] for key in ('require', 'load', 'same', 'sealed'))
model = module(BASE / 'model.py')


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact completed helper-join intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed own-subtest intake task')
    start = task.index('- ID: `' + OWNER + '`')
    end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end], 'whole completed helper-join owner')
    require(set(binding['archives']) == set(load(PRIOR / 'binding.json')['archives']) | {str(PRIOR)}, 'complete own-subtest prerequisite domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole own-subtest prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)]) == (Path(path) / name).read_bytes(),
                    'whole committed own-subtest prerequisite bytes')
    require(binding['auxiliary_receipts'] == load(PRIOR / 'binding.json')['auxiliary_receipts'], 'whole inherited receipt authority')
    for path, body in binding['auxiliary_receipts'].items():
        require(subprocess.check_output(['git', 'show', REVISION + ':' + path]) == Path(path).read_bytes() == body.encode(),
                'whole committed own-subtest receipt bytes')
    prior['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def expected_models(source):
    callback['check_sources'](source)
    recipes = load(SOURCES / 'proofs.json')['source_recipes']
    require(all(source[name] == recipes['source_units'][name]['body'] for name in ('test', 'observer')), 'whole own source authority')
    return model['derive'](source, recipes, prior['expected_models'](source), require)


def check(models, expected, inventories, source):
    callback['check_sources'](source)
    require(same(models, expected), 'whole own subtest/body/delegate/load source model')
    proof = []
    for mode, inventory in zip(models['modes'], inventories, strict=True):
        require(mode['mode'] == inventory['mode'], 'own-subtest native mode identity')
        cases = []
        for domain in ('api', 'parses'):
            records = inventory['domains'][domain]['nonempty']
            require(all(type(row['index']) is int for row in records), 'own-subtest native record index kind')
            native = {row['index']: row for row in records}
            wanted = [case for case in mode['cases'] if case['domain'] == domain]
            require(len(native) == len(records) and set(native) == {case['index'] for case in wanted}, 'complete finite own-subtest refusal population')
            for case in wanted:
                row = native[case['index']]
                require(type(row['context']['helper']) is int, 'own source helper allocation kind')
                require(row['context']['helper'] == case['helper'], 'own source helper/subtest allocation')
                frames = [frame for frame in row['segments'] if frame['kind'] == 'frame']
                helpers = [index for index, frame in enumerate(frames) if frame['call'].startswith('main::refuses(')]
                loads = [index for index, frame in enumerate(frames) if frame['call'].startswith('require ')]
                require(len(helpers) == len(loads) == case['phases'], 'complete finite own-subtest throw/load phases')
                phases = []
                for phase, (helper, loaded) in enumerate(zip(helpers, loads, strict=True)):
                    body_start = helper + 2
                    entry_start = loaded - 2
                    require(body_start + 2 <= entry_start, 'own body/delegate/framework interval order')
                    require(frames[loaded]['call'] == case['load_marker'], 'own do-file diagnostic load identifier')
                    require(phase + 1 == len(helpers) or loaded < helpers[phase + 1], 'disjoint own throw/load phase ordering')
                    observed = []
                    for start, roles in ((body_start, case['body_frames']), (entry_start, case['entry_frames'])):
                        actual = frames[start:start + len(roles)]
                        require([frame['call'].split('(', 1)[0] for frame in actual] == [role['function'] for role in roles],
                                'finite own body/delegate/entry function roles')
                        for frame, role in zip(actual, roles, strict=True):
                            footprint = callback['arguments'](frame['call'], role['function'])
                            callback['check_footprint'](footprint, role['arguments'])
                            observed.append({'role': role['role'], 'visible_arguments': footprint})
                    opaque = frames[body_start + 2:entry_start]
                    phases.append({'phase': phase, 'body_positions': list(range(body_start, body_start + 2)),
                                   'entry_positions': list(range(entry_start, loaded)), 'load_position': loaded,
                                   'visible_roles': observed, 'opaque_framework_frames': opaque,
                                   'load_marker': frames[loaded]['call']})
                cases.append({'domain': domain, 'index': case['index'], 'helper': case['helper'], 'name': case['name'],
                              'body_identity': row['body_identity'], 'phases': phases})
        proof.append({'mode': mode['mode'], 'cases': cases})
    return proof


def main():
    authenticate()
    module(BASE / 'verify_public.py')['main']()
    module(BASE / 'verify_book.py')['main']()
    source = callback['sources']()
    expected = expected_models(source)
    inventories = load(callback['direct']['classes']['RAW'] / 'proofs.json')['inventories']
    observed = check(expected, expected, inventories, source)
    sample = expected['modes'][0]['cases'][0]

    def frame(native, offset):
        row = next(row for row in native[0]['domains']['api']['nonempty'] if row['index'] == sample['index'])
        frames = [item for item in row['segments'] if item['kind'] == 'frame']
        load_index = next(index for index, item in enumerate(frames) if item['call'].startswith('require '))
        return frames[load_index + offset]

    def body_frame(native):
        row = next(row for row in native[0]['domains']['api']['nonempty'] if row['index'] == sample['index'])
        frames = [item for item in row['segments'] if item['kind'] == 'frame']
        helper = next(index for index, item in enumerate(frames) if item['call'].startswith('main::refuses('))
        return frames[helper + 2]

    mutations = [
        ('wrong-own-body-delegate', lambda m, n, s: s.update(observer=s['observer'].replace('return $body->(@_);', 'return $body->(1, @_);')), 'original compiled helper lookup/wrapper/delegate source'),
        ('wrong-authored-subtest-name', lambda m, n, s: m['bodies'][0].update(name='borrowed'), 'whole own subtest/body/delegate/load source model'),
        ('missing-source-case', lambda m, n, s: m['modes'][0]['cases'].pop(), 'whole own subtest/body/delegate/load source model'),
        ('borrowed-source-subtest', lambda m, n, s: m['modes'][0]['cases'][0].update(name='borrowed'), 'whole own subtest/body/delegate/load source model'),
        ('wrong-native-load-file', lambda m, n, s: frame(n, 0).update(call='require ./borrowed-test.t'), 'own do-file diagnostic load identifier'),
        ('wrong-native-entry-function', lambda m, n, s: frame(n, -1).update(call='borrowed::entry()'), 'finite own body/delegate/entry function roles'),
        ('wrong-native-subtest-name', lambda m, n, s: frame(n, -1).update(call=frame(n, -1)['call'].replace(sample['name'], 'borrowed')), 'direct Value source scalar argument footprint'),
        ('wrong-native-callback-kind', lambda m, n, s: frame(n, -1).update(call=frame(n, -1)['call'].replace('CODE(', 'HASH(')), 'direct Value reference argument footprint'),
        ('wrong-native-body-argument', lambda m, n, s: body_frame(n).update(call='main::__ANON__("borrowed argument")'), 'direct Value visible argument membership'),
        ('wrong-native-public-delegate', lambda m, n, s: frame(n, -2).update(call='borrowed::delegate()'), 'finite own body/delegate/entry function roles'),
        ('Boolean-native-index', lambda m, n, s: n[0]['domains']['api']['nonempty'][0].update(index=False), 'own-subtest native record index kind'),
        ('Boolean-helper-allocation', lambda m, n, s: n[0]['domains']['api']['nonempty'][0]['context'].update(helper=False), 'own source helper allocation kind'),
        ('lost-native-refusal', lambda m, n, s: n[0]['domains']['api']['nonempty'].pop(), 'complete finite own-subtest refusal population'),
    ]
    controls = []
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(item) for item in (expected, inventories, source)]
        mutate(*changed)
        try:
            check(changed[0], expected, changed[1], changed[2])
        except ValueError as error:
            require(str(error) == cause, 'intended own-subtest control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green own-subtest boundary: ' + name)
    proof = {'models': expected, 'observed': observed, 'controls': controls,
             'scope': 'Finite own authored body/wrapper/public-delegate/load-source roles and recorded header agreement; external framework, full display, raw coordinates and actual callback/native identity remain unmeasured.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved own-subtest proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed own-subtest producer cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete finite own subtest/body/delegate/do-load roles and rejecting controls; framework/display/native identity remain open.')


if __name__ == '__main__':
    main()
