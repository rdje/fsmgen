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

BASE = Path('docs/audits/record-value-clone-tree-20261004')
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
old = Path('docs/audits/record-value-clone-root-20261004')
binding = json.loads((old / 'binding.json').read_text())
current = json.loads((BASE / 'binding.json').read_text())
fixture = Path('.artifacts/record-value-clone-tree-root-replay-20261004')
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
relative = str(old / 'verify.py')
controls = {row['command'][-1]: row for row in json.loads((old / 'controls.json').read_text())}
receipts = []
for flag in (None, '--omit-root', '--wrong-role', '--same-type-source', '--numeric-preparation'):
    command = ['python3', '-B', relative] + ([flag] if flag else [])
    environment = dict(os.environ)
    environment['GIT_DIR'] = subprocess.check_output(['git', 'rev-parse', '--absolute-git-dir']).decode().strip()
    environment['GIT_WORK_TREE'] = str(Path.cwd() / fixture)
    # The same project metadata is read only; no synthetic Git repository or
    # index mutation is created. Pathspecs must address the fixture root rather
    # than its ancestor-repository subdirectory prefix.
    run = subprocess.run(command, cwd=fixture, env=environment, text=True, capture_output=True)
    assert run.returncode == (1 if flag else 0), run.stdout + run.stderr
    output = helpers['qualified'](run.stdout + run.stderr, str(Path.cwd() / fixture / relative), relative)
    if flag:
        prior = controls[flag]
        assert prior['command'] == command and prior['status'] == run.returncode
        assert output == helpers['historical'](prior['output'], relative), 'whole actual source-root semantic/control output beyond bound process filename'
    else:
        prior = subprocess.check_output(['git', 'show', current['revision'] + ':docs/audits/record-value-clone-root-checks-20261004/ordinary.txt']).decode()
        assert prior.splitlines()[0].startswith('ram-guard: PID ')
        assert output == '\n'.join(prior.splitlines()[1:]) + '\n'
    receipts.append({'command': command, 'working_directory': str(fixture), 'inputs': inputs, 'status': run.returncode, 'output': output, 'git_context': {'metadata': 'current repository metadata derived by git rev-parse --absolute-git-dir', 'work_tree': str(fixture), 'operations': 'read-only child queries'}})
packet = {'python': sys.version, 'source_revision': binding['revision'], 'receipts': receipts}
if args.check:
    assert packet == json.loads((BASE / 'root-replays.json').read_text()), 'whole dated source/doc/runtime/Python/status/native/control output replay identity'
else:
    (BASE / 'root-replays.json').write_text(json.dumps(packet, sort_keys=True, indent=2) + '\n')
print('PASS complete source-root proof ordinary/all four source/allocation/kind RED controls reexecute exact dated source/doc/owner/runtime contexts with its whole repaired native proof and original joint/native records. Only exact invoked Python File-frame filename qualifies.')
