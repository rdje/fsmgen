"""Whole finite consumer publication, original source roles and saved recovery."""
import argparse
import stat
import sys
from publication_common import *
import intake
import publish
import recover

_previous = sys.path[:]
try:
    sys.path.insert(0, 'scripts')
    import record_value_consumer_fact as fact
finally:
    sys.path[:] = _previous

SUCCESS = 'PASS complete non-growing consumer canonical publication with preserved first failures and qualified final source/index custody; canonical/original consumer acceptance remains separate.\n'
EXCLUDED = {'final-proof.json', 'final-manifest.json'} | {label + suffix for label in ('final-seal', 'final-default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


RECOVERY_GATES = {
    'recovery-publication': ['python3', '-B', str(BASE / 'recover.py')],
    'recovery-source': ['python3', '-B', str(BASE / 'recover.py'), '--source'],
    'focused-repaired': publish.COMMANDS['focused'],
    'size-repaired': publish.COMMANDS['size'],
    'claims-repaired': publish.COMMANDS['claims'],
    'inventory-repaired-write': publish.COMMANDS['inventory-write'],
    'inventory-repaired': publish.COMMANDS['inventory'],
    'whitespace-repaired': ['git', 'diff', '--cached', '--check']}


FINAL_GATES = {
    'final-publication': ['python3', '-B', str(BASE / 'finish.py'), '--publish'],
    'final-source': ['python3', '-B', str(BASE / 'finish.py'), '--source'],
    'final-sources': ['python3', '-B', 'scripts/book_source_references.py', '--write'],
    'final-focused': publish.COMMANDS['focused'],
    'final-book': publish.COMMANDS['book'],
    'final-native': publish.COMMANDS['native'],
    'final-size': publish.COMMANDS['size'],
    'final-claims': publish.COMMANDS['claims'],
    'final-inventory-write': publish.COMMANDS['inventory-write'],
    'final-inventory': publish.COMMANDS['inventory'],
    'final-whitespace': ['git', 'diff', '--cached', '--check']}
RECOVERY_SIZE_FAILURE = {'bytes': 430308, 'sha256': 'd41cf7df3584f05686e53662e288676fbd229c9dcbcee9b23e72e0d4405ce3ca'}
_development_ledger = None


def epochs():
    first, recovered = read('formal-programmes.json'), read('formal-programmes-recovery.json')
    final = _development_ledger if _development_ledger is not None else read('formal-programmes-final.json')
    need(set(final) == {str(path) for path in BASE.glob('*.py')}
         and set(final) - set(recovered) == {str(BASE / 'finish.py')}
         and set(recovered) - set(first) == {str(BASE / name) for name in ('complete.py', 'recover.py')},
         'whole distinct first10 recovered12 and final13 programme populations')
    guide = gzip.decompress((BASE / 'first-guide.gz').read_bytes())
    expected = {name: row['body'].encode() for name, row in first.items()}
    common = str(BASE / 'publication_common.py')
    need(expected[common].endswith(b'\n\n') and not expected[common][:-1].endswith(b'\n\n'),
         'exact first common EOF blank line')
    expected[common] = expected[common][:-1]
    publisher = str(BASE / 'publish.py')
    old = b"    guide = (BASE / 'guide.txt').read_bytes()"
    need(expected[publisher].count(old) == 1, 'unique guide reconstruction source locus')
    expected[publisher] = expected[publisher].replace(old, old + b" + b'\\n'", 1)
    verifier = str(BASE / 'verify.py')
    source = expected[verifier]
    marker = b"if __name__ == '__main__':"
    need(source.count(marker) == 1, 'unique default entrypoint source locus')
    expected[verifier] = source[:source.index(marker)] + (
        "if __name__ == '__main__':\n    import runpy\n    runpy.run_path(str(BASE / 'complete.py'), run_name='__main__')\n").encode()
    need(guide.endswith(b'\n\n') and not guide[:-1].endswith(b'\n\n')
         and (BASE / 'guide.txt').read_bytes() == guide[:-1], 'exact sole guide EOF trim')
    patches = read('repair-programmes.json')
    changed = {common, publisher, verifier}
    need(set(patches) == changed | {str(BASE / 'guide.txt')}, 'closed exact recovery patch domain')
    for name, row in recovered.items():
        body = row['body'].encode()
        need(pin(body) == row['identity'], 'whole preserved recovered programme')
        if name in expected:
            need(body == expected[name], 'whole exact first to recovered programme correspondence')
            need(pin(first[name]['body'].encode()) == first[name]['identity'], 'whole first programme body')
    for name in patches:
        before = guide if name.endswith('/guide.txt') else first[name]['body'].encode()
        after = guide[:-1] if name.endswith('/guide.txt') else expected[name]
        need(patches[name]['before'] == pin(before) and patches[name]['after'] == pin(after), 'whole exact declared repair identities')
    for name, row in final.items():
        body = row['body'].encode()
        need(pin(body) == row['identity'] and Path(name).read_bytes() == body, 'whole current final programme')
        if name in recovered:
            wanted = recovered[name]['body'].encode()
            if name == verifier:
                old_call = b"runpy.run_path(str(BASE / 'complete.py'), run_name='__main__')"
                new_call = b"runpy.run_path(str(BASE / 'finish.py'), run_name='__main__')"
                need(wanted.count(old_call) == 1, 'unique final default delegate')
                wanted = wanted.replace(old_call, new_call, 1)
            need(body == wanted, 'only exact final default delegate advances recovered source')
    return first, recovered


def first_population():
    first, recovered = epochs()
    population = read('first-population.json')
    old_manifest = read('manifest.json')
    excluded = {'proof.json', 'manifest.json'} | {label + suffix for label in ('seal', 'default')
        for suffix in ('-started.json', '-actual.json')}
    need(set(population) == set(old_manifest) | excluded, 'whole sealed first namespace membership')
    for name, row in population.items():
        path = BASE / name
        if str(path) in first:
            body = first[str(path)]['body'].encode()
        elif name == 'guide.txt':
            body = gzip.decompress((BASE / 'first-guide.gz').read_bytes())
        else:
            body = path.read_bytes()
        need(row == dict(**pin(body), executable=bool(path.stat().st_mode & 0o111)),
             'whole preserved first namespace body and mode')
        if name in old_manifest:
            need(old_manifest[name] == row, 'whole original sealed first catalogue')
    failure = read('whitespace-first.json')
    need(type(failure['status']) is int and failure['status'] == 2
         and type(failure['expected_status']) is int and failure['expected_status'] == 0
         and failure['command'] == ['git', 'diff', '--cached', '--check'] and failure['stderr'] == ''
         and failure['stdout'] == ''.join(str(BASE / name) + ':' + str(line) + ': new blank line at EOF.\n'
             for name, line in (('guide.txt', 14), ('publication_common.py', 89))),
         'whole original unexpected staged whitespace native2')
    return dict(population=pin(canonical(population)), manifest=pin(canonical(old_manifest)),
                failure=pin(canonical(failure)))


def gate(label, command, status=0, stdout=None, *, current=False, declared=None, epoch='first'):
    declared = status if declared is None else declared
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
         and all(same(row[key], value) for key, value in started.items()), 'closed whole native publication terminal')
    need(type(row['status']) is int and row['status'] == status
         and type(row['expected_status']) is int and row['expected_status'] == declared,
         'actual typed intended publication result ' + label)
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(row['programmes'], row['programmes_after']), 'whole actual command and programme epoch')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole actual programme/input body')
        if current:
            recovery = read('formal-programmes-final.json')
            wanted = recovery[name]['body'].encode() if name in recovery else body
            need(Path(name).read_bytes() == wanted, 'whole explicit original or exactly recovered publication instrument')
    need(type(row['stderr']) is str and type(row['stdout']) is str
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged complete publication guard')
    frozen = read({'first': 'formal-programmes.json', 'recovery': 'formal-programmes-recovery.json', 'final': 'formal-programmes-final.json'}[epoch])
    need(all(row['programmes'].get(name) == entry for name, entry in frozen.items()),
         'whole frozen own programme source epoch in every formal gate')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'complete intended publication terminal')
    return pin(canonical(row))


def factory():
    implementation = read('implementation.json')
    body = gzip.decompress(Path(implementation['scripts/check_record_value_publication.py']['snapshot']).read_bytes())
    need(pin(body) == implementation['scripts/check_record_value_publication.py']['identity'], 'whole admitted maintained factory')
    namespace = {'__name__': 'saved_consumer_current_factory', '__file__': 'scripts/check_record_value_publication.py'}
    previous = sys.path[:]
    try:
        sys.path.insert(0, 'scripts')
        exec(compile(body, namespace['__file__'], 'exec'), namespace)
    finally:
        sys.path[:] = previous
    return namespace


def contracts():
    original_body = fixed([TASK])[TASK]
    active_body = intake.overlays()[TASK]
    original = nodes(original_body)
    active = nodes(active_body)
    expected_body = original_body.replace(original[PLAN['owner']],
        original[PLAN['owner']].replace(b'  Status: `pending`', b'  Status: `active`', 1), 1)
    need(expected_body.count(b'- Last updated: `2026-10-11`') == 1, 'exact prior task metadata date')
    expected_body = expected_body.replace(b'- Last updated: `2026-10-11`', b'- Last updated: `2026-10-12`', 1)
    need(active_body == expected_body, 'whole exact activation and owned metadata-date repair')
    need(original.keys() == active.keys(), 'whole original consumer/canonical task domain')
    for name, block in original.items():
        if name == PLAN['owner']:
            need(field(block, 'Status') == 'pending' and field(active[name], 'Status') == 'active'
                 and block.replace(b'  Status: `pending`', b'  Status: `active`', 1) == active[name],
                 'only exact unchanged publication child activates')
        else:
            need(block == active[name], 'every unchanged original parent and completed descendant contract')
    need(field(active[PLAN['parent']], 'Status') == field(active[PLAN['consumer']], 'Status') == 'active'
         and field(active[PLAN['parent'] + '.1'], 'Status') == 'done'
         and field(active[PLAN['parent'] + '.3'], 'Status') == 'pending', 'only publication is in scope')
    return {name: {key: field(active[name], key) for key in ('Goal', 'Acceptance', 'Children', 'Status')}
            for name in (PLAN['owner'], PLAN['parent'], PLAN['consumer'])}


def core(*, current=False):
    epochs()
    development = read('development-phase.json')
    need(development['formal_started'] is False and development['owner'] == PLAN['owner'], 'declared prior development boundary')
    need(type(read('development-actual.json')['status']) is int and read('development-actual.json')['status'] == 1
         and read('development-actual.json')['expected_status'] == 0
         and read('development-v3-actual.json')['status'] == 1
         and read('development-v3-actual.json')['expected_status'] == 0
         and read('development-v4-actual.json')['status'] == 1
         and read('development-v4-actual.json')['expected_status'] == 0
         and read('development-v5-actual.json')['status'] == read('development-controls-actual.json')['status']
         == read('development-full-controls-actual.json')['status'] == 0,
         'complete actual prior development preflight and permanent controls')
    preview = load_product('development-source-proposal.json.gz')
    publication = read('publication.json')
    need(preview['after'] == {name: gzip.decompress(Path(roles['after']['snapshot']).read_bytes()).decode()
                             for name, roles in publication['snapshots'].items()},
         'whole development and formal publication afterimages correspond')
    receipt = read('preparation-normal-commit.json')
    need(type(receipt['status']) is int and receipt['status'] == 0
         and receipt['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and PLAN['revision'][:9] in receipt['stdout'].splitlines()[0]
         and '[doctrine] all doctrine checks passed' in receipt['stdout'] + receipt['stderr'],
         'whole prior normal preparation commit and hooks')
    roles = intake.derive()
    need(same(roles, read('source-roles.json')), 'complete fixed original/current source roles')
    before, after = read('source-before.json'), read('source-after.json')
    need(before['source'] == after['source'] == pin(canonical(roles['publication']))
         and before['members'] == after['members'] == sorted(set(roles['publication']['members']) | set(intake.overlays())),
         'complete fixed/current source and member domain')
    for later, row in ((False, before), (True, after)):
        need(row['overlays'] == {name: pin(body) for name, body in intake.overlays(later).items()},
             'only exact declared activation/implementation/publication source overlays')
    legacy = json.loads((Path(PLAN['preparation']) / 'integration-contract.json').read_bytes())['retained_dependencies']
    retained = fixed(legacy)
    need(all(pin(body) == legacy[name] and Path(name).read_bytes() == body for name, body in retained.items()),
         'all historical helper bodies and fixed-source import contracts retain')
    candidate = fact.admission()
    admission = read('admission.json')
    admitted = fact.authenticate()
    need(same(admission['qualification'], admitted) and same(admission['candidate'], candidate)
         and admission['before'] == candidate['before'] and admission['after'] == fact.published(candidate),
         'whole admitted source-bound consumer meanings and source/native custody')
    proposal = load_product('before-proposal.json.gz')
    original = {'__name__': 'fixed_predecessor_factory', '__file__': 'scripts/check_record_value_publication.py'}
    first = (BASE / 'before-factory.py.txt').read_bytes()
    need(first == fixed(['scripts/check_record_value_publication.py'])['scripts/check_record_value_publication.py'], 'whole original predecessor factory')
    previous = sys.path[:]
    try:
        sys.path.insert(0, 'scripts')
        exec(compile(first, original['__file__'], 'exec'), original)
    finally:
        sys.path[:] = previous
    canonical_before = canonical_sources()
    prospective = dict(canonical_before, **{fact.CARD: candidate['after'].encode()})
    need(proposal['canonical'] == {name: body.decode() for name, body in prospective.items()}, 'whole genuine predecessor proposal')
    try:
        prior = original['historical']()
        original['check'](proposal['record'], prospective, prior, original['authority'](prior))
    except ValueError as error:
        need(str(error) == 'complete current target meanings questions metadata and replay routes', 'independent intended predecessor refusal')
    else:
        raise ValueError('complete predecessor accepted unadmitted consumer meanings')
    sources = {name: text.encode() for name, text in load_product('canonical-after.json.gz').items()}
    need(sources == prospective, 'whole canonical production changes only admitted finite consumer meanings')
    record = load_product('current-after.json.gz')
    public = factory()
    prior = public['historical']()
    public['check'](record, sources, prior, public['authority'](prior))
    if current:
        need(public['sources']() == sources, 'whole explicit live current canonical source')
    commands = {
        'source-before': ['python3', '-B', str(BASE / 'intake.py'), '--before'],
        'source-after': ['python3', '-B', str(BASE / 'intake.py'), '--after'],
        'before': ['python3', '-B', str(BASE / 'before.py')],
        'admission': ['python3', '-B', str(BASE / 'admit.py')],
        'preparation': ['python3', '-B', PLAN['preparation'] + '/verify.py'],
        'root-history': ['git', 'log', '-1', '-S', 'cause_fact.cards', '--format=%H %s', '--', 'scripts/check_record_value_publication.py'],
        'publication': ['python3', '-B', str(BASE / 'publish.py')],
        'current': ['python3', '-B', str(BASE / 'current_snapshot.py')],
        'controls': ['python3', '-B', '-m', 'unittest', 'discover', '-s', 't/python', '-p', 'test_record_value_current_publication.py', '-v'],
        'map': ['knowledge-map/scripts/gen_knowledge_map.sh'],
        'sources': ['python3', '-B', 'scripts/book_source_references.py', '--write'],
    }
    gates = {name: gate(name, command, 1 if name == 'before' else 0, current=current) for name, command in commands.items()}
    need(read('before-actual.json')['stdout'] == 'REFUSED complete prepared consumer meanings at unchanged predecessor target contract.\n',
         'actual complete genuine predecessor native refusal')
    control = read('controls-actual.json')
    need('\nOK\n' in control['stderr'] and all(name in control['stderr'] for name in (
        'test_consumer_admission_preserves_every_predecessor_meaning_and_route',
        'test_consumer_first_admission_rejects_proposed_schema_and_native_authority',
        'test_consumer_proposal_cannot_borrow_meanings_grow_or_promote_scope',
        'test_consumer_actual_requires_its_complete_typed_source_role',
        'test_consumer_original_size_failure_requires_its_distinct_native_role')), 'complete actual meaningful permanent consumer controls')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], source=pin(canonical(roles)),
        source_before=before, source_after=after, contracts=contracts(), admission=pin(canonical(admission)),
        normal_commit=pin(canonical(receipt)), admitted=admitted, canonical=pin(canonical({n: pin(b) for n, b in sources.items()})),
        current=pin(canonical(record)), gates=gates, condition=PLAN['condition'], legs=dict(
            rederive='Whole original/current fixed source/contract/native/canonical evidence, exact reviewed finite meanings, complete direct/cached source-derived questions and all physical metrics.',
            falsify='Actual unchanged predecessor native1 and complete meaningful permanent first-admission, lost meaning/question/probe, original failure custody, Boolean, borrowed source/command/programme and native-promotion refusals.',
            durability='Complete preparation, original source/native/product/failure custody, programme/command/terminal epochs, full before/after snapshots and normal commit receipts; saved reconstruction requires no ignored checkpoint.'))


def check_staging_failure():
    identity = gate('size-repaired', RECOVERY_GATES['size-repaired'], status=1, declared=0, epoch='recovery')
    need(identity == RECOVERY_SIZE_FAILURE, 'whole fixed original recovery failure source and terminal')
    stderr = read('size-repaired-actual.json')['stderr']
    need('live-doc-resulting-tree: controlled path differs between staged result and worktree: ' + TASK in stderr
         and 'live-doc-resulting-tree: controlled path differs between staged result and worktree: ' + REGISTRY in stderr
         and 'live-doc-ceiling-authority: controlled files differ between the staged index and worktree' in stderr,
         'whole actual original recovery staging-custody failure')
    return identity


FINAL_REOPEN = ('First recovery size gate failed actual1/expected0 because controlled Task/registry working copies differed from the previously staged first epoch. Capacity checks passed; own the staging-order repair and retain all twelve-programme evidence. Earlier verification: ')
FINAL_FINDING = ('First recovery size gate failed actual1/expected0 on exact Task/registry staged-worktree custody differences, not capacity. The driver invoked resulting-tree authority before restaging repaired controlled metadata. Preserve first10/recovery12 source/native populations and both original failures. Final13 advances only the default delegate and adds complete qualification with distinct actual/declared failure statuses. Stage intended controlled metadata before resulting-tree checks; final source/focused/size/claim/inventory/whitespace/doctrine and normal commit custody qualify this unchanged publication owner. Published card/book, prior helpers, old meanings, original failures, unknowns and ceilings retain.')


def final_metadata():
    recover.qualify(current=False)
    first = {name: gzip.decompress((BASE / ('recovery-after-' + str(i) + '.gz')).read_bytes())
             for i, name in enumerate(recover.NAMES)}
    reopened = dict(first)
    for i, name in enumerate((TASK, 'MEMORY.md', 'docs/TASK_TREE.md')):
        reopened[name] = gzip.decompress((BASE / ('final-reopened-' + str(i) + '.gz')).read_bytes())
    owner, block = PLAN['owner'], nodes(first[TASK])[PLAN['owner']]
    active = block.replace(b'  Status: `done`', b'  Status: `active`', 1)
    active = active.replace(b'  Verification: `', ('  Verification: `' + FINAL_REOPEN).encode(), 1)
    need(reopened[TASK] == first[TASK].replace(block, active, 1), 'whole exact final custody reopening')
    memory = first['MEMORY.md'].replace((PLAN['parent'] + '.3` (pending)').encode(), (owner + '` (active)').encode(), 1)
    memory = re.sub(rb'^- next_action:.*$', b'- next_action: Repair owned staging-order custody; preserve both earlier epochs, stage controlled metadata before resulting-tree checks, and finish publication.', memory, flags=re.M)
    need(reopened['MEMORY.md'] == memory and reopened['docs/TASK_TREE.md'] == first['docs/TASK_TREE.md'].replace(
        b'canonical publication done; acceptance next.', b'canonical publication recovery active.', 1), 'whole exact final bounded pointer reopening')
    after = dict(first)
    verification = field(block, 'Verification')
    final = block.replace(('  Verification: `' + verification + '`').encode(),
                          ('  Verification: `' + verification + ' ' + FINAL_FINDING + '`').encode(), 1)
    final = final.rstrip() + ('\n  Finding F3: `' + FINAL_FINDING + '`\n\n').encode()
    after[TASK] = first[TASK].replace(block, final, 1)
    rows = list(map(json.loads, first[REGISTRY].splitlines()))
    publication = read('publication.json')
    tasks = fixed(publication['task_names']); tasks[TASK] = after[TASK]
    measured = metrics(tasks)
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            for key, value in measured.items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged final task ceilings')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
    after[REGISTRY] = b''.join(canonical(row) for row in rows)
    need(all(after[name] == first[name] for name in (BOOK, 'MEMORY.md', 'docs/TASK_TREE.md', PLAN['target'])),
         'whole final published card/book and pointers retain')
    need(all(field(block, key) == field(nodes(after[TASK])[owner], key)
             for key in ('Goal', 'Acceptance', 'Children', 'Commit', 'Status')), 'whole final unchanged owner contract')
    return first, reopened, after, measured


def qualify_final(*, current=False):
    _, _, after, measured = final_metadata()
    row = read('final-metadata.json')
    need(row['owner'] == PLAN['owner'] and row['task_metrics'] == measured
         and row['snapshots'] == {name: pin(body) for name, body in after.items()}, 'whole final metadata correspondence')
    for i, name in enumerate(recover.NAMES):
        body = gzip.decompress((BASE / ('final-after-' + str(i) + '.gz')).read_bytes())
        need(body == after[name] and (not current or Path(name).read_bytes() == body), 'whole exact saved/current final metadata')
    return row


def publish_final():
    epochs()
    _, reopened, after, measured = final_metadata()
    need(all(Path(name).read_bytes() == body for name, body in reopened.items()), 'whole current final reopened input')
    for i, name in enumerate(recover.NAMES):
        path = BASE / ('final-after-' + str(i) + '.gz')
        need(not path.exists(), 'fresh complete final afterimage')
        path.write_bytes(gzip.compress(after[name], mtime=0))
    save('final-metadata.json', dict(owner=PLAN['owner'], task_metrics=measured,
         snapshots={name: pin(body) for name, body in after.items()}))
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published only final truthful custody metadata; canonical card/book unchanged.')


def current_source():
    epochs()
    qualify_final(current=True)
    _, _, after, _ = final_metadata()
    previous = intake.overlays
    try:
        intake.overlays = lambda later=False: dict(previous(later), **after) if later else previous()
        result = intake.live(read('source-roles.json'), True)
    finally:
        intake.overlays = previous
    return result


def source_final():
    result = current_source()
    save('final-source.json', result)
    print('PASS whole final current source and exact controlled metadata; all prior epochs retain.')


def final_gates(*, current=False):
    selection = read('final-gate-selection.json')
    need(set(selection) == set(FINAL_GATES), 'whole final gate selection')
    result = {}
    for role, command in FINAL_GATES.items():
        labels = selection[role]
        need(type(labels) is list and labels and len(labels) == len(set(labels))
             and labels[0] == role and all(label == role + '-v' + str(i + 1) for i, label in enumerate(labels[1:], 1)),
             'ordered distinct final gate attempt roles')
        actual_labels = {p.name.removesuffix('-actual.json') for p in BASE.glob(role + '*-actual.json')
                         if re.fullmatch(re.escape(role) + r'(?:-v(?:[2-9]|[1-9][0-9]+))?-actual\.json', p.name)}
        need(actual_labels == set(labels), 'no omitted final gate attempts')
        attempts = []
        for i, label in enumerate(labels):
            actual = read(label + '-actual.json')
            status = actual['status']
            need(type(status) is int and (status == 0 if i == len(labels) - 1 else status != 0),
                 'final accepted success and distinct earlier failures')
            attempts.append(dict(label=label, status=status, declared=actual['expected_status'],
                identity=gate(label, command, status=status, declared=0, current=current, epoch='final')))
        result[role] = attempts
    return result


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
    parser.add_argument('--publish', action='store_true')
    parser.add_argument('--source', action='store_true')
    args = parser.parse_args()
    need(sum((args.core, args.seal, args.publish, args.source)) <= 1, 'one explicit final qualification role')
    if args.publish:
        publish_final()
    elif args.source:
        source_final()
    else:
        result = core(current=False)
        result['publication'] = publish.qualify(current=False)
        result['external'] = {name: gate(name, command) for name, command in publish.COMMANDS.items()}
        need(same(read('proof.json'), result), 'whole original first proof reconstructs unchanged')
        if args.core:
            print('PASS complete first proof and exact first10/recovery12/final13 programme correspondence.')
        else:
            first = first_population()
            first['seal'] = gate('seal', ['python3', '-B', str(BASE / 'verify.py'), '--seal'])
            first['default'] = gate('default', ['python3', '-B', str(BASE / 'verify.py')])
            recovery = {name: gate(name, RECOVERY_GATES[name], epoch='recovery')
                        for name in ('recovery-publication', 'recovery-source', 'focused-repaired')}
            recovery['size-failure'] = check_staging_failure()
            metadata = qualify_final(current=args.current or args.seal)
            source = read('final-source.json')
            before = read('source-after.json')
            need(source['source'] == before['source'] and source['members'] == before['members']
                 and source['condition'] == before['condition']
                 and source['overlays'] == dict(before['overlays'], **metadata['snapshots']),
                 'whole final source epoch and only declared metadata overlays')
            if args.current or args.seal:
                need(same(current_source(), source), 'whole fresh final current source still conserves at sealing')
            result['final'] = dict(first=first, recovery=recovery, metadata=metadata, source=source,
                gates=final_gates(current=args.current or args.seal),
                programmes=pin(canonical(read('formal-programmes-final.json'))),
                condition='Both actual first failures remain non-success. Only owned whitespace/source/index custody and truthful metadata recover; whole published card/book, original evidence, helpers, meanings, unknowns and ceilings retain. Canonical/original consumer and higher acceptance remain separate.')
            if args.seal:
                save('final-proof.json', result)
                save('final-manifest.json', catalogue())
            else:
                need(same(read('final-proof.json'), result) and same(read('final-manifest.json'), catalogue()),
                     'whole immutable first/recovery/final evidence custody')
            print(SUCCESS, end='')
