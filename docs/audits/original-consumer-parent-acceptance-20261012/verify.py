"""Reconstruct unchanged original consumer acceptance and complete bounded delivery."""
import argparse
import copy
import stat
from parent_common import *
import book_native
import controls
import intake
import interfaces
import model
import native_probe
import publish
import reader

SUCCESS = 'PASS complete unchanged original consumer-parent acceptance; full alias downstream and higher owners retain.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


def programmes():
    frozen = read('formal-programmes.json')
    need(frozen['owner'] == PLAN['owner'] and frozen['phase'] == 'formal'
         and set(frozen['programmes']) == {str(path) for path in BASE.glob('*.py')}, 'complete frozen formal programme membership')
    for name, entry in frozen['programmes'].items():
        body = entry['body'].encode()
        need(pin(body) == entry['identity'] and Path(name).read_bytes() == body, 'whole unchanged frozen formal programme body')
    return frozen['programmes']


def gate(label, command, status=0, stdout=None, *, declared=None, current=False, development=False):
    declared = status if declared is None else declared
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
         and all(same(row[key], value) for key, value in started.items()), 'closed whole original-consumer native terminal')
    need(type(row['status']) is int and row['status'] == status
         and type(row['expected_status']) is int and row['expected_status'] == declared,
         'distinct typed observed and declared native status: ' + label)
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(row['programmes'], row['programmes_after']), 'whole exact command and conserved native source epoch')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole native programme source body identity')
        if current and not development:
            need(Path(name).read_bytes() == body, 'whole explicit current native programme')
    own = {name: entry for name, entry in row['programmes'].items() if Path(name).parent == BASE}
    if development:
        epoch = read('development-epochs.json')['epochs'][label]
        need(same(own, epoch['programmes']) and epoch['actual'] == pin((BASE / (label + '-actual.json')).read_bytes()),
             'whole explicitly dated development programme epoch')
    else:
        need(same(own, read('formal-programmes.json')['programmes']), 'whole formal native source population')
    root = Path('.artifacts/original-consumer-parent-acceptance-20261012/checks') / label
    need(row['stdout_path'] == str(root / 'stdout.txt') and row['stderr_path'] == str(root / 'stderr.txt'),
         'whole repository-local native stream paths')
    need(type(row['stdout']) is type(row['stderr']) is str
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged complete native RAM guard')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended positive native terminal')
    return pin(canonical(row))


def separating(candidate, *, prefix='', current=False, development=False):
    rows = read(prefix + 'controls.json')
    declarations = controls.declarations()
    need(len(rows) == len(declarations), 'whole original source meaning and parent-link native separating domain')
    result = {}
    for row, (role, label, status, cause) in zip(rows, declarations, strict=True):
        original = native_probe.payload(candidate, role)
        wanted = copy.deepcopy(original)
        controls.mutate(role, label, wanted)
        need((cause is None and same(wanted, original)) or (cause is not None and not same(wanted, original)),
             'genuine unchanged-input positive or complete hostile native mutation')
        name = prefix + 'control-' + role + '-' + label + '.json.gz'
        need(same(load_product(name), wanted) and row['role'] == role and row['label'] == label
             and row['candidate'] == name and row['identity'] == pin(canonical(wanted))
             and type(row['status']) is int and row['status'] == status and row['cause'] == cause,
             'whole original-preserving native separating candidate')
        command = ['python3', '-B', str(BASE / 'native_probe.py'), '--role', role, '--candidate', name]
        tag = prefix + 'control-' + role + '-' + label
        receipt = gate(tag, command, status, native_probe.SUCCESS[role] if cause is None else None,
                       current=current, development=development)
        actual = read(tag + '-actual.json')
        need(row['native'] == receipt and row['command'] == actual['command'], 'whole native separating custody')
        if cause:
            need(actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n'),
                 'exact intended first actual native separating cause')
        need(row['outer'] == dict(command=['python3', '-B', str(BASE / 'capture.py'), '--expect', str(status), tag, *command],
                                 status=0, stdout=tag + ' actual native status ' + str(status) + '\n', stderr=''),
             'whole successful external native capture terminal')
        result[role + ':' + label] = receipt
    return result


def development(*, skip_self=False):
    phase, epochs = read('development-phase.json'), read('development-epochs.json')
    expected = {'development-interfaces', 'development-source', 'development-candidate', 'development-controls',
                'development-publication', 'development-whitespace'} | {
                    'development-control-' + role + '-' + label for role, label, _, _ in controls.declarations()}
    if not skip_self:
        expected.add('development-verifier')
    need(phase['owner'] == epochs['owner'] == PLAN['owner'] and phase['formal_started'] is False
         and set(epochs['epochs']) == expected, 'complete explicitly declared development source/native epochs')
    commands = {
        'development-interfaces': ['python3', '-B', str(BASE / 'development_interfaces.py')],
        'development-source': ['python3', '-B', str(BASE / 'intake.py'), '--development'],
        'development-candidate': ['python3', '-B', str(BASE / 'development_candidate.py')],
        'development-controls': ['python3', '-B', str(BASE / 'run_controls.py'), '--development'],
        'development-publication': ['python3', '-B', str(BASE / 'development_publication.py')],
        'development-whitespace': ['git', 'diff', '--cached', '--check'],
    }
    if not skip_self:
        commands['development-verifier'] = ['python3', '-B', str(BASE / 'development_verifier.py')]
    gates = {label: gate(label, command, development=True) for label, command in commands.items()}
    candidate = load_product('development-candidate.json.gz')
    need(same(reader.check(candidate), read('development-qualification.json')), 'whole fresh development candidate qualification')
    proposal = read('development-publication.json')
    before = {name: gzip.decompress(Path(row['before']['snapshot']).read_bytes()) for name, row in proposal['snapshots'].items()}
    after, measured = publish.transformation(before)
    for name, body in after.items():
        row = proposal['snapshots'][name]
        need(pin(before[name]) == row['before']['identity'] and pin(body) == row['after']['identity']
             and gzip.decompress(Path(row['after']['snapshot']).read_bytes()) == body,
             'whole independently reconstructed pre-formal publication proposal')
    need(proposal['owner'] == PLAN['owner'] and same(proposal['measured'], measured), 'whole development publication metadata')
    return dict(gates=gates, controls=separating(candidate, prefix='development-', development=True),
                proposal=pin(canonical(proposal)), condition='Development epochs precede whole formal freeze and are never substituted for formal current acceptance.')


def core(*, current=False):
    programmes()
    developed = development()
    normal = read('canonical-normal-commit.json')
    need(type(normal['status']) is int and normal['status'] == 0
         and normal['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and '[doctrine] all doctrine checks passed' in normal['stdout'] + normal['stderr'], 'whole normal publication commit receipt and hooks')
    commit = re.search(r'^\[[^\]]+ ([0-9a-f]{7,40})\] ', normal['stdout'])
    need(commit is not None and git('rev-parse', commit[1]).decode().strip() == PLAN['revision'], 'normal publication resolves to exact source revision')
    roles = intake.derive()
    need(same(roles, read('source-roles.json')), 'complete original/current source roles retain')
    before, after = read('source-before.json'), read('source-after.json')
    need(same(before, after) and before['source'] == pin(canonical(roles['publication']))
         and before['overlays'] == {name: pin(body) for name, body in intake.overlays().items()}, 'whole original/current source conservation around native controls')
    commands = {
        'source-before': ['python3', '-B', str(BASE / 'intake.py'), '--before'],
        'source-after': ['python3', '-B', str(BASE / 'intake.py'), '--after'],
        'replay-source': ['python3', '-B', PLAN['source_contract'] + '/verify.py'],
        'replay-canonical': ['python3', '-B', PLAN['canonical_parent'] + '/verify.py'],
        'replay-meaning': ['python3', '-B', PLAN['meaning'] + '/verify.py'],
        'produce': ['python3', '-B', str(BASE / 'produce.py')],
        'independent': ['python3', '-B', str(BASE / 'reader.py'), '--save'],
        'controls': ['python3', '-B', str(BASE / 'run_controls.py')],
        'permanent': ['python3', '-B', '-m', 'unittest', 'discover', '-s', 't/python', '-p', 'test_record_value_current_publication.py', '-v'],
        'current-before': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'before'],
        'root-history': ['git', 'log', '-1', '-S', 'Independently qualify every original consumer operand and outcome.', '--format=%H %s', '--', 'docs/tasks/'],
    }
    gates = {label: gate(label, command, current=current) for label, command in commands.items()}
    expected = {
        'replay-source': 'PASS complete original consumer source contracts; operand/outcome truth and every higher owner retain.\n',
        'replay-canonical': 'PASS complete unchanged consumer canonical-parent acceptance; original consumer parent and higher owners retain.\n',
        'replay-meaning': 'PASS complete unchanged independent consumer-meaning parent acceptance; canonical/original parent and higher owners retain.\n',
        'independent': reader.SUCCESS,
        'controls': 'PASS complete original source, meaning and parent-link native separating controls.\n',
    }
    need(all(read(label + '-actual.json')['stdout'] == output for label, output in expected.items()), 'whole prerequisite and actual native acceptance terminals')
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', read('root-history-actual.json')['stdout']), 'actual unchanged original consumer obligation history locus')
    permanent = read('permanent-actual.json')
    need(re.search(r'\nRan 28 tests in [0-9.]+s\n\nOK\n$', permanent['stderr']) is not None, 'actual complete permanent admission regression')
    candidate = load_product('candidate.json.gz')
    qualification = reader.check(candidate)
    need(same(qualification, read('qualification.json')), 'whole fresh independent unchanged original consumer qualification')
    public = interfaces.public()
    prior = public['historical']()
    sources = load_product('canonical-before.json.gz')
    need(sources == {name: body.decode() for name, body in canonical_sources().items()}, 'every fixed canonical fact/question/probe source byte')
    public['check'](load_product('current-before.json.gz'), {name: body.encode() for name, body in sources.items()}, prior, public['authority'](prior))
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], source=pin(canonical(roles)), source_epoch=before,
        qualification=qualification, controls=separating(candidate, current=current), contracts=interfaces.contracts(),
        normal_commit=pin(canonical(normal)), development=developed, gates=gates, condition=PLAN['condition'],
        legs=dict(rederive='Whole unchanged original parent/descendant contracts, complete original source/native/product/cause and separate source-contract/typed-meaning readers with source-first operand/outcome/admission/current reconstruction.',
                  falsify='Genuine complete original source, meaning and parent-link contract/omission/borrowed operand/native/source/mode/Boolean/false-green/failure/boundary native mutations reach intended first causes; permanent admission tests qualify.',
                  durability='Whole committed source/native epochs, complete programmes/commands/statuses/streams, first failures/repairs, candidates/proposals/publication/native snapshots and default recovery with normal hooks.'))


def delivery(*, current=False):
    publication = publish.qualify(current=current)
    before, after = load_product('canonical-before.json.gz'), load_product('canonical-after.json.gz')
    need(same(before, after), 'every unchanged canonical fact/question/probe/authority byte retains')
    public = interfaces.public()
    prior = public['historical']()
    record = load_product('current-after.json.gz')
    public['check'](record, {name: body.encode() for name, body in after.items()}, prior, public['authority'](prior))
    need(record['chapter'].encode() == gzip.decompress(Path(publication['snapshots'][BOOK]['after']['snapshot']).read_bytes()), 'whole published unchanged original consumer acceptance chapter')
    source = read('source-published.json')
    need(source == dict(read('source-before.json'), overlays={name: pin(body) for name, body in intake.overlays(True).items()}), 'whole source epoch with only explicit canonical acceptance metadata overlays')
    if current:
        need(public['sources']() == {name: body.encode() for name, body in after.items()}
             and same(intake.live(intake.derive(), True), source), 'whole explicit current canonical/source epoch')
    native = book_native.qualify(gzip.decompress((BASE / 'native-chapter.html.gz').read_bytes()).decode())
    need(same(native, read('book-native.json')), 'whole actual native canonical acceptance guidance')
    commands = dict(publish.COMMANDS,
        publication=['python3', '-B', str(BASE / 'publish.py')],
        **{'current-after': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'after'],
           'book-native': ['python3', '-B', str(BASE / 'book_native.py')],
           'source-published': ['python3', '-B', str(BASE / 'intake.py'), '--published'],
           'book-source': ['python3', '-B', 'scripts/book_source_references.py', '--write'],
           'whitespace': ['git', 'diff', '--cached', '--check']})
    gates = {label: gate(label, command, current=current) for label, command in commands.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'actual focused canonical acceptance regression')
    return dict(publication=publication, current=pin(canonical(record)), native=native, source=source, gates=gates)


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        info = path.lstat()
        need(not path.is_symlink() and stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev,
             'whole ordinary flat same-volume canonical acceptance archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(info.st_mode & 0o111))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one complete canonical acceptance qualification role')
    result = core(current=args.current or args.seal)
    if args.core:
        print('PASS complete unchanged original consumer-parent acceptance core; full alias downstream and higher owners retain.')
    else:
        result['delivery'] = delivery(current=args.current or args.seal)
        need(json.loads(canonical(result)) == result, 'whole proof JSON-native round trip')
        if args.seal:
            save('proof.json', result)
            save('manifest.json', catalogue())
        else:
            need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()), 'whole immutable saved original-consumer acceptance')
        print(SUCCESS, end='')
