"""Unchanged complete association acceptance; broader raw publication remains open."""
import argparse
import re
from common import *
import intake
import replay

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
SUCCESS = 'PASS unchanged complete original raw-body association acceptance; full raw semantic parent, canonical publication and original native/private scopes remain open.\n'
DEFAULTS = [
    ('construction', CONSTRUCTION / 'verify.py', 'PASS complete source-bound raw-body candidate construction, independent whole original body conservation and strict dated custody; independent semantic reconstruction and separating controls remain pending.\n'),
    ('layout', REPAIR / 'qualify.py', 'PASS whole first repair epoch, dated original reader, typed source copies, fresh separate native width parity and exact retirement; all document allowances remain unchanged.\n'),
    ('custody', CUSTODY / 'verify.py', 'PASS complete required archive and whole construction/repair Git custody; original semantic/native/private scopes conserve.\n'),
    ('semantic', PRIOR / 'verify.py', 'PASS complete finite original raw semantic associations and genuine prior-preserving controls; original native/private and parent/publication scopes remain open.\n'),
]
FOCUSED = ['prove', '-v', 't/1549-task-tree-integrity-doctrine.t', 't/1636-claim-verification-doctrine.t',
           't/1303-isf-public-live-book-paths-audit.t', 't/1305-isf-book-feature-matrix-audit.t']


def read(path):
    raw = local(path).read_bytes()
    value = json.loads(raw)
    need(raw == canonical(value), 'whole canonical fixed association prerequisite')
    return value


def nodes(raw):
    matches = list(re.finditer(rb'^- ID: `([^`]+)`\n.*?(?=^- ID: |\Z)', raw, re.M | re.S))
    result = {m[1].decode(): m[0] for m in matches}
    need(len(result) == len(matches), 'complete unique association task identities')
    return result


def field(block, name):
    match = re.search(rb'^  ' + name.encode() + rb': `(.*)`$', block, re.M)
    return match[1] if match else None


def contracts(final=None):
    original = git('show', REVISION + ':' + TASK)
    declared = gzip.decompress(local(BASE / 'declared-task.md.gz').read_bytes())
    old, start = nodes(original), nodes(declared)
    need(set(old) == set(start), 'whole original association task population conserved at activation')
    for key in old:
        if key == LEAF:
            need(start[key] == old[key].replace(b'  Status: `pending`\n', b'  Status: `active`\n', 1)
                 and field(old[key], 'Status') == b'pending', 'sole association closure leaf activation')
        else:
            need(old[key] == start[key], 'every other original association contract conserved at activation')
    descendants = sorted(key for key in old if key.startswith(OWNER + '.'))
    need(field(old[OWNER], 'Status') == b'active' and LEAF in descendants
         and all(field(old[key], 'Status') == b'done' for key in descendants if key != LEAF),
         'all complete association construction, custody, semantic and repair descendants committed first')
    if final is not None:
        end = nodes(final)
        need(set(end) == set(old), 'whole original task graph conserved at association closure')
        for key in old:
            if key in (OWNER, LEAF):
                need(all(field(old[key], k) == field(start[key], k) == field(end[key], k) for k in ('Goal', 'Acceptance', 'Children'))
                     and field(end[key], 'Status') == b'done', 'original complete association acceptance closes unchanged')
            else:
                need(old[key] == end[key], 'every unrelated node and completed descendant conserves exactly')
    return dict(original=pin(original), declared=pin(declared), final=pin(final) if final is not None else None,
        contracts={key: dict(goal=field(old[key], 'Goal').decode(), acceptance=(field(old[key], 'Acceptance') or b'').decode(),
            children=(field(old[key], 'Children') or b'').decode(), status=field(old[key], 'Status').decode())
            for key in [OWNER, *descendants]})


def actual(name, command, expected=None, negative=False):
    row = load('checks.json')[name]
    need(row['command'] == command and type(row.get('status')) is int
         and (row['status'] != 0 if negative else row['status'] == 0)
         and row['programmes'] == row['programmes_after'] == programs()
         and row['inputs'] == row['inputs_after'] and row['epoch_conserved'] is True,
         'actual complete association qualification command/status/epoch: ' + name)
    need(local(row['stdout_path']).read_bytes() == row['stdout'].encode()
         and local(row['stderr_path']).read_bytes() == row['stderr'].encode(), 'whole external gate streams: ' + name)
    if expected is not None:
        need(row['stdout'] == expected and row['stderr'] == '', 'whole intended association predecessor success: ' + name)
    return row


def checkpoint(source):
    row = load('prerequisite-checkpoint.json')
    expected_roots = list(map(str, (CONSTRUCTION, REPAIR, CUSTODY, PRIOR)))
    need(row['revision'] == REVISION and row['roots'] == expected_roots and row['whole_head_source_parity'] is True,
         'actual clean committed association prerequisite checkpoint')
    names = sorted(name for name in source['members'] if any(name.startswith(root + '/') for root in expected_roots))
    digest = hashlib.sha256()
    for name in names:
        with local(name).open('rb') as stream:
            while chunk := stream.read(1048576):
                digest.update(chunk)
    need(type(row['members']) is int and row['members'] == len(names)
         and type(row['bytes']) is int and row['bytes'] == sum(source['members'][name]['bytes'] for name in names)
         and row['ordered_complete_bytes_sha256'] == digest.hexdigest()
         and type(row['directories']) is int and row['directories'] == sum(
             any(name == root or name.startswith(root + '/') for root in expected_roots) for name in source['directories'])
         and row['archive'] == str(REPAIR / 'first-epoch.zip') and row['archive'] in names,
         'whole committed prerequisite member/byte/directory/archive checkpoint independently rederived')
    return pin(canonical(row))


def core():
    source = load('intake-before.json')
    need(source == load('intake-after.json') == intake.derive(), 'every complete fixed/current source/native/product byte, mode and directory conserves')
    task_contracts = contracts()
    defaults = {}
    for timing in ('before', 'after'):
        for role, path, success in DEFAULTS:
            row = actual(timing + '-' + role, ['python3', '-B', str(path)], success)
            defaults[timing + '-' + role] = pin(canonical(row))
    history = actual('root-history', ['git', 'log', '-1', '-S', 'semantic_links', '--format=%H %s', '--', str(PRIOR / 'reader.py')])
    need(history['stdout'].startswith(REVISION + ' ') and history['stderr'] == '', 'actual git log -S semantic reconstruction history locus')
    focused = actual('focused', FOCUSED)
    need('All tests successful.' in focused['stdout'] and focused['stderr'] == '', 'actual focused association regressions')
    saved = load('fresh-controls.json')
    observed = replay.rows()
    need([(r['name'], r['cause'], r['member']) for r in saved['cases']] == [(r['name'], r['cause'], r['member']) for r in observed]
         and saved['scope'] == SCOPE, 'complete fresh original positive and hostile control allocation')
    outcomes = []
    for row in saved['cases']:
        for kind in ('native', 'semantic'):
            need(row[kind] == 'fresh-' + row['name'] + '-' + kind + '-actual.json', 'exact current control result ownership')
            result = load(row[kind])
            replay.validate(result, row['name'], kind, row['cause'], row['member'])
        outcomes.append(dict(name=row['name'], cause=row['cause'], member=str(PRIOR / row['member']),
            candidate=identity(PRIOR / row['member']), native=pin(canonical(load(row['native']))), semantic=pin(canonical(load(row['semantic'])))))
    typed = actual('typed-positive', ['perl', str(PRIOR / 'typed.pl'), str(PRIOR / 'candidate.json.gz')],
                   'PASS independent semantic JSON integer record and phase coordinates.\n')
    negative = actual('typed-negative', ['perl', str(PRIOR / 'typed.pl'), str(PRIOR / 'boolean-phase-first.json.gz')], negative=True)
    need(negative['stdout'] == '' and negative['stderr'].startswith('semantic phase coordinate requires a JSON integer at ' + str(PRIOR / 'typed.pl') + ' line '),
         'actual intended independent Boolean wire-kind refusal')
    first = read(PRIOR / 'boolean-phase-first-semantic-actual.json')
    need(type(first['status']) is int and first['status'] == 0 and first['stdout'] == replay.SEMANTIC and first['stderr'] == '',
         'complete first false-green epoch retained without reclassification')
    semantic = read(PRIOR / 'proof.json')
    independent = read(PRIOR / 'independent-bounded.json')
    need(semantic['semantic']['independent'] == independent and semantic['semantic']['controls'] == pin(local(PRIOR / 'bounded-controls.json').read_bytes()),
         'complete independent reconstruction and genuine whole-candidate proofs remain bound')
    bindings = {role: dict(path=str(Path('docs/audits') / path), source=source['members'][str(Path('docs/audits') / path)]) for role, path in PATHS.items()}
    obligations = [
        dict(obligation='Every whole original class/message/frame/argument/source-coordinate/address role independently reconstructed without byte normalization or invented identity.',
             sources=bindings, independent=independent, reader=str(PRIOR / 'reader.py'), fresh_defaults=defaults),
        dict(obligation='Visible/opaque/private boundaries and complete nested inner/outer cause association conserve.',
             scope=semantic['scope'], proof=pin(canonical(semantic)), controls=['opaque-promotion', 'scope-promotion', 'nested-cause', 'class-promotion', 'load-operator']),
        dict(obligation='Every genuine complete mutation reaches its intended new assertion while all inherited meanings conserve.',
             controls=outcomes, exact_mutation_custody=str(PRIOR / 'bounded.py'), original_body_predicate=str(PRIOR / 'native.pl')),
        dict(obligation='Full positive/hostile bodies, exact inherited source/native custody and actual independent readers retain before current publication qualification.',
             checkpoint=checkpoint(source), source=pin(canonical(source)), typed_positive=pin(canonical(typed)), typed_negative=pin(canonical(negative)),
             first_boolean=pin(canonical(first)), first_ram=pin(local(PRIOR / 'ram-cutoff.json').read_bytes()), focused=pin(canonical(focused))),
    ]
    return dict(contracts=task_contracts, obligations=obligations, scope=SCOPE,
        independence='Closure joins the unchanged original contracts to fresh actual complete predecessor and control executions. Semantic truth remains supplied by the separate committed source-first reader and qualified shared source models; this witness creates no new native or private measurement.')


def publication():
    import publish
    record = load('publication.json')
    tasks = fixed_sources(record['task_names'])
    task = gzip.decompress(local(BASE / 'qualified-task.md.gz').read_bytes())
    tasks[TASK] = task
    need(metrics(tasks) == load('task-census.json'), 'whole measured association task collection')
    books = fixed_sources(record['book_names'])
    before = gzip.decompress(local(BASE / 'book-before.md.gz').read_bytes())
    after = gzip.decompress(local(BASE / 'book-after.md.gz').read_bytes())
    need(before == books[BOOK] and after == before.replace(publish.MARKER, publish.ADDITION + publish.MARKER, 1), 'whole exact finite association book publication')
    registry = fixed_sources([SURFACES])[SURFACES]
    need(local(BASE / 'registry-before.txt').read_bytes() == registry
         and local(BASE / 'registry-after.txt').read_bytes() == publish.authority(registry, tasks, books, after), 'whole measured association authority without widened allowances')
    return dict(contracts=contracts(task), book=pin(after), registry=pin(local(BASE / 'registry-after.txt').read_bytes()))


def external():
    commands = {
        'book-build': ['mdbook', 'build', 'docs/book'],
        'current-native': ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', 'docs/book/book'],
        'size': ['scripts/check_live_document_size.sh'],
        'claims': ['scripts/check_claim_verification.pl'],
        'inventory': ['scripts/check_claim_verification_inventory.pl'],
    }
    return {name: pin(canonical(actual(name, command))) for name, command in commands.items()}


def catalog():
    return {path.name: identity(path) for path in sorted(BASE.iterdir()) if local(path).name not in ('checks.json', 'manifest.json')}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one complete association proof role')
    qualified = core()
    if args.core:
        print('PASS complete unchanged association obligations, descendant contracts, fresh controls and whole source custody; publication still requires qualification.')
    else:
        proof = dict(owner=LEAF, revision=REVISION, scope=SCOPE, association=qualified, publication=publication(), external=external(),
            legs=dict(rederive='Complete fixed/current binary Git/source, unchanged original task contracts, full independent semantic reconstruction and fresh predecessor defaults.',
                      falsify='Every complete committed semantic intervention freshly executes both the unchanged body predicate and separate source-first semantic reader, reaching its intended refusal. Independent native JSON-kind refusal and complete first false-green/RAM epochs retain.',
                      durability='Complete products and source graphs remain tracked; fresh programmes/commands/streams, exact publication snapshots and strict namespace retain in this owning commit.'),
            condition='All admitted instruments and source/native/product namespaces remain byte/mode/member/directory identical to cd84713b. Complete reader executions qualify this dated closure; original pre-serialization native/private identities and full raw publication are unmeasured or separately owned. Staged doctrines and normal hooks additionally gate the owning commit.')
        if args.seal:
            save('proof.json', proof)
            save('manifest.json', catalog())
        else:
            need(load('proof.json') == proof and load('manifest.json') == catalog(), 'whole strict unchanged association acceptance proof and namespace')
        print(SUCCESS, end='')
