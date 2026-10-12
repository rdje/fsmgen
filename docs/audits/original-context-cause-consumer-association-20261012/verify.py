"""Qualify complete independent associations with native/source/delivery custody."""
import argparse
import contextlib
import difflib
import stat
from association_inputs import *
import book_native
import controls
import intake
import model
import publish
import reader
import run_controls

SUCCESS = 'PASS complete independent original context/cause/coordinate/consumer association; canonical/parent acceptance and higher owners remain separate.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix
    for label in ('seal', 'default', 'staged-doctrines') for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


def bodies(row):
    for name, entry in row.items():
        raw = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(raw) == entry['identity'], 'whole native programme/input body identity')
        yield name, raw


def gate(label, command, current=False, development=False, status=0):
    actual, started = read(label + '-actual.json'), read(label + '-started.json')
    extra = {'candidate_inputs'} if 'candidate_inputs' in started else set()
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'} | extra
         and set(actual) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
             | ({'candidate_inputs_after'} if extra else set())
         and all(same(actual[key], value) for key, value in started.items()), 'closed complete native gate')
    need(type(actual['status']) is int and actual['status'] == status
         and type(actual['expected_status']) is int and actual['expected_status'] == status
         and actual['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(actual['programmes'], actual['programmes_after']), 'typed native declared/observed outcome and conserved source epoch')
    if extra:
        need(same(actual['candidate_inputs'], actual['candidate_inputs_after']), 'whole native candidate input conservation')
        for name, identity in actual['candidate_inputs'].items():
            path = Path(name)
            need(path.parent == BASE and path.suffix == '.gz' and not path.is_symlink()
                 and pin(path.read_bytes()) == identity, 'whole saved native candidate body')
    own = {name: entry for name, entry in actual['programmes'].items() if Path(name).parent == BASE and Path(name).suffix == '.py'}
    if development:
        epoch = read('development-epochs.json')['epochs'][label]
        need(same(own, epoch['programmes']) and pin((BASE / (label + '-actual.json')).read_bytes()) == epoch['actual'],
             'complete dated development source/native epoch')
    else:
        need(same(own, read('formal-programmes.json')['programmes']), 'whole frozen formal programme membership and bodies')
    for name, raw in bodies(actual['programmes']):
        if current and not development:
            need(Path(name).read_bytes() == raw, 'whole current native programme/input body')
    stream = Path('.artifacts') / BASE.name / 'checks' / label
    need(actual['stdout_path'] == str(stream / 'stdout.txt') and actual['stderr_path'] == str(stream / 'stderr.txt')
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', actual['stderr'])
         and 'ram-guard: terminating PID tree' not in actual['stderr'], 'unchanged guard and repository-local full terminal routes')
    return pin(canonical(actual))


def failures():
    initial = read('development-initial-programmes.json')
    programmes = initial['programmes']
    need(len(programmes) == 8, 'complete first development source population')
    for name, raw in bodies(programmes):
        if Path(name).name not in ('reader.py', 'capture.py'):
            need(Path(name).read_bytes() == raw, 'every unaffected first programme retains')
    repaired = read('typed-equality-repair.json')
    before, after = repaired['before'], repaired['after']
    need(same(before, programmes[str(BASE / 'reader.py')]), 'whole first failing reader source')
    body = before['body']
    for old, new in repaired['replacements']:
        need(body.count(old) == 1, 'unique minimal typed comparison repair beforeimage')
        body = body.replace(old, new)
    need(body == after['body'] and pin(body.encode()) == after['identity']
         and (BASE / 'reader.py').read_bytes() == body.encode()
         and repaired['diff'] == ''.join(difflib.unified_diff(before['body'].splitlines(True), body.splitlines(True),
             fromfile='first-development/reader.py', tofile='typed-repair/reader.py')), 'whole exact canonical typed-equality repair')
    capture = programmes[str(BASE / 'capture.py')]
    for name in ('capture-typed-repair-expansion.json', 'capture-candidate-input-expansion.json'):
        expansion = read(name)
        need(same(expansion['before'], capture), 'whole successive capture source epoch')
        capture = expansion['after']
        need(pin(capture['body'].encode()) == capture['identity'], 'whole capture input custody source expansion')
    need((BASE / 'capture.py').read_bytes() == capture['body'].encode(), 'whole current final capture source')
    result = {}
    for label, cause in (
        ('development-boolean-alias', 'whole own parser source text filename caller and complete API span association'),
        ('development-float-alias', 'whole own native operation and qualified cause source custody')):
        actual = read(label + '-actual.json')
        need(type(actual['status']) is int and actual['status'] == 0
             and type(actual['expected_status']) is int and actual['expected_status'] == 1
             and actual['stdout'].startswith('FALSE-GREEN: complete reader accepted malformed ')
             and same(actual['programmes'], actual['programmes_after'])
             and all(same(actual['programmes'][name], entry) for name, entry in programmes.items()),
             'first actual0/declared1 false green remains failed with complete source epoch')
        list(bodies(actual['programmes']))
        declared = initial['failures'][label]
        need(declared['receipt_identity'] == pin((BASE / (label + '-actual.json')).read_bytes())
             and same(repaired['reproductions'][label], declared), 'whole native first failure custody')
        corrected = read(label + '-v2-actual.json')
        need(type(corrected['status']) is int and corrected['status'] == 1
             and type(corrected['expected_status']) is int and corrected['expected_status'] == 1
             and corrected['stdout'] == '' and corrected['stderr'].endswith('ValueError: ' + cause + '\n')
             and same(corrected['programmes'], corrected['programmes_after']), 'corrected real intended native first refusal')
        result[label] = dict(first=pin(canonical(actual)), corrected=pin(canonical(corrected)), cause=cause)
    return dict(reproductions=result, initial=pin(canonical(initial)), repair=pin(canonical(repaired)),
        condition='Both first actual0/declared1 results remain false greens; corrected actual1/declared1 controls qualify typed equality. Every original admitted source/meaning/native/private limit retains.')


def fresh_admission():
    """Reexecute the complete unchanged admitted reader in an isolated namespace."""
    root = PLAN['admission']
    names = git('ls-tree', '-r', '--name-only', PLAN['revision'], '--', root).decode().splitlines()
    sources = fixed(names)
    need(all(Path(name).parent == Path(root) and stat.S_ISREG(Path(name).lstat().st_mode)
             and Path(name).stat().st_dev == Path.cwd().stat().st_dev and Path(name).read_bytes() == body
             for name, body in sources.items()), 'whole ordinary same-volume fixed admission namespace')
    module_names = {Path(name).stem for name in names if name.endswith('.py')} | {'capture'}
    prior = {name: sys.modules[name] for name in module_names if name in sys.modules}
    old_path, old_argv = sys.path[:], sys.argv[:]
    entry = root + '/verify.py'
    namespace = {'__name__': '__main__', '__file__': entry}
    terminal = io.StringIO()
    try:
        for name in module_names:
            sys.modules.pop(name, None)
        sys.path.insert(0, root)
        sys.argv[:] = [entry]
        with contextlib.redirect_stdout(terminal):
            exec(compile(sources[entry], entry, 'exec'), namespace)
    finally:
        sys.path[:] = old_path
        sys.argv[:] = old_argv
        for name in module_names:
            sys.modules.pop(name, None)
        sys.modules.update(prior)
    wanted = json.loads(sources[root + '/proof.json'])
    need(same(namespace['result'], wanted)
         and terminal.getvalue() == namespace['SUCCESS']
         and all(Path(name).read_bytes() == body for name, body in sources.items()),
         'fresh whole unchanged admitted source/context/cause/consumer meaning and delivery proof')
    return dict(proof=pin(canonical(wanted)), namespace={name: pin(body) for name, body in sources.items()},
                stdout=terminal.getvalue(), condition=PLAN['condition'])


def preflight():
    failures()
    data = inputs()
    candidate = model.propose(data)
    qualification = reader.check(candidate)
    for declaration in controls.declarations(candidate):
        wanted = json.loads(canonical(candidate))
        controls.mutate(wanted, declaration)
        need((declaration['cause'] is None) == same(wanted, candidate), 'genuine development-only separating mutation')
        try:
            reader.check(wanted)
        except ValueError as error:
            need(declaration['status'] == 1 and str(error) == declaration['cause'],
                 'intended development-only library refusal: ' + declaration['label'])
        else:
            need(declaration['status'] == 0, 'development-only false green: ' + declaration['label'])
    before = {name: Path(name).read_bytes() for name in publish.NAMES}
    need(all(before[name] == body for name, body in intake.overlays().items()), 'whole declared activation metadata')
    after, measured = publish.transformation(before)
    first, last = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == last.keys(), 'complete projected task population')
    for name, block in first.items():
        need((all(field(block, key) == field(last[name], key) for key in ('Goal', 'Acceptance', 'Children'))
              and field(last[name], 'Status') == 'done') if name == PLAN['owner'] else block == last[name],
             'whole unchanged projected contracts and only owned closure')
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
    save_product('development-candidate.json.gz', candidate)
    save_product('development-qualification.json.gz', qualification)
    save('development-preflight.json', dict(contracts=contracts(), snapshots=snapshots, measured=measured,
        candidate=pin(canonical(candidate)), qualification=pin(canonical(qualification)), resume=physical,
        declarations=controls.declarations(candidate), failures=failures()))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole development targets remain readonly')
    print('PASS development-only complete association, intended library controls and publication/capacity preflight; formal native controls remain required.')


def core(current=False):
    frozen = read('formal-programmes.json')
    need(frozen['owner'] == PLAN['owner'] and frozen['phase'] == 'formal'
         and set(frozen['programmes']) == {str(path) for path in BASE.glob('*.py')}, 'complete frozen formal source population')
    need(all(Path(name).read_bytes() == raw for name, raw in bodies(frozen['programmes'])), 'whole unchanged final formal programmes')
    normal = read('admission-normal-commit.json')
    commit = re.search(r'^\[[^\]]+ ([0-9a-f]{7,40})\] ', normal['stdout'])
    need(type(normal['status']) is int and normal['status'] == 0
         and normal['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and '[doctrine] all doctrine checks passed' in normal['stdout'] + normal['stderr']
         and commit is not None and git('rev-parse', commit[1]).decode().strip() == PLAN['revision'],
         'complete prior admission normal commit and hooks')
    commands = {
        'source-before': ['python3', '-B', str(BASE / 'intake.py'), '--before'],
        'replay-admission': ['python3', '-B', PLAN['admission'] + '/verify.py'],
        'proposal': ['python3', '-B', str(BASE / 'produce.py')],
        'independent': ['python3', '-B', str(BASE / 'reader.py'), '--save'],
        'native-controls': ['python3', '-B', str(BASE / 'run_controls.py')],
        'current-before': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'before'],
        'source-after': ['python3', '-B', str(BASE / 'intake.py'), '--after'],
        'root-history': ['git', 'log', '-1', '-S', 'Join complete original source context, cause, coordinate and consumer semantics.', '--format=%H %s', '--', 'docs/tasks/']}
    gates = {label: gate(label, command, current) for label, command in commands.items()}
    for label, command in {
        'development-source': ['python3', '-B', str(BASE / 'intake.py'), '--development'],
        'development-preflight': ['python3', '-B', str(BASE / 'verify.py'), '--preflight'],
        'development-whitespace': ['git', 'diff', '--cached', '--check']}.items():
        gates[label] = gate(label, command, current, True)
    roles = intake.derive()
    need(same(roles, read('source-roles.json')) and same(read('source-before.json'), read('source-after.json')),
         'whole source roles and formal native epoch conserve')
    admission = fresh_admission()
    need(read('replay-admission-actual.json')['stdout'] == admission['stdout'], 'whole complete native saved admission replay')
    candidate = load_product('candidate.json.gz')
    data = inputs()
    need(same(candidate, model.propose(data)), 'complete mode-first proposal source correspondence')
    qualification = reader.check(candidate)
    need(same(qualification, read('qualification.json')), 'complete independent source-first association qualification')
    separating = run_controls.qualify(candidate, '', current)
    for row in separating:
        declaration = row['declaration']
        gates['control-' + declaration['label']] = gate('control-' + declaration['label'], row['command'], current,
                                                       status=declaration['status'])
    developed = read('development-preflight.json')
    need(same(candidate, load_product('development-candidate.json.gz'))
         and same(qualification, load_product('development-qualification.json.gz'))
         and same(developed['declarations'], controls.declarations(candidate))
         and same(developed['contracts'], contracts()) and same(developed['failures'], failures()),
         'whole development/formal source/candidate/control/failure correspondence')
    before = {name: gzip.decompress(Path(entry['before']['snapshot']).read_bytes()) for name, entry in developed['snapshots'].items()}
    after, measured = publish.transformation(before)
    need(same(measured, developed['measured']) and all(
         gzip.decompress(Path(developed['snapshots'][name]['after']['snapshot']).read_bytes()) == body for name, body in after.items()),
         'whole projected publication reconstruction')
    factory = public()
    prior, sources = factory['historical'](), canonical_sources()
    need(same(load_product('canonical-before.json.gz'), {name: body.decode() for name, body in sources.items()}),
         'all original canonical facts/questions/probes conserve')
    factory['check'](load_product('current-before.json.gz'), sources, prior, factory['authority'](prior))
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', read('root-history-actual.json')['stdout']), 'whole original join obligation history')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], contracts=contracts(), admission=admission,
        qualification=qualification, controls=separating, source=pin(canonical(roles)), source_epoch=read('source-before.json'),
        development=pin(canonical(developed)), failures=failures(), normal_commit=pin(canonical(normal)), gates=gates,
        condition=PLAN['condition'], legs=dict(
            rederive='Whole source-first operation/helper/parser/consumer relations, unchanged original contracts and fresh complete saved admitted source/context/cause/consumer meanings, source/current/query/capacity.',
            falsify='Genuine complete changed associations reach intended actual native first refusals, including both corrected primitive-kind aliases. Both first actual0/declared1 false greens remain failed. Qualified source-derived primary causes and typed consumer truths are shared premises, never native flags.',
            durability='Full unchanged original sources/native/model/products and own programme/input/command/status/stream/candidate/control/failure/repair/publication epochs, immutable saved reconstruction and normal hooks. Original native/private uncertainty, dated executions and wider owners retain.'))


def delivery(current=False):
    publication = publish.qualify(current)
    before, after = load_product('canonical-before.json.gz'), load_product('canonical-after.json.gz')
    need(same(before, after), 'all canonical facts/questions/probes retain')
    factory = public()
    prior = factory['historical']()
    record = load_product('current-after.json.gz')
    factory['check'](record, {name: body.encode() for name, body in after.items()}, prior, factory['authority'](prior))
    need(record['chapter'].encode() == gzip.decompress(Path(publication['snapshots'][BOOK]['after']['snapshot']).read_bytes()),
         'whole current published chapter')
    source = read('source-published.json')
    need(same(source, dict(read('source-before.json'), overlays={name: pin(body) for name, body in intake.overlays(True).items()})),
         'whole source conservation with only five intended publication overlays')
    if current:
        need(factory['sources']() == {name: body.encode() for name, body in after.items()}
             and same(intake.live(intake.derive(), True), source), 'complete actual current source/canonical epoch')
    native = book_native.qualify(gzip.decompress((BASE / 'native-chapter.html.gz').read_bytes()).decode())
    need(same(native, read('book-native.json')), 'whole actual native chapter qualification')
    commands = dict(publish.COMMANDS, core=['python3', '-B', str(BASE / 'verify.py'), '--core', '--current'],
        publication=['python3', '-B', str(BASE / 'publish.py')],
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
             'whole flat ordinary same-volume association archive')
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
    need(sum((args.preflight, args.core, args.seal)) <= 1, 'one explicit association verification role')
    if args.preflight:
        preflight()
    else:
        result = core(args.current or args.seal)
        if args.core:
            print('PASS complete independent original association core; delivery remains separate.')
        else:
            result['delivery'] = delivery(args.current or args.seal)
            need(same(json.loads(canonical(result)), result), 'complete JSON-native proof roundtrip')
            if args.seal:
                save('proof.json', result)
                save('manifest.json', catalogue())
            else:
                need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()),
                     'whole immutable saved association and delivery proof')
            print(SUCCESS, end='')
