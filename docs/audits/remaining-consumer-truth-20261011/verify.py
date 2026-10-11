"""Qualify every remaining original consumer truth and bounded delivery."""
import argparse
import copy
import stat
from remaining_common import *
import book_native
import value_inputs as inputs
import controls
import intake
import native_comparisons
import publish
import reader
import recovery

SUCCESS = 'PASS complete original remaining consumer operands/truth; complete join and every higher owner retain.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


def gate(label, command, status=0, stdout=None, *, current=False):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
         and all(same(row[key], value) for key, value in started.items()), 'closed whole native remaining-consumer terminal')
    need(type(row['status']) is int and row['status'] == status
         and type(row['expected_status']) is int and row['expected_status'] == status,
         'typed intended native remaining-consumer result: ' + label)
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(row['programmes'], row['programmes_after']), 'whole remaining-consumer command and unchanged programme epoch')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole native remaining-consumer programme body')
        if current:
            need(Path(name).read_bytes() == body, 'whole current remaining-consumer instrument')
    need(type(row['stderr']) is str and type(row['stdout']) is str
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged complete remaining-consumer RAM guard')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended remaining-consumer native terminal')
    return pin(canonical(row))


def separating(candidate, *, current=False):
    rows = read('controls.json')
    need(len(rows) == len(controls.CASES), 'complete native remaining-consumer separating population')
    result = {}
    for row, (label, mutate, status, cause) in zip(rows, controls.CASES, strict=True):
        wanted = copy.deepcopy(candidate)
        if mutate:
            mutate(wanted)
            need(not same(wanted, candidate), 'genuine complete remaining-consumer separating mutation')
        name = 'control-' + label + '.json.gz'
        need(same(wanted, load_product(name)) and row['label'] == label and row['candidate'] == name
             and row['identity'] == pin(canonical(wanted)) and row['cause'] == cause
             and type(row['status']) is int and row['status'] == status,
             'whole exact prior-preserving native remaining-consumer candidate')
        command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', name]
        receipt = gate('control-' + label, command, status, reader.SUCCESS if cause is None else None, current=current)
        actual = read('control-' + label + '-actual.json')
        need(row['native'] == receipt and row['command'] == actual['command'], 'whole native control receipt custody')
        if cause:
            need(actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n'),
                 'first intended native remaining-consumer rejection')
        outer = row['outer']
        need(outer == dict(command=['python3', '-B', str(BASE / 'capture.py'), '--expect', str(status),
                                   'control-' + label, *command], status=0,
                           stdout='control-' + label + ' actual native status ' + str(status) + '\n', stderr=''),
             'whole successful external control capture command and terminal')
        result[label] = receipt
    return result


def core(*, current=False):
    normal = read('helper-normal-commit.json')
    need(type(normal['status']) is int and normal['status'] == 0
         and normal['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and '[doctrine] all doctrine checks passed' in normal['stdout'] + normal['stderr'],
         'complete normal helper-truth commit receipt and hooks')
    commit = re.search(r'^\[[^\]]+ ([0-9a-f]{7,40})\] ', normal['stdout'])
    need(commit is not None and git('rev-parse', commit[1]).decode().strip() == PLAN['revision'],
         'native prior normal commit resolves to exact fixed source revision')
    roles = intake.derive()
    need(same(roles, read('source-roles.json')), 'whole complete original/current consumer source roles')
    before, after = read('source-before-v2.json'), read('source-after-v2.json')
    need(same(before, after) and before['source'] == pin(canonical(roles['publication']))
         and before['overlays'] == {name: pin(body) for name, body in intake.overlays().items()},
         'whole unchanged source epoch around remaining-consumer readers and controls')
    commands = {
        'source-before-v2': ['python3', '-B', str(BASE / 'intake.py'), '--before', '--corrected'],
        'source-after-v2': ['python3', '-B', str(BASE / 'intake.py'), '--after', '--corrected'],
        'replay-source-contract': ['python3', '-B', PLAN['source_contract'] + '/verify.py'],
        'replay-helper': ['python3', '-B', PLAN['publication'] + '/verify.py'],
        'native-comparisons': ['python3', '-B', str(BASE / 'native_comparisons.py')],
        'produce-v2': ['python3', '-B', str(BASE / 'produce.py'), '--output', 'candidate-v2.json.gz'],
        'independent-v2': ['python3', '-B', str(BASE / 'reader.py'), '--save'],
        'controls': ['python3', '-B', str(BASE / 'controls.py')],
        'current-before': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'before'],
        'root-history': ['git', 'log', '-1', '-S', 'Independently qualify every remaining original consumer assertion.',
                         '--format=%H %s', '--', 'docs/tasks/'],
    }
    gates = {name: gate(name, command, current=current and name not in {'replay-source-contract', 'replay-helper', 'current-before'})
             for name, command in commands.items()}
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', read('root-history-actual.json')['stdout']),
         'original consumer contract history locus')
    need(read('replay-source-contract-actual.json')['stdout'] ==
         'PASS complete original consumer source contracts; operand/outcome truth and every higher owner retain.\n',
         'whole actual complete source-contract replay')
    need(read('replay-helper-actual.json')['stdout'] ==
         'PASS complete original refusal-helper consumer operands/truth; nonhelper and every higher owner retain.\n',
         'whole actual complete original helper consumer replay')
    candidate = load_product('candidate-v2.json.gz')
    qualification = reader.check(candidate)
    need(same(qualification, read('qualification.json')), 'whole independent saved remaining-consumer admission')
    public = original_public()
    prior = public['historical']()
    sources = load_product('canonical-before.json.gz')
    need(sources == {name: body.decode() for name, body in canonical_sources().items()}, 'whole fixed canonical source collection')
    public['check'](load_product('current-before.json.gz'), {name: body.encode() for name, body in sources.items()},
                    prior, public['authority'](prior))
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], source=pin(canonical(roles)),
        source_epoch=before, qualification=qualification, controls=separating(candidate, current=current),
        contracts=inputs.contracts(), recovery=recovery.qualify(gate, current=current), native_comparisons=native_comparisons.qualify(gate, current=current),
        normal_commit=pin(canonical(normal)), gates=gates, condition=PLAN['condition'],
        legs=dict(rederive='Complete fixed source/native/helper/contracts and qualified authored JSON/type/actor/path/API/copy models; independent literal/recipe/property/dataflow and complete typed operands with distinct scalar/structural/regex interpretation.',
                  falsify='Complete genuine native false-green/false-red/source/API/property/structure/kind/omission/synthetic/helper-promotion candidates reach intended independent comparison or own-source operand refusals; separate public native Test::More positive/negative comparisons corroborate finite rules.',
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
         'whole actual current published remaining-consumer chapter')
    source = read('source-published.json')
    need(source == dict(read('source-before-v2.json'), overlays={name: pin(body) for name, body in intake.overlays(True).items()}),
         'complete published source epoch with only declared task/book metadata overlays')
    if current:
        need(public['sources']() == {name: body.encode() for name, body in after.items()}
             and same(intake.live(intake.derive(), True), source), 'whole explicit current source and canonical epoch')
    native = book_native.qualify(gzip.decompress((BASE / 'native-chapter.html.gz').read_bytes()).decode())
    need(same(native, read('book-native.json')), 'whole native remaining-consumer guidance and original scopes')
    extra = {
        'publication': ['python3', '-B', str(BASE / 'publish.py')],
        'current-after': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'after'],
        'book-native': ['python3', '-B', str(BASE / 'book_native.py')],
        'source-published': ['python3', '-B', str(BASE / 'intake.py'), '--published'],
    }
    gates = {name: gate(name, command, current=current) for name, command in {**publish.COMMANDS, **extra}.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'actual focused remaining-consumer regression')
    return dict(publication=publication, current=pin(canonical(record)), native=native, source=source, gates=gates)


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        info = path.lstat()
        need(not path.is_symlink() and stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev,
             'whole ordinary flat same-volume remaining-consumer archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(info.st_mode & 0o111))
    return result


if __name__ == '__main__':
    import runpy
    runpy.run_path(str(BASE / 'complete.py'), run_name='__main__')
