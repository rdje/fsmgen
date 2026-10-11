"""Qualify complete finite cause association with dated and explicit current roles."""
import argparse
import copy
import stat

from cause_common import *
import controls
import intake
import reader

SUCCESS = 'PASS complete finite independent primary/raw cause association; canonical and cause-parent acceptance remain open.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


def gate(label, command, stdout=None, *, current=False):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
         and all(same(row[key], value) for key, value in started.items()), 'closed complete actual native gate')
    need(type(row['status']) is int and row['status'] == 0
         and type(row['expected_status']) is int and row['expected_status'] == 0, 'typed actual positive native success')
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(row['programmes'], row['programmes_after']), 'whole actual command and programme epoch')
    direct = {name for name in command if '\n' not in name and len(name) < 240 and Path(name).is_file()}
    own = {Path(name).name for name in direct if Path(name).parent == BASE}
    dependencies = {'capture.py'} | own
    if own - {'intake.py'}:
        dependencies.add('cause_common.py')
    if 'controls.py' in own:
        dependencies.add('reader.py')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole actual programme or input body')
        # Enumerated auxiliary own programmes retain their actual dated bodies;
        # only the command and its declared imports carry current-source claims.
        if current and (Path(name).parent != BASE or Path(name).name in dependencies):
            need(Path(name).read_bytes() == body, 'whole explicit current command dependency')
    need(type(row['stdout']) is str and type(row['stderr']) is str
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged complete native guard terminal')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended native gate output')
    return row


def contracts():
    original = nodes(intake.git('show', PLAN['revision'] + ':' + TASK))
    active = nodes(intake.overlays()[TASK])
    need(original.keys() == active.keys(), 'whole activation task population')
    for name, block in original.items():
        if name == PLAN['owner']:
            need(field(block, 'Status') == 'pending' and field(active[name], 'Status') == 'active'
                 and active[name] == block.replace(b'  Status: `pending`', b'  Status: `active`', 1), 'only unchanged cause association activates')
        else:
            need(block == active[name], 'every other whole task contract conserves')
    need(field(active[PLAN['parent']], 'Status') == 'active'
         and field(active[PLAN['parent'] + '.1'], 'Status') == 'done'
         and field(active[PLAN['parent'] + '.3'], 'Status') == 'pending', 'complete prerequisite/canonical parent state')
    return {name: {key: field(active[name], key) for key in ('Goal', 'Acceptance', 'Status', 'Children')}
            for name in (PLAN['parent'], *(PLAN['parent'] + '.' + str(i) for i in (1, 2, 3)))}


def qualify_controls(candidate):
    terminal = read('controls.json')
    cases = controls.cases(candidate)
    specifications = [('candidate', None, None), *cases]
    need(terminal['owner'] == PLAN['owner'] and set(terminal['actuals']) == {name for name, _, _ in specifications},
         'complete positive and separating control population')
    receipts = {}
    for label, mutate, cause in specifications:
        expected = copy.deepcopy(candidate)
        if mutate:
            mutate(expected)
        path = BASE / (label + '.json.gz')
        need(same(product(path), expected), 'whole intended changed candidate and conserved prior products')
        actual, started = read('control-' + label + '-actual.json'), read('control-' + label + '-started.json')
        need(set(started) == {'command', 'expected_status', 'intended_cause', 'candidate', 'programmes'}
             and set(actual) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
             and all(same(actual[key], value) for key, value in started.items()), 'complete direct native control terminal')
        status = int(mutate is not None)
        need(type(actual['status']) is int and type(actual['expected_status']) is int
             and actual['status'] == actual['expected_status'] == status and actual['intended_cause'] == cause
             and actual['command'] == ['python3', '-B', str(BASE / 'reader.py'), '--candidate', str(path)]
             and actual['candidate'] == dict(path=str(path), identity=pin(path.read_bytes()))
             and same(actual['programmes'], actual['programmes_after']), 'whole intended typed native refusal or positive success')
        for name, entry in actual['programmes'].items():
            need(entry == dict(body=Path(name).read_text(), identity=pin(Path(name).read_bytes())), 'whole control command and dependency source epoch')
        need((actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n')) if mutate
             else actual['stdout'] == reader.SUCCESS and actual['stderr'] == '', 'exact first native control refusal or positive output')
        identity = pin(canonical(actual))
        need(identity == terminal['actuals'][label], 'whole retained native separating outcome custody')
        receipts[label] = identity
    return dict(receipts=receipts, condition=terminal['condition'])


def core(*, current=False):
    prior = read('preparation-normal-commit.json')
    need(set(prior) == {'command', 'status', 'stdout', 'stderr'} and type(prior['status']) is int and prior['status'] == 0
         and prior['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and PLAN['revision'][:9] in prior['stdout'].splitlines()[0]
         and '[doctrine] all doctrine checks passed' in prior['stdout'] + prior['stderr'], 'whole normal preparation commit and hooks')
    source = intake.derive()
    need(same(source, read('source-roles.json')) and same(read('source-before.json'), read('source-after.json')),
         'whole fixed original/current graph and unchanged live source epoch')
    before = read('source-before.json')
    need(before['source'] == pin(canonical(source['publication']))
         and before['overlays'] == {name: pin(body) for name, body in intake.overlays().items()}, 'whole source census role and activation overlays')
    for epoch in ('before', 'after'):
        gate('source-' + epoch, ['python3', '-B', str(BASE / 'intake.py'), '--' + epoch], intake.SUCCESS, current=current)
    gate('producer', ['python3', '-B', str(BASE / 'produce.py')],
         'Built complete proposed original primary/raw cause association; independent qualification remains required.\n', current=current)
    gate('independent', ['python3', '-B', str(BASE / 'reader.py'), '--save'], reader.SUCCESS, current=current)
    gate('controls', ['python3', '-B', str(BASE / 'controls.py')],
         'PASS complete positive and genuine prior-preserving primary/raw association controls.\n', current=current)
    prerequisite = gate('prerequisite', ['python3', '-B', PLAN['preparation'] + '/verify.py'],
         'PASS complete source-bound primary/raw/coordinate/address cause prerequisites; independent cause association remains next.\n', current=current)
    history = gate('root-history', ['git', 'log', '-1', '-S',
        'Independently join every original primary and complete raw cause identity.', '--format=%H %s', '--', 'docs/tasks/'], current=current)
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', history['stdout']), 'complete owned association obligation history locus')
    candidate = product(BASE / 'candidate.json.gz')
    association = reader.check(candidate)
    need(same(association, read('association.json')), 'whole independently reconstructed native association qualification')
    qualified = qualify_controls(candidate)
    draft = read('guide-draft.json')
    need(draft['owner'] == PLAN['owner'] and type(draft['first']['native_status']) is int and draft['first']['native_status'] == 1
         and draft['first']['bytes'] == len((BASE / 'guide-first-draft.txt').read_bytes()) > draft['limit_bytes']
         and type(draft['second']['native_status']) is int and draft['second']['native_status'] == 1
         and draft['second']['bytes'] == len((BASE / 'guide-second-draft.txt').read_bytes()) > draft['limit_bytes']
         and draft['final']['bytes'] == len((BASE / 'guide.txt').read_bytes()) <= draft['limit_bytes'], 'retained over-budget preview and contained final guide')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], source=pin(canonical(source)), prior_commit=pin(canonical(prior)),
        contracts=contracts(), association=association, controls=qualified, prerequisite=pin(canonical(prerequisite)), guide_preview=draft,
        legs=dict(rederive='Complete fixed source/native/product graph, finite source/context/first-cause/acceptance models and whole own empty/raw/class/frame/coordinate/address/nested association.',
                  falsify='Every complete positive and genuine wrong/borrowed/omitted/order/Boolean/native-boundary candidate executes the independent native reader; all original underlying qualified products conserve.',
                  durability='Complete fixed Git sources, matching live source epochs, native programmes/commands/streams, whole positive/hostile products and actual typed outcomes, saved reader and normal commit hooks.'),
        condition=PLAN['condition'], programme_roles='Complete enumerated auxiliary own programmes retain their actual dated bodies; only each command and its declared imports carry current-source authority. The exploratory schema receipt retains its first capture programme separately.')


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        need(not path.is_symlink() and stat.S_ISREG(path.lstat().st_mode)
             and path.stat().st_dev == Path.cwd().stat().st_dev, 'whole ordinary same-volume flat association archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(path.stat().st_mode & 0o111))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one explicit complete association proof role')
    result = core(current=args.current or args.seal)
    if args.core:
        print('PASS complete independent primary/raw cause association core; delivery remains separate.')
    else:
        import publish
        result['publication'] = publish.qualify(current=args.current or args.seal)
        result['external'] = {name: pin(canonical(gate(name, command, current=args.current or args.seal))) for name, command in publish.COMMANDS.items()}
        need('All tests successful' in read('focused-actual.json')['stdout'], 'actual focused regression success')
        need(json.loads(canonical(result)) == result, 'whole proof uses lossless JSON-native containers and values')
        if args.seal:
            save('proof.json', result)
            save('manifest.json', catalogue())
        else:
            need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()), 'whole immutable saved association proof')
        print(SUCCESS, end='')
