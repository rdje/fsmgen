"""Authenticate and join saved finite public qualification; never run captures."""
import argparse
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-public-qualification-20261008')
CHECKS = Path('docs/audits/coordinate-public-qualification-checks-20261008')
AUDITS = Path('docs/audits')
REVISION = '7a5446252d380e9a6fc784c0b44dc1e9a36d016f'
ROLE = ('Whole dated finite own public caller/boundary/origin and native-control '
        'qualification only. Final publication, original-coordinate intake and '
        'original/private/formatter/toolchain/address identities remain pending.')
SUCCESS = 'PASS complete finite public coordinate qualification, whole actual results and controls; no capture executes or original identity qualifies.\n'
DOMAINS = (
    ('public-hypotheses', 'public-hypotheses', '20261007'),
    ('public-capture', 'public-capture', '20261007'),
    ('public-caller-selection', 'public-caller-selection', '20261007'),
    ('public-origin-hypotheses', 'public-origin-hypotheses', '20261007'),
    ('public-origin-selection', 'public-origin-selection', '20261007'),
    ('native-control-plans', 'native-control-plan', '20261008'),
    ('native-control-capture', 'native-control-capture', '20261008'),
    ('native-semantic', 'native-semantic', '20261008'),
)


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
    result = {'__name__': 'saved_public_qualification_dependency'}
    exec(compile(path.read_bytes(), str(path), 'exec'), result)
    return result


def domain(model, reader, date):
    return (AUDITS / ('record-value-coordinate-' + model + '-' + date),
            AUDITS / ('coordinate-' + reader + '-checks-' + date))


def binding():
    revision = subprocess.check_output(['git', 'rev-parse', REVISION], text=True).strip()
    names = subprocess.check_output(['git', 'ls-tree', '-z', '--name-only',
                                     revision + ':docs/audits']).split(b'\0')
    roots = [str(AUDITS / n.decode()) for n in names
             if n.startswith((b'record-value-coordinate-', b'coordinate-'))]
    archive = subprocess.check_output(['git', 'archive', revision, *roots])
    with tarfile.open(fileobj=io.BytesIO(archive)) as source:
        fixed = {m.name: source.extractfile(m).read() for m in source.getmembers() if m.isfile()}
    current = {}
    for name in roots:
        root = Path(name)
        need(root.is_dir() and not root.is_symlink() and root.stat().st_dev == Path.cwd().stat().st_dev,
             'whole regular same-volume prerequisite root')
        for path in root.iterdir():
            need(path.is_file() and not path.is_symlink() and path.stat().st_dev == Path.cwd().stat().st_dev,
                 'whole regular same-volume prerequisite member')
            current[str(path)] = path.read_bytes()
    need(current == fixed, 'every complete fixed coordinate member conserves')
    task = subprocess.check_output(['git', 'show', revision + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'])
    owners = {}
    for name in roots:
        if '/record-value-' not in name:
            continue
        owner = fixed[name + '/scope.txt'].decode().splitlines()[0].removeprefix('Owner: ')
        suffix = task.decode().split('- ID: `' + owner + '`', 1)[1].split('\n- ID:', 1)[0]
        need('\n  Status: `done`\n' in suffix, 'complete fixed completed coordinate owner')
        owners[owner] = '- ID: `' + owner + '`' + suffix
    return dict(revision=revision, roots=roots, members={p: pin(raw) for p, raw in fixed.items()},
                task_identity=pin(task), owners=owners, role=ROLE)


def receipt(row, script, expected_stdout):
    need(type(row['status']) is int and row['status'] == 0, 'whole public actual integer success')
    paths = [CHECKS / 'run.py', Path('scripts/run_with_ram_guard.sh'), script]
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(script)]
         and row['stdout'] == expected_stdout
         and re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and same(row['instruments'], {str(p): pin(p.read_bytes()) for p in paths}),
         'whole public actual command/streams/instruments')


def actual_results():
    result = []
    for model_name, reader_name, date in DOMAINS:
        model, reader = domain(model_name, reader_name, date)
        producer = namespace(model / 'verify.py')
        primary = load(CHECKS / (model_name + '-model.json'))
        receipt(primary, model / 'verify.py', producer['SUCCESS'])
        saved_name = 'saved-result-qualified.json' if model_name == 'public-capture' else 'saved-result.json'
        historical = load(reader / saved_name)
        need(type(historical['status']) is int and historical['status'] == 0,
             'whole historical independent successful result')
        independent = load(CHECKS / (model_name + '-reader.json'))
        receipt(independent, reader / 'verify_saved.py', historical['stdout'])
        result.append(dict(domain=model_name, model=primary, independent=independent,
                           historical_result=str(reader / saved_name), historical_identity=pin((reader / saved_name).read_bytes())))
    return result


def derive():
    callers = AUDITS / 'record-value-coordinate-public-caller-selection-20261007'
    origins = AUDITS / 'record-value-coordinate-public-origin-selection-20261007'
    native = AUDITS / 'record-value-coordinate-native-semantic-20261008'
    caller_product = namespace(callers / 'verify.py')['derive'](load(callers / 'inputs.json'))
    origin_product = namespace(origins / 'verify.py')['derive'](load(origins / 'inputs.json'))
    native_product = namespace(native / 'verify.py')['derive'](load(native / 'inputs.json'))
    for root, name, expected in ((callers, 'selections.json', caller_product),
                                 (origins, 'selections.json', origin_product),
                                 (native, 'qualification.json', native_product)):
        need(same(load(root / name), expected), 'every complete historical coordinate product rederives')
    need([r['invocation'] for r in caller_product['runs']] == [r['invocation'] for r in origin_product['runs']],
         'whole public caller/origin invocation join')
    return dict(callers=caller_product, origins=origin_product, native=native_product,
                actual_results=actual_results(), role=ROLE)


def check(product, expected):
    need(product['role'] == ROLE, 'finite public qualification cannot promote pending identities')
    need([r['domain'] for r in product['actual_results']] == [row[0] for row in DOMAINS],
         'whole public actual domain allocation')
    for row, (model_name, reader_name, date) in zip(product['actual_results'], DOMAINS):
        model, reader = domain(model_name, reader_name, date)
        receipt(row['model'], model / 'verify.py', namespace(model / 'verify.py')['SUCCESS'])
        saved = 'saved-result-qualified.json' if model_name == 'public-capture' else 'saved-result.json'
        receipt(row['independent'], reader / 'verify_saved.py', load(reader / saved)['stdout'])
    need(same(product, expected), 'whole public selection/ambiguity/refusal and actual result join')


def controls(product):
    # Every full candidate is reproducible from this sealed complete input and
    # these tracked transformations; no raw source or wire is trimmed.
    cases = (
        ('lost-domain', lambda c: c['actual_results'].pop(), 'whole public actual domain allocation'),
        ('Boolean-status', lambda c: c['actual_results'][0]['independent'].update(status=False), 'whole public actual integer success'),
        ('borrowed-programme', lambda c: c['actual_results'][0]['independent']['instruments'].pop(str(domain(*DOMAINS[0])[1] / 'verify_saved.py')),
         'whole public actual command/streams/instruments'),
        ('lost-actual-output', lambda c: c['actual_results'][-1]['independent'].update(stdout=''), 'whole public actual command/streams/instruments'),
        ('lost-equivalent-label', lambda c: c['callers']['runs'][0]['calls'][0]['selection']['matching_line_labels'].pop(),
         'whole public selection/ambiguity/refusal and actual result join'),
        ('lost-native-refusal', lambda c: c['native']['runs'][0].update(intended_refusal=None),
         'whole public selection/ambiguity/refusal and actual result join'),
        ('original-identity-promotion', lambda c: c.update(role='Every original identity qualifies.'),
         'finite public qualification cannot promote pending identities'),
    )
    results = []
    for name, mutate, cause in cases:
        candidate = copy.deepcopy(product); mutate(candidate)
        need(not same(candidate, product), 'genuine whole-public qualification control')
        try:
            check(candidate, product)
        except ValueError as error:
            need(str(error) == cause, 'intended whole-public refusal: ' + name)
            results.append(dict(control=name, status=1, cause=cause,
                                candidate_identity=pin(json.dumps(candidate, sort_keys=True).encode())))
        else:
            raise ValueError('false-green whole-public qualification control: ' + name)
    return results


def members():
    need(all(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev
             for p in BASE.iterdir()), 'whole regular same-volume qualification seal')
    return {p.name: pin(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}


def save(name, value):
    path = BASE / name; raw = json.dumps(value, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained public qualification product: ' + name)
    else:
        need(not (BASE / 'manifest.json').exists(), 'sealed public qualification cannot publish')
        path.write_text(raw)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seal', action='store_true'); args = parser.parse_args()
    if (BASE / 'manifest.json').exists():
        need(same(load(BASE / 'manifest.json'), members()), 'whole immutable public qualification seal')
    before = binding(); save('binding.json', before)
    product = derive(); check(product, product)
    save('qualification.json', product); save('controls.json', controls(product))
    need(same(binding(), before), 'every complete coordinate prerequisite conserves after qualification')
    if args.seal:
        save('manifest.json', members())
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
