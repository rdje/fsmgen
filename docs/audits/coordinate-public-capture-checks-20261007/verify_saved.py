"""Independently consume every committed source and saved native wire member."""
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-capture-checks-20261007')
CAPTURE = Path('docs/audits/record-value-coordinate-public-capture-20261007')
SOURCE = Path('docs/audits/record-value-coordinate-public-hypotheses-20261007')
REVISION = '0f597fbb50a7632a18fb9464c1985645dccadaf0'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def identity(raw):
    return {'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


def object_pairs(pairs):
    result = {}
    for key, value in pairs:
        need(key not in result, 'duplicate native JSON field')
        result[key] = value
    return result


def decoded(raw):
    return json.loads(raw, object_pairs_hook=object_pairs)


def data(path):
    return decoded(path.read_bytes())


def ns(path):
    result = {'__name__': 'independent_public_capture_dependency'}
    exec(compile(path.read_bytes(), str(path), 'exec'), result)
    return result


def actual(row, command, stdout):
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and type(row['status']) is int and row['status'] == 0 and row['stdout'] == stdout,
         'complete actual public custody command integer success and stdout')
    need(re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr']),
         'whole unchanged guard actual stderr')
    paths = [BASE / 'run.py', Path('scripts/run_with_ram_guard.sh')]
    paths.extend(Path(arg) for arg in command if arg.startswith(('docs/', 'scripts/', 't/')) and Path(arg).is_file())
    need(row['instruments'] == {str(p): identity(p.read_bytes()) for p in paths}, 'whole actual producing instrument pins')


def independent_wire(wire, committed):
    # Construct the logical source set directly from the fixed Git archive,
    # rather than using the producer's input object or source classifier.
    names = {'fixture.pl':'fixture.pl', 'dependency.pm':'lib/CoordinateDependency.pm',
             'load-body.pl':'load-body.pl', 'require-body.pl':'require-body.pl'}
    source = {dst: committed[str(SOURCE / name)].decode('utf-8') for name, dst in names.items()}
    source_pins = {p: identity(s.encode()) for p, s in source.items()}
    hypotheses = decoded(committed[str(SOURCE / 'hypotheses.json')])
    need(len(wire['runs']) == 2, 'whole saved independent invocation domain')
    result = []
    for index, saved in enumerate(wire['runs']):
        label = ('root-a', 'root-b')[index]
        root = '.artifacts/public-coordinate-native/' + label
        need(saved['invocation'] == {'root':root, 'label':label, 'command':['perl','fixture.pl']},
             'independent exact legitimate invocation recipe')
        need(saved['source'] == source and saved['before'] == source_pins and saved['after'] == source_pins,
             'independent whole committed native source conservation')
        row = saved['actual']
        need(row['command'] == ['perl', 'fixture.pl'] and row['cwd'] == root
             and type(row['status']) is int and row['status'] == 0, 'independent integer native execution and root')
        for stream in ('stdout', 'stderr'):
            need(type(row[stream]) is str and row[stream+'_identity'] == identity(row[stream].encode()),
                 'independent complete native wire bytes')
        payload = decoded(row['stdout'])
        need(list(payload) == ['module_filename', 'observations']
             and [r['role'] for r in payload['observations']] == [r['role'] for r in hypotheses['calls']],
             'independent complete source-declared public observation allocation')
        for observed in payload['observations']:
            need(set(observed) == {'role','frames','trace','guard_ok','guard_error'}
                 and observed['guard_ok'] is None and observed['trace'] and observed['guard_error'],
                 'independent full public trace and caught error')
            for frame in observed['frames']:
                need(len(frame) == 8 and type(frame[2]) is int and frame[2] > 0,
                     'independent raw coordinate integer kind')
        result.append({'invocation': saved['invocation'], 'payload': payload,
                       'source_pins': source_pins, 'wire_identity': identity(row['stdout'].encode())})
    return result


def main():
    producer = ns(CAPTURE / 'verify.py')
    member_paths = list(CAPTURE.iterdir())
    need(all(p.is_file() and not p.is_symlink() for p in member_paths), 'independent regular capture member domain')
    members = {p.name: identity(p.read_bytes()) for p in member_paths if p.name != 'manifest.json'}
    need(members == data(CAPTURE / 'manifest.json'), 'whole independent public capture seal')
    before_members = copy.deepcopy(members)
    raw = subprocess.check_output(['git','archive',REVISION,str(SOURCE),
                                  'docs/audits/coordinate-public-hypotheses-checks-20261007'])
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        committed = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
    binding = data(CAPTURE / 'binding.json')
    expected_pins = {path: identity(body) for path, body in committed.items()}
    need({p: v for root in binding['members'].values() for p, v in root.items()} == expected_pins
         and all(Path(p).read_bytes() == body for p, body in committed.items()),
         'complete independently archived source and actual prerequisite custody')
    need(binding == producer['binding'](), 'whole saved source binding and completed owner')
    wire = data(CAPTURE / 'wire.json')
    expected = producer['derive'](wire)
    need(expected == data(CAPTURE / 'custody.json')
         and expected['runs'] == independent_wire(wire, committed), 'whole independently reconstructed saved public wire custody')
    need(producer['controls'](wire) == data(CAPTURE / 'controls.json'), 'all genuine intended custody control decisions')
    actual(data(BASE / 'capture.json'), ['python3','-B',str(CAPTURE / 'capture.py')],
           'Captured complete public fixtures in both declared roots; selection remains pending.\n')
    actual(data(BASE / 'seal.json'), ['python3','-B',str(CAPTURE / 'verify.py'),'--seal'], producer['SUCCESS'])
    prior_stdout = data(Path('docs/audits/coordinate-public-hypotheses-checks-20261007/saved-result.json'))['stdout']
    actual(data(BASE / 'prerequisite.json'), ['python3','-B','docs/audits/coordinate-public-hypotheses-checks-20261007/verify_saved.py'], prior_stdout)
    refusals = []
    cases = [('Boolean-saved-status', lambda w:w['runs'][0]['actual'].update(status=False), 'independent integer native execution and root'),
             ('float-saved-status', lambda w:w['runs'][0]['actual'].update(status=0.0), 'independent integer native execution and root'),
             ('lost-saved-source', lambda w:w['runs'][1]['after'].pop('fixture.pl'), 'independent whole committed native source conservation'),
             ('borrowed-saved-root', lambda w:w['runs'][0]['invocation'].update(root='../foreign'), 'independent exact legitimate invocation recipe'),
             ('lost-saved-wire-byte', lambda w:w['runs'][1]['actual'].update(stderr=''), 'independent complete native wire bytes')]
    for name, mutate, cause in cases:
        changed = copy.deepcopy(wire); mutate(changed)
        need(json.dumps(changed, sort_keys=True) != json.dumps(wire, sort_keys=True),
             'genuine independent saved result control')
        try:
            independent_wire(changed, committed)
        except ValueError as error:
            need(str(error) == cause, 'intended independent result refusal')
            refusals.append({'control':name, 'status':1, 'cause':cause})
        else:
            raise ValueError('false-green independent saved result control')
    need(before_members == {p.name:identity(p.read_bytes()) for p in CAPTURE.iterdir() if p.name != 'manifest.json'},
         'every immutable source and raw member conserves after qualification')
    print(json.dumps({'members':len(members), 'runs':len(expected['runs']),
                      'observations_per_run':[len(r['payload']['observations']) for r in expected['runs']],
                      'controls':refusals, 'scope':producer['ROLE']}, sort_keys=True))


if __name__ == '__main__':
    main()
