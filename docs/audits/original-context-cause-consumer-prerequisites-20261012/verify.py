"""Admit complete saved meanings without claiming their later independent join."""
import argparse
import ast
import contextlib
import stat
from admission_common import *
import admission_publish as publish
import book_native
import intake

SUCCESS = 'PASS complete original context/cause/consumer prerequisite admission; independent association and parent acceptance remain separate.\n'
SUFFIXES = {
    'context': 'PASS complete finite source-authored helper/consumer/parser contexts and qualified own operation spans. Raw operands/errors retain; primary/raw-coordinate and consumer-operand truth remain open.\n',
    'cause': 'PASS unchanged original primary/raw cause-container acceptance; higher join and full alias remain separate.\n',
    'consumer': 'PASS complete unchanged original consumer-parent acceptance; full alias downstream and higher owners retain.\n'}
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix
    for label in ('seal', 'default', 'staged-doctrines') for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


def contracts():
    original = fixed([TASK])[TASK]
    active = gzip.decompress((BASE / 'activation-task.gz').read_bytes())
    initial = gzip.decompress((BASE / 'activation-task-first.gz').read_bytes())
    first, started, last = nodes(original), nodes(initial), nodes(active)
    new = {PLAN[key] for key in ('owner', 'association', 'acceptance')}
    need(set(last) == set(started) == set(first) | new, 'exact three added join children')
    parent = PLAN['parent']
    need(field(first[parent], 'Status') == 'pending' and field(last[parent], 'Status') == 'active'
         and field(first[parent], 'Children') is None
         and field(last[parent], 'Children') == ', '.join(PLAN[key] for key in ('owner', 'association', 'acceptance')),
         'exact pending join activation and declared safe slices')
    need(all(field(first[parent], key) == field(last[parent], key) for key in ('Goal', 'Acceptance', 'Commit')),
         'whole original join contract retains')
    for name, block in first.items():
        if name != parent:
            need(block == last[name] == started[name], 'every unrelated whole original task block retains')
    need(started[parent] == last[parent] and all(started[name] == last[name] for name in new - {PLAN['owner']}),
         'preparation finding changes only its owning new leaf')
    need(field(last[PLAN['owner']], 'Status') == 'active'
         and all(field(last[PLAN[key]], 'Status') == 'pending' for key in ('association', 'acceptance', 'full_alias')),
         'exact admission and separately pending successor states')
    direct = [PLAN['family'] + '.' + str(i) for i in range(1, 4)]
    need(all(field(first[name], 'Status') == 'done' for name in direct), 'all three complete direct original prerequisites')
    descendants = {name: block.decode() for name, block in first.items()
                   if name == PLAN['family'] or name.startswith(PLAN['family'] + '.')}
    return dict(original_join=first[parent].decode(), active_join=last[parent].decode(),
        original_containers_and_descendants=descendants, children={name: last[name].decode() for name in sorted(new)},
        direct_prerequisites=direct, full_alias=last[PLAN['full_alias']].decode())


def reader(role):
    """Execute every fixed member in an isolated module context; keep all output."""
    declarations = read('reader-contracts.json')
    need(set(declarations) == {'context', 'cause', 'consumer'}, 'complete original prerequisite interface domain')
    declaration = declarations[role]
    root = PLAN[role]
    need(declaration['command'] == ['python3', '-B', root + '/verify.py']
         and declaration['proof'] == root + ('/proofs.json' if role == 'context' else '/proof.json')
         and declaration['scope'] == root + ('/scope.txt' if role == 'context' else '/plan.json'),
         'exact original saved reader, proof and scope roles')
    entries = {}
    for row in git('ls-tree', '-r', '-z', PLAN['revision'], '--', root).rstrip(b'\0').split(b'\0'):
        header, name = row.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        name = name.decode()
        need(kind == 'blob' and mode in ('100644', '100755') and Path(name).parent == Path(root),
             'complete flat ordinary saved-reader namespace')
        entries[name] = dict(mode=mode, oid=oid)
    census = subprocess.run(['rg', '--files', '--hidden', '--no-ignore', '--', root], capture_output=True, text=True)
    need(census.returncode == 0 and census.stderr == '' and sorted(census.stdout.splitlines()) == sorted(entries),
         'whole independent original prerequisite namespace membership')
    bodies = fixed(entries)
    for name, body in bodies.items():
        info = Path(name).lstat()
        need(stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev
             and bool(info.st_mode & 0o111) == (entries[name]['mode'] == '100755')
             and Path(name).read_bytes() == body, 'whole fixed prerequisite source/mode/body')
    names = {Path(name).stem for name in entries if name.endswith('.py')} | {'capture'}
    previous = {name: sys.modules[name] for name in names if name in sys.modules}
    previous_path, previous_argv = sys.path[:], sys.argv[:]
    entry = declaration['command'][-1]
    scope = {'__name__': '__main__', '__file__': entry}
    terminal = io.StringIO()
    try:
        for name in names:
            sys.modules.pop(name, None)
        sys.path.insert(0, root)
        sys.argv[:] = [entry]
        with contextlib.redirect_stdout(terminal):
            exec(compile(bodies[entry], entry, 'exec'), scope)
            if role == 'context':
                source, helpers, consumers, products = scope['source_models']()
                results = scope['result_reader']
                records = {mode: scope['load'](results['CAPTURE'] / (mode + '.json'))
                           for mode in ('ordinary', 'storable', 'controls')}
                execution = scope['load'](results['CAPTURE'] / 'execution.json')
                value = dict(proofs=scope['check'](records, execution, source, helpers, consumers, products),
                             controls=scope['controls'](records, execution, source, helpers, consumers, products))
            else:
                value = scope['result']
    finally:
        sys.path[:] = previous_path
        sys.argv[:] = previous_argv
        for name in names:
            sys.modules.pop(name, None)
        sys.modules.update(previous)
    need(same(value, json.loads(bodies[declaration['proof']])) and terminal.getvalue().endswith(SUFFIXES[role]),
         'complete freshly rederived original saved meaning and native stdout')
    if role != 'context':
        need(terminal.getvalue() == SUFFIXES[role]
             and declaration['condition'] == json.loads(bodies[declaration['scope']])['condition'],
             'whole exact later reader terminal and original qualification condition')
    else:
        need(len(value['controls']) == 13 and all(type(row['status']) is int and row['status'] == 1 for row in value['controls'])
             and 'caught library refusals' in declaration['condition'], 'caught context controls are not native exit receipts')
    need(all(Path(name).read_bytes() == body for name, body in bodies.items()), 'whole original reader namespace remains readonly')
    return dict(declaration=declaration, namespace=entries, proof=value, stdout=terminal.getvalue(),
                scope=bodies[declaration['scope']].decode())


def preparation():
    first, second = read('preparation-first.json'), read('preparation-second.json')
    for row, error in ((first, 'AssertionError'), (second, "NameError: name 'review' is not defined")):
        need(row['command'] == ['python3', '-B', '-'] and type(row['status']) is int and row['status'] == 1
             and row['expected_status'] is None and row['stdout'] == '' and error in row['stderr'],
             'both unwrapped preparations remain actual1 without predeclared native status')
        raw = Path(row['source']['path']).read_bytes()
        need(Path(row['source']['path']).parent == BASE and pin(raw) == {k: row['source'][k] for k in ('bytes', 'sha256')},
             'whole explicitly after-invocation preparation source reconstruction')
        compile(raw, row['source']['path'], 'exec')
    tree = ast.parse(Path(first['source']['path']).read_bytes())
    literals = {node.targets[0].id: ast.literal_eval(node.value) for node in tree.body
                if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name)
                and node.targets[0].id in ('guide', 'changes')}
    review = read('book-review.json')
    book = fixed([BOOK])[BOOK].decode()
    proposal = book.replace(review['anchor'], review['anchor'] + '\n' + literals['guide'], 1)
    need(literals['changes'] == [tuple(row) for row in review['book_compactions'][:4]], 'whole failed first static proposal recipe')
    for old, new in literals['changes']:
        need(proposal.count(old) == 1, 'whole failed proposal original prose')
        proposal = proposal.replace(old, new, 1)
    need(len(proposal.encode()) == review['first_bytes'] == review['before_bytes'] + 2,
         'first static proposal exceeded unchanged allowance before writes')
    partial = read('preparation-partial-programmes.json')
    need(partial['condition'].startswith('After-invocation') and len(partial['programmes']) == 5,
         'explicit partial-source census after second failed informational print')
    for name, row in partial['programmes'].items():
        need(pin(row['body'].encode()) == row['identity'], 'whole retained partial programme body')
        if name == str(BASE / 'capture.py'):
            expansion = read('capture-input-expansion.json')
            expected = row['body'].replace(
                "'activation-memory.gz', 'activation-index.gz', 'reader-contracts.json'",
                "'activation-memory.gz', 'activation-index.gz', 'reader-contracts.json',\n"
                "        'activation-task-first.gz', 'preparation-first.json', 'preparation-second.json',\n"
                "        'preparation-first-source.txt', 'preparation-second-source.txt', 'preparation-partial-programmes.json', 'capture-input-expansion.json'")
            need(same(expansion['before'], row) and expansion['after']['body'] == expected
                 and pin(expected.encode()) == expansion['after']['identity']
                 and Path(name).read_bytes() == expected.encode(), 'exact capture-only input custody expansion')
        else:
            need(Path(name).read_bytes() == row['body'].encode(), 'every other partial programme remains unchanged')
    return dict(first=first, second=second, partial=partial,
                condition='Both are preparation failures; original producers/readers and semantic/native records were unchanged. Full projected and actual delivery qualify the corrected metadata, not either failed terminal.')


def gate(label, command, current=False, development=False):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
         and all(same(row[key], value) for key, value in started.items()), 'whole closed native gate')
    need(type(row['status']) is int and row['status'] == 0 and type(row['expected_status']) is int
         and row['expected_status'] == 0 and row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(row['programmes'], row['programmes_after']), 'typed distinct observed/declared status and conserved complete source/input epoch')
    own = {name: value for name, value in row['programmes'].items() if Path(name).parent == BASE and Path(name).suffix == '.py'}
    if development:
        epoch = read('development-epochs.json')['epochs'][label]
        need(same(own, epoch['programmes']) and pin((BASE / (label + '-actual.json')).read_bytes()) == epoch['actual'],
             'whole dated development programme/native epoch')
    else:
        need(same(own, read('formal-programmes.json')['programmes']), 'whole formal programme freeze')
    for name, value in row['programmes'].items():
        body = value['body'].encode() if 'body' in value else bytes.fromhex(value['body_hex'])
        need(pin(body) == value['identity'], 'whole instrument/input body identity')
        if current and not development:
            need(Path(name).read_bytes() == body, 'whole current instrument/input body')
    stream = Path('.artifacts') / BASE.name / 'checks' / label
    need(row['stdout_path'] == str(stream / 'stdout.txt') and row['stderr_path'] == str(stream / 'stderr.txt')
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'whole unchanged guard and same-volume stream routes')
    return pin(canonical(row))


def preflight():
    before = {name: Path(name).read_bytes() for name in publish.NAMES}
    need(all(before[name] == body for name, body in intake.overlays().items()), 'whole declared activation')
    contracts()
    preparation()
    after, measured = publish.transformation(before)
    roles = intake.derive()
    source = intake.live(roles)
    meanings = {role: reader(role) for role in ('context', 'cause', 'consumer')}
    need(source == intake.live(roles), 'whole source conservation around all development saved readers')
    after, measured = publish.transformation(before)
    first, last = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == last.keys(), 'whole projected task membership')
    for name, block in first.items():
        need((all(field(block, key) == field(last[name], key) for key in ('Goal', 'Acceptance', 'Children'))
              and field(last[name], 'Status') == 'done') if name == PLAN['owner'] else block == last[name],
             'whole owned projected contract and every unrelated block')
    physical = metrics({'MEMORY.md': after['MEMORY.md']})
    for row in map(json.loads, after[REGISTRY].splitlines()):
        if row.get('surface_id') == 'active_resume':
            need(all(key == 'files' or value * 100 < row['health_targets'][key] * row['milestones']['warning_pct']
                     for key, value in physical.items()), 'all resume health axes below warning')
        elif row.get('surface_id') in ('task_evidence', 'shipped_behavior'):
            actual = measured['task_metrics' if row['surface_id'] == 'task_evidence' else 'book_after']
            need(all(row['enforcement_ceilings'][key] is None or value <= row['enforcement_ceilings'][key]
                     for key, value in actual.items()), 'all unchanged task/book physical ceilings')
    factory = public()
    prior, sources = factory['historical'](), factory['sources']()
    record = factory['current_input'](prior, sources)
    record['chapter'] = after[BOOK].decode()
    factory['check'](record, sources, prior, factory['authority'](prior))
    snapshots = {}
    for i, name in enumerate(publish.NAMES):
        snapshots[name] = {}
        for role, body in (('before', before[name]), ('after', after[name])):
            path = BASE / ('development-publication-' + role + '-' + str(i) + '.gz')
            need(not path.exists(), 'retain first development publication source')
            path.write_bytes(gzip.compress(body, mtime=0))
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    save_product('development-meanings.json.gz', meanings)
    save('development-preflight.json', dict(contracts=contracts(), snapshots=snapshots, measured=measured,
        source=source, resume=physical, preparation=preparation()))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole development targets remain readonly')
    print('PASS development-only complete prerequisite meanings, source/contracts and publication preflight.')


def core(current=False):
    frozen = read('formal-programmes.json')
    need(frozen['owner'] == PLAN['owner'] and frozen['phase'] == 'formal'
         and set(frozen['programmes']) == {str(path) for path in BASE.glob('*.py')}, 'complete formal programme membership')
    for name, value in frozen['programmes'].items():
        need(Path(name).read_bytes() == value['body'].encode() and pin(value['body'].encode()) == value['identity'],
             'whole unchanged formal source')
    normal = read('cause-normal-commit.json')
    commit = re.search(r'^\[[^\]]+ ([0-9a-f]{7,40})\] ', normal['stdout'])
    need(type(normal['status']) is int and normal['status'] == 0
         and normal['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and '[doctrine] all doctrine checks passed' in normal['stdout'] + normal['stderr']
         and commit is not None and git('rev-parse', commit[1]).decode().strip() == PLAN['revision'],
         'whole prior normal commit/hook/source custody')
    commands = {
        'development-source': ['python3', '-B', str(BASE / 'intake.py'), '--development'],
        'development-preflight': ['python3', '-B', str(BASE / 'verify.py'), '--preflight'],
        'development-whitespace': ['git', 'diff', '--cached', '--check'],
        'source-before': ['python3', '-B', str(BASE / 'intake.py'), '--before'],
        'current-before': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'before'],
        'source-after': ['python3', '-B', str(BASE / 'intake.py'), '--after'],
        'root-history': ['git', 'log', '-1', '-S', 'Join complete original source context, cause, coordinate and consumer semantics.', '--format=%H %s', '--', 'docs/tasks/']}
    commands.update({'replay-' + role: declaration['command'] for role, declaration in read('reader-contracts.json').items()})
    gates = {label: gate(label, command, current, label.startswith('development-')) for label, command in commands.items()}
    roles = intake.derive()
    need(same(roles, read('source-roles.json')) and read('source-before.json') == read('source-after.json'),
         'whole original/current source roles and replay epoch conserve')
    meanings = {role: reader(role) for role in ('context', 'cause', 'consumer')}
    for role, value in meanings.items():
        need(read('replay-' + role + '-actual.json')['stdout'] == value['stdout'], 'whole native and independently reconstructed reader stdout')
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', read('root-history-actual.json')['stdout']), 'complete original join obligation history')
    developed = read('development-preflight.json')
    need(same(meanings, load_product('development-meanings.json.gz')) and developed['contracts'] == contracts()
         and same(developed['preparation'], preparation()), 'whole development/formal contract/meaning/failure correspondence')
    before = {name: gzip.decompress(Path(entry['before']['snapshot']).read_bytes()) for name, entry in developed['snapshots'].items()}
    after, measured = publish.transformation(before)
    need(same(measured, developed['measured']) and all(gzip.decompress(Path(developed['snapshots'][name]['after']['snapshot']).read_bytes()) == body
         for name, body in after.items()), 'whole reconstructed development publication')
    factory = public()
    prior, sources = factory['historical'](), canonical_sources()
    need(load_product('canonical-before.json.gz') == {name: body.decode() for name, body in sources.items()}, 'all fixed canonical bytes retain')
    factory['check'](load_product('current-before.json.gz'), sources, prior, factory['authority'](prior))
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], contracts=contracts(), meanings=meanings,
        source=pin(canonical(roles)), source_epoch=read('source-before.json'), preparation=preparation(),
        development=pin(canonical(developed)), normal_commit=pin(canonical(normal)), gates=gates, condition=PLAN['condition'],
        legs=dict(rederive='Whole unchanged contracts and freshly reexecuted complete saved context/cause/consumer meanings, source/current/query/capacity.',
            falsify='Every complete inherited genuine rejecting source/context/cause/coordinate/address/consumer candidate and actual intended outcome retains. Context caught library refusals are distinguished from separate native exits; both preparation failures remain failed.',
            durability='Complete committed sources/native programmes/inputs/commands/statuses/streams/products/controls/failures and source/publication snapshots with explicit after-invocation preparation reconstruction, sealed/default recovery and normal hooks.'))


def delivery(current=False):
    publication = publish.qualify(current)
    before, after = load_product('canonical-before.json.gz'), load_product('canonical-after.json.gz')
    need(same(before, after), 'every canonical fact/question/probe/source byte retains')
    factory = public()
    prior = factory['historical']()
    record = load_product('current-after.json.gz')
    factory['check'](record, {name: body.encode() for name, body in after.items()}, prior, factory['authority'](prior))
    need(record['chapter'].encode() == gzip.decompress(Path(publication['snapshots'][BOOK]['after']['snapshot']).read_bytes()), 'whole actual published chapter')
    source = read('source-published.json')
    need(source == dict(read('source-before.json'), overlays={name: pin(body) for name, body in intake.overlays(True).items()}),
         'whole source conservation with only five explicit publication overlays')
    if current:
        need(factory['sources']() == {name: body.encode() for name, body in after.items()}
             and same(intake.live(intake.derive(), True), source), 'whole actual current source/canonical epoch')
    native = book_native.qualify(gzip.decompress((BASE / 'native-chapter.html.gz').read_bytes()).decode())
    need(same(native, read('book-native.json')), 'whole actual native chapter')
    commands = dict(publish.COMMANDS, core=['python3', '-B', str(BASE / 'verify.py'), '--core', '--current'],
        publication=['python3', '-B', str(BASE / 'admission_publish.py')],
        **{'current-after': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'after'],
           'book-source': ['python3', '-B', 'scripts/book_source_references.py', '--write'],
           'source-published': ['python3', '-B', str(BASE / 'intake.py'), '--published'],
           'book-native': ['python3', '-B', str(BASE / 'book_native.py')],
           'whitespace': ['git', 'diff', '--cached', '--check']})
    gates = {label: gate(label, command, current) for label, command in commands.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'actual focused regression success')
    return dict(publication=publication, current=pin(canonical(record)), source=source, native=native, gates=gates)


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        info = path.lstat()
        need(stat.S_ISREG(info.st_mode) and not path.is_symlink() and info.st_dev == Path.cwd().stat().st_dev,
             'whole flat ordinary same-volume admission archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(info.st_mode & 0o111))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--preflight', action='store_true')
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    need(sum((args.preflight, args.core, args.seal)) <= 1, 'one explicit admission role')
    if args.preflight:
        preflight()
    else:
        result = core(args.current or args.seal)
        if args.core:
            print('PASS complete original prerequisite admission core; delivery remains separate.')
        else:
            result['delivery'] = delivery(args.current or args.seal)
            need(json.loads(canonical(result)) == result, 'whole JSON-native proof round trip')
            if args.seal:
                save('proof.json', result)
                save('manifest.json', catalogue())
            else:
                need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()), 'whole saved immutable prerequisite admission')
            print(SUCCESS, end='')
