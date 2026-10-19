"""Bind recovered-cause executable inputs without executing the original reader."""
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
PATH = execute.AUDIT / 'recovered-cause-inputs-qualified.json.gz'
OWNER = prerequisite.OWNER.rsplit('.', 1)[0] + '.3'
PREMISES = ('recovered_cause_inputs.py', *prerequisite.PREMISES)
LIMITS = dict(runtime_source_image_qualified=False, runtime_exports_qualified=False,
              helper_api_identity_qualified=False, semantic_outputs_qualified=False,
              default_reachability_qualified=False, effects_qualified=False, runtime_permission=False)
SCOPE = ('Whole recovered-cause source caller/plan/table/entry byte, logical name, namespace, '
         'argv/import cache/restoration, stdout and proof bindings only. Qualified table '
         'retention, source AST/value/namespace grammar and the declared image are shared '
         'premises. Distinct Git blob reads and native Path values qualify bytes/paths; '
         'source result/proof/stdout predicates do not prove their executed semantic truth. '
         'Physical image, original helper/API/export identity, private/native uncertainty, '
         'default effects and custody remain open. No original reader, module, factory, '
         'recipe or cohort runs. All earlier failures, spent fixtures and unused slots retain.')


def source_contract(spec):
    text = spec['operand']['enclosing_recipe']['text']
    function = ast.parse(text).body[0]
    assert isinstance(function, ast.FunctionDef) and function.name == 'cause_qualification'
    assert not function.args.args
    forms = {ast.dump(node) for node in ast.walk(function)}
    statements = (
        "root = PLAN['cause_join']", 'bodies = fixed(entries)',
        "entry = root + '/' + PLAN['cause_entry']", "scope = {'__name__': '__main__', '__file__': entry}",
        "names = {Path(name).stem for name in entries if name.endswith('.py')} | {'capture'}",
        'previous = {name: sys.modules[name] for name in names if name in sys.modules}',
        'previous_path, previous_argv = sys.path[:], sys.argv[:]', 'terminal = io.StringIO()',
        'sys.modules.pop(name, None)', 'sys.path.insert(0, root)', 'sys.argv[:] = [entry]',
        "exec(compile(bodies[entry], entry, 'exec'), scope)", 'sys.path[:] = previous_path',
        'sys.argv[:] = previous_argv', 'sys.modules.update(previous)', "result = scope['result']", 'return result')
    for source in statements:
        assert ast.dump(ast.parse(source).body[0]) in forms, ('whole source binding statement', source)
    predicates = ('terminal.getvalue() == CAUSE_SUCCESS', "same(result, json.loads(bodies[root + '/proof.json']))")
    for source in predicates:
        assert ast.dump(ast.parse(source, mode='eval').body) in forms
    assert ast.dump(ast.parse('contextlib.redirect_stdout(terminal)', mode='eval').body) in forms
    assignments = {node.targets[0].id: node.value for node in function.body
                   if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name)}
    return function, assignments, dict(statements=list(statements), predicates=list(predicates),
                                       recipe=spec['operand']['enclosing_recipe'])


def derive(retained, graph, whole):
    candidates = [table for table in retained['tables']
                  if table['spec']['operand']['enclosing_name'] == 'cause_qualification']
    assert len(candidates) == 1
    table = candidates[0]
    tables.review_table(table)
    spec = table['spec']
    assert spec['selector'] == 'cause_join'
    _, assignments, contract = source_contract(spec)
    env = dict(graph.environments[spec['caller']])
    root = graph.value(assignments['root'], env, spec['caller'])
    assert type(root) is str and root == spec['root']
    env['root'] = root
    entry = graph.value(assignments['entry'], env, spec['caller'])
    assert type(entry) is str and entry == root + '/' + env['PLAN']['cause_entry']
    env['entry'] = entry
    namespace = graph.value(assignments['scope'], env, spec['caller'])
    assert namespace == dict(__name__='__main__', __file__=entry)
    references = {key: table['descriptors'][name] for key, name in (
        ('entry', entry), ('proof', root + '/proof.json'), ('original_plan', root + '/plan.json'))}
    body = prerequisite.read_reference(references['entry'])
    original_plan_body = prerequisite.read_reference(references['original_plan'])
    assert body == prepare.unblob(whole['sources'][entry]['body']), 'actual table entry versus declared image source'
    suffix = env['CAUSE_SUCCESS']
    assert type(suffix) is str
    modules = sorted({posixpath.splitext(posixpath.basename(name))[0]
                      for name in table['descriptors'] if name.endswith('.py')} | {'capture'})
    plan = json.loads(prepare.unblob(spec['plan']))
    assert plan == env['PLAN'] and plan['revision'] == spec['revision']
    return dict(schema='fsmgen.recovered_cause_source_inputs.v1', owner=OWNER, scope=SCOPE,
        table_spec=spec, table_identity=bounded.identity(table), table_members=sorted(table['descriptors']),
        contract=contract, callers=spec['calls'], plan=spec['plan'], references=references,
        input=prepare.blob(body), logical_name=entry, namespace=namespace, argv=[entry], import_path_first=root,
        cleared_modules=modules, stdout=dict(kind='exact', value=suffix), required_exports=['result'],
        proof_contract=dict(expression="same(result, json.loads(bodies[root + '/proof.json']))",
                            reference=references['proof'], semantic_truth_qualified=False),
        original_plan=prepare.blob(original_plan_body), outer_condition=plan['condition'],
        original_condition=json.loads(original_plan_body)['condition'], source_image_revision=epoch.REVISION,
        source_allocation_owner=direct.ALLOCATION_OWNER,
        shared_premises=['complete retained table byte qualification', 'AST/value/import/namespace source grammar',
                        'declared source image and original helper/API identities'], **LIMITS)


def review(value, expected, retained):
    bounded.strict_equal(value, expected)
    table = next(row for row in retained['tables'] if row['spec'] == value['table_spec'])
    bounded.strict_equal(bounded.identity(table), value['table_identity'])
    body = prepare.unblob(value['input'])
    assert body == prerequisite.read_reference(value['references']['entry'])
    assert value['references']['entry']['revision'] == value['table_spec']['revision']
    entry = value['logical_name']
    plan = json.loads(prepare.unblob(value['plan']))
    native_entry = Path(plan['cause_join']) / plan['cause_entry']
    assert str(native_entry) == entry, 'independent native Path entry value'
    native_modules = sorted({Path(name).stem for name in table['descriptors'] if name.endswith('.py')} | {'capture'})
    assert native_modules == value['cleared_modules'], 'independent native Path module stems'
    assert value['namespace'] == dict(__name__='__main__', __file__=entry) and value['argv'] == [entry]
    assert all(value[name] is False for name in LIMITS)
    assert value['proof_contract']['semantic_truth_qualified'] is False
    return dict(entry=prepare.identity(body), native_entry=str(native_entry), native_modules=native_modules,
        original_plan=prepare.identity(prerequisite.read_reference(
        value['references']['original_plan'])), proof_reference=value['references']['proof'], original_execution=False)


def controls(expected, retained):
    outcomes = []
    for label in ('revision', 'entry', 'input', 'namespace', 'argv', 'module', 'stdout',
                  'proof', 'member', 'caller', 'condition', 'progress', 'permission'):
        bad = copy.deepcopy(expected)
        if label == 'revision': bad['references']['entry']['revision'] = epoch.REVISION
        elif label == 'entry': bad['logical_name'] = bad['import_path_first'] + '/verify.py'
        elif label == 'input': bad['input'] = prepare.blob(b'other entry source')
        elif label == 'namespace': bad['namespace']['__name__'] = 'later_progress'
        elif label == 'argv': bad['argv'] = ['later.py']
        elif label == 'module': bad['cleared_modules'].remove('capture')
        elif label == 'stdout': bad['stdout']['kind'] = 'suffix'
        elif label == 'proof': bad['proof_contract']['reference']['path'] = bad['logical_name']
        elif label == 'member': bad['table_members'].pop()
        elif label == 'caller': bad['callers'].pop()
        elif label == 'condition': bad['original_condition'] = 'later original native currency'
        elif label == 'progress': bad['semantic_outputs_qualified'] = True
        else: bad['runtime_permission'] = 0
        changes = caller.changes(expected, bad)
        assert changes
        try: review(bad, expected, retained)
        except AssertionError as error:
            outcomes.append(dict(label=label, changes=changes, candidate_identity=bounded.identity(bad),
                                 refusal=str(error), kind='caught source/data binding refusal; no original native result'))
        else: raise AssertionError('changed cause input admitted: ' + label)
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
        else: raise AssertionError('retained cause input candidate admitted')
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
        table_input=dict(revision=AUTHORITY, identity=prepare.identity(raw)), native_interpreter=whole['language'],
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write: execute.save(PATH, product)
    else: bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Recovered cause table/entry/name/namespace/argv/import/stdout/proof source bindings agree; semantic outputs, default effects and all original execution remain unqualified.')
