"""Join independently qualified original named and compiled helper paths."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-helper-join-20261005')
PRIOR = Path('docs/audits/record-value-original-callback-paths-20261005')
REVISION = 'de279ec5dbae65e8193fe700e4a217f17a968e90'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.3.2'


def module(path):
    namespace = {'__name__': 'helper_join_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


prior = module(PRIOR / 'verify.py')
named = prior['prior']
require, load, same, sealed = (prior[key] for key in ('require', 'load', 'same', 'sealed'))


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact done compiled-helper intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed helper-join intake task')
    start = task.index('- ID: `' + OWNER + '`')
    end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end],
            'whole completed compiled-helper owner')
    require(set(binding['archives']) == set(load(PRIOR / 'binding.json')['archives']) | {str(PRIOR)},
            'complete helper-join prerequisite domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole helper-join prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
                    == (Path(path) / name).read_bytes(), 'whole committed helper-join prerequisite bytes')
    require(binding['auxiliary_receipts'] == load(PRIOR / 'binding.json')['auxiliary_receipts'],
            'whole inherited receipt-control authority')
    for path, body in binding['auxiliary_receipts'].items():
        require(subprocess.check_output(['git', 'show', REVISION + ':' + path])
                == Path(path).read_bytes() == body.encode(), 'whole committed receipt-control bytes')
    prior['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def expected_models(source):
    """Construct the join from source models before looking at native frames."""
    named_modes = named['expected_models'](source)
    callback_modes = prior['expected_models'](source)
    result = []
    for inputs, callbacks in zip(named_modes, callback_modes, strict=True):
        require(inputs['mode'] == callbacks['mode'], 'source helper mode join')
        named_cases = {(case['domain'], case['index']): case for case in inputs['cases']}
        callback_cases = {(case['domain'], case['index']): case for case in callbacks['cases']}
        require(len(named_cases) == len(inputs['cases']) and len(callback_cases) == len(callbacks['cases'])
                and set(named_cases) == set(callback_cases), 'complete disjoint source helper refusal join')
        helpers = {helper['index']: helper for helper in inputs['helpers']}
        require(len(helpers) == len(inputs['helpers']), 'complete distinct source helper recipe join')
        cases = []
        for key, callback in callback_cases.items():
            active = named_cases[key]
            require(active['helper'] == callback['helper'] and active['phases'] == callback['phases']
                    and same(active['frames'], callback['named_helper_frames']),
                    'source helper allocation/phase/active-path agreement')
            helper = helpers[active['helper']]
            require(helper['label'] == callback['label']
                    and helper['source_statement'] == callback['source_statement']
                    and helper['source_declaration'] == callback['source_declaration']
                    and active['index'] in helper['api_members' if active['domain'] == 'api' else 'parse_members'],
                    'complete source helper statement/label/member agreement')
            require(len(active['frames']) in (0, active['phases'])
                    and len(callback['paths']) == active['phases'], 'complete source helper throw-phase join')
            paths = []
            for phase, path in enumerate(callback['paths']):
                paths.append((active['frames'][phase:phase + 1] if active['frames'] else []) + path)
            cases.append({'domain': key[0], 'index': key[1], 'helper': active['helper'],
                          'phases': active['phases'], 'pattern': callback['pattern'],
                          'label': callback['label'], 'paths': paths})
        result.append({'mode': inputs['mode'], 'helpers': inputs['helpers'], 'cases': cases})
    return result


def check(models, expected, inventories, source):
    prior['check_sources'](source)
    require(same(models, expected), 'whole source helper input/allocation/return/phase/path join')
    proof = []
    for modeled, inventory in zip(models, inventories, strict=True):
        require(modeled['mode'] == inventory['mode'], 'helper-join native mode identity')
        observed = []
        for domain in ('api', 'parses'):
            records = inventory['domains'][domain]['nonempty']
            native = {row['index']: row for row in records}
            cases = [case for case in modeled['cases'] if case['domain'] == domain]
            require(len(native) == len(records) and set(native) == {case['index'] for case in cases},
                    'complete native joint helper refusal population')
            for case in cases:
                row = native[case['index']]
                require(row['context']['helper'] == case['helper'], 'source joint helper allocation')
                frames = [frame for frame in row['segments'] if frame['kind'] == 'frame']
                anchors = [i for i, frame in enumerate(frames) if frame['call'].startswith('main::refuses(')]
                require(len(anchors) == case['phases'], 'complete native joint helper throw phases')
                phase_proofs = []
                for phase, (anchor, wanted) in enumerate(zip(anchors, case['paths'], strict=True)):
                    start = anchor - (len(wanted) - 2)
                    require(start >= 0 and anchor + 1 < len(frames), 'complete contiguous joint helper path')
                    actual = frames[start:anchor + 2]
                    require([frame['call'].split('(', 1)[0] for frame in actual]
                            == [frame['function'] for frame in wanted], 'source joint helper function order')
                    # Named helpers may have returned while building arguments. Only
                    # source-derived active helpers belong to this throw-phase path.
                    active_named = [frame for frame in frames if frame['call'].startswith(named['PACKAGES'])]
                    expected_named = [frame for path in case['paths'] for frame in path
                                      if frame['function'] + '(' in named['PACKAGES']]
                    require(len(active_named) == len(expected_named), 'complete active/returned named-helper frame population')
                    visible = []
                    for got, want in zip(actual, wanted, strict=True):
                        if want['function'] == 'eval {...}':
                            require(got['call'] == 'eval {...}' and want['arguments'] == [], 'joint helper eval footprint')
                            visible.append([])
                        else:
                            footprint = prior['arguments'](got['call'], want['function'])
                            prior['check_footprint'](footprint, want['arguments'])
                            visible.append(footprint)
                    phase_proofs.append({'phase': phase, 'frame_positions': list(range(start, anchor + 2)),
                                         'visible_source_roles': visible})
                observed.append({'domain': domain, 'index': case['index'], 'helper': case['helper'],
                                 'body': row['body_identity'], 'joint_paths': phase_proofs})
        proof.append({'mode': modeled['mode'], 'cases': observed})
    return proof


def main():
    authenticate()
    source = prior['sources']()
    expected = expected_models(source)
    inventories = load(prior['direct']['classes']['RAW'] / 'proofs.json')['inventories']
    observed = check(expected, expected, inventories, source)
    sample = next(case for case in expected[0]['cases'] if len(case['paths'][0]) == 5)
    index = sample['index']

    def raw_frames(native):
        return [frame for frame in prior['native_case'](native, index)['segments'] if frame['kind'] == 'frame']

    def joint_frame(native, offset):
        frames = raw_frames(native)
        anchor = next(i for i, frame in enumerate(frames) if frame['call'].startswith('main::refuses('))
        return frames[anchor + offset]

    def change_named_operand(native):
        frame = joint_frame(native, -3)
        frame['call'] = frame['call'].replace('HASH(', 'ARRAY(', 1)

    mutations = [
        ('borrowed-source-default', lambda m, n, s: s.update(test=s['test'].replace("access => $access || 'read'", "access => $access || 'write'")), 'exact named-helper formal/default/delegate source'),
        ('omitted-source-helper-recipe', lambda m, n, s: m[0]['helpers'].pop(), 'whole source helper input/allocation/return/phase/path join'),
        ('borrowed-source-allocation', lambda m, n, s: m[0]['cases'][0].update(helper=42), 'whole source helper input/allocation/return/phase/path join'),
        ('lost-source-default-role', lambda m, n, s: next(h for h in m[0]['helpers'] if h['defaults']).update(defaults={}), 'whole source helper input/allocation/return/phase/path join'),
        ('returned-operation-made-active', lambda m, n, s: next(o for h in m[0]['helpers'] for o in h['named_operations'] if o['phase']=='returned_before_outer_operation').update(phase='active'), 'whole source helper input/allocation/return/phase/path join'),
        ('omitted-nested-source-phase', lambda m, n, s: next(c for c in m[0]['cases'] if c['phases']==2)['paths'].pop(), 'whole source helper input/allocation/return/phase/path join'),
        ('omitted-native-refusal', lambda m, n, s: n[0]['domains']['api']['nonempty'].pop(), 'complete native joint helper refusal population'),
        ('borrowed-native-allocation', lambda m, n, s: prior['native_case'](n, index)['context'].update(helper=42), 'source joint helper allocation'),
        ('wrong-active-helper', lambda m, n, s: joint_frame(n, -3).update(call='borrowed::helper()'), 'source joint helper function order'),
        ('wrong-compiled-callback', lambda m, n, s: joint_frame(n, -2).update(call='borrowed::callback()'), 'source joint helper function order'),
        ('borrowed-named-operand', lambda m, n, s: change_named_operand(n), 'direct Value reference argument footprint'),
        ('borrowed-pattern-display', lambda m, n, s: joint_frame(n, 0).update(call=joint_frame(n, 0)['call'].replace('qr(', 'qr(borrowed ', 1)), 'callback source regex body display'),
        ('invented-returned-helper-frame', lambda m, n, s: prior['native_case'](n, index)['segments'].append(copy.deepcopy(joint_frame(n, -3))), 'complete active/returned named-helper frame population'),
    ]
    controls = []
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(item) for item in (expected, inventories, source)]
        mutate(*changed)
        try:
            check(changed[0], expected, changed[1], changed[2])
        except ValueError as error:
            require(str(error) == cause, 'intended complete helper-join control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green complete helper join: ' + name)
    proof = {'models': expected, 'footprints': observed, 'controls': controls,
             'scope': 'Complete finite source named-helper inputs/defaults/returned operations and compiled callback/refusal path join; full framework/display/coordinate/address meanings remain open.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved helper-join proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed helper-join producer cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete finite source helper allocation/input/default/return/throw-phase and callback/refusal path join; full framework/display/native identity remains open.')


if __name__ == '__main__':
    main()
