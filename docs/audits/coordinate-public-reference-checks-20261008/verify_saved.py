"""Rebuild the finite reference from independent complete binary-source oracles."""
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-reference-checks-20261008')
MODEL = Path('docs/audits/record-value-coordinate-public-reference-20261008')
PRIOR = 'docs/audits/coordinate-public-qualification-checks-20261008/verify_saved.py'
QUALIFIED = 'docs/audits/record-value-coordinate-public-qualification-20261008/qualification.json'
ROLE = 'Dated complete finite own public coordinate recipes. Canonical current route, final public parent, original coordinates and original/private/formatter/toolchain/address identities remain pending.'
SUCCESS = 'PASS independent complete finite public reference, typed source selections and genuine controls; original meanings remain pending.\n'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def read(path):
    return json.loads(path.read_bytes())


def fixed_source():
    revision = read(BASE / 'epoch.json')['revision']
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision, 'docs/audits'], text=True).splitlines()
    selected = [p for p in paths if p.split('/')[2].startswith(('coordinate-', 'record-value-coordinate-'))]
    archive = subprocess.check_output(['git', 'archive', revision, *selected])
    with tarfile.open(fileobj=io.BytesIO(archive)) as source:
        fixed = {m.name: source.extractfile(m).read() for m in source.getmembers() if m.isfile()}
    roots = sorted({str(Path(p).parent) for p in selected})
    live = {}
    for root in roots:
        need(not Path(root).is_symlink() and Path(root).stat().st_dev == Path.cwd().stat().st_dev,
             'independent regular local prerequisite root')
        for path in Path(root).iterdir():
            need(path.is_file() and not path.is_symlink() and path.stat().st_dev == Path.cwd().stat().st_dev,
                 'independent regular local prerequisite member')
            live[str(path)] = path.read_bytes()
    need(live == fixed, 'independent complete fixed source/result member census')
    task = subprocess.check_output(['git', 'show', revision + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'])
    owners = {}
    for root in roots:
        if '/record-value-' in root:
            owner = fixed[root + '/scope.txt'].decode().splitlines()[0][7:]
            suffix = task.decode().split('- ID: `' + owner + '`', 1)[1].split('\n- ID:', 1)[0]
            need('\n  Status: `done`\n' in suffix, 'independent complete committed owner')
            owners[owner] = '- ID: `' + owner + '`' + suffix
    expected = dict(revision=revision, roots=roots, members={p: pin(v) for p, v in fixed.items()},
                    owners=owners, task_identity=pin(task), role=ROLE)
    need(same(read(MODEL / 'binding.json'), expected), 'independent entire reference member/owner binding')
    return fixed


def rebuild(fixed):
    oracle = {'__name__': 'fixed_independent_source_wire_oracle'}
    exec(compile(fixed[PRIOR], PRIOR, 'exec'), oracle)
    full = oracle['reconstruct'](fixed)
    runs = []
    need(len(full['callers']['runs']) == len(full['origins']['runs']), 'independent complete recipe root population')
    for callers, origins in zip(full['callers']['runs'], full['origins']['runs']):
        need(same(callers['invocation'], origins['invocation']), 'independent exact caller/origin root join')
        def coordinate(row):
            selected = row['selection']
            return dict(role=row['role'], frame_index=row['frame_index'], callee=selected['callee'],
                        filename=selected['filename'], line=selected['line'],
                        matching_line_labels=selected['matching_line_labels'], source=selected['source'])
        origin_rows = []
        for row in origins['cases']:
            fields = {}
            for field, value in row['origins'].items():
                fields[field] = dict(filename=value['filename'], line=value['line'], matches=value['matches'],
                                     outcome=value['outcome'], unresolved=value['unresolved'],
                                     message=value['message'], raw_identity=value['raw_identity'])
            origin_rows.append(dict(role=row['role'], origins=fields))
        runs.append(dict(invocation=callers['invocation'], calls=list(map(coordinate, callers['calls'])),
                         boundaries={k: coordinate(v) for k, v in callers['boundaries'].items()}, origins=origin_rows,
                         whole_raw_wire_identity=callers['whole_raw_wire_identity'], module_filename=callers['module_filename']))
    variants = []
    for row in full['native']['runs']:
        variants.append(dict(name=row['name'], invocation=row['invocation'], expected=row['expected'],
                             intended_refusal=row['intended_refusal'], target_result=row['target_result'],
                             base_root_admission=row['base_root_admission'],
                             source_identity={p: pin(v.encode()) for p, v in row['source'].items()}))
    return dict(runs=runs, native_controls=variants, configuration=full['origins']['configuration'],
                complete_qualification_path=QUALIFIED, complete_qualification_identity=pin(fixed[QUALIFIED]), role=ROLE)


def check(candidate, expected):
    need(candidate['role'] == ROLE, 'independent finite reference identity gaps')
    for run in candidate['runs']:
        coordinates = run['calls'] + list(run['boundaries'].values())
        coordinates.extend(v for case in run['origins'] for v in case['origins'].values())
        need(all(type(c['line']) is int for c in coordinates), 'independent reference line kinds')
    need(same(candidate, expected), 'independent entire binary-source/reference allocation')


def main():
    members = {p.name: pin(p.read_bytes()) for p in MODEL.iterdir() if p.name != 'manifest.json'}
    need(all(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev for p in MODEL.iterdir())
         and same(read(MODEL / 'manifest.json'), members), 'independent immutable full reference seal')
    fixed = fixed_source(); expected = rebuild(fixed); product = read(MODEL / 'recipes.json'); check(product, expected)
    controls = []
    for name, mutate, cause in (
        ('lost-root', lambda c: c['runs'].pop(), 'independent entire binary-source/reference allocation'),
        ('lost-origin', lambda c: c['runs'][0]['origins'].pop(), 'independent entire binary-source/reference allocation'),
        ('lost-alternative', lambda c: c['runs'][0]['calls'][0]['matching_line_labels'].pop(), 'independent entire binary-source/reference allocation'),
        ('Boolean-line', lambda c: c['runs'][0]['calls'][0].update(line=False), 'independent reference line kinds'),
        ('false-wrong-root', lambda c: c['native_controls'][2]['base_root_admission'].update(status='selected'), 'independent entire binary-source/reference allocation'),
        ('lost-native-control', lambda c: c['native_controls'].pop(), 'independent entire binary-source/reference allocation'),
        ('scope-promotion', lambda c: c.update(role='All original coordinates qualify.'), 'independent finite reference identity gaps'),
    ):
        candidate = copy.deepcopy(product); mutate(candidate)
        need(not same(candidate, product), 'genuine independent reference control')
        try:
            check(candidate, expected)
        except ValueError as error:
            need(str(error) == cause, 'intended independent reference refusal')
            controls.append(dict(control=name, status=1, cause=cause, candidate_identity=pin(json.dumps(candidate, sort_keys=True).encode())))
        else:
            raise ValueError('false-green independent reference control')
    # Consume the primary actual-result product independently, including exact
    # expected command, status, streams and all invocation-time instruments.
    actuals = read(MODEL / 'actual-results.json')
    scripts = ['docs/audits/record-value-coordinate-public-qualification-20261008/verify.py', PRIOR,
               'docs/audits/coordinate-public-qualification-checks-20261008/consume_actual.py']
    need([r['name'] for r in actuals] == ['qualification', 'independent', 'actual'], 'independent complete reference actual population')
    for row, script in zip(actuals, scripts):
        actual = row['actual']
        historical_name = {'qualification': 'qualification.json', 'independent': 'saved-result.json', 'actual': 'actual-consumption.json'}[row['name']]
        historical = json.loads(fixed['docs/audits/coordinate-public-qualification-checks-20261008/' + historical_name])
        instruments = {str(BASE / 'run.py'): pin((BASE / 'run.py').read_bytes()), 'scripts/run_with_ram_guard.sh': pin(Path('scripts/run_with_ram_guard.sh').read_bytes()), script: pin(fixed[script])}
        need(type(actual['status']) is int and actual['status'] == 0
             and actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', script]
             and actual['stdout'] == historical['stdout'] and same(actual['instruments'], instruments)
             and re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', actual['stderr']),
             'independent entire actual reference result/instrument custody')
    proof = dict(members=members, controls=controls, actual_results=actuals,
                 reconstruction=pin(json.dumps(expected, sort_keys=True).encode()), role=ROLE)
    path = BASE / 'proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'complete retained independent reference proof')
    else:
        path.write_text(raw)
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
