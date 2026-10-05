"""Own observer/callback source recipes; native frame meanings remain open."""
import copy
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-observer-sources-20261005')
API = Path('docs/audits/record-value-original-api-paths-20261005')
REVISION = 'e19f5893a581a03afdaf39b99d3254bc83a2fc25'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.2.4'


def module(path):
    namespace = {'__name__': 'observer_source_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


api = module(API / 'verify.py')
primary = api['primary']
require, load, same, sealed = (api[key] for key in ('require', 'load', 'same', 'sealed'))
recipes = module(BASE / 'recipes.py')


def authenticate():
    binding = load(BASE / 'binding.json')
    require(binding['revision'] == REVISION and binding['owner'] == OWNER, 'exact done API-path owner intake')
    task = subprocess.check_output(['git', 'show', REVISION + ':' + binding['task_path']], text=True)
    require(task == binding['task_body'], 'whole committed observer-source intake task')
    start = task.index('- ID: `' + OWNER + '`')
    end = task.index('\n- ID:', start + 1)
    require(task[start:end] == binding['owner_body'] and '\n  Status: `done`\n' in task[start:end], 'whole completed API-path owner')
    require(set(binding['archives']) == set(load(API / 'binding.json')['archives']) | {str(API)}, 'complete observer-source prerequisite domain')
    for path, manifest in binding['archives'].items():
        require(manifest == sealed(Path(path)), 'whole observer-source prerequisite identity')
        for name in (*manifest, 'manifest.json'):
            require(subprocess.check_output(['git', 'show', REVISION + ':' + str(Path(path) / name)])
                    == (Path(path) / name).read_bytes(), 'whole committed observer-source prerequisite bytes')
    require(binding['auxiliary_receipts'] == load(API / 'binding.json')['auxiliary_receipts'], 'whole inherited receipt-control authority')
    for path, body in binding['auxiliary_receipts'].items():
        require(subprocess.check_output(['git', 'show', REVISION + ':' + path]) == Path(path).read_bytes() == body.encode(), 'whole committed receipt-control bytes')
    api['main']()
    if (BASE / 'manifest.json').exists():
        sealed(BASE)


def functions(source, expected, observer=False):
    matches = list(re.finditer(r'^sub (\w+)\s*\{', source, re.MULTILINE))
    require([match[1] for match in matches] == list(expected), 'complete own named source-function inventory')
    result = []
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(source)
        # These are finite top-level source boundaries, not a general Perl
        # parser. The last observer function precedes the instrumentation block;
        # test functions precede the next authored subtest call.
        if observer and index + 1 == len(matches):
            end = source.index("\n{\n    no warnings 'redefine';", match.start())
        elif not observer:
            next_subtest = re.search(r'^subtest ', source[match.start():end], re.MULTILINE)
            if next_subtest:
                end = match.start() + next_subtest.start()
        body = source[match.start():end]
        parameters, role = expected[match[1]]
        if parameters is not None:
            require(body.count('my (' + parameters + ') = @_;') == 1, 'exact own source parameter-role declaration')
        else:
            require("(split /\\n/, $_[0] // '')[0] // ''" in body, 'exact first-line diagnostic helper source')
        result.append({'name': match[1], 'parameters': parameters, 'role': role, 'body': body,
                       'offset_bytes': len(source[:match.start()].encode()), 'source_body': api['primary']['result_reader']['identity'](body.encode())})
    return result


def model(source, helpers):
    observer, test = source['observer'], source['test']
    observer_functions = functions(observer, recipes['OBSERVER_FUNCTIONS'], True)
    test_functions = functions(test, recipes['TEST_FUNCTIONS'])
    wrappers = list(re.finditer(r'^    local \*([^=]+?)\s*=\s*sub([^\n{]*)\{\n.*?^    };', observer, re.MULTILINE | re.DOTALL))
    require([match[1].strip() for match in wrappers] == [name for name, _ in recipes['WRAPPERS']], 'complete own wrapper source membership/order')
    wrapped = [{'name': match[1].strip(), 'prototype': match[2].strip(), 'role': role, 'body': match[0],
                'offset_bytes': len(observer[:match.start()].encode())}
               for match, (_, role) in zip(wrappers, recipes['WRAPPERS'], strict=True)]
    helper_wrapper = re.findall(r'^            local \*main::refuses = sub \{\n.*?^            };', observer, re.MULTILINE | re.DOTALL)
    require(len(helper_wrapper) == 1, 'unique compiled original refusal wrapper')
    for key, statement in recipes['STATEMENTS'].items():
        body = test if key.startswith('helper_') and key not in ('helper_parameters', 'helper_active_scope') else observer
        require(body.count(statement) == 1, 'exact observer/callback/eval/consumer/do source contract')
    subtests = list(re.finditer(r"^subtest '([^']+)' => sub \{", test, re.MULTILINE))
    require([match[1] for match in subtests] == recipes['SUBTESTS'], 'complete authored subtest source membership/order')
    callback_sources = []
    for helper in helpers:
        statement = helper['source_statement']
        require(test.count(statement) == 1 and statement.startswith('refuses(sub {'), 'unique complete original helper callback statement')
        offset = test.index(statement)
        owner = [match for match in subtests if match.start() < offset][-1]
        callback_sources.append({'index': helper['index'], 'label': helper['label'], 'pattern': helper['pattern'],
                                 'source_statement': statement, 'source_declaration': helper['source_declaration'],
                                 'subtest': owner[1], 'api_members': helper['api_members'], 'parse_members': helper['parse_members'],
                                 'consumer_members': helper['consumer_members'], 'copy_members': helper['copy_members']})
    identity = primary['result_reader']['identity']
    return {'source_units': {name: {'body': body, 'identity': identity(body.encode())} for name, body in source.items()},
            'observer_functions': observer_functions, 'test_functions': test_functions, 'wrappers': wrapped,
            'compiled_helper_wrapper': helper_wrapper[0],
            'subtests': [{'name': match[1], 'source_marker': match[0], 'offset_bytes': len(test[:match.start()].encode())} for match in subtests],
            'callbacks': callback_sources,
            'test_execution': {key: recipes['STATEMENTS'][key] for key in ('original_test_do', 'test_error_capture')}}


def check(actual, expected, source, helpers):
    rebuilt = model(source, helpers)
    require(same(expected, rebuilt), 'whole independent observer-source recipe reconstruction')
    require(same(actual, expected), 'complete observer/callback source role/member/provenance recipes')


def main():
    authenticate()
    test, helpers, _, _ = primary['context']['source_models']()
    source = {'test': test, 'observer': api['inherited']['nested']['sources']()['observer']}
    expected = model(source, helpers)
    check(expected, expected, source, helpers)
    controls = []
    mutations = [
        ('changed-observer-parameters', lambda m, s, h: s.update(observer=s['observer'].replace('my ($kind, $operation, $caller, @args) = @_;', 'my ($kind, $borrowed, $caller, @args) = @_;', 1)), 'exact own source parameter-role declaration'),
        ('omitted-wrapper-source', lambda m, s, h: s.update(observer=s['observer'].replace(m['wrappers'][2]['body'], '')), 'complete own wrapper source membership/order'),
        ('changed-helper-eval', lambda m, s, h: s.update(test=s['test'].replace(recipes['STATEMENTS']['helper_eval'], 'my $ok = 1;')), 'exact observer/callback/eval/consumer/do source contract'),
        ('changed-subtest-title', lambda m, s, h: s.update(test=s['test'].replace(recipes['SUBTESTS'][2], 'borrowed title')), 'complete authored subtest source membership/order'),
        ('wrong-source-role', lambda m, s, h: m['wrappers'][2].update(role='snapshot API'), 'complete observer/callback source role/member/provenance recipes'),
        ('omitted-callback-member', lambda m, s, h: m['callbacks'].pop(), 'complete observer/callback source role/member/provenance recipes'),
        ('borrowed-helper-allocation', lambda m, s, h: m['callbacks'][0].update(api_members=m['callbacks'][1]['api_members']), 'complete observer/callback source role/member/provenance recipes'),
    ]
    for name, mutate, cause in mutations:
        changed = [copy.deepcopy(item) for item in (expected, source, helpers)]
        mutate(*changed)
        try:
            check(changed[0], expected, changed[1], changed[2])
        except ValueError as error:
            require(str(error) == cause, 'intended observer-source control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green own observer source recipe: ' + name)
    proof = {'source_recipes': expected, 'controls': controls,
             'scope': 'Complete finite own source recipe/role/provenance inventory; actual native frame/header/format/framework meanings remain open.'}
    path = BASE / 'proofs.json'
    if path.exists():
        require(same(load(path), proof), 'whole saved observer-source recipe proof')
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed observer source producer cannot publish')
        path.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete own observer/callback source recipes and rejecting controls; native frame/header/framework/display meanings remain open.')


if __name__ == '__main__':
    main()
