"""Whole finite cause publication, original source roles and saved recovery."""
import argparse
import stat
import sys
from publication_common import *
import intake
import publish

_previous = sys.path[:]
try:
    sys.path.insert(0, 'scripts')
    import record_value_cause_fact as fact
finally:
    sys.path[:] = _previous

SUCCESS = 'PASS complete non-growing finite cause canonical publication; complete cause-parent acceptance remains separately owned.\n'
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


def factory():
    implementation = read('implementation.json')
    body = gzip.decompress(Path(implementation['scripts/check_record_value_publication.py']['snapshot']).read_bytes())
    need(pin(body) == implementation['scripts/check_record_value_publication.py']['identity'], 'whole admitted maintained factory')
    namespace = {'__name__': 'saved_cause_current_factory', '__file__': 'scripts/check_record_value_publication.py'}
    previous = sys.path[:]
    try:
        sys.path.insert(0, 'scripts')
        exec(compile(body, namespace['__file__'], 'exec'), namespace)
    finally:
        sys.path[:] = previous
    return namespace


def contracts():
    original = nodes(fixed([TASK])[TASK])
    active = nodes(intake.overlays()[TASK])
    need(original.keys() == active.keys(), 'whole original cause/canonical task domain')
    for name, block in original.items():
        if name == PLAN['owner']:
            need(field(block, 'Status') == 'pending' and field(active[name], 'Status') == 'active'
                 and block.replace(b'  Status: `pending`', b'  Status: `active`', 1) == active[name],
                 'only exact unchanged publication child activates')
        else:
            need(block == active[name], 'every unchanged original parent and completed descendant contract')
    need(field(active[PLAN['parent']], 'Status') == field(active[PLAN['cause']], 'Status') == 'active'
         and field(active[PLAN['parent'] + '.1'], 'Status') == 'done'
         and field(active[PLAN['parent'] + '.3'], 'Status') == 'pending', 'only publication is in scope')
    return {name: {key: field(active[name], key) for key in ('Goal', 'Acceptance', 'Children', 'Status')}
            for name in (PLAN['owner'], PLAN['parent'], PLAN['cause'])}


def core(*, current=False):
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
         'whole admitted source-bound cause meanings and source/native custody')
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
        raise ValueError('complete predecessor accepted unadmitted cause meanings')
    sources = {name: text.encode() for name, text in load_product('canonical-after.json.gz').items()}
    need(sources == prospective, 'whole canonical production changes only admitted finite cause meanings')
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
        'root-history': ['git', 'log', '-1', '-S', 'raw_fact.cards', '--format=%H %s', '--', 'scripts/check_record_value_publication.py'],
        'publication': ['python3', '-B', str(BASE / 'publish.py')],
        'current': ['python3', '-B', str(BASE / 'current_snapshot.py')],
        'controls': ['python3', '-B', '-m', 'unittest', 'discover', '-s', 't/python', '-p', 'test_record_value_current_publication.py', '-v'],
        'map': ['knowledge-map/scripts/gen_knowledge_map.sh'],
        'sources': ['python3', '-B', 'scripts/book_source_references.py', '--write'],
    }
    gates = {name: gate(name, command, 1 if name == 'before' else 0, current=current) for name, command in commands.items()}
    need(read('before-actual.json')['stdout'] == 'REFUSED complete prepared cause meanings at unchanged predecessor target contract.\n',
         'actual complete genuine predecessor native refusal')
    control = read('controls-actual.json')
    need('\nOK\n' in control['stderr'] and all(name in control['stderr'] for name in (
        'test_cause_admission_preserves_every_predecessor_meaning_and_route',
        'test_cause_first_admission_rejects_proposed_schema_and_native_authority',
        'test_cause_proposal_cannot_borrow_meanings_grow_or_promote_scope',
        'test_cause_actual_requires_its_complete_typed_source_role')), 'complete actual meaningful permanent cause controls')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], source=pin(canonical(roles)),
        source_before=before, source_after=after, contracts=contracts(), admission=pin(canonical(admission)),
        normal_commit=pin(canonical(receipt)), admitted=admitted, canonical=pin(canonical({n: pin(b) for n, b in sources.items()})),
        current=pin(canonical(record)), gates=gates, condition=PLAN['condition'], legs=dict(
            rederive='Whole original/current fixed source/contract/native/canonical evidence, exact reviewed finite meanings, complete direct/cached source-derived questions and all physical metrics.',
            falsify='Actual unchanged predecessor native1 and complete meaningful permanent first-admission, lost meaning/question/probe, Boolean, borrowed source/command/programme and native-promotion refusals.',
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
        print('PASS complete non-growing finite cause publication core; cause-parent acceptance remains open.')
    else:
        result['publication'] = publish.qualify(current=args.current or args.seal)
        result['external'] = {name: gate(name, command, current=args.current or args.seal) for name, command in publish.COMMANDS.items()}
        need('All tests successful' in read('focused-actual.json')['stdout'], 'actual complete focused publication regression')
        need(json.loads(canonical(result)) == result, 'complete JSON-native publication round trip')
        if args.seal:
            save('proof.json', result)
            save('manifest.json', catalogue())
        else:
            need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()), 'whole immutable saved finite cause publication')
        print(SUCCESS, end='')
