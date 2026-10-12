"""Qualify complete original consumer join truth and bounded delivery."""
import argparse
import copy
import stat
from join_common import *
import book_native
import join_inputs as inputs
import controls
import intake
import publish
import reader

SUCCESS = 'PASS complete original consumer source/meaning/operand/truth join; meaning acceptance and every higher owner retain.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


def gate(label, command, status=0, stdout=None, *, current=False):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
         and all(same(row[key], value) for key, value in started.items()), 'closed whole native consumer-join terminal')
    need(type(row['status']) is int and row['status'] == status
         and type(row['expected_status']) is int and row['expected_status'] == status,
         'typed intended native consumer-join result: ' + label)
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(row['programmes'], row['programmes_after']), 'whole consumer-join command and unchanged programme epoch')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole native consumer-join programme body')
        if current:
            need(Path(name).read_bytes() == body, 'whole current consumer-join instrument')
    need(type(row['stderr']) is str and type(row['stdout']) is str
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged complete consumer-join RAM guard')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended consumer-join native terminal')
    return pin(canonical(row))


def development():
    phase = read('development-phase.json')
    need('development' in canonical(phase).decode().lower(), 'explicit prior non-acceptance development declaration')
    gate('development-interface', ['python3', '-B', str(BASE / 'development_probe.py')],
         stdout='PASS development-only isolated committed helper/remaining reader interfaces; no formal acceptance.\n')
    first = read('development-interface-actual.json')
    first_own = {name: value for name, value in first['programmes'].items() if str(Path(name).parent) == str(BASE)}
    need(set(first_own) == {str(BASE / name) for name in ('capture.py', 'join_common.py', 'child_readers.py', 'development_probe.py')},
         'whole first development programme epoch, no later formal-source claim')
    need(all(Path(name).read_bytes() == value['body'].encode() for name, value in first_own.items()),
         'unchanged explicitly scoped development interfaces')
    frozen = read('formal-programmes.json')
    need(frozen['phase'] == 'formal' and frozen['owner'] == PLAN['owner']
         and set(frozen['programmes']) == {str(path) for path in BASE.glob('*.py')},
         'complete formal programme population frozen before qualification')
    for name, value in frozen['programmes'].items():
        need(Path(name).read_bytes() == value['body'].encode() and pin(value['body'].encode()) == value['identity'],
             'whole unchanged formal source body')


def separating(candidate, *, current=False):
    rows = read('controls.json')
    need(len(rows) == len(controls.CASES), 'complete native consumer-join separating population')
    result = {}
    for row, (label, mutate, status, cause) in zip(rows, controls.CASES, strict=True):
        wanted = copy.deepcopy(candidate)
        if mutate:
            mutate(wanted)
            need(not same(wanted, candidate), 'genuine complete consumer-join separating mutation')
        name = 'control-' + label + '.json.gz'
        need(same(wanted, load_product(name)) and row['label'] == label and row['candidate'] == name
             and row['identity'] == pin(canonical(wanted)) and row['cause'] == cause
             and type(row['status']) is int and row['status'] == status,
             'whole exact prior-preserving native consumer-join candidate')
        command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', name]
        receipt = gate('control-' + label, command, status, reader.SUCCESS if cause is None else None, current=current)
        actual = read('control-' + label + '-actual.json')
        need(row['native'] == receipt and row['command'] == actual['command'], 'whole native control receipt custody')
        if cause:
            need(actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n'),
                 'first intended native consumer-join rejection')
        outer = row['outer']
        need(outer == dict(command=['python3', '-B', str(BASE / 'capture.py'), '--expect', str(status),
                                   'control-' + label, *command], status=0,
                           stdout='control-' + label + ' actual native status ' + str(status) + '\n', stderr=''),
             'whole successful external control capture command and terminal')
        result[label] = receipt
    return result


def core(*, current=False):
    development()
    normal = read('remaining-normal-commit.json')
    need(type(normal['status']) is int and normal['status'] == 0
         and normal['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and '[doctrine] all doctrine checks passed' in normal['stdout'] + normal['stderr'],
         'complete normal remaining-truth commit receipt and hooks')
    commit = re.search(r'^\[[^\]]+ ([0-9a-f]{7,40})\] ', normal['stdout'])
    need(commit is not None and git('rev-parse', commit[1]).decode().strip() == PLAN['revision'],
         'native prior normal commit resolves to exact fixed source revision')
    roles = intake.derive()
    need(same(roles, read('source-roles.json')), 'whole complete original/current consumer source roles')
    before, after = read('source-before.json'), read('source-after.json')
    need(same(before, after) and before['source'] == pin(canonical(roles['publication']))
         and before['overlays'] == {name: pin(body) for name, body in intake.overlays().items()},
         'whole unchanged source epoch around consumer-join readers and controls')
    commands = {
        'source-before': ['python3', '-B', str(BASE / 'intake.py'), '--before'],
        'source-after': ['python3', '-B', str(BASE / 'intake.py'), '--after'],
        'replay-source-contract': ['python3', '-B', PLAN['source_contract'] + '/verify.py'],
        'replay-helper': ['python3', '-B', PLAN['helper'] + '/verify.py'],
        'replay-remaining': ['python3', '-B', PLAN['remaining'] + '/verify.py'],
        'produce': ['python3', '-B', str(BASE / 'produce.py')],
        'independent': ['python3', '-B', str(BASE / 'reader.py'), '--save'],
        'controls': ['python3', '-B', str(BASE / 'controls.py')],
        'current-before': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'before'],
        'root-history': ['git', 'log', '-1', '-S', 'Independently derive complete original consumer operands and truth.',
                         '--format=%H %s', '--', 'docs/tasks/'],
    }
    gates = {name: gate(name, command, current=current) for name, command in commands.items()}
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', read('root-history-actual.json')['stdout']),
         'original consumer contract history locus')
    need(read('replay-source-contract-actual.json')['stdout'] ==
         'PASS complete original consumer source contracts; operand/outcome truth and every higher owner retain.\n',
         'whole actual complete source-contract replay')
    need(read('replay-helper-actual.json')['stdout'] ==
         'PASS complete original refusal-helper consumer operands/truth; nonhelper and every higher owner retain.\n'
         and read('replay-remaining-actual.json')['stdout'] ==
         'PASS complete original remaining consumer operands/truth; complete join and every higher owner retain.\n',
         'whole actual complete helper and remaining source-meaning replays')
    candidate = load_product('candidate.json.gz')
    qualification = reader.check(candidate)
    need(same(qualification, read('qualification.json')), 'whole independent saved consumer-join admission')
    public = original_public()
    prior = public['historical']()
    sources = load_product('canonical-before.json.gz')
    need(sources == {name: body.decode() for name, body in canonical_sources().items()}, 'whole fixed canonical source collection')
    public['check'](load_product('current-before.json.gz'), {name: body.encode() for name, body in sources.items()},
                    prior, public['authority'](prior))
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], source=pin(canonical(roles)),
        source_epoch=before, qualification=qualification, controls=separating(candidate, current=current),
        contracts=inputs.contracts(), normal_commit=pin(canonical(normal)), gates=gates, condition=PLAN['condition'],
        legs=dict(rederive='Complete source assertion partition and fresh isolated child source-model/comparison readers join every own original typed operand and outcome; shared child algorithms explicitly retain their qualified limits.',
                  falsify='Complete genuine native false-green/red/source/role/helper/API/primary/borrowed-meaning/primitive/structural/Storable/synthetic/outcome/omission candidates reject at intended independent comparison or own source-meaning/operand join.',
                  durability='Complete committed original/current programmes, sources, actual commands/streams/statuses, candidate/control products, normal receipts, publication before/after snapshots and saved recovery independent of ignored views.'))


def delivery(*, current=False):
    publication = publish.qualify(current=current)
    before, after = load_product('canonical-before.json.gz'), load_product('canonical-after.json.gz')
    need(same(before, after), 'all existing canonical facts questions probes and collection bytes retain')
    public = original_public()
    prior = public['historical']()
    record = load_product('current-after.json.gz')
    public['check'](record, {name: body.encode() for name, body in after.items()}, prior, public['authority'](prior))
    need(record['chapter'].encode() == gzip.decompress(Path(publication['snapshots'][BOOK]['after']['snapshot']).read_bytes()),
         'whole actual current published consumer-join chapter')
    source = read('source-published.json')
    need(source == dict(read('source-before.json'), overlays={name: pin(body) for name, body in intake.overlays(True).items()}),
         'complete published source epoch with only declared task/book metadata overlays')
    if current:
        need(public['sources']() == {name: body.encode() for name, body in after.items()}
             and same(intake.live(intake.derive(), True), source), 'whole explicit current source and canonical epoch')
    native = book_native.qualify(gzip.decompress((BASE / 'native-chapter.html.gz').read_bytes()).decode())
    need(same(native, read('book-native.json')), 'whole native consumer-join guidance and original scopes')
    extra = {
        'publication': ['python3', '-B', str(BASE / 'publish.py')],
        'current-after': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'after'],
        'book-native': ['python3', '-B', str(BASE / 'book_native.py')],
        'source-published': ['python3', '-B', str(BASE / 'intake.py'), '--published'],
    }
    gates = {name: gate(name, command, current=current) for name, command in {**publish.COMMANDS, **extra}.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'actual focused consumer-join regression')
    return dict(publication=publication, current=pin(canonical(record)), native=native, source=source, gates=gates)


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        info = path.lstat()
        need(not path.is_symlink() and stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev,
             'whole ordinary flat same-volume consumer-join archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(info.st_mode & 0o111))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one complete consumer-join qualification role')
    result = core(current=args.current or args.seal)
    if args.core:
        print('PASS complete original consumer join core; complete meaning and higher acceptance retain.')
    else:
        result['delivery'] = delivery(current=args.current or args.seal)
        need(json.loads(canonical(result)) == result, 'whole consumer-join proof JSON-native round trip')
        if args.seal:
            save('proof.json', result)
            save('manifest.json', catalogue())
        else:
            need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()),
                 'whole immutable complete saved consumer-join qualification')
        print(SUCCESS, end='')
