"""Independently consume whole fixed plan bytes and every retained native checkpoint."""
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-native-control-capture-checks-20261008')
MODEL = Path('docs/audits/record-value-coordinate-native-control-capture-20261008')
PLANS = Path('docs/audits/record-value-coordinate-native-control-plans-20261008')
PRIOR = Path('docs/audits/coordinate-native-control-plan-checks-20261008')
REVISION = 'ef5ab4b222a3d0c9a86d2d8431c9a6b62190a452'
SCOPE = 'Dated native control source/wire custody only; native semantic refusals and original/private/formatter/toolchain identities remain unqualified.'
ROLE = 'Dated native control custody only. Every raw coordinate/frame/error/argument remains intact; semantic refusing decisions and original identities remain pending.'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def read(path):
    return json.loads(path.read_bytes())


def check(wire, plans, binding):
    need(wire['scope'] == SCOPE and wire['admission']['scope'] == SCOPE, 'independent custody scope cannot promote native meanings')
    need(same(wire['admission']['binding'], binding)
         and same(wire['admission']['capture_programme'], pin((MODEL / 'capture.py').read_bytes()))
         and same(wire['admission']['planned_invocations'], [p['invocation'] for p in plans]),
         'independent complete native plan/instrument admission')
    need([r['name'] for r in wire['runs']] == [p['name'] for p in plans], 'independent whole native run allocation')
    result = []
    for row, plan in zip(wire['runs'], plans):
        native = row['actual']
        need(type(native['status']) is int and native['status'] == 0, 'independent integer native control status')
        need(same(row['invocation'], plan['invocation']) and native['command'] == plan['invocation']['command']
             and native['cwd'] == plan['invocation']['root'], 'independent exact actual native root and invocation')
        sources = {p: text.encode('utf-8') for p, text in plan['source'].items()}
        need(same(row['source'], plan['source']) and same(row['before'], {p: pin(raw) for p, raw in sources.items()})
             and same(row['after'], row['before']), 'independent full source byte and census conservation')
        need(same(row['environment'], dict(PERL5OPT='', PERL5LIB='', temporary_root=native['cwd'] + '/.tmp',
                                          runtime_absolute_temporary_values=True)), 'independent native environment locality')
        for field in ('stdout', 'stderr'):
            need(type(native[field]) is str and same(native[field + '_identity'], pin(native[field].encode('utf-8'))),
                 'independent complete raw native streams')
        payload = json.loads(native['stdout'].encode('utf-8'))
        need(set(payload) == {'module_filename', 'observations'}
             and [r['role'] for r in payload['observations']] == ['single', 'multiline', 'postfix', 'block-eval', 'anonymous', 'do-load', 'require-load', 'module-call', 'subtest'],
             'independent complete native raw observation population')
        for observed in payload['observations']:
            need(set(observed) == {'role', 'frames', 'trace', 'guard_ok', 'guard_error'} and observed['guard_ok'] is None
                 and type(observed['frames']) is list and observed['frames']
                 and all(type(observed[k]) is str and observed[k] for k in ('trace', 'guard_error')),
                 'independent whole caught native trace/error/frame products')
            for frame in observed['frames']:
                need(type(frame) is list and len(frame) == 8 and type(frame[2]) is int and frame[2] > 0
                     and all(type(frame[i]) is str for i in (0, 1, 3)), 'independent raw frame primitive kinds')
        result.append(dict(name=row['name'], invocation=row['invocation'], payload=payload,
                           whole_raw_wire_identity=pin(native['stdout'].encode()), source_pins=row['before']))
    tools = wire['tools']; first = plans[0]['invocation']['root']
    need(same(tools['executable_before'], tools['executable_after'])
         and type(tools['executable_before']['bytes']) is int and tools['executable_before']['bytes'] > 0
         and re.fullmatch('[0-9a-f]{64}', tools['executable_before']['sha256']), 'independent opaque executable identity conservation')
    for name in ('version', 'modules'):
        row = tools[name]
        need(type(row['status']) is int and row['status'] == 0 and row['cwd'] == first, 'independent complete public metadata native status/root')
        for field in ('stdout', 'stderr'):
            need(same(row[field + '_identity'], pin(row[field].encode())), 'independent complete public metadata raw streams')
    need(tools['version']['command'] == ['perl', '-V'], 'independent native version command')
    command = ['perl', '-MJSON::PP', '-MCarp', '-MTest::More', '-e',
               'print JSON::PP->new->canonical->encode({perl=>$^V."", json_pp=>$JSON::PP::VERSION, carp=>$Carp::VERSION, test_more=>$Test::More::VERSION}), "\\n";']
    need(tools['modules']['command'] == command and set(json.loads(tools['modules']['stdout'])) == {'perl', 'json_pp', 'carp', 'test_more'},
         'independent complete public module metadata command and keys')
    return dict(runs=result, tools=tools, role=ROLE)


def receipt(name, command, stdout):
    row = read(BASE / name)
    paths = [BASE / 'run.py', Path('scripts/run_with_ram_guard.sh')]
    paths.extend(Path(arg) for arg in command if arg.startswith(('docs/', 'scripts/', 't/')) and Path(arg).is_file())
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and type(row['status']) is int and row['status'] == 0 and row['stdout'] == stdout
         and re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and same(row['instruments'], {str(p): pin(p.read_bytes()) for p in paths}), 'independent complete actual receipt and instruments: ' + name)


def main():
    members = {p.name: pin(p.read_bytes()) for p in MODEL.iterdir() if p.name != 'manifest.json'}
    need(all(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev for p in MODEL.iterdir())
         and same(members, read(MODEL / 'manifest.json')), 'independent complete immutable capture seal')
    archive = subprocess.check_output(['git', 'archive', REVISION, str(PLANS), str(PRIOR)])
    with tarfile.open(fileobj=io.BytesIO(archive)) as source:
        fixed = {m.name: source.extractfile(m).read() for m in source.getmembers() if m.isfile()}
    need(fixed == {str(p): p.read_bytes() for root in (PLANS, PRIOR) for p in root.iterdir()}, 'independent whole fixed plan/programme/actual bytes')
    plans = json.loads(fixed[str(PLANS / 'plans.json')])['plans']; binding = read(MODEL / 'binding.json')
    task = subprocess.check_output(['git', 'show', REVISION + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'])
    owner = fixed[str(PLANS / 'scope.txt')].decode().splitlines()[0].removeprefix('Owner: ')
    suffix = task.decode().split('- ID: `' + owner + '`', 1)[1].split('\n- ID:', 1)[0]
    need(same(binding, dict(revision=REVISION, members={p: pin(raw) for p, raw in fixed.items()}, owner='- ID: `' + owner + '`' + suffix, task_identity=pin(task)))
         and '\n  Status: `done`\n' in suffix, 'independent whole committed completed plan owner and binding')
    wire = read(MODEL / 'wire.json')
    need(same(wire['admission'], read(MODEL / 'started.json')) and same(wire['tools'], read(MODEL / 'tools.json'))
         and all(same(row, read(MODEL / ('run-' + row['name'] + '.json'))) for row in wire['runs']), 'independent complete spent admission and native run checkpoints')
    expected = check(wire, plans, binding)
    need(same(expected, read(MODEL / 'custody.json')), 'independent whole raw native custody reconstruction')
    receipt('capture.json', ['python3', '-B', str(MODEL / 'capture.py')], 'Captured every committed native control once with per-run complete checkpoints; semantic refusal selection remains pending.\n')
    receipt('seal.json', ['python3', '-B', str(MODEL / 'verify.py'), '--seal'], 'PASS complete one-time native control custody and genuine custody controls; semantic refusals remain pending.\n')
    receipt('prerequisite.json', ['python3', '-B', str(PRIOR / 'verify_saved.py')], json.loads(fixed[str(PRIOR / 'saved-result.json')])['stdout'])
    controls = []
    for name, mutate, cause in [
        ('Boolean-status', lambda c: c['runs'][0]['actual'].update(status=False), 'independent integer native control status'),
        ('lost-run', lambda c: c['runs'].pop(), 'independent whole native run allocation'),
        ('borrowed-root', lambda c: c['runs'][2]['actual'].update(cwd='borrowed'), 'independent exact actual native root and invocation'),
        ('source-member-loss', lambda c: c['runs'][3]['after'].pop('borrowed-body.pl'), 'independent full source byte and census conservation'),
        ('raw-byte-loss', lambda c: c['runs'][1]['actual'].update(stdout=c['runs'][1]['actual']['stdout'][:-1]), 'independent complete raw native streams'),
        ('semantic-promotion', lambda c: c.update(scope='Native semantic refusals qualify.'), 'independent custody scope cannot promote native meanings'),
    ]:
        candidate = copy.deepcopy(wire); mutate(candidate)
        need(not same(candidate, wire), 'genuine independent custody mutation')
        try:
            check(candidate, plans, binding)
        except ValueError as error:
            need(str(error) == cause, 'intended independent custody refusal: ' + name)
            controls.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green independent custody control: ' + name)
    producer = {'__name__': 'native_custody_controls'}
    exec(compile((MODEL / 'verify.py').read_bytes(), str(MODEL / 'verify.py'), 'exec'), producer)
    need(same(producer['controls'](wire), read(MODEL / 'controls.json')), 'whole real producer custody controls reproduce')
    proof = dict(members=members, controls=controls, capture_utc=wire['admission']['captured_utc'],
                 source_wire_scope=SCOPE, native_semantic_refusals='pending')
    path = BASE / 'proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained independent native capture proof')
    else:
        path.write_text(raw)
    print('PASS independent complete native control source/wire/checkpoint custody and genuine controls; semantic refusal qualification remains pending.')


if __name__ == '__main__':
    main()
