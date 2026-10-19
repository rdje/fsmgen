"""Bind prerequisite reader source roles without running original readers."""
import argparse
import ast
import copy
import gzip
import hashlib
import json
import posixpath

import bounded_runtime_inventory as bounded
import direct_inputs as direct
import epoch_constraints as epoch
import execute
import operand_inventory as operands
import prepare
import qualify_caller_modules as caller
import reader_tables as tables
import typed_callers as typed
import wrapper_templates as templates

AUTHORITY = '533a054f339b9f4ad105f34cb9b41fd8f6f7e3c1'
PATH = execute.AUDIT / 'prerequisite-inputs-qualified.json.gz'
OWNER = tables.OWNER.rsplit('.', 1)[0] + '.2'
PREMISES = ('prerequisite_inputs.py', *tables.PREMISES)
LIMITS = dict(runtime_source_image_qualified=False, runtime_exports_qualified=False,
              helper_api_identity_qualified=False, semantic_outputs_qualified=False,
              default_reachability_qualified=False, effects_qualified=False, runtime_permission=False)
SCOPE = ('Complete source-derived prerequisite context/cause/consumer caller, parameter, '
         'table, entry payload, filename, namespace/argv/import/stdout and capture/proof/scope '
         'bindings. Qualified whole tables are an explicit shared premise. Source-value, '
         'namespace and finite caller grammar and the declared source image remain shared '
         'premises; native Path and separate Git blob reads check values/bytes. Retained '
         'conditions are source/data contracts, not proof of original execution or semantic '
         'outputs. Context caught-library controls never become native exits. Actual source '
         'image, helper/API/export identity, default effects, private/native uncertainty and '
         'custody remain open. No original reader, module, factory, recipe or cohort runs; '
         'all failures, spent fixtures and unused slots retain.')


def file_reference(revision, path):
    tables.safe_name(path)
    raw = tables.git('ls-tree', '-l', '-z', revision, '--', path)
    entries = raw.rstrip(b'\0').split(b'\0')
    assert len(entries) == 1
    header, name = entries[0].split(b'\t', 1)
    mode, kind, oid, size = header.decode().split()
    assert name.decode() == path and kind == 'blob' and mode in ('100644', '100755') and size.isdecimal()
    return dict(revision=revision, path=path, mode=mode, oid=oid, bytes=int(size),
                retention_contract='fsmgen_required_history')


def read_reference(reference):
    body = tables.git('show', reference['revision'] + ':' + reference['path'])
    assert len(body) == reference['bytes']
    assert hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == reference['oid']
    independent = tables.git('cat-file', 'blob', reference['oid'])
    assert independent == body, 'whole independent actual blob bytes'
    if 'sha256' in reference:
        assert hashlib.sha256(body).hexdigest() == reference['sha256']
    return body


def source_contract(spec):
    source = spec['operand']['enclosing_recipe']['text']
    tree = ast.parse(source)
    function = tree.body[0]
    assert isinstance(function, ast.FunctionDef) and function.name == 'reader'
    forms = {ast.dump(node) for node in ast.walk(function)}
    required = (
        "declarations = read('reader-contracts.json')", 'declaration = declarations[role]',
        'root = PLAN[role]', 'bodies = fixed(entries)', "entry = declaration['command'][-1]",
        "scope = {'__name__': '__main__', '__file__': entry}", "sys.path.insert(0, root)",
        'sys.argv[:] = [entry]', "exec(compile(bodies[entry], entry, 'exec'), scope)",
        "names = {Path(name).stem for name in entries if name.endswith('.py')} | {'capture'}",
        'sys.path[:] = previous_path', 'sys.argv[:] = previous_argv', 'sys.modules.update(previous)',
        'sys.modules.pop(name, None)', 'terminal = io.StringIO()', "results = scope['result_reader']",
    )
    for statement in required:
        assert ast.dump(ast.parse(statement).body[0]) in forms, ('complete source binding statement', statement)
    branches = [node for node in ast.walk(function) if isinstance(node, ast.If)
                and ast.dump(node.test) == ast.dump(ast.parse("role == 'context'", mode='eval').body)]
    assert len(branches) == 1 and branches[0].orelse
    context_branch = branches[0]
    assert len(context_branch.orelse) == 1
    assert ast.dump(context_branch.orelse[0]) == ast.dump(ast.parse("value = scope['result']").body[0])
    slots = set()
    for node in ast.walk(context_branch):
        if isinstance(node, ast.Subscript) and isinstance(node.value, ast.Name) and node.value.id == 'scope':
            slots.add(ast.literal_eval(node.slice))
    assert slots == {'source_models', 'result_reader', 'load', 'check', 'controls', 'result'}
    comprehensions = [node for node in ast.walk(context_branch) if isinstance(node, ast.DictComp)]
    assert len(comprehensions) == 1 and len(comprehensions[0].generators) == 1
    generator = comprehensions[0].generators[0]
    assert not generator.ifs and not generator.is_async and ast.unparse(generator.target) == 'mode'
    assert ast.unparse(comprehensions[0].key) == 'mode'
    assert ast.dump(comprehensions[0].value) == ast.dump(ast.parse(
        "scope['load'](results['CAPTURE'] / (mode + '.json'))", mode='eval').body)
    modes = list(ast.literal_eval(generator.iter))
    assert modes == ['ordinary', 'storable', 'controls']
    assert ast.dump(ast.parse("execution = scope['load'](results['CAPTURE'] / 'execution.json')").body[0]) in forms
    assert ast.dump(ast.parse("with contextlib.redirect_stdout(terminal):\n    pass").body[0].items[0].context_expr) in forms
    predicates = (
        "same(value, json.loads(bodies[declaration['proof']]))",
        'terminal.getvalue().endswith(SUFFIXES[role])',
        'terminal.getvalue() == SUFFIXES[role]',
        "declaration['condition'] == json.loads(bodies[declaration['scope']])['condition']",
    )
    for expression in predicates:
        assert ast.dump(ast.parse(expression, mode='eval').body) in forms
    later = [node for node in ast.walk(function) if isinstance(node, ast.If)
             and ast.dump(node.test) == ast.dump(ast.parse("role != 'context'", mode='eval').body)]
    assert len(later) == 1
    later_forms = {ast.dump(node) for statement in later[0].body for node in ast.walk(statement)}
    assert all(ast.dump(ast.parse(expression, mode='eval').body) in later_forms for expression in predicates[2:])
    return dict(statements=list(required), required_slots=sorted(slots), modes=modes,
                predicates=list(predicates), recipe=spec['operand']['enclosing_recipe'])


def derive(retained, graph, whole):
    candidates = [table for table in retained['tables'] if table['spec']['operand']['enclosing_name'] == 'reader']
    assert {table['spec']['selector'] for table in candidates} == {'context', 'cause', 'consumer'}
    origins = {table['spec']['caller'] for table in candidates}
    assert len(origins) == 1
    origin = next(iter(origins))
    model_env = graph.environments[origin]
    base = model_env['BASE']
    assert isinstance(base, typed.SourcePath)
    declaration_path = str(base) + '/reader-contracts.json'
    declaration_ref = file_reference(epoch.REVISION, declaration_path)
    declaration_body = read_reference(declaration_ref)
    declarations = json.loads(declaration_body)
    assert set(declarations) == {'context', 'cause', 'consumer'}
    originals = {name: prepare.unblob(row['body']) for name, row in whole['sources'].items()}
    rows = []
    for table in candidates:
        tables.review_table(table)
        spec = table['spec']
        contract = source_contract(spec)
        role, root = spec['selector'], spec['root']
        declaration = declarations[role]
        entry = declaration['command'][-1]
        assert declaration['command'] == ['python3', '-B', root + '/verify.py']
        proof = root + ('/proofs.json' if role == 'context' else '/proof.json')
        scope = root + ('/scope.txt' if role == 'context' else '/plan.json')
        assert declaration['proof'] == proof and declaration['scope'] == scope
        references = {key: table['descriptors'][path] for key, path in (
            ('entry', entry), ('proof', proof), ('scope', scope))}
        entry_body, scope_body = read_reference(references['entry']), read_reference(references['scope'])
        assert entry_body == originals[entry], 'actual table entry source versus declared image namespace model'
        namespace = dict(__name__='__main__', __file__=entry)
        modules = sorted({posixpath.splitext(posixpath.basename(name))[0]
                          for name in table['descriptors'] if name.endswith('.py')} | {'capture'})
        row = dict(role=role, caller=origin, callers=spec['calls'], parameter=dict(role=role),
            table_spec=spec, table_identity=bounded.identity(table), table_members=sorted(table['descriptors']),
            contract=contract, declaration=declaration, references=references,
            input=prepare.blob(entry_body), logical_name=entry, namespace=namespace,
            argv=[entry], import_path_first=root, cleared_modules=modules,
            stdout=dict(kind='suffix' if role == 'context' else 'exact', value=model_env['SUFFIXES'][role]),
            scope=prepare.blob(scope_body), semantic_outputs_qualified=False,
            source_image_revision=epoch.REVISION, runtime_exports_qualified=False)
        if role == 'context':
            env = graph.environments[entry]
            results = env['result_reader']
            capture_origin = next(name for name, value in graph.environments.items() if value is results)
            capture = results['CAPTURE']
            assert isinstance(capture, typed.SourcePath)
            native = typed.native_path(capture.trace, originals)
            assert str(native) == str(capture)
            paths = [str(native / (mode + '.json')) for mode in contract['modes']]
            paths.append(str(native / 'execution.json'))
            row.update(required_exports={name: typed.datum(env[name]) for name in
                ('source_models', 'load', 'check', 'controls')},
                capture=dict(namespace_origin=capture_origin, path=typed.datum(capture),
                    inputs=[file_reference(epoch.REVISION, path) for path in paths],
                    modes=contract['modes'], condition=declaration['condition'],
                    role='retained capture inputs and caught-library-control source contract; no new native exits'),
                required_namespace_slot='result_reader', condition_kind='caught library refusal source contract')
        else:
            assert declaration['condition'] == json.loads(scope_body)['condition']
            row.update(required_exports=['result'], capture=None, required_namespace_slot='result',
                       condition_kind='exact original plan condition and terminal source contract')
        rows.append(row)
    return dict(schema='fsmgen.prerequisite_reader_inputs.v1', owner=OWNER, revision=epoch.REVISION,
        declaration=dict(reference=declaration_ref, body=prepare.blob(declaration_body)),
        bindings=rows, scope=SCOPE,
        shared_premises=['complete retained table byte qualification', 'AST/value/import/namespace/finite source grammar',
                        'declared original source image and original helper/API identities'], **LIMITS)


def review(value, expected, retained, originals):
    bounded.strict_equal(value, expected)
    assert {row['role'] for row in value['bindings']} == {'context', 'cause', 'consumer'}
    native = []
    for row in value['bindings']:
        table = next(table for table in retained['tables'] if table['spec'] == row['table_spec'])
        bounded.strict_equal(bounded.identity(table), row['table_identity'])
        entry = row['logical_name']
        body = prepare.unblob(row['input'])
        assert body == read_reference(row['references']['entry'])
        assert row['namespace'] == dict(__name__='__main__', __file__=entry) and row['argv'] == [entry]
        assert row['semantic_outputs_qualified'] is False and row['runtime_exports_qualified'] is False
        capture_bytes = []
        if row['capture']:
            path = row['capture']['path']
            assert path['kind'] == 'Path'
            actual = typed.native_path(path['trace'], originals)
            assert str(actual) == path['value']
            for reference in row['capture']['inputs']:
                capture_body = read_reference(reference)
                capture_bytes.append(dict(reference=reference, identity=prepare.identity(capture_body)))
        native.append(dict(role=row['role'], entry_reference=row['references']['entry'],
                           input_identity=prepare.identity(body), capture_bytes=capture_bytes,
                           original_execution=False))
    return native


def controls(expected, retained, originals):
    outcomes = []
    for label in ('role', 'revision', 'member', 'input', 'namespace', 'argv', 'modules',
                  'capture', 'proof', 'condition', 'caller', 'omission', 'progress', 'typed_permission'):
        bad = copy.deepcopy(expected)
        row = next(row for row in bad['bindings'] if row['role'] == 'context')
        if label == 'role': row['role'] = 'consumer'
        elif label == 'revision': row['references']['entry']['revision'] = epoch.REVISION
        elif label == 'member': row['table_members'].pop()
        elif label == 'input': row['input'] = prepare.blob(b'other entry source')
        elif label == 'namespace': row['namespace']['__name__'] = 'later_progress'
        elif label == 'argv': row['argv'] = ['later.py']
        elif label == 'modules': row['cleared_modules'].remove('capture')
        elif label == 'capture': row['capture']['path']['value'] = row['logical_name']
        elif label == 'proof': row['references']['proof']['path'] = row['logical_name']
        elif label == 'condition': row['declaration']['condition'] = 'native control exits qualified'
        elif label == 'caller': row['callers'].pop()
        elif label == 'omission': bad['bindings'].pop()
        elif label == 'progress': bad['semantic_outputs_qualified'] = True
        else: bad['runtime_permission'] = 0
        changes = caller.changes(expected, bad)
        assert changes
        try: review(bad, expected, retained, originals)
        except AssertionError as error:
            outcomes.append(dict(label=label, changes=changes, candidate_identity=bounded.identity(bad),
                                 refusal=str(error), kind='caught source/data binding refusal; no original native result'))
        else: raise AssertionError('changed prerequisite input admitted: ' + label)
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
        try: review(bad, expected, retained, originals)
        except AssertionError as error: assert str(error) == outcome['refusal']
        else: raise AssertionError('retained prerequisite candidate admitted')
    return outcomes


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw = execute.read(tables.PATH)
    assert raw == epoch.read(AUTHORITY, str(tables.PATH)), 'whole committed table qualification'
    retained = json.loads(gzip.decompress(raw))
    assert retained['owner'] == tables.OWNER and all(retained[key] is False for key in tables.LIMITS)
    contract_raw = execute.read(templates.PATH)
    assert contract_raw == epoch.read(typed.AUTHORITY, str(templates.PATH))
    contracts = json.loads(gzip.decompress(contract_raw))['result']['templates']
    graph = typed.Graph(contracts)
    whole = json.loads(prepare.encoded(graph.build()))
    fixed = json.loads(gzip.decompress(execute.read(operands.INPUT)))['graph']
    assert execute.read(operands.INPUT) == epoch.read(operands.AUTHORITY, str(operands.INPUT))
    bounded.strict_equal(whole['sources'], fixed['sources'])
    expected = json.loads(prepare.encoded(derive(retained, graph, whole)))
    originals = {name: prepare.unblob(row['body']) for name, row in whole['sources'].items()}
    product = dict(result=expected, native=review(expected, expected, retained, originals),
        controls=controls(expected, retained, originals), table_input=dict(revision=AUTHORITY, identity=prepare.identity(raw)),
        native_interpreter=whole['language'], programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write: execute.save(PATH, product)
    else: bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Complete prerequisite role/table/entry/namespace/argv/import and capture/proof/scope source bindings agree; semantic outputs, default effects and all original execution remain unqualified.')
