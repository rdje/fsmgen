"""Qualify complete original join canonical preparation with native/source/delivery custody."""
import argparse
import contextlib
import difflib
import stat
from preparation_inputs import *
import book_native
import controls
import intake
import model
import publish
import reader
import run_controls
import resource_observer

SUCCESS = 'PASS complete non-growing original join canonical preparation; production original parents and full alias remain separate.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix
    for label in ('seal', 'default', 'staged-doctrines') for suffix in ('-started.json', '-actual.json')} | {label + '-resources.json.gz' for label in ('seal', 'default')}


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


def stream_namespace():
    """Compare every complete fixed archived body without accumulating negative cases."""
    root = PLAN['association']
    names = git('ls-tree', '-r', '--name-only', PLAN['revision'], '--', root).decode().splitlines()
    need(names == sorted(str(path) for path in Path(root).iterdir()), 'complete fixed flat association namespace')
    result = {}
    process = subprocess.Popen(['git', '--no-replace-objects', 'cat-file', '--batch'],
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        for name in names:
            info = Path(name).lstat()
            need(Path(name).parent == Path(root) and stat.S_ISREG(info.st_mode)
                 and info.st_dev == Path.cwd().stat().st_dev, 'ordinary same-volume fixed association namespace')
            process.stdin.write((PLAN['revision'] + ':' + name + '\n').encode())
            process.stdin.flush()
            header = process.stdout.readline().split()
            need(len(header) == 3 and header[1] == b'blob', 'whole fixed association blob header')
            remaining = int(header[2])
            import hashlib
            digest = hashlib.sha256()
            with Path(name).open('rb') as local:
                while remaining:
                    size = min(1048576, remaining)
                    body = process.stdout.read(size)
                    need(len(body) == size and local.read(size) == body, 'whole streamed fixed association source bytes')
                    digest.update(body)
                    remaining -= size
                need(local.read(1) == b'' and process.stdout.read(1) == b'\n', 'whole fixed association EOF')
            result[name] = dict(bytes=int(header[2]), sha256=digest.hexdigest(), executable=bool(info.st_mode & 0o111))
        process.stdin.close()
        need(process.stdout.read(1) == b'' and process.stderr.read() == b'' and process.wait() == 0,
             'whole native read-only streamed Git source result')
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
    manifest = json.loads(Path(root, 'manifest.json').read_bytes())
    excluded = {'proof.json', 'manifest.json'} | {label + suffix for label in
        ('seal', 'default', 'staged-doctrines') for suffix in ('-started.json', '-actual.json')}
    need(same(manifest, {Path(name).name: value for name, value in result.items() if Path(name).name not in excluded}),
         'complete committed source proof native control failure repair catalogue')
    return result


def fresh_association():
    before = stream_namespace()
    terminal = io.StringIO()
    with contextlib.redirect_stdout(terminal):
        with association_module('verify') as namespace:
            entry = PLAN['association'] + '/verify.py'
            namespace['__name__'] = '__main__'
            exec(compile(Path(entry).read_bytes(), entry, 'exec'), namespace)
    wanted = json.loads(Path(PLAN['association'], 'proof.json').read_bytes())
    need(same(namespace['result'], wanted) and terminal.getvalue() == namespace['SUCCESS']
         and same(before, stream_namespace()), 'fresh complete unchanged association meaning and whole saved proof')
    return dict(proof=pin(canonical(wanted)), namespace=before, stdout=terminal.getvalue(), condition=PLAN['condition'])


def resource_failure():
    first = read('replay-association-actual.json')
    initial = read('formal-programmes-initial.json')
    need(type(first['status']) is int and first['status'] == 137
         and type(first['expected_status']) is int and first['expected_status'] == 0
         and first['stdout'] == '' and same(first['programmes'], first['programmes_after'])
         and first['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', PLAN['association'] + '/verify.py']
         and re.fullmatch(r'ram-guard: PID [0-9]+; host 73\.4%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n'
                          r'ram-guard: host memory 88\.2% reached cutoff 88%\nram-guard: terminating PID tree: [0-9]+ \n', first['stderr']),
         'first actual137 declared0 unchanged host-cutoff failure remains non-success')
    own = {name: row for name, row in first['programmes'].items() if Path(name).parent == BASE and name.endswith('.py')}
    need(len(own) == 13 and same(own, initial['programmes']), 'whole first thirteen-programme resource failure epoch')
    list(bodies(first['programmes']))
    failure = read('resource-failure.json')
    need(failure['owner'] == PLAN['owner'] and failure['finding'] == 'F1'
         and same(failure['first']['identity'], pin((BASE / 'replay-association-actual.json').read_bytes()))
         and same(failure['programmes'], initial)
         and same(failure['activation_before'], pin(gzip.decompress((BASE / 'activation-task-initial.gz').read_bytes())))
         and same(failure['activation_after'], pin(gzip.decompress((BASE / 'activation-task-resource.gz').read_bytes()))),
         'whole owned first source metadata native and attribution-gap record')
    parse = read('resource-edit-parse-failure.json')
    need(type(parse['status']) is int and parse['status'] == 1 and parse['expected_status'] is None
         and parse['stderr'].endswith('SyntaxError: invalid syntax\n')
         and same(parse['programmes'], initial), 'separate unwrapped pre-execution edit failure and unchanged complete source epoch')
    repair = read('resource-repair.json')
    current = read('formal-programmes-resource.json')['programmes']
    need(repair['owner'] == PLAN['owner'] and same(repair['before'], initial['programmes'])
         and same(repair['after'], current), 'whole before and after external resource-observer source extension')
    changes = {name for name in set(current) | set(own) if not same(current.get(name), own.get(name))}
    need(changes == {str(BASE / name) for name in ('intake.py', 'publish.py', 'verify.py', 'resource_observer.py')}
         and set(repair['diffs']) == changes, 'only explicit observer census publication and proof source extensions')
    for name in changes:
        before = own.get(name, {'body': ''})['body']
        after = current.get(name, {'body': ''})['body']
        need(repair['diffs'][name] == ''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True),
             fromfile='first-development/' + Path(name).name, tofile='resource-observation/' + Path(name).name)),
             'whole exact resource observation programme change')
    survey = read('resource-survey.json')
    need(survey['owner'] == PLAN['owner'] and len(survey['native']) == len(resource_observer.COMMANDS)
         and all(type(row['status']) is int and row['status'] == 0 and row['command'] == command
                 and row['stderr'] == '' and row['stdout'] for row, command in zip(survey['native'], resource_observer.COMMANDS, strict=True)),
         'complete native post-stop survey without retrospective attribution')
    return dict(first=pin(canonical(first)), failure=pin(canonical(failure)), parse=pin(canonical(parse)),
                repair=pin(canonical(repair)), survey=pin(canonical(survey)), condition=resource_observer.CONDITION)


def ordering_failure():
    first, corrected = read('development-order-failure-actual.json'), read('development-order-corrected-actual.json')
    need(type(first['status']) is int and first['status'] == 1
         and type(first['expected_status']) is int and first['expected_status'] == 1
         and first['stdout'] == '' and first['stderr'].endswith('ValueError: canonical JSON roundtrip changes complete declaration order\n')
         and same(first['programmes'], first['programmes_after']), 'genuine first canonical-roundtrip native ordering refusal')
    need(type(corrected['status']) is int and corrected['status'] == 0
         and type(corrected['expected_status']) is int and corrected['expected_status'] == 0
         and corrected['stdout'] == 'PASS complete declaration meanings and order retain across canonical JSON roundtrip.\n'
         and same(corrected['programmes'], corrected['programmes_after'])
         and same(first['command'], corrected['command']), 'identical canonical-roundtrip native probe passes after minimal repair')
    own = lambda row: {name: value for name, value in row['programmes'].items()
                       if Path(name).parent == BASE and name.endswith('.py')}
    before, minimal = own(first), own(corrected)
    need(same(before, read('formal-programmes-resource.json')['programmes'])
         and same(minimal, read('declaration-minimal-programmes.json')), 'whole first and minimally repaired fourteen-programme epochs')
    repaired = read('declaration-order-repair.json')
    name = str(BASE / 'controls.py')
    need(repaired['owner'] == PLAN['owner'] and repaired['path'] == name
         and same(repaired['before'], before[name]) and same(repaired['after'], minimal[name])
         and same(repaired['first'], pin((BASE / 'development-order-failure-actual.json').read_bytes())),
         'whole source-bound first ordering refusal and minimal repair')
    old, new = repaired['replacements'][0]
    need(len(repaired['replacements']) == 1 and before[name]['body'].count(old) == 1
         and before[name]['body'].replace(old, new, 1) == minimal[name]['body']
         and repaired['diff'] == ''.join(difflib.unified_diff(before[name]['body'].splitlines(True),
             minimal[name]['body'].splitlines(True), fromfile='first-resource/controls.py', tofile='ordered/controls.py'))
         and all(same(value, minimal[path]) for path, value in before.items() if path != name),
         'exact one-line enumeration repair preserves every other programme')
    extension = read('declaration-orchestration.json')
    current = {str(path): dict(body=path.read_text(), identity=pin(path.read_bytes())) for path in BASE.glob('*.py')}
    need(extension['owner'] == PLAN['owner'] and same(extension['before'], minimal)
         and same(extension['after'], current), 'complete source epochs for versioned output and recovery orchestration')
    changed = {path for path in current if not same(current[path], minimal[path])}
    need(changed == {str(BASE / filename) for filename in
         ('intake.py', 'current_snapshot.py', 'produce.py', 'reader.py', 'run_controls.py', 'publish.py', 'verify.py')}
         and set(extension['diffs']) == changed, 'only declared output orchestration and proof programmes advance')
    for path in changed:
        need(extension['diffs'][path] == ''.join(difflib.unified_diff(minimal[path]['body'].splitlines(True),
             current[path]['body'].splitlines(True), fromfile='minimal-order/' + Path(path).name,
             tofile='ordered-recovery/' + Path(path).name)), 'whole exact versioned orchestration source change')
    # The independent meaning predicate itself does not change with CLI output naming.
    first_reader, final_reader = minimal[str(BASE / 'reader.py')]['body'], current[str(BASE / 'reader.py')]['body']
    need(first_reader.split("if __name__ == '__main__':", 1)[0] == final_reader.split("if __name__ == '__main__':", 1)[0],
         'whole independent canonical meaning reader retains')
    finding, queue, correction = read('declaration-order-finding.json'), read('queue-hold.json'), read('queue-hold-correction.json')
    need(finding['owner'] == PLAN['owner'] and finding['finding'] == 'F2'
         and finding['development'] != finding['formal'] and sorted(finding['development']) == sorted(finding['formal'])
         and same(correction['corrects'], dict(path=str(BASE / 'queue-hold.json'), **pin((BASE / 'queue-hold.json').read_bytes()))),
         'whole first ordering finding and explicit correction of inaccurate queue annotation')
    interrupted = read('source-after-v2-incomplete.json')
    need(interrupted['owner'] == PLAN['owner'] and interrupted['observed_native_status'] is None
         and type(interrupted['expected_status']) is int and interrupted['expected_status'] == 0
         and type(interrupted['queue_exit_status']) is int and interrupted['queue_exit_status'] == 143
         and not (BASE / 'source-after-v2-actual.json').exists()
         and same(interrupted['started'], pin((BASE / 'source-after-v2-started.json').read_bytes()))
         and same(interrupted['source_after_invocation'], before), 'incomplete census remains unknown non-success without forged native afterimage')
    for role, entry in interrupted['streams'].items():
        raw = Path(entry['path']).read_bytes()
        need(role in ('stdout', 'stderr') and same(pin(raw), entry['identity']) and raw.decode() == entry['body'],
             'whole retained incomplete native census stream')
    return dict(first=pin(canonical(first)), corrected=pin(canonical(corrected)), repair=pin(canonical(repaired)),
        orchestration=pin(canonical(extension)), finding=pin(canonical(finding)), queue=pin(canonical(queue)),
        queue_correction=pin(canonical(correction)), incomplete_census=pin(canonical(interrupted)),
        condition='Exact one-line ordering repair and identical native1 to native0 probe preserve every complete case meaning. '
                  'Dated valid controls retain. The inaccurate queue annotation is explicitly corrected; parent143 and incomplete '
                  'census with unknown native outcome remain non-success. No original meaning, native/private boundary or parent closure advances.')


def preflight():
    resource_failure()
    ordering_failure()
    prefix = 'development-v3-'
    ctx = context()
    candidate = model.propose(ctx)
    qualification = reader.check(candidate, ctx)
    need(same(controls.declarations(candidate), controls.declarations(json.loads(canonical(candidate)))),
         'whole declaration order and meanings retain across canonical roundtrip')
    for declaration in controls.declarations(candidate):
        wanted = json.loads(canonical(candidate))
        controls.mutate(wanted, declaration)
        need((declaration['cause'] is None) == same(wanted, candidate), 'genuine development-only separating mutation')
        try:
            reader.check(wanted, ctx)
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
            path = BASE / (prefix + 'publication-' + role + '-' + str(i) + '.gz')
            need(not path.exists(), 'retain first development publication source')
            path.write_bytes(gzip.compress(body, mtime=0))
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    save_product(prefix + 'candidate.json.gz', candidate)
    save_product(prefix + 'qualification.json.gz', qualification)
    save(prefix + 'preflight.json', dict(contracts=contracts(), snapshots=snapshots, measured=measured,
        candidate=pin(canonical(candidate)), qualification=pin(canonical(qualification)), resume=physical,
        declarations=controls.declarations(candidate), association=ctx['data']['association']))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole development targets remain readonly')
    print('PASS development-only complete canonical preparation, intended library controls and publication/capacity preflight; formal native controls remain required.')


def core(current=False):
    frozen = read('formal-programmes.json')
    need(frozen['owner'] == PLAN['owner'] and frozen['phase'] == 'formal'
         and set(frozen['programmes']) == {str(path) for path in BASE.glob('*.py')}, 'complete frozen formal source population')
    need(all(Path(name).read_bytes() == raw for name, raw in bodies(frozen['programmes'])), 'whole unchanged final formal programmes')
    normal = read('association-normal-commit.json')
    commit = re.search(r'^\[[^\]]+ ([0-9a-f]{7,40})\] ', normal['stdout'])
    need(type(normal['status']) is int and normal['status'] == 0
         and normal['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and '[doctrine] all doctrine checks passed' in normal['stdout'] + normal['stderr']
         and commit is not None and git('rev-parse', commit[1]).decode().strip() == PLAN['revision'],
         'complete prior independent association normal commit and hooks')
    commands = {
        'source-before-v3': ['python3', '-B', str(BASE / 'intake.py'), '--before', '--prefix', 'v3-'],
        'proposal-v3': ['python3', '-B', str(BASE / 'produce.py'), '--prefix', 'v3-'],
        'independent-v3': ['python3', '-B', str(BASE / 'reader.py'), '--candidate', 'v3-candidate.json.gz', '--save'],
        'native-controls-v3': ['python3', '-B', str(BASE / 'run_controls.py'), '--prefix', 'v3-'],
        'current-before-v3': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'before', '--prefix', 'v3-'],
        'source-after-v3': ['python3', '-B', str(BASE / 'intake.py'), '--after', '--prefix', 'v3-'],
        'root-history': ['git', 'log', '-1', '-S', 'Join complete original source context, cause, coordinate and consumer semantics.', '--format=%H %s', '--', 'docs/tasks/']}
    gates = {label: gate(label, command, current) for label, command in commands.items()}
    for label, command in {
        'development-source': ['python3', '-B', str(BASE / 'intake.py'), '--development'],
        'development-preflight': ['python3', '-B', str(BASE / 'verify.py'), '--preflight'],
        'development-whitespace': ['git', 'diff', '--cached', '--check'],
        'source-before': ['python3', '-B', str(BASE / 'intake.py'), '--before'],
        'development-source-v2': ['python3', '-B', str(BASE / 'intake.py'), '--development', '--prefix', 'v2-'],
        'development-preflight-v2': ['python3', '-B', str(BASE / 'verify.py'), '--preflight'],
        'development-whitespace-v2': ['git', 'diff', '--cached', '--check'],
        'source-before-v2': ['python3', '-B', str(BASE / 'intake.py'), '--before', '--prefix', 'v2-'],
        'replay-association-v2': ['python3', '-B', PLAN['association'] + '/verify.py'],
        'proposal': ['python3', '-B', str(BASE / 'produce.py')],
        'independent': ['python3', '-B', str(BASE / 'reader.py'), '--save'],
        'native-controls': ['python3', '-B', str(BASE / 'run_controls.py')],
        'current-before': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'before'],
        'development-order-failure': ['python3', '-B', '.artifacts/' + BASE.name + '/order-probe.py'],
        'development-order-corrected': ['python3', '-B', '.artifacts/' + BASE.name + '/order-probe.py'],
        'development-source-v3': ['python3', '-B', str(BASE / 'intake.py'), '--development', '--prefix', 'v3-'],
        'development-preflight-v3': ['python3', '-B', str(BASE / 'verify.py'), '--preflight'],
        'development-whitespace-v3': ['git', 'diff', '--cached', '--check']}.items():
        gates[label] = gate(label, command, current, True, status=1 if label == 'development-order-failure' else 0)
    earlier = run_controls.qualify(load_product('candidate.json.gz'), '', False)
    for row in earlier:
        declaration = row['declaration']
        gates['earlier-control-' + declaration['label']] = gate('control-' + declaration['label'], row['command'],
            current=False, development=True, status=declaration['status'])
    roles = intake.derive()
    need(same(roles, read('v3-source-roles.json')) and same(read('v3-source-before.json'), read('v3-source-after.json')),
         'whole source roles and formal native epoch conserve')
    association = fresh_association()
    need(read('replay-association-v2-actual.json')['stdout'] == association['stdout'], 'whole complete native saved independent association replay')
    candidate = load_product('v3-candidate.json.gz')
    ctx = context()
    need(same(candidate, model.propose(ctx)), 'complete reviewed canonical proposal source correspondence')
    qualification = reader.check(candidate, ctx)
    need(same(qualification, read('v3-qualification.json')), 'complete independent canonical meaning qualification')
    separating = run_controls.qualify(candidate, 'v3-', current)
    for row in separating:
        declaration = row['declaration']
        gates['control-' + declaration['label']] = gate('v3-control-' + declaration['label'], row['command'], current,
                                                       status=declaration['status'])
    developed = read('development-v3-preflight.json')
    need(same(candidate, load_product('development-v3-candidate.json.gz'))
         and same(qualification, load_product('development-v3-qualification.json.gz'))
         and same(developed['declarations'], controls.declarations(candidate))
         and same(developed['contracts'], contracts()) and same(developed['association'], ctx['data']['association']),
         'whole development/formal source/candidate/control/failure correspondence')
    before = {name: gzip.decompress(Path(entry['before']['snapshot']).read_bytes()) for name, entry in developed['snapshots'].items()}
    after, measured = publish.transformation(before)
    need(same(measured, developed['measured']) and all(
         gzip.decompress(Path(developed['snapshots'][name]['after']['snapshot']).read_bytes()) == body for name, body in after.items()),
         'whole projected publication reconstruction')
    factory = public()
    prior, sources = factory['historical'](), canonical_sources()
    need(same(load_product('v3-canonical-before.json.gz'), {name: body.decode() for name, body in sources.items()}),
         'all original canonical facts/questions/probes conserve')
    factory['check'](load_product('v3-current-before.json.gz'), sources, prior, factory['authority'](prior))
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', read('root-history-actual.json')['stdout']), 'whole original join obligation history')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], contracts=contracts(), association=association,
        qualification=qualification, controls=separating, source=pin(canonical(roles)), source_epoch=read('v3-source-before.json'),
        development=pin(canonical(developed)), resource_failure=resource_failure(), ordering_failure=ordering_failure(),
        earlier_controls=earlier,
        replay_resources=resource_observer.qualify('replay-association-v2'), normal_commit=pin(canonical(normal)), gates=gates,
        condition=PLAN['condition'], legs=dict(
            rederive='Complete unchanged source-first associations and original parent/descendant contracts; independently declared whole paragraph facts/questions/probes, query allocation and non-growing capacity.',
            falsify='Genuine whole changed canonical proposals reach intended native first refusals for borrowed, omitted, typed-kind, false-green, promoted or widened authority. All original native first failures retain; qualified source-derived causes and typed truths are shared premises, never native flags.',
            durability='Full committed association namespace and all original source/native/model/control/failure/repair products; own complete programmes/inputs/commands/statuses/streams/candidates/epochs and sealed/default recovery with normal hooks. Original assumptions native/private limits and dated execution boundaries retain.'))


def delivery(current=False):
    publication = publish.qualify(current)
    before, after = load_product('v3-canonical-before.json.gz'), load_product('v3-canonical-after.json.gz')
    need(same(before, after), 'all canonical facts/questions/probes retain')
    factory = public()
    prior = factory['historical']()
    record = load_product('v3-current-after.json.gz')
    factory['check'](record, {name: body.encode() for name, body in after.items()}, prior, factory['authority'](prior))
    need(record['chapter'].encode() == gzip.decompress(Path(publication['snapshots'][BOOK]['after']['snapshot']).read_bytes()),
         'whole current published chapter')
    source = read('v3-source-published.json')
    need(same(source, dict(read('v3-source-before.json'), overlays={name: pin(body) for name, body in intake.overlays(True).items()})),
         'whole source conservation with only five intended publication overlays')
    if current:
        need(factory['sources']() == {name: body.encode() for name, body in after.items()}
             and same(intake.live(intake.derive(), True), source), 'complete actual current source/canonical epoch')
    native = book_native.qualify(gzip.decompress((BASE / 'native-chapter.html.gz').read_bytes()).decode())
    need(same(native, read('book-native.json')), 'whole actual native chapter qualification')
    commands = dict(publish.COMMANDS, core=['python3', '-B', str(BASE / 'verify.py'), '--core', '--current'],
        publication=['python3', '-B', str(BASE / 'publish.py')],
        **{'current-after-v3': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'after', '--prefix', 'v3-'],
           'book-source': ['python3', '-B', 'scripts/book_source_references.py', '--write'],
           'source-published-v3': ['python3', '-B', str(BASE / 'intake.py'), '--published', '--prefix', 'v3-'],
           'book-native': ['python3', '-B', str(BASE / 'book_native.py')],
           'whitespace': ['git', 'diff', '--cached', '--check']})
    gates = {label: gate(label, command, current) for label, command in commands.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'actual focused regression success')
    return dict(publication=publication, current=pin(canonical(record)), source=source, native=native, gates=gates, core_resources=resource_observer.qualify('core'))


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        info = path.lstat()
        need(stat.S_ISREG(info.st_mode) and not path.is_symlink() and info.st_dev == Path.cwd().stat().st_dev,
             'whole flat ordinary same-volume preparation archive')
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
            print('PASS complete non-growing original join canonical preparation core; delivery remains separate.')
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
