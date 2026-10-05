"""Finite original callback call shapes and named-helper source roles."""
import re

NAMED = ('scope_for', 'reference', 'copy')
FORMALS = {
    'scope_for': ['source_type', 'target_type', 'local'],
    'reference': ['scope', 'token', 'access', 'whole'],
    'copy': ['scope', 'source', 'target'],
}
OPERATIONS = {'scope_for': 'scope', 'reference': 'reference', 'copy': 'copy'}
DIRECT = {
    'validate_record_port_copy': 'copy',
    'record_value_scope': 'scope',
    'record_value_reference': 'reference',
    '$parser->parse_source': 'source',
}
CONTRACTS = {
    'scope_for': [
        'my ($source_type, $target_type, $local) = @_;',
        "return record_value_scope(outer => {\n        packet => {role => 'input', type_spec => $source_type},\n        held => {role => 'storage', type_spec => $target_type},\n        output => {role => 'output', type_spec => $target_type},\n        scalar => {role => 'output', type_spec => $scalar},\n    }, local => $local || {});",
    ],
    'reference': [
        'my ($scope, $token, $access, $whole) = @_;',
        "return record_value_reference(scope => $scope, token => $token,\n        access => $access || 'read', allow_whole => $whole || 0, context => 'control');",
    ],
    'copy': [
        'my ($scope, $source, $target) = @_;',
        "return validate_record_port_copy(source => reference($scope, $source, 'read', 1),\n        target => reference($scope, $target, 'write', 1), context => 'copy control');",
    ],
}


def calls(helper, require):
    statement = helper['source_statement']
    require(statement.startswith('refuses(sub {'), 'complete own helper callback source opening')
    body = statement[len('refuses(sub {'):statement.rindex('}')].strip()
    named = [{'function': match[1], 'tokens': [token.strip() for token in match[2].split(',')]}
             for match in re.finditer(r'(?<![\w:])(scope_for|reference|copy)\(([^()]*)\)', body)]
    top = re.fullmatch(r'(scope_for|reference|copy)\(([^()]*)\)', body)
    if top:
        require(len(named) == 1, 'single complete named callback operation')
        active = named[0]
        operation = OPERATIONS[active['function']]
        completed = []
    else:
        functions = [function for function in DIRECT if body.startswith(function + '(')]
        require(len(functions) == 1, 'complete finite direct callback operation')
        operation = DIRECT[functions[0]]
        require(not named or (functions[0] == 'validate_record_port_copy'
                              and len(named) == 1 and named[0]['function'] == 'reference'), 'finite completed helper argument evaluation')
        active, completed = None, named
    return {'body': body, 'outer_operation': operation, 'active': active, 'completed': completed}


def literal(token, require):
    if re.fullmatch(r"'[^'\\]*'", token):
        return token[1:-1]
    require(re.fullmatch(r'[0-9]+', token) is not None, 'finite source literal helper argument')
    return int(token)
