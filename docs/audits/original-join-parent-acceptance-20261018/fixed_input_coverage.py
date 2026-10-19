"""Join fixed wrapper/direct/reader input classes without original execution."""
import argparse
import ast
import copy
import gzip
import json
import sys

import bounded_runtime_inventory as bounded
import direct_inputs as direct
import epoch_constraints as epoch
import execute
import operand_inventory as operands
import parameter_input_coverage as parameter
import prepare
import prerequisite_inputs as prerequisite
import qualify_caller_modules as caller
import typed_callers as typed
import wrapper_templates as templates

AUTHORITY = '247f27e4de658b407e66dab65c3d6797ba2f399d'
PATH = execute.AUDIT / 'fixed-input-coverage-qualified.json.gz'
OWNER = parameter.OWNER.rsplit('.', 2)[0] + '.5'
RECONSTRUCTION = OWNER.rsplit('.', 2)[0]
MODEL_PATHS = (templates.PATH, typed.PATH, direct.PATH, parameter.PATH, operands.INPUT, operands.PATH)
PREMISES = tuple(dict.fromkeys(('fixed_input_coverage.py', *parameter.PREMISES)))
LIMITS = dict(runtime_source_image_qualified=False, runtime_callable_identity_qualified=False,
              loader_selected_bytes_qualified=False, target_exports_qualified=False,
              complete_source_allocation_qualified=False, default_reachability_qualified=False,
              effects_qualified=False, runtime_permission=False)
SCOPE = ('Complete fixed-graph wrapper/direct/reader source-input allocation only. '
         'Prior qualified templates, typed contexts, direct inputs and parameter joins '
         'are shared premises. Whole AST/token compile-site enumeration, fixed wrapper '
         'routes, native Path traces and versioned Git blobs check the combined relation. '
         'Each payload retains its revision/path/object/byte identity; equal filenames '
         'never replace distinct source versions. File reads are conditional original '
         'image inputs. Importlib rows remain file candidates, not observed selected '
         'source/bytecode. Declared namespaces, names, typed arguments and export premises '
         'retain through whole model identities. Saved-program, transformed-AST and '
         'syntactic compile-only candidates have explicit reconstruction owners. '
         'AST/value/import/caller grammar, Git store/protocol/hashes and original helper/API '
         'identities remain shared premises. Physical/cache/loader/export/default/effect/'
         'runtime/custody and native/private gaps remain open. No original source, reader, '
         'factory, recipe or cohort executes.')


def site_key(name, site):
    return (name, site['source']['line'], site['source']['column'])


def slot(family, context):
    return family + ':' + bounded.identity(context)['sha256']


def domains(fixed, inventory, contracts):
    all_sites, module_sites = {}, {}
    for name, rows in inventory['sites'].items():
        body = prepare.unblob(fixed['sources'][name]['body'])
        # The existing independent token census and whole AST inventory must
        # still agree on every compile/exec member, including deferred inputs.
        actual = operands.ast_sites(body, name)
        bounded.strict_equal(actual, rows)
        token = operands.token_sites(body)
        assert {(row['source']['line'], row['source']['column']) for row in rows} == set(token)
        for row in rows:
            if row['operation'] != 'compile': continue
            identity = site_key(name, row)
            assert identity not in all_sites
            all_sites[identity] = row
            if row['enclosing_name'] == 'module': module_sites[identity] = row
    byte_definitions = {name for name, row in contracts.items()
                        if row['contract']['kind'] == 'exec dictionary namespace'}
    assert {identity[0] for identity in module_sites} == byte_definitions
    direct_sites = {site_key(row['caller'], row['site']): row for row in direct.selected(inventory)}
    reader_sites = parameter.lexical_domains(fixed)
    readers = {identity[:3] for identity in reader_sites}
    assert not (set(module_sites) & set(direct_sites) or set(module_sites) & readers or set(direct_sites) & readers)
    covered = set(module_sites) | set(direct_sites) | readers
    deferred = []
    for identity in sorted(set(all_sites) - covered):
        row = all_sites[identity]
        expression = ast.parse(row['expressions']['input']['text'], mode='eval').body
        if row['syntactic_role'] == 'compile-only-operand':
            kind, owner = 'syntactic compile-only candidate; use qualification pending', RECONSTRUCTION + '.5'
        elif isinstance(expression, ast.Subscript) and isinstance(expression.slice, ast.Constant) and expression.slice.value == 'complete_program':
            kind, owner = 'saved complete-program reconstruction pending', RECONSTRUCTION + '.3'
        else:
            assert isinstance(expression, ast.Call) and ast.unparse(expression.func) == 'ast.fix_missing_locations'
            kind, owner = 'AST-transformed reconstruction pending', RECONSTRUCTION + '.4'
        deferred.append(dict(site=list(identity), kind=kind, owner=owner, operand=row))
    expected = {}
    for route in fixed['wrappers']:
        identity = slot('wrapper', route)
        assert identity not in expected
        expected[identity] = ('wrapper', route)
    for identity in sorted(direct_sites): expected[slot('direct', list(identity))] = ('direct', list(identity))
    for identity in sorted(reader_sites): expected[slot('reader', list(identity))] = ('reader', list(identity))
    return expected, deferred


def model_rows(models):
    return {'wrapper': models[str(typed.PATH)]['result']['bindings'],
            'direct': models[str(direct.PATH)]['result']['bindings'],
            'reader': models[str(parameter.PATH)]['result']['bindings']}


def context(family, row):
    if family == 'wrapper': return row['route']
    if family == 'direct': return list(site_key(row['caller'], row['site']))
    assert family == 'reader'
    return row['site']


def certificate(family, row, fixed, contracts, originals, cache):
    """Bind byte authority separately from logical filenames and execution premises."""
    if family == 'wrapper':
        route = row['route']
        origin = route['namespace_caller'][0] if route['namespace_caller'] else route['caller']
        definition = fixed['exports'][origin]['module']['declaration'][0]
        assert definition == row['definition']
        contract = contracts[definition]['contract']
        assert set(row['arguments']) == set(contract['parameters'])
        argument = row['arguments']['path']
        assert argument['kind'] == 'Path'
        native_path = typed.native_path(argument['trace'], originals)
        path = str(native_path)
        assert path == argument['value'] == route['target'] == row['source_candidate']['path']
        assert row['namespace_name'] == route['module_name'] and row['return_kind'] == contract['return_kind']
        assert row['runtime_payload_qualified'] is False
        if contract['kind'] == 'exec dictionary namespace':
            assert row['logical_name'] == path and row['input_expression'] == 'path.read_bytes()'
            authority = 'read_bytes under original source-image premise'
        else:
            assert contract['kind'] == 'importlib file module'
            assert row['logical_name'] is None and row['input_expression'] is None
            assert row['arguments']['name'] == dict(kind='str', value=route['module_name'])
            authority = 'importlib file candidate; selected executable bytes unqualified'
        revision, body = epoch.REVISION, prepare.unblob(row['source_candidate']['body'])
        namespace = dict(declared_name=row['namespace_name'], file_field_expression=row['file_field_expression'],
                         return_kind=row['return_kind'], actual_exports_qualified=False)
        logical = row['logical_name']
    elif family == 'direct':
        revision, path, body = row['revision'], row['path']['value'], prepare.unblob(row['payload'])
        assert row['target_exports_qualified'] is False
        if row['kind'] == 'file':
            assert row['path']['kind'] == 'Path' and revision == epoch.REVISION
            assert str(typed.native_path(row['path']['trace'], originals)) == path == row['logical_name']
            authority = 'read_bytes under original source-image premise'
        else:
            assert row['kind'] == 'fixed Git' and row['path']['kind'] == 'str'
            assert revision == json.loads(prepare.unblob(row['helper']['plan']))['revision']
            authority = 'whole source-selected plan-revision Git blob'
        namespace, logical = row['namespace'], row['logical_name']
    else:
        assert family == 'reader'
        binding = row['binding']
        reference = binding['references']['entry']
        revision, path, body = reference['revision'], reference['path'], prepare.unblob(binding['input'])
        assert revision == binding['table_spec']['revision'] and path == binding['logical_name']
        namespace, logical = binding['namespace'], binding['logical_name']
        authority = 'whole source-selected reader-table entry Git blob'
    identity = (revision, path)
    if identity not in cache:
        reference = prerequisite.file_reference(revision, path)
        cache[identity] = (reference, prerequisite.read_reference(reference))
    reference, native_body = cache[identity]
    assert body == native_body, 'whole actual versioned source bytes'
    if revision == epoch.REVISION:
        assert body == originals[path]
    return dict(reference=reference, payload=prepare.identity(body), authority=authority,
                logical_name=logical, namespace_premise=namespace, runtime_input_observed=False)


def assemble(models, fixed, inventory, contracts, originals):
    expected, deferred = domains(fixed, inventory, contracts)
    rows, cache = [], {}
    for family, bindings in model_rows(models).items():
        for index, binding in enumerate(bindings):
            rows.append(dict(slot=slot(family, context(family, binding)),
                model=dict(family=family, index=index), binding_identity=bounded.identity(binding),
                certificate=certificate(family, binding, fixed, contracts, originals, cache)))
    variants = {prepare.encoded(row['certificate']['reference']): row['certificate']['reference'] for row in rows}
    return dict(schema='fsmgen.fixed_input_coverage.v1', owner=OWNER, scope=SCOPE,
        bindings=rows, deferred=deferred, payload_variants=[variants[key] for key in sorted(variants)],
        source_allocation_owner=direct.ALLOCATION_OWNER, **LIMITS)


def review(value, models, fixed, inventory, contracts, originals):
    assert value['schema'] == 'fsmgen.fixed_input_coverage.v1' and value['owner'] == OWNER and value['scope'] == SCOPE
    assert value['source_allocation_owner'] == direct.ALLOCATION_OWNER
    assert all(value[key] is False for key in LIMITS), 'no borrowed source/loader/export/runtime progress'
    expected, deferred = domains(fixed, inventory, contracts)
    assigned = [row['slot'] for row in value['bindings']]
    assert len(assigned) == len(set(assigned)) and set(assigned) == set(expected), 'complete unique fixed input allocation'
    bounded.strict_equal(value['deferred'], deferred)
    rows, cache, variants = model_rows(models), {}, {}
    for row in value['bindings']:
        family, wanted = expected[row['slot']]
        assert row['model']['family'] == family, 'input-class/model allocation'
        index = row['model']['index']
        assert type(index) is int and 0 <= index < len(rows[family])
        binding = rows[family][index]
        bounded.strict_equal(context(family, binding), wanted)
        bounded.strict_equal(row['binding_identity'], bounded.identity(binding))
        actual = certificate(family, binding, fixed, contracts, originals, cache)
        bounded.strict_equal(row['certificate'], actual)
        variants[prepare.encoded(actual['reference'])] = actual['reference']
    bounded.strict_equal(value['payload_variants'], [variants[key] for key in sorted(variants)])
    return dict(qualified_static_inputs=True, runtime_input_observed=False,
                native_references=[cache[key][0] for key in sorted(cache)])


def controls(expected, models, fixed, inventory, contracts, originals):
    outcomes = []
    for label in ('omission', 'duplicate', 'permuted_context', 'wrong_class', 'wrong_binding',
                  'wrong_source', 'wrong_revision', 'wrong_namespace', 'wrong_authority',
                  'lost_variant', 'deferred_owner', 'loader_progress', 'typed_permission'):
        bad = copy.deepcopy(expected)
        row = bad['bindings'][0]
        if label == 'omission': bad['bindings'].pop()
        elif label == 'duplicate': bad['bindings'].append(copy.deepcopy(row))
        elif label == 'permuted_context':
            bad['bindings'][0]['slot'], bad['bindings'][1]['slot'] = bad['bindings'][1]['slot'], bad['bindings'][0]['slot']
        elif label == 'wrong_class': row['model']['family'] = 'direct'
        elif label == 'wrong_binding': row['model']['index'] = (row['model']['index'] + 1) % len(models[str(typed.PATH)]['result']['bindings'])
        elif label == 'wrong_source': row['certificate']['payload']['sha256'] = '0' * 64
        elif label == 'wrong_revision': row['certificate']['reference']['revision'] = AUTHORITY
        elif label == 'wrong_namespace': row['certificate']['namespace_premise']['declared_name'] = '__main__'
        elif label == 'wrong_authority': row['certificate']['authority'] = 'observed selected executable source'
        elif label == 'lost_variant': bad['payload_variants'].pop()
        elif label == 'deferred_owner': bad['deferred'][0]['owner'] = OWNER
        elif label == 'loader_progress': bad['loader_selected_bytes_qualified'] = True
        else: bad['runtime_permission'] = 0
        changes = caller.changes(expected, bad)
        assert changes
        try: review(bad, models, fixed, inventory, contracts, originals)
        except AssertionError as error:
            outcomes.append(dict(label=label, changes=changes, candidate_identity=bounded.identity(bad),
                refusal=str(error), prior_model_inputs_unchanged=True,
                kind='caught static cross-class binding refusal; no original native exit'))
        else: raise AssertionError('changed fixed input allocation admitted: ' + label)
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
        try: review(bad, models, fixed, inventory, contracts, originals)
        except AssertionError as error: assert str(error) == outcome['refusal']
        else: raise AssertionError('retained fixed input allocation admitted')
    return outcomes


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw = {str(path): execute.read(path) for path in MODEL_PATHS}
    for path, body in raw.items(): assert body == epoch.read(AUTHORITY, path), 'whole committed input: ' + path
    models = {path: json.loads(gzip.decompress(body)) for path, body in raw.items()}
    fixed, inventory = models[str(operands.INPUT)]['graph'], models[str(operands.PATH)]['result']
    contracts = models[str(templates.PATH)]['result']['templates']
    for path, limits in ((typed.PATH, typed.LIMITS), (direct.PATH, direct.LIMITS), (parameter.PATH, parameter.LIMITS)):
        assert all(models[str(path)]['result'][key] is False for key in limits)
    originals = {name: prepare.unblob(row['body']) for name, row in fixed['sources'].items()}
    result = json.loads(prepare.encoded(assemble(models, fixed, inventory, contracts, originals)))
    product = dict(result=result, native=review(result, models, fixed, inventory, contracts, originals),
        controls=controls(result, models, fixed, inventory, contracts, originals),
        inputs={path: dict(revision=AUTHORITY, identity=prepare.identity(body)) for path, body in raw.items()},
        native_python=dict(implementation=sys.implementation.name, version=list(sys.version_info)),
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write: execute.save(PATH, product)
    else: bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Fixed wrapper/direct/reader input classes and versioned payload variants join completely; native source/Path checks and genuine cross-class controls agree. Loader-selected bytes, deferred reconstruction and all original execution remain unqualified.')
