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

SUCCESS = 'PASS complete non-growing consumer canonical publication and exact whitespace recovery; canonical/original consumer acceptance remains separate.\n'
EXCLUDED = {'recovery-proof.json', 'recovery-manifest.json'} | {label + suffix for label in ('seal-v2', 'default-v2', 'staged-doctrines')
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


def epochs():
    first, recovered = read('formal-programmes.json'), read('formal-programmes-recovery.json')
    need(set(recovered) == {str(path) for path in BASE.glob('*.py')}
         and set(recovered) - set(first) == {str(BASE / name) for name in ('complete.py', 'recover.py')},
         'whole distinct first and recovered programme populations')
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
        need(pin(body) == row['identity'] and Path(name).read_bytes() == body, 'whole current recovered programme')
        if name in expected:
            need(body == expected[name], 'whole exact first to recovered programme correspondence')
            need(pin(first[name]['body'].encode()) == first[name]['identity'], 'whole first programme body')
    for name in patches:
        before = guide if name.endswith('/guide.txt') else first[name]['body'].encode()
        after = guide[:-1] if name.endswith('/guide.txt') else expected[name]
        need(patches[name]['before'] == pin(before) and patches[name]['after'] == pin(after), 'whole exact declared repair identities')
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
            recovery = read('formal-programmes-recovery.json')
            wanted = recovery[name]['body'].encode() if name in recovery else body
            need(Path(name).read_bytes() == wanted, 'whole explicit original or exactly recovered publication instrument')
    need(type(row['stderr']) is str and type(row['stdout']) is str
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged complete publication guard')
    frozen = read('formal-programmes-recovery.json' if label in RECOVERY_GATES else 'formal-programmes.json')
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
    need(not (args.core and args.seal), 'one explicit whole publication role')
    result = core(current=args.current or args.seal)
    if args.core:
        print('PASS complete first publication and exact recovered source correspondence; delivery remains separate.')
    else:
        result['publication'] = publish.qualify(current=False)
        result['external'] = {name: gate(name, command, current=args.current or args.seal) for name, command in publish.COMMANDS.items()}
        need(same(read('proof.json'), result), 'whole preserved first publication proof reconstructs unchanged')
        first = first_population()
        first['seal'] = gate('seal', ['python3', '-B', str(BASE / 'verify.py'), '--seal'])
        first['default'] = gate('default', ['python3', '-B', str(BASE / 'verify.py')])
        metadata = recover.qualify(current=args.current or args.seal)
        source = read('recovery-source.json')
        previous = read('source-after.json')
        wanted = dict(previous['overlays'], **metadata['snapshots'])
        need(source['source'] == previous['source'] and source['members'] == previous['members']
             and source['condition'] == previous['condition'] and source['overlays'] == wanted,
             'whole recovered source epoch and only explicit final metadata overlays')
        recovery_gates = {name: gate(name, command, current=args.current or args.seal)
                          for name, command in RECOVERY_GATES.items()}
        need('All tests successful' in read('focused-repaired-actual.json')['stdout'], 'actual complete recovered focused regression')
        result['recovery'] = dict(first=first, metadata=metadata, source=source, gates=recovery_gates,
            programmes=pin(canonical(read('formal-programmes-recovery.json'))),
            scope='Only exact owned whitespace/source and truthful task metadata recovery. First native2 remains failure; whole original/first evidence, published meanings and all unknowns retain. No canonical/original consumer-parent or higher closure.')
        need(json.loads(canonical(result)) == result, 'complete recovered publication JSON round trip')
        if args.seal:
            save('recovery-proof.json', result)
            save('recovery-manifest.json', catalogue())
        else:
            need(same(read('recovery-proof.json'), result) and same(read('recovery-manifest.json'), catalogue()),
                 'whole immutable first and recovered publication custody')
        print(SUCCESS, end='')
