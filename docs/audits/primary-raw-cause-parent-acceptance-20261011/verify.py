"""Qualify every unchanged finite cause/canonical parent obligation and source role."""
import argparse
import copy
import stat
from parent_common import *
import book_native
import context
import controls
import intake
import publish
import reader
import requirements

SUCCESS = 'PASS complete unchanged finite primary/raw cause and canonical parent acceptance; every higher owner and original native/private limit retains.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


def gate(label, command, status=0, stdout=None, *, current=False):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
         and all(same(row[key], value) for key, value in started.items()), 'closed whole native publication terminal')
    need(type(row['status']) is int and row['status'] == status
         and type(row['expected_status']) is int and row['expected_status'] == status,
         'actual typed intended publication result ' + label)
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(row['programmes'], row['programmes_after']), 'whole actual command and programme epoch')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole actual programme/input body')
        if current:
            need(Path(name).read_bytes() == body, 'whole explicit current publication instrument')
    need(type(row['stderr']) is str and type(row['stdout']) is str
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged complete publication guard')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'complete intended publication terminal')
    return pin(canonical(row))


def qualify_controls(candidate):
    terminal = read('controls.json')
    specifications = [('candidate', None, None), *controls.cases()]
    need(terminal['owner'] == PLAN['owner'] and set(terminal['actuals']) == {name for name, _, _ in specifications},
         'complete native positive and hostile parent candidate population')
    receipts = {}
    for label, mutate, cause in specifications:
        expected = copy.deepcopy(candidate)
        if mutate:
            mutate(expected)
            need(not same(expected, candidate), 'genuine changed whole parent candidate')
        name = label + '.json.gz'
        need(same(load_product(name), expected), 'whole prior-preserving parent candidate and exact separating intervention')
        actual, started = read('control-' + label + '-actual.json'), read('control-' + label + '-started.json')
        need(set(started) == {'command', 'candidate', 'programmes', 'expected_status', 'intended_cause'}
             and set(actual) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after', 'candidate_after'}
             and all(same(actual[key], value) for key, value in started.items()), 'closed complete direct parent native terminal')
        status = int(mutate is not None)
        need(type(actual['status']) is int and actual['status'] == status
             and type(actual['expected_status']) is int and actual['expected_status'] == status
             and actual['intended_cause'] == cause
             and actual['command'] == ['python3', '-B', str(BASE / 'reader.py'), '--candidate', name]
             and actual['candidate'] == dict(path=str(BASE / name), identity=pin((BASE / name).read_bytes()))
             and actual['candidate_after'] == actual['candidate']['identity']
             and same(actual['programmes'], actual['programmes_after']), 'whole typed original parent control source/product/result')
        external = [path for path in actual['programmes'] if Path(path).parent != BASE]
        old = fixed(external)
        for path, entry in actual['programmes'].items():
            raw = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
            need(pin(raw) == entry['identity'] and raw == (Path(path).read_bytes() if Path(path).parent == BASE else old[path]),
                 'whole own immutable or explicit original dated control programme')
        need(actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n') if mutate
             else actual['stdout'] == reader.SUCCESS and actual['stderr'] == '', 'whole intended first native parent outcome')
        receipts[label] = pin(canonical(actual))
        need(receipts[label] == terminal['actuals'][label], 'complete actual native control receipt custody')
    return dict(receipts=receipts, condition=terminal['condition'])


def core(*, current=False):
    normal = read('publication-normal-commit.json')
    need(type(normal['status']) is int and normal['status'] == 0
         and normal['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and PLAN['revision'][:9] in normal['stdout'].splitlines()[0]
         and '[doctrine] all doctrine checks passed' in normal['stdout'] + normal['stderr'],
         'whole prior publication normal commit and hooks')
    roles = intake.derive()
    need(same(roles, read('source-roles.json')), 'complete original current cause-parent source graph')
    before, after = read('source-before.json'), read('source-after.json')
    need(same(before, after) and before['source'] == pin(canonical(roles['publication']))
         and before['overlays'] == {name: pin(body) for name, body in intake.overlays().items()},
         'complete unchanged source epoch around original dated readers and independent parent controls')
    for epoch in ('before', 'after'):
        gate('source-' + epoch, ['python3', '-B', str(BASE / 'intake.py'), '--' + epoch], current=current)
    obligations = requirements.contracts()
    for role in context.REPLAYS:
        gate('replay-' + role, ['python3', '-B', PLAN[role] + '/verify.py'], current=current)
    direct = gate('association-independent', ['python3', '-B', PLAN['association'] + '/reader.py'], current=current)
    need(read('association-independent-actual.json')['stdout'] ==
         'PASS independent complete original primary/raw cause association; every prior scope and native/private unknown retains.\n',
         'whole fresh independent source cause acceptance and original body association')
    gate('current-before', ['python3', '-B', str(BASE / 'current_snapshot.py'), 'before'], current=current)
    gate('build', ['python3', '-B', str(BASE / 'build.py')], current=current)
    gate('independent', ['python3', '-B', str(BASE / 'reader.py'), '--save'], current=current)
    gate('controls', ['python3', '-B', str(BASE / 'controls.py')], current=current)
    history = read('root-history-actual.json')
    gate('root-history', ['git', 'log', '-1', '-S', 'Join complete original primary and raw native cause semantics.',
         '--format=%H %s', '--', 'docs/tasks/'], current=current)
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', history['stdout']), 'exact original cause parent obligation history locus')
    candidate = load_product('candidate.json.gz')
    qualification = reader.check(candidate)
    need(same(qualification, read('qualification.json')) and same(candidate['contracts'], obligations),
         'whole independently reconstructed original current cause-parent qualification')
    separating = qualify_controls(candidate)
    whitespace = read('publication-whitespace-check.json')
    need(len(whitespace) == 2 and type(whitespace[0]['status']) is int and whitespace[0]['status'] == 2
         and type(whitespace[1]['status']) is int and whitespace[1]['status'] == 0
         and whitespace[0]['stderr'] == whitespace[1]['stderr'] == ''
         and all('new blank line at EOF.' in line for line in whitespace[0]['stdout'].splitlines()),
         'complete preserved scoped prior EOF diagnostics without semantic failure reclassification')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], source=pin(canonical(roles)),
        source_epoch=before, original_contracts=obligations, qualification=qualification, controls=separating,
        original_inputs=pin(canonical(candidate['inputs'])), independent=direct,
        normal_commit=pin(canonical(normal)), original_whitespace=pin(canonical(whitespace)), boundary=candidate['boundary'],
        condition=PLAN['condition'], legs=dict(
            rederive='Whole fixed original/current source graphs, unchanged complete obligations, exact prerequisite native epochs, fresh independent source causes and complete source/raw/empty/nested associations, canonical facts/questions/probes and capacity.',
            falsify='Whole positive and genuine prior-preserving source/contract/reader/typed-primary/first-failure/command/association/question/query/native-boundary candidates execute the independent native reader with actual first outcomes; original child controls retain.',
            durability='Committed complete original/current source/native/product/failure custody, all actual programmes/commands/streams, whole candidate/control products and publication snapshots, prior normal receipts and saved recovery independent of ignored views.'))


def delivery(*, current=False):
    publication = publish.qualify(current=current)
    published = read('source-published.json')
    before = read('source-before.json')
    need(published == dict(before, overlays={name: pin(body) for name, body in intake.overlays(True).items()}),
         'complete post-publication source epoch with only exact owned task/book metadata changes')
    sources_before, sources_after = load_product('canonical-before.json.gz'), load_product('canonical-after.json.gz')
    need(same(sources_before, sources_after) and sources_after == {name: body.decode() for name, body in canonical_sources().items()},
         'every complete canonical fact question probe and all collection bytes conserve through parent closure')
    public = original_public()
    prior = public['historical']()
    record = load_product('current-after.json.gz')
    sources = {name: text.encode() for name, text in sources_after.items()}
    public['check'](record, sources, prior, public['authority'](prior))
    book = publication['snapshots'][BOOK]['after']
    need(record['chapter'].encode() == gzip.decompress(Path(book['snapshot']).read_bytes()),
         'whole actual after-publication book source role')
    if current:
        need(public['sources']() == sources, 'whole explicit current canonical collection')
    html = gzip.decompress((BASE / 'native-chapter.html.gz').read_bytes()).decode()
    native = book_native.qualify(html)
    need(same(native, read('book-native.json')), 'whole actual native finite closure guidance and limits')
    extra = {
        'publication': ['python3', '-B', str(BASE / 'publish.py')],
        'current-after': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'after'],
        'book-native': ['python3', '-B', str(BASE / 'book_native.py')],
        'source-published': ['python3', '-B', str(BASE / 'intake.py'), '--published'],
    }
    gates = {name: gate(name, command, current=current) for name, command in {**publish.COMMANDS, **extra}.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'actual full focused parent acceptance regression')
    return dict(publication=publication, current=pin(canonical(record)), native=native,
                source_published=published, external=gates)


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        need(not path.is_symlink() and stat.S_ISREG(path.lstat().st_mode)
             and path.stat().st_dev == Path.cwd().stat().st_dev, 'whole ordinary flat same-volume publication archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(path.stat().st_mode & 0o111))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one whole unchanged finite parent acceptance role')
    result = core(current=args.current or args.seal)
    if args.core:
        print('PASS complete unchanged finite cause/canonical parent core; current delivery remains separate.')
    else:
        result['delivery'] = delivery(current=args.current or args.seal)
        need(json.loads(canonical(result)) == result, 'whole parent proof JSON-native round trip')
        if args.seal:
            save('proof.json', result)
            save('manifest.json', catalogue())
        else:
            need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()), 'whole immutable complete saved cause-parent acceptance')
        print(SUCCESS, end='')
