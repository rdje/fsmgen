"""Join unchanged complete raw acceptance with explicit original/current roles."""
import argparse
import copy
import gzip
import json
from pathlib import Path
import re
import stat

from capture import BASE, canonical, pin, save
import controls
import intake

PLAN = intake.PLAN
TASK = intake.TASK
RAW = PLAN['raw']
CLOSE = (RAW, RAW + '.5', RAW + '.5.3', PLAN['owner'])
SUCCESS = 'PASS complete finite original raw acceptance; original source/native/private boundaries and higher owners retain.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix
    for label in ('seal', 'default', 'staged-doctrines') for suffix in ('-started.json', '-actual.json')}


def need(value, cause):
    if not value:
        raise ValueError(cause)


def read(name):
    return json.loads((BASE / name).read_bytes())


def nodes(body):
    starts = list(re.finditer(rb'^- ID: `([^`]+)`\n', body, re.M))
    result = {row[1].decode(): body[row.start():starts[i + 1].start() if i + 1 < len(starts) else len(body)]
              for i, row in enumerate(starts)}
    need(len(result) == len(starts), 'unique complete raw task nodes')
    return result


def field(block, name):
    match = re.search(rb'^  ' + name.encode() + rb': `(.*)`$', block, re.M)
    return match[1].decode() if match else None


def contracts():
    original = nodes(intake.git('show', PLAN['original_revision'] + ':' + TASK))
    fixed = nodes(intake.git('show', PLAN['revision'] + ':' + TASK))
    activation = nodes(intake.overlays(after=True)[TASK])
    old = {name: {key: field(block, key) for key in ('Goal', 'Acceptance', 'Children')}
           for name, block in original.items() if name == RAW or name.startswith(RAW + '.')}
    current = {name: {key: field(block, key) for key in ('Goal', 'Acceptance', 'Children')}
               for name, block in fixed.items() if name == RAW or name.startswith(RAW + '.')}
    need(set(current) == set(old) | {RAW + '.5.3.' + str(i) for i in (1, 2, 3)},
         'only declared canonical children supplement original full raw forest')
    for name, record in current.items():
        need(all(field(activation[name], key) == value for key, value in record.items()),
             'every current raw goal acceptance and child contract conserves')
        if name in old:
            for key, value in old[name].items():
                if name == RAW + '.5.3' and key == 'Children':
                    need(record[key] == ', '.join(RAW + '.5.3.' + str(i) for i in (1, 2, 3)),
                         'exact safe canonical decomposition preserves original full parent goal')
                else:
                    need(record[key] == value, 'every unchanged original full raw/container/descendant obligation')
        if name not in CLOSE:
            need(field(fixed[name], 'Status') == field(activation[name], 'Status') == 'done'
                 and field(fixed[name], 'Commit') not in (None, 'pending'), 'every complete raw descendant is committed')
        else:
            need(field(activation[name], 'Status') == 'active', 'exact remaining complete raw closure frontier')
    return dict(original_revision=PLAN['original_revision'], publication_revision=PLAN['revision'],
                original=old, current=current, condition=PLAN['condition'])


def gate(label, command, stdout=None, *, status=0, declared_status=None, current=False):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(all(row[key] == value for key, value in started.items()), 'whole native started declaration')
    if declared_status is None:
        declared_status = status
    need(type(row['status']) is int and row['status'] == status
         and type(row['expected_status']) is int and row['expected_status'] == declared_status,
         'actual typed declared raw acceptance native outcome')
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and row['programmes'] == row['programmes_after'], 'whole native command and conserved programme epoch')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole dated native programme/input identity')
        if current:
            old = {('gate-source-before', str(BASE / 'intake.py')): 'intake-first.py.txt',
                   ('gate-prior', str(BASE / 'prior.py')): 'prior-first.py.txt'}.get((label, name))
            expected = (BASE / old).read_bytes() if old else Path(name).read_bytes()
            need(body == expected, 'explicit current or first dated native programme role')
    need(re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged completed raw acceptance guard')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended raw acceptance terminal')
    return row


def semantic(source):
    result = read('controls-result.json')
    cases = controls.cases()
    need(result['cases'] == cases and set(result['outcomes']) == {row['name'] for row in cases},
         'complete original positive hostile and typed candidate population')
    members = source['publication']['members']
    for name, entry in result['programmes'].items():
        body = entry['body'].encode()
        need(pin(body) == entry['identity'] == {key: members[name][key] for key in ('bytes', 'sha256')},
             'whole unchanged original semantic/native programme source')
    need(set(result['programmes']) == set(controls.programmes()), 'complete independent reader programme allocation')
    terminals = {}
    for case in cases:
        path = str(controls.PRIOR / case['member'])
        candidate = {key: members[path][key] for key in ('bytes', 'sha256')}
        terminals[case['name']] = {}
        for role, command in (
            ('native', ['perl', str(controls.PRIOR / 'native.pl'), path]),
            ('semantic', ['python3', '-B', str(controls.PRIOR / 'reader.py'), path])):
            row = read('case-' + case['name'] + '-' + role + '.json')
            need(pin(canonical(row)) == result['outcomes'][case['name']][role]
                 and row['command'] == command and row['programmes'] == row['programmes_after'] == result['programmes']
                 and row['candidate'] == row['candidate_after'] == candidate and type(row['status']) is int,
                 'whole actual unchanged full candidate/source/native custody')
            if role == 'native':
                need(row['status'] == 0 and row['stdout'] == controls.NATIVE and row['stderr'] == '',
                     'actual complete inherited raw body conservation')
            elif case['cause'] is None:
                need(row['status'] == 0 and row['stdout'] == controls.SEMANTIC and row['stderr'] == '',
                     'actual complete source-first semantic reconstruction')
            else:
                need(row['status'] == 1 and row['stdout'] == ''
                     and row['stderr'].endswith('ValueError: ' + case['cause'] + '\n'),
                     'actual intended prior-preserving full semantic refusal')
            terminals[case['name']][role] = pin(canonical(row))
    return terminals


def join(candidate, expected):
    need(candidate['source'] == expected['source'], 'complete original/current source and native custody join')
    need(candidate['contracts'] == expected['contracts'], 'every complete unchanged raw/container/descendant obligation')
    intake.fact.check_checkpoint(candidate['checkpoint'], expected['admitted']['source'])
    need(candidate['checkpoint'] == expected['checkpoint'] and candidate['admitted'] == expected['admitted'],
         'whole admitted original checkpoint and e428/later source conditions')
    need(type(candidate['canonical']['status']) is int and candidate['canonical']['status'] == 0,
         'actual successful current canonical native role')
    need(candidate['canonical'] == expected['canonical'] and candidate['prior'] == expected['prior']
         and candidate['semantic'] == expected['semantic'] and candidate['unknowns'] == expected['unknowns'],
         'whole original prerequisite semantic canonical and uncertainty joins')


def core(*, current=False):
    source = intake.derive()
    need(source == read('source-roles.json'), 'whole fixed original/publication source rederivation')
    before, after = read('source-before.json'), read('source-after.json')
    expected = dict(before, overlays={name: pin(body) for name, body in intake.overlays(after=True).items()})
    need(before['source'] == after['source'] == pin(canonical(source['publication'])) and after == expected,
         'whole before/after source membership and exact owned finding boundary')
    for role in ('before', 'after'):
        gate('gate-source-' + role, ['python3', '-B', str(BASE / 'intake.py'), '--' + role], intake.SUCCESS, current=current)
    admitted = intake.fact.authenticate()
    checkpoint = json.loads((intake.fact.PREPARATION / 'parent-checkpoint-v3-actual.json').read_bytes())
    canonical_gate = gate('gate-canonical-before', ['python3', '-B', PLAN['publication'] + '/verify.py', '--core'],
        'PASS complete finite raw admission and current canonical core; delivery remains separate.\n', current=current)
    gate('gate-controls', ['python3', '-B', str(BASE / 'controls.py')], controls.SUCCESS, current=current)
    prior = read('prior-result.json')
    need(prior['revision'] == 'e42845fc43a61b2da76d5ad3fb5b4158c80765ff', 'original prerequisite source role retains')
    original_readers = json.loads(Path('docs/audits/raw-stack-prerequisites-20261011/readers.json').read_bytes())
    need(prior['readers'] == original_readers['readers'], 'every complete original prerequisite receipt role rederives')
    gate('gate-prior-corrected', ['python3', '-B', str(BASE / 'prior.py')],
        'PASS complete original prerequisite reader and predecessor contract roles; original source epochs retain.\n', current=current)
    failed = gate('gate-prior', ['python3', '-B', str(BASE / 'prior.py')], status=1, declared_status=0, current=current)
    need(failed['stdout'] == '' and "ImportError: cannot import name 'TASK' from 'common'" in failed['stderr'],
         'complete first metadata harness import refusal retains without original execution')
    finding = read('post-source-finding.json')
    previous = intake.overlays(after=True)[TASK]
    updated = gzip.decompress((BASE / finding['after']).read_bytes())
    start = previous.index(('- ID: `' + PLAN['owner'] + '`\n').encode())
    end = previous.index(b'\n- ID:', start + 1)
    need(finding['owner'] == PLAN['owner'] and finding['before'] == 'source-finding-task.md.gz'
         and finding['after'] == 'post-source-task.md.gz'
         and updated == previous[:end].rstrip() + b'\n' + finding['finding'].encode() + previous[end:],
         'exact metadata-only finding after completed original source epoch')
    first_core = read('gate-core-actual.json')
    need(type(first_core['status']) is int and first_core['status'] == 1
         and type(first_core['expected_status']) is int and first_core['expected_status'] == 0
         and first_core['programmes'][str(BASE / 'verify.py')]['body'].encode() == (BASE / 'verify-first.py.txt').read_bytes()
         and first_core['stderr'].endswith('ValueError: actual typed intended raw acceptance native terminal\n'),
         'whole original unexpected final qualifier outcome remains non-success')
    history = gate('root-history', ['git', 'log', '-1', '-S',
        'Qualify complete original raw stacks, source coordinates and address lifetimes.', '--format=%H %s', '--', 'docs/tasks/'], current=current)
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', history['stdout']), 'original full raw obligation history locus')
    prepared = json.loads((intake.fact.PREPARATION / 'proof.json').read_bytes())
    obligations = contracts()
    need(prepared['contracts']['nodes'] == obligations['original'], 'every original prepared raw obligation retains whole')
    product = json.loads(gzip.decompress(Path(PLAN['semantic'] + '/candidate.json.gz').read_bytes()))
    unknowns = dict(original=product['semantic_links']['original_unknowns'], inherited=product['semantic_links']['inherited_scopes'],
                    preparation=prepared['prerequisite'], condition=PLAN['condition'])
    candidate = dict(source=source, contracts=obligations, admitted=admitted, checkpoint=checkpoint,
                     canonical=canonical_gate, prior=prior, semantic=semantic(source), unknowns=unknowns)
    join(candidate, candidate)
    counterexamples = []
    for name, mutate, cause in (
        ('omitted complete source', lambda row: row['source']['publication']['members'].pop(next(iter(row['source']['publication']['members']))),
         'complete original/current source and native custody join'),
        ('omitted original raw obligation', lambda row: row['contracts']['original'].pop(RAW),
         'every complete unchanged raw/container/descendant obligation'),
        ('Boolean original checkpoint', lambda row: row['checkpoint'].update(status=False), 'actual admitted raw checkpoint integer success'),
        ('Boolean current canonical', lambda row: row['canonical'].update(status=False), 'actual successful current canonical native role'),
        ('native/private boundary promotion', lambda row: row['unknowns'].update(condition='native identities measured'),
         'whole original prerequisite semantic canonical and uncertainty joins')):
        changed = copy.deepcopy(candidate)
        mutate(changed)
        try:
            join(changed, candidate)
        except ValueError as error:
            need(str(error) == cause, 'intended complete raw acceptance intervention refusal')
            counterexamples.append(dict(name=name, cause=str(error)))
        else:
            raise ValueError('changed complete raw acceptance accepted')
    return dict(owner=PLAN['owner'], contracts=obligations, source=pin(canonical(source)),
        admitted=admitted, checkpoint=pin(canonical(checkpoint)), canonical=pin(canonical(canonical_gate)),
        prior=pin(canonical(prior)), semantic=candidate['semantic'], unknowns=unknowns, controls=counterexamples,
        first_failure=pin(canonical(failed)), condition=PLAN['condition'], legs=dict(
            rederive='Complete original/publication Git source graphs, unchanged original raw/descendant contracts and prerequisite roles; actual fresh full-body source-first/native-positive/hostile readers and current canonical gate.',
            falsify='Every original semantic/typed counterexample preserves inherited body meanings before its intended refusal; complete source/obligation/original and current typed-status/native-boundary join interventions reject.',
            durability='Complete fixed Git source/native/candidate bodies, explicit e428 and later checkpoint roles, all first failures and unknowns, complete native streams and saved ignored-view-independent proof. No original native/private recapture or later historical-programme currency.'))


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        need(not path.is_symlink() and stat.S_ISREG(path.lstat().st_mode)
             and path.stat().st_dev == Path.cwd().stat().st_dev, 'complete ordinary flat raw acceptance archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(path.stat().st_mode & 0o111))
    return result


def publication_population():
    row = read('publication.json')
    tracked = intake.git('ls-tree', '-r', '--name-only', PLAN['revision']).decode().splitlines()
    expected = dict(
        task_names=sorted(name for name in tracked if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name)),
        book_names=sorted(name for name in tracked if re.fullmatch(r'docs/book/src/[^/]+\.md', name)))
    def qualify(candidate):
        need(all(candidate[key] == value for key, value in expected.items()),
             'complete fixed-revision publication task/book source population')
    qualify(row)
    controls = []
    for key in expected:
        changed = copy.deepcopy(row)
        changed[key].pop()
        try:
            qualify(changed)
        except ValueError as error:
            need(str(error) == 'complete fixed-revision publication task/book source population',
                 'intended publication source omission refusal')
            controls.append(dict(name='omitted ' + key, cause=str(error)))
        else:
            raise ValueError('narrowed publication source population accepted')
    return dict(population=expected, controls=controls)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one explicit raw acceptance qualification role')
    result = core(current=args.current or args.seal)
    if args.core:
        print('PASS complete unchanged finite raw obligation/source/native/canonical core; delivery remains separate.')
        return
    # Publication and external gates are added after the complete core qualifies.
    import publish
    result['population'] = publication_population()
    result['publication'] = publish.qualify(current=args.current or args.seal)
    commands = publish.COMMANDS
    result['external'] = {name: pin(canonical(gate(name, command, current=args.current or args.seal)))
                          for name, command in commands.items()}
    need('All tests successful' in read('focused-actual.json')['stdout'], 'actual complete focused regression success')
    if args.seal:
        save('proof.json', result)
        save('manifest.json', catalogue())
    else:
        need(read('proof.json') == result and read('manifest.json') == catalogue(), 'complete immutable saved raw acceptance proof')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
