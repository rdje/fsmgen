"""Qualify complete unchanged meaning acceptance and exact bounded delivery."""
import argparse
import copy
import stat
from acceptance_common import *
import book_native
import controls
import intake
import parent_model as model
import publish
import reader

SUCCESS = 'PASS complete unchanged independent consumer-meaning parent acceptance; canonical/original parent and higher owners retain.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


def gate(label, command, status=0, stdout=None, *, declared=None, current=False, development=False):
    declared = status if declared is None else declared
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
         and all(same(row[key], value) for key, value in started.items()), 'closed whole meaning-parent native terminal')
    need(type(row['status']) is int and row['status'] == status
         and type(row['expected_status']) is int and row['expected_status'] == declared,
         'distinct typed observed and declared native status roles: ' + label)
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(row['programmes'], row['programmes_after']), 'whole exact command and conserved native programme epoch')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole native programme body and identity')
        if current and not development:
            need(Path(name).read_bytes() == body, 'whole explicit current native programme')
    own = {name: entry for name, entry in row['programmes'].items() if Path(name).parent == BASE}
    if development:
        epoch = read('development-epochs.json')['epochs'][label]
        need(same(own, epoch['programmes']) and epoch['actual'] == pin((BASE / (label + '-actual.json')).read_bytes()),
             'whole explicitly dated non-acceptance development programme epoch')
    else:
        need(same(own, read('formal-programmes.json')['programmes']), 'whole frozen formal native programme population and bodies')
    need(type(row['stdout']) is type(row['stderr']) is str
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged whole native RAM guard')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended native terminal')
    return pin(canonical(row))


def development():
    phase, epochs = read('development-phase.json'), read('development-epochs.json')
    need(phase['owner'] == epochs['owner'] == PLAN['owner'] and 'development' in phase['phase']
         and set(epochs['epochs']) == {'development-interface', 'development-mutations', 'development-refusals', 'development-publication'},
         'complete explicitly declared non-acceptance development roles')
    texts = {
        'development-interface': ('development_probe.py', 'PASS development-only complete committed helper/remaining/join interfaces and original Storable kind; no formal acceptance.\n'),
        'development-mutations': ('development_mutations.py', 'PASS development-only complete positive meaning interface and every genuine mutation construction; no formal acceptance.\n'),
        'development-refusals': ('development_refusals.py', 'PASS development-only complete positive and every intended library refusal; formal native cases remain required.\n'),
        'development-publication': ('development_publication.py', 'PASS development-only complete unchanged parent publication proposal; no live source or formal acceptance changed.\n'),
    }
    result = {label: gate(label, ['python3', '-B', str(BASE / name)], stdout=stdout, development=True)
              for label, (name, stdout) in texts.items()}
    adjustment = read('development-adjustment.json')
    old, new = adjustment['replacement']
    source = str(BASE / 'controls.py')
    need(adjustment['owner'] == PLAN['owner'] and adjustment['source'] == source
         and adjustment['before'] == epochs['epochs']['development-mutations']['programmes'][source]
         and adjustment['after'] == epochs['epochs']['development-refusals']['programmes'][source]
         and adjustment['before']['body'].count(old) == 1
         and adjustment['before']['body'].replace(old, new, 1) == adjustment['after']['body']
         and Path(source).read_bytes() == adjustment['after']['body'].encode(),
         'exact pre-formal expected-cause adjustment and complete dated source correspondence')
    frozen = read('formal-programmes.json')
    need(frozen['owner'] == PLAN['owner'] and frozen['phase'] == 'formal'
         and set(frozen['programmes']) == {str(path) for path in BASE.glob('*.py')},
         'complete formal programme set frozen after development')
    for name, entry in frozen['programmes'].items():
        need(Path(name).read_bytes() == entry['body'].encode() and pin(entry['body'].encode()) == entry['identity'],
             'whole unchanged final formal programme source')
    preview = read('book-preview-revision.json')
    need(preview['owner'] == PLAN['owner'] and preview['corrected_projected_bytes'] == read('book-review.json')['after_bytes'] <= 292485
         and [row['status'] for row in preview['static_outer_refusals']] == [1, 1],
         'owned exact static book refusals and corrected pre-formal bounded proposal')
    proposal = read('development-publication.json')
    before = {name: gzip.decompress(Path(entry['before']['snapshot']).read_bytes()) for name, entry in proposal['snapshots'].items()}
    wanted, measured = publish.transformation(before)
    for name, body in wanted.items():
        entry = proposal['snapshots'][name]
        need(pin(before[name]) == entry['before']['identity'] and pin(body) == entry['after']['identity']
             and gzip.decompress(Path(entry['after']['snapshot']).read_bytes()) == body,
             'whole independently reconstructed development-only publication proposal')
    need(proposal['owner'] == PLAN['owner'] and same(proposal['measured'], measured), 'whole reviewed development proposal metadata')
    return dict(gates=result, adjustment=pin(canonical(adjustment)), preview=pin(canonical(preview)), proposal=pin(canonical(proposal)),
        condition='Development interfaces, positive and construction/library-error probes and publication previews only. Caught library errors/static outer refusals are never relabeled formal native status-1 controls or live publication.')


def separating(candidate, *, current=False):
    rows = read('controls.json')
    need(len(rows) == len(controls.CASES), 'complete actual native parent separating population')
    result = {}
    for row, (label, mutate, status, cause) in zip(rows, controls.CASES, strict=True):
        wanted = copy.deepcopy(candidate)
        if mutate:
            mutate(wanted)
            need(not same(wanted, candidate), 'genuine complete meaning-parent separating mutation')
        name = 'control-' + label + '.json.gz'
        need(same(load_product(name), wanted) and row['label'] == label and row['candidate'] == name
             and row['identity'] == pin(canonical(wanted)) and type(row['status']) is int and row['status'] == status
             and row['cause'] == cause, 'whole original-preserving native parent control candidate')
        command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', name]
        receipt = gate('control-' + label, command, status, reader.SUCCESS if cause is None else None, current=current)
        actual = read('control-' + label + '-actual.json')
        need(row['native'] == receipt and row['command'] == actual['command'], 'whole parent native control receipt custody')
        if cause:
            need(actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n'), 'first intended actual native parent rejection')
        need(row['outer'] == dict(command=['python3', '-B', str(BASE / 'capture.py'), '--expect', str(status), 'control-' + label, *command],
                                 status=0, stdout='control-' + label + ' actual native status ' + str(status) + '\n', stderr=''),
             'whole successful external native parent capture terminal')
        result[label] = receipt
    return result


def core(*, current=False):
    developed = development()
    normal = read('join-normal-commit.json')
    need(type(normal['status']) is int and normal['status'] == 0
         and normal['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and '[doctrine] all doctrine checks passed' in normal['stdout'] + normal['stderr'], 'complete normal join commit receipt and hooks')
    commit = re.search(r'^\[[^\]]+ ([0-9a-f]{7,40})\] ', normal['stdout'])
    need(commit is not None and git('rev-parse', commit[1]).decode().strip() == PLAN['revision'], 'normal committed join resolves to exact source revision')
    roles = intake.derive()
    need(same(roles, read('source-roles.json')), 'complete unchanged original/current meaning source roles')
    before, after = read('source-before.json'), read('source-after.json')
    need(same(before, after) and before['source'] == pin(canonical(roles['publication']))
         and before['overlays'] == {name: pin(body) for name, body in intake.overlays().items()}, 'whole source epoch conservation around actual meaning replays and controls')
    commands = {
        'source-before': ['python3', '-B', str(BASE / 'intake.py'), '--before'],
        'source-after': ['python3', '-B', str(BASE / 'intake.py'), '--after'],
        'replay-source-contract': ['python3', '-B', PLAN['source_contract'] + '/verify.py'],
        'replay-helper': ['python3', '-B', PLAN['helper'] + '/verify.py'],
        'replay-remaining': ['python3', '-B', PLAN['remaining'] + '/verify.py'],
        'replay-join': ['python3', '-B', PLAN['join'] + '/final.py'],
        'produce': ['python3', '-B', str(BASE / 'produce.py')],
        'independent': ['python3', '-B', str(BASE / 'reader.py'), '--save'],
        'controls': ['python3', '-B', str(BASE / 'run_controls.py')],
        'current-before': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'before'],
        'root-history': ['git', 'log', '-1', '-S', 'Independently derive complete original consumer operands and truth.', '--format=%H %s', '--', 'docs/tasks/'],
    }
    gates = {label: gate(label, command, current=current) for label, command in commands.items()}
    outputs = {
        'replay-source-contract': 'PASS complete original consumer source contracts; operand/outcome truth and every higher owner retain.\n',
        'replay-helper': 'PASS complete original refusal-helper consumer operands/truth; nonhelper and every higher owner retain.\n',
        'replay-remaining': 'PASS complete original remaining consumer operands/truth; complete join and every higher owner retain.\n',
        'replay-join': 'PASS complete original consumer source/meaning/operand/truth join; meaning acceptance and every higher owner retain.\n',
    }
    need(all(read(label + '-actual.json')['stdout'] == text for label, text in outputs.items()), 'whole complete prerequisite replay terminals and scopes')
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', read('root-history-actual.json')['stdout']), 'exact unchanged complete meaning obligation history locus')
    candidate = load_product('candidate.json.gz')
    qualification = reader.check(candidate)
    need(same(qualification, read('qualification.json')), 'whole freshly rederived independent meaning-parent qualification')
    public = original_public()
    prior = public['historical']()
    sources = load_product('canonical-before.json.gz')
    need(sources == {name: body.decode() for name, body in canonical_sources().items()}, 'complete fixed canonical source collection')
    public['check'](load_product('current-before.json.gz'), {name: body.encode() for name, body in sources.items()}, prior, public['authority'](prior))
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], source=pin(canonical(roles)), source_epoch=before,
        qualification=qualification, controls=separating(candidate, current=current), contracts=model.contracts(),
        normal_commit=pin(canonical(normal)), development=developed, gates=gates, condition=PLAN['condition'],
        legs=dict(rederive='Whole original parent/descendant/source contracts and fresh isolated complete child source-meaning/comparison readers join every original typed operand and outcome.',
                  falsify='Complete actual native source/meaning/operand/truth join and parent weakening/borrowed narrower success/independent child kind/false-green/omission candidates reach intended first refusals.',
                  durability='Complete committed original/current source, programmes, raw commands/statuses/streams, all first failures/repairs, products/candidates, proposals/publication/native snapshots and saved default qualification preserve recovery without ignored views.'))


def delivery(*, current=False):
    publication = publish.qualify(current=current)
    before, after = load_product('canonical-before.json.gz'), load_product('canonical-after.json.gz')
    need(same(before, after), 'every canonical fact/question/probe and collection byte retains')
    public = original_public()
    prior = public['historical']()
    record = load_product('current-after.json.gz')
    public['check'](record, {name: body.encode() for name, body in after.items()}, prior, public['authority'](prior))
    need(record['chapter'].encode() == gzip.decompress(Path(publication['snapshots'][BOOK]['after']['snapshot']).read_bytes()), 'whole current published complete meaning-parent chapter')
    source = read('source-published.json')
    need(source == dict(read('source-before.json'), overlays={name: pin(body) for name, body in intake.overlays(True).items()}), 'complete source epoch with only declared parent/book metadata overlays')
    if current:
        need(public['sources']() == {name: body.encode() for name, body in after.items()}
             and same(intake.live(intake.derive(), True), source), 'whole explicit current source/canonical epoch')
    native = book_native.qualify(gzip.decompress((BASE / 'native-chapter.html.gz').read_bytes()).decode())
    need(same(native, read('book-native.json')), 'whole rendered parent guidance and original retained scopes')
    extra = {
        'publication': ['python3', '-B', str(BASE / 'publish.py')],
        'current-after': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'after'],
        'book-native': ['python3', '-B', str(BASE / 'book_native.py')],
        'source-published': ['python3', '-B', str(BASE / 'intake.py'), '--published'],
    }
    gates = {label: gate(label, command, current=current) for label, command in {**publish.COMMANDS, **extra}.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'actual focused complete meaning-parent regression')
    return dict(publication=publication, current=pin(canonical(record)), native=native, source=source, gates=gates)


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        info = path.lstat()
        need(not path.is_symlink() and stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev,
             'whole ordinary flat same-volume meaning-parent archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(info.st_mode & 0o111))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one explicit complete parent qualification role')
    result = core(current=args.current or args.seal)
    if args.core:
        print('PASS complete unchanged independent meaning-parent core; canonical/original parent and higher owners retain.')
    else:
        result['delivery'] = delivery(current=args.current or args.seal)
        need(json.loads(canonical(result)) == result, 'whole parent proof JSON-native round trip')
        if args.seal:
            save('proof.json', result)
            save('manifest.json', catalogue())
        else:
            need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()), 'whole immutable saved complete parent acceptance')
        print(SUCCESS, end='')
