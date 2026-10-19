"""Bind source-derived Path/string wrapper arguments and fixed-epoch payloads.

The existing conservative source evaluator supplies namespace and loop binding.
This successor preserves Path kinds and source construction traces. A separate
public pathlib API oracle checks their native kinds and operator results. No
original module or producer executes; runtime source/cache observations remain
unqualified, including the actual input selected by an importlib loader.
"""
import argparse
import ast
import copy
import gzip
import json
from pathlib import Path
import posixpath

import bounded_runtime_inventory as bounded
import caller_modules
import default_dispatch as dispatch
import epoch_constraints as epoch
import execute
import fixed_modules
import operand_inventory as operands
import prepare
import qualify_caller_modules as caller
import wrapper_templates as templates

AUTHORITY = '504dd1f3f10939d854b122ffd60c5b884dcf68cd'
PATH = execute.AUDIT / 'typed-callers-qualified.json.gz'
OWNER = templates.OWNER.rsplit('.', 1)[0] + '.2'
PREMISES = ('typed_callers.py', *templates.PREMISES)
LIMITS = dict(runtime_source_image_qualified=False, runtime_callable_identity_qualified=False,
              loader_input_qualified=False, target_exports_qualified=False,
              default_reachability_qualified=False, effects_qualified=False, runtime_permission=False)
SHARED = ['existing conservative AST/value/import/namespace/finite-loop source grammar',
          'fixed graph membership and declaration/namespace contracts',
          'source namespace/export representation; runtime dictionary/module APIs unqualified',
          'public API oracle is this native interpreter; source builtin/import identities unqualified']
SCOPE = ('Source-derived Path/string caller arguments, namespace/finite-loop context '
         'and original Git-epoch source candidates for all fixed wrapper routes. '
         'Native public pathlib calls qualify constructor/join/parent/str values '
         'without reading any original path. AST/value/namespace/loop interpretation '
         'and fixed graph membership remain shared premises; the independent full '
         'binding join has a separate owner. Direct read_bytes payloads are conditional '
         'on the declared original source image. Importlib rows retain a file candidate, '
         'not qualified selected executable bytes. Runtime identity, source/cache image, '
         'loader/hooks/bytecode selection, actual exports, default effects and custody '
         'remain open. No original module, recipe or cohort runs. All earlier failures '
         'and unused slots retain.')


class SourcePath(str):
    """Pure source datum; never a filesystem-capable Path object."""
    def __new__(cls, text, trace):
        value = super().__new__(cls, posixpath.normpath(text))
        value.trace = trace
        return value


def datum(value, namespaces=None):
    namespaces = namespaces or {}
    if isinstance(value, SourcePath):
        return dict(kind='Path', value=str(value), trace=value.trace)
    if id(value) in namespaces:
        return dict(kind='source namespace', source=namespaces[id(value)])
    if isinstance(value, tuple) and value and value[0] == 'declared':
        return dict(kind='source declaration', origin=list(value[1:]))
    if type(value) is dict:
        return dict(kind='dictionary', fields={key: datum(item, namespaces) for key, item in value.items()})
    if isinstance(value, (list, tuple)):
        return dict(kind='sequence', items=[datum(item, namespaces) for item in value])
    assert type(value) in (str, int, bool, float, type(None)), 'closed typed source datum'
    return dict(kind=type(value).__name__, value=value)


class Graph(caller_modules.Graph):
    def __init__(self, contracts):
        super().__init__()
        self.contracts = contracts
        self.plan_bound = set()

    def location(self, node, caller):
        return dict(origin=caller, source=dispatch.source(node, self.bodies[caller].decode()))

    def module(self, name):
        env = super().module(name)
        # The sealed parent model's declaration hook accepts an untyped string
        # BASE. Retain that same fixed JSON input when BASE now carries a Path
        # kind; never substitute a source population seeded from the answer.
        base = env.get('BASE')
        if isinstance(base, SourcePath):
            plan = str(base) + '/plan.json'
            if plan in self.members and name not in self.plan_bound:
                self.plan_bound.add(name)
                env['PLAN'] = json.loads(self.read(plan))
                tree = ast.parse(self.bodies[name])
                self.assignments(tree.body, env, name)
                self.scan(name, tree, env)
        return env

    def value(self, node, env, caller):
        if isinstance(node, ast.BinOp) and isinstance(node.op, ast.Div):
            left = self.value(node.left, env, caller)
            right = self.value(node.right, env, caller)
            if not isinstance(left, SourcePath) or type(right) is not str:
                raise fixed_modules.Unknown('path division requires Path / str')
            return SourcePath(posixpath.join(str(left), right), dict(operation='join',
                left=left.trace, right=right, **self.location(node, caller)))
        if isinstance(node, ast.Attribute) and node.attr == 'parent':
            base = self.value(node.value, env, caller)
            if not isinstance(base, SourcePath):
                raise fixed_modules.Unknown('parent requires Path')
            return SourcePath(posixpath.dirname(base), dict(operation='parent',
                base=base.trace, **self.location(node, caller)))
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and not node.keywords:
            if node.func.id == 'Path' and len(node.args) == 1:
                # Every used fixed path root has a literal constructor. Other
                # forms remain unresolved instead of inventing provenance.
                if not isinstance(node.args[0], ast.Constant) or type(node.args[0].value) is not str:
                    raise fixed_modules.Unknown('Path root requires fixed string literal')
                text = node.args[0].value
                return SourcePath(text, dict(operation='Path', argument=text, **self.location(node, caller)))
            if node.func.id == 'str' and len(node.args) == 1:
                value = self.value(node.args[0], env, caller)
                if isinstance(value, SourcePath) or type(value) is str:
                    return str(value)
        return super().value(node, env, caller)

    def wrapper_call(self, call, env, caller):
        binding = env.get('module')
        if not (isinstance(binding, tuple) and binding[0] == 'declared'):
            raise fixed_modules.Unknown('typed module callable needs source declaration')
        _, origin, name = binding
        assert name == 'module' and origin in self.contracts
        contract = self.contracts[origin]['contract']
        assert not call.keywords and len(call.args) == len(contract['parameters'])
        arguments = {key: self.value(node, env, caller)
                     for key, node in zip(contract['parameters'], call.args)}
        path = arguments['path']
        if not isinstance(path, SourcePath):
            raise fixed_modules.Unknown('actual wrapper path argument is not a Path source datum')
        target = str(path)
        assert not posixpath.isabs(target) and '..' not in target.split('/')
        assert target in self.members, 'typed fixed source member'
        if contract['kind'] == 'exec dictionary namespace':
            module_name = ast.literal_eval(contract['fields']['__name__'])
            file_field = '__file__' in contract['fields']
        else:
            module_name, file_field = arguments['name'], True
            assert type(module_name) is str, 'file loader name string'
        return target, dict(module_name=module_name, file_field=file_field, loader=contract['kind'],
                            typed_arguments={key: datum(value) for key, value in arguments.items()})

    def exports(self):
        namespaces = {id(env): name for name, env in self.environments.items()}
        return {name: {key: datum(value, namespaces) for key, value in sorted(env.items())}
                for name, env in sorted(self.environments.items())}


def native_path(trace, originals):
    """Independent public API execution on path data; never open an original file."""
    body, source = originals[trace['origin']], trace['source']
    lines = body.splitlines(keepends=True)
    start = sum(map(len, lines[:source['line'] - 1])) + source['column']
    end = sum(map(len, lines[:source['end_line'] - 1])) + source['end_column']
    assert body[start:end].decode('utf-8') == source['text'], 'exact original construction bytes'
    node = ast.parse(source['text'], mode='eval').body
    if trace['operation'] == 'Path':
        assert isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == 'Path'
        assert len(node.args) == 1 and not node.keywords and isinstance(node.args[0], ast.Constant)
        assert type(node.args[0].value) is str and trace['argument'] == node.args[0].value
        result = Path(trace['argument'])
    elif trace['operation'] == 'join':
        assert isinstance(node, ast.BinOp) and isinstance(node.op, ast.Div)
        assert type(trace['right']) is str
        if isinstance(node.right, ast.Constant):
            assert node.right.value == trace['right']
        result = native_path(trace['left'], originals) / trace['right']
    else:
        assert trace['operation'] == 'parent' and isinstance(node, ast.Attribute) and node.attr == 'parent'
        result = native_path(trace['base'], originals).parent
    assert isinstance(result, Path)
    return result


def key(row):
    return (row['caller'], row['source']['line'], row['source']['column'],
            prepare.encoded(row['namespace_caller']), prepare.encoded(row['finite_path']))


def derive(graph, fixed, contracts):
    bounded.strict_equal(graph['sources'], fixed['sources'])
    bounded.strict_equal(graph['declarations'], fixed['declarations'])
    original = {key(row): row for row in fixed['wrappers']}
    typed = {key(row): row for row in graph['wrappers']}
    assert len(typed) == len(graph['wrappers']) and set(typed) == set(original), 'all fixed contextual wrapper routes'
    bindings = []
    for site, row in typed.items():
        projected = {name: value for name, value in row.items() if name != 'typed_arguments'}
        bounded.strict_equal(projected, original[site])
        origin = (row['namespace_caller'][0] if row['namespace_caller'] else row['caller'])
        definition = fixed['exports'][origin]['module']['declaration'][0]
        contract = contracts[definition]['contract']
        assert row['typed_arguments']['path']['kind'] == 'Path'
        candidate = row['target']
        body = graph['sources'][candidate]['body']
        bindings.append(dict(route=projected, definition=definition, arguments=row['typed_arguments'],
            return_kind=contract['return_kind'], logical_name=candidate if contract['kind'] == 'exec dictionary namespace' else None,
            namespace_name=row['module_name'], file_field_expression='str(path)' if '__file__' in contract.get('fields', {}) else None,
            input_expression=contract.get('input'), source_candidate=dict(path=candidate, body=body),
            payload_role='read_bytes input under fixed source-image premise' if contract['kind'] == 'exec dictionary namespace'
                         else 'file-loader source candidate; selected executable input unqualified',
            runtime_payload_qualified=False))
    return dict(schema='fsmgen.typed_wrapper_callers.v1', owner=OWNER, revision=epoch.REVISION,
        sources=graph['sources'], declarations=graph['declarations'], bindings=bindings, scope=SCOPE,
        shared_premises=SHARED,
        independent_join_owner=OWNER.rsplit('.', 1)[0] + '.5', **LIMITS)


def review(value, fixed, contracts, originals):
    assert value['schema'] == 'fsmgen.typed_wrapper_callers.v1' and value['owner'] == OWNER
    assert value['revision'] == epoch.REVISION and value['scope'] == SCOPE
    bounded.strict_equal({name: value[name] for name in LIMITS}, LIMITS)
    bounded.strict_equal(value['shared_premises'], SHARED)
    bounded.strict_equal(value['sources'], fixed['sources'])
    bounded.strict_equal(value['declarations'], fixed['declarations'])
    for name, row in value['sources'].items():
        assert prepare.unblob(row['body']) == originals[name]
    assert len(value['bindings']) == len(fixed['wrappers'])
    routes = {key(row): row for row in fixed['wrappers']}
    assert {key(row['route']) for row in value['bindings']} == set(routes)
    public = []
    for row in value['bindings']:
        route = routes[key(row['route'])]
        bounded.strict_equal(row['route'], route)
        origin = route['namespace_caller'][0] if route['namespace_caller'] else route['caller']
        assert row['definition'] == fixed['exports'][origin]['module']['declaration'][0]
        contract = contracts[row['definition']]['contract']
        assert set(row['arguments']) == set(contract['parameters'])
        argument = row['arguments']['path']
        assert argument['kind'] == 'Path' and type(argument['value']) is str
        path = native_path(argument['trace'], originals)
        assert str(path) == argument['value'] == route['target'], 'native typed actual path versus original abstract path'
        assert row['source_candidate']['path'] == str(path)
        assert prepare.unblob(row['source_candidate']['body']) == originals[str(path)]
        assert row['return_kind'] == contract['return_kind'] and row['namespace_name'] == route['module_name']
        assert row['runtime_payload_qualified'] is False
        if contract['kind'] == 'exec dictionary namespace':
            assert row['logical_name'] == str(path) and row['input_expression'] == 'path.read_bytes()'
            assert row['payload_role'] == 'read_bytes input under fixed source-image premise'
            assert row['file_field_expression'] == ('str(path)' if route['file_field'] else None)
        else:
            name = row['arguments']['name']
            assert name['kind'] == 'str' and type(name['value']) is str and name['value'] == route['module_name']
            assert row['logical_name'] is None and row['input_expression'] is None and row['file_field_expression'] is None
            assert row['payload_role'] == 'file-loader source candidate; selected executable input unqualified'
        public.append(dict(route=list(key(route)[:3]), native_type=type(path).__module__ + '.' + type(path).__qualname__,
                           native_value=str(path), file_read=False))
    assert value['independent_join_owner'] == OWNER.rsplit('.', 1)[0] + '.5'
    return public


def controls(expected, fixed, contracts, originals):
    outcomes = []
    for label in ('path_kind', 'path_value', 'constructor', 'payload', 'logical_name', 'namespace',
                  'omitted_binding', 'omitted_declaration', 'caller', 'loader_authority', 'typed_permission'):
        bad = copy.deepcopy(expected)
        row = bad['bindings'][0]
        if label == 'path_kind': row['arguments']['path']['kind'] = 'str'
        elif label == 'path_value': row['arguments']['path']['value'] = row['route']['caller']
        elif label == 'constructor': row['arguments']['path']['trace']['operation'] = 'Path'
        elif label == 'payload': row['source_candidate']['body'] = prepare.blob(b'other source')
        elif label == 'logical_name': row['logical_name'] = 'synthetic.py'
        elif label == 'namespace': row['namespace_name'] = '__main__'
        elif label == 'omitted_binding': bad['bindings'].pop()
        elif label == 'omitted_declaration': bad['declarations'].pop(next(iter(bad['declarations'])))
        elif label == 'caller': row['definition'] = row['route']['target']
        elif label == 'loader_authority': bad['loader_input_qualified'] = True
        else: bad['runtime_permission'] = 0
        changes = caller.changes(expected, bad)
        assert changes
        try:
            review(bad, fixed, contracts, originals)
        except (AssertionError, KeyError) as error:
            outcomes.append(dict(label=label, changes=changes, candidate_identity=bounded.identity(bad),
                refusal=type(error).__name__ + ': ' + str(error), kind='caught typed source-model refusal; no historical native exit'))
        else:
            raise AssertionError('changed typed binding admitted: ' + label)
    for outcome in outcomes:
        bad = copy.deepcopy(expected)
        for change in outcome['changes']:
            parent = bad
            for part in change['path'][:-1]: parent = parent[part]
            part = change['path'][-1]
            bounded.strict_equal(parent[part], change['before'])
            if change.get('remove') is True: del parent[part]
            else: parent[part] = change['after']
        bounded.strict_equal(bounded.identity(bad), outcome['candidate_identity'])
        try:
            review(bad, fixed, contracts, originals)
        except (AssertionError, KeyError) as error:
            assert type(error).__name__ + ': ' + str(error) == outcome['refusal']
        else:
            raise AssertionError('retained typed candidate admitted')
    return outcomes


def source_type_control(expected, contracts, originals):
    """Replace an actual literal Path constructor with str, then check both APIs.

    Only expressions in the source model and public API calls on string data
    are evaluated. The changed historical file and its functions never run.
    """
    row = expected['bindings'][0]
    trace = row['arguments']['path']['trace']
    assert trace['operation'] == 'join' and trace['left']['operation'] == 'Path'
    root = trace['left']
    text = root['source']['text']
    assert text.startswith('Path(')
    changed = 'str(' + text[5:]
    body = originals[root['origin']]
    assert body.count(text.encode()) == 1
    candidate = body.replace(text.encode(), changed.encode(), 1)
    ast.parse(candidate)
    model = Graph(contracts)
    model.bodies[root['origin']] = body
    original_tree = ast.parse(body)
    root_node = next(node for node in ast.walk(original_tree) if isinstance(node, ast.Call)
                     and dispatch.source(node, body.decode()) == root['source'])
    before = model.value(root_node, {}, root['origin'])
    after = model.value(ast.parse(changed, mode='eval').body, {}, root['origin'])
    assert isinstance(before, SourcePath) and type(after) is str and str(before) == after
    expression = ast.parse(trace['source']['text'], mode='eval').body
    assert isinstance(expression, ast.BinOp) and isinstance(expression.left, ast.Name)
    assert isinstance(expression.right, ast.Constant) and expression.right.value == trace['right']
    try:
        model.value(expression, {expression.left.id: after}, trace['origin'])
    except fixed_modules.Unknown as error:
        refusal = str(error)
    else:
        raise AssertionError('string constructor admitted as a Path join')
    native_before, native_after = Path(root['argument']), str(root['argument'])
    assert isinstance(native_before, Path) and type(native_after) is str
    assert str(native_before / trace['right']) == row['route']['target']
    try:
        native_after / trace['right']
    except TypeError as error:
        native_refusal = str(error)
    else:
        raise AssertionError('native string division unexpectedly admitted')
    return dict(original=root['origin'], before=text, after=changed, candidate=prepare.blob(candidate),
        typed_before=datum(before), typed_after=datum(after), model_refusal=refusal,
        native_refusal=native_refusal, role='actual syntax-valid constructor substitution; no original code executes')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw = execute.read(templates.PATH)
    assert raw == epoch.read(AUTHORITY, str(templates.PATH)), 'whole committed source-template qualification'
    contracts = json.loads(gzip.decompress(raw))['result']['templates']
    fixed_raw = execute.read(operands.INPUT)
    assert fixed_raw == epoch.read(operands.AUTHORITY, str(operands.INPUT))
    fixed = json.loads(gzip.decompress(fixed_raw))['graph']
    graph = json.loads(prepare.encoded(Graph(contracts).build()))
    # This is a serialized-record oracle: discard construction-time aliasing
    # before making/replaying genuine serialized candidate interventions.
    result = json.loads(prepare.encoded(derive(graph, fixed, contracts)))
    originals = epoch.batch(epoch.REVISION, result['sources'])
    product = dict(result=result, native_pathlib=review(result, fixed, contracts, originals),
        native_interpreter=graph['language'],
        controls=controls(result, fixed, contracts, originals),
        source_type_control=source_type_control(result, contracts, originals),
        template_identity=prepare.identity(raw), fixed_graph_identity=prepare.identity(fixed_raw),
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write:
        execute.save(PATH, product)
    else:
        bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Typed Path/string caller bindings, native public path operators, complete fixed source candidates and saved refusals agree; loader/cache/runtime payload and effects remain unqualified.')
