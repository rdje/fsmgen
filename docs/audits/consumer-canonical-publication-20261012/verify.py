"""Whole finite consumer publication, original source roles and saved recovery."""
import argparse
import stat
import sys
from publication_common import *
import intake
import publish

_previous = sys.path[:]
try:
    sys.path.insert(0, 'scripts')
    import record_value_consumer_fact as fact
finally:
    sys.path[:] = _previous

SUCCESS = 'PASS complete non-growing finite consumer canonical publication; complete consumer-parent acceptance remains separately owned.\n'
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
    frozen = read('formal-programmes.json')
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
    frozen = read('formal-programmes.json')
    need(set(frozen) == {str(path) for path in BASE.glob('*.py')}, 'whole frozen publication programme population')
    for name, entry in frozen.items():
        body = entry['body'].encode()
        need(pin(body) == entry['identity'] and Path(name).read_bytes() == body, 'whole frozen publication programme body')
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
    import runpy
    runpy.run_path(str(BASE / 'finish.py'), run_name='__main__')
