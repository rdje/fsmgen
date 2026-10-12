"""Qualify the complete source-bound canonical proposal and committed recovery."""
import argparse
import stat

from canonical_common import *
import controls
import intake
import reader
import publish
import book_native
import recover

SUCCESS = 'PASS complete non-growing source-bound consumer canonical preparation; maintained publication and original consumer acceptance remain open.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}
PROGRAMMES = {'capture.py', 'canonical_common.py', 'intake.py', 'prepare.py', 'reader.py', 'controls.py',
              'publish.py', 'current_snapshot.py', 'book_native.py', 'verify.py', 'development_probe.py'}

RECOVERY_PROGRAMMES = PROGRAMMES | {'complete.py', 'recover.py'}
FIRST_LABELS = {'source-before', 'source-after', 'prepare', 'independent', 'controls', 'meaning',
                'factory-before', 'root-history', 'publication', 'source-published', 'current-after',
                'focused', 'book', 'book-native', 'native', 'size', 'claims', 'inventory-write'}


def programme_epochs():
    original = read('formal-programmes.json')
    current = read('formal-programmes-recovery.json')
    repair = read('repair-programmes.json')
    need(set(original) == PROGRAMMES and set(current) == RECOVERY_PROGRAMMES
         and {path.name for path in BASE.glob('*.py')} == RECOVERY_PROGRAMMES,
         'complete original and repaired programme domains')
    before = original['verify.py']['body']
    old, new = repair['old'], repair['new']
    need(before.count(old) == 1 and before.replace(old, new, 1) == current['verify.py']['body'],
         'unique complete default entrypoint recovery correspondence')
    need(all(original[name] == current[name] for name in PROGRAMMES - {'verify.py'}),
         'every original non-entrypoint programme remains immutable')
    need(all(entry['body'].encode() == (BASE / name).read_bytes()
             and pin(entry['body'].encode()) == entry['identity'] for name, entry in current.items()),
         'whole current repaired programme bytes and identities')
    return original, current


def read(name):
    return json.loads((BASE / name).read_bytes())


def gate(label, command, stdout=None, *, current=False, formal=True, status=0, declared=None):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
         and all(same(row[key], value) for key, value in started.items()), 'closed complete native preparation terminal')
    expected = status if declared is None else declared
    need(type(row['status']) is int and row['status'] == status
         and type(row['expected_status']) is int and row['expected_status'] == expected, 'distinct exact actual and declared integer outcomes')
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(row['programmes'], row['programmes_after']), 'whole actual command and programme epoch')
    own = {Path(name).name: entry for name, entry in row['programmes'].items() if Path(name).parent == BASE}
    prior, repaired = programme_epochs()
    selected = prior if label in FIRST_LABELS or label == 'development' else repaired
    need(set(own) == set(selected), 'complete actual declared programme epoch domain')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole native programme or argument body')
        if current:
            if name == str(BASE / 'verify.py') and selected is prior:
                need(body.decode() == prior['verify.py']['body']
                     and Path(name).read_text() == repaired['verify.py']['body'],
                     'whole dated first entrypoint and exact current recovery successor')
            else:
                need(Path(name).read_bytes() == body, 'whole explicitly current native programme or input')
    if formal:
        need(same(own, selected), 'whole separately frozen original or repaired source epoch')
    need(type(row['stdout']) is str and type(row['stderr']) is str
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged native guard and complete terminal')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended actual native output')
    return row


def contracts():
    original = nodes(git('show', PLAN['revision'] + ':' + TASK))
    active = nodes(intake.overlays()[TASK])
    parent, consumer = PLAN['parent'], PLAN['consumer']
    additions = {parent + '.' + str(i) for i in (1, 2, 3)}
    need(set(active) == set(original) | additions and not additions.intersection(original), 'only declared canonical child decomposition')
    for name, block in original.items():
        if name == parent:
            need(all(field(active[name], key) == field(block, key) for key in ('Goal', 'Acceptance', 'Verification', 'Commit'))
                 and field(block, 'Status') == 'pending' and field(active[name], 'Status') == 'active'
                 and field(active[name], 'Children') == ', '.join(parent + '.' + str(i) for i in (1, 2, 3)),
                 'whole unchanged canonical obligation with safe child decomposition')
        else:
            need(block == active[name], 'every original whole task contract retains')
    need(field(active[consumer], 'Status') == 'active'
         and all(field(active[consumer + '.' + str(i)], 'Status') == 'done' for i in (1, 2))
         and field(active[PLAN['owner']], 'Status') == 'active'
         and all(field(active[parent + '.' + str(i)], 'Status') == 'pending' for i in (2, 3))
         and field(active[consumer + '.4'], 'Status') == 'pending', 'complete committed meanings and separately open successors')
    return {name: active[name].decode() for name in sorted(additions | {parent, consumer})}


def core(*, current=False):
    programme_epochs()
    commit = read('meaning-normal-commit.json')
    need(set(commit) == {'command', 'status', 'stdout', 'stderr'} and type(commit['status']) is int and commit['status'] == 0
         and commit['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and PLAN['revision'][:9] in commit['stdout'].splitlines()[0]
         and '[doctrine] all doctrine checks passed' in commit['stdout'] + commit['stderr'], 'whole previous normal meaning commit and hooks')
    source = intake.derive()
    need(same(source, read('source-roles.json')) and same(read('source-before.json'), read('source-after.json')),
         'whole original/current source graph and conserved prepublication epoch')
    census = read('source-before.json')
    need(census['source'] == pin(canonical(source['publication']))
         and census['overlays'] == {name: pin(body) for name, body in intake.overlays().items()}, 'whole source census and exact activation overlays')
    gates = {}
    for epoch in ('before', 'after'):
        gates['source-' + epoch] = gate('source-' + epoch, ['python3', '-B', str(BASE / 'intake.py'), '--' + epoch], intake.SUCCESS, current=current)
    gates['prepare'] = gate('prepare', ['python3', '-B', str(BASE / 'prepare.py')],
        'Prepared complete non-growing consumer canonical candidate; live canonical production remains unchanged.\n', current=current)
    gates['independent'] = gate('independent', ['python3', '-B', str(BASE / 'reader.py')], reader.SUCCESS, current=current)
    gates['controls'] = gate('controls', ['python3', '-B', str(BASE / 'controls.py')],
        'PASS complete genuine prior-preserving canonical proposal controls; original native and private limits retain.\n', current=current)
    gates['meaning'] = gate('meaning', ['python3', '-B', PLAN['meaning'] + '/verify.py'],
        'PASS complete unchanged independent consumer-meaning parent acceptance; canonical/original parent and higher owners retain.\n', current=current)
    gates['factory-before'] = gate('factory-before', ['python3', '-B', 'scripts/check_record_value_publication.py'],
        original_public()['SUCCESS'], current=current)
    history_command = ['git', 'log', '-1', '-S', 'Publish only admitted source-bound consumer canonical meanings.', '--format=%H %s', '--', 'docs/tasks/']
    gates['root-history'] = gate('root-history', history_command, current=current)
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', gates['root-history']['stdout']), 'whole original canonical obligation history locus')
    candidate = read('candidate.json')
    inputs = reader.context()
    qualification = reader.check(candidate, inputs)
    need(same(qualification, read('qualification.json')), 'whole independent canonical source meaning qualification')
    falsification = controls.qualify(candidate, inputs)
    need(same(falsification, load_product('controls.json.gz')), 'every complete separating product and intended library refusal retains')
    development = gate('development', ['python3', '-B', str(BASE / 'development_probe.py')],
        'PASS development-only complete canonical proposal, capacity, controls and publication interfaces.\n', formal=False)
    need(read('development-phase.json')['formal_started'] is False
         and read('development-phase.json')['owner'] == PLAN['owner'], 'separate declared development-only epoch')
    dev = load_product('development-products.json.gz')
    need(same(dev['candidate'], candidate) and same(dev['qualification'], qualification)
         and same(dev['controls'], falsification), 'whole independently requalified development proposal and library refusals')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], source=pin(canonical(source)),
        normal_commit=pin(canonical(commit)), contracts=contracts(), qualification=qualification,
        controls=dict(product=pin(canonical(falsification)), role=falsification['role'],
            refusals=[dict(name=row['name'], exception=row['exception'], cause=row['cause']) for row in falsification['controls']]),
        gates={name: pin(canonical(row)) for name, row in gates.items()}, development=pin(canonical(development)),
        legs=dict(rederive='Fixed complete canonical/source/meaning contracts, reviewed whole before/after correspondence, original independent meanings, direct/cached question allocation and all physical capacity metrics.',
                  falsify='Genuine complete omitted/borrowed/Boolean/meaning/native-boundary products reach intended library ValueError refusals inside the native guarded qualifier. All original semantic/native controls retain.',
                  durability='Whole original/current source and normal commit, canonical beforeimages, proposal, review, full native programmes/commands/streams and saved reader; ignored checkpoints are not required.'),
        condition=PLAN['condition'])


def delivery(*, current=False):
    publication = publish.qualify(current=False)  # Exact first publication, never relabelled current.
    pubgate = gate('publication', ['python3', '-B', str(BASE / 'publish.py')],
        'Prepared source-bound consumer canonical meanings; live publication and consumer-parent acceptance remain next.\n', current=current)
    sourcegate = gate('source-published', ['python3', '-B', str(BASE / 'intake.py'), '--published'], intake.SUCCESS, current=current)
    source = read('source-published.json')
    roles = read('source-roles.json')
    need(source['source'] == pin(canonical(roles['publication']))
         and source['overlays'] == {name: pin(body) for name, body in intake.overlays(True).items()}, 'complete postpublication source and metadata allocation')
    currentgate = gate('current-after', ['python3', '-B', str(BASE / 'current_snapshot.py'), 'after'],
        'PASS complete current unchanged canonical meanings and whole source/query/capacity input: after.\n', current=current)
    canonical_after = load_product('canonical-after.json.gz')
    need(same(canonical_after, load_product('canonical-sources.json.gz')), 'whole canonical production remains unchanged after preparation')
    public = original_public(); prior = public['historical']()
    record = load_product('current-after.json.gz')
    public['check'](record, {name: text.encode() for name, text in canonical_after.items()}, prior, public['authority'](prior))
    review = read('book-review.json')
    snapshots = publication['snapshots']
    before = {name: gzip.decompress(Path(row['before']['snapshot']).read_bytes()) for name, row in snapshots.items()}
    proposed, _ = publish.transformation(before)
    dev = load_product('development-products.json.gz')
    need(same(dev['publication'], {name: body.decode() for name, body in proposed.items()})
         and dev['publication_metrics'] == {key: publication[key] for key in ('task_names', 'book_names', 'task_metrics', 'book_before', 'book_after')},
         'whole development and formal metadata publication correspondence')
    need(record['chapter'].encode() == proposed[BOOK], 'whole current canonical-input book afterimage')
    for line in before[BOOK].splitlines():
        if re.search(rb'[0-9]|UTF-8', line):
            need(proposed[BOOK].splitlines().count(line) == before[BOOK].splitlines().count(line), 'every original quantitative and encoding disposition line retains')
    html = gzip.decompress((BASE / 'native-chapter.html.gz').read_bytes()).decode()
    native = book_native.qualify(html)
    need(native == read('book-native.json'), 'whole actual native book scope and command')
    nativegate = gate('book-native', ['python3', '-B', str(BASE / 'book_native.py')],
        'PASS whole native canonical-preparation scope guidance and dated original scope.\n', current=current)
    external = {name: pin(canonical(gate(name, command, current=current, status=1 if name == 'size' else 0, declared=0))) for name, command in publish.COMMANDS.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'actual focused preparation regression success')
    return dict(publication=publication, source=source, current=pin(canonical(record)), book_review=review, book_native=native,
                external=external, gates={name: pin(canonical(row)) for name, row in (
                    ('publication', pubgate), ('source-published', sourcegate), ('current-after', currentgate), ('book-native', nativegate))})



def recovery(*, current=False):
    row = recover.qualify(current=current)
    first = gate('size', ['scripts/check_live_document_size.sh'], status=1, declared=0, current=current)
    need('live-doc-size: surface active_resume is at 81.8% and must declare warning_debt' in first['stderr'],
         'whole actual first unexpected pointer health failure remains non-success')
    commands = {
        'recovery-preview': (['python3', '-B', str(BASE / 'recover.py'), '--preview'], 0),
        'recovery-publication': (['python3', '-B', str(BASE / 'recover.py')], 0),
        'negative-before': (['python3', '-B', str(BASE / 'recover.py'), '--negative-before'], 0),
        'size-reproduce': (['scripts/check_live_document_size.sh'], 1),
        'negative-after': (['python3', '-B', str(BASE / 'recover.py'), '--negative-after'], 0),
        'size-repaired': (['scripts/check_live_document_size.sh'], 0),
        'recovery-source': (['python3', '-B', str(BASE / 'recover.py'), '--source'], 0),
        'inventory-repaired-write': (['scripts/check_claim_verification_inventory.pl', '--write'], 0)}
    gates = {name: pin(canonical(gate(name, command, current=current, status=status)))
             for name, (command, status) in commands.items()}
    refusal = read('size-reproduce-actual.json')
    need('live-doc-size: surface active_resume is at 81.8% and must declare warning_debt' in refusal['stderr'],
         'same intended actual native pointer health refusal')
    _, _, after, _ = recover.transformation()
    need(same(load_product('recovery-preview.json.gz'), {name: body.decode() for name, body in after.items()}),
         'whole saved recovery preview equals final maintained metadata')
    source = read('recovery-source.json')
    roles = read('source-roles.json')
    need(source['source'] == pin(canonical(roles['publication']))
         and source['overlays'] == {name: pin(body) for name, body in after.items()},
         'whole repaired current source census and metadata epoch')
    negative_before, negative_after = read('negative-source-before.json'), read('negative-source-after.json')
    need(negative_before['before'] == negative_after['after'] == {name: pin(body) for name, body in after.items()}
         and negative_before['replacement'] == pin(recover.snapshots()['MEMORY.md'])
         and negative_after['refusal'] == pin(canonical(refusal)), 'complete pointer-only intervention, native refusal and restoration residue')
    return dict(publication=row, gates=gates, source=source, first_failure=pin(canonical(first)),
                negative_before=negative_before, negative_after=negative_after,
                condition='Original formal size failure remains actual1/declared0. An actual old-pointer control is1/1; restored bounded pointer is0/0. Both source epochs and all original meanings retain; no ceiling grows.')


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        need(not path.is_symlink() and stat.S_ISREG(path.lstat().st_mode)
             and path.stat().st_dev == Path.cwd().stat().st_dev, 'whole ordinary same-volume flat preparation archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(path.stat().st_mode & 0o111))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true'); parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true'); args = parser.parse_args()
    need(not (args.core and args.seal), 'one explicit preparation role')
    result = core(current=args.current or args.seal)
    if args.core:
        print('PASS complete source-bound consumer canonical preparation core; maintained production remains unchanged.')
    else:
        result['delivery'] = delivery(current=args.current or args.seal)
        result['recovery'] = recovery(current=args.current or args.seal)
        need(json.loads(canonical(result)) == result, 'whole lossless JSON-native preparation proof')
        if args.seal:
            save('proof.json', result); save('manifest.json', catalogue())
        else:
            need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()), 'whole immutable saved canonical preparation')
        print(SUCCESS, end='')
