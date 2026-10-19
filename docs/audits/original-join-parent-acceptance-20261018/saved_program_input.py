"""Reconstruct saved field-reader compile bytes without historical execution."""
import argparse
import ast
import builtins
import copy
import gzip
import json
import symtable
import sys

import bounded_runtime_inventory as bounded
import epoch_constraints as epoch
import execute
import fixed_input_coverage as fixed_inputs
import prepare
import prerequisite_inputs as prerequisite
import qualify_caller_modules as caller

AUTHORITY = 'cfeeec4d1bebcc76e6f1f99fdf0b9b80797e81c6'
OWNER = fixed_inputs.RECONSTRUCTION + '.3'
PATH = execute.AUDIT / 'saved-program-input-qualified.json.gz'
RECIPE = 'docs/audits/record-value-original-fields-20261005/verify.py'
FIELDS = 'docs/audits/record-value-copy-fields-20261004'
SAVED = 'docs/audits/record-value-original-fields-20261005/reader-transform.json'
INPUT = FIELDS + '/verify.py'
PREMISES = tuple(dict.fromkeys(('saved_program_input.py', *fixed_inputs.PREMISES)))
LIMITS = dict(runtime_source_image_qualified=False, runtime_callable_identity_qualified=False,
              namespace_values_qualified=False, actual_exports_qualified=False,
              complete_source_allocation_qualified=False, default_reachability_qualified=False,
              effects_qualified=False, runtime_permission=False)
SCOPE = ('Saved complete-program compile bytes and original source namespace/name/export '
         'contracts only. A finite declarative grammar extracts literal slice/replacement '
         'rules from the whole original source; no historical function, recipe, module '
         'or programme executes. A separate UTF-8 byte-splice oracle joins full native '
         'Git input and saved-record bytes. Original caller/data/model/helper values, '
         'Python AST/text/symbol-table/stdlib APIs and original image/callable identities '
         'remain premises. Namespace expressions and result uses retain as source '
         'contracts; their concrete values, truth and actual exports are not observed. '
         'Transitive source/data allocation, AST/compile-only reconstruction, physical/'
         'cache/default/effect/runtime/custody and native/private gaps remain open.')


def equal_ast(node, source):
    expected = ast.parse(source)
    if isinstance(node, ast.expr):
        assert len(expected.body) == 1 and isinstance(expected.body[0], ast.Expr)
        expected = expected.body[0].value
    else:
        assert len(expected.body) == 1
        expected = expected.body[0]
    assert ast.dump(node) == ast.dump(expected), 'complete source-defined recipe/role grammar'


def function(tree, name):
    rows = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name == name]
    assert len(rows) == 1
    return rows[0]


def recipe_rules(body, source):
    """Extract a declarative edit table; never interpret original statements."""
    tree = ast.parse(body)
    fn = function(tree, 'reader_transform')
    assert not fn.decorator_list and fn.returns is None
    assert ast.dump(fn.args) == ast.dump(ast.parse('def f(): pass').body[0].args)
    statements = fn.body
    assert len(statements) == 10
    equal_ast(statements[0], "source = (FIELDS / 'verify.py').read_text()")
    start_mark = ast.literal_eval(statements[1].value.args[0])
    end_mark = ast.literal_eval(statements[2].value.args[0])
    equal_ast(statements[1], 'start = source.index(' + repr(start_mark) + ')')
    equal_ast(statements[2], 'end = source.index(' + repr(end_mark) + ', start)')
    first_new = ast.literal_eval(statements[3].value.elts[0].elts[1])
    equal_ast(statements[3], 'replacements = [(source[start:end], ' + repr(first_new) + ')]')
    middle = ast.literal_eval(statements[4].value)
    assert type(middle) is list and all(type(pair) is tuple and len(pair) == 2
        and all(type(part) is str for part in pair) for pair in middle)
    equal_ast(statements[4], 'replacements += ' + repr(middle))
    tail_mark = ast.literal_eval(statements[5].value.slice.lower.args[0])
    equal_ast(statements[5], 'tail = source[source.index(' + repr(tail_mark) + '):]')
    tail_new = ast.literal_eval(statements[6].value.args[0].elts[1])
    equal_ast(statements[6], 'replacements.append((tail, ' + repr(tail_new) + '))')
    equal_ast(statements[7], 'transformed = source')
    equal_ast(statements[8], "for old, new in replacements:\n"
        "    require(transformed.count(old) == 1, 'unique complete independent field-reader transform')\n"
        "    transformed = transformed.replace(old, new)")
    equal_ast(statements[9], "return {'source_path': str(FIELDS / 'verify.py'), "
        "'replacements': [list(pair) for pair in replacements], 'complete_program': transformed}")
    assert all(type(part) is str and part for part in (start_mark, end_mark, tail_mark))
    assert type(first_new) is str and type(tail_new) is str
    # Native read_text would normalize CR/LF. The fixed source is already LF UTF-8.
    assert b'\r' not in source and source.decode().encode() == source
    text = source.decode()
    assert text.count(start_mark) == text.count(end_mark) == text.count(tail_mark) == 1
    start = text.index(start_mark)
    end = text.index(end_mark, start)
    assert start < end < text.index(tail_mark)
    rules = [(text[start:end], first_new), *middle, (text[text.index(tail_mark):], tail_new)]
    transformed = text
    steps = []
    for old, new in rules:
        assert old and transformed.count(old) == 1, 'unique sequential source-defined edit'
        before = transformed
        transformed = transformed.replace(old, new)
        steps.append(dict(old=prepare.blob(old.encode()), new=prepare.blob(new.encode()),
            before=prepare.identity(before.encode()), after=prepare.identity(transformed.encode())))
    return dict(source_path=INPUT, replacements=[list(pair) for pair in rules],
                complete_program=transformed), steps


def byte_oracle(source, saved):
    """Splice the saved declarative edits in bytes, independently of source AST rules."""
    assert set(saved) == {'source_path', 'replacements', 'complete_program'}
    assert saved['source_path'] == INPUT
    current, spans = source, []
    for pair in saved['replacements']:
        assert type(pair) is list and len(pair) == 2 and all(type(part) is str for part in pair)
        old, new = (part.encode() for part in pair)
        assert old
        start = current.find(old)
        assert start >= 0 and current.find(old, start + 1) < 0, 'independent unique byte edit'
        end = start + len(old)
        before = current
        current = current[:start] + new + current[end:]
        assert current[:start] == before[:start] and current[start + len(new):] == before[end:]
        spans.append(dict(start=start, end=end, before=prepare.identity(before),
                          after=prepare.identity(current)))
    assert current == saved['complete_program'].encode(), 'whole saved programme reconstruction'
    return current, spans


def source_contract(body, programme):
    tree = ast.parse(body)
    globals_ = {target.id: ast.literal_eval(node.value.args[0])
        for node in tree.body if isinstance(node, ast.Assign) and len(node.targets) == 1
        and isinstance((target := node.targets[0]), ast.Name)
        and isinstance(node.value, ast.Call) and ast.unparse(node.value.func) == 'Path'
        and len(node.value.args) == 1 and not node.value.keywords}
    assert globals_['FIELDS'] == FIELDS and globals_['BASE'] == SAVED.rsplit('/', 1)[0]
    check = function(tree, 'check')
    equal_ast(check.body[1], "namespace = {'__name__': 'complete_source_field_reader', "
        "'native': expected, 'data': data, 'models': copy.deepcopy(models), "
        "'binding': load(FIELDS / 'binding.json'), 'args': SimpleNamespace(omit_field=False, "
        "swap_source_role=False, trust_private_product=False, swap_malformed_model=False)}")
    equal_ast(check.body[2], "exec(compile(transform['complete_program'], "
        "mode + '-complete-independent-field-reader', 'exec'), namespace)")
    equal_ast(check.body[5], "proof = namespace['proof_result']")
    calls = [node for node in ast.walk(tree) if isinstance(node, ast.Call)
             and isinstance(node.func, ast.Name) and node.func.id == 'check']
    assert sorted(ast.unparse(node) for node in calls) == sorted((
        "check('ordinary', data, expected['ordinary'], models, transform)",
        'check(m, mode_data[m], expected[m], models, transform)'))
    main = function(tree, 'main')
    modes = ast.literal_eval(main.body[4].value.generators[0].iter)
    assert type(modes) is tuple and all(type(mode) is str for mode in modes) and len(modes) == len(set(modes))
    equal_ast(main.body[4], 'expected = {m: model_native(m, products, private) for m in ' + repr(modes) + '}')
    equal_ast(main.body[5], "observations = load(BASE / 'observer-transforms.json')")
    equal_ast(main.body[6], "require([r['mode'] for r in observations] == " + repr(list(modes)) + ", 'complete field observation mode domain')")
    equal_ast(main.body[9], 'transform = reader_transform()')
    equal_ast(main.body[10], "transform_path = BASE / 'reader-transform.json'")
    # Full retained source, rather than a mode count, conserves all caller and
    # source-data roles. Concrete native/data/model bindings remain unqualified.
    assert ast.unparse(main.body[12].value.values[1]) == '[check(m, mode_data[m], expected[m], models, transform) for m in mode_data]'
    symbol_root = symtable.symtable(programme, 'reconstructed-field-reader', 'exec')
    tables, pending = [], [symbol_root]
    while pending:
        table = pending.pop(); tables.append(table); pending.extend(table.get_children())
    bound = {symbol.get_name() for symbol in symbol_root.get_symbols()
             if symbol.is_assigned() or symbol.is_imported() or symbol.is_namespace()}
    used = {symbol.get_name() for table in tables for symbol in table.get_symbols()
            if symbol.is_referenced() and (table is symbol_root or symbol.is_global())}
    external = sorted(used - bound - set(vars(builtins)))
    assert set(external) == {'args', 'binding', 'data', 'models', 'native'}, 'complete declared namespace inputs'
    imports = [ast.unparse(node) for node in ast.parse(programme).body
               if isinstance(node, (ast.Import, ast.ImportFrom))]
    return dict(modes=list(modes), logical_names=[mode + '-complete-independent-field-reader' for mode in modes],
        namespace_source=ast.get_source_segment(body.decode(), check.body[1]),
        caller_sites=[dict(line=node.lineno, column=node.col_offset, expression=ast.unparse(node))
                      for node in sorted(calls, key=lambda node: (node.lineno, node.col_offset))],
        check_source=ast.get_source_segment(body.decode(), check),
        main_source=ast.get_source_segment(body.decode(), main),
        controls_source=ast.get_source_segment(body.decode(), function(tree, 'controls')),
        external_namespace_inputs=external, declared_imports=imports,
        result_use=ast.unparse(check.body[5]),
        concrete_namespace_values_qualified=False, actual_exports_qualified=False)


def derive(raw):
    saved = json.loads(raw[SAVED])
    reconstructed, steps = recipe_rules(raw[RECIPE], raw[INPUT])
    bounded.strict_equal(reconstructed, saved)
    programme, spans = byte_oracle(raw[INPUT], saved)
    contract = source_contract(raw[RECIPE], programme.decode())
    prior = json.loads(gzip.decompress(raw[str(fixed_inputs.PATH)]))
    sites = [row for row in prior['result']['deferred'] if row['owner'] == OWNER]
    assert len(sites) == 1 and sites[0]['site'][0] == RECIPE
    site = sites[0]['operand']
    assert site['expressions']['input']['text'] == "transform['complete_program']"
    assert site['source']['line'] == function(ast.parse(raw[RECIPE]), 'check').body[2].value.args[0].lineno
    return dict(schema='fsmgen.saved_program_input.v1', owner=OWNER, scope=SCOPE,
        reconstruction=reconstructed, programme=prepare.blob(programme), steps=steps,
        byte_splice_oracle=spans, source_contract=contract, original_operand=sites[0],
        transitive_source_allocation_owner=fixed_inputs.direct.ALLOCATION_OWNER,
        namespace_values_owner=OWNER.rsplit('.', 2)[0] + '.3', **LIMITS)


def review(value, raw):
    assert all(value[key] is False for key in LIMITS), 'exact false source/runtime boundaries'
    bounded.strict_equal(value, derive(raw))
    return True


def controls(expected, raw):
    outcomes = []
    for label in ('changed_literal_recipe', 'changed_recipe_operation', 'changed_input',
                  'changed_saved_programme', 'omitted_edit', 'reversed_edits',
                  'wrong_namespace', 'wrong_mode', 'wrong_result_role'):
        candidate = dict(raw)
        if label == 'changed_literal_recipe':
            candidate[RECIPE] = raw[RECIPE].replace(b"'own field copy role'", b"'foreign field copy role'", 1)
        elif label == 'changed_recipe_operation':
            candidate[RECIPE] = raw[RECIPE].replace(b'transformed.replace(old, new)', b'transformed.replace(old, new, 0)', 1)
        elif label == 'changed_input': candidate[INPUT] += b'\n# foreign tail\n'
        elif label in ('changed_saved_programme', 'omitted_edit', 'reversed_edits'):
            saved = json.loads(raw[SAVED])
            if label == 'changed_saved_programme': saved['complete_program'] += '\n# foreign programme\n'
            elif label == 'omitted_edit': saved['replacements'].pop()
            else: saved['replacements'].reverse()
            candidate[SAVED] = prepare.encoded(saved)
        elif label == 'wrong_namespace': candidate[RECIPE] = raw[RECIPE].replace(b"'native': expected", b"'native': data", 1)
        elif label == 'wrong_mode': candidate[RECIPE] = raw[RECIPE].replace(b"mode + '-complete-independent-field-reader'", b"'foreign-field-reader'", 1)
        else: candidate[RECIPE] = raw[RECIPE].replace(b"proof = namespace['proof_result']", b"proof = namespace['foreign_result']", 1)
        changes = {name: prepare.blob(body) for name, body in candidate.items() if body != raw[name]}
        assert changes, 'genuine source/data/recipe/role intervention'
        try: derive(candidate)
        except AssertionError as error:
            outcomes.append(dict(label=label, changed_inputs=changes, refusal=str(error),
                kind='caught reconstructed-source refusal; no original native exit'))
        else: raise AssertionError('changed saved source admitted: ' + label)
    for outcome in outcomes:
        candidate = {**raw, **{name: prepare.unblob(blob) for name, blob in outcome['changed_inputs'].items()}}
        try: derive(candidate)
        except AssertionError as error: assert str(error) == outcome['refusal']
        else: raise AssertionError('retained changed source admitted')
    for label, key, replacement in (('borrowed_runtime', 'runtime_permission', True),
                                    ('typed_permission', 'runtime_permission', 0)):
        candidate = copy.deepcopy(expected); candidate[key] = replacement
        try: review(candidate, raw)
        except AssertionError as error:
            outcomes.append(dict(label=label, changes=caller.changes(expected, candidate),
                refusal=str(error), kind='saved reader boundary type/value refusal'))
        else: raise AssertionError('borrowed execution permission admitted')
    for label in ('oracle_wrong_programme', 'oracle_omitted_edit', 'oracle_duplicate_edit'):
        saved = json.loads(raw[SAVED])
        if label == 'oracle_wrong_programme': saved['complete_program'] += '\n# foreign programme\n'
        elif label == 'oracle_omitted_edit': saved['replacements'].pop()
        else: saved['replacements'].append(copy.deepcopy(saved['replacements'][-1]))
        for attempt in range(2):
            candidate = json.loads(prepare.encoded(saved))
            try: byte_oracle(raw[INPUT], candidate)
            except AssertionError as error:
                if attempt == 0:
                    outcomes.append(dict(label=label, candidate=candidate, refusal=str(error),
                        kind='independent byte-splice refusal without primary equality'))
                else: assert str(error) == outcomes[-1]['refusal']
            else: raise AssertionError('corrupted byte-splice candidate admitted')
    return outcomes


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    native, raw = {}, {}
    for name in (RECIPE, INPUT, SAVED):
        reference = prerequisite.file_reference(epoch.REVISION, name)
        body = prerequisite.read_reference(reference)
        assert body == epoch.read(epoch.REVISION, name), 'whole native Git body'
        native[name], raw[name] = reference, body
    raw[str(fixed_inputs.PATH)] = execute.read(fixed_inputs.PATH)
    assert raw[str(fixed_inputs.PATH)] == epoch.read(AUTHORITY, str(fixed_inputs.PATH))
    result = json.loads(prepare.encoded(derive(raw)))
    assert review(result, raw)
    product = dict(result=result, controls=controls(result, raw),
        native=native, inputs={name: prepare.blob(body) for name, body in raw.items()},
        native_python=dict(implementation=sys.implementation.name, version=list(sys.version_info)),
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write: execute.save(PATH, product)
    else: bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Saved complete-program compile bytes reconstruct from whole source-defined edits and independent native Git/byte splices. Exact names and namespace/result source contracts retain; concrete values, exports, transitive allocation and all original execution remain unqualified.')
