"""Bind complete committed source roots, actual checkers and done owners."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-public-boundary-join-20261006')
ns = {'__name__':'prepare_original_public_boundary_join'}
exec(compile((BASE/'verify.py').read_bytes(),str(BASE/'verify.py'),'exec'),ns)
assert not (BASE/'binding.json').exists() and not (BASE/'manifest.json').exists()
task_path='docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task=subprocess.check_output(['git','show',ns['REVISION']+':'+task_path]); owners={}; bodies={}; archives={}
for directory in ns['DIRECTORIES']:
    root=ns['CONTEXT'] if directory==ns['CONTEXT_CHECKS'] else ns['FIXTURE'] if directory==ns['FIXTURE_CHECKS'] else directory
    owner=(root/'scope.txt').read_text().splitlines()[0].removeprefix('Owner: ')
    start=task.decode().index('- ID: `'+owner+'`');end=task.decode().index('\n- ID:',start+1);body=task.decode()[start:end]
    assert '\n  Status: `done`\n' in body
    actual={str(p):p.read_bytes() for p in directory.iterdir()};assert actual==ns['committed'](directory)
    owners[str(directory)]=owner;bodies[owner]=body;archives[str(directory)]={p:ns['identity'](raw) for p,raw in actual.items()}
ns['save']('binding.json',dict(revision=ns['REVISION'],task_path=task_path,task_identity=ns['identity'](task),owners=owners,owner_bodies=bodies,archives=archives))
print('PASS whole fixed-Git original/public source roots, actual checkers and done-owner binding.')
