"""Select a whole historical source epoch without launching a saved reader.

Git objects are the source image here. Physical checkout, import execution and
semantic acceptance remain separate prerequisites of a fresh intake.
"""
import argparse
import ast
import copy
import gzip
import hashlib
import io
import json
from pathlib import Path
import subprocess

import execute
import prepare

REVISION = '192c9dae1f788fb13a0b10c1d1eb952875b03dd6'
BASES = {
    'cause': 'docs/audits/primary-raw-cause-container-acceptance-20261012',
    'consumer': 'docs/audits/original-consumer-parent-acceptance-20261012',
    'prerequisites': 'docs/audits/original-context-cause-consumer-prerequisites-20261012',
    'association': 'docs/audits/original-context-cause-consumer-association-20261012',
}
OVERLAYS = {'MEMORY.md', 'docs/TASK_TREE.md', prepare.TASK,
            'docs/book/src/13k-isf-feature-support-matrix.md',
            'doctrine/live_document_size/surfaces.jsonl'}
FACTORY = 'scripts/check_record_value_publication.py'
RUNTIME = ['.artifacts', '.artifacts/build', '.artifacts/cache', '.artifacts/logs', '.artifacts/tmp']
PATH = execute.AUDIT / 'conjunctive-epoch-constraints-qualified.json.gz'


def git(*args, data=None):
    result = subprocess.run(['git', '--no-replace-objects', *args], input=data,
                            capture_output=True, cwd=execute.ROOT, timeout=60)
    assert result.returncode == 0 and not result.stderr
    return result.stdout


def tree(revision, *roots):
    raw = git('ls-tree', '-r', '-l', '-z', revision, '--', *roots)
    members = {}
    for record in raw.split(b'\0'):
        if not record:
            continue
        header, name = record.split(b'\t', 1)
        mode, kind, oid, size = header.decode().split()
        name = name.decode()
        assert kind == 'blob' and mode in ('100644', '100755', '120000')
        assert not Path(name).is_absolute() and '..' not in Path(name).parts and name not in members
        members[name] = dict(mode=mode, oid=oid, bytes=int(size))
    return raw, members


def batch(revision, names):
    names = sorted(names)
    stream = io.BytesIO(git('cat-file', '--batch', data=b''.join(
        (revision + ':' + name + '\n').encode() for name in names)))
    result = {}
    for name in names:
        header = stream.readline().split()
        assert len(header) == 3 and header[1] == b'blob'
        body = stream.read(int(header[2]))
        assert len(body) == int(header[2]) and stream.read(1) == b'\n'
        assert hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == header[0].decode()
        result[name] = body
    assert not stream.read(1)
    return result


def read(revision, name):
    return batch(revision, [name])[name]


def decoded(revision, name):
    return json.loads(read(revision, name))


def exact_members(actual, expected, message):
    assert actual.keys() == expected.keys(), message + ': membership'
    assert all(actual[name] == row for name, row in expected.items()), message + ': mode/content'


def derive(revision, source_image=None):
    raw_tree, candidate = tree(revision)
    if source_image is not None:
        candidate = source_image
    plans = {role: decoded(REVISION, base + '/plan.json') for role, base in BASES.items()}
    # The completed association commit is an observed boundary, not a guessed
    # "latest before publication" epoch. Preserve its entire source graph.
    history = git('show', '-s', '--format=%H %s', REVISION).decode()
    assert plans['association']['owner'] in history
    declarations, source_graphs, namespaces, programme_epochs = {}, {}, {}, {}
    required = set()
    for role, base in BASES.items():
        plan = plans[role]
        roles_name = base + '/source-roles.json'
        roles = decoded(REVISION, roles_name)
        source = roles['publication']
        assert source['revision'] == plan['revision']
        # These are recorded source graphs, including the complete original
        # graph. Default readers use fixed originals and explicit afterimages;
        # their five mutable publication targets are never a live baseline.
        assert source['members'].keys() >= roles['original']['members'].keys()
        wanted = tree(plan['revision'], *source['roots'])[1]
        exact_members(wanted, {name: {key: row[key] for key in ('mode', 'oid', 'bytes')}
                               for name, row in source['members'].items()}, role + ' declared source graph')
        roots = set(source['roots'])
        projected = {name: row for name, row in candidate.items()
                     if name in roots or any(str(parent) in roots for parent in Path(name).parents)}
        assert projected.keys() == wanted.keys(), role + ': complete declared source membership'
        differences = {name for name, row in wanted.items() if candidate.get(name) != row}
        assert differences == OVERLAYS, role + ': undeclared source-epoch conflict'
        source_graphs[role] = dict(declaration=prepare.blob(read(REVISION, roles_name)),
                                   fixed_revision=plan['revision'], mutable_targets=sorted(differences))
        required.update(wanted)
        # All formal code and all archive members belong to the final observed
        # namespace, including native receipts, first failures and repairs.
        expected = tree(REVISION, base)[1]
        actual = {name: row for name, row in candidate.items() if name.startswith(base + '/')}
        exact_members(actual, expected, role + ' complete reader namespace')
        namespaces[role] = expected
        required.update(expected)
        frozen = decoded(REVISION, base + '/formal-programmes.json')['programmes']
        assert set(frozen) == {name for name in expected if name.endswith('.py')}
        bodies = batch(revision, frozen)
        assert all(prepare.identity(bodies[name]) == row['identity']
                   and bodies[name] == row['body'].encode() for name, row in frozen.items())
        programme_epochs[role] = {name: prepare.identity(body) for name, body in bodies.items()}
        integration = decoded(REVISION, base + '/integration-contract.json')['retained_dependencies']
        helpers = batch(revision, integration)
        fixed_helpers = batch(plan['revision'], integration)
        assert all(helpers[name] == fixed_helpers[name] and prepare.identity(body) == integration[name]
                   for name, body in helpers.items())
        assert read(revision, FACTORY) == read(plan['revision'], FACTORY)
        declarations[role] = dict(plan=prepare.blob(read(REVISION, base + '/plan.json')),
                                  integration=prepare.blob(read(REVISION, base + '/integration-contract.json')))

    # The consumer is the nested default reader with a *physical* canonical
    # equality premise. Other canonical_sources() calls consume their fixed Git
    # epoch; imposing physical equality on all four would invent a contract.
    canonical_revision = plans['consumer']['revision']
    canonical = {name: row for name, row in tree(canonical_revision, 'docs/knowledge', 'docs/decisions')[1].items()
                 if name.endswith('.md')}
    assert all(candidate.get(name) == row for name, row in canonical.items()), 'whole physical consumer canonical baseline'
    required.update(canonical)

    # Evaluate the original dated repair's complete changed-set population.
    # This includes tests and data, not merely imports. No function body runs.
    base = BASES['cause']
    first_name = base + '/development-preflight-actual.json'
    first = decoded(REVISION, first_name)
    bodies = batch(revision, first['programmes'])
    changed = sorted(name for name, row in first['programmes'].items()
                     if bodies[name] != (row['body'].encode() if 'body' in row else bytes.fromhex(row['body_hex'])))
    assert changed == sorted(base + '/' + name for name in ('verify.py', 'container_publish.py', 'plan.json'))
    required.update(first['programmes'])
    repair = dict(first_receipt=prepare.blob(read(REVISION, first_name)), changed=changed,
                  complete_population={name: prepare.identity(body) for name, body in bodies.items()})

    # Full maintained factory import closure, derived with the original static
    # import grammar; no factory or historical semantic module is imported.
    available = {Path(name).stem: name for name in candidate
                 if Path(name).parent == Path('scripts') and name.endswith('.py')}
    pending, imports = [FACTORY], {}
    while pending:
        name = pending.pop()
        if name in imports:
            continue
        body = read(revision, name)
        expected = read(plans['cause']['revision'], name)
        assert body == expected, 'whole original import source: ' + name
        dependencies = set()
        for node in ast.walk(ast.parse(body)):
            modules = [item.name for item in node.names] if isinstance(node, ast.Import) else (
                [node.module] if isinstance(node, ast.ImportFrom) and not node.level and node.module else [])
            dependencies.update(available[module.split('.')[0]] for module in modules
                                if module.split('.')[0] in available)
        imports[name] = dict(source=prepare.blob(body), imports=sorted(dependencies))
        pending.extend(dependencies)
    required.update(imports)

    # Retain an addressable read-site census across the complete recorded Python
    # source population, so a subsequent checkout/intake review can inspect every
    # read boundary rather than rediscover just the last failing guard.
    code = batch(revision, (name for name in required if name.endswith('.py')))
    read_sites = {}
    methods = {'read_bytes', 'read_text', 'open', 'glob', 'rglob', 'iterdir', 'stat', 'lstat', 'exists'}
    for name, body in code.items():
        sites = []
        parsed = ast.parse(body, filename=name)
        for node in ast.walk(parsed):
            if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute) and node.func.attr in methods:
                sites.append(dict(line=node.lineno, expression=ast.get_source_segment(body.decode(), node)))
        if sites:
            read_sites[name] = sorted(sites, key=lambda row: row['line'])

    guard_sources = {}
    for role, filename in (('cause', 'container_common.py'), ('consumer', 'interfaces.py'),
                           ('prerequisites', 'admission_common.py'), ('association', 'association_common.py')):
        name = BASES[role] + '/' + filename
        body = read(revision, name)
        function = next(node for node in ast.parse(body).body if isinstance(node, ast.FunctionDef) and node.name == 'public')
        guard_sources[name] = ast.get_source_segment(body.decode(), function)
    for name, function_name in ((BASES['consumer'] + '/model.py', 'inputs'), (base + '/verify.py', 'repaired_preflight')):
        body = read(revision, name)
        function = next(node for node in ast.parse(body).body if isinstance(node, ast.FunctionDef) and node.name == function_name)
        guard_sources[name] = ast.get_source_segment(body.decode(), function)

    locality = read(revision, 'scripts/project_data_locality_env.sh')
    assert locality == read(REVISION, 'scripts/project_data_locality_env.sh')
    for leaf in ('tmp', 'cache', 'logs', 'build'):
        assert ('${FSMGEN_ARTIFACT_ROOT}/' + leaf).encode() in locality
    original = prepare.premises()
    assert prepare.check_contracts(execute.read(prepare.TASK), original[2], original[0])
    return dict(schema='fsmgen.conjunctive_historical_epoch.v1', revision=revision,
                observed_boundary=history, tree=prepare.blob(raw_tree), declarations=declarations,
                source_graphs=source_graphs, namespaces=namespaces, formal_programmes=programme_epochs,
                canonical_revision=canonical_revision, canonical_members=canonical, development_repair=repair,
                imports=imports, original_guards=guard_sources, filesystem_read_sites=read_sites,
                required_members={name: candidate[name] for name in sorted(required)},
                locality=dict(programme=prepare.blob(locality), directories=RUNTIME, files=[]),
                original_contracts=original[2], commands=prepare.cohorts(original[0]),
                roles=dict(historical=['prerequisites', 'association'],
                           primary=['publication', 'current', 'focused', 'book', 'native_book', 'source_views']),
                limits=dict(physical_checkout=False, semantic_acceptance=False, original_native_private=False,
                            full_alias=False, visual=False, hial=False, full_ci=False, push=False),
                scope='Complete fixed-Git source-constraint selection only. Whole source graphs, namespaces, '
                      'formal/import/runtime/canonical epochs and original contracts conjoin. Five publication '
                      'targets remain explicit fixed/afterimage roles. Physical checkout/custody and genuine '
                      'physical guard controls must qualify and commit before preparing any new intake. '
                      'No original producer, semantic reader or spent/unused cohort slot runs.')


def controls(value):
    # Intervene on the whole source image supplied to the real constraint
    # derivation. These are inert Git-tree controls, not physical-file controls.
    original = tree(REVISION)[1]
    late = tree('1a40a1da89216f4761ef73e67cefb029c78e8f94')[1]
    canonical_changed = next(name for name in sorted(value['canonical_members']) if late[name] != original[name])
    publication = tree('a0561d999b0354ed261289f66657bf8704c75ec9')[1]
    outcomes = {}
    for label, name in (('omitted_member', FACTORY), ('changed_mode', FACTORY), ('wrong_oid', FACTORY),
                        ('extra_member', BASES['consumer'] + '/undeclared.py'),
                        ('canonical_epoch', canonical_changed),
                        ('runtime_input', 't/python/test_record_value_current_publication.py')):
        candidate = copy.deepcopy(original)
        if label == 'omitted_member':
            del candidate[name]
        elif label == 'changed_mode':
            candidate[name]['mode'] = '100755' if candidate[name]['mode'] == '100644' else '100644'
        elif label == 'extra_member':
            candidate[name] = dict(candidate[FACTORY])
        elif label == 'wrong_oid':
            candidate[name]['oid'] = '0' * 40
        else:
            candidate[name] = (late if label == 'canonical_epoch' else publication)[name]
        assert candidate != original, 'genuine altered source: ' + label
        try:
            derive(REVISION, candidate)
        except AssertionError as error:
            outcomes[label] = str(error)
            continue
        raise AssertionError('incompatible source image admitted: ' + label)
    # Independently compare two actually captured bad whole-source epochs with
    # the same complete derivation. Both must fail without any semantic run.
    for revision in ('1a40a1da89216f4761ef73e67cefb029c78e8f94',
                     'a0561d999b0354ed261289f66657bf8704c75ec9'):
        try:
            derive(revision)
        except AssertionError as error:
            outcomes[revision] = str(error)
            continue
        raise AssertionError('known incompatible whole source admitted: ' + revision)
    assert not value['limits']['physical_checkout'] and not value['limits']['semantic_acceptance']
    return outcomes


def validate_record(candidate, expected):
    assert candidate == expected, 'closed complete source-epoch/role/contract/locality selection'
    return True


def record_controls(value):
    outcomes = {}
    for label in ('current_promotion', 'lost_contract', 'missing_directory', 'runtime_file', 'false_physical'):
        candidate = copy.deepcopy(value)
        if label == 'current_promotion':
            candidate['roles']['historical'].append('current')
        elif label == 'lost_contract':
            candidate['original_contracts'].pop(next(iter(candidate['original_contracts'])))
        elif label == 'missing_directory':
            candidate['locality']['directories'].pop()
        elif label == 'runtime_file':
            candidate['locality']['files'].append('.artifacts/tmp/undeclared')
        else:
            candidate['limits']['physical_checkout'] = True
        try:
            validate_record(candidate, value)
        except AssertionError as error:
            outcomes[label] = str(error)
            continue
        raise AssertionError('promoted or incomplete source selection admitted: ' + label)
    return outcomes


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = derive(REVISION)
    outcomes = controls(value)
    value['source_controls'] = outcomes
    value['record_controls'] = record_controls(value)
    if args.write:
        execute.save(PATH, value)
    else:
        assert validate_record(json.loads(gzip.decompress(execute.read(PATH))), value)
    print('Complete fixed-Git epoch conjunction passes; incompatible actual epochs refuse. '
          'Physical checkout and semantic acceptance remain unqualified; no intake starts.')
