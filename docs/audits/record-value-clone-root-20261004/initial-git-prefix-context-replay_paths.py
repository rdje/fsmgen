"""Reexecute the completed relative-command native proof in its dated context."""
import argparse
import ast
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/record-value-clone-root-20261004')
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
old = Path('docs/audits/record-value-clone-paths-20261004')
binding = json.loads((old / 'binding.json').read_text())
current = json.loads((BASE / 'binding.json').read_text())
fixture = Path('.artifacts/record-value-clone-root-path-replay-20261004')
documents = {row['path']: row['after'] for row in json.loads((old / 'doc-updates.json').read_text())}
for path, row in binding['sources'].items():
    if path not in documents:
        assert row['body'] == current['sources'][path]['body']
    if path.startswith(('perl/', 't/lib/')):
        assert Path(path).read_text() == row['body']
        continue
    destination = fixture / path
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(documents.get(path, row['body']))
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
(fixture / task_path).parent.mkdir(parents=True, exist_ok=True)
(fixture / task_path).write_bytes(Path(task_path).read_bytes())
for path in ('docs/audits', 'scripts', 'perl', 't/lib'):
    link = fixture / path
    target = os.path.relpath(Path.cwd() / path, Path.cwd() / link.parent)
    if link.is_symlink():
        assert os.readlink(link) == target
    else:
        assert not link.exists()
        link.symlink_to(target, target_is_directory=True)
inputs = {path: {'bytes': len((fixture / path).read_bytes()), 'sha256': hashlib.sha256((fixture / path).read_bytes()).hexdigest()} for path in binding['sources']}
tree = ast.parse(Path('docs/audits/record-value-replay-portability-20261004/portable_replay.py').read_text())
functions = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in ('frames', 'qualified', 'historical')]
assert {node.name for node in functions} == {'frames', 'qualified', 'historical'}
helpers = {'re': re, 'Path': Path}
exec(compile(ast.Module(body=functions, type_ignores=[]), 'bound exact Python file-coordinate helpers', 'exec'), helpers)
relative = str(old / 'portability.py')
controls = {row['command'][-1]: row for row in json.loads((old / 'portability-controls.json').read_text())}
receipts = []
for flag in (None, '--absolute-command', '--wrong-file', '--wrong-cause', '--root-echo'):
    command = ['python3', '-B', relative] + ([flag] if flag else [])
    run = subprocess.run(command, cwd=fixture, text=True, capture_output=True)
    assert run.returncode == (1 if flag else 0), run.stdout + run.stderr
    output = helpers['qualified'](run.stdout + run.stderr, str(Path.cwd() / fixture / relative), relative)
    if flag:
        prior = controls[flag]
        assert prior['command'] == command and prior['status'] == run.returncode
        assert output == helpers['historical'](prior['output'], relative), 'whole actual portability semantic/control output beyond bound process filename'
    else:
        prior = subprocess.check_output(['git', 'show', current['revision'] + ':docs/audits/record-value-clone-paths-checks-20261004/ordinary.txt']).decode()
        assert prior.splitlines()[0].startswith('ram-guard: PID ')
        assert output == '\n'.join(prior.splitlines()[1:]) + '\n'
    receipts.append({'command': command, 'working_directory': str(fixture), 'inputs': inputs, 'status': run.returncode, 'output': output})
packet = {'python': sys.version, 'source_revision': binding['revision'], 'receipts': receipts}
if args.check:
    assert packet == json.loads((BASE / 'path-replays.json').read_text()), 'whole dated source/doc/runtime/Python/status/native/control output replay identity'
else:
    (BASE / 'path-replays.json').write_text(json.dumps(packet, sort_keys=True, indent=2) + '\n')
print('PASS full relative-command native proof ordinary/all four portable RED controls reexecute exact dated source/doc/owner/runtime contexts, including both real native roots/all ten native RED proofs and full8251 joint/native records. Only exact invoked Python File-frame filename qualifies.')
