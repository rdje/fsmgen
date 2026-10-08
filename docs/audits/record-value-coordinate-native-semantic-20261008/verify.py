"""Qualify retained native variants without executing their spent captures."""
import argparse
import copy
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-native-semantic-20261008')
REVISION = '857ba30485c5a176263e6e5779779051294d6f23'
AUDITS = Path('docs/audits')
SOURCE = AUDITS / 'record-value-coordinate-public-hypotheses-20261007'
CALLERS = AUDITS / 'record-value-coordinate-public-caller-selection-20261007'
ORIGINS = AUDITS / 'record-value-coordinate-public-origin-selection-20261007'
PLANS = AUDITS / 'record-value-coordinate-native-control-plans-20261008'
CAPTURE = AUDITS / 'record-value-coordinate-native-control-capture-20261008'
GOOD = AUDITS / 'record-value-coordinate-public-capture-20261007'
ROLE = ('Dated finite native semantic falsification only. Whole raw bytes and actual '
        'roots conserve; whole public qualification and every original/private/'
        'formatter/toolchain/address identity remain pending.')
SUCCESS = 'PASS complete retained native semantic refusals, positive wrong-root coordinates and genuine controls; no capture executes.\n'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def load(path):
    return json.loads(path.read_bytes())


def namespace(path):
    result = {'__name__': 'retained_native_semantic_dependency'}
    exec(compile(path.read_bytes(), str(path), 'exec'), result)
    return result


def binding():
    names = subprocess.check_output(['git', 'ls-tree', '-z', '--name-only',
                                     REVISION + ':docs/audits']).split(b'\0')
    roots = [AUDITS / name.decode() for name in names if name.startswith(
        (b'record-value-coordinate-', b'coordinate-public-', b'coordinate-native-control-'))]
    raw = subprocess.check_output(['git', 'archive', REVISION, *map(str, roots)])
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        fixed = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
    current = {}
    for root in roots:
        need(root.is_dir() and not root.is_symlink()
             and root.stat().st_dev == Path.cwd().stat().st_dev, 'complete same-volume prerequisite root')
        for path in root.iterdir():
            need(path.is_file() and not path.is_symlink()
                 and path.stat().st_dev == Path.cwd().stat().st_dev, 'complete regular prerequisite member')
            current[str(path)] = path.read_bytes()
    need(current == fixed, 'whole fixed committed source/plan/capture/actual bytes')
    task = subprocess.check_output(['git', 'show', REVISION + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'])
    owners = {}
    for root in roots:
        if not root.name.startswith('record-value-'):
            continue
        owner = fixed[str(root / 'scope.txt')].decode().splitlines()[0].removeprefix('Owner: ')
        suffix = task.decode().split('- ID: `' + owner + '`', 1)[1].split('\n- ID:', 1)[0]
        need('\n  Status: `done`\n' in suffix, 'whole committed completed prerequisite owner')
        owners[owner] = '- ID: `' + owner + '`' + suffix
    return dict(revision=REVISION, roots=list(map(str, roots)), owners=owners,
                members={p: pin(raw) for p, raw in fixed.items()}, task_identity=pin(task), role=ROLE)


def inputs():
    return dict(good_source=load(SOURCE / 'inputs.json')['source'],
                hypotheses=load(SOURCE / 'hypotheses.json'),
                origins=load(ORIGINS / 'inputs.json')['hypotheses'],
                plans=load(PLANS / 'plans.json'), wire=load(CAPTURE / 'wire.json'),
                good_wire=load(GOOD / 'wire.json'), role=ROLE)


def attempt(callback):
    try:
        return dict(status='selected', selection=callback(), refusal=None)
    except ValueError as error:
        return dict(status='refused', selection=None, refusal=str(error))


def coordinates(payload, hypotheses, origin_hypotheses):
    caller = namespace(CALLERS / 'verify.py')
    origin = namespace(ORIGINS / 'verify.py')
    need([r['role'] for r in payload['observations']] == [r['role'] for r in hypotheses['calls']],
         'whole source-declared native observation allocation')
    observations = {r['role']: r for r in payload['observations']}
    calls = []
    for declared in hypotheses['calls']:
        frames = observations[declared['role']]['frames']; index = declared['caller_frame_index']
        need(len(frames) > index, 'whole native declared caller frame')
        result = attempt(lambda: caller['frame_selection'](frames[index], declared, declared['filename_hypotheses']))
        calls.append(dict(role=declared['role'], frame_index=index, result=result))
    boundaries = {}
    for name, role in caller['BOUNDARIES'].items():
        declared = hypotheses['boundaries'][name]; index = declared['caller_frame_index']
        frames = observations[role]['frames']
        need(len(frames) > index, 'whole native declared boundary frame')
        result = attempt(lambda: caller['frame_selection'](frames[index], declared, [declared['filename']]))
        boundaries[name] = dict(role=role, frame_index=index, result=result)
    origins = []
    for declared in origin_hypotheses['cases']:
        observed = observations[declared['role']]
        origins.append(dict(role=declared['role'], origins={
            field: origin['origin'](observed[field], declared['origins'][field])
            for field in ('trace', 'guard_error')}))
    need(payload['module_filename'] == hypotheses['module_filename'], 'whole unchanged public module filename')
    return dict(calls=calls, boundaries=boundaries, origins=origins,
                module_filename=payload['module_filename'])


def root_admission(saved, invocation):
    # This is the unchanged admission expression from the qualified caller
    # selector. The native row is passed as captured, without rewriting cwd.
    need(same(saved['invocation'], invocation)
         and saved['actual']['cwd'] == invocation['root']
         and saved['actual']['command'] == invocation['command'],
         'exact legitimate public selection invocation')
    return dict(invocation=invocation)


def derive(candidate):
    need(candidate['role'] == ROLE, 'native falsification cannot promote pending identity or whole-public scope')
    fixed = inputs()
    need(same(candidate['good_source'], fixed['good_source']), 'whole fixed good-source authority')
    need(same(candidate['hypotheses'], fixed['hypotheses'])
         and same(candidate['origins'], fixed['origins'])
         and same(candidate['plans'], fixed['plans']), 'whole precommitted hypotheses and refusal plans')
    need(same(candidate['good_wire'], fixed['good_wire']), 'whole retained positive comparison wire')
    wire = candidate['wire']; plans = candidate['plans']['plans']
    need([r['name'] for r in wire['runs']] == [p['name'] for p in plans], 'whole native semantic run allocation')
    # Custody was independently qualified before this leaf. Reconsume its full
    # typed source/command/environment/stream predicates, without recapturing.
    custody = namespace(CAPTURE / 'verify.py')
    custody['derive'](wire)
    positive = []
    for row, invocation in zip(candidate['good_wire']['runs'], candidate['hypotheses']['invocations']):
        root_admission(row, invocation)
        result = coordinates(json.loads(row['actual']['stdout']), candidate['hypotheses'], candidate['origins'])
        need(all(c['result']['status'] == 'selected' for c in result['calls'])
             and all(c['result']['status'] == 'selected' for c in result['boundaries'].values())
             and all(o['outcome'] == 'selected' for c in result['origins'] for o in c['origins'].values()),
             'whole retained positive comparison coordinates')
        positive.append(dict(invocation=invocation, coordinates=result,
                             raw_wire_identity=pin(row['actual']['stdout'].encode())))
    results = []
    for row, plan in zip(wire['runs'], plans):
        expected = plan['expected']; native = row['actual']; payload = json.loads(native['stdout'])
        result = coordinates(payload, candidate['hypotheses'], candidate['origins'])
        observed = next(r for r in payload['observations'] if r['role'] == expected['role'])
        frame = observed['frames'][expected['frame_index']]
        need(frame[3] == expected['caller'] and type(frame[2]) is int
             and frame[2] in (expected['first_line'], expected['closing_line'])
             and frame[1] == expected['filename'], 'actual target agrees with precommitted variant source')
        target = next(r['result'] for r in result['calls'] if r['role'] == expected['role'])
        root = attempt(lambda: root_admission(row, plan['base_invocation']))
        if expected['coordinate_check'] == 'positive':
            need(all(c['result']['status'] == 'selected' for c in result['calls'])
                 and all(c['result']['status'] == 'selected' for c in result['boundaries'].values())
                 and all(o['outcome'] == 'selected' for c in result['origins'] for o in c['origins'].values()),
                 'source-identical wrong-root keeps all good coordinates')
            refusing = root
        else:
            refusing = target
        need(refusing['status'] == 'refused' and refusing['refusal'] == expected['refusal'],
             'exact precommitted native separating refusal')
        results.append(dict(name=row['name'], invocation=row['invocation'], source=plan['source'],
                            expected=expected, target_frame=frame, target_result=target,
                            base_root_admission=root, intended_refusal=refusing['refusal'],
                            coordinates=result, actual=native, environment=row['environment'],
                            before=row['before'], after=row['after']))
    return dict(runs=results, positive_comparisons=positive, role=ROLE)


def controls(original):
    cases = [
        ('lost-run', lambda c: c['wire']['runs'].pop(), 'whole native semantic run allocation'),
        ('lost-refusal-plan', lambda c: c['plans']['plans'][0]['expected'].update(refusal='passed'),
         'whole precommitted hypotheses and refusal plans'),
        ('borrowed-good-source', lambda c: c['good_source'].update({'fixture.pl': c['good_source']['load-body.pl']}),
         'whole fixed good-source authority'),
        ('whole-public-promotion', lambda c: c.update(role='Whole public and original identities qualify.'),
         'native falsification cannot promote pending identity or whole-public scope'),
    ]
    result = []
    for name, mutate, cause in cases:
        changed = copy.deepcopy(original); mutate(changed)
        need(not same(changed, original), 'genuine native semantic candidate')
        try:
            derive(changed)
        except ValueError as error:
            need(str(error) == cause, 'intended semantic candidate refusal: ' + name)
            result.append(dict(control=name, status=1, cause=cause, candidate=changed))
        else:
            raise ValueError('false-green native semantic candidate: ' + name)
    return result


def members():
    need(all(p.is_file() and not p.is_symlink()
             and p.stat().st_dev == Path.cwd().stat().st_dev for p in BASE.iterdir()),
         'whole regular same-volume semantic seal')
    return {p.name: pin(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}


def save(name, value):
    path = BASE / name; raw = json.dumps(value, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained semantic product: ' + name)
    else:
        need(not (BASE / 'manifest.json').exists(), 'sealed semantic products cannot publish')
        path.write_text(raw)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true'); args = parser.parse_args()
    if (BASE / 'manifest.json').exists():
        need(same(load(BASE / 'manifest.json'), members()), 'whole immutable semantic seal')
    before = binding(); save('binding.json', before)
    candidate = inputs(); save('inputs.json', candidate)
    save('qualification.json', derive(candidate)); save('controls.json', controls(candidate))
    need(same(binding(), before), 'every complete original prerequisite member conserves')
    if args.seal:
        save('manifest.json', members())
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
