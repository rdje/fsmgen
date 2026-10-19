"""Reconstruct fixed model AST operands; never execute historical recipes/models."""
import argparse
import ast
import copy
import gzip
import json
import symtable
import sys

import bounded_runtime_inventory as bounded
import epoch_constraints as epoch
import execute
import fixed_input_coverage as fixed_inputs
import operand_inventory as operands
import prepare
import prerequisite_inputs as prerequisite
import saved_program_input as saved

AUTHORITY = '99f212ba474b527fede4b749fcd4ded23ef19c14'
OWNER = fixed_inputs.RECONSTRUCTION + '.4'
PATH = execute.AUDIT / 'ast-model-inputs-qualified.json.gz'
PRIMARY = 'docs/audits/record-value-original-primary-20261005/verify.py'
CAUSE = PRIMARY.rsplit('/', 1)[0] + '/cause_model.py'
MODELS = {
    'docs/audits/record-value-original-metadata-frames-20261005/frame_model.py':
        ('source', 'metadata_source_model', True),
    'docs/audits/record-value-original-value-frames-20261005/frame_model.py':
        ('cause_source', 'direct_value_source_model', False),
}
PREMISES = tuple(dict.fromkeys(('ast_model_inputs.py', *saved.PREMISES)))
LIMITS = dict(runtime_source_image_qualified=False, runtime_callable_identity_qualified=False,
              namespace_values_qualified=False, actual_exports_qualified=False,
              complete_source_allocation_qualified=False, default_reachability_qualified=False,
              effects_qualified=False, runtime_permission=False)
SCOPE = ('Fixed model AST compile operands and source namespace/caller/export contracts only. '
         'Whole retained fixed graph, operand inventory, native Git bodies and original '
         'read_text/Path provenance supply the input premises. A finite source grammar '
         'admits predicate-site annotation and the metadata unsupported-raise replacement. '
         'A separate typed-tree path-patch oracle checks every original/transformed field, '
         'scalar type and coordinate without calling the transformer or location fixer. '
         'Python parsing/AST schemas/location semantics, symbol-table and stdlib APIs, '
         'fixed graph namespace resolution and original helper/API identity remain shared '
         'premises. No historical source, recipe, function, model or cohort executes. '
         'Concrete namespace values, actual exports, complete executable-source/default/'
         'effect/runtime/custody and native/private qualifications remain open.')

ANNOTATION = """for function in tree.body:
    if not isinstance(function, ast.FunctionDef):
        continue
    calls = sorted((node for node in ast.walk(function)
                    if isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                    and node.func.id == 'must'), key=lambda node: (node.lineno, node.col_offset))
    for index, node in enumerate(calls, 1):
        node.keywords.append(ast.keyword(arg='site', value=ast.Constant(function.name + '.' + str(index))))
"""
UNSUPPORTED = """    if function.name == 'metadata_type':
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
"""


def typed(value):
    """Lossless AST fields/attributes; booleans cannot alias integer literals."""
    if isinstance(value, ast.AST):
        return dict(node=type(value).__name__, fields={key: typed(child) for key, child in ast.iter_fields(value)},
                    attributes={key: typed(getattr(value, key)) for key in value._attributes if hasattr(value, key)})
    if type(value) is list:
        return [typed(child) for child in value]
    assert type(value) in (str, int, bool, float, type(None)), 'reviewed AST scalar domain'
    return dict(scalar_type=type(value).__name__, value=value)


def walk_fields(node, path=()):
    """Independent depth-first field paths, without ast.walk or AST mutation."""
    if type(node) is dict and 'node' in node:
        yield path, node
        for key, child in node['fields'].items():
            yield from walk_fields(child, (*path, 'fields', key))
    elif type(node) is list:
        for index, child in enumerate(node):
            yield from walk_fields(child, (*path, index))


def at(value, path):
    for key in path:
        value = value[key]
    return value


def scalar(node):
    assert set(node) == {'scalar_type', 'value'}
    assert type(node['value']).__name__ == node['scalar_type']
    return node['value']


def make_node(kind, fields, location=None):
    return dict(node=kind, fields=fields, attributes=copy.deepcopy(location or {}))


def constant(value, location):
    return make_node('Constant', dict(value=typed(value), kind=typed(None)), location)


def keyword(label, location):
    return make_node('keyword', dict(arg=typed('site'), value=constant(label, location)), location)


def tree_oracle(source, metadata):
    """Patch serialized fields directly, deriving new locations from original parents."""
    result = typed(ast.parse(source))
    edits = []
    for index, function in enumerate(result['fields']['body']):
        if function['node'] != 'FunctionDef':
            continue
        prefix = ('fields', 'body', index)
        name = scalar(function['fields']['name'])
        calls = [(path, node) for path, node in walk_fields(function)
                 if node['node'] == 'Call' and node['fields']['func']['node'] == 'Name'
                 and scalar(node['fields']['func']['fields']['id']) == 'must']
        calls.sort(key=lambda pair: tuple(scalar(pair[1]['attributes'][key]) for key in ('lineno', 'col_offset')))
        for ordinal, (path, node) in enumerate(calls, 1):
            label = name + '.' + str(ordinal)
            assert not any(scalar(row['fields']['arg']) == 'site' for row in node['fields']['keywords'])
            node['fields']['keywords'].append(keyword(label, node['attributes']))
            edits.append(dict(path=list((*prefix, *path)), rule='append predicate site', label=label))
        if metadata and name == 'metadata_type':
            raises = [(path, node) for path, node in walk_fields(function) if node['node'] == 'Raise']
            assert len(raises) == 1, 'complete finite metadata raise domain'
            path, old = raises[0]
            exc = old['fields']['exc']
            assert scalar(old['fields']['cause']) is None and exc['node'] == 'Call'
            assert exc['fields']['func']['node'] == 'Name' and scalar(exc['fields']['func']['fields']['id']) == 'Primary'
            assert not exc['fields']['keywords'] and len(exc['fields']['args']) == 1
            message = exc['fields']['args'][0]
            assert message['node'] == 'Constant' and scalar(message['fields']['value']) == 'unsupported resolved type kind'
            location = old['attributes']
            call = make_node('Call', dict(
                func=make_node('Name', dict(id=typed('must'), ctx=make_node('Load', {})), location),
                args=[constant(False, location), copy.deepcopy(message)],
                keywords=[keyword('metadata_type.unsupported', location)]), location)
            at(function, path[:-1])[path[-1]] = make_node('Expr', dict(value=call), location)
            edits.append(dict(path=list((*prefix, *path)), rule='replace unsupported raise', label='metadata_type.unsupported'))
    return result, edits


def transform(source, metadata):
    """Apply admitted declarative rules in new code; never invoke the original recipe."""
    tree = ast.parse(source)
    for function in tree.body:
        if not isinstance(function, ast.FunctionDef):
            continue
        calls = sorted((node for node in ast.walk(function)
                        if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == 'must'),
                       key=lambda node: (node.lineno, node.col_offset))
        for ordinal, node in enumerate(calls, 1):
            node.keywords.append(ast.keyword(arg='site', value=ast.Constant(function.name + '.' + str(ordinal))))
        if metadata and function.name == 'metadata_type':
            class ReplaceUnsupported(ast.NodeTransformer):
                def visit_Raise(self, node):
                    saved.equal_ast(node, "raise Primary('unsupported resolved type kind')")
                    call = ast.Call(func=ast.Name(id='must', ctx=ast.Load()), args=[ast.Constant(False), node.exc.args[0]],
                                    keywords=[ast.keyword(arg='site', value=ast.Constant('metadata_type.unsupported'))])
                    return ast.copy_location(ast.Expr(value=call), node)
            ReplaceUnsupported().visit(function)
    return ast.fix_missing_locations(tree)


def recipe_contract(body, model):
    argument, namespace, metadata = MODELS[model]
    fn = saved.function(ast.parse(body), 'derive')
    assert not fn.decorator_list and fn.returns is None
    assert ast.dump(fn.args) == ast.dump(ast.parse('def f(' + argument + ', kind, arguments): pass').body[0].args)
    saved.equal_ast(fn.body[0], 'tree = ast.parse(' + argument + ')')
    saved.equal_ast(fn.body[1], ANNOTATION + (UNSUPPORTED if metadata else ''))
    saved.equal_ast(fn.body[2], "namespace = {'__name__': " + repr(namespace) + '}')
    saved.equal_ast(fn.body[3], "exec(compile(ast.fix_missing_locations(tree), '<qualified-cause-model>', 'exec'), namespace)")
    uses = [dict(line=node.lineno, column=node.col_offset, source=ast.get_source_segment(body.decode(), node))
            for node in ast.walk(fn) if isinstance(node, ast.Subscript)
            and isinstance(node.value, ast.Name) and node.value.id == 'namespace']
    return dict(recipe_source=ast.get_source_segment(body.decode(), fn), input_parameter=argument,
                namespace={'__name__': namespace}, logical_name='<qualified-cause-model>', mode='exec',
                namespace_use_sites=sorted(uses, key=lambda row: (row['line'], row['column'])))


def caller_contract(raw, fixed, model):
    caller = model.rsplit('/', 1)[0] + '/verify.py'
    exports = fixed['exports'][caller]
    assert exports['frame_model'] == dict(namespace=model)
    assert exports['primary'] == dict(namespace=PRIMARY)
    assert fixed['exports'][PRIMARY]['BASE'] + '/cause_model.py' == CAUSE
    function = saved.function(ast.parse(raw[caller]), 'source_contracts')
    ret = function.body[-1]
    assert isinstance(ret, ast.Return) and isinstance(ret.value, ast.Dict)
    entries = dict(zip((ast.literal_eval(key) for key in ret.value.keys), ret.value.values, strict=True))
    saved.equal_ast(entries['cause_model'], "(primary['BASE'] / 'cause_model.py').read_text()")
    expected = saved.function(ast.parse(raw[caller]), 'expected_models')
    calls = [node for node in ast.walk(expected) if isinstance(node, ast.Call)
             and isinstance(node.func, ast.Subscript) and isinstance(node.func.value, ast.Name)
             and node.func.value.id == 'frame_model' and ast.literal_eval(node.func.slice) == 'derive']
    assert len(calls) == 1
    saved.equal_ast(calls[0], "frame_model['derive'](source['cause_model'], row['kind'], arguments)")
    return dict(caller=caller, primary_namespace=PRIMARY, source_path=CAUSE,
        path_operation='Path(primary.BASE) / cause_model.py; read_text under original image premise',
        source_contract=ast.get_source_segment(raw[caller].decode(), function),
        caller_source=ast.get_source_segment(raw[caller].decode(), expected),
        call_line=calls[0].lineno, actual_source_image_observed=False)


def derive(raw):
    prior = json.loads(gzip.decompress(raw[str(fixed_inputs.PATH)]))['result']
    fixed = json.loads(gzip.decompress(raw[str(operands.INPUT)]))['graph']
    assert fixed['revision'] == epoch.REVISION and fixed['runtime_permission'] is False
    sites = [row for row in prior['deferred'] if row['owner'] == OWNER]
    assert len(sites) == len(MODELS) and {row['site'][0] for row in sites} == set(MODELS)
    names = {CAUSE, PRIMARY, *MODELS, *(name.rsplit('/', 1)[0] + '/verify.py' for name in MODELS)}
    assert set(raw) == names | {str(fixed_inputs.PATH), str(operands.INPUT)}, 'complete whole fixed input domain'
    for name in names:
        assert raw[name] == prepare.unblob(fixed['sources'][name]['body']), 'whole fixed source binding: ' + name
        assert b'\r' not in raw[name] and raw[name].decode().encode() == raw[name], 'fixed LF UTF-8 source'
    source = raw[CAUSE]
    bindings = []
    for row in sites:
        model = row['site'][0]
        contract = recipe_contract(raw[model], model)
        actual = operands.ast_sites(raw[model], model)
        assert [item for item in actual if item['operation'] == 'compile'] == [row['operand']], 'whole original operand correspondence'
        tree = transform(source, MODELS[model][2])
        expected, edits = tree_oracle(source, MODELS[model][2])
        bounded.strict_equal(typed(tree), expected)
        symbols = symtable.symtable(source.decode(), CAUSE, 'exec')
        declared = sorted(symbol.get_name() for symbol in symbols.get_symbols()
                          if symbol.is_assigned() or symbol.is_imported() or symbol.is_namespace())
        bindings.append(dict(original_operand=row, recipe=contract,
            caller=caller_contract(raw, fixed, model), source_path=CAUSE,
            original_tree=typed(ast.parse(source)), transformed_tree=typed(tree), edits=edits,
            declared_module_bindings=declared, declared_imports=[ast.unparse(node) for node in tree.body
                if isinstance(node, (ast.Import, ast.ImportFrom))], actual_exports_qualified=False))
    return dict(schema='fsmgen.ast_model_inputs.v1', owner=OWNER, scope=SCOPE, bindings=bindings,
                complete_allocation_owner=fixed_inputs.direct.ALLOCATION_OWNER, **LIMITS)


def review(value, raw):
    assert all(value[key] is False for key in LIMITS), 'exact false execution/qualification boundaries'
    bounded.strict_equal(value, derive(raw))
    return True


def controls(expected, raw):
    outcomes = []
    metadata = next(name for name, row in MODELS.items() if row[2])
    for label, name, old, new in (
        ('changed_source', CAUSE, b"'invalid resolved member type'", b"'foreign resolved member type'"),
        ('changed_recipe', metadata, b'node.keywords.append(', b'node.keywords.insert(0, '),
        ('wrong_compile_name', metadata, b'<qualified-cause-model>', b'<foreign-model>'),
        ('wrong_namespace', metadata, b'metadata_source_model', b'foreign_source_model'),
    ):
        candidate = dict(raw)
        assert raw[name].count(old) == 1
        candidate[name] = raw[name].replace(old, new, 1)
        # Keep the qualified graph fixed: a source substitution cannot silently
        # become a new historical input just because reconstruction still works.
        try:
            derive(candidate)
        except AssertionError as error:
            outcomes.append(dict(label=label, changed_inputs={name: prepare.blob(candidate[name])}, refusal=str(error)))
        else:
            raise AssertionError('changed fixed source admitted: ' + label)
        if name == metadata:
            # Exercise the recipe grammar itself, separately from source identity.
            try:
                recipe_contract(candidate[name], metadata)
            except AssertionError as error:
                outcomes.append(dict(label=label + '_grammar', changed_inputs={name: prepare.blob(candidate[name])}, refusal=str(error)))
            else:
                raise AssertionError('changed recipe grammar admitted')
    for label in ('omitted_site', 'wrong_coordinate', 'false_as_integer', 'changed_predicate', 'wrong_node_kind'):
        candidate = copy.deepcopy(expected['bindings'][0]['transformed_tree'])
        binding = expected['bindings'][0]
        edit = binding['edits'][0]
        call = at(candidate, edit['path'])
        if label == 'omitted_site':
            call['fields']['keywords'].pop()
        elif label == 'wrong_coordinate':
            call['fields']['keywords'][-1]['attributes']['lineno']['value'] += 1
        elif label == 'changed_predicate':
            call['fields']['func']['fields']['id'] = typed('foreign_predicate')
        elif label == 'wrong_node_kind':
            call['node'] = 'Expr'
        else:
            meta_binding = next(row for row in expected['bindings'] if row['original_operand']['site'][0] == metadata)
            binding, candidate = meta_binding, copy.deepcopy(meta_binding['transformed_tree'])
            replacement = next(row for row in meta_binding['edits'] if row['rule'] == 'replace unsupported raise')
            at(candidate, replacement['path'])['fields']['value']['fields']['args'][0]['fields']['value'] = typed(0)
        try:
            oracle, _ = tree_oracle(raw[CAUSE], MODELS[binding['original_operand']['site'][0]][2])
            bounded.strict_equal(candidate, oracle)
        except AssertionError as error:
            outcomes.append(dict(label=label, candidate_tree=candidate,
                model=binding['original_operand']['site'][0], refusal=str(error),
                kind='independent complete typed-tree refusal; no primary transformer/equality oracle'))
        else:
            raise AssertionError('corrupted typed AST admitted: ' + label)
    for label in ('missing_model', 'duplicate_model', 'wrong_input_role', 'borrowed_runtime', 'typed_permission'):
        candidate = copy.deepcopy(expected)
        if label == 'missing_model':
            candidate['bindings'].pop()
        elif label == 'duplicate_model':
            candidate['bindings'].append(copy.deepcopy(candidate['bindings'][0]))
        elif label == 'wrong_input_role':
            candidate['bindings'][0]['caller']['source_path'] = PRIMARY
        else:
            candidate['runtime_permission'] = True if label == 'borrowed_runtime' else 0
        try:
            review(candidate, raw)
        except AssertionError as error:
            outcomes.append(dict(label=label, candidate=candidate, refusal=str(error)))
        else:
            raise AssertionError('borrowed execution permission admitted')
    return outcomes


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw = {str(path): execute.read(path) for path in (fixed_inputs.PATH, operands.INPUT)}
    for name, body in raw.items():
        assert body == epoch.read(AUTHORITY, name), 'whole committed input record'
    native = {}
    for name in (CAUSE, PRIMARY, *MODELS, *(model.rsplit('/', 1)[0] + '/verify.py' for model in MODELS)):
        reference = prerequisite.file_reference(epoch.REVISION, name)
        body = prerequisite.read_reference(reference)
        assert body == epoch.read(epoch.REVISION, name), 'whole native versioned source'
        raw[name], native[name] = body, reference
    result = json.loads(prepare.encoded(derive(raw)))
    assert review(result, raw)
    product = dict(result=result, controls=controls(result, raw), native=native,
        inputs={name: prepare.blob(body) for name, body in raw.items()},
        native_python=dict(implementation=sys.implementation.name, version=list(sys.version_info)),
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write:
        execute.save(PATH, product)
    else:
        bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Whole fixed model AST inputs reconstruct with typed fields and coordinates; independent path-patch/source controls agree. Namespace/caller/export contracts retain without historical execution or complete allocation/runtime authority.')
