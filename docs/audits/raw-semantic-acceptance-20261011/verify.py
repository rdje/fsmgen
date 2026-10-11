"""Unchanged complete raw semantic parent acceptance; canonical publication remains open."""
import argparse
import re
from common import *
import intake
import fixed_view

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
SUCCESS = 'PASS unchanged complete original raw semantic parent acceptance; canonical publication and original native/private/higher scopes remain open.\n'
DEFAULTS = [
    ('admission', ADMISSION / 'verify.py', 'PASS complete dated raw-semantic admission, whole fixed/current source/native/product custody, fresh source/dated reader roles and genuine controls; full raw association/publication and original native/private scopes remain open.\n'),
    ('association', PRIOR / 'verify.py', 'PASS unchanged complete original raw-body association acceptance; full raw semantic parent, canonical publication and original native/private scopes remain open.\n'),
    ('construction', CONSTRUCTION / 'verify.py', 'PASS complete source-bound raw-body candidate construction, independent whole original body conservation and strict dated custody; independent semantic reconstruction and separating controls remain pending.\n'),
    ('layout', REPAIR / 'qualify.py', 'PASS whole first repair epoch, dated original reader, typed source copies, fresh separate native width parity and exact retirement; all document allowances remain unchanged.\n'),
    ('custody', CUSTODY / 'verify.py', 'PASS complete required archive and whole construction/repair Git custody; original semantic/native/private scopes conserve.\n'),
    ('semantic', SEMANTIC / 'verify.py', 'PASS complete finite original raw semantic associations and genuine prior-preserving controls; original native/private and parent/publication scopes remain open.\n'),
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
    expected_roots = list(map(str, (CONSTRUCTION, REPAIR, CUSTODY, SEMANTIC, PRIOR, CLARITY)))
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
    need(source == load('intake-after.json') == intake.derive(), 'whole complete raw semantic fixed/current source/native/product epoch')
    contract = contracts()
    defaults = {}
    for timing in ('before', 'after'):
        for role, path, success in DEFAULTS:
            defaults[timing + '-' + role] = pin(canonical(actual(timing + '-' + role, ['python3', '-B', str(path)], success)))
    history = actual('root-history', ['git', 'log', '-1', '-S', 'def core', '--format=%H %s', '--', str(PRIOR / 'verify.py')])
    need(history['stdout'].startswith(REVISION + ' ') and history['stderr'] == '', 'actual git log -S complete association prerequisite history')
    focused = actual('focused', FOCUSED)
    need('All tests successful.' in focused['stdout'] and focused['stderr'] == '', 'complete focused raw-parent regressions')
    specs = fixed_view.specifications()
    product = load('readers.json')
    need(product['owner'] == LEAF and product['revision'] == REVISION and product['scope'] == SCOPE
         and set(product['readers']) == set(specs), 'complete original prerequisite reader/role allocation')
    actuals = {}
    for name, spec in specs.items():
        entry = product['readers'][name]
        member = entry['receipt']
        need(re.fullmatch('reader-[A-Za-z0-9]+-' + re.escape(name) + '-actual.json', member) is not None
             and entry['specification'] == spec and entry['identity'] == identity(BASE / member), 'whole fresh owned prerequisite result')
        row = load(member)
        fixed_view.qualify_reader(row, spec)
        actuals[name] = dict(specification=spec, actual=pin(canonical(row)))
    need(load(product['source_before']) == load(product['source_after']) == source,
         'every complete source/native/product byte and directory conserves across fresh prerequisite readers')
    run = actual('fresh-readers', ['python3', '-B', str(BASE / 'fixed_view.py'), '--readers', '--attempt', 'A'])
    expected_output = ''.join('qualified complete fresh raw-parent prerequisite ' + name + '\n'
        for name in sorted(specs, key=lambda n: (n == 'address-coordinate', n)))
    need(run['stdout'] == expected_output and run['stderr'] == '', 'actual complete terminal prerequisite group, never an incomplete aggregate')
    bodies, members = fixed_view.materialize()
    declared = load('fixed-view-source.json')
    need(declared['revision'] == REVISION and declared['members'] == members and declared['population'] == fixed_view.expected(members)
         and declared['original_programme'] == bodies[str(CLARITY / 'verification.json')].decode(), 'whole unchanged committed clarity programme/source context')
    advanced = gzip.decompress(local(BASE / 'advanced-task-candidate.md.gz').read_bytes())
    need(advanced == bodies[TASK].replace(('- ID: `' + LEAF + '`\n  Status: `pending`\n').encode(),
         ('- ID: `' + LEAF + '`\n  Status: `active`\n').encode(), 1) and advanced != bodies[TASK],
         'whole genuine later task activation is the sole fixed-view intervention')
    controls = load('fixed-view-controls.json')
    need(controls['source'] == pin(canonical(declared)) and controls['scope'] == SCOPE
         and controls['candidate'] == 'advanced-task-candidate.md.gz'
         and controls['positive'] == 'fixed-view-positive-before-actual.json'
         and controls['negative'] == 'fixed-view-advanced-task-actual.json'
         and controls['restored'] == 'fixed-view-positive-after-actual.json', 'complete original fixed-context control allocation')
    for role in ('positive', 'negative', 'restored'):
        fixed_view.qualify_view(load(controls[role]), fixed_view.expected(members, advanced if role == 'negative' else None), negative=role == 'negative')
    view_run = actual('fixed-view-controls', ['python3', '-B', str(BASE / 'fixed_view.py'), '--view-controls'],
        'PASS whole committed clarity context, genuine advanced-task refusal and exact restoration; no original programme edit or later currency.\n')
    fresh_context = fixed_view.replay_view()
    semantic = read(SEMANTIC / 'proof.json')
    association = read(PRIOR / 'proof.json')
    prior_controls = read(SEMANTIC / 'bounded-controls.json')
    need(semantic['semantic']['controls'] == pin(canonical(prior_controls))
         and [r['name'] for r in association['association']['obligations'][2]['controls']] == [r['name'] for r in prior_controls['cases']],
         'whole genuine semantic candidate/control allocation and complete committed association witness conserve')
    bindings = {role: dict(path=str(Path('docs/audits') / path), source=source['members'][str(Path('docs/audits') / path)]) for role, path in PATHS.items()}
    obligations = [
        dict(obligation='Bind and reexecute all complete primary/source/context/inventory/class/frame/observer/header/coordinate/address products in their exact declared source or dated roles.',
             readers=actuals, sources=bindings, group=pin(canonical(run)), source=pin(canonical(source))),
        dict(obligation='Independently join each whole original own class/message/frame/argument/source-coordinate/address role and nested inner/outer cause without byte normalization.',
             independent=semantic['semantic']['independent'], association=pin(canonical(association)), fresh_defaults=defaults),
        dict(obligation='All genuine complete semantic interventions reach their intended refusals while every prior meaning and full first failure epoch conserves.',
             controls=association['association']['obligations'][2], first_boolean=identity(SEMANTIC / 'boolean-phase-first-semantic-actual.json'),
             first_ram=identity(SEMANTIC / 'ram-cutoff.json'), source_scope=semantic['scope']),
        dict(obligation='Preserve exact inherited native/private/identity uncertainty and all completed admission/association descendant contracts; current publication is separately qualified.',
             checkpoint=checkpoint(source), contracts=contract, fixed_context=dict(source=pin(canonical(declared)), controls=pin(canonical(controls)), actual=pin(canonical(view_run)), fresh=fresh_context),
             scope=SCOPE, focused=pin(canonical(focused))),
    ]
    return dict(contracts=contract, obligations=obligations, scope=SCOPE,
        independence='Whole original raw semantic parent obligations join the fresh complete declared reader corpus, separate committed source-first semantic reconstruction and genuine unchanged controls. Exact original clarity programme replay uses the complete committed task/book/authority context, not a changed oracle or later current result. Qualified source models remain shared assumptions; original native/private measurements remain absent.')


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
        print('PASS complete unchanged raw semantic obligations, all fresh prerequisite readers, exact fixed context and whole source custody; publication remains required.')
    else:
        proof = dict(owner=LEAF, revision=REVISION, scope=SCOPE, raw_semantic=qualified, publication=publication(), external=external(),
            legs=dict(rederive='Whole original raw semantic contracts, complete fixed/current source/native/product custody, every fresh declared prerequisite and complete association defaults.',
                      falsify='Complete genuine semantic controls and first Boolean/RAM epochs retain under unchanged source/programme custody. The unchanged original clarity programme rejects the actual later Task activation and passes its exact committed triple before and after restoration.',
                      durability='Complete products and source graphs remain tracked; fresh programmes/commands/streams, exact publication snapshots and strict namespace retain in this owning commit.'),
            condition='All admitted source/native/product/instrument bytes, modes, members and directories match the complete 48455c13 checkpoint. Source and dated reader roles stay explicit; complete fixed-context clarity replay creates no later live currency. Original native/private identities remain unmeasured, and governed canonical raw publication remains separately owned. Current staged doctrines and normal hooks additionally gate this owning commit.')
        if args.seal:
            save('proof.json', proof)
            save('manifest.json', catalog())
        else:
            need(load('proof.json') == proof and load('manifest.json') == catalog(), 'whole strict unchanged association acceptance proof and namespace')
        print(SUCCESS, end='')
