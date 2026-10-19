"""Bind admission source inputs without replaying the original admission."""
import argparse
import ast
import copy
import gzip
import json
import posixpath
from pathlib import Path

import bounded_runtime_inventory as bounded
import direct_inputs as direct
import epoch_constraints as epoch
import execute
import operand_inventory as operands
import prepare
import prerequisite_inputs as prerequisite
import qualify_caller_modules as caller
import reader_tables as tables
import typed_callers as typed
import wrapper_templates as templates

AUTHORITY = prerequisite.AUTHORITY
PATH = execute.AUDIT / 'admission-inputs-qualified.json.gz'
OWNER = prerequisite.OWNER.rsplit('.', 1)[0] + '.4'
PREMISES = ('admission_inputs.py', *prerequisite.PREMISES)
LIMITS = dict(runtime_source_image_qualified=False, runtime_exports_qualified=False,
              helper_api_identity_qualified=False, semantic_outputs_qualified=False,
              default_reachability_qualified=False, effects_qualified=False, runtime_permission=False)
SCOPE = ('Complete original admission caller/plan/table/compile bytes, separate logical '
         'name, namespace/argv/import/stdout/proof/condition source bindings only. Whole '
         'table retention and AST/value/import/caller grammar are shared premises. '
         'Independent Git blob reads and native Path operations check bytes/paths. '
         'Source ordinary/same-volume/unchanged-image and proof/stdout predicates are '
         'retained contracts, never executed semantic truth. Physical image, original '
         'helper/API/export identities, default effects, private/native uncertainty and '
         'custody remain open. No original reader/module/factory/recipe/admission/cohort '
         'runs; all earlier failures, spent fixtures and unused slots retain.')


def source_contract(spec):
    """Check the explicit source predicates separately from value evaluation."""
    source = spec['operand']['enclosing_recipe']['text']
    function = ast.parse(source).body[0]
    assert isinstance(function, ast.FunctionDef) and function.name == 'fresh_admission'
    assert ast.dump(function.args) == ast.dump(ast.parse('def f(): pass').body[0].args)
    forms = {ast.dump(node) for node in ast.walk(function)}
    statements = (
        "root = PLAN['admission']",
        "names = git('ls-tree', '-r', '--name-only', PLAN['revision'], '--', root).decode().splitlines()",
        'sources = fixed(names)', "entry = root + '/verify.py'",
        "namespace = {'__name__': '__main__', '__file__': entry}",
        "module_names = {Path(name).stem for name in names if name.endswith('.py')} | {'capture'}",
        'prior = {name: sys.modules[name] for name in module_names if name in sys.modules}',
        'old_path, old_argv = sys.path[:], sys.argv[:]', 'terminal = io.StringIO()',
        'sys.modules.pop(name, None)', 'sys.path.insert(0, root)', 'sys.argv[:] = [entry]',
        "exec(compile(sources[entry], entry, 'exec'), namespace)",
        'sys.path[:] = old_path', 'sys.argv[:] = old_argv', 'sys.modules.update(prior)',
        "wanted = json.loads(sources[root + '/proof.json'])",
        "return dict(proof=pin(canonical(wanted)), namespace={name: pin(body) for name, body in sources.items()}, stdout=terminal.getvalue(), condition=PLAN['condition'])")
    predicates = (
        'all(Path(name).parent == Path(root) and stat.S_ISREG(Path(name).lstat().st_mode) '
        'and Path(name).stat().st_dev == Path.cwd().stat().st_dev and Path(name).read_bytes() == body '
        'for name, body in sources.items())',
        "same(namespace['result'], wanted) and terminal.getvalue() == namespace['SUCCESS'] "
        'and all(Path(name).read_bytes() == body for name, body in sources.items())',
        'contextlib.redirect_stdout(terminal)')
    for statement in statements:
        assert ast.dump(ast.parse(statement).body[0]) in forms, ('whole admission binding statement', statement)
    for predicate in predicates:
        assert ast.dump(ast.parse(predicate, mode='eval').body) in forms, ('whole admission predicate', predicate)
    assignments = {node.targets[0].id: node.value for node in function.body
                   if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name)}
    return assignments, dict(statements=list(statements), predicates=list(predicates),
                            recipe=spec['operand']['enclosing_recipe'])


def derive(retained, graph, whole):
    candidates = [table for table in retained['tables']
                  if table['spec']['operand']['enclosing_name'] == 'fresh_admission']
    assert len(candidates) == 1
    table = candidates[0]
    tables.review_table(table)
    spec = table['spec']
    assert spec['selector'] == 'admission'
    assignments, contract = source_contract(spec)
    env = dict(graph.environments[spec['caller']])
    plan = json.loads(prepare.unblob(spec['plan']))
    bounded.strict_equal(plan, env['PLAN'])
    assert plan['revision'] == spec['revision']
    root = graph.value(assignments['root'], env, spec['caller'])
    assert type(root) is str and root == spec['root']
    env['root'] = root
    entry = graph.value(assignments['entry'], env, spec['caller'])
    assert type(entry) is str and entry == root + '/verify.py'
    env['entry'] = entry
    namespace = graph.value(assignments['namespace'], env, spec['caller'])
    assert namespace == dict(__name__='__main__', __file__=entry)
    references = {key: table['descriptors'][name] for key, name in (
        ('entry', entry), ('proof', root + '/proof.json'), ('original_plan', root + '/plan.json'))}
    body = prerequisite.read_reference(references['entry'])
    assert body == prepare.unblob(whole['sources'][entry]['body']), 'actual table entry versus declared source image'
    modules = sorted({posixpath.splitext(posixpath.basename(name))[0]
                      for name in table['descriptors'] if name.endswith('.py')} | {'capture'})
    # Caller membership comes from the entire fixed source, independently of the saved spec.
    caller_body = prepare.unblob(whole['sources'][spec['caller']]['body']).decode()
    calls = [typed.dispatch.source(node, caller_body) for node in ast.walk(ast.parse(caller_body))
             if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == 'fresh_admission']
    assert calls and calls == spec['calls']
    return dict(schema='fsmgen.admission_source_inputs.v1', owner=OWNER, scope=SCOPE,
        table_spec=spec, table_identity=bounded.identity(table), table_members=sorted(table['descriptors']),
        contract=contract, callers=calls, plan=spec['plan'], references=references, input=prepare.blob(body),
        logical_name=entry, namespace=namespace, argv=[entry], import_path_first=root, cleared_modules=modules,
        stdout=dict(kind='exact', expression="terminal.getvalue() == namespace['SUCCESS']", export='SUCCESS'),
        required_exports=['SUCCESS', 'result'],
        proof_contract=dict(expression="same(namespace['result'], wanted)",
                            reference=references['proof'], semantic_truth_qualified=False),
        return_roles=dict(proof='pin(canonical(wanted))', namespace='all original sources, each pin(body)',
                          stdout='terminal.getvalue()', condition=plan['condition']),
        original_plan=prepare.blob(prerequisite.read_reference(references['original_plan'])),
        image_checks=dict(before=contract['predicates'][0], after='all(Path(name).read_bytes() == body for name, body in sources.items())',
                          physical_truth_qualified=False),
        source_image_revision=epoch.REVISION, source_allocation_owner=direct.ALLOCATION_OWNER,
        shared_premises=['complete retained table byte qualification', 'AST/value/import/namespace source grammar',
                        'declared source image and original helper/API identities'], **LIMITS)


def review(value, expected, retained):
    bounded.strict_equal(value, expected)
    table = next(row for row in retained['tables'] if row['spec'] == value['table_spec'])
    bounded.strict_equal(bounded.identity(table), value['table_identity'])
    body = prepare.unblob(value['input'])
    assert body == prerequisite.read_reference(value['references']['entry'])
    assert value['references']['entry']['revision'] == value['table_spec']['revision']
    plan = json.loads(prepare.unblob(value['plan']))
    native_entry = Path(plan['admission']) / 'verify.py'
    assert str(native_entry) == value['logical_name'], 'independent native Path entry'
    assert all(Path(name).parent == Path(plan['admission']) for name in value['table_members'])
    native_modules = sorted({Path(name).stem for name in table['descriptors'] if name.endswith('.py')} | {'capture'})
    assert native_modules == value['cleared_modules'], 'independent native Path module stems'
    assert value['namespace'] == dict(__name__='__main__', __file__=str(native_entry))
    assert value['argv'] == [str(native_entry)]
    assert all(value[name] is False for name in LIMITS)
    assert value['proof_contract']['semantic_truth_qualified'] is False
    assert value['image_checks']['physical_truth_qualified'] is False
    return dict(entry=prepare.identity(body), native_entry=str(native_entry), native_modules=native_modules,
                proof=prepare.identity(prerequisite.read_reference(value['references']['proof'])),
                original_plan=prepare.identity(prerequisite.read_reference(value['references']['original_plan'])),
                original_execution=False)


def controls(expected, retained):
    outcomes = []
    for label in ('revision', 'entry', 'input', 'namespace', 'argv', 'module', 'stdout', 'proof',
                  'member', 'caller', 'condition', 'return_role', 'image', 'progress', 'permission'):
        bad = copy.deepcopy(expected)
        if label == 'revision': bad['references']['entry']['revision'] = epoch.REVISION
        elif label == 'entry': bad['logical_name'] = bad['import_path_first'] + '/later.py'
        elif label == 'input': bad['input'] = prepare.blob(b'other admitted source')
        elif label == 'namespace': bad['namespace']['__name__'] = 'later_progress'
        elif label == 'argv': bad['argv'] = ['later.py']
        elif label == 'module': bad['cleared_modules'].remove('capture')
        elif label == 'stdout': bad['stdout']['kind'] = 'suffix'
        elif label == 'proof': bad['proof_contract']['reference']['path'] = bad['logical_name']
        elif label == 'member': bad['table_members'].pop()
        elif label == 'caller': bad['callers'].pop()
        elif label == 'condition': bad['return_roles']['condition'] = 'later execution currency'
        elif label == 'return_role': bad['return_roles']['namespace'] = 'entry only'
        elif label == 'image': bad['image_checks']['physical_truth_qualified'] = True
        elif label == 'progress': bad['semantic_outputs_qualified'] = True
        else: bad['runtime_permission'] = 0
        changes = caller.changes(expected, bad)
        assert changes
        try: review(bad, expected, retained)
        except AssertionError as error:
            outcomes.append(dict(label=label, changes=changes, candidate_identity=bounded.identity(bad),
                                 refusal=str(error), kind='caught admission source/data binding refusal; no original native result'))
        else: raise AssertionError('changed admission input admitted: ' + label)
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
        try: review(bad, expected, retained)
        except AssertionError as error: assert str(error) == outcome['refusal']
        else: raise AssertionError('retained admission input candidate admitted')
    return outcomes


def source_controls(spec):
    """Alter the original source, rather than only the derived record."""
    outcomes = []
    for before, after in (
        ("PLAN['admission']", "PLAN['cause']"),
        ('sources[entry]', 'sources[root]'),
        ("'__name__': '__main__'", "'__name__': 'later'"),
        ("namespace['SUCCESS']", "namespace['result']"),
        ('stat.S_ISREG', 'stat.S_ISDIR'),
        ("condition=PLAN['condition']", "condition='later progress'")):
        bad = copy.deepcopy(spec)
        recipe = bad['operand']['enclosing_recipe']
        assert recipe['text'].count(before) == 1
        recipe['text'] = recipe['text'].replace(before, after)
        ast.parse(recipe['text'])  # Every intervention remains valid Python.
        try: source_contract(bad)
        except AssertionError as error:
            outcomes.append(dict(before=before, after=after, recipe=recipe,
                                 refusal=str(error), kind='caught changed original source contract; no execution'))
        else: raise AssertionError('changed original admission source admitted')
    return outcomes


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw = execute.read(tables.PATH)
    assert raw == epoch.read(AUTHORITY, str(tables.PATH)), 'whole committed table qualification'
    retained = json.loads(gzip.decompress(raw))
    contract_raw = execute.read(templates.PATH)
    assert contract_raw == epoch.read(typed.AUTHORITY, str(templates.PATH))
    graph = typed.Graph(json.loads(gzip.decompress(contract_raw))['result']['templates'])
    whole = json.loads(prepare.encoded(graph.build()))
    fixed_raw = execute.read(operands.INPUT)
    assert fixed_raw == epoch.read(operands.AUTHORITY, str(operands.INPUT))
    bounded.strict_equal(whole['sources'], json.loads(gzip.decompress(fixed_raw))['graph']['sources'])
    expected = json.loads(prepare.encoded(derive(retained, graph, whole)))
    product = dict(result=expected, native=review(expected, expected, retained), controls=controls(expected, retained),
        source_controls=source_controls(expected['table_spec']),
        table_input=dict(revision=AUTHORITY, identity=prepare.identity(raw)), native_interpreter=whole['language'],
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write: execute.save(PATH, product)
    else: bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Admission table/entry/name/namespace/argv/import/stdout/proof/condition source bindings agree; semantic outputs, physical image, default effects and all original execution remain unqualified.')
