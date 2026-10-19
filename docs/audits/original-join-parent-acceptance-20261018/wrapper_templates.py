"""Qualify fixed source wrapper templates without evaluating historical code.

AST extraction is checked against a separate, closed token grammar. This proves
source structure and lexical declaration routing, not callable identity at run
time, argument types, input bytes, loader behavior, reachability or effects.
"""
import argparse
import ast
import copy
import gzip
import io
import json
import tokenize

import bounded_runtime_inventory as bounded
import default_dispatch as dispatch
import epoch_constraints as epoch
import execute
import operand_inventory as operands
import prepare
import qualify_caller_modules as caller

AUTHORITY = operands.AUTHORITY
INPUT = operands.INPUT
PATH = execute.AUDIT / 'wrapper-templates-qualified.json.gz'
OWNER = operands.OWNER + '.2.2.1'
PREMISES = ('wrapper_templates.py', *operands.PREMISES)
LIMITS = dict(argument_types_qualified=False, input_payloads_qualified=False,
              runtime_callable_identity_qualified=False, loader_semantics_qualified=False,
              default_reachability_qualified=False, effects_qualified=False,
              runtime_permission=False)
SCOPE = ('Fixed graph source-defined module wrapper templates and lexical declaration '
         'routes only. Whole original source and function spans retain. Independent '
         'token grammar checks AST structure; both share CPython source/literal grammar. '
         'Builtin identities, Path/API semantics, import hooks and file-loader choice, '
         'source/cache image, runtime namespace mutation and actual exports remain '
         'explicit unqualified premises. Typed caller/payload and complete fixed binding '
         'joins have separate owners. No original source, recipe, module or cohort runs. '
         'Every earlier failure, spent fixture and unused slot retains.')


def function(body, name='module'):
    tree = ast.parse(body)
    matches = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name == name]
    assert len(matches) == 1, 'one top-level source callable'
    node = matches[0]
    assert not node.decorator_list and not node.returns and not node.type_params
    args = node.args
    assert not (args.posonlyargs or args.kwonlyargs or args.vararg or args.kwarg or args.defaults)
    assert not any(arg.annotation for arg in args.args)
    return tree, node


def ast_contract(body):
    _, node = function(body)
    text = body.decode('utf-8')
    args = [arg.arg for arg in node.args.args]
    first = node.body[0]
    assert isinstance(first, ast.Assign) and len(first.targets) == 1
    if isinstance(first.value, ast.Dict):
        assert len(node.body) == 3
        namespace = first.targets[0].id
        fields = {ast.literal_eval(key): dispatch.source(value, text)
                  for key, value in zip(first.value.keys, first.value.values)}
        expression = node.body[1]
        assert isinstance(expression, ast.Expr) and isinstance(expression.value, ast.Call)
        execution = expression.value
        assert isinstance(execution.func, ast.Name) and execution.func.id == 'exec'
        assert len(execution.args) == 2 and not execution.keywords
        compilation = execution.args[0]
        assert isinstance(compilation, ast.Call) and compilation.func.id == 'compile'
        assert len(compilation.args) == 3 and not compilation.keywords
        assert isinstance(node.body[2], ast.Return)
        return dict(parameters=args, kind='exec dictionary namespace', namespace=namespace,
            fields={key: value['text'] for key, value in fields.items()},
            input=dispatch.source(compilation.args[0], text)['text'],
            logical_name=dispatch.source(compilation.args[1], text)['text'],
            mode=ast.literal_eval(compilation.args[2]),
            execution_namespace=dispatch.source(execution.args[1], text)['text'],
            returned=dispatch.source(node.body[2].value, text)['text'],
            return_kind='dictionary', loader_chain=['compile', 'exec'])
    assert len(node.body) == 4
    calls = [first.value, node.body[1].value, node.body[2].value]
    assert all(isinstance(call, ast.Call) and not call.keywords for call in calls)
    return dict(parameters=args, kind='importlib file module',
        specification=first.targets[0].id, module=node.body[1].targets[0].id,
        loader_chain=[ast.unparse(call.func) for call in calls],
        name_argument=ast.unparse(calls[0].args[0]), path_argument=ast.unparse(calls[0].args[1]),
        specification_argument=ast.unparse(calls[1].args[0]),
        execution_argument=ast.unparse(calls[2].args[0]),
        returned=ast.unparse(node.body[3].value), return_kind='module object')


def token_function(body):
    """Locate the whole top-level definition without using AST coordinates."""
    all_tokens = list(tokenize.tokenize(io.BytesIO(body).readline))
    starts = [i for i, token in enumerate(all_tokens)
              if token.type == tokenize.NAME and token.string == 'def' and token.start[1] == 0
              and all_tokens[i + 1].string == 'module']
    assert len(starts) == 1, 'independent top-level module definition'
    start = starts[0]
    ignored = {tokenize.ENCODING, tokenize.COMMENT, tokenize.NL, tokenize.NEWLINE,
               tokenize.INDENT, tokenize.DEDENT, tokenize.ENDMARKER}
    depth, entered, selected = 0, False, []
    for token in all_tokens[start:]:
        if token.type == tokenize.INDENT:
            depth += 1
            entered = True
        elif token.type == tokenize.DEDENT:
            depth -= 1
            if entered and depth == 0:
                break
        if token.type not in ignored:
            selected.append(token)
    assert entered and depth == 0
    first, last = selected[0], selected[-1]
    lines = body.decode('utf-8').splitlines(keepends=True)
    source = ''.join(lines[first.start[0] - 1:last.end[0]])
    source = source[first.start[1]:]
    last_length = len(lines[last.end[0] - 1])
    source = source[:len(source) - last_length + last.end[1]]
    return dict(line=first.start[0], column=first.start[1], end_line=last.end[0],
                end_column=last.end[1], text=source), selected


class Tokens:
    def __init__(self, tokens):
        self.tokens, self.index = tokens, 0

    def take(self, *words):
        for word in words:
            assert self.index < len(self.tokens), 'incomplete wrapper token grammar'
            actual = self.tokens[self.index].string
            assert actual == word, ('wrapper token grammar', self.index, actual, word)
            self.index += 1

    def literal(self):
        item = self.tokens[self.index]
        assert item.type == tokenize.STRING
        self.index += 1
        value = ast.literal_eval(item.string)
        assert type(value) is str
        return value, item.string


def token_contract(body):
    source, tokens = token_function(body)
    stream = Tokens(tokens)
    if tokens[3].string == 'path':
        stream.take('def', 'module', '(', 'path', ')', ':')
        namespace = tokens[stream.index].string
        assert namespace in ('ns', 'namespace')
        stream.take(namespace, '=', '{')
        key, _ = stream.literal()
        assert key == '__name__'
        stream.take(':')
        _, name_source = stream.literal()
        fields = {'__name__': name_source}
        if tokens[stream.index].string == ',':
            stream.take(',')
            key, _ = stream.literal()
            assert key == '__file__'
            stream.take(':', 'str', '(', 'path', ')')
            fields['__file__'] = 'str(path)'
        stream.take('}', 'exec', '(', 'compile', '(', 'path', '.', 'read_bytes', '(', ')',
                    ',', 'str', '(', 'path', ')', ',')
        mode, _ = stream.literal()
        assert mode == 'exec'
        stream.take(')', ',', namespace, ')', 'return', namespace)
        result = dict(parameters=['path'], kind='exec dictionary namespace', namespace=namespace,
            fields=fields, input='path.read_bytes()', logical_name='str(path)', mode=mode,
            execution_namespace=namespace, returned=namespace, return_kind='dictionary',
            loader_chain=['compile', 'exec'])
    else:
        stream.take('def', 'module', '(', 'name', ',', 'path', ')', ':', 'spec', '=',
                    'importlib', '.', 'util', '.', 'spec_from_file_location', '(', 'name', ',', 'path', ')',
                    'result', '=', 'importlib', '.', 'util', '.', 'module_from_spec', '(', 'spec', ')')
        if tokens[stream.index].string == ';':
            stream.take(';')
        stream.take('spec', '.', 'loader', '.', 'exec_module', '(', 'result', ')', 'return', 'result')
        result = dict(parameters=['name', 'path'], kind='importlib file module', specification='spec',
            module='result', loader_chain=['importlib.util.spec_from_file_location',
            'importlib.util.module_from_spec', 'spec.loader.exec_module'], name_argument='name',
            path_argument='path', specification_argument='spec', execution_argument='result',
            returned='result', return_kind='module object')
    assert stream.index == len(tokens), 'complete wrapper grammar; no ignored statement'
    return source, result


def declaration(graph, route):
    """Independently check local lexical declaration or explicit namespace borrowing.

    Dynamic mutation and initialization order remain runtime premises. There are
    no imported module-callable bindings in this fixed route population.
    """
    scope = route['namespace_caller'][0] if route['namespace_caller'] else route['caller']
    body = prepare.unblob(graph['sources'][scope]['body'])
    tree, fn = function(body)
    for node in tree.body:
        if isinstance(node, ast.ImportFrom):
            assert not any(item.name in ('*', 'module') or item.asname == 'module' for item in node.names)
        if isinstance(node, ast.Import):
            assert not any((item.asname or item.name) == 'module' for item in node.names)
    assert not any(isinstance(node, ast.Name) and isinstance(node.ctx, ast.Store)
                   and node.id == 'module' for node in ast.walk(tree)), 'no lexical module rebinding'
    binding = dict(declaration=[scope, fn.name])
    bounded.strict_equal(graph['exports'][scope]['module'], binding)
    caller_body = prepare.unblob(graph['sources'][route['caller']]['body'])
    caller_tree = ast.parse(caller_body)
    calls = [node for node in ast.walk(caller_tree) if isinstance(node, ast.Call)
             and isinstance(node.func, ast.Name) and node.func.id == 'module'
             and node.lineno == route['source']['line'] and node.col_offset == route['source']['column']]
    assert len(calls) == 1, 'one bare module call, including nested calls at the same column'
    bounded.strict_equal(dispatch.source(calls[0], caller_body.decode()), route['source'])
    assert not calls[0].keywords and len(calls[0].args) == len(fn.args.args)
    evidence = dict(scope=scope, binding=binding, source=dispatch.source(fn, body.decode()))
    if route['namespace_caller']:
        contexts = [row for row in graph['namespace_calls']
                    if [row['caller'], row['source']['line'], row['source']['column']] == route['namespace_caller']]
        assert len(contexts) == 1
        context = contexts[0]
        assert context['target'] == route['caller'] and context['function'] == route['owner']
        _, owner = function(caller_body, route['owner'])
        assignments = [node for node in owner.body if isinstance(node, ast.Assign)
                       and any(isinstance(part, ast.Name) and part.id == 'module'
                               for target in node.targets for part in ast.walk(target))]
        assert len(assignments) == 1
        assignment = assignments[0]
        assert len(assignment.targets) == 1 and isinstance(assignment.targets[0], ast.Tuple)
        assert isinstance(assignment.value, ast.GeneratorExp) and len(assignment.value.generators) == 1
        generator = assignment.value.generators[0]
        assert not generator.ifs and not generator.is_async and isinstance(generator.target, ast.Name)
        assert isinstance(assignment.value.elt, ast.Subscript)
        assert ast.unparse(assignment.value.elt) == context['parameter'] + '[' + generator.target.id + ']'
        keys = ast.literal_eval(generator.iter)
        assert [part.id for part in assignment.targets[0].elts].index('module') == keys.index('module')
        assert context['module_binding'] == ['declared', scope, 'module']
        assert context['namespace_source'] == scope
        assert context['source']['text'].endswith('(globals())')
        evidence.update(namespace_context=context, borrowed=dispatch.source(assignment, caller_body.decode()),
                        borrowing_function=dispatch.source(owner, caller_body.decode()))
    else:
        # The reviewed callers do not declare module as a local parameter.
        for node in ast.walk(caller_tree):
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda)):
                assert not any(arg.arg == 'module' for arg in (*node.args.posonlyargs,
                               *node.args.args, *node.args.kwonlyargs)), 'unqualified local module parameter'
    return evidence


def derive(graph):
    templates, routes = {}, []
    for route in graph['wrappers']:
        binding = declaration(graph, route)
        origin = binding['scope']
        if origin not in templates:
            body = prepare.unblob(graph['sources'][origin]['body'])
            _, node = function(body)
            source = dispatch.source(node, body.decode())
            templates[origin] = dict(source=source, function_bytes=prepare.blob(source['text'].encode()),
                                     contract=ast_contract(body))
        routes.append(dict(route=route, declaration=binding, template=origin,
                           binding_owner=OWNER.rsplit('.', 1)[0] + '.2', payload_qualified=False))
    names = set(templates) | {row['route']['caller'] for row in routes}
    return dict(schema='fsmgen.wrapper_source_templates.v1', revision=epoch.REVISION, owner=OWNER,
        sources={name: graph['sources'][name] for name in sorted(names)}, templates=templates, routes=routes,
        premises=dict(source='Git epoch bytes, not an observed runtime filesystem/cache image',
            builtins='exec/compile/str and globals/namespace initialization semantics unqualified',
            path='Path argument types, read_bytes dispatch and actual file bytes unqualified',
            loader='Public importlib functions, import hooks, selected loader and bytecode/cache behavior unqualified',
            exports='dictionary/module return syntax; dynamic target exports and __file__ API behavior unqualified'),
        fixed_graph=dict(revision=AUTHORITY, path=str(INPUT)), scope=SCOPE, **LIMITS)


def review(value, graph, originals):
    assert value['schema'] == 'fsmgen.wrapper_source_templates.v1' and value['owner'] == OWNER
    assert value['revision'] == epoch.REVISION and value['scope'] == SCOPE
    bounded.strict_equal({key: value[key] for key in LIMITS}, LIMITS)
    bounded.strict_equal(value['fixed_graph'], dict(revision=AUTHORITY, path=str(INPUT)))
    # Data premises and all unresolved roles are part of the accepted product.
    expected = derive(graph)
    bounded.strict_equal(value['premises'], expected['premises'])
    assert set(value['sources']) == set(expected['sources'])
    for name, row in value['sources'].items():
        bounded.strict_equal(row, graph['sources'][name])
        assert prepare.unblob(row['body']) == originals[name], 'independent whole fixed Git source'
    assert set(value['templates']) == set(expected['templates']), 'complete routed definition population'
    for name, template in value['templates'].items():
        source, contract = token_contract(prepare.unblob(value['sources'][name]['body']))
        bounded.strict_equal(template['source'], source)
        assert prepare.unblob(template['function_bytes']) == source['text'].encode()
        bounded.strict_equal(template['contract'], contract)
    bounded.strict_equal(value['routes'], expected['routes'])
    for row in value['routes']:
        route, template = row['route'], value['templates'][row['template']]['contract']
        assert route['loader'] == template['kind']
        if template['kind'] == 'exec dictionary namespace':
            assert route['module_name'] == ast.literal_eval(template['fields']['__name__'])
            assert route['file_field'] is ('__file__' in template['fields'])
        else:
            assert route['file_field'] is True  # declared graph contract, not API verification
    return dict(structure='independent complete token grammar and byte spans versus AST extraction',
                routing='source-defined local callable or explicit globals parameter borrowing',
                membership='all fixed graph wrapper routes and all their definitions; complete payload binding open',
                shared='CPython lexical/literal grammar, fixed graph membership and namespace call contracts',
                runtime_permission=False)


def controls(expected, graph, originals):
    outcomes = []
    direct = next(name for name, row in expected['templates'].items()
                  if row['contract']['kind'] == 'exec dictionary namespace')
    loader = next(name for name, row in expected['templates'].items()
                  if row['contract']['kind'] == 'importlib file module')
    for label in ('source', 'function_bytes', 'input', 'logical_name', 'namespace', 'return',
                  'loader', 'loader_argument', 'omitted_template', 'omitted_route',
                  'wrong_callable', 'changed_premise', 'typed_permission', 'runtime_permission'):
        bad = copy.deepcopy(expected)
        template = bad['templates'][direct]
        if label == 'source': bad['sources'][direct]['body'] = prepare.blob(b'def module(path):\n    return path\n')
        elif label == 'function_bytes': template['function_bytes'] = prepare.blob(b'def module(path): pass')
        elif label == 'input': template['contract']['input'] = 'str(path)'
        elif label == 'logical_name': template['contract']['logical_name'] = 'path.read_bytes()'
        elif label == 'namespace': template['contract']['execution_namespace'] = 'globals()'
        elif label == 'return': template['contract']['return_kind'] = 'module object'
        elif label == 'loader': bad['templates'][loader]['contract']['loader_chain'][-1] = 'exec'
        elif label == 'loader_argument': bad['templates'][loader]['contract']['path_argument'] = 'name'
        elif label == 'omitted_template': del bad['templates'][loader]
        elif label == 'omitted_route': bad['routes'].pop()
        elif label == 'wrong_callable': bad['routes'][0]['template'] = loader
        elif label == 'changed_premise': bad['premises']['source'] = 'runtime filesystem qualified'
        elif label == 'typed_permission': bad['runtime_permission'] = 0
        else: bad['runtime_permission'] = True
        changes = caller.changes(expected, bad)
        assert changes
        try:
            review(bad, graph, originals)
        except AssertionError as error:
            outcomes.append(dict(label=label, changes=changes, candidate_identity=bounded.identity(bad),
                refusal=str(error), kind='caught source/template review assertion; no historical native result'))
        else:
            raise AssertionError('changed wrapper template admitted: ' + label)
    for outcome in outcomes:
        bad = copy.deepcopy(expected)
        for change in outcome['changes']:
            parent = bad
            for key in change['path'][:-1]: parent = parent[key]
            key = change['path'][-1]
            bounded.strict_equal(parent[key], change['before'])
            if change.get('remove') is True: del parent[key]
            else: parent[key] = change['after']
        bounded.strict_equal(bounded.identity(bad), outcome['candidate_identity'])
        try:
            review(bad, graph, originals)
        except AssertionError as error:
            assert str(error) == outcome['refusal']
        else:
            raise AssertionError('retained template candidate admitted')
    return outcomes


def source_controls(expected):
    """Actually change source operands, then run the independent grammar oracle.

    These are syntax-valid source candidates, not merely altered result fields.
    No candidate function is compiled or executed. Namespace literal changes
    remain grammatically valid but refuse the unchanged fixed contract.
    """
    direct = next(name for name, row in expected['templates'].items()
                  if row['contract']['kind'] == 'exec dictionary namespace')
    loader = next(name for name, row in expected['templates'].items()
                  if row['contract']['kind'] == 'importlib file module')
    namespace = expected['templates'][direct]['contract']['namespace']
    edits = (
        ('input', direct, 'path.read_bytes()', 'path.read_text()'),
        ('logical_name', direct, "str(path), 'exec'", "'other.py', 'exec'"),
        ('namespace', direct, ', ' + namespace + ')', ', globals())'),
        ('name_literal', direct, expected['templates'][direct]['contract']['fields']['__name__'], "'__main__'"),
        ('return', direct, 'return ' + namespace, 'return path'),
        ('loader', loader, 'spec.loader.exec_module', 'spec.loader.load_module'),
        ('loader_input', loader, 'spec_from_file_location(name, path)', 'spec_from_file_location(path, name)'),
        ('extra_statement', direct, 'return ' + namespace, 'probe = path\n    return ' + namespace),
    )
    outcomes = []
    for label, name, before, after in edits:
        body = prepare.unblob(expected['sources'][name]['body'])
        fn = expected['templates'][name]['source']['text']
        assert fn.count(before) == 1 and body.count(fn.encode()) == 1
        changed = body.replace(fn.encode(), fn.replace(before, after).encode(), 1)
        assert changed != body
        ast.parse(changed)  # syntax validation only; never compile/evaluate
        try:
            _, contract = token_contract(changed)
            bounded.strict_equal(contract, expected['templates'][name]['contract'])
        except AssertionError as error:
            outcome = dict(label=label, original=name, before=before, after=after,
                           candidate=prepare.blob(changed), refusal=str(error),
                           kind='independent token grammar/fixed-contract refusal; no historical native result')
        else:
            raise AssertionError('changed source template admitted: ' + label)
        # Replay the exact retained candidate and refusal, not a summary flag.
        retained = prepare.unblob(outcome['candidate'])
        assert retained == changed
        try:
            _, contract = token_contract(retained)
            bounded.strict_equal(contract, expected['templates'][name]['contract'])
        except AssertionError as error:
            assert str(error) == outcome['refusal']
        else:
            raise AssertionError('retained source candidate admitted')
        outcomes.append(outcome)
    return outcomes


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw = execute.read(INPUT)
    assert raw == epoch.read(AUTHORITY, str(INPUT)), 'whole committed fixed graph'
    graph = json.loads(gzip.decompress(raw))['graph']
    result = json.loads(prepare.encoded(derive(graph)))
    originals = epoch.batch(epoch.REVISION, result['sources'])
    product = dict(result=result, review=review(result, graph, originals),
        controls=controls(result, graph, originals), source_controls=source_controls(result),
        graph_identity=prepare.identity(raw),
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write:
        execute.save(PATH, product)
    else:
        bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Fixed wrapper source spans, independent token templates, lexical callable routes and saved refusals agree; typed payload, loader/cache semantics and runtime remain unqualified.')
