"""Qualify complete finite consumer source contracts and bounded delivery."""
import argparse
import copy
import stat
from consumer_common import *
import book_native
import contract_inputs as inputs
import controls
import intake
import publish
import reader

SUCCESS = 'PASS complete original consumer source contracts; operand/outcome truth and every higher owner retain.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


def gate(label, command, status=0, stdout=None, *, current=False):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
         and all(same(row[key], value) for key, value in started.items()), 'closed whole native source-contract terminal')
    need(type(row['status']) is int and row['status'] == status
         and type(row['expected_status']) is int and row['expected_status'] == status,
         'typed intended native source-contract result: ' + label)
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(row['programmes'], row['programmes_after']), 'whole source-contract command and unchanged programme epoch')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole native source-contract programme body')
        if current:
            need(Path(name).read_bytes() == body, 'whole current source-contract instrument')
    need(type(row['stderr']) is str and type(row['stdout']) is str
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged complete source-contract RAM guard')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended source-contract native terminal')
    return pin(canonical(row))


def separating(candidate, *, current=False):
    rows = read('controls.json')
    need(len(rows) == len(controls.CASES), 'complete native source-contract separating population')
    result = {}
    for row, (label, mutate, status, cause) in zip(rows, controls.CASES, strict=True):
        wanted = copy.deepcopy(candidate)
        if mutate:
            mutate(wanted)
            need(not same(wanted, candidate), 'genuine complete source-contract separating mutation')
        name = 'control-' + label + '.json.gz'
        need(same(wanted, load_product(name)) and row['label'] == label and row['candidate'] == name
             and row['identity'] == pin(canonical(wanted)) and row['cause'] == cause
             and type(row['status']) is int and row['status'] == status,
             'whole exact prior-preserving native source-contract candidate')
        command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', name]
        receipt = gate('control-' + label, command, status, reader.SUCCESS if cause is None else None, current=current)
        actual = read('control-' + label + '-actual.json')
        need(row['native'] == receipt and row['command'] == actual['command'], 'whole native control receipt custody')
        if cause:
            need(actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n'),
                 'first intended native source-contract rejection')
        outer = row['outer']
        need(outer == dict(command=['python3', '-B', str(BASE / 'capture.py'), '--expect', str(status),
                                   'control-' + label, *command], status=0,
                           stdout='control-' + label + ' actual native status ' + str(status) + '\n', stderr=''),
             'whole successful external control capture command and terminal')
        result[label] = receipt
    return result


def core(*, current=False):
    recovery = read('capture-route-recovery.json')
    need(type(recovery['status']) is int and recovery['status'] == 1
         and recovery['child_launched'] is False and recovery['started_receipt_created'] is False
         and recovery['before'] == pin((BASE / 'initial-capture.py.txt').read_bytes())
         and recovery['after'] == pin((BASE / 'capture.py').read_bytes()),
         'whole first pre-launch capture failure and exact corrected route programme')
    reproduction = ['python3', '-B', str(BASE / 'initial-capture.py.txt'), 'source-before',
                    'python3', '-B', str(BASE / 'intake.py'), '--before']
    gate('prelaunch-reproduction', reproduction, status=1, current=current)
    refused = read('prelaunch-reproduction-actual.json')
    need(refused['stdout'] == '' and refused['stderr'].endswith(
         "FileExistsError: [Errno 17] File exists: '.artifacts/primary-raw-cause-parent-acceptance-20261011/checks/source-before'\n"),
         'actual separate native exclusive-route refusal reproduces the first pre-launch mechanism')
    normal = read('cause-parent-normal-commit.json')
    need(type(normal['status']) is int and normal['status'] == 0
         and normal['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and '[doctrine] all doctrine checks passed' in normal['stdout'] + normal['stderr'],
         'complete normal cause-parent commit receipt and hooks')
    commit = re.search(r'^\[[^\]]+ ([0-9a-f]{7,40})\] ', normal['stdout'])
    need(commit is not None and git('rev-parse', commit[1]).decode().strip() == PLAN['revision'],
         'native prior normal commit resolves to exact fixed source revision')
    roles = intake.derive()
    need(same(roles, read('source-roles.json')), 'whole complete original/current consumer source roles')
    before, after = read('source-before.json'), read('source-after.json')
    need(same(before, after) and before['source'] == pin(canonical(roles['publication']))
         and before['overlays'] == {name: pin(body) for name, body in intake.overlays().items()},
         'whole unchanged source epoch around source-contract readers and controls')
    commands = {
        'source-before': ['python3', '-B', str(BASE / 'intake.py'), '--before'],
        'source-after': ['python3', '-B', str(BASE / 'intake.py'), '--after'],
        'replay-cause-parent': ['python3', '-B', PLAN['publication'] + '/complete.py'],
        'produce': ['python3', '-B', str(BASE / 'produce.py')],
        'independent': ['python3', '-B', str(BASE / 'reader.py'), '--save'],
        'controls': ['python3', '-B', str(BASE / 'controls.py')],
        'current-before': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'before'],
        'root-history': ['git', 'log', '-1', '-S', 'Independently qualify every original consumer operand and outcome.',
                         '--format=%H %s', '--', 'docs/tasks/'],
    }
    gates = {name: gate(name, command, current=current) for name, command in commands.items()}
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', read('root-history-actual.json')['stdout']),
         'original consumer contract history locus')
    need(read('replay-cause-parent-actual.json')['stdout'] ==
         'PASS complete unchanged finite primary/raw cause and canonical parent acceptance; every higher owner and original native/private limit retains.\n',
         'whole actual saved complete cause-parent replay')
    candidate = load_product('candidate.json.gz')
    qualification = reader.check(candidate)
    need(same(qualification, read('qualification.json')), 'whole independent saved source-contract admission')
    public = original_public()
    prior = public['historical']()
    sources = load_product('canonical-before.json.gz')
    need(sources == {name: body.decode() for name, body in canonical_sources().items()}, 'whole fixed canonical source collection')
    public['check'](load_product('current-before.json.gz'), {name: body.encode() for name, body in sources.items()},
                    prior, public['authority'](prior))
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], source=pin(canonical(roles)),
        source_epoch=before, qualification=qualification, controls=separating(candidate, current=current),
        contracts=inputs.contracts(), normal_commit=pin(canonical(normal)), gates=gates,
        capture_recovery=pin(canonical(recovery)), condition=PLAN['condition'],
        legs=dict(rederive='Complete fixed source/native/product/cause roles and unchanged original consumer contract; independent whole assertion/argument, helper/loop/dataflow and typed operand-role traversal.',
                  falsify='Whole genuine native omitted/borrowed/expression/span/helper/loop/dataflow/source/Boolean/boundary candidates fail at their intended first independent assertions.',
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
         'whole actual current published source-contract chapter')
    source = read('source-published.json')
    need(source == dict(read('source-before.json'), overlays={name: pin(body) for name, body in intake.overlays(True).items()}),
         'complete published source epoch with only declared task/book metadata overlays')
    if current:
        need(public['sources']() == {name: body.encode() for name, body in after.items()}
             and same(intake.live(intake.derive(), True), source), 'whole explicit current source and canonical epoch')
    native = book_native.qualify(gzip.decompress((BASE / 'native-chapter.html.gz').read_bytes()).decode())
    need(same(native, read('book-native.json')), 'whole native source-contract guidance and original scopes')
    extra = {
        'publication': ['python3', '-B', str(BASE / 'publish.py')],
        'current-after': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'after'],
        'book-native': ['python3', '-B', str(BASE / 'book_native.py')],
        'source-published': ['python3', '-B', str(BASE / 'intake.py'), '--published'],
    }
    gates = {name: gate(name, command, current=current) for name, command in {**publish.COMMANDS, **extra}.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'actual focused source-contract regression')
    return dict(publication=publication, current=pin(canonical(record)), native=native, source=source, gates=gates)


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        info = path.lstat()
        need(not path.is_symlink() and stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev,
             'whole ordinary flat same-volume source-contract archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(info.st_mode & 0o111))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one complete source-contract qualification role')
    result = core(current=args.current or args.seal)
    if args.core:
        print('PASS complete source-contract core; operands/outcomes and delivery remain separately owned.')
    else:
        result['delivery'] = delivery(current=args.current or args.seal)
        need(json.loads(canonical(result)) == result, 'whole source-contract proof JSON-native round trip')
        if args.seal:
            save('proof.json', result)
            save('manifest.json', catalogue())
        else:
            need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()),
                 'whole immutable complete saved consumer source-contract qualification')
        print(SUCCESS, end='')
