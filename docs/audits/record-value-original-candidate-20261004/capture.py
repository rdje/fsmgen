"""Capture unchanged original T1986 in fresh same-volume native fixtures.

This runner records observations. Independent semantic qualification belongs
in the successor; never invoke this producer into a sealed capture directory.
"""
import base64
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

BASE = Path('docs/audits/record-value-original-candidate-20261004')
INPUTS = Path('docs/audits/record-value-copy-inputs-20261004')
PIN = Path('docs/audits/record-value-original-replay-20261004')
PROBES = Path('docs/audits/record-value-copy-probes-20261004')
JOIN = Path('docs/audits/record-value-copy-probe-join-20261004')
PREFIX = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.'


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def native_bytes(row):
    return row['body'].encode() if 'body' in row else base64.b64decode(row['body_b64'], validate=True)


def load(path):
    return json.loads(path.read_text())


def save(name, data):
    (BASE / name).write_text(json.dumps(data, sort_keys=True, indent=2) + '\n')


def sealed(directory):
    manifest = load(directory / 'manifest.json')
    assert {p.name for p in directory.iterdir()} == set(manifest) | {'manifest.json'}
    for name, expected in manifest.items():
        assert identity((directory / name).read_bytes()) == expected, name
    return manifest


assert not (BASE / 'manifest.json').exists(), 'sealed producers never rerun in place'
assert not (BASE / 'execution.json').exists(), 'native evidence is never overwritten'
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
original = load(INPUTS / 'binding.json')
pin = load(PIN / 'binding.json')
archives = {str(path): sealed(path) for path in (INPUTS, PIN, PROBES, JOIN)}
assert (BASE / 'candidate.pl').read_bytes() == (PROBES / 'candidate.pl').read_bytes()
# Each full original selected source and each own runtime body has Git authority.
sources = original['sources']
runtime = {}
for path, expected in pin['runtime'].items():
    raw = subprocess.check_output(['git', 'show', revision + ':' + path])
    assert identity(raw) == expected == identity(Path(path).read_bytes()), path
    runtime[path] = {'body_b64': base64.b64encode(raw).decode(), **identity(raw)}
for path, row in sources.items():
    raw = subprocess.check_output(['git', 'show', original['revision'] + ':' + path])
    assert row == {'body': raw.decode(), **identity(raw)}, path
    if path.startswith(('perl/', 't/')):
        assert Path(path).read_bytes() == raw, 'unchanged original source: ' + path
context = subprocess.check_output(['git', 'show', revision + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'], text=True)
owners = []
for owner in (PREFIX + '2.1', PREFIX + '2.2', PREFIX + '2.3.1'):
    start = context.index('- ID: `' + owner + '`')
    end = context.index('\n- ID:', start + 1)
    body = context[start:end]
    assert '\n  Status: `done`\n' in body, owner
    owners.append({'id': owner, 'body': body})
support = {}
support_paths = subprocess.check_output(['git', 'ls-files', 'bin', 'specs', 'plugin'], text=True).splitlines()
for path in ('README.md', *support_paths):
    raw = subprocess.check_output(['git', 'show', revision + ':' + path])
    support[path] = {'body_b64': base64.b64encode(raw).decode(), **identity(raw)}
binding = {'revision': revision, 'original_revision': original['revision'],
           'sources': sources, 'runtime': runtime, 'support': support,
           'task_path': 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md',
           'task_body': context, 'owners': owners, 'archives': archives}
save('binding.json', binding)
root = Path.cwd().resolve()
scratch = Path('.artifacts/record-value-original-candidate-20261004')
scratch.mkdir(parents=True, exist_ok=True)
assert scratch.resolve().is_relative_to(root) and scratch.stat().st_dev == root.stat().st_dev
programs = {name: {'body': (BASE / name).read_text(), **identity((BASE / name).read_bytes())}
            for name in ('observe.pl', 'candidate.pl')}
execution = {'python': sys.version, 'programs': programs,
             'producer': {'body': Path(__file__).read_text(), **identity(Path(__file__).read_bytes())}, 'modes': []}
save('execution.json', execution)
for mode in ('ordinary', 'storable', 'alias', 'controls'):
    fixture = Path(tempfile.mkdtemp(prefix=mode + '-', dir=scratch)).resolve().relative_to(root)
    assert fixture.stat().st_dev == root.stat().st_dev
    fixture_sources = {**runtime, **sources, **support,
                       **{str(BASE / name): row for name, row in programs.items()}}
    for path, row in fixture_sources.items():
        destination = fixture / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(native_bytes(row))
    command = ['perl', str(BASE / 'observe.pl'), mode, str(BASE / (mode + '.json'))]
    run = subprocess.run(command, cwd=fixture, text=True, capture_output=True, timeout=60)
    row = {'mode': mode, 'fixture': str(fixture), 'same_volume': True,
           'command': command, 'status': run.returncode,
           'stdout': run.stdout, 'stderr': run.stderr,
           'sources_before': {path: identity(native_bytes(value)) for path, value in fixture_sources.items()},
           'sources_after': {path: identity((fixture / path).read_bytes()) for path in fixture_sources}}
    destination = fixture / BASE / (mode + '.json')
    row['captured'] = destination.exists()
    if destination.exists():
        raw = destination.read_bytes()
        (BASE / (mode + '.json')).write_bytes(raw)
        row['record_identity'] = identity(raw)
    execution['modes'].append(row)
    save('execution.json', execution)  # Keep first failures and raw streams.
    assert row['captured'], run.stdout + run.stderr
    assert row['sources_before'] == row['sources_after'], 'complete fixture source afterimage'
    print(mode + ': native status ' + str(run.returncode) + '; full capture retained', flush=True)
assert all(identity(Path(path).read_bytes()) == {key: value[key] for key in ('bytes', 'sha256')}
           for path, value in runtime.items()), 'primary runtime afterimage'
print('PASS four real original-source modes captured; independent semantics remain pending.')
