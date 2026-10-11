"""Qualify finite cause prerequisites; saved evidence never implies later currency."""
import argparse
import copy
import gzip
import json
from pathlib import Path
import re
import stat

from capture import BASE, canonical, pin, save
import intake
import prerequisites

PLAN = intake.PLAN
TASK = intake.TASK
PRIMARY = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.1'
SUCCESS = 'PASS complete source-bound primary/raw/coordinate/address cause prerequisites; independent cause association remains next.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix for label in ('seal-corrected', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def need(value, cause):
    if not value:
        raise ValueError(cause)


def read(name):
    return json.loads((BASE / name).read_bytes())


def nodes(body):
    starts = list(re.finditer(rb'^- ID: `([^`]+)`\n', body, re.M))
    result = {row[1].decode(): body[row.start():starts[i + 1].start() if i + 1 < len(starts) else len(body)]
              for i, row in enumerate(starts)}
    need(len(result) == len(starts), 'unique whole cause task graph')
    return result


def field(block, name):
    match = re.search(rb'^  ' + name.encode() + rb': `(.*)`$', block, re.M)
    return match[1].decode() if match else None


def contracts():
    original = nodes(intake.git('show', PLAN['revision'] + ':' + TASK))
    activation = nodes(intake.overlays()[TASK])
    prefixes = (PRIMARY, PLAN['raw'])
    selected = {name: block for name, block in original.items()
                if any(name == prefix or name.startswith(prefix + '.') for prefix in prefixes)}
    need(PRIMARY in selected and PLAN['raw'] in selected, 'whole primary and raw descendant roots')
    for name, block in selected.items():
        need(activation[name] == block and field(block, 'Status') == 'done'
             and field(block, 'Commit') not in (None, 'pending'), 'every whole committed prerequisite contract retains')
    parent = PLAN['parent']
    obligation = {key: field(original[parent], key) for key in ('Goal', 'Acceptance')}
    need(all(field(activation[parent], key) == value for key, value in obligation.items()),
         'whole original cause Goal and Acceptance unchanged')
    need(field(original[parent], 'Status') == 'pending' and field(activation[parent], 'Status') == 'active',
         'original open cause owner activates without closure')
    need(field(activation[parent], 'Children') == ', '.join(parent + '.' + str(i) for i in (1, 2, 3)),
         'exact safe source association and final decomposition')
    children = {parent + '.' + str(i): {key: field(activation[parent + '.' + str(i)], key)
                for key in ('Goal', 'Acceptance')} for i in (1, 2, 3)}
    need(field(activation[PLAN['owner']], 'Status') == 'active'
         and all(field(activation[parent + '.' + str(i)], 'Status') == 'pending' for i in (2, 3)),
         'only prerequisite preparation active')
    return dict(revision=PLAN['revision'], prerequisites={name: block.decode() for name, block in selected.items()},
                parent=obligation, children=children)


def gate(label, command, stdout=None, *, current=False):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(set(started) == {'command', 'programmes', 'expected_status', 'stdout_path', 'stderr_path', 'condition'}
         and set(row) == set(started) | {'status', 'stdout', 'stderr', 'programmes_after'},
         'closed whole native terminal and declaration')
    need(all(row[key] == value for key, value in started.items()), 'whole actual started declaration')
    need(type(row['status']) is int and row['status'] == 0
         and type(row['expected_status']) is int and row['expected_status'] == 0, 'actual typed native success')
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and row['programmes'] == row['programmes_after'], 'whole exact native command and programme epoch')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'], 'whole actual native programme/input bytes')
        if current:
            expected = ((BASE / 'prerequisites-first-import.py.txt').read_bytes()
                        if label == 'gate-prerequisites' and name == str(BASE / 'prerequisites.py')
                        else Path(name).read_bytes())
            need(expected == body, 'whole explicit current or declared first runner programme/input role')
    need(type(row['stdout']) is str and type(row['stderr']) is str
         and re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'complete unchanged native guard terminal')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended native output')
    return row


def join(candidate, expected):
    def same(key):
        return canonical(candidate[key]) == canonical(expected[key])

    need(same('source'), 'complete original/current source role join')
    need(same('contracts'), 'whole original prerequisite and cause obligation join')
    need(all(type(candidate[key]['status']) is int and candidate[key]['status'] == 0
             for key in ('primary', 'epoch_primary')), 'typed complete primary success')
    need(all(same(key) for key in ('primary', 'epoch_primary', 'raw')),
         'whole exact actual primary and raw reader custody')
    need(same('prerequisites'), 'complete coordinate/address native association')
    need(same('unknowns'), 'whole source-native uncertainty boundary')


def core(*, current=False):
    prior_commit = read('raw-normal-commit.json')
    need(set(prior_commit) == {'command', 'status', 'stdout', 'stderr'}
         and type(prior_commit['status']) is int and prior_commit['status'] == 0
         and prior_commit['command'] == ['git', '--no-pager', 'commit', '-F', 'git_message_brief.txt']
         and PLAN['revision'][:9] in prior_commit['stdout'].splitlines()[0]
         and '[doctrine] all doctrine checks passed' in prior_commit['stdout'] + prior_commit['stderr']
         and intake.git('rev-parse', PLAN['revision'] + '^{commit}').decode().strip() == PLAN['revision'],
         'complete original normal raw commit and hooks receipt')
    source = intake.derive()
    need(source == read('source-roles.json'), 'whole fixed original and clean publication source graph')
    before, after = read('source-before.json'), read('source-after.json')
    need(before == after and before['source'] == pin(canonical(source['publication']))
         and before['overlays'] == {name: pin(body) for name, body in intake.overlays().items()},
         'whole unchanged source census epoch around fresh primary, coordinate/address and raw readers')
    for role in ('before', 'after'):
        gate('gate-source-' + role, ['python3', '-B', str(BASE / 'intake.py'), '--' + role], intake.SUCCESS, current=current)
    primary = gate('gate-primary', ['python3', '-B', PLAN['primary'] + '/verify.py'], current=current)
    original_specs = json.loads(Path(PLAN['prerequisite'] + '/readers.json').read_bytes())['readers']
    original_primary = json.loads(Path(original_specs['primary']['receipt']).read_bytes())
    need(type(original_primary['status']) is int and original_primary['status'] == 0
         and primary['stdout'] == original_primary['stdout']
         and primary['stdout'].endswith(original_specs['primary']['specification']['stdout'])
         and primary['stderr'].count('\n') == 1, 'whole original primary stdout and source role')
    epoch_primary = gate('gate-primary-epoch', ['python3', '-B', PLAN['primary'] + '/verify.py'], current=current)
    need(epoch_primary['stdout'] == primary['stdout'] and epoch_primary['stderr'].count('\n') == 1
         and epoch_primary['programmes'][PLAN['primary'] + '/verify.py'] == primary['programmes'][PLAN['primary'] + '/verify.py'],
         'whole fresh primary result and original programme inside the complete source census epoch')
    primary_path = PLAN['primary'] + '/verify.py'
    need(primary['programmes'][primary_path]['identity'] ==
         {key: source['publication']['members'][primary_path][key] for key in ('bytes', 'sha256')},
         'whole primary original source epoch')
    raw = gate('gate-raw', ['python3', '-B', PLAN['raw_acceptance'] + '/verify.py'],
        'PASS complete finite original raw acceptance; original source/native/private boundaries and higher owners retain.\n', current=current)
    gate('gate-prerequisites', ['python3', '-B', str(BASE / 'prerequisites.py')], current=current)
    terminal = read('prerequisites-result.json')
    specs = prerequisites.selected()
    need(set(terminal['readers']) == set(specs), 'whole coordinate/address reader population')
    actuals = {}
    for name, spec in specs.items():
        actual = read(name + '-actual.json')
        need(set(actual) == {'specification', 'command', 'programme', 'status', 'stdout', 'stderr', 'programme_after'}
             and set(actual['programme']) == {'body', 'identity'}, 'closed complete prerequisite actual and programme')
        prerequisites.qualify(actual, spec)
        need(pin(canonical(actual)) == terminal['readers'][name], 'whole exact prerequisite native receipt')
        path = spec['command'][2]
        need(actual['programme']['identity'] == {key: source['publication']['members'][path][key]
             for key in ('bytes', 'sha256')}, 'whole complete original reader source allocation')
        actuals[name] = actual
    history = gate('root-history', ['git', 'log', '-1', '-S',
        'Join complete original primary and raw native cause semantics.', '--format=%H %s', '--', 'docs/tasks/'], current=current)
    need(re.fullmatch(r'[0-9a-f]{40} .+\n', history['stdout']), 'whole original cause obligation history locus')
    progress = read('progress-observation.json')
    progress_path = 'docs/audits/coordinate-original-hostile-checks-20261009/progress.json'
    progress_source = 'docs/audits/coordinate-original-hostile-20261009/verify.py'
    need(progress['owner'] == PLAN['owner'] and progress['progress_path'] == progress_path
         and progress['programme']['path'] == progress_source
         and progress['programme']['identity'] == {key: source['publication']['members'][progress_source][key]
              for key in ('bytes', 'sha256')}, 'whole original progress writer source role')
    original_progress = intake.git('show', PLAN['revision'] + ':' + progress_path)
    need(progress['original'] == dict(body=original_progress.decode(), identity=pin(original_progress))
         and pin(original_progress) == {key: source['publication']['members'][progress_path][key]
              for key in ('bytes', 'sha256')}, 'whole original terminal progress and conserved endpoint')
    observed_progress = progress['observed']['body'].encode()
    need(pin(observed_progress) == progress['observed']['identity']
         and json.loads(observed_progress)['stage'] == 'independent-controls'
         and json.loads(original_progress)['stage'] == 'independent-complete',
         'complete retained transient progress is distinct from final source conservation')
    correction = read('roundtrip-finding.json')
    first_code = (BASE / 'verify-pre-roundtrip.py.txt').read_bytes()
    fixed_code = (BASE / 'verify-post-roundtrip.py.txt').read_bytes()
    correction_epochs = (
        ('first_programme', 'verify-pre-roundtrip.py.txt', first_code),
        ('repaired_programme', 'verify-post-roundtrip.py.txt', fixed_code))
    for role, filename, body in correction_epochs:
        need(correction[role] == dict(path=str(BASE / filename), **pin(body)),
             'whole owned first and repaired round-trip programme epoch')
    old_expression = b"conditions=(PLAN['condition'], terminal['condition'])"
    new_expression = b"conditions=[PLAN['condition'], terminal['condition']]"
    need(correction['owner'] == PLAN['owner'] and first_code.count(old_expression) == 1
         and fixed_code == first_code.replace(old_expression, new_expression, 1),
         'only exact condition-container repair advances first metadata programme')
    sample = (PLAN['condition'], 'original source/datelined prerequisite role')
    need(canonical(correction['actual']) == canonical(dict(before_equal=False, after_equal=True))
         and json.loads(json.dumps(sample)) != sample
         and json.loads(json.dumps(list(sample))) == list(sample), 'actual first and repaired JSON condition round trip')
    import_finding = read('import-finding.json')
    failed_seal = read('seal-actual.json')
    started_seal = read('seal-started.json')
    need(import_finding['owner'] == PLAN['owner']
         and all(failed_seal[key] == value for key, value in started_seal.items())
         and type(failed_seal['status']) is int and failed_seal['status'] == 1
         and type(failed_seal['expected_status']) is int and failed_seal['expected_status'] == 0
         and failed_seal['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'), '--seal']
         and failed_seal['stdout'] == '' and failed_seal['programmes'] == failed_seal['programmes_after']
         and "ImportError: cannot import name 'TASK' from 'verify'" in failed_seal['stderr']
         and 'docs/audits/raw-stack-prerequisites-20261011/verify.py' in failed_seal['stderr'],
         'whole first unexpected native1 declared0 final-seal import failure retains')
    need(failed_seal['programmes'][str(BASE / 'verify.py')]['body'].encode() == (BASE / 'verify-first-seal.py.txt').read_bytes()
         and read('publication-actual.json')['programmes'][str(BASE / 'publish.py')]['body'].encode()
             == (BASE / 'publish-first-seal.py.txt').read_bytes(), 'whole first failed verifier and original publisher epochs')
    first_runner = (BASE / 'prerequisites-first-import.py.txt').read_bytes()
    old_import = b"sys.path.insert(0, str(PRIOR))\nimport replay\n"
    fixed_import = (b"_prior_import_path = sys.path[:]\ntry:\n    sys.path.insert(0, str(PRIOR))\n"
                    b"    import replay\nfinally:\n    sys.path[:] = _prior_import_path\n")
    need(first_runner.count(old_import) == 1
         and (BASE / 'prerequisites.py').read_bytes() == first_runner.replace(old_import, fixed_import, 1)
         and read('gate-prerequisites-actual.json')['programmes'][str(BASE / 'prerequisites.py')]['body'].encode() == first_runner,
         'only scoped original replay import changes; original child commands and predicates retain')
    import_check = gate('import-corrected', ['python3', '-B', str(BASE / 'import_check.py')],
        'PASS actual original prerequisite imports resolve the owned publisher/verifier interface.\n', current=current)
    recovery_finding = read('recovery-finding.json')
    failed_publication = read('recovery-publication-actual.json')
    first_recovery = (BASE / 'publish-first-recovery.py.txt').read_bytes()
    need(recovery_finding['owner'] == PLAN['owner']
         and recovery_finding['first_programme'] == dict(path=str(BASE / 'publish-first-recovery.py.txt'), **pin(first_recovery))
         and type(failed_publication['status']) is int and failed_publication['status'] == 1
         and type(failed_publication['expected_status']) is int and failed_publication['expected_status'] == 0
         and failed_publication['stdout'] == ''
         and failed_publication['stderr'].endswith('ValueError: exact original proposed prerequisite closure\n')
         and failed_publication['programmes'] == failed_publication['programmes_after'],
         'complete first unexpected recovery publication block refusal and programme retains')
    recovery_publication = gate('recovery-publication-corrected', ['python3', '-B', str(BASE / 'recover.py')],
        'Published corrected owned import recovery; original reader results and scopes retain.\n', current=current)
    raw_proof = json.loads(Path(PLAN['raw_acceptance'] + '/proof.json').read_bytes())
    unknowns = dict(raw=raw_proof['unknowns'], conditions=[PLAN['condition'], terminal['condition']],
        primary_epoch='Primary authenticated its own complete original pinned source/native graph before this separately retained source census. Temporal before/after census for that first primary run is not claimed; its actual programmes conserve. A separate fresh primary execution now lies inside the retained whole source census epoch.',
        association='Independent every-operation primary/raw association and cause-parent closure remain pending.')
    candidate = dict(source=source, contracts=contracts(), primary=primary, epoch_primary=epoch_primary, raw=raw,
                     prerequisites=actuals, unknowns=unknowns)
    join(candidate, candidate)
    controls = []
    for name, mutate, cause in (
        ('omitted source member', lambda row: row['source']['publication']['members'].pop(next(iter(row['source']['publication']['members']))), 'complete original/current source role join'),
        ('omitted original prerequisite', lambda row: row['contracts']['prerequisites'].pop(PRIMARY), 'whole original prerequisite and cause obligation join'),
        ('Boolean primary outcome', lambda row: row['primary'].update(status=False), 'typed complete primary success'),
        ('borrowed raw command', lambda row: row['raw'].update(command=row['primary']['command']), 'whole exact actual primary and raw reader custody'),
        ('omitted coordinate/address reader', lambda row: row['prerequisites'].pop('address-coordinate'), 'complete coordinate/address native association'),
        ('private/native promotion', lambda row: row['unknowns'].update(association='Original private identity measured'), 'whole source-native uncertainty boundary')):
        bad = copy.deepcopy(candidate)
        mutate(bad)
        try:
            join(bad, candidate)
        except ValueError as error:
            need(str(error) == cause, 'intended whole prerequisite join refusal')
            controls.append(dict(name=name, cause=str(error)))
        else:
            raise ValueError('changed prerequisite join accepted')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], source=pin(canonical(source)), prior_commit=pin(canonical(prior_commit)),
        contracts=candidate['contracts'], primary=pin(canonical(primary)),
        epoch_primary=pin(canonical(epoch_primary)), raw=pin(canonical(raw)),
        progress=pin(canonical(progress)), correction=pin(canonical(correction)),
        import_recovery=dict(finding=pin(canonical(import_finding)), first_seal=pin(canonical(failed_seal)),
                             corrected=pin(canonical(import_check)), block_finding=pin(canonical(recovery_finding)),
                             first_publication=pin(canonical(failed_publication)), publication=pin(canonical(recovery_publication))),
        prerequisites={name: pin(canonical(row)) for name, row in actuals.items()}, unknowns=unknowns, controls=controls,
        legs=dict(rederive='Complete original/publication Git graph, unchanged full task contracts, actual original primary and raw readers and eleven coordinate/address readers in their explicit source/dated roles.',
                  falsify='Every inherited reader retains its original semantic controls; genuine complete-source/contract/typed-primary/raw-command/coordinate/native-boundary join interventions reject.',
                  durability='Complete source graph, before/after coordinate/address/raw epoch, original native/products, complete actual programmes/commands/streams and saved reader committed with normal hooks. No original native/private recapture or later currency.'))


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        need(not path.is_symlink() and stat.S_ISREG(path.lstat().st_mode)
             and path.stat().st_dev == Path.cwd().stat().st_dev, 'whole ordinary flat cause prerequisite archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(path.stat().st_mode & 0o111))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one complete prerequisite reader role')
    result = core(current=args.current or args.seal)
    if args.core:
        print('PASS complete primary/raw/coordinate/address source prerequisite core; delivery remains separate.')
        return
    import publish
    result['publication'] = publish.qualify(current=args.current or args.seal)
    result['external'] = {name: pin(canonical(gate(name, command, current=args.current or args.seal)))
                          for name, command in publish.COMMANDS.items()}
    need('All tests successful' in read('focused-corrected-actual.json')['stdout'], 'actual focused regression success')
    need(json.loads(canonical(result)) == result, 'whole proof uses lossless JSON-native containers and values')
    if args.seal:
        save('proof.json', result)
        save('manifest.json', catalogue())
    else:
        need(read('proof.json') == result and read('manifest.json') == catalogue(), 'whole immutable saved cause prerequisite proof')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
