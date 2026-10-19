"""Qualify bounded whole fixed reader tables through immutable Git retrieval.

All bytes are read, one object at a time. A separate raw tree parser and batch
blob protocol check population, modes and byte identities. Only descriptors
and a bounded real protocol fixture are copied; original bytes retain under
the repository's required-history contract. No original reader executes.
"""
import argparse
import ast
import copy
import gzip
import hashlib
import io
import json
import os
import posixpath
import re
import subprocess
import sys

import bounded_runtime_inventory as bounded
import direct_inputs as direct
import epoch_constraints as epoch
import execute
import operand_inventory as operands
import prepare
import qualify_caller_modules as caller
import typed_callers as typed

AUTHORITY = 'ea718e3fcc4afc29b14d5f89662cbf7d8d36c7f3'
RETENTION = 'doctrine/live_document_size/version_retention_contracts.jsonl'
PATH = execute.AUDIT / 'reader-tables-qualified.json.gz'
OWNER = direct.OWNER.rsplit('.', 1)[0] + '.4.1'
PREMISES = ('reader_tables.py', *direct.PREMISES)
MAX_MEMBERS = 4096
MAX_BLOB = 32 * 1024 * 1024
CHUNK = 64 * 1024
ENVIRONMENT = dict(GIT_NO_LAZY_FETCH='1', GIT_OPTIONAL_LOCKS='0')
LIMITS = dict(entrypoint_bindings_qualified=False, runtime_source_image_qualified=False,
              helper_api_identity_qualified=False, complete_source_allocation_qualified=False,
              default_reachability_qualified=False, effects_qualified=False, runtime_permission=False)
SCOPE = ('Complete fixed reader-table candidate domains, whole native byte retrieval '
         'and required-history descriptors only. Source selectors and finite caller roles '
         'name every prerequisite/cause/admission table; entrypoint/namespace/argv/capture '
         'semantics have separate successors. All source, capture and data members retain. '
         'Producer uses ls-tree/show; the independent oracle decodes the raw tree and '
         'streams cat-file blob bytes. Git object format/store, cryptographic hashes and '
         'AST/source/caller selector grammar are shared premises. Physical source image, '
         'original helper/API identity, runtime/default effects and custody remain open. '
         'Every referenced revision/path retains under fsmgen_required_history; rewrites '
         'must preserve/materialize objects and missing retrieval must fail. No original '
         'module, factory, recipe, reader or cohort runs. Earlier failures and slots retain.')


def git(*args):
    command = ['git', '--no-replace-objects', '--literal-pathspecs', *args]
    result = subprocess.run(command, cwd=prepare.ROOT, env=dict(os.environ, **ENVIRONMENT),
                            capture_output=True, timeout=60)
    assert result.returncode == 0 and result.stderr == b'', (command, result.returncode, result.stderr)
    return result.stdout


def safe_name(name):
    assert type(name) is str and name and not posixpath.isabs(name)
    assert '..' not in name.split('/') and '\n' not in name and '\0' not in name and ':' not in name
    return name


def specifications(fixed, inventory):
    specs = []
    population = [(name, row) for name, rows in inventory['sites'].items() for row in rows
                  if row['operation'] == 'compile' and row['enclosing_name'] in
                  ('reader', 'cause_qualification', 'fresh_admission')]
    assert {row['enclosing_name'] for _, row in population} == {'reader', 'cause_qualification', 'fresh_admission'}
    for name, row in population:
        body = prepare.unblob(fixed['sources'][name]['body'])
        tree = ast.parse(body)
        function = next(node for node in tree.body if isinstance(node, ast.FunctionDef)
                        and node.name == row['enclosing_name'])
        bounded.strict_equal(typed.dispatch.source(function, body.decode()), row['enclosing_recipe'])
        roots = [node for node in function.body if isinstance(node, ast.Assign)
                 and any(isinstance(target, ast.Name) and target.id == 'root' for target in node.targets)]
        assert len(roots) == 1 and isinstance(roots[0].value, ast.Subscript)
        selector = roots[0].value
        assert isinstance(selector.value, ast.Name) and selector.value.id == 'PLAN'
        helper_origin = fixed['exports'][name]['fixed']['declaration'][0]
        plan_path = fixed['exports'][helper_origin]['BASE'] + '/plan.json'
        plan_blob = fixed['declarations'][plan_path]
        plan = json.loads(prepare.unblob(plan_blob))
        bounded.strict_equal(plan, fixed['exports'][name]['PLAN'])
        assert re.fullmatch('[0-9a-f]{40}', plan['revision'])
        calls = [node for node in ast.walk(tree) if isinstance(node, ast.Call)
                 and isinstance(node.func, ast.Name) and node.func.id == function.name]
        assert calls, 'whole source caller domain'
        caller_sources = [typed.dispatch.source(call, body.decode()) for call in calls]
        if isinstance(selector.slice, ast.Name):
            assert selector.slice.id == 'role' and [arg.arg for arg in function.args.args] == ['role']
            parents = {id(child): node for node in ast.walk(tree) for child in ast.iter_child_nodes(node)}
            alternatives = None
            for call in calls:
                assert len(call.args) == 1 and not call.keywords and ast.unparse(call.args[0]) == 'role'
                ancestor = parents[id(call)]
                while not isinstance(ancestor, (ast.DictComp, ast.ListComp, ast.GeneratorExp)):
                    ancestor = parents[id(ancestor)]
                assert len(ancestor.generators) == 1
                generator = ancestor.generators[0]
                assert ast.unparse(generator.target) == 'role' and not generator.ifs and not generator.is_async
                values = list(ast.literal_eval(generator.iter))
                assert values == ['context', 'cause', 'consumer']
                assert alternatives is None or values == alternatives
                alternatives = values
        else:
            assert not function.args.args and all(not call.args and not call.keywords for call in calls)
            alternatives = [ast.literal_eval(selector.slice)]
        for role in alternatives:
            root = safe_name(plan[role])
            specs.append(dict(caller=name, operand=row, root_selector=typed.dispatch.source(roots[0], body.decode()),
                calls=caller_sources, selector=role, root=root, revision=plan['revision'],
                helper_origin=helper_origin, plan_path=plan_path, plan=plan_blob))
    assert len({(row['revision'], row['root']) for row in specs}) == len(specs), 'unique complete candidate tables'
    return specs


def tree_members(spec):
    raw = git('ls-tree', '-r', '-l', '-z', spec['revision'], '--', spec['root'])
    members = {}
    for entry in raw.rstrip(b'\0').split(b'\0'):
        header, path = entry.split(b'\t', 1)
        mode, kind, oid, size = header.decode().split()
        name = safe_name(path.decode('utf-8'))
        assert posixpath.dirname(name) == spec['root'], 'complete flat original table'
        assert kind == 'blob' and mode in ('100644', '100755') and re.fullmatch('[0-9a-f]{40}', oid)
        assert size.isdecimal() and 0 <= int(size) <= MAX_BLOB and name not in members
        members[name] = dict(mode=mode, oid=oid, bytes=int(size))
        assert len(members) <= MAX_MEMBERS
    assert members
    return raw, members


def decode_tree(raw, root):
    members, offset = {}, 0
    while offset < len(raw):
        space = raw.index(b' ', offset)
        zero = raw.index(b'\0', space + 1)
        mode = raw[offset:space].decode()
        name = raw[space + 1:zero].decode('utf-8')
        assert name and '/' not in name and mode in ('100644', '100755')
        binary = raw[zero + 1:zero + 21]
        assert len(binary) == 20
        path = safe_name(root + '/' + name)
        assert path not in members
        members[path] = dict(mode=mode, oid=binary.hex())
        offset = zero + 21
        assert len(members) <= MAX_MEMBERS
    assert offset == len(raw) and members
    return members


def raw_tree(spec):
    oid = git('rev-parse', spec['revision'] + ':' + spec['root']).decode().strip()
    assert re.fullmatch('[0-9a-f]{40}', oid)
    raw = git('cat-file', 'tree', oid)
    assert hashlib.sha1(b'tree ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == oid
    return dict(oid=oid, body=prepare.blob(raw), members=decode_tree(raw, spec['root']))


def blob_identity(stream, expected):
    """Consume one complete native batch frame with bounded reads and strict EOF framing."""
    header = stream.readline(256)
    fields = header.split()
    assert header.endswith(b'\n') and len(fields) == 3 and fields[1] == b'blob'
    assert fields[0].decode() == expected['oid'] and fields[2].isdigit()
    size = int(fields[2])
    assert size == expected['bytes'] and 0 <= size <= MAX_BLOB
    sha256, sha1 = hashlib.sha256(), hashlib.sha1(b'blob ' + str(size).encode() + b'\0')
    remaining, largest = size, 0
    while remaining:
        part = stream.read(min(remaining, CHUNK))
        assert part and len(part) <= min(remaining, CHUNK), 'whole bounded blob body'
        largest = max(largest, len(part))
        remaining -= len(part)
        sha256.update(part)
        sha1.update(part)
    assert stream.read(1) == b'\n' and sha1.hexdigest() == expected['oid'], 'whole object hash and batch terminator'
    return dict(bytes=size, sha256=sha256.hexdigest(), largest_chunk=largest, header=prepare.blob(header))


def qualify_table(spec):
    listing, members = tree_members(spec)
    independent = raw_tree(spec)
    bounded.strict_equal({name: {key: row[key] for key in ('mode', 'oid')} for name, row in members.items()},
                         independent['members'])
    git('merge-base', '--is-ancestor', spec['revision'], AUTHORITY)
    descriptors, fixture = {}, None
    for name, row in sorted(members.items()):
        body = git('show', spec['revision'] + ':' + name)
        assert len(body) == row['bytes'] and prepare.identity(body)['bytes'] <= MAX_BLOB
        assert hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == row['oid']
        descriptors[name] = dict(row, sha256=hashlib.sha256(body).hexdigest(), revision=spec['revision'],
            path=name, retention_contract='fsmgen_required_history')
        if fixture is None and 0 < len(body) <= CHUNK:
            fixture = dict(expected=row, body=prepare.blob(body), path=name)
    assert fixture is not None, 'bounded actual native protocol fixture'
    process = subprocess.Popen(['git', '--no-replace-objects', 'cat-file', '--batch'],
        cwd=prepare.ROOT, env=dict(os.environ, **ENVIRONMENT), stdin=subprocess.PIPE,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    checks = {}
    try:
        for name, row in sorted(members.items()):
            process.stdin.write((row['oid'] + '\n').encode())
            process.stdin.flush()
            checked = blob_identity(process.stdout, row)
            assert checked['sha256'] == descriptors[name]['sha256']
            checks[name] = checked
        process.stdin.close()
        assert process.stdout.read(1) == b'' and process.stderr.read() == b'' and process.wait(timeout=30) == 0
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
    return dict(spec=spec, listing=prepare.blob(listing), independent_tree=independent,
                descriptors=descriptors, independent_blobs=checks, protocol_fixture=fixture)


def review_table(row):
    spec = row['spec']
    assert re.fullmatch('[0-9a-f]{40}', spec['revision'])
    plan = json.loads(prepare.unblob(spec['plan']))
    assert spec['revision'] == plan['revision'] and spec['root'] == plan[spec['selector']]
    expected = row['independent_tree']['members']
    assert set(row['descriptors']) == set(row['independent_blobs']) == set(expected)
    raw = prepare.unblob(row['independent_tree']['body'])
    assert hashlib.sha1(b'tree ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == row['independent_tree']['oid']
    bounded.strict_equal(expected, decode_tree(raw, spec['root']))
    for name, descriptor in row['descriptors'].items():
        assert descriptor['revision'] == spec['revision'] and descriptor['path'] == name
        assert descriptor['retention_contract'] == 'fsmgen_required_history'
        assert descriptor['mode'] == expected[name]['mode'] and descriptor['oid'] == expected[name]['oid']
        assert type(descriptor['bytes']) is int and type(descriptor['sha256']) is str
        independent = row['independent_blobs'][name]
        assert descriptor['bytes'] == independent['bytes'] and descriptor['sha256'] == independent['sha256']
        assert 0 <= independent['largest_chunk'] <= CHUNK
    return True


def controls(table):
    results = []
    for label in ('revision', 'missing_member', 'coordinated_loss', 'mode', 'oid', 'body', 'size', 'type', 'retention'):
        bad = copy.deepcopy(table)
        name = next(iter(bad['descriptors']))
        row = bad['descriptors'][name]
        if label == 'revision': row['revision'] = AUTHORITY
        elif label == 'missing_member': del bad['descriptors'][name]
        elif label == 'coordinated_loss':
            del bad['descriptors'][name]
            del bad['independent_tree']['members'][name]
            del bad['independent_blobs'][name]
        elif label == 'mode': row['mode'] = '120000'
        elif label == 'oid': row['oid'] = '0' * 40
        elif label == 'body': row['sha256'] = '0' * 64
        elif label == 'size': row['bytes'] += 1
        elif label == 'type': row['bytes'] = str(row['bytes'])
        else: row['retention_contract'] = 'borrowed_progress'
        try:
            review_table(bad)
        except AssertionError as error:
            results.append(dict(label=label, changes=caller.changes(table, bad),
                candidate_identity=bounded.identity(bad), refusal=str(error), kind='caught descriptor assertion; no original execution'))
        else:
            raise AssertionError('changed table admitted: ' + label)
    for result in results:
        bad = copy.deepcopy(table)
        for change in result['changes']:
            parent = bad
            for key in change['path'][:-1]: parent = parent[key]
            key = change['path'][-1]
            bounded.strict_equal(parent[key], change['before'])
            if change.get('remove') is True: del parent[key]
            else: parent[key] = change['after']
        bounded.strict_equal(bounded.identity(bad), result['candidate_identity'])
        try: review_table(bad)
        except AssertionError as error: assert str(error) == result['refusal']
        else: raise AssertionError('retained table candidate admitted')
    fixture = table['protocol_fixture']
    body, expected = prepare.unblob(fixture['body']), fixture['expected']
    wire = (expected['oid'] + ' blob ' + str(len(body)) + '\n').encode() + body + b'\n'
    positive = io.BytesIO(wire)
    blob_identity(positive, expected)
    assert positive.read(1) == b''
    protocol = []
    mutations = dict(truncated=wire[:-2], wrong_body=wire[:-2] + bytes([wire[-2] ^ 1]) + wire[-1:],
                     wrong_header=(b'1' if wire[:1] == b'0' else b'0') + wire[1:],
                     wrong_terminator=wire[:-1] + b'x')
    assert all(changed != wire for changed in mutations.values())
    for label, changed in mutations.items():
        try: blob_identity(io.BytesIO(changed), expected)
        except AssertionError as error:
            protocol.append(dict(label=label, candidate=prepare.blob(changed), refusal=str(error),
                                 kind='caught actual-byte protocol assertion; no historical native result'))
        else: raise AssertionError('changed native blob frame admitted')
    return dict(descriptors=results, protocol=protocol)


def derive():
    fixed_raw = execute.read(operands.INPUT)
    assert fixed_raw == epoch.read(operands.AUTHORITY, str(operands.INPUT))
    inventory_raw = execute.read(operands.PATH)
    assert inventory_raw == epoch.read(direct.OPERAND_AUTHORITY, str(operands.PATH))
    fixed = json.loads(gzip.decompress(fixed_raw))['graph']
    inventory = json.loads(gzip.decompress(inventory_raw))['result']
    assert git('rev-parse', '--show-object-format') == b'sha1\n'
    policy = epoch.read(AUTHORITY, RETENTION)
    contracts = [row for row in map(json.loads, policy.splitlines()) if row.get('contract_id') == 'fsmgen_required_history']
    assert len(contracts) == 1 and all(contracts[0].get(key) for key in ('guarantee', 'recovery'))
    tables = [qualify_table(spec) for spec in specifications(fixed, inventory)]
    tables = json.loads(prepare.encoded(tables))
    for table in tables: review_table(table)
    return dict(schema='fsmgen.complete_reader_table_retention.v1', owner=OWNER, scope=SCOPE,
        tables=tables, controls=[controls(table) for table in tables],
        retention=dict(revision=AUTHORITY, path=RETENTION, body=prepare.blob(policy)),
        inputs={str(operands.INPUT): prepare.identity(fixed_raw), str(operands.PATH): prepare.identity(inventory_raw)},
        environment=ENVIRONMENT, limits=dict(MAX_MEMBERS=MAX_MEMBERS, MAX_BLOB=MAX_BLOB, CHUNK=CHUNK),
        native_git=git('--version').decode(), native_python=dict(implementation=sys.implementation.name,
                                                               version=list(sys.version_info)),
        programmes={name: prepare.blob(execute.read(execute.AUDIT / name)) for name in PREMISES}, **LIMITS)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = derive()
    if args.write: execute.save(PATH, value)
    else: bounded.strict_equal(json.loads(gzip.decompress(execute.read(PATH))), value)
    print('Complete reader tables retain exact versioned bytes; independent raw trees, bounded native blobs and saved rejection candidates agree. Entrypoint binding and all original execution remain gated.')
