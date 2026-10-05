"""Finite metadata recursion driven by independently qualified type inputs."""
import ast
import functools

PACKAGE = 'FSM::Support::ISFInterfacePortMetadata::'
GUARDS = {
    'metadata_type.1': "_require(ref($spec) eq 'HASH', 'invalid resolved member type');",
    'metadata_type.2': "_require(!$active->{$address}, 'cyclic resolved type');",
    'metadata_type.3': "_require(_positive_integer($spec->{width}), 'invalid resolved type width');",
    'metadata_type.4': "_require($kind ne 'bit' || $spec->{width} == 1, 'bit type width must be one');",
    'metadata_type.5': "_require(!exists($spec->{signed}) || _binary($spec->{signed}), 'invalid resolved signed property');",
    'metadata_type.6': "_require(!exists($spec->{state_model}) || _state_model($spec->{state_model}), 'invalid resolved state model');",
    'metadata_type.7': "_require(ref($members) eq 'HASH' && ref($order) eq 'ARRAY' && scalar(@$order),\n            'record requires ordered members');",
    'metadata_type.8': "_require(keys(%$members) == @$order, 'record member inventory disagrees');",
    'metadata_type.9': "_require(_identifier($name) && !$seen{$name}++ && exists($members->{$name}),\n                'invalid or duplicate record member');",
    'metadata_type.10': "_require(length($path), 'list-root interface metadata remains unsupported');",
    'metadata_type.11': "_require(ref($items) eq 'ARRAY' && scalar(@$items), 'list requires ordered items');",
    'metadata_type.12': "_require($width == $spec->{width}, 'resolved aggregate width disagrees with members');",
    'metadata_type.unsupported': "_require(0, 'unsupported resolved type kind');",
}
CALLS = {
    'capture_paths': "_collect_scalar_paths($spec, '', \\@paths, {});",
    'member_paths': '_collect_scalar_paths($members->{$name}, "$path.$name", $paths, $active);',
    'list_paths': '_collect_scalar_paths($items->[$index], "$path\\[$index\\]", $paths, $active);',
}


def reference(role, kind):
    return {'role': role, 'kind': 'reference', 'reference_kind': kind}


def derive(source, kind, arguments):
    tree = ast.parse(source)
    for function in tree.body:
        if not isinstance(function, ast.FunctionDef):
            continue
        calls = sorted((node for node in ast.walk(function)
                        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                        and node.func.id == 'must'), key=lambda node: (node.lineno, node.col_offset))
        for index, node in enumerate(calls, 1):
            node.keywords.append(ast.keyword(arg='site', value=ast.Constant(function.name + '.' + str(index))))
        if function.name == 'metadata_type':
            # The qualified model's explicit unsupported-kind raise is the
            # own Perl producer's literal-false guard, not a different path.
            class Unsupported(ast.NodeTransformer):
                def visit_Raise(self, node):
                    if (isinstance(node.exc, ast.Call) and isinstance(node.exc.func, ast.Name)
                            and node.exc.func.id == 'Primary' and len(node.exc.args) == 1
                            and isinstance(node.exc.args[0], ast.Constant)
                            and node.exc.args[0].value == 'unsupported resolved type kind'):
                        return ast.copy_location(ast.Expr(ast.Call(func=ast.Name(id='must', ctx=ast.Load()),
                            args=[ast.Constant(False), node.exc.args[0]],
                            keywords=[ast.keyword(arg='site', value=ast.Constant('metadata_type.unsupported'))])), node)
                    raise ValueError('unexpected finite metadata raise')
            Unsupported().visit(function)
    namespace = {'__name__': 'metadata_source_model'}
    exec(compile(ast.fix_missing_locations(tree), '<qualified-cause-model>', 'exec'), namespace)
    stack, failures = [], []

    def predicate(condition, message, site):
        if condition:
            return
        if site not in GUARDS or not stack:
            raise ValueError('failure outside finite metadata source domain: ' + site)
        frames = [{'function': PACKAGE + '_require', 'call_site': site,
                   'arguments': [{'role': 'failed_predicate', 'kind': 'false_predicate'},
                                 {'role': 'diagnostic_message', 'kind': 'scalar', 'value': message}]}]
        for frame in reversed(stack):
            frames.append({'function': PACKAGE + '_collect_scalar_paths', 'call_site': frame['call_site'],
                           'arguments': [reference('resolved_type_at:' + frame['path'], 'HASH'),
                                         {'role': 'member_path', 'kind': 'scalar', 'value': frame['path']},
                                         reference('scalar_path_sink', 'ARRAY'), reference('active_type_path', 'HASH')]})
        frames.append({'function': PACKAGE + 'capture_interface_port_metadata', 'call_site': 'observer_operation',
                       'arguments': [reference('declared_interface', 'HASH')]})
        failures.append({'guard': site, 'metadata_primary': 'Invalid ISF interface port metadata: ' + message,
                         'frames': frames})
        raise namespace['Primary'](message)

    namespace['must'] = predicate
    operation = namespace['metadata_type']

    @functools.wraps(operation)
    def traverse(spec, path='', active=None):
        if type(spec) is not dict:
            raise ValueError('outside finite qualified metadata type profile')
        call_site = 'capture_paths' if not stack else 'member_paths' if stack[-1]['kind'] == 'record' else 'list_paths'
        stack.append({'kind': spec.get('kind'), 'path': path, 'call_site': call_site})
        try:
            return operation(spec, path, active)
        finally:
            stack.pop()

    namespace['metadata_type'] = traverse
    primary = namespace['primary'](kind, arguments)
    if len(failures) != 1:
        raise ValueError('finite metadata failure event population')
    return {'primary': primary, **failures[0]}
