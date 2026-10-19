"""Join complete parameter-backed input coverage without executing originals."""
import argparse
import ast
import copy
import gzip
import json
from pathlib import Path
import sys

import admission_inputs as admission
import bounded_runtime_inventory as bounded
import direct_inputs as direct
import epoch_constraints as epoch
import execute
import operand_inventory as operands
import prepare
import prerequisite_inputs as prerequisite
import qualify_caller_modules as caller
import reader_tables as tables
import recovered_cause_inputs as cause
import typed_callers as typed

AUTHORITY = '1861de7c9e59f5658fff261f2697460248bf6bd3'
PATH = execute.AUDIT / 'parameter-input-coverage-qualified.json.gz'
OWNER = admission.OWNER.rsplit('.', 1)[0] + '.5'
MODELS = (prerequisite.PATH, cause.PATH, admission.PATH)
PREMISES = tuple(dict.fromkeys(('parameter_input_coverage.py', *admission.PREMISES, *cause.PREMISES)))
LIMITS = dict(runtime_source_image_qualified=False, helper_api_identity_qualified=False,
              runtime_exports_qualified=False, semantic_outputs_qualified=False,
              complete_source_allocation_qualified=False, default_reachability_qualified=False,
              effects_qualified=False, runtime_permission=False)
SCOPE = ('Complete source-listed parameter-backed compile sites and finite original '
         'reader contexts only. Qualified whole tables and prior binding models are '
         'shared premises. Separate whole-source AST enumeration checks site/context '
         'allocation; native Git trees and actual entry blobs check membership/bytes, '
         'and native Path values check filenames/import names. AST/finite caller grammar, '
         'Git protocol/store/hashes and original source-image/helper/API identities remain '
         'explicit premises. All original table members and source variants retain their '
         'own revisions; imported executable allocation is separately owned. Preserved '
         'namespace/argv/import/capture/stdout/proof/condition roles are source contracts, '
         'not executed truth. Physical/cache/runtime/export/default/effect/custody and '
         'native/private gaps remain open. No original reader/module/factory/recipe/cohort runs.')


def key(spec):
    site = spec['operand']['source']
    return (spec['caller'], site['line'], site['column'], spec['selector'])


def lexical_domains(fixed):
    """Enumerate entry-table operands from full source, without helper-name selection."""
    result = {}
    for name, row in sorted(fixed['sources'].items()):
        text = prepare.unblob(row['body']).decode()
        tree = ast.parse(text)
        parents = {id(child): node for node in ast.walk(tree) for child in ast.iter_child_nodes(node)}
        for node in ast.walk(tree):
            if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                    and node.func.id == 'compile' and node.args
                    and isinstance(node.args[0], ast.Subscript)
                    and isinstance(node.args[0].slice, ast.Name) and node.args[0].slice.id == 'entry'):
                continue
            assert len(node.args) == 3 and not node.keywords
            assert isinstance(node.args[0].value, ast.Name)
            assert ast.unparse(node.args[1]) == 'entry' and ast.literal_eval(node.args[2]) == 'exec'
            function = parents[id(node)]
            while not isinstance(function, ast.FunctionDef):
                function = parents[id(function)]
            roots = [statement for statement in function.body if isinstance(statement, ast.Assign)
                     and any(isinstance(target, ast.Name) and target.id == 'root' for target in statement.targets)]
            assert len(roots) == 1 and isinstance(roots[0].value, ast.Subscript)
            root = roots[0].value
            assert isinstance(root.value, ast.Name) and root.value.id == 'PLAN'
            calls = [call for call in ast.walk(tree) if isinstance(call, ast.Call)
                     and isinstance(call.func, ast.Name) and call.func.id == function.name]
            assert calls, 'complete original own-source caller membership'
            if isinstance(root.slice, ast.Name):
                assert [arg.arg for arg in function.args.args] == [root.slice.id] == ['role']
                roles = None
                for call in calls:
                    assert len(call.args) == 1 and not call.keywords and ast.unparse(call.args[0]) == 'role'
                    context = parents[id(call)]
                    while not isinstance(context, (ast.DictComp, ast.ListComp, ast.GeneratorExp)):
                        context = parents[id(context)]
                    assert len(context.generators) == 1
                    generator = context.generators[0]
                    assert ast.unparse(generator.target) == 'role' and not generator.ifs and not generator.is_async
                    current = list(ast.literal_eval(generator.iter))
                    assert len(current) == len(set(current)) and all(type(role) is str for role in current)
                    assert roles is None or current == roles
                    roles = current
            else:
                assert not function.args.args and all(not call.args and not call.keywords for call in calls)
                roles = [ast.literal_eval(root.slice)]
            site = typed.dispatch.source(node, text)
            for role in roles:
                identity = (name, site['line'], site['column'], role)
                assert identity not in result
                result[identity] = dict(function=function.name, site=site,
                    input_expression=ast.unparse(node.args[0]),
                    callers=[typed.dispatch.source(call, text) for call in calls])
    assert result
    return result


def bindings(models):
    result = []
    for path, model in models.items():
        value = model['result']
        assert all(value[field] is False for field in prerequisite.LIMITS)
        rows = value['bindings'] if path == str(prerequisite.PATH) else [value]
        result.extend((path, row) for row in rows)
    return result


def assemble(models, retained, fixed, inventory):
    specs = tables.specifications(fixed, inventory)
    rows = []
    originals = bindings(models)
    for spec in specs:
        matches = [(path, row) for path, row in originals if row['table_spec'] == spec]
        assert len(matches) == 1
        path, binding = matches[0]
        rows.append(dict(site=list(key(spec)), model=path, binding=copy.deepcopy(binding),
                         table_revision=spec['revision'], complete_members=binding['table_members'],
                         input_identity=prepare.identity(prepare.unblob(binding['input']))))
    return dict(schema='fsmgen.parameter_input_coverage.v1', owner=OWNER, scope=SCOPE,
                bindings=rows, source_allocation_owner=direct.ALLOCATION_OWNER, **LIMITS)


def review(value, models, retained, fixed, inventory):
    """Check the new allocation relation before final saved-product equality."""
    assert value['schema'] == 'fsmgen.parameter_input_coverage.v1' and value['owner'] == OWNER
    assert value['scope'] == SCOPE and value['source_allocation_owner'] == direct.ALLOCATION_OWNER
    assert all(value[field] is False for field in LIMITS), 'no borrowed progress or typed permission'
    specs = {key(row): row for row in tables.specifications(fixed, inventory)}
    lexical = lexical_domains(fixed)
    assert specs.keys() == lexical.keys(), 'whole inventory versus independent lexical context domain'
    assigned = [tuple(row['site']) for row in value['bindings']]
    assert len(assigned) == len(set(assigned)), 'one allocation per source/context'
    assert set(assigned) == specs.keys(), 'complete parameter-backed source/context allocation'
    originals = bindings(models)
    assert len(originals) == len(specs)
    native = []
    for row in value['bindings']:
        identity = tuple(row['site'])
        spec, source = specs[identity], lexical[identity]
        binding = row['binding']
        # An intact binding in the wrong slot must fail here even when all
        # counts, source models and individual prior qualifications survive.
        bounded.strict_equal(binding['table_spec'], spec)
        matching = [original for path, original in originals if path == row['model'] and original['table_spec'] == spec]
        assert len(matching) == 1, 'original qualified model/source allocation'
        bounded.strict_equal(binding, matching[0])
        bounded.strict_equal(source['site'], spec['operand']['source'])
        assert source['function'] == spec['operand']['enclosing_name']
        bounded.strict_equal(binding['callers'], source['callers'])
        assert source['input_expression'] == spec['operand']['expressions']['input']['text']
        table = next(table for table in retained['tables'] if table['spec'] == spec)
        tables.review_table(table)
        bounded.strict_equal(binding['table_identity'], bounded.identity(table))
        assert row['table_revision'] == spec['revision']
        members = sorted(table['descriptors'])
        assert row['complete_members'] == binding['table_members'] == members
        _, current_tree = tables.tree_members(spec)
        bounded.strict_equal(current_tree, {name: {k: ref[k] for k in ('mode', 'oid', 'bytes')}
                                          for name, ref in table['descriptors'].items()})
        entry = binding['logical_name']
        assert str(Path(spec['root']) / Path(entry).name) == entry and Path(entry).parent == Path(spec['root'])
        bounded.strict_equal(binding['references']['entry'], table['descriptors'][entry])
        body = prerequisite.read_reference(binding['references']['entry'])
        assert body == prepare.unblob(binding['input']) == prepare.unblob(fixed['sources'][entry]['body'])
        bounded.strict_equal(row['input_identity'], prepare.identity(body))
        assert binding['namespace'] == dict(__name__='__main__', __file__=entry)
        assert binding['argv'] == [entry] and binding['import_path_first'] == spec['root']
        modules = sorted({Path(name).stem for name in members if name.endswith('.py')} | {'capture'})
        assert binding['cleared_modules'] == modules
        if 'parameter' in binding:
            assert binding['parameter'] == dict(role=spec['selector']) and binding['role'] == spec['selector']
        bounded.strict_equal(spec['plan'], fixed['declarations'][spec['plan_path']])
        native.append(dict(site=list(identity), entry=prepare.identity(body), modules=modules,
                           table_revision=spec['revision'], original_execution=False))
    return native


def controls(expected, models, retained, fixed, inventory):
    results = []
    for label in ('omission', 'duplicate', 'permuted_allocation', 'wrong_model', 'revision',
                  'member', 'input', 'namespace', 'caller', 'capture', 'progress', 'typed_permission'):
        bad = copy.deepcopy(expected)
        row = bad['bindings'][0]
        if label == 'omission': bad['bindings'].pop()
        elif label == 'duplicate': bad['bindings'].append(copy.deepcopy(row))
        elif label == 'permuted_allocation':
            bad['bindings'][0]['site'], bad['bindings'][1]['site'] = bad['bindings'][1]['site'], bad['bindings'][0]['site']
        elif label == 'wrong_model': row['model'] = str(admission.PATH) if row['model'] != str(admission.PATH) else str(cause.PATH)
        elif label == 'revision': row['table_revision'] = epoch.REVISION
        elif label == 'member': row['complete_members'].pop()
        elif label == 'input': row['input_identity']['sha256'] = '0' * 64
        elif label == 'namespace': row['binding']['namespace']['__name__'] = 'borrowed_progress'
        elif label == 'caller': row['binding']['callers'].pop()
        elif label == 'capture':
            context = next(item['binding'] for item in bad['bindings'] if item['binding'].get('role') == 'context')
            context['capture']['inputs'].pop()
        elif label == 'progress': bad['semantic_outputs_qualified'] = True
        else: bad['runtime_permission'] = 0
        changes = caller.changes(expected, bad)
        assert changes
        intact = all(any(item['binding'] == original for _, original in bindings(models)) for item in bad['bindings'])
        try: review(bad, models, retained, fixed, inventory)
        except AssertionError as error:
            results.append(dict(label=label, changes=changes, candidate_identity=bounded.identity(bad),
                                prior_bindings_intact=intact, refusal=str(error),
                                kind='caught static input-coverage assertion; no original native receipt'))
        else: raise AssertionError('changed parameter input coverage admitted: ' + label)
    for result in results:
        bad = copy.deepcopy(expected)
        for change in result['changes']:
            parent = bad
            for part in change['path'][:-1]: parent = parent[part]
            part = change['path'][-1]
            bounded.strict_equal(parent[part], change['before'])
            if change.get('remove') is True: del parent[part]
            else: parent[part] = change['after']
        bounded.strict_equal(bounded.identity(bad), result['candidate_identity'])
        try: review(bad, models, retained, fixed, inventory)
        except AssertionError as error: assert str(error) == result['refusal']
        else: raise AssertionError('retained parameter coverage candidate admitted')
    return results


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    inputs = {}
    for path in (*MODELS, tables.PATH, operands.INPUT, operands.PATH):
        raw = execute.read(path)
        assert raw == epoch.read(AUTHORITY, str(path)), 'whole committed input: ' + str(path)
        inputs[str(path)] = raw
    models = {str(path): json.loads(gzip.decompress(inputs[str(path)])) for path in MODELS}
    retained = json.loads(gzip.decompress(inputs[str(tables.PATH)]))
    fixed = json.loads(gzip.decompress(inputs[str(operands.INPUT)]))['graph']
    inventory = json.loads(gzip.decompress(inputs[str(operands.PATH)]))['result']
    result = json.loads(prepare.encoded(assemble(models, retained, fixed, inventory)))
    product = dict(result=result, native=review(result, models, retained, fixed, inventory),
        controls=controls(result, models, retained, fixed, inventory),
        inputs={path: dict(revision=AUTHORITY, identity=prepare.identity(raw)) for path, raw in inputs.items()},
        native_python=dict(implementation=sys.implementation.name, version=list(sys.version_info)),
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write: execute.save(PATH, product)
    else: bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Complete parameter-backed compile inputs conserve source/context/model/table/byte/role allocation; independent lexical, native tree/blob/Path and genuine separating controls agree. All original execution remains unqualified.')
