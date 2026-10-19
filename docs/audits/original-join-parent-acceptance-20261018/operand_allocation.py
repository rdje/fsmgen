"""Join frozen operand models to original lexical sites without executing them."""
import argparse
import ast
import copy
import gzip
import json

import bounded_runtime_inventory as bounded
import execute
import fixed_input_coverage as fixed
import operand_inventory as operands
import prepare
import prerequisite_inputs as prerequisite

AUTHORITY = '8762ea98ab1e30e9c54686ccb113e21097b1fa35'
OWNER = operands.OWNER + '.3.2'
PATH = execute.AUDIT / 'operand-allocation-qualified.json.gz'
SAVED = execute.AUDIT / 'saved-program-input-qualified.json.gz'
AST_INPUT = execute.AUDIT / 'ast-model-inputs-qualified.json.gz'
COMPILE_ONLY = execute.AUDIT / 'compile-only-inputs-qualified.json.gz'
MODEL_PATHS = tuple(dict.fromkeys((fixed.PATH, SAVED, AST_INPUT, COMPILE_ONLY, *fixed.MODEL_PATHS)))
PREMISES = tuple(dict.fromkeys(('operand_allocation.py', *fixed.PREMISES)))
LIMITS = dict(payload_import_closure_qualified=False, recursive_payload_closure_qualified=False,
              concrete_namespace_values_qualified=False, actual_exports_qualified=False,
              complete_source_allocation_qualified=False, default_reachability_qualified=False,
              effects_qualified=False, runtime_callable_identity_qualified=False,
              runtime_permission=False)
SCOPE = ('Model-to-original-site allocation only. Whole committed fixed, saved-program, '
         'AST and compile-only qualified models are shared premises and retain their '
         'complete source/data/name/namespace/export contracts and native identities. '
         'An independent complete lexical AST/token census supplies the compile/exec '
         'population; every exec has its exact direct compile operand. Importlib rows '
         'remain file candidates with no invented compile site or selected executable '
         'bytes. Literal saved modes, both transformed AST contexts and finite compile-only '
         'variants remain distinct. Per-row extraction is shared by assembly/review; '
         'the prior qualified model populations and whole-source lexical census supply '
         'separate membership evidence. No original source, recipe, model or programme '
         'executes. Payload imports, recursive expansion, concrete namespace values, '
         'actual exports, complete source/default/effect/runtime/custody and native/private '
         'gaps remain open; the original fixed/deferred records are not rewritten.')


def source_domains(models):
    graph = models[str(operands.INPUT)]['graph']
    inventory = models[str(operands.PATH)]['result']
    bounded.strict_equal(sorted(graph['sources']), inventory['source_population'])
    assert set(inventory['sources']) == set(inventory['sites']), 'positive-site source population'
    assert set(inventory['sites']) <= set(graph['sources'])
    compile_sites, exec_sites = {}, {}
    for name, source in graph['sources'].items():
        body = prepare.unblob(source['body'])
        rows = operands.ast_sites(body, name)
        bounded.strict_equal(rows, inventory['sites'].get(name, []))
        if rows:
            bounded.strict_equal(source, inventory['sources'][name])
        tokens = operands.token_sites(body)
        bounded.strict_equal(tokens, {(row['source']['line'], row['source']['column']):
            dict(operation=row['operation'], syntactic_role=row['syntactic_role']) for row in rows})
        tree = ast.parse(body, filename=name)
        calls = {(node.lineno, node.col_offset): node for node in ast.walk(tree)
                 if isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                 and node.func.id in ('compile', 'exec')}
        assert len(calls) == len(rows)
        for row in rows:
            site = (name, row['source']['line'], row['source']['column'])
            if row['operation'] == 'compile':
                compile_sites[site] = row
            else:
                call = calls[site[1:]]
                assert call.args and isinstance(call.args[0], ast.Call)
                operand = call.args[0]
                assert isinstance(operand.func, ast.Name) and operand.func.id == 'compile'
                exec_sites[site] = (name, operand.lineno, operand.col_offset)
    assert len(set(exec_sites.values())) == len(exec_sites), 'unique direct exec/compile pairing'
    assert set(exec_sites.values()) <= set(compile_sites)
    paired = set(exec_sites.values())
    assert paired == {site for site, row in compile_sites.items() if row['syntactic_role'] == 'exec-operand'}
    return graph, compile_sites, exec_sites


def fixed_entries(models, compile_sites):
    coverage = models[str(fixed.PATH)]['result']
    prior_rows = fixed.model_rows(models)
    templates = models[str(fixed.templates.PATH)]['result']['templates']
    result = {}
    for row in coverage['bindings']:
        family, index = row['model']['family'], row['model']['index']
        assert type(index) is int
        binding = prior_rows[family][index]
        bounded.strict_equal(row['binding_identity'], bounded.identity(binding))
        assert row['slot'] == fixed.slot(family, fixed.context(family, binding))
        contract = None
        if family == 'wrapper':
            definition = binding['definition']
            contract = templates[definition]['contract']
            if contract['kind'] == 'importlib file module':
                assert row['certificate']['logical_name'] is None
                site = None
            else:
                assert contract['kind'] == 'exec dictionary namespace'
                sites = [site for site, operand in compile_sites.items()
                         if site[0] == definition and operand['enclosing_name'] == 'module']
                assert len(sites) == 1, 'one exact wrapper compiler definition'
                site = sites[0]
        else:
            site = tuple(fixed.context(family, binding)[:3])
        identifier = 'fixed:' + row['slot']
        assert identifier not in result
        result[identifier] = dict(model=str(fixed.PATH), context=row['slot'],
            model_binding=bounded.identity(row), prior_binding=bounded.identity(binding),
            compile_site=list(site) if site else None,
            input=dict(kind='importlib file candidate' if site is None else 'source bytes',
                       certificate=copy.deepcopy(row['certificate'])),
            logical_name=row['certificate']['logical_name'],
            namespace_premise=dict(execution=copy.deepcopy(row['certificate']['namespace_premise']),
                                   wrapper_contract=copy.deepcopy(contract)))
    return result


def reconstructed_entries(models):
    result = {}
    saved = models[str(SAVED)]['result']
    contract = saved['source_contract']
    assert len(contract['modes']) == len(contract['logical_names'])
    assert len(contract['modes']) == len(set(contract['modes']))
    for mode, name in zip(contract['modes'], contract['logical_names'], strict=True):
        result['saved-program:' + mode] = dict(model=str(SAVED), context=mode,
            model_binding=bounded.identity(saved), prior_binding=bounded.identity(contract),
            compile_site=copy.deepcopy(saved['original_operand']['site']),
            input=dict(kind='reconstructed source bytes', identity=prepare.identity(prepare.unblob(saved['programme'])),
                       recipe=bounded.identity(saved['reconstruction'])), logical_name=name,
            namespace_premise=copy.deepcopy(contract))
    for index, row in enumerate(models[str(AST_INPUT)]['result']['bindings']):
        identifier = 'ast:' + row['source_path'] + ':' + str(row['original_operand']['site'])
        assert identifier not in result
        result[identifier] = dict(model=str(AST_INPUT), context=index,
            model_binding=bounded.identity(row), prior_binding=bounded.identity(row['recipe']),
            compile_site=copy.deepcopy(row['original_operand']['site']),
            input=dict(kind='transformed AST', source_path=row['source_path'],
                       original_tree=bounded.identity(row['original_tree']),
                       transformed_tree=bounded.identity(row['transformed_tree']),
                       edits=bounded.identity(row['edits'])), logical_name=row['recipe']['logical_name'],
            namespace_premise=copy.deepcopy(row['recipe']))
    for row in models[str(COMPILE_ONLY)]['result']['bindings']:
        identifier = 'compile-only:' + row['context']
        assert identifier not in result
        result[identifier] = dict(model=str(COMPILE_ONLY), context=row['context'],
            model_binding=bounded.identity(row), prior_binding=bounded.identity(row['original_operand']),
            compile_site=copy.deepcopy(row['original_operand']['site']),
            input=dict(kind='after-invocation reconstructed source bytes',
                       source_path=row['source_path'], identity=prepare.identity(prepare.unblob(row['payload'])),
                       role=row['source_role']), logical_name=row['logical_name'],
            namespace_premise=dict(namespace=None, result_use=row['site']['result_use'],
                source_role=row['source_role'], original_stdin_observed=False,
                original_compile_callable_qualified=False))
    return result


def entry_domains(models, compile_sites):
    fixed_rows, reconstructed = fixed_entries(models, compile_sites), reconstructed_entries(models)
    assert not set(fixed_rows) & set(reconstructed)
    covered = {tuple(row['compile_site']) for row in fixed_rows.values() if row['compile_site'] is not None}
    reconstructed_sites = {tuple(row['compile_site']) for row in reconstructed.values()}
    deferred = {tuple(row['site']) for row in models[str(fixed.PATH)]['result']['deferred']}
    assert reconstructed_sites == deferred, 'each prior deferred site has a qualified input model'
    assert not covered & deferred, 'disjoint fixed and reconstructed lexical roles'
    assert covered | reconstructed_sites == set(compile_sites), 'every original compiler site allocated'
    return fixed_rows | reconstructed


def assemble(models):
    _, compilers, executors = source_domains(models)
    entries = entry_domains(models, compilers)
    reverse = {compiler: executor for executor, compiler in executors.items()}
    rows = []
    for identifier, value in sorted(entries.items()):
        site = tuple(value['compile_site']) if value['compile_site'] is not None else None
        executor = reverse.get(site)
        rows.append(dict(identifier=identifier, **value, exec_site=list(executor) if executor else None))
    return dict(schema='fsmgen.operand_allocation.v1', owner=OWNER, scope=SCOPE, bindings=rows,
                lexical_compile_sites=[list(site) for site in sorted(compilers)],
                lexical_exec_pairs=[dict(exec_site=list(site), compile_site=list(executors[site]))
                                    for site in sorted(executors)],
                payload_closure_owner=OWNER.rsplit('.', 1)[0] + '.3', **LIMITS)


def review(value, models):
    assert value['schema'] == 'fsmgen.operand_allocation.v1' and value['owner'] == OWNER and value['scope'] == SCOPE
    assert all(value[key] is False for key in LIMITS), 'no borrowed namespace/source/effect/runtime authority'
    assert value['payload_closure_owner'] == OWNER.rsplit('.', 1)[0] + '.3'
    _, compilers, executors = source_domains(models)
    entries = entry_domains(models, compilers)
    identifiers = [row['identifier'] for row in value['bindings']]
    assert len(identifiers) == len(set(identifiers)) and set(identifiers) == set(entries), 'whole unique input model population'
    reverse = {compiler: executor for executor, compiler in executors.items()}
    for row in value['bindings']:
        expected = entries[row['identifier']]
        bounded.strict_equal({key: item for key, item in row.items() if key not in ('identifier', 'exec_site')}, expected)
        site = tuple(row['compile_site']) if row['compile_site'] is not None else None
        if site is None:
            assert row['exec_site'] is None, 'no invented importlib compile/exec site'
        else:
            assert site in compilers
            executor = reverse.get(site)
            bounded.strict_equal(row['exec_site'], list(executor) if executor else None)
            assert (executor is None) == (compilers[site]['syntactic_role'] == 'compile-only-operand')
    bounded.strict_equal(value['lexical_compile_sites'], [list(site) for site in sorted(compilers)])
    bounded.strict_equal(value['lexical_exec_pairs'], [dict(exec_site=list(site), compile_site=list(executors[site]))
                                                      for site in sorted(executors)])
    return dict(whole_model_site_allocation_qualified=True, original_programme_execution=False,
                payload_import_and_recursive_closure_qualified=False)


def controls(expected, models):
    result = []
    for label in ('omitted_input', 'duplicate_input', 'exchanged_bindings', 'wrong_model', 'wrong_context', 'wrong_compile_site',
                  'wrong_exec_site', 'changed_source', 'borrowed_input_role', 'wrong_name',
                  'wrong_namespace', 'omitted_lexical_site', 'borrowed_importlib_source',
                  'compile_only_exec', 'ast_borrowed_tree', 'saved_wrong_mode',
                  'borrowed_runtime', 'numeric_permission'):
        bad = copy.deepcopy(expected)
        row = bad['bindings'][0]
        if label == 'omitted_input': bad['bindings'].pop()
        elif label == 'duplicate_input': bad['bindings'].append(copy.deepcopy(row))
        elif label == 'exchanged_bindings':
            bad['bindings'][0]['identifier'], bad['bindings'][-1]['identifier'] = bad['bindings'][-1]['identifier'], bad['bindings'][0]['identifier']
        elif label == 'wrong_model': row['model'] = str(SAVED)
        elif label == 'wrong_context': row['context'] = 'borrowed context'
        elif label == 'wrong_compile_site': row['compile_site'] = ['other.py', 1, 0]
        elif label == 'wrong_exec_site': row['exec_site'] = ['other.py', 1, 0]
        elif label == 'changed_source': row['input']['transformed_tree']['sha256'] = '0' * 64
        elif label == 'borrowed_input_role': row['input']['kind'] = 'observed original executable bytes'
        elif label == 'wrong_name': row['logical_name'] = 'borrowed.py'
        elif label == 'wrong_namespace': row['namespace_premise']['namespace']['__name__'] = '__main__'
        elif label == 'omitted_lexical_site': bad['lexical_compile_sites'].pop()
        elif label == 'borrowed_importlib_source':
            next(item for item in bad['bindings'] if item['compile_site'] is None)['input']['kind'] = 'observed selected executable bytes'
        elif label == 'compile_only_exec':
            next(item for item in bad['bindings'] if item['identifier'].startswith('compile-only:'))['exec_site'] = ['other.py', 1, 0]
        elif label == 'ast_borrowed_tree':
            items = [item for item in bad['bindings'] if item['identifier'].startswith('ast:')]
            assert len(items) == 2
            items[0]['input']['transformed_tree'] = copy.deepcopy(items[1]['input']['transformed_tree'])
        elif label == 'saved_wrong_mode':
            items = [item for item in bad['bindings'] if item['identifier'].startswith('saved-program:')]
            assert len(items) > 1
            items[0]['logical_name'], items[1]['logical_name'] = items[1]['logical_name'], items[0]['logical_name']
        elif label == 'borrowed_runtime': bad['runtime_permission'] = True
        else: bad['runtime_permission'] = 0
        changes = fixed.caller.changes(expected, bad)
        assert changes, 'genuine candidate change'
        try:
            review(bad, models)
        except AssertionError as error:
            result.append(dict(label=label, changes=changes, candidate_identity=bounded.identity(bad),
                               refusal=str(error), prior_models_unchanged=True))
        else:
            raise AssertionError('changed operand allocation admitted: ' + label)
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw, references = {}, {}
    for path in MODEL_PATHS:
        name = str(path)
        reference = prerequisite.file_reference(AUTHORITY, name)
        body = prerequisite.read_reference(reference)
        assert body == execute.read(path), 'complete committed prior model: ' + name
        raw[name], references[name] = body, reference
    models = {name: json.loads(gzip.decompress(body)) for name, body in raw.items()}
    result = assemble(models)
    product = dict(result=result, review=review(result, models), controls=controls(result, models),
        inputs={name: dict(reference=references[name], body=prepare.blob(body)) for name, body in raw.items()},
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write:
        execute.save(PATH, product)
    else:
        bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Complete prior input models join every original compile/exec site and importlib candidate; genuine allocation controls refuse. Payload closure, concrete namespace values and original source/default/effect/runtime authority remain open.')
