"""Publish only the complete qualified finite own public recipe reference."""
import argparse
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-public-reference-20261008')
CHECKS = Path('docs/audits/coordinate-public-reference-checks-20261008')
QUALIFIED = Path('docs/audits/record-value-coordinate-public-qualification-20261008')
PRIOR_CHECKS = Path('docs/audits/coordinate-public-qualification-checks-20261008')
ROLE = 'Dated complete finite own public coordinate recipes. Canonical current route, final public parent, original coordinates and original/private/formatter/toolchain/address identities remain pending.'
SUCCESS = 'PASS complete finite public recipe reference and genuine controls; no original-coordinate intake or capture execution.\n'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def load(path):
    return json.loads(path.read_bytes())


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def binding():
    revision = load(CHECKS / 'epoch.json')['revision']
    names = subprocess.check_output(['git', 'ls-tree', '-z', '--name-only', revision + ':docs/audits']).split(b'\0')
    roots = ['docs/audits/' + n.decode() for n in names if n.startswith((b'coordinate-', b'record-value-coordinate-'))]
    raw = subprocess.check_output(['git', 'archive', revision, *roots])
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        fixed = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
    current = {}
    for root in roots:
        paths = list(Path(root).iterdir())
        need(not Path(root).is_symlink() and all(p.is_file() and not p.is_symlink()
             and p.stat().st_dev == Path.cwd().stat().st_dev for p in paths), 'complete regular same-volume public reference prerequisites')
        current.update({str(p): p.read_bytes() for p in paths})
    need(current == fixed, 'whole fixed public reference source/programme/product/result bytes')
    task = subprocess.check_output(['git', 'show', revision + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'])
    owners = {}
    for root in roots:
        if '/record-value-' in root:
            owner = fixed[root + '/scope.txt'].decode().splitlines()[0][7:]
            suffix = task.decode().split('- ID: `' + owner + '`', 1)[1].split('\n- ID:', 1)[0]
            need('\n  Status: `done`\n' in suffix, 'complete committed completed public reference owner')
            owners[owner] = '- ID: `' + owner + '`' + suffix
    return dict(revision=revision, roots=roots, members={p: pin(v) for p, v in fixed.items()},
                owners=owners, task_identity=pin(task), role=ROLE)


def actual_results():
    results = []
    for name, script, success in (
        ('qualification', QUALIFIED / 'verify.py', 'PASS complete finite public coordinate qualification, whole actual results and controls; no capture executes or original identity qualifies.\n'),
        ('independent', PRIOR_CHECKS / 'verify_saved.py', 'PASS independent complete public source/wire/result qualification and genuine controls; no original identity or capture execution.\n'),
        ('actual', PRIOR_CHECKS / 'consume_actual.py', 'PASS whole independent public qualification actual result custody and genuine controls; final publication and original identities remain pending.\n'),
    ):
        row = load(CHECKS / (name + '.json'))
        paths = [CHECKS / 'run.py', Path('scripts/run_with_ram_guard.sh'), script]
        need(type(row['status']) is int and row['status'] == 0
             and row['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(script)]
             and row['stdout'] == success
             and re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
             and same(row['instruments'], {str(p): pin(p.read_bytes()) for p in paths}), 'complete fresh public reference actual result: ' + name)
        results.append(dict(name=name, actual=row))
    return results


def reference(product):
    runs = []
    for caller, origin in zip(product['callers']['runs'], product['origins']['runs']):
        need(same(caller['invocation'], origin['invocation']), 'whole public reference invocation join')
        calls = [dict(role=c['role'], frame_index=c['frame_index'], **{k: c['selection'][k]
                 for k in ('callee', 'filename', 'line', 'matching_line_labels', 'source')}) for c in caller['calls']]
        boundaries = {name: dict(role=c['role'], frame_index=c['frame_index'], **{k: c['selection'][k]
                      for k in ('callee', 'filename', 'line', 'matching_line_labels', 'source')}) for name, c in caller['boundaries'].items()}
        origins = [dict(role=c['role'], origins={field: {k: value[k] for k in ('filename', 'line', 'matches', 'outcome', 'unresolved', 'message', 'raw_identity')}
                   for field, value in c['origins'].items()}) for c in origin['cases']]
        runs.append(dict(invocation=caller['invocation'], calls=calls, boundaries=boundaries, origins=origins,
                         whole_raw_wire_identity=caller['whole_raw_wire_identity'], module_filename=caller['module_filename']))
    controls = [dict(name=r['name'], invocation=r['invocation'], expected=r['expected'],
                    intended_refusal=r['intended_refusal'], target_result=r['target_result'],
                    base_root_admission=r['base_root_admission'], source_identity={p: pin(v.encode()) for p, v in r['source'].items()})
                for r in product['native']['runs']]
    return dict(runs=runs, native_controls=controls, configuration=product['origins']['configuration'],
                complete_qualification_path=str(QUALIFIED / 'qualification.json'),
                complete_qualification_identity=pin((QUALIFIED / 'qualification.json').read_bytes()), role=ROLE)


def check(candidate, expected):
    need(candidate['role'] == ROLE, 'finite public reference preserves pending identities')
    for run in candidate['runs']:
        coordinates = run['calls'] + list(run['boundaries'].values())
        coordinates += [value for case in run['origins'] for value in case['origins'].values()]
        need(all(type(c['line']) is int for c in coordinates), 'finite public reference integer coordinates')
    need(same(candidate, expected), 'complete public reference source/coordinate/ambiguity/refusal allocation')


def controls(product):
    results = []
    for name, mutate, cause in (
        ('lost-caller', lambda c: c['runs'][0]['calls'].pop(), 'complete public reference source/coordinate/ambiguity/refusal allocation'),
        ('lost-boundary', lambda c: c['runs'][0]['boundaries'].pop('block_eval'), 'complete public reference source/coordinate/ambiguity/refusal allocation'),
        ('lost-origin', lambda c: c['runs'][0]['origins'].pop(), 'complete public reference source/coordinate/ambiguity/refusal allocation'),
        ('lost-equivalent-label', lambda c: c['runs'][0]['calls'][0]['matching_line_labels'].pop(), 'complete public reference source/coordinate/ambiguity/refusal allocation'),
        ('Boolean-line', lambda c: c['runs'][0]['calls'][0].update(line=True), 'finite public reference integer coordinates'),
        ('borrowed-root', lambda c: c['runs'][0]['invocation'].update(root='foreign'), 'complete public reference source/coordinate/ambiguity/refusal allocation'),
        ('lost-refusal', lambda c: c['native_controls'][0].update(intended_refusal=None), 'complete public reference source/coordinate/ambiguity/refusal allocation'),
        ('identity-promotion', lambda c: c.update(role='All original identities qualify.'), 'finite public reference preserves pending identities'),
    ):
        candidate = copy.deepcopy(product); mutate(candidate)
        need(not same(candidate, product), 'genuine public reference control')
        try:
            check(candidate, product)
        except ValueError as error:
            need(str(error) == cause, 'intended public reference control: ' + name)
            results.append(dict(control=name, status=1, cause=cause, candidate_identity=pin(json.dumps(candidate, sort_keys=True).encode())))
        else:
            raise ValueError('false-green public reference control: ' + name)
    return results


def save(name, value):
    path = BASE / name; raw = json.dumps(value, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'complete retained reference product: ' + name)
    else:
        need(not (BASE / 'manifest.json').exists(), 'sealed reference cannot publish')
        path.write_text(raw)


def main():
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument('--seal', action='store_true'); args = parser.parse_args()
    members = lambda: {p.name: pin(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}
    if (BASE / 'manifest.json').exists():
        need(same(load(BASE / 'manifest.json'), members()), 'complete immutable finite reference seal')
    before = binding(); save('binding.json', before)
    expected = reference(load(QUALIFIED / 'qualification.json')); check(expected, expected)
    save('recipes.json', expected); save('actual-results.json', actual_results()); save('controls.json', controls(expected))
    need(same(binding(), before), 'whole committed public/original raw evidence conserves')
    if args.seal:
        save('manifest.json', members())
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
