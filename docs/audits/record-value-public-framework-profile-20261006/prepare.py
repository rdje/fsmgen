"""Bind whole prior public source evidence and the actual fresh capture."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-public-framework-profile-20261006')
ns = {'__name__': 'prepare_public_framework_profile'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
assert not (BASE / 'binding.json').exists() and not (BASE / 'manifest.json').exists()
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task = subprocess.check_output(['git', 'show', ns['REVISION'] + ':' + task_path])
owner = (ns['PRIOR'] / 'scope.txt').read_text().splitlines()[0].removeprefix('Owner: ')
start = task.decode().index('- ID: `' + owner + '`')
end = task.decode().index('\n- ID:', start + 1)
body = task.decode()[start:end]
assert '\n  Status: `done`\n' in body
archive = ns['committed'](ns['PRIOR'])
assert archive == {str(p): p.read_bytes() for p in ns['PRIOR'].iterdir()}
binding = dict(revision=ns['REVISION'], task_path=task_path, task_identity=ns['identity'](task),
    owner=owner, owner_body=body, archive={p: ns['identity'](raw) for p, raw in archive.items()},
    capture_identity=ns['identity']((BASE / 'public-profile.json').read_bytes()))
(BASE / 'binding.json').write_text(json.dumps(binding, sort_keys=True, indent=2)+'\n')
print('PASS whole committed prior public/source task/member and fresh dated capture binding.')
