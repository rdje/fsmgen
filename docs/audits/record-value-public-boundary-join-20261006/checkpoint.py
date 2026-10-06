"""Authenticate saved executions against unchanged committed audit inputs.

This is an explicit replay scope, not a claim that the prerequisites ran again.
Current models, joins, controls and native guide checks still execute afresh.
"""
import ast
import copy
import io
import json
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/record-value-public-boundary-join-20261006')
REVISION = 'af4999e7308865968f69ff5ec72591dc24101fd1'
ROLE = 'Saved actual full prerequisites at the committed checkpoint; no fresh prerequisite execution is claimed.'
SNAPSHOTS = ('binding.json', 'model.py', 'pre-native-models.json', 'proofs.json',
             'prerequisite-replays.json', 'initial-reader.py.txt', 'initial-reader-result.json')
FUNCTIONS = ('module', 'models', 'public_arguments', 'check', 'controls')
SUCCESSES = (
    'PASS complete finite own parser/API/observer/helper/subtest context join and completed nested allocations; opaque native meanings remain open.\n',
    'PASS actual sealed replay, complete file pins, source/context/control regeneration and typed receipt refusals.\n',
    'PASS finite independent public callback/eval/load/trace roles and genuine source/native controls; historical/private identities remain open.\n',
    'PASS actual public fixture seal, complete source/native/first/guide regeneration and typed/borrowed-result refusals.\n',
)


def directories(namespace):
    """Enumerate the loaded source-model namespaces' declared audit inputs.

    The model includes its dynamically selected product/capture roots in these
    namespaces. Installed tools are not replayed in this saved-profile mode.
    """
    seen, result = set(), set()

    def visit(value):
        if id(value) in seen:
            return
        seen.add(id(value))
        if isinstance(value, Path) and str(value).startswith('docs/audits/'):
            if value.is_dir():
                result.add(value)
            elif value.is_file():
                result.add(value.parent)
        elif isinstance(value, dict):
            for key, child in value.items():
                if key != '__builtins__':
                    visit(child)
        elif isinstance(value, (list, tuple)):
            for child in value:
                visit(child)

    visit(namespace)
    return sorted(result - {BASE}, key=str)


def committed(directory):
    raw = subprocess.check_output(['git', 'archive', REVISION, str(directory)])
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        return {entry.name: archive.extractfile(entry).read()
                for entry in archive.getmembers() if entry.isfile()}


def derive(namespace):
    require, same, identity = (namespace[k] for k in ('require', 'same', 'identity'))
    snapshots, inputs = {}, {}
    for name in SNAPSHOTS:
        path = BASE / name
        original = subprocess.check_output(['git', 'show', REVISION + ':' + str(path)])
        require(path.read_bytes() == original, 'unchanged whole checkpoint programme/product/actual receipt: ' + name)
        snapshots[name] = identity(original)
    for directory in directories(namespace):
        paths = list(directory.iterdir())
        require(all(p.is_file() and not p.is_symlink() for p in paths),
                'regular complete transitive checkpoint input population')
        actual = {str(p): p.read_bytes() for p in paths}
        original = committed(directory)
        require(actual == original, 'unchanged whole transitive checkpoint inputs: ' + str(directory))
        inputs[str(directory)] = {path: identity(raw) for path, raw in original.items()}
    initial = ast.parse((BASE / 'initial-reader.py.txt').read_text())
    current = ast.parse((BASE / 'verify.py').read_text())
    for name in FUNCTIONS:
        before = next(n for n in initial.body if isinstance(n, ast.FunctionDef) and n.name == name)
        after = next(n for n in current.body if isinstance(n, ast.FunctionDef) and n.name == name)
        require(ast.dump(before) == ast.dump(after), 'unchanged reexecuted semantic programme: ' + name)
    return dict(revision=REVISION, role=ROLE, snapshots=snapshots, inputs=inputs,
                unchanged_semantic_functions=list(FUNCTIONS))


def check_binding(candidate, expected, require, same):
    require(set(candidate) == set(expected) and candidate['revision'] == REVISION and candidate['role'] == ROLE,
            'exact committed checkpoint and saved execution scope')
    require(all(type(pin['bytes']) is int and pin['bytes'] >= 0
                for members in candidate['inputs'].values() for pin in members.values()),
            'checkpoint input discrete byte-count kind')
    require(same(candidate, expected), 'complete unchanged checkpoint input/member/programme binding')


def check_receipts(rows, namespace):
    require = namespace['require']
    require(len(rows) == len(namespace['DIRECTORIES']), 'complete saved actual prerequisite population')
    for row, directory, success in zip(rows, namespace['DIRECTORIES'], SUCCESSES, strict=True):
        programme = directory / ('verify_seal.py' if directory in
                    (namespace['CONTEXT_CHECKS'], namespace['FIXTURE_CHECKS']) else 'verify.py')
        require(set(row) == {'command', 'status', 'stdout', 'stderr'} and
                row['command'] == ['python3', '-B', str(programme)] and row['stdout'] == success and row['stderr'] == '',
                'exact saved actual prerequisite command/result')
        require(type(row['status']) is int and row['status'] == 0, 'saved prerequisite integer success')
    initial = namespace['load'](BASE / 'initial-reader-result.json')
    require(initial['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py')]
            and type(initial['status']) is int and initial['status'] == 0 and
            initial['stdout'] == namespace['SUCCESS'] and initial['stderr'].startswith('ram-guard: PID '),
            'actual initial full source/public/core replay under unchanged guard')


def qualify(namespace):
    expected = derive(namespace)
    check_binding(namespace['load'](BASE / 'checkpoint-inputs.json'), expected,
                  namespace['require'], namespace['same'])
    rows = namespace['load'](BASE / 'prerequisite-replays.json')
    check_receipts(rows, namespace)
    return rows


def controls(namespace):
    require, same, load = (namespace[k] for k in ('require', 'same', 'load'))
    expected = derive(namespace)
    binding = load(BASE / 'checkpoint-inputs.json')
    check_binding(binding, expected, require, same)
    rows = load(BASE / 'prerequisite-replays.json')
    check_receipts(rows, namespace)
    result = []

    def refuse(name, candidate, cause, checker):
        try:
            checker(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended checkpoint refusal: ' + name)
            result.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green checkpoint control: ' + name)

    changed = copy.deepcopy(binding); changed['revision'] = '0' * 40
    refuse('borrowed-checkpoint', changed, 'exact committed checkpoint and saved execution scope',
           lambda value: check_binding(value, expected, require, same))
    changed = copy.deepcopy(binding); changed['inputs'].pop(next(iter(changed['inputs'])))
    refuse('lost-transitive-input-root', changed, 'complete unchanged checkpoint input/member/programme binding',
           lambda value: check_binding(value, expected, require, same))
    changed = copy.deepcopy(binding)
    pin = next(iter(next(iter(changed['inputs'].values())).values())); pin['bytes'] = True
    refuse('boolean-input-byte-count', changed, 'checkpoint input discrete byte-count kind',
           lambda value: check_binding(value, expected, require, same))
    changed = copy.deepcopy(binding)
    pin = next(iter(next(iter(changed['inputs'].values())).values())); pin['sha256'] = '0' * 64
    refuse('changed-transitive-member', changed, 'complete unchanged checkpoint input/member/programme binding',
           lambda value: check_binding(value, expected, require, same))
    for status in (True, 0.0, 1):
        changed = copy.deepcopy(rows); changed[0]['status'] = status
        refuse('saved-prerequisite-status-' + repr(status), changed, 'saved prerequisite integer success',
               lambda value: check_receipts(value, namespace))
    changed = copy.deepcopy(rows); changed[0] = copy.deepcopy(rows[2])
    refuse('borrowed-public-only-prerequisite', changed, 'exact saved actual prerequisite command/result',
           lambda value: check_receipts(value, namespace))
    return dict(scope=ROLE, controls=result)
