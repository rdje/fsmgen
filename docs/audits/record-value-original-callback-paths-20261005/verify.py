"""Compiled original callback/refusal roles and finite visible footprints."""
import copy
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-callback-paths-20261005')
PRIOR = Path('docs/audits/record-value-original-named-helpers-20261005')
SOURCES = Path('docs/audits/record-value-original-observer-sources-20261005')
REVISION = 'da0988b3af58ad34876728396b562064d075a62a'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.3.1'


def module(path):
    namespace = {'__name__': 'callback_path_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


prior = module(PRIOR / 'verify.py')
primary, direct = prior['primary'], prior['direct']
require, load, same, sealed = (prior[key] for key in ('require', 'load', 'same', 'sealed'))
frame_model = module(BASE / 'frame_model.py')


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact done named-helper intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed callback-path intake task')
    start = task.index('- ID: `' + OWNER + '`')
    end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end], 'whole completed named-helper owner')
    require(set(binding['archives']) == set(load(PRIOR / 'binding.json')['archives']) | {str(PRIOR)}, 'complete callback-path prerequisite domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole callback-path prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
                    == (Path(path) / name).read_bytes(), 'whole committed callback-path prerequisite bytes')
    require(binding['auxiliary_receipts'] == load(PRIOR / 'binding.json')['auxiliary_receipts'], 'whole inherited receipt-control authority')
    for path, body in binding['auxiliary_receipts'].items():
        require(subprocess.check_output(['git', 'show', REVISION + ':' + path]) == Path(path).read_bytes() == body.encode(), 'whole committed receipt-control bytes')
    prior['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def sources():
    return prior['sources']()


def check_sources(source):
    contracts = frame_model['CONTRACTS']
    helper = source['test'][source['test'].index('sub refuses {'):source['test'].index('sub diagnostic_line {')]
    require(helper.count(contracts['helper_parameters']) == helper.count(contracts['callback_eval']) == 1,
            'original helper parameters/parameterless callback eval source')
    observer = source['observer']
    for key in ('helper_lookup', 'helper_wrapper', 'wrapper_parameters', 'helper_delegate', 'callback_body_delegate'):
        require(observer.count(contracts[key]) == 1, 'original compiled helper lookup/wrapper/delegate source')
    require(observer.index(contracts['helper_lookup']) < observer.index(contracts['helper_wrapper'])
            < observer.index(contracts['helper_delegate']), 'original helper lookup precedes installed wrapper/delegate')
    prior['check_sources'](source)
    authority = load(SOURCES / 'proofs.json')['source_recipes']['source_units']
    require(all(source[name] == authority[name]['body'] for name in ('test', 'observer')), 'whole qualified callback/observer source authority')


def expected_models(source):
    check_sources(source)
    _, helpers, _, _ = primary['context']['source_models']()
    named_modes = prior['expected_models'](source)
    result = []
    for mode in named_modes:
        cases = []
        for case in mode['cases']:
            helper = helpers[case['helper']]
            cases.append({'domain': case['domain'], 'index': case['index'], 'helper': helper['index'],
                          'source_statement': helper['source_statement'], 'source_declaration': helper['source_declaration'],
                          'pattern': helper['pattern'], 'label': helper['label'],
                          'named_helper_frames': case['frames'], **frame_model['derive'](helper, case['phases'])})
        result.append({'mode': mode['mode'], 'cases': cases})
    return result


TOKEN = re.compile(r'qr\([^()]*\)|(?:HASH|ARRAY|CODE)\(0x[0-9a-fA-F]+\)|undef|-?[0-9]+|"(?:\\.|[^"\\])*"(?:\.\.\.)?|\.\.\.')


def arguments(call, function):
    require(call.startswith(function + '(') and call.endswith(')'), 'callback function header')
    body, offset, result = call[len(function) + 1:-1], 0, []
    while offset < len(body):
        match = TOKEN.match(body, offset)
        require(match is not None, 'finite callback argument display grammar')
        raw, offset = match.group(), match.end()
        if raw == '...':
            result.append({'kind': 'remaining_arguments'})
        elif raw.startswith('qr('):
            result.append({'kind': 'regex_display', 'body': raw[3:-1]})
        elif raw.endswith(')') and not raw.startswith('"'):
            result.append({'kind': 'reference', 'reference_kind': raw.split('(')[0]})
        elif raw.startswith('"'):
            truncated = raw.endswith('...')
            result.append({'kind': 'scalar', 'value': json.loads(raw[:-3] if truncated else raw), 'truncated': truncated})
        else:
            result.append({'kind': 'scalar', 'value': None if raw == 'undef' else raw, 'truncated': False})
        if offset < len(body):
            require(body[offset:offset + 2] == ', ', 'callback argument display separator')
            offset += 2
    return result


def check_footprint(actual, wanted):
    if not any(arg['kind'] == 'regex_source' for arg in wanted):
        direct['check_footprint'](actual, wanted)
        return
    # Exactly three arguments are visible in these finite refusal headers.
    # This does not establish a universal Carp argument or regex formatter.
    require(len(actual) == len(wanted) == 3, 'complete finite callback helper argument display')
    for got, want in zip(actual, wanted, strict=True):
        if want['kind'] == 'regex_source':
            require(got['kind'] == 'regex_display' and got['body'] == want['display_body'], 'callback source regex body display')
        else:
            direct['check_footprint']([got], [want])


def check(models, expected, inventories, source):
    check_sources(source)
    require(same(models, expected), 'complete source compiled callback/helper/pattern/label/phase models')
    proof = []
    for modeled, inventory in zip(models, inventories, strict=True):
        require(modeled['mode'] == inventory['mode'], 'callback native mode identity')
        observed = []
        for domain in ('api', 'parses'):
            native = {row['index']: row for row in inventory['domains'][domain]['nonempty']}
            cases = [case for case in modeled['cases'] if case['domain'] == domain]
            require(len(native) == len(inventory['domains'][domain]['nonempty'])
                    and set(native) == {case['index'] for case in cases}, 'complete callback native refusal population')
            for case in cases:
                row = native[case['index']]
                require(row['context']['helper'] == case['helper'], 'source callback helper allocation')
                frames = [frame for frame in row['segments'] if frame['kind'] == 'frame']
                positions = [i for i, frame in enumerate(frames) if frame['call'].startswith('main::refuses(')]
                require(len(positions) == len(case['paths']), 'complete source compiled callback throw-phase membership')
                visible = []
                for phase, (position, wanted) in enumerate(zip(positions, case['paths'], strict=True)):
                    require(position >= 2 and position + 1 < len(frames), 'complete adjacent compiled callback path')
                    actual = frames[position - 2:position + 2]
                    require([frame['call'].split('(', 1)[0] for frame in actual] == [frame['function'] for frame in wanted],
                            'source-derived callback/eval/original-helper/wrapper order')
                    if case['named_helper_frames']:
                        require(position >= 3 and frames[position - 3]['call'].split('(', 1)[0]
                                == case['named_helper_frames'][phase]['function'], 'named helper precedes compiled callback throw phase')
                    footprints = []
                    for got, want in zip(actual, wanted, strict=True):
                        if want['function'] == 'eval {...}':
                            require(got['call'] == 'eval {...}' and want['arguments'] == [], 'original helper callback eval footprint')
                            footprints.append([])
                        else:
                            parsed = arguments(got['call'], want['function'])
                            check_footprint(parsed, want['arguments'])
                            footprints.append(parsed)
                    visible.append(footprints)
                observed.append({'domain': domain, 'index': case['index'], 'body': row['body_identity'], 'visible_callback_path_footprints': visible})
        proof.append({'mode': modeled['mode'], 'cases': observed})
    return proof


def native_case(inventories, index):
    return next(row for row in inventories[0]['domains']['api']['nonempty'] if row['index'] == index)


def callback_frames(inventories, index):
    frames = [frame for frame in native_case(inventories, index)['segments'] if frame['kind'] == 'frame']
    position = next(i for i, frame in enumerate(frames) if frame['call'].startswith('main::refuses('))
    return frames[position - 2:position + 2]


def main():
    authenticate()
    source = sources()
    expected = expected_models(source)
    inventories = load(direct['classes']['RAW'] / 'proofs.json')['inventories']
    observed = check(expected, expected, inventories, source)
    index = next(case['index'] for case in expected[0]['cases'] if case['domain'] == 'api')
    controls = []
    mutations = [
        ('source-callback-borrowed-arguments', lambda m, n, s: s.update(test=s['test'].replace(frame_model['CONTRACTS']['callback_eval'], 'my $ok = eval { $run->(@_); 1 };')), 'original helper parameters/parameterless callback eval source'),
        ('wrong-source-helper-delegate', lambda m, n, s: s.update(observer=s['observer'].replace(frame_model['CONTRACTS']['helper_delegate'], 'my $returned = $operation->(@_);')), 'original compiled helper lookup/wrapper/delegate source'),
        ('borrowed-source-pattern', lambda m, n, s: m[0]['cases'][0].update(pattern='(?^:borrowed)'), 'complete source compiled callback/helper/pattern/label/phase models'),
        ('borrowed-source-label', lambda m, n, s: m[0]['cases'][0].update(label='borrowed helper'), 'complete source compiled callback/helper/pattern/label/phase models'),
        ('omitted-source-path', lambda m, n, s: m[0]['cases'][0]['paths'].pop(), 'complete source compiled callback/helper/pattern/label/phase models'),
        ('omitted-native-refusal', lambda m, n, s: n[0]['domains']['api']['nonempty'].pop(), 'complete callback native refusal population'),
        ('borrowed-native-helper', lambda m, n, s: native_case(n, index)['context'].update(helper=42), 'source callback helper allocation'),
        ('wrong-callback-frame', lambda m, n, s: callback_frames(n, index)[0].update(call='borrowed::callback()'), 'source-derived callback/eval/original-helper/wrapper order'),
        ('wrong-helper-eval-frame', lambda m, n, s: callback_frames(n, index)[1].update(call='borrowed::eval()'), 'source-derived callback/eval/original-helper/wrapper order'),
        ('wrong-helper-wrapper-frame', lambda m, n, s: callback_frames(n, index)[3].update(call='borrowed::wrapper()'), 'source-derived callback/eval/original-helper/wrapper order'),
        ('callback-invented-argument', lambda m, n, s: callback_frames(n, index)[0].update(call='main::__ANON__("borrowed")'), 'direct Value visible argument membership'),
        ('wrong-actual-pattern-body', lambda m, n, s: callback_frames(n, index)[2].update(call=callback_frames(n, index)[2]['call'].replace('qr(', 'qr(borrowed ', 1)), 'callback source regex body display'),
        ('wrong-actual-helper-label', lambda m, n, s: callback_frames(n, index)[2].update(call=callback_frames(n, index)[2]['call'].replace('"copy independently enforces target role"', '"borrowed helper"', 1)), 'direct Value source scalar argument footprint'),
        ('wrong-actual-operation-kind', lambda m, n, s: callback_frames(n, index)[2].update(call=callback_frames(n, index)[2]['call'].replace('CODE(', 'HASH(', 1)), 'direct Value reference argument footprint'),
    ]
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(item) for item in (expected, inventories, source)]
        mutate(*changed)
        try:
            check(changed[0], expected, changed[1], changed[2])
        except ValueError as error:
            require(str(error) == cause, 'intended compiled callback control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green compiled callback qualification: ' + name)
    proof = {'models': expected, 'footprints': observed, 'controls': controls,
             'scope': 'Complete finite compiled callback/eval/refuses/helper-wrapper source roles and visible code/regex-body/label displays; identity and full framework/format/trace remain open.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved callback-path proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed callback-path producer cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete finite compiled callback/refusal/helper-wrapper paths and visible source roles; full framework/display/native identity remains open.')


if __name__ == '__main__':
    main()
