"""Whole fixed-source prospective canonical custody and saved recovery qualification."""
import argparse
import stat

from canonical_common import *
import controls
import intake
import reader

SUCCESS = 'PASS complete non-growing source-bound cause canonical preparation; live publication and cause-parent acceptance remain open.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


def gate(label, command, stdout=None, *, current=False):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'}
         and all(same(row[key], value) for key, value in started.items()), 'closed complete native preparation terminal')
    need(type(row['status']) is int and row['status'] == 0 and type(row['expected_status']) is int and row['expected_status'] == 0,
         'actual typed positive preparation success')
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and same(row['programmes'], row['programmes_after']), 'whole actual preparation command and programme epoch')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'complete native programme and input body')
        if current:
            need(Path(name).read_bytes() == body, 'whole explicit current preparation programme or input')
    need(type(row['stdout']) is str and type(row['stderr']) is str
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged complete native guard terminal')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended native preparation output')
    return row


def contracts():
    original = nodes(git('show', PLAN['revision'] + ':' + TASK))
    active = nodes(intake.overlays()[TASK])
    parent = PLAN['parent']
    additions = {parent + '.' + str(i) for i in (1, 2, 3)}
    need(set(active) == set(original) | additions and not additions.intersection(original), 'only explicit safe canonical child decomposition')
    for name, block in original.items():
        if name == parent:
            need(all(field(active[name], key) == field(block, key) for key in ('Goal', 'Acceptance', 'Verification', 'Commit'))
                 and field(block, 'Status') == 'pending' and field(active[name], 'Status') == 'active'
                 and field(active[name], 'Children') == ', '.join(parent + '.' + str(i) for i in (1, 2, 3)),
                 'unchanged full original canonical obligation with only safe children')
        else:
            need(block == active[name], 'every original whole cause primary raw and descendant task contract retains')
    need(field(active[PLAN['cause']], 'Status') == 'active'
         and all(field(active[PLAN['cause'] + '.' + str(i)], 'Status') == 'done' for i in (1, 2))
         and field(active[PLAN['owner']], 'Status') == 'active'
         and all(field(active[parent + '.' + str(i)], 'Status') == 'pending' for i in (2, 3)), 'exact committed cause prerequisites and open successors')
    return dict(original_task=pin(git('show', PLAN['revision'] + ':' + TASK)),
        cause={key: field(active[PLAN['cause']], key) for key in ('Goal', 'Acceptance', 'Children')},
        canonical={key: field(active[parent], key) for key in ('Goal', 'Acceptance', 'Children')},
        children={name: {key: field(active[name], key) for key in ('Goal', 'Acceptance', 'Status')} for name in sorted(additions)})


def core(*, current=False):
    commit = read('association-normal-commit.json')
    need(set(commit) == {'command', 'status', 'stdout', 'stderr'} and type(commit['status']) is int and commit['status'] == 0
         and commit['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and PLAN['revision'][:9] in commit['stdout'].splitlines()[0]
         and '[doctrine] all doctrine checks passed' in commit['stdout'] + commit['stderr'], 'whole previous normal cause association commit and hooks')
    source = intake.derive()
    need(same(source, read('source-roles.json')) and same(read('source-before.json'), read('source-after.json')),
         'whole original and current canonical cause source graph and conserved live epoch')
    census = read('source-before.json')
    need(census['source'] == pin(canonical(source['publication']))
         and census['overlays'] == {name: pin(body) for name, body in intake.overlays().items()}, 'complete source census and exact activation overlays')
    for epoch in ('before', 'after'):
        gate('source-' + epoch, ['python3', '-B', str(BASE / 'intake.py'), '--' + epoch], intake.SUCCESS, current=current)
    gate('prepare', ['python3', '-B', str(BASE / 'prepare.py')],
         'Prepared complete non-growing cause canonical candidate; live canonical production remains unchanged.\n', current=current)
    gate('independent', ['python3', '-B', str(BASE / 'reader.py')], reader.SUCCESS, current=current)
    gate('controls', ['python3', '-B', str(BASE / 'controls.py')],
         'PASS complete genuine prior-preserving canonical proposal controls; original native and private limits retain.\n', current=current)
    association = gate('association', ['python3', '-B', PLAN['association'] + '/verify.py'],
         'PASS complete finite independent primary/raw cause association; canonical and cause-parent acceptance remain open.\n', current=current)
    history = gate('root-history', ['git', 'log', '-1', '-S', 'Publish and close complete unchanged primary/raw cause acceptance.',
        '--format=%H %s', '--', 'docs/tasks/'], current=current)
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', history['stdout']), 'whole original canonical cause obligation history locus')
    candidate = read('candidate.json')
    inputs = reader.context()
    qualification = reader.check(candidate, inputs)
    need(same(qualification, read('qualification.json')), 'whole independently reconstructed canonical source meaning qualification')
    falsification = controls.qualify(candidate, inputs)
    need(same(falsification, load_product('controls.json.gz')), 'every complete separating product and intended actual ValueError refusal retains')
    draft = read('guide-draft.json')
    need(draft['owner'] == PLAN['owner'] and type(draft['first']['native_status']) is int and draft['first']['native_status'] == 1
         and draft['first']['bytes'] == len((BASE / 'guide-first-draft.txt').read_bytes())
         and draft['first']['resulting_chapter'] > draft['chapter_bound'] == 292485
         and draft['final']['bytes'] == len((BASE / 'guide.txt').read_bytes())
         and draft['final']['resulting_chapter'] <= draft['chapter_bound'], 'complete refused preview and admitted unchanged book authority')
    capacity = read('capacity-frontier.json')
    need(capacity['owner'] == PLAN['owner'] and capacity['scheduled_owner'] == PLAN['parent'] + '.2'
         and capacity['planned_chapter_bytes'] == draft['final']['resulting_chapter'] == capacity['chapter_bound'] == 292485,
         'exact bounded next-publication compaction ownership')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], source=pin(canonical(source)), normal_commit=pin(canonical(commit)),
        contracts=contracts(), qualification=qualification, association=pin(canonical(association)),
        controls=dict(product=pin(canonical(falsification)), role=falsification['role'],
                      refusals=[dict(name=row['name'], exception=row['exception'], cause=row['cause']) for row in falsification['controls']]),
        guide_preview=draft, capacity_frontier=capacity,
        legs=dict(rederive='Complete fixed original/current cause and canonical sources, unchanged full contracts, independently reconstructed exact whole meanings, complete direct/cached question allocation and every physical capacity metric.',
                  falsify='Genuine whole omitted/borrowed/Boolean/native-boundary proposals produce their intended ValueError refusals inside the native guarded qualifier; all original underlying products and scope limits conserve.',
                  durability='Complete canonical beforeimages, prospective product, ordered review, original source/native/cause/failure custody and normal prior commit, matching live source epochs and a saved reader requiring no ignored checkpoint.'),
        condition=PLAN['condition'])


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        need(not path.is_symlink() and stat.S_ISREG(path.lstat().st_mode)
             and path.stat().st_dev == Path.cwd().stat().st_dev, 'whole ordinary same-volume flat canonical preparation archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(path.stat().st_mode & 0o111))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one explicit complete canonical preparation role')
    result = core(current=args.current or args.seal)
    if args.core:
        print('PASS complete source-bound canonical cause preparation core; live production remains unchanged.')
    else:
        import publish
        result['publication'] = publish.qualify(current=args.current or args.seal)
        result['external'] = {name: pin(canonical(gate(name, command, current=args.current or args.seal))) for name, command in publish.COMMANDS.items()}
        need('All tests successful' in read('focused-actual.json')['stdout'], 'actual focused canonical preparation regression success')
        need(json.loads(canonical(result)) == result, 'complete lossless JSON-native preparation proof')
        if args.seal:
            save('proof.json', result)
            save('manifest.json', catalogue())
        else:
            need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()), 'whole immutable saved canonical cause preparation')
        print(SUCCESS, end='')
