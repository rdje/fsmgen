"""Authenticate dated complete public wire custody without choosing coordinates."""
import argparse
import copy
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-public-capture-20261007')
SOURCE = Path('docs/audits/record-value-coordinate-public-hypotheses-20261007')
REVISION = '0f597fbb50a7632a18fb9464c1985645dccadaf0'
ROOTS = [SOURCE, Path('docs/audits/coordinate-public-hypotheses-checks-20261007')]
ROLE = ('Dated current public fixture source/wire custody only. Raw coordinates and complete '
        'errors are preserved; line/filename selection, original-coordinate joins and '
        'original/private/formatter/toolchain identity remain unqualified.')
SUCCESS = 'PASS complete public fixture wire custody and genuine controls; coordinate selection remains pending.\n'


def require(value, cause):
    if not value:
        raise ValueError(cause)


def same(left, right):
    return json.dumps(left, sort_keys=True) == json.dumps(right, sort_keys=True)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def load(path):
    return json.loads(path.read_bytes())


def module(path):
    namespace = {'__name__': 'public_capture_dependency'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def binding():
    members = {}
    for root in ROOTS:
        paths = list(root.iterdir())
        require(all(p.is_file() and not p.is_symlink() for p in paths), 'complete flat regular public prerequisite domain')
        raw = subprocess.check_output(['git', 'archive', REVISION, str(root)])
        with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
            original = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
        require({str(p): p.read_bytes() for p in paths} == original,
                'complete fixed committed public hypothesis/programme/actual members')
        members[str(root)] = {p: pin(body) for p, body in original.items()}
    owner = (SOURCE / 'scope.txt').read_text().splitlines()[0].removeprefix('Owner: ')
    task = subprocess.check_output(['git', 'show', REVISION + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md']).decode()
    start = task.index('- ID: `' + owner + '`'); end = task.index('\n- ID:', start + 1)
    body = task[start:end]
    require('\n  Status: `done`\n' in body, 'complete committed completed pre-native owner')
    prior = module(SOURCE / 'verify.py')
    hypotheses = prior['derive'](prior['source_inputs']())
    require(same(hypotheses, load(SOURCE / 'hypotheses.json')), 'complete unchanged source-declared unselected hypotheses')
    require(all(row['selected_line'] is None and row['selected_filename'] is None for row in hypotheses['calls']),
            'pre-native alternatives must remain unselected')
    return dict(revision=REVISION, members=members, owner=body, task_identity=pin(task.encode()), role=ROLE)


def check_actual(row, command, cwd):
    require(row['command'] == command and row['cwd'] == cwd,
            'exact public native command and legitimate invocation root')
    require(type(row['status']) is int and row['status'] == 0, 'integer actual public native success')
    for field in ('stdout', 'stderr'):
        require(type(row[field]) is str and same(row[field + '_identity'], pin(row[field].encode())),
                'whole actual public wire byte identity')


def derive(wire):
    source = load(SOURCE / 'inputs.json')
    hypotheses = load(SOURCE / 'hypotheses.json')
    require(wire['scope'] == 'Dated current public fixture wire only; line/filename recipes and original-coordinate identity remain unqualified.',
            'dated custody cannot promote coordinate or original identity meaning')
    require(same(wire['capture_programme'], pin((BASE / 'capture.py').read_bytes())), 'whole native producing instrument identity')
    require(len(wire['runs']) == len(source['invocations']), 'complete declared native invocation population')
    capture = module(BASE / 'capture.py')
    for name, command in (('version', ['perl', '-V']), ('modules', capture['METADATA'])):
        check_actual(wire['tools'][name], command, source['invocations'][0]['root'])
    require(type(wire['tools']['executable_identity']['bytes']) is int
            and wire['tools']['executable_identity']['bytes'] > 0
            and len(wire['tools']['executable_identity']['sha256']) == 64, 'dated executable byte identity')
    modules = json.loads(wire['tools']['modules']['stdout'])
    require(set(modules) == {'perl', 'json_pp', 'carp', 'test_more'} and all(type(v) is str for v in modules.values()),
            'whole dated public module version metadata')
    products = []
    for saved, invocation in zip(wire['runs'], source['invocations']):
        require(same(saved['invocation'], invocation), 'complete declared invocation identity and order')
        check_actual(saved['actual'], invocation['command'], invocation['root'])
        require(same(saved['source'], source['source']), 'complete independently committed executed own sources')
        require(same(saved['before'], source['source_pins']) and same(saved['after'], source['source_pins']),
                'every complete native fixture source member conserves')
        require(saved['environment'] == dict(PERL5OPT='', PERL5LIB='',
                    temporary_root=invocation['root'] + '/.tmp', runtime_absolute_temporary_values=True),
                'exact same-volume native temporary and public interpreter environment recipe')
        payload = json.loads(saved['actual']['stdout'])
        require(set(payload) == {'observations', 'module_filename'}
                and type(payload['module_filename']) is str and payload['module_filename'], 'complete public wire payload domain')
        expected_roles = [r['role'] for r in hypotheses['calls']]
        require([r['role'] for r in payload['observations']] == expected_roles,
                'complete independently source-declared own observation allocation')
        for row in payload['observations']:
            require(set(row) == {'role', 'frames', 'trace', 'guard_ok', 'guard_error'}
                    and row['guard_ok'] is None
                    and type(row['trace']) is str and row['trace']
                    and type(row['guard_error']) is str and row['guard_error'], 'whole public observation and caught error wire')
            require(type(row['frames']) is list and row['frames'], 'nonempty complete public caller frame wire')
            for frame in row['frames']:
                require(type(frame) is list and len(frame) == 8
                        and all(type(frame[i]) is str for i in (0, 1, 3))
                        and type(frame[2]) is int and frame[2] > 0, 'raw public frame shape and integer coordinate kind')
        products.append(dict(invocation=invocation, wire_identity=pin(saved['actual']['stdout'].encode()),
                             payload=payload, source_pins=saved['before']))
    return dict(runs=products, tools=wire['tools'], role=ROLE)


def controls(wire):
    mutations = [
        ('Boolean-native-status', lambda w: w['runs'][0]['actual'].update(status=False), 'integer actual public native success'),
        ('float-native-status', lambda w: w['runs'][0]['actual'].update(status=0.0), 'integer actual public native success'),
        ('nonzero-native-status', lambda w: w['runs'][0]['actual'].update(status=1), 'integer actual public native success'),
        ('lost-public-run', lambda w: w['runs'].pop(), 'complete declared native invocation population'),
        ('borrowed-invocation', lambda w: w['runs'][0]['invocation'].update(root='../borrowed'), 'complete declared invocation identity and order'),
        ('borrowed-command-root', lambda w: w['runs'][0]['actual'].update(cwd='../borrowed'), 'exact public native command and legitimate invocation root'),
        ('lost-wire-byte', lambda w: w['runs'][0]['actual'].update(stdout=w['runs'][0]['actual']['stdout'][:-1]), 'whole actual public wire byte identity'),
        ('borrowed-source', lambda w: w['runs'][0]['source'].update({'fixture.pl':w['runs'][0]['source']['load-body.pl']}), 'complete independently committed executed own sources'),
        ('lost-source-member', lambda w: w['runs'][0]['after'].pop('require-body.pl'), 'every complete native fixture source member conserves'),
        ('borrowed-instrument', lambda w: w['capture_programme'].update(sha256='0' * 64), 'whole native producing instrument identity'),
        ('original-identity-promotion', lambda w: w.update(scope='Original coordinate and toolchain identities are qualified.'), 'dated custody cannot promote coordinate or original identity meaning'),
    ]
    refusals = []
    for name, mutate, cause in mutations:
        changed = copy.deepcopy(wire); mutate(changed)
        require(not same(changed, wire), 'genuine public wire custody control')
        try:
            derive(changed)
        except ValueError as error:
            require(str(error) == cause, 'intended public custody refusal: ' + name)
            refusals.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green public custody control: ' + name)
    return refusals


def members():
    require(all(p.is_file() and not p.is_symlink() for p in BASE.iterdir()), 'whole regular flat public capture member domain')
    return {p.name: pin(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}


def save(name, value):
    path = BASE / name
    encoded = json.dumps(value, sort_keys=True, indent=2) + '\n'
    if path.exists():
        require(path.read_text() == encoded, 'whole saved public capture product: ' + name)
    else:
        require(not (BASE / 'manifest.json').exists(), 'sealed public capture cannot publish')
        path.write_text(encoded)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    if (BASE / 'manifest.json').exists():
        require(same(load(BASE / 'manifest.json'), members()), 'whole immutable native public capture seal')
    before = binding(); save('binding.json', before)
    wire = load(BASE / 'wire.json')
    save('custody.json', derive(wire)); save('controls.json', controls(wire))
    require(same(binding(), before), 'every complete pre-native prerequisite conserves')
    if args.seal:
        save('manifest.json', members())
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
