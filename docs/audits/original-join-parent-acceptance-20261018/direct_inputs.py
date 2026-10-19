"""Bind direct file and fixed-Git compile inputs without executing originals."""
import argparse
import ast
import copy
import gzip
import hashlib
import json
import re

import bounded_runtime_inventory as bounded
import epoch_constraints as epoch
import execute
import operand_inventory as operands
import prepare
import qualify_caller_modules as caller
import typed_callers as typed
import wrapper_templates as templates

AUTHORITY = '752772895cc2286556816a0121f67a40c891737e'
OPERAND_AUTHORITY = 'dccd681e075c3b9df74811109de8a7cc427dae7a'
PATH = execute.AUDIT / 'direct-inputs-qualified.json.gz'
OWNER = typed.OWNER.rsplit('.', 1)[0] + '.3'
ALLOCATION_OWNER = operands.OWNER.rsplit('.', 1)[0] + '.3'
PREMISES = ('direct_inputs.py', *typed.PREMISES)
LIMITS = dict(runtime_source_image_qualified=False, runtime_callable_identity_qualified=False,
              target_exports_qualified=False, complete_source_allocation_qualified=False,
              default_reachability_qualified=False, effects_qualified=False, runtime_permission=False)
SCOPE = ('Source-derived direct read_bytes and fixed-Git/public factory compile inputs. '
         'Whole actual Git payloads use their own plan revision/path, not a compilation '
         'filename or later source body. File payloads are conditional on the declared '
         'original source image. Independent public Git tree/blob/object-hash and native '
         'Path oracles check bytes and path values. AST/value/namespace source grammar, '
         'original helper/builtin/API identity and Git protocol interpretation remain '
         'explicit premises. Source variants retain for the separately owned full '
         'allocation. Actual namespace exports, runtime source/cache image, default '
         'effects and custody remain unqualified. No original module, factory, recipe '
         'or cohort executes. Every earlier failure and unused slot retains.')


def selected(inventory):
    result = []
    for name, rows in inventory['sites'].items():
        for row in rows:
            if row['operation'] != 'compile' or row['enclosing_name'] == 'module':
                continue
            node = ast.parse(row['expressions']['input']['text'], mode='eval').body
            file_input = (isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
                          and node.func.attr == 'read_bytes')
            factory = row['enclosing_name'] in ('public', 'original_public')
            if file_input or factory:
                assert row['syntactic_role'] == 'exec-operand'
                result.append(dict(caller=name, site=row, kind='file' if file_input else 'fixed Git'))
    return result


def source_function(graph, name, function):
    body = graph.bodies[name]
    _, node = templates.function(body, function)
    return node, typed.dispatch.source(node, body.decode())


def context(graph, row):
    name, site = row['caller'], row['site']
    body = graph.bodies[name]
    tree = ast.parse(body)
    calls = [node for node in ast.walk(tree) if isinstance(node, ast.Call)
             and isinstance(node.func, ast.Name) and node.func.id == 'compile'
             and node.lineno == site['source']['line'] and node.col_offset == site['source']['column']]
    assert len(calls) == 1 and not calls[0].keywords and len(calls[0].args) == 3
    call = calls[0]
    bounded.strict_equal(typed.dispatch.source(call, body.decode()), site['source'])
    env = dict(graph.environments[name])
    owner = None
    if site['enclosing_name'] != '<module>':
        owner, source = source_function(graph, name, site['enclosing_name'])
        bounded.strict_equal(source, site['enclosing_recipe'])
        graph.assignments(owner.body, env, name)
    namespace = graph.value(ast.parse(site['namespace']['text'], mode='eval').body, env, name)
    assert type(namespace) is dict and all(type(key) is str and type(value) is str
                                           for key, value in namespace.items())
    logical = graph.value(call.args[1], env, name)
    assert type(logical) is str and ast.literal_eval(call.args[2]) == 'exec'
    uses = []
    namespace_name = site['namespace']['text']
    for node in ast.walk(owner or tree):
        if isinstance(node, ast.Subscript) and isinstance(node.value, ast.Name) and node.value.id == namespace_name:
            uses.append(typed.dispatch.source(node, body.decode()))
    return call, env, namespace, logical, uses


def git_contract(graph, caller_name, env):
    binding = env['fixed']
    assert isinstance(binding, tuple) and binding[0] == 'declared' and binding[2] == 'fixed'
    origin = binding[1]
    node, source = source_function(graph, origin, 'fixed')
    statements = {ast.dump(item) for item in ast.walk(node)}
    def contains(source):
        return ast.dump(ast.parse(source).body[0]) in statements
    assert contains("request = b''.join((PLAN['revision'] + ':' + name + '\\n').encode() for name in names)")
    assert contains("result = subprocess.run(['git', '--no-replace-objects', 'cat-file', '--batch'], input=request, capture_output=True)")
    assert contains('stream, sources = io.BytesIO(result.stdout), {}')
    assert contains('body = stream.read(int(header[2]))')
    assert contains('sources[name] = body') and contains('return sources')
    plan_path = str(graph.environments[origin]['BASE']) + '/plan.json'
    raw = graph.read(plan_path)
    plan = json.loads(raw)
    bounded.strict_equal(plan, env['PLAN'])
    assert type(plan['revision']) is str and re.fullmatch('[0-9a-f]{40}', plan['revision'])
    return dict(origin=origin, source=source, plan_path=plan_path, plan=prepare.blob(raw),
                revision=plan['revision'], binding=['declared', origin, 'fixed'], caller=caller_name)


def git_oracle(revision, name, body):
    """Independent tree/blob read and Git object hash; no original helper runs."""
    command = ['git', '--no-replace-objects', '--literal-pathspecs', 'ls-tree', '-z', revision, '--', name]
    listing = execute.command(command)
    entries = listing.rstrip(b'\0').split(b'\0')
    assert len(entries) == 1
    header, path = entries[0].split(b'\t', 1)
    mode, kind, oid = header.decode().split()
    assert path.decode() == name and kind == 'blob' and mode in ('100644', '100755')
    blob_command = ['git', '--no-replace-objects', 'cat-file', 'blob', oid]
    independent = execute.command(blob_command)
    assert independent == body, 'whole independent Git tree/blob source'
    assert hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == oid
    return dict(tree_command=command, tree_stdout=prepare.blob(listing), blob_command=blob_command,
                mode=mode, oid=oid, body=prepare.blob(independent))


def derive(graph, inventory):
    rows = []
    for row in selected(inventory):
        name, site = row['caller'], row['site']
        call, env, namespace, logical, uses = context(graph, row)
        product = dict(caller=name, site=site, kind=row['kind'], logical_name=logical,
                       namespace=namespace, namespace_uses=uses, target_exports_qualified=False)
        if row['kind'] == 'file':
            expression = call.args[0]
            assert not expression.args and not expression.keywords
            path = graph.value(expression.func.value, env, name)
            assert isinstance(path, typed.SourcePath) and str(path) == logical
            assert str(path) in graph.environments, 'whole selected source candidate'
            product.update(path=typed.datum(path), revision=epoch.REVISION,
                payload=prepare.blob(graph.read(str(path))),
                input_authority='read_bytes under original source-image premise', helper=None)
        else:
            helper = git_contract(graph, name, env)
            assert logical == 'scripts/check_record_value_publication.py'
            expected = "fixed([name])[name]"
            if isinstance(call.args[0], ast.Name):
                assert call.args[0].id == 'body'
                owner, _ = source_function(graph, name, site['enclosing_name'])
                assignments = [node for node in owner.body if isinstance(node, ast.Assign)
                               and any(isinstance(target, ast.Name) and target.id == 'body' for target in node.targets)]
                assert len(assignments) == 1 and ast.unparse(assignments[0].value) == expected
            else:
                assert ast.unparse(call.args[0]) == expected
            body = epoch.read(helper['revision'], logical)
            product.update(path=dict(kind='str', value=logical), revision=helper['revision'],
                payload=prepare.blob(body), helper=helper,
                input_authority='whole plan-revision Git blob',
                selected_image_equal=body == graph.read(logical),
                source_allocation_owner=ALLOCATION_OWNER)
        rows.append(product)
    return dict(schema='fsmgen.direct_executable_inputs.v1', revision=epoch.REVISION, owner=OWNER,
        scope=SCOPE, bindings=rows,
        sources={name: dict(body=prepare.blob(body)) for name, body in sorted(graph.bodies.items())},
        shared_premises=['fixed source AST/value/import/namespace grammar',
                        'source-defined fixed helper request/read/return protocol',
                        'original builtin/Path/Git/helper identity and actual runtime source image unqualified'],
        source_allocation_owner=ALLOCATION_OWNER, **LIMITS)


def review(value, graph, inventory, originals):
    assert value['schema'] == 'fsmgen.direct_executable_inputs.v1' and value['owner'] == OWNER
    assert value['revision'] == epoch.REVISION and value['scope'] == SCOPE
    bounded.strict_equal({key: value[key] for key in LIMITS}, LIMITS)
    expected = derive(graph, inventory)
    bounded.strict_equal(value['shared_premises'], expected['shared_premises'])
    bounded.strict_equal(value['sources'], expected['sources'])
    bounded.strict_equal(value['bindings'], expected['bindings'])
    assert value['source_allocation_owner'] == ALLOCATION_OWNER
    checks = []
    for row in value['bindings']:
        body = prepare.unblob(row['payload'])
        assert row['target_exports_qualified'] is False
        if row['kind'] == 'file':
            path = typed.native_path(row['path']['trace'], originals)
            assert row['path']['kind'] == 'Path' and str(path) == row['path']['value'] == row['logical_name']
            assert row['revision'] == epoch.REVISION and body == originals[str(path)]
            checks.append(dict(caller=row['caller'], site=row['site']['source'], kind='native public Path and fixed Git source',
                               native_type=type(path).__module__ + '.' + type(path).__qualname__, file_read=False))
        else:
            plan = json.loads(prepare.unblob(row['helper']['plan']))
            assert row['revision'] == plan['revision'] and row['path'] == dict(kind='str', value=row['logical_name'])
            checks.append(dict(caller=row['caller'], site=row['site']['source'], kind='independent native Git object protocol',
                               oracle=git_oracle(row['revision'], row['logical_name'], body)))
    return checks


def controls(expected, graph, inventory, originals):
    outcomes = []
    for label in ('source', 'revision', 'input', 'name', 'namespace', 'omitted_input', 'type', 'allocation', 'permission'):
        bad = copy.deepcopy(expected)
        file_row = next(row for row in bad['bindings'] if row['kind'] == 'file')
        git_row = next(row for row in bad['bindings'] if row['kind'] == 'fixed Git')
        if label == 'source': file_row['payload'] = prepare.blob(b'other source')
        elif label == 'revision': git_row['revision'] = epoch.REVISION
        elif label == 'input': git_row['payload'] = file_row['payload']
        elif label == 'name': file_row['logical_name'] = 'synthetic.py'
        elif label == 'namespace': file_row['namespace']['__name__'] = '__main__'
        elif label == 'omitted_input': bad['bindings'].pop()
        elif label == 'type': file_row['path']['kind'] = 'str'
        elif label == 'allocation': bad['complete_source_allocation_qualified'] = True
        else: bad['runtime_permission'] = 0
        changes = caller.changes(expected, bad)
        assert changes
        try:
            review(bad, graph, inventory, originals)
        except AssertionError as error:
            outcomes.append(dict(label=label, changes=changes, candidate_identity=bounded.identity(bad),
                                 refusal=str(error), kind='caught source binding refusal; no historical native result'))
        else:
            raise AssertionError('changed direct input admitted: ' + label)
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
        try:
            review(bad, graph, inventory, originals)
        except AssertionError as error:
            assert str(error) == outcome['refusal']
        else:
            raise AssertionError('retained direct input candidate admitted')
    return outcomes


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    inputs = {}
    for path, authority in ((typed.PATH, AUTHORITY), (operands.PATH, OPERAND_AUTHORITY)):
        raw = execute.read(path)
        assert raw == epoch.read(authority, str(path)), 'whole committed source/data input'
        inputs[str(path)] = dict(revision=authority, identity=prepare.identity(raw))
    typed_saved = json.loads(gzip.decompress(execute.read(typed.PATH)))['result']
    inventory = json.loads(gzip.decompress(execute.read(operands.PATH)))['result']
    contracts = json.loads(gzip.decompress(execute.read(templates.PATH)))['result']['templates']
    assert execute.read(templates.PATH) == epoch.read(typed.AUTHORITY, str(templates.PATH))
    graph = typed.Graph(contracts)
    whole = json.loads(prepare.encoded(graph.build()))
    bounded.strict_equal(whole['sources'], typed_saved['sources'])
    bounded.strict_equal(whole['declarations'], typed_saved['declarations'])
    result = json.loads(prepare.encoded(derive(graph, inventory)))
    originals = {name: prepare.unblob(row['body']) for name, row in typed_saved['sources'].items()}
    product = dict(result=result, review=review(result, graph, inventory, originals),
        controls=controls(result, graph, inventory, originals), inputs=inputs,
        native_interpreter=whole['language'],
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES})
    if args.write:
        execute.save(PATH, product)
    else:
        bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), product)
    print('Direct source-image inputs and distinct plan-revision Git payloads, namespace/name roles and native Path/Git oracles agree; full source allocation, exports, effects and runtime remain unqualified.')
