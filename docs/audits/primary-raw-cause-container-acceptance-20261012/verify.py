"""Qualify unchanged containing contracts against the complete recovered cause proof."""
import argparse
import ast
import contextlib
import stat
from container_common import *
import book_native
import container_publish as publish
import intake

SUCCESS = 'PASS unchanged original primary/raw cause-container acceptance; higher join and full alias remain separate.\n'
CAUSE_SUCCESS = 'PASS complete unchanged finite primary/raw cause and canonical parent acceptance; every higher owner and original native/private limit retains.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix
    for label in ('seal', 'default', 'staged-doctrines') for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


def contracts():
    original = fixed([TASK])[TASK]
    active = gzip.decompress((BASE / PLAN['activation_task']).read_bytes())
    first, last = nodes(original), nodes(active)
    owner, parent = PLAN['owner'], PLAN['parent']
    need(owner not in first and set(last) == set(first) | {owner}, 'one exact added owned acceptance leaf')
    children = ', '.join(parent + '.' + str(i) for i in range(1, 4))
    need(field(first[parent], 'Status') == field(last[parent], 'Status') == 'active'
         and field(first[parent], 'Children') == children
         and field(last[parent], 'Children') == children + ', ' + owner,
         'unchanged original active container and declared child-list addition')
    expected_parent = first[parent].replace(('  Children: `' + children + '`').encode(),
        ('  Children: `' + children + ', ' + owner + '`').encode(), 1)
    consumer = PLAN['higher_join'].rsplit('.', 1)[0] + '.3'
    wanted = original.replace(first[parent], expected_parent, 1).replace(first[consumer], last[owner] + first[consumer], 1)
    need(wanted == active and field(last[owner], 'Status') == 'active', 'whole exact activation transformation')
    descendants = {name: block.decode() for name, block in first.items() if name.startswith(parent + '.')}
    need(all(field(first[name], 'Status') == 'done' and first[name] == last[name] for name in descendants),
         'every complete original primary/raw/cause descendant contract retains')
    need(field(last[PLAN['higher_join']], 'Status') == field(last[PLAN['full_alias']], 'Status') == 'pending',
         'separate higher and full-alias acceptances remain pending')
    return dict(original_container=first[parent].decode(), active_container=last[parent].decode(),
                original_descendants=descendants, acceptance_leaf=last[owner].decode(),
                higher_join=last[PLAN['higher_join']].decode(), full_alias=last[PLAN['full_alias']].decode())


def cause_qualification():
    """Execute the whole unchanged recovered entrypoint in its isolated module context."""
    root = PLAN['cause_join']
    listing = git('ls-tree', '-r', '-z', PLAN['revision'], '--', root).rstrip(b'\0').split(b'\0')
    entries = {}
    for row in listing:
        header, name = row.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        name = name.decode()
        need(kind == 'blob' and mode in ('100644', '100755') and Path(name).parent == Path(root),
             'whole flat ordinary recovered cause namespace')
        entries[name] = dict(mode=mode, oid=oid)
    census = subprocess.run(['rg', '--files', '--hidden', '--no-ignore', '--', root], capture_output=True, text=True)
    need(census.returncode == 0 and census.stderr == '' and sorted(census.stdout.splitlines()) == sorted(entries),
         'whole independent recovered cause namespace membership')
    bodies = fixed(entries)
    for name, body in bodies.items():
        info = Path(name).lstat()
        need(stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev
             and bool(info.st_mode & 0o111) == (entries[name]['mode'] == '100755')
             and Path(name).read_bytes() == body, 'whole fixed recovered cause source/mode/body')
    names = {Path(name).stem for name in entries if name.endswith('.py')} | {'capture'}
    previous = {name: sys.modules[name] for name in names if name in sys.modules}
    previous_path, previous_argv = sys.path[:], sys.argv[:]
    entry = root + '/' + PLAN['cause_entry']
    scope = {'__name__': '__main__', '__file__': entry}
    terminal = io.StringIO()
    try:
        for name in names:
            sys.modules.pop(name, None)
        sys.path.insert(0, root)
        sys.argv[:] = [entry]
        with contextlib.redirect_stdout(terminal):
            exec(compile(bodies[entry], entry, 'exec'), scope)
    finally:
        sys.path[:] = previous_path
        sys.argv[:] = previous_argv
        for name in names:
            sys.modules.pop(name, None)
        sys.modules.update(previous)
    result = scope['result']
    need(terminal.getvalue() == CAUSE_SUCCESS and same(result, json.loads(bodies[root + '/proof.json'])),
         'whole independently rederived unchanged recovered cause proof and native terminal')
    return result


def preparation():
    custody = read('preparation-source-custody.json')
    result = {}
    for tag in ('preparation-first', 'preparation-anchor-read-first'):
        native = read(tag + '.json')
        first = (BASE / (tag + '.py.txt')).read_bytes()
        source = Path(custody[tag]['corrected_source']['path']).read_bytes()
        need(native['command'] == ['python3', '-B', '-'] and type(native['status']) is int
             and native['status'] == 1 and native['expected_status'] is None,
             'first unwrapped actual1 retains absent prelaunch declaration')
        need(pin(first) == custody[tag]['first_transcription'] ==
             {key: native['stdin'][key] for key in ('bytes', 'sha256')}
             and pin(source) == {key: custody[tag]['corrected_source'][key] for key in ('bytes', 'sha256')}
             and source == first.replace(bytes([92, 92, 110]), bytes([92, 110]))
             and pin((BASE / (tag + '.json')).read_bytes()) == custody[tag]['native'],
             'whole first transcription, explicit escape correction and unchanged native terminal custody')
        compile(source, str(BASE / (tag + '-source.txt')), 'exec')
        need(native['stderr'].endswith('AssertionError\n' if tag == 'preparation-first'
                                      else 'ValueError: subsection not found\n'), 'whole first preparation refusal locus')
        result[tag] = dict(native=pin(canonical(native)), source=custody[tag])
    review = read('book-review.json')
    original_book = fixed([BOOK])[BOOK]
    notice = fixed([PLAN['cause_join'] + '/notice.txt'])[PLAN['cause_join'] + '/notice.txt']
    need(original_book.count(notice) == 0 and original_book.count(review['anchor'].encode()) == 1
         and PLAN['cause_entry'] == 'complete.py', 'dated notice absent and exact recovered current command admitted')
    return result


def coverage(qualified):
    original = nodes(fixed([TASK])[TASK])[PLAN['parent']]
    acceptance = field(original, 'Acceptance')
    clauses = [
        ('Derive own intended API/helper/parser primary causes from complete source models/contracts', ['original', 'core', 'qualification']),
        ('preserve exact full class/message/stack/source coordinate bytes and per-capture address lifetimes', ['original', 'core', 'qualification', 'product']),
        ('reject actual first-cause/full-stack/borrowed-context/false-green controls', ['original', 'core', 'controls']),
        ('No broad normalization or pattern-only/full-trace success can substitute for primary truth', ['original', 'core', 'qualification', 'inputs']),
        ('wider host-native qualification remains separately owned', ['original', 'core', 'boundary'])]
    rows = []
    for clause, path in clauses:
        need(clause in acceptance, 'exact unchanged original container acceptance clause')
        value = qualified
        for key in path:
            value = value[key]
        rows.append(dict(clause=clause, path=path, identity=pin(canonical(value))))
    return dict(goal=field(original, 'Goal'), acceptance=acceptance, clauses=rows,
                source_native_boundary=qualified['original']['core']['boundary'], condition=PLAN['condition'])


def gate(label, command, current=False, development=False, status=0, declared=0):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
         and all(same(row[key], value) for key, value in started.items()), 'whole closed native gate')
    need(type(row['status']) is int and row['status'] == status and type(row['expected_status']) is int
         and row['expected_status'] == declared and row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(row['programmes'], row['programmes_after']), 'distinct typed observed/declared status and conserved command/source epoch')
    own = {name: value for name, value in row['programmes'].items() if Path(name).parent == BASE and Path(name).suffix == '.py'}
    if development:
        epoch = read('development-epochs.json')['epochs'][label]
        need(same(own, epoch['programmes']) and pin((BASE / (label + '-actual.json')).read_bytes()) == epoch['actual'],
             'whole explicitly dated development programme/input/native epoch')
    else:
        need(same(own, read('formal-programmes.json')['programmes']), 'whole unchanged formal programme freeze')
    for name, value in row['programmes'].items():
        body = value['body'].encode() if 'body' in value else bytes.fromhex(value['body_hex'])
        need(pin(body) == value['identity'], 'whole programme source identity')
        if current and not development:
            need(Path(name).read_bytes() == body, 'whole current programme body')
    stream = Path('.artifacts') / BASE.name / 'checks' / label
    need(row['stdout_path'] == str(stream / 'stdout.txt') and row['stderr_path'] == str(stream / 'stderr.txt')
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'whole native guard and repository-local stream route')
    return pin(canonical(row))


def repaired_preflight():
    first = read('development-preflight-actual.json')
    repair = read('preflight-repair.json')
    source = first['programmes'][str(BASE / 'verify.py')]['body']
    minimal = Path(repair['minimal_repaired_source']['path']).read_text()
    wanted = source.replace("row['surface_id'] == 'active_resume'", "row.get('surface_id') == 'active_resume'")
    wanted = wanted.replace("row['surface_id'] in ('task_evidence', 'shipped_behavior')",
                            "row.get('surface_id') in ('task_evidence', 'shipped_behavior')")
    need(minimal == wanted and minimal != source and pin(source.encode()) == repair['first_source']
         and pin(minimal.encode()) == {key: repair['minimal_repaired_source'][key] for key in ('bytes', 'sha256')}
         and pin((BASE / 'development-preflight-actual.json').read_bytes()) == repair['first_actual'],
         'whole first source and exact minimal two-predicate metadata repair')
    def function(body):
        return ast.get_source_segment(body, next(node for node in ast.parse(body).body
            if isinstance(node, ast.FunctionDef) and node.name == 'preflight'))
    need(function(minimal) == function((BASE / 'verify.py').read_text()),
         'current preflight retains only the minimal selector repair')
    need(first['stdout'] == '' and first['stderr'].endswith("KeyError: 'surface_id'\n"),
         'whole first unexpected native registry-control-row refusal remains failure')
    header = json.loads(fixed([REGISTRY])[REGISTRY].splitlines()[0])
    need('surface_id' not in header and header['record_type'] == 'registry', 'legitimate fixed registry control row')
    first_plan = json.loads(first['programmes'][str(BASE / 'plan.json')]['body'])
    need(PLAN == dict(first_plan, activation_task=PLAN['activation_task'])
         and json.loads((BASE / 'plan-before-preflight-recovery.json').read_bytes()) == first_plan,
         'only declared owned activation metadata advances after first failure')
    changed = {name for name, value in first['programmes'].items()
               if Path(name).read_bytes() != (value['body'].encode() if 'body' in value else bytes.fromhex(value['body_hex']))}
    need(changed == {str(BASE / name) for name in ('verify.py', 'container_publish.py', 'plan.json')},
         'only owned metadata selector/qualification/publication evidence and activation input advance')
    return dict(first=gate('development-preflight', ['python3', '-B', str(BASE / 'verify.py'), '--preflight'],
                          development=True, status=1, declared=0), repair=repair,
                condition='The first guarded whole preflight remains actual1/declared0. The minimal metadata selector repair and separately successful complete second preflight qualify; original semantic programmes/predicates/inputs/native records remain unchanged.')


def preflight():
    before = {name: Path(name).read_bytes() for name in publish.NAMES}
    need(all(before[name] == body for name, body in intake.overlays().items()), 'whole qualified activation before preflight')
    roles = intake.derive()
    first_source = intake.live(roles)
    qualified = cause_qualification()
    need(first_source == intake.live(roles), 'whole source conservation around development recovered cause execution')
    after, measured = publish.transformation(before)
    initial, final = nodes(before[TASK]), nodes(after[TASK])
    need(initial.keys() == final.keys(), 'whole projected task membership')
    for name, block in initial.items():
        need((all(field(block, key) == field(final[name], key) for key in ('Goal', 'Acceptance', 'Children'))
              and field(final[name], 'Status') == 'done') if name in (PLAN['owner'], PLAN['parent'])
             else block == final[name], 'whole projected contract or unchanged unrelated block')
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
            need(not path.exists(), 'retain first development source snapshot')
            path.write_bytes(gzip.compress(body, mtime=0))
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    save_product('development-cause-proof.json.gz', qualified)
    save('development-preflight.json', dict(contracts=contracts(), coverage=coverage(qualified),
        snapshots=snapshots, measured=measured, resume=physical, source=first_source, preparation=preparation()))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'development projection leaves all targets unchanged')
    print('PASS development-only complete cause-container contracts, recovered proof and whole publication preflight.')


def core(current=False):
    frozen = read('formal-programmes.json')
    need(frozen['owner'] == PLAN['owner'] and frozen['phase'] == 'formal'
         and set(frozen['programmes']) == {str(path) for path in BASE.glob('*.py')}, 'whole formal programme membership')
    for name, value in frozen['programmes'].items():
        need(Path(name).read_bytes() == value['body'].encode() and pin(value['body'].encode()) == value['identity'],
             'whole unchanged formal programme source')
    normal = read('consumer-normal-commit.json')
    commit = re.search(r'^\[[^\]]+ ([0-9a-f]{7,40})\] ', normal['stdout'])
    need(type(normal['status']) is int and normal['status'] == 0
         and normal['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and '[doctrine] all doctrine checks passed' in normal['stdout'] + normal['stderr']
         and commit is not None and git('rev-parse', commit[1]).decode().strip() == PLAN['revision'],
         'whole prior normal commit and hook custody at exact source revision')
    commands = {
        'development-source': ['python3', '-B', str(BASE / 'intake.py'), '--development'],
        'development-preflight-v2': ['python3', '-B', str(BASE / 'verify.py'), '--preflight'],
        'development-whitespace': ['git', 'diff', '--cached', '--check'],
        'source-before': ['python3', '-B', str(BASE / 'intake.py'), '--before'],
        'replay-cause': ['python3', '-B', PLAN['cause_join'] + '/' + PLAN['cause_entry']],
        'current-before': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'before'],
        'source-after': ['python3', '-B', str(BASE / 'intake.py'), '--after'],
        'root-history': ['git', 'log', '-1', '-S', 'Qualify exact primary causes and complete raw original native coordinates.', '--format=%H %s', '--', 'docs/tasks/']}
    gates = {label: gate(label, command, current=current, development=label.startswith('development-'))
             for label, command in commands.items()}
    need(read('replay-cause-actual.json')['stdout'] == CAUSE_SUCCESS
         and re.fullmatch(r'[0-9a-f]{40} .+\n', read('root-history-actual.json')['stdout']), 'whole native recovered entrypoint and original obligation history')
    roles = intake.derive()
    need(same(roles, read('source-roles.json')) and read('source-before.json') == read('source-after.json'),
         'whole unchanged original/current source roles and execution epoch')
    qualified = cause_qualification()
    developed = read('development-preflight.json')
    need(same(qualified, load_product('development-cause-proof.json.gz')) and developed['contracts'] == contracts()
         and same(developed['coverage'], coverage(qualified)), 'full development/formal unchanged contract and proof correspondence')
    before = {name: gzip.decompress(Path(entry['before']['snapshot']).read_bytes()) for name, entry in developed['snapshots'].items()}
    after, measured = publish.transformation(before)
    need(same(measured, developed['measured']) and all(
        gzip.decompress(Path(developed['snapshots'][name]['after']['snapshot']).read_bytes()) == body for name, body in after.items()),
        'whole independently reconstructed preflight publication')
    factory = public()
    prior, sources = factory['historical'](), canonical_sources()
    need(load_product('canonical-before.json.gz') == {name: body.decode() for name, body in sources.items()}, 'all fixed canonical bytes')
    factory['check'](load_product('current-before.json.gz'), sources, prior, factory['authority'](prior))
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], contracts=contracts(), cause_proof=qualified,
        coverage=coverage(qualified), source=pin(canonical(roles)), source_epoch=read('source-before.json'),
        preparation=preparation(), development=pin(canonical(developed)), development_refusal=repaired_preflight(),
        normal_commit=pin(canonical(normal)),
        gates=gates, condition=PLAN['condition'], legs=dict(
            rederive='Unchanged whole container/descendant contracts and fresh complete recovered cause/current source/query/capacity reconstruction.',
            falsify='Every whole genuine original source/cause/raw/coordinate/address/contract/native-boundary candidate and intended native first outcome requalifies through the complete unchanged recovered reader. Both unwrapped preparation refusals and guarded first preflight actual1/declared0 remain failures; the metadata-only repair has separate successful complete execution.',
            durability='Complete committed source/native/programme/command/product/control/failure/repair and before/after snapshots, with explicit after-invocation preparation source reconstruction, saved recovery and normal hooks.'))


def delivery(current=False):
    publication = publish.qualify(current)
    before, after = load_product('canonical-before.json.gz'), load_product('canonical-after.json.gz')
    need(same(before, after), 'every canonical fact question probe and source byte retains')
    factory = public()
    prior = factory['historical']()
    record = load_product('current-after.json.gz')
    factory['check'](record, {name: body.encode() for name, body in after.items()}, prior, factory['authority'](prior))
    need(record['chapter'].encode() == gzip.decompress(Path(publication['snapshots'][BOOK]['after']['snapshot']).read_bytes()),
         'whole actual published chapter')
    source = read('source-published.json')
    need(source == dict(read('source-before.json'), overlays={name: pin(body) for name, body in intake.overlays(True).items()}),
         'whole source conservation with only five declared publication overlays')
    if current:
        need(factory['sources']() == {name: body.encode() for name, body in after.items()}
             and same(intake.live(intake.derive(), True), source), 'whole current source/canonical epoch')
    native = book_native.qualify(gzip.decompress((BASE / 'native-chapter.html.gz').read_bytes()).decode())
    need(same(native, read('book-native.json')), 'whole actual native chapter qualification')
    commands = dict(publish.COMMANDS, publication=['python3', '-B', str(BASE / 'container_publish.py')],
        **{'current-after': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'after'],
           'book-source': ['python3', '-B', 'scripts/book_source_references.py', '--write'],
           'source-published': ['python3', '-B', str(BASE / 'intake.py'), '--published'],
           'book-native': ['python3', '-B', str(BASE / 'book_native.py')],
           'whitespace': ['git', 'diff', '--cached', '--check']})
    gates = {label: gate(label, command, current=current) for label, command in commands.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'actual focused regression success')
    return dict(publication=publication, current=pin(canonical(record)), source=source, native=native, gates=gates)


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        info = path.lstat()
        need(stat.S_ISREG(info.st_mode) and not path.is_symlink() and info.st_dev == Path.cwd().stat().st_dev,
             'whole flat ordinary same-volume acceptance archive')
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
    need(sum((args.preflight, args.core, args.seal)) <= 1, 'one acceptance role')
    if args.preflight:
        preflight()
    else:
        result = core(args.current or args.seal)
        if args.core:
            print('PASS unchanged original primary/raw cause-container acceptance core; delivery remains separate.')
        else:
            result['delivery'] = delivery(args.current or args.seal)
            need(json.loads(canonical(result)) == result, 'whole proof JSON-native round trip')
            if args.seal:
                save('proof.json', result)
                save('manifest.json', catalogue())
            else:
                need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()), 'whole saved immutable container acceptance')
            print(SUCCESS, end='')
