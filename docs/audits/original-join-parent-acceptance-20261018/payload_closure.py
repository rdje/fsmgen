"""Inspect frozen reconstructed payloads as syntax, without running their code."""
import argparse
import ast
import builtins
import copy
import gzip
import io
import json
import symtable
import sys
import tokenize

import operand_allocation as allocation

AUTHORITY = '14237e63cb12c8b0ce43251772cfdac17d5d084f'
OWNER = allocation.OWNER.rsplit('.', 1)[0] + '.3'
PATH = allocation.execute.AUDIT / 'payload-boundary-qualified.json.gz'
SOURCE = allocation.execute.AUDIT / 'payload_closure.py'
EXEC_NAMES = {'compile', 'exec', 'eval', '__import__'}
LIMITS = dict(original_programme_execution=False, concrete_namespace_values_qualified=False,
              actual_exports_qualified=False, original_import_selection_qualified=False,
              original_compile_callable_qualified=False, complete_source_allocation_qualified=False,
              default_reachability_qualified=False, effects_qualified=False, runtime_permission=False)
SCOPE = ('Whole reconstructed-payload lexical imports, declared namespace/export contracts '
         'and direct Python execution-input boundaries only. Frozen native-Git-bound allocation '
         'and prior qualified source/data/recipe/name models remain shared premises. Token '
         'membership checks byte syntax; serialized-tree traversal independently checks AST '
         'import/execution names. Current Python grammar, AST schemas, symbol-table semantics, '
         'builtin/stdlib name lists and the declared original compiler/import API contracts '
         'are shared premises, not observed original callable or loader identities. AST '
         'canonical rendering is a derived syntax representation, never original byte custody. '
         'Input-only code retains all nested syntax and is excluded only by its original '
         'discarded compiler-result source contract. No original programme/model/recipe '
         'executes. Indirect runtime dispatch, concrete namespace values, actual exports, '
         'original import selection and complete source/default/effect/runtime/custody/native/'
         'private qualifications remain open.')


def decode(value):
    """Rebuild syntax objects only; no compiled code object is created or run."""
    if type(value) is list:
        return [decode(child) for child in value]
    assert type(value) is dict
    if 'scalar_type' in value:
        assert set(value) == {'scalar_type', 'value'}
        assert type(value['value']).__name__ == value['scalar_type']
        assert type(value['value']) in (str, int, bool, float, type(None))
        return value['value']
    assert set(value) == {'node', 'fields', 'attributes'}
    kind = getattr(ast, value['node'])
    assert isinstance(kind, type) and issubclass(kind, ast.AST)
    assert set(value['fields']) == set(kind._fields)
    assert set(value['attributes']) <= set(kind._attributes)
    node = kind(**{key: decode(child) for key, child in value['fields'].items()})
    for key, child in value['attributes'].items():
        setattr(node, key, decode(child))
    return node


def token_calls(body):
    tokens = [token for token in tokenize.tokenize(io.BytesIO(body).readline)
              if token.type not in (tokenize.ENCODING, tokenize.NL, tokenize.NEWLINE,
                  tokenize.COMMENT, tokenize.INDENT, tokenize.DEDENT, tokenize.ENDMARKER)]
    lines, result = body.decode().splitlines(), []
    for index, token in enumerate(tokens):
        if token.type != tokenize.NAME or token.string not in EXEC_NAMES:
            continue
        if index + 1 >= len(tokens) or tokens[index + 1].string != '(':
            continue
        if index and tokens[index - 1].string in ('.', 'def', 'class'):
            continue
        line, column = token.start
        result.append(dict(name=token.string, line=line, column=len(lines[line - 1][:column].encode())))
    return result


def inspect_body(body):
    text, tree = body.decode(), ast.parse(body)
    imports, calls, references = [], [], []
    parents = {id(child): node for node in ast.walk(tree) for child in ast.iter_child_nodes(node)}
    for node in ast.walk(tree):
        if isinstance(node, (ast.Import, ast.ImportFrom)):
            imports.append(dict(kind=type(node).__name__, source=ast.get_source_segment(text, node),
                module=node.module if isinstance(node, ast.ImportFrom) else None,
                level=node.level if isinstance(node, ast.ImportFrom) else 0,
                names=[dict(name=alias.name, asname=alias.asname) for alias in node.names],
                line=node.lineno, column=node.col_offset,
                end_line=node.end_lineno, end_column=node.end_col_offset))
        if isinstance(node, ast.Name) and node.id in EXEC_NAMES and isinstance(node.ctx, ast.Load):
            parent = parents[id(node)]
            direct = isinstance(parent, ast.Call) and parent.func is node
            references.append(dict(name=node.id, direct_call=direct, line=node.lineno, column=node.col_offset))
            if direct:
                calls.append(dict(name=node.id, line=node.lineno, column=node.col_offset))
    ordered = lambda rows: sorted(rows, key=lambda row: (row['line'], row['column']))
    allocation.bounded.strict_equal(ordered(calls), ordered(token_calls(body)))
    keywords = [(token.start[0], len(text.splitlines()[token.start[0] - 1][:token.start[1]].encode()))
                for token in tokenize.tokenize(io.BytesIO(body).readline)
                if token.type == tokenize.NAME and token.string == 'import']
    assigned = []
    for row in imports:
        matches = [point for point in keywords if (row['line'], row['column']) <= point
                   < (row['end_line'], row['end_column'])]
        assert len(matches) == 1, 'one independent import keyword per complete import statement'
        assigned.extend(matches)
    assert sorted(assigned) == sorted(keywords), 'all lexical import keywords allocated exactly once'
    root = symtable.symtable(text, 'payload-syntax-inventory', 'exec')
    tables, pending = [], [root]
    while pending:
        table = pending.pop()
        tables.append(table)
        pending.extend(table.get_children())
    bound = {symbol.get_name() for symbol in root.get_symbols()
             if symbol.is_assigned() or symbol.is_imported() or symbol.is_namespace()}
    used = {symbol.get_name() for table in tables for symbol in table.get_symbols()
            if symbol.is_referenced() and (table is root or symbol.is_global())}
    return dict(imports=ordered(imports), direct_execution_calls=ordered(calls),
        execution_name_references=ordered(references), module_bindings=sorted(bound),
        external_namespace_inputs=sorted(used - bound - set(vars(builtins))))


def serialized_oracle(value):
    """Inspect typed fields directly, without decoding/unparsing or ast.walk."""
    imports, references = [], []
    scalar = allocation_value

    def visit(node):
        if type(node) is list:
            for child in node:
                visit(child)
        elif type(node) is dict and 'node' in node:
            fields = node['fields']
            if node['node'] in ('Import', 'ImportFrom'):
                imports.append(dict(kind=node['node'],
                    module=scalar(fields['module']) if node['node'] == 'ImportFrom' else None,
                    level=scalar(fields['level']) if node['node'] == 'ImportFrom' else 0,
                    names=[dict(name=scalar(alias['fields']['name']), asname=scalar(alias['fields']['asname']))
                           for alias in fields['names']]))
            if node['node'] == 'Name' and scalar(fields['id']) in EXEC_NAMES and fields['ctx']['node'] == 'Load':
                references.append(scalar(fields['id']))
            for child in fields.values():
                visit(child)

    visit(value)
    return dict(imports=imports, execution_names=sorted(references))


def allocation_value(value):
    assert set(value) == {'scalar_type', 'value'}
    assert type(value['value']).__name__ == value['scalar_type']
    return value['value']


def selector_domain(use, parents, module, body):
    if isinstance(use.slice, ast.Constant) and type(use.slice.value) is str:
        return [use.slice.value], None
    assert isinstance(use.slice, ast.Name) and use.slice.id == 'name', 'owned finite namespace selector grammar'
    node = parents[id(use)]
    while not isinstance(node, ast.For):
        assert not isinstance(node, (ast.FunctionDef, ast.Module)), 'selector must be bound by its enclosing finite loop'
        node = parents[id(node)]
    assert isinstance(node.target, ast.Name) and node.target.id == 'name'
    expected = ast.parse("('values', *FUNCTIONS)", mode='eval').body
    assert ast.dump(node.iter) == ast.dump(expected), 'complete finite namespace iterator'
    declarations = [statement for statement in module.body if isinstance(statement, ast.Assign)
                    and len(statement.targets) == 1 and isinstance(statement.targets[0], ast.Name)
                    and statement.targets[0].id == 'FUNCTIONS']
    assert len(declarations) == 1 and isinstance(declarations[0].value, ast.Dict)
    declaration = declarations[0]
    mapping = []
    for key, value in zip(declaration.value.keys, declaration.value.values, strict=True):
        assert isinstance(key, ast.Constant) and type(key.value) is str
        assert isinstance(value, ast.Constant) and type(value.value) is str
        mapping.append([key.value, value.value])
    assert mapping and len({pair[0] for pair in mapping}) == len(mapping)
    source = ast.get_source_segment(body.decode(), declaration)
    tokens = [token for token in tokenize.generate_tokens(io.StringIO(source).readline)
              if token.type not in (tokenize.NL, tokenize.NEWLINE, tokenize.COMMENT,
                  tokenize.INDENT, tokenize.DEDENT, tokenize.ENDMARKER)]
    assert [token.string for token in tokens[:3]] == ['FUNCTIONS', '=', '{'] and tokens[-1].string == '}'
    index, independent = 3, []
    while index < len(tokens) - 1:
        assert tokens[index].type == tokenize.STRING and tokens[index + 1].string == ':'
        assert tokens[index + 2].type == tokenize.STRING
        pair = [ast.literal_eval(tokens[index].string), ast.literal_eval(tokens[index + 2].string)]
        assert all(type(value) is str for value in pair)
        independent.append(pair)
        index += 3
        if index < len(tokens) - 1:
            assert tokens[index].string == ','
            index += 1
    allocation.bounded.strict_equal(mapping, independent)
    keys = ['values', *[pair[0] for pair in mapping]]
    assert len(keys) == len(set(keys))
    return keys, dict(iterator_source=ast.get_source_segment(body.decode(), node.iter),
        declaration_source=source, ordered_mapping=mapping, keys=keys,
        source_identity=allocation.prepare.identity(body), concrete_original_value_observed=False)


def namespace_contract(model, syntax, is_ast, frame_source=None):
    if is_ast:
        declared = model['recipe']
        initial = {key: repr(value) for key, value in declared['namespace'].items()}
        allocation.bounded.strict_equal(syntax['module_bindings'], model['declared_module_bindings'])
        module = ast.parse(frame_source)
        parents = {id(child): node for node in ast.walk(module) for child in ast.iter_child_nodes(node)}
        functions = [node for node in module.body if isinstance(node, ast.FunctionDef) and node.name == 'derive']
        assert len(functions) == 1
        function = functions[0]
        assert ast.get_source_segment(frame_source.decode(), function) == declared['recipe_source']
        uses = sorted([node for node in ast.walk(function) if isinstance(node, ast.Subscript)
                       and isinstance(node.value, ast.Name) and node.value.id == 'namespace'],
                      key=lambda node: (node.lineno, node.col_offset))
        allocation.bounded.strict_equal([dict(line=node.lineno, column=node.col_offset,
            source=ast.get_source_segment(frame_source.decode(), node)) for node in uses],
            declared['namespace_use_sites'])
    else:
        declared = model['source_contract']
        statement = ast.parse(declared['namespace_source']).body[0]
        assert isinstance(statement, ast.Assign) and len(statement.targets) == 1
        assert isinstance(statement.targets[0], ast.Name) and statement.targets[0].id == 'namespace'
        assert isinstance(statement.value, ast.Dict)
        initial = {}
        for key, value in zip(statement.value.keys, statement.value.values, strict=True):
            assert isinstance(key, ast.Constant) and type(key.value) is str and key.value not in initial
            initial[key.value] = ast.unparse(value)
        allocation.bounded.strict_equal(syntax['external_namespace_inputs'], declared['external_namespace_inputs'])
        use = ast.parse(declared['result_use']).body[0]
        assert isinstance(use, ast.Assign)
        uses = [use.value]
    assert set(syntax['external_namespace_inputs']) <= set(initial), 'all declared external namespace requirements supplied by source contract'
    exports, writes, selectors = [], [], []
    for use in uses:
        assert isinstance(use, ast.Subscript) and isinstance(use.value, ast.Name) and use.value.id == 'namespace'
        if is_ast:
            keys, selector = selector_domain(use, parents, module, frame_source)
            if selector is not None:
                selectors.append(dict(line=use.lineno, column=use.col_offset,
                    role=type(use.ctx).__name__, contract=selector))
        else:
            assert isinstance(use.slice, ast.Constant) and type(use.slice.value) is str
            keys = [use.slice.value]
        assert set(keys) <= set(syntax['module_bindings']), 'read or replaced export has a source-defined module binding'
        assert isinstance(use.ctx, (ast.Load, ast.Store))
        (exports if isinstance(use.ctx, ast.Load) else writes).extend(keys)
    return dict(initial_expressions=initial, external_inputs=syntax['external_namespace_inputs'],
        requested_exports=sorted(set(exports)), replaced_exports=sorted(set(writes)),
        finite_selectors=selectors, complete_prior_contract=allocation.bounded.identity(declared),
        concrete_values_qualified=False, actual_exports_qualified=False)


def discarded_result(model, models):
    site = model['original_operand']['site']
    source = models[str(allocation.operands.INPUT)]['graph']['sources'][site[0]]
    body = allocation.prepare.unblob(source['body'])
    tree = ast.parse(body)
    parents = {id(child): node for node in ast.walk(tree) for child in ast.iter_child_nodes(node)}
    calls = [node for node in ast.walk(tree) if isinstance(node, ast.Call)
             and (node.lineno, node.col_offset) == tuple(site[1:])]
    assert len(calls) == 1
    call = calls[0]
    assert isinstance(call.func, ast.Name) and call.func.id == 'compile'
    assert len(call.args) == 3 and not call.keywords and ast.literal_eval(call.args[2]) == 'exec'
    statement = parents[id(call)]
    assert isinstance(statement, ast.Expr) and statement.value is call, 'compiler result discarded by its complete source statement'
    text = ast.get_source_segment(body.decode(), statement)
    assert text == model['site']['statement'] and model['site']['namespace'] is None
    assert model['site']['result_use'] == 'discarded standalone expression'
    return dict(source_path=site[0], source_identity=allocation.prepare.identity(body),
        compile_site=site, statement=text, compiler_result_discarded_by_source=True,
        original_compiler_identity_qualified=False,
        premise='Declared compile API returns a code object without evaluating it; original callable identity and actual stdin remain unobserved.')


def inputs():
    reference = allocation.prerequisite.file_reference(AUTHORITY, str(allocation.PATH))
    raw = allocation.prerequisite.read_reference(reference)
    assert raw == allocation.execute.read(allocation.PATH), 'whole committed model/site allocation'
    prior = json.loads(gzip.decompress(raw))
    models = {name: json.loads(gzip.decompress(allocation.prepare.unblob(row['body'])))
              for name, row in prior['inputs'].items()}
    return raw, reference, prior, models


def derive(prior, models):
    result = []
    for row in prior['result']['bindings']:
        if row['model'] == str(allocation.SAVED):
            model = models[row['model']]['result']
            index = model['source_contract']['modes'].index(row['context'])
            assert row['logical_name'] == model['source_contract']['logical_names'][index], 'allocated saved compilation name'
            body = allocation.prepare.unblob(model['programme'])
            allocation.bounded.strict_equal(allocation.prepare.identity(body), row['input']['identity'])
            kind, excluded = 'reconstructed source bytes', False
        elif row['model'] == str(allocation.AST_INPUT):
            assert type(row['context']) is int and 0 <= row['context'] < len(models[row['model']]['result']['bindings']), 'typed allocated AST context'
            model = models[row['model']]['result']['bindings'][row['context']]
            assert row['logical_name'] == model['recipe']['logical_name'], 'allocated AST compilation name'
            allocation.bounded.strict_equal(allocation.bounded.identity(model['transformed_tree']), row['input']['transformed_tree'])
            tree = decode(model['transformed_tree'])
            body = (ast.unparse(tree) + '\n').encode()
            assert ast.dump(tree) == ast.dump(ast.parse(body)), 'canonical rendering retains AST fields'
            kind, excluded = 'canonical rendering of transformed AST; not original source bytes', False
        elif row['model'] == str(allocation.COMPILE_ONLY):
            selected = [candidate for candidate in models[row['model']]['result']['bindings']
                        if candidate['context'] == row['context']]
            assert len(selected) == 1
            model = selected[0]
            assert row['logical_name'] == model['logical_name'], 'allocated input-only compilation name'
            body = allocation.prepare.unblob(model['payload'])
            allocation.bounded.strict_equal(allocation.prepare.identity(body), row['input']['identity'])
            kind, excluded = 'input-only reconstructed source bytes', True
        else:
            assert row['model'] == str(allocation.fixed.PATH)
            continue
        allocation.bounded.strict_equal(allocation.bounded.identity(model), row['model_binding'])
        syntax = inspect_body(body)
        imports = []
        for statement in syntax['imports']:
            assert statement['level'] == 0, 'relative import requires a separately owned source expansion'
            roots = ([statement['module'].split('.')[0]] if statement['module'] is not None
                     else [alias['name'].split('.')[0] for alias in statement['names']])
            assert all(root in sys.stdlib_module_names for root in roots), 'non-stdlib declaration requires owned executable-source inputs'
            imports.append(dict(source=statement['source'], roots=roots,
                contract='Declared stdlib names under current Python API; actual original loader/module bytes remain unobserved.'))
        if row['model'] == str(allocation.AST_INPUT):
            oracle = serialized_oracle(model['transformed_tree'])
            actual = [{key: item[key] for key in ('kind', 'module', 'level', 'names')}
                      for item in syntax['imports']]
            allocation.bounded.strict_equal(oracle['imports'], actual)
            allocation.bounded.strict_equal(oracle['execution_names'],
                sorted(item['name'] for item in syntax['execution_name_references']))
        else:
            oracle = None
        if excluded:
            namespace, exclusion = None, discarded_result(model, models)
        else:
            assert not syntax['execution_name_references'], 'new direct or aliased execution-name input requires owned recursive expansion'
            is_ast = row['model'] == str(allocation.AST_INPUT)
            if is_ast:
                frame_path = model['original_operand']['site'][0]
                frame_source = allocation.prepare.unblob(models[row['model']]['inputs'][frame_path])
                allocation.bounded.strict_equal(frame_source,
                    allocation.prepare.unblob(models[str(allocation.operands.INPUT)]['graph']['sources'][frame_path]['body']))
            else:
                frame_source = None
            namespace = namespace_contract(model, syntax, is_ast, frame_source)
            exclusion = None
        result.append(dict(identifier=row['identifier'], allocation=allocation.bounded.identity(row),
            logical_name=row['logical_name'], representation=kind, body=allocation.prepare.blob(body),
            input_only=excluded, syntax=syntax, import_contracts=imports,
            serialized_tree_oracle=oracle, namespace_contract=namespace, exclusion=exclusion))
    expected = {row['identifier'] for row in prior['result']['bindings']
                if row['model'] != str(allocation.fixed.PATH)}
    identifiers = [row['identifier'] for row in result]
    assert len(identifiers) == len(set(identifiers)) and set(identifiers) == expected
    return dict(schema='fsmgen.reconstructed_payload_boundaries.v1', owner=OWNER, scope=SCOPE,
        payloads=result, reconstructed_lexical_input_closure_qualified=True,
        complete_data_recovery_owner=OWNER.rsplit('.', 1)[0] + '.4', **LIMITS)


def review(value, prior, models):
    assert all(value[key] is False for key in LIMITS), 'no borrowed concrete namespace/import/source/runtime authority'
    allocation.bounded.strict_equal(value, derive(prior, models))
    return True


def controls(expected, prior, models):
    result = []
    for label in ('omitted_payload', 'duplicate_payload', 'wrong_binding', 'changed_source',
                  'lost_import', 'wrong_import_name', 'wrong_stdlib_role', 'lost_namespace_seed',
                  'wrong_export', 'wrong_recipe', 'hidden_execution_site', 'wrong_input_only_role',
                  'lost_discarded_result', 'borrowed_import_selection', 'numeric_permission'):
        bad = copy.deepcopy(expected)
        row = bad['payloads'][0]
        if label == 'omitted_payload': bad['payloads'].pop()
        elif label == 'duplicate_payload': bad['payloads'].append(copy.deepcopy(row))
        elif label == 'wrong_binding': row['allocation']['sha256'] = '0' * 64
        elif label == 'changed_source': row['body']['sha256'] = '0' * 64
        elif label == 'lost_import': row['syntax']['imports'].pop()
        elif label == 'wrong_import_name': row['syntax']['imports'][0]['names'][0]['name'] = 'json'
        elif label == 'wrong_stdlib_role': row['import_contracts'][0]['roots'][0] = 'json'
        elif label == 'lost_namespace_seed': row['namespace_contract']['initial_expressions'].pop('__name__')
        elif label == 'wrong_export': row['namespace_contract']['requested_exports'][0] = 'Missing'
        elif label == 'wrong_recipe': row['namespace_contract']['complete_prior_contract']['sha256'] = '0' * 64
        elif label == 'hidden_execution_site': row['syntax']['direct_execution_calls'].append(dict(name='exec', line=1, column=0))
        elif label == 'wrong_input_only_role': row['input_only'] = True
        elif label == 'lost_discarded_result':
            next(item for item in bad['payloads'] if item['input_only'])['exclusion']['compiler_result_discarded_by_source'] = False
        elif label == 'borrowed_import_selection': bad['original_import_selection_qualified'] = True
        else: bad['runtime_permission'] = 0
        changes = allocation.fixed.caller.changes(expected, bad)
        assert changes
        try:
            review(bad, prior, models)
        except AssertionError as error:
            result.append(dict(label=label, changes=changes, candidate_identity=allocation.bounded.identity(bad),
                               refusal=str(error), prior_inputs_unchanged=True))
        else:
            raise AssertionError('changed payload boundary admitted: ' + label)
    return result


def semantic_controls(prior, models):
    """Calibrate predicates with consistent private inputs, beyond frozen hashes.

    Updating inner identities here does not update the native outer allocation.
    These are private predicate controls, never alternate admitted provenance.
    """
    result = []
    for label in ('recursive_source', 'unowned_import', 'missing_namespace',
                  'changed_export_contract', 'selector_missing_export',
                  'selector_iterator_change', 'boolean_context', 'wrong_compilation_name'):
        candidate_prior, candidate_models = copy.deepcopy(prior), copy.deepcopy(models)
        if label in ('recursive_source', 'unowned_import', 'missing_namespace'):
            model = candidate_models[str(allocation.SAVED)]['result']
            if label == 'missing_namespace':
                statement = ast.parse(model['source_contract']['namespace_source']).body[0]
                pairs = [(key, value) for key, value in zip(statement.value.keys, statement.value.values, strict=True)
                         if ast.literal_eval(key) != 'args']
                statement.value.keys = [key for key, _ in pairs]
                statement.value.values = [value for _, value in pairs]
                model['source_contract']['namespace_source'] = ast.unparse(statement)
            else:
                tail = b'\nexec("pass")\n' if label == 'recursive_source' else b'\nimport unowned_payload_module\n'
                model['programme'] = allocation.prepare.blob(allocation.prepare.unblob(model['programme']) + tail)
            for row in candidate_prior['result']['bindings']:
                if row['model'] == str(allocation.SAVED):
                    row['model_binding'] = allocation.bounded.identity(model)
                    row['input']['identity'] = allocation.prepare.identity(allocation.prepare.unblob(model['programme']))
        elif label in ('selector_missing_export', 'selector_iterator_change'):
            row = next(item for item in candidate_prior['result']['bindings']
                       if item['model'] == str(allocation.AST_INPUT)
                       and 'original-value-frames' in item['compile_site'][0])
            model = candidate_models[str(allocation.AST_INPUT)]['result']['bindings'][row['context']]
            frame_path = model['original_operand']['site'][0]
            source = allocation.prepare.unblob(candidate_models[str(allocation.AST_INPUT)]['inputs'][frame_path])
            old, new = ((b"FUNCTIONS = {'keys': '_keys'", b"FUNCTIONS = {'Missing': '_keys'")
                        if label == 'selector_missing_export' else
                        (b"for name in ('values', *FUNCTIONS):", b'for name in OTHER:'))
            assert source.count(old) == 1
            source = source.replace(old, new)
            candidate_models[str(allocation.AST_INPUT)]['inputs'][frame_path] = allocation.prepare.blob(source)
            candidate_models[str(allocation.operands.INPUT)]['graph']['sources'][frame_path]['body'] = allocation.prepare.blob(source)
            if label == 'selector_iterator_change':
                function = next(node for node in ast.parse(source).body
                                if isinstance(node, ast.FunctionDef) and node.name == 'derive')
                model['recipe']['recipe_source'] = ast.get_source_segment(source.decode(), function)
                row['model_binding'] = allocation.bounded.identity(model)
        else:
            row = next(item for item in candidate_prior['result']['bindings']
                       if item['model'] == str(allocation.AST_INPUT))
            if label == 'boolean_context':
                assert row['context'] == 0
                row['context'] = False
            elif label == 'wrong_compilation_name':
                row['logical_name'] = 'borrowed-name.py'
            else:
                model = candidate_models[str(allocation.AST_INPUT)]['result']['bindings'][row['context']]
                model['recipe']['namespace_use_sites'][0]['source'] = "namespace['Missing']"
                row['model_binding'] = allocation.bounded.identity(model)
        try:
            derive(candidate_prior, candidate_models)
        except AssertionError as error:
            result.append(dict(label=label, refusal=str(error),
                allocation_changes=allocation.fixed.caller.changes(prior, candidate_prior),
                model_changes=allocation.fixed.caller.changes(models, candidate_models),
                candidate_allocation=allocation.bounded.identity(candidate_prior),
                candidate_models=allocation.bounded.identity(candidate_models),
                scope='Private source/namespace predicate; native outer authority deliberately unchanged and no original code executes.'))
        else:
            raise AssertionError('changed source/namespace predicate admitted: ' + label)
    return result


def result_use_controls(models):
    cases = models[str(allocation.COMPILE_ONLY)]['result']['bindings']
    original_case = next(row for row in cases if row['context'] == 'prerequisites:preparation-second')
    source_path, line, _ = original_case['original_operand']['site']
    original_body = allocation.prepare.unblob(models[str(allocation.operands.INPUT)]['graph']['sources'][source_path]['body'])
    result = []
    for label in ('assigned_compiler_result', 'executed_compiler_result'):
        candidate_models, case = copy.deepcopy(models), copy.deepcopy(original_case)
        lines = original_body.decode().splitlines(keepends=True)
        call = original_case['site']['statement']
        assert lines[line - 1].strip() == call
        indent = lines[line - 1][:-len(lines[line - 1].lstrip())]
        statement = 'captured = ' + call if label == 'assigned_compiler_result' else 'exec(' + call + ')'
        lines[line - 1] = indent + statement + '\n'
        body = ''.join(lines).encode()
        calls = [node for node in ast.walk(ast.parse(body)) if isinstance(node, ast.Call)
                 and isinstance(node.func, ast.Name) and node.func.id == 'compile' and node.lineno == line]
        assert len(calls) == 1
        case['original_operand']['site'][2] = calls[0].col_offset
        candidate_models[str(allocation.operands.INPUT)]['graph']['sources'][source_path]['body'] = allocation.prepare.blob(body)
        try:
            discarded_result(case, candidate_models)
        except AssertionError as error:
            result.append(dict(label=label, candidate_body=allocation.prepare.blob(body),
                candidate_case=case, refusal=str(error),
                original_source_identity=allocation.prepare.identity(original_body),
                scope='Direct discarded-result predicate with the changed call coordinate re-derived from its actual syntax; native published source/proofs remain untouched.'))
        else:
            raise AssertionError('used compiler result received an input-only exclusion: ' + label)
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw, reference, prior, models = inputs()
    value = derive(prior, models)
    product = dict(result=value, review=review(value, prior, models), controls=controls(value, prior, models),
        semantic_controls=semantic_controls(prior, models), result_use_controls=result_use_controls(models),
        native_allocation=dict(reference=reference, body=allocation.prepare.blob(raw)),
        native_python=dict(implementation=sys.implementation.name, version=list(sys.version_info)),
        programmes={name: allocation.prepare.blob(allocation.execute.read(allocation.execute.AUDIT / name))
                    for name in dict.fromkeys(('payload_closure.py', *allocation.PREMISES))})
    if args.write:
        allocation.execute.save(PATH, product)
    else:
        allocation.bounded.strict_equal(json.loads(gzip.decompress(allocation.execute.read(PATH))), product)
    print('Reconstructed lexical payload boundaries, stdlib-name declarations, namespace/export source contracts and discarded-result input-only exclusions qualify; token/serialized-tree checks and genuine controls agree. Original loader/callable/namespace values and source/default/effect/runtime authority remain open.')
