"""Independently consume the full fixed-source join and every fresh actual result."""
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-qualification-checks-20261008')
MODEL = Path('docs/audits/record-value-coordinate-public-qualification-20261008')
REVISION = '7a5446252d380e9a6fc784c0b44dc1e9a36d016f'
ROLE = ('Whole dated finite own public caller/boundary/origin and native-control '
        'qualification only. Final publication, original-coordinate intake and '
        'original/private/formatter/toolchain/address identities remain pending.')
SUCCESS = 'PASS independent complete public source/wire/result qualification and genuine controls; no original identity or capture execution.\n'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def read(path):
    return json.loads(path.read_bytes())


def namespace(raw, path):
    result = {'__name__': 'independent_fixed_coordinate_reader'}
    exec(compile(raw, path, 'exec'), result)
    return result


def fixed_source():
    revision = subprocess.check_output(['git', 'rev-parse', REVISION], text=True).strip()
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision, 'docs/audits'], text=True).splitlines()
    selected = [p for p in paths if p.split('/')[2].startswith(('coordinate-', 'record-value-coordinate-'))]
    roots = sorted({str(Path(p).parent) for p in selected})
    raw = subprocess.check_output(['git', 'archive', revision, *selected])
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        fixed = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
    current = {}
    for root in roots:
        directory = Path(root)
        need(directory.is_dir() and not directory.is_symlink() and directory.stat().st_dev == Path.cwd().stat().st_dev,
             'independent same-volume source root')
        for path in directory.iterdir():
            need(path.is_file() and not path.is_symlink() and path.stat().st_dev == Path.cwd().stat().st_dev,
                 'independent regular same-volume source member')
            current[str(path)] = path.read_bytes()
    need(current == fixed, 'independent entire committed coordinate source census')
    task = subprocess.check_output(['git', 'show', revision + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'])
    nodes = {m.group(1): m.group(0) for m in re.finditer(r'^- ID: `([^`]+)`\n.*?(?=^\n- ID:|\Z)', task.decode(), re.M | re.S)}
    owners = {}
    for root in roots:
        if '/record-value-' in root:
            owner = fixed[root + '/scope.txt'].decode().splitlines()[0][len('Owner: '):]
            body = nodes[owner]
            need('\n  Status: `done`\n' in body, 'independent completed coordinate owner')
            # The producer's split includes the blank separator before the next
            # ID. Retrieve that exact body while owner membership comes from the
            # separate anchored whole-node census above.
            suffix = task.decode().split('- ID: `' + owner + '`', 1)[1].split('\n- ID:', 1)[0]
            owners[owner] = '- ID: `' + owner + '`' + suffix
    expected = dict(revision=revision, roots=roots, members={p: pin(raw) for p, raw in fixed.items()},
                    task_identity=pin(task), owners=owners, role=ROLE)
    need(same(read(MODEL / 'binding.json'), expected), 'independent whole member/owner/capture-boundary binding')
    return fixed


def reconstruct(fixed):
    def archive_json(path):
        return json.loads(fixed[path])

    results = {}
    for name, product in (('public-caller-selection', 'callers'), ('public-origin-selection', 'origins')):
        root = 'docs/audits/record-value-coordinate-' + name + '-20261007/'
        reader = 'docs/audits/coordinate-' + name + '-checks-20261007/verify_saved.py'
        oracle = namespace(fixed[reader], reader)
        results[product] = oracle['reconstruct'](archive_json(root + 'inputs.json'), fixed)
    native = 'docs/audits/record-value-coordinate-native-semantic-20261008/'
    reader = 'docs/audits/coordinate-native-semantic-checks-20261008/verify_saved.py'
    oracle = namespace(fixed[reader], reader)
    results['native'] = oracle['reconstruct'](archive_json(native + 'inputs.json'))
    # Independent binary/LF/header oracles above rebuild every source-selected
    # coordinate and ambiguity without calling the join's producer predicates.
    return dict(**results, role=ROLE)


def actual_rows(fixed):
    rows = []
    # These contracts select source, custody, selection, before-native plans and
    # actual semantic meanings. They never select capture.py.
    names = ['public-hypotheses', 'public-capture', 'public-caller-selection',
             'public-origin-hypotheses', 'public-origin-selection',
             'native-control-plans', 'native-control-capture', 'native-semantic']
    for name in names:
        date = '20261008' if name.startswith('native') else '20261007'
        reader_name = 'native-control-plan' if name == 'native-control-plans' else name
        model_script = 'docs/audits/record-value-coordinate-' + name + '-' + date + '/verify.py'
        reader_script = 'docs/audits/coordinate-' + reader_name + '-checks-' + date + '/verify_saved.py'
        historical_path = str(Path(reader_script).parent / ('saved-result-qualified.json' if name == 'public-capture' else 'saved-result.json'))
        historical = json.loads(fixed[historical_path])
        need(type(historical['status']) is int and historical['status'] == 0,
             'independent historical reader success')
        model_success = namespace(fixed[model_script], model_script)['SUCCESS']
        actuals = {}
        for label, script, stdout in (('model', model_script, model_success),
                                       ('independent', reader_script, historical['stdout'])):
            suffix = 'model' if label == 'model' else 'reader'
            actual = read(BASE / (name + '-' + suffix + '.json'))
            check_receipt(actual, script, stdout, fixed)
            actuals[label] = actual
        rows.append(dict(domain=name, **actuals, historical_result=historical_path,
                         historical_identity=pin(fixed[historical_path])))
    need(sorted(p.name for p in BASE.glob('*-model.json') if not p.name.startswith('first-'))
         == sorted(name + '-model.json' for name in names)
         and sorted(p.name for p in BASE.glob('*-reader.json')) == sorted(name + '-reader.json' for name in names),
         'independent complete actual reader census')
    return rows


def check_receipt(row, script, stdout, fixed):
    need(type(row['status']) is int and row['status'] == 0, 'independent actual status integer success')
    instruments = {str(BASE / 'run.py'): pin((BASE / 'run.py').read_bytes()),
                   'scripts/run_with_ram_guard.sh': pin(Path('scripts/run_with_ram_guard.sh').read_bytes()),
                   script: pin(fixed[script])}
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', script]
         and row['stdout'] == stdout and same(row['instruments'], instruments)
         and re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr']),
         'independent entire actual command/streams/programme custody')


def check(product, expected):
    need(product['role'] == ROLE, 'independent whole public scope preserves identity gaps')
    need([r['domain'] for r in product['actual_results']] == [r['domain'] for r in expected['actual_results']],
         'independent complete source/reader/result allocation')
    need(all(type(r[k]['status']) is int and r[k]['status'] == 0
             for r in product['actual_results'] for k in ('model', 'independent')),
         'independent whole result statuses remain integer success')
    need(same(product, expected), 'independent complete binary-source/raw-wire/result join')


def main():
    files = list(MODEL.iterdir())
    need(all(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev for p in files),
         'independent regular same-volume whole-public seal')
    members = {p.name: pin(p.read_bytes()) for p in files if p.name != 'manifest.json'}
    need(same(read(MODEL / 'manifest.json'), members), 'independent immutable whole-public seal')
    fixed = fixed_source()
    expected = dict(**reconstruct(fixed), actual_results=actual_rows(fixed))
    product = read(MODEL / 'qualification.json'); check(product, expected)
    controls = []
    cases = (
        ('lost-actual-domain', lambda c: c['actual_results'].pop(), 'independent complete source/reader/result allocation'),
        ('Boolean-result', lambda c: c['actual_results'][0]['model'].update(status=False), 'independent whole result statuses remain integer success'),
        ('borrowed-result', lambda c: c['actual_results'][0].update(independent=c['actual_results'][-1]['independent']), 'independent complete binary-source/raw-wire/result join'),
        ('lost-equivalent-label', lambda c: c['callers']['runs'][0]['calls'][0]['selection']['matching_line_labels'].pop(), 'independent complete binary-source/raw-wire/result join'),
        ('changed-origin', lambda c: c['origins']['runs'][0]['cases'][0]['origins']['trace'].update(line=1), 'independent complete binary-source/raw-wire/result join'),
        ('lost-refusal', lambda c: c['native']['runs'][0].update(intended_refusal=None), 'independent complete binary-source/raw-wire/result join'),
        ('false-root-coordinate', lambda c: c['native']['runs'][2]['coordinates']['calls'][0]['result'].update(status='refused'), 'independent complete binary-source/raw-wire/result join'),
        ('original-promotion', lambda c: c.update(role='Original identities are known.'), 'independent whole public scope preserves identity gaps'),
    )
    for name, mutate, cause in cases:
        candidate = copy.deepcopy(product); mutate(candidate)
        need(not same(candidate, product), 'genuine independently reconstructed join control')
        try:
            check(candidate, expected)
        except ValueError as error:
            need(str(error) == cause, 'intended independent whole-public refusal: ' + name)
            controls.append(dict(control=name, status=1, cause=cause,
                                 candidate_identity=pin(json.dumps(candidate, sort_keys=True).encode())))
        else:
            raise ValueError('false-green independent whole-public control: ' + name)
    proof = dict(members=members, controls=controls, binding=pin((MODEL / 'binding.json').read_bytes()),
                 reconstruction=pin(json.dumps(expected, sort_keys=True).encode()), role=ROLE,
                 oracle_programmes={p: pin(fixed[p]) for p in fixed if p.endswith('/verify_saved.py')})
    path = BASE / 'proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained independent public qualification proof')
    else:
        path.write_text(raw)
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
