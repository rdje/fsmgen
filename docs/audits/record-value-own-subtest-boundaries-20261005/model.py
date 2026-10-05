"""Finite own-source boundaries; external framework and identity stay opaque."""
import re

CONTRACTS = {
    'saved_delegate': "my $subtest = Test::More->can('subtest');",
    'wrapper_parameters': 'my ($name, $body, @args) = @_;',
    'compiled_helper_lookup': "my $helper = main->can('refuses');",
    'public_delegate': 'return $subtest->($name, sub {',
    'body_delegate': 'return $body->(@_);',
    'extra_arguments': '}, @args);',
    'load': "my $ok = do './t/1986-isf-record-port-value-gates.t';",
    'errors': '$test_error = $@; $test_errno = "$!";',
    'loaded': '$test_loaded = defined($ok) ? 1 : 0;',
}


def derive(source, source_recipes, helper_models, require):
    observer, test = source['observer'], source['test']
    for statement in CONTRACTS.values():
        require(observer.count(statement) == 1, 'exact own subtest/delegate/do/error source contract')
    wrapper = next(item['body'] for item in source_recipes['wrappers'] if item['name'] == 'Test::More::subtest')
    require(observer.count(wrapper) == 1, 'whole qualified own subtest wrapper')
    bodies = list(re.finditer(r"^subtest '([^']+)' => sub \{\n.*?^};", test, re.M | re.S))
    require([match[1] for match in bodies] == [item['name'] for item in source_recipes['subtests']],
            'complete authored subtest body membership/order')
    callbacks = {item['index']: item for item in source_recipes['callbacks']}
    result = []
    for mode in helper_models:
        cases = []
        for case in mode['cases']:
            callback = callbacks[case['helper']]
            body = next(match for match in bodies if match[1] == callback['subtest'])
            require(body[0].count(callback['source_statement']) == 1, 'whole source callback belongs to authored subtest body')
            role_arguments = [
                {'kind': 'scalar', 'role': 'authored_subtest_name', 'value': callback['subtest']},
                {'kind': 'reference', 'role': 'callback_role_not_measured_identity', 'reference_kind': 'CODE'},
            ]
            cases.append({'domain': case['domain'], 'index': case['index'], 'helper': case['helper'],
                          'phases': case['phases'], 'name': callback['subtest'], 'body': body[0],
                          'body_frames': [{'function': 'main::__ANON__', 'arguments': [], 'role': 'authored_body'},
                                          {'function': 'main::__ANON__', 'arguments': [], 'role': 'own_observer_callback'}],
                          'entry_frames': [{'function': 'Test::More::subtest', 'arguments': role_arguments,
                                            'role': 'saved_public_delegate'},
                                           {'function': 'main::__ANON__', 'arguments': role_arguments,
                                            'role': 'own_subtest_entry'}],
                          'load_marker': 'require ./t/1986-isf-record-port-value-gates.t',
                          'load_source_operator': 'do',
                          'external_interval': 'opaque; framework/frame/formatter/coordinate/identity owner remains separate'})
        result.append({'mode': mode['mode'], 'cases': cases})
    return {'contracts': CONTRACTS, 'wrapper': wrapper, 'bodies': [{'name': match[1], 'body': match[0]} for match in bodies],
            'modes': result}
