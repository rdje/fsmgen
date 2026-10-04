"""Replay whole completed metadata capture proof in its exact input/doc/owner context."""
import argparse
import ast
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
old = Path('docs/audits/record-value-captures-20261004')
binding = json.loads((old / 'binding.json').read_text())
current = json.loads((BASE / 'binding.json').read_text())
fixture = Path('.artifacts/record-value-snapshots-capture-replay-20261004')
docs = {row['path']: row['after'] for row in json.loads((old / 'doc-updates.json').read_text())}
for path, source in binding['sources'].items():
    if path not in docs:
        assert source['body'] == current['sources'][path]['body']
    target = fixture / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(docs.get(path, source['body']))
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
(fixture / task_path).parent.mkdir(parents=True, exist_ok=True)
(fixture / task_path).write_bytes(Path(task_path).read_bytes())
link = fixture / 'docs/audits'
expected_link = os.path.relpath(Path.cwd() / 'docs/audits', Path.cwd() / fixture / 'docs')
if link.is_symlink():
    assert os.readlink(link) == expected_link
else:
    assert not link.exists()
    link.symlink_to(expected_link, target_is_directory=True)
inputs = {}
for path in binding['sources']:
    raw = (fixture / path).read_bytes()
    inputs[path] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
tree = ast.parse(Path('docs/audits/record-value-replay-portability-20261004/portable_replay.py').read_text())
helpers = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in ('frames', 'qualified', 'historical')]
assert {node.name for node in helpers} == {'frames', 'qualified', 'historical'}
namespace = {'re': re, 'Path': Path}
exec(compile(ast.Module(body=helpers, type_ignores=[]), 'bound portable process-coordinate helpers', 'exec'), namespace)
receipts = []
relative = str(old / 'verify.py')
for flag in (None, '--omit-product', '--omit-stage', '--swap-layout', '--private-width', '--strict-value-authority'):
    command = ['python3', '-B', relative] + ([flag] if flag else [])
    run = subprocess.run(command, cwd=fixture, text=True, capture_output=True)
    label = flag[2:] if flag else 'ordinary'
    previous = subprocess.check_output(['git', 'show', current['revision'] + ':docs/audits/record-value-captures-checks-20261004/' + label + '.txt']).decode()
    previous_status = json.loads(subprocess.check_output(['git', 'show', current['revision'] + ':docs/audits/record-value-captures-checks-20261004/' + label + '-status.json']))
    assert previous_status['command'] == command and previous_status['working_directory'] == '.'
    assert run.returncode == previous_status['status'] == (1 if flag else 0), run.stdout + run.stderr
    output = namespace['qualified'](run.stdout + run.stderr, str(Path.cwd() / fixture / relative), relative)
    assert output == namespace['historical'](previous, relative), 'complete capture semantic output beyond exact process filename coordinate'
    receipts.append({'command': command, 'working_directory': str(fixture), 'inputs': inputs, 'status': run.returncode, 'output': output})
packet = {'python': sys.version, 'source_revision': binding['revision'], 'receipts': receipts}
if args.check:
    assert packet == json.loads((BASE / 'capture-replays.json').read_text()), 'whole source/profile/input/output/control capture receipt identity'
else:
    (BASE / 'capture-replays.json').write_text(json.dumps(packet, sort_keys=True, indent=2) + '\n')
print('PASS complete capture ordinary/five intended RED proofs and all inherited value/field/actor semantics conserve exact full sources/input/doc/owner/Python/status/output identities beyond bound process filename only.')
