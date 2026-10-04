"""Independent real-output oracle separates process coordinates from data echoes."""
import ast
import hashlib
import json
import os
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
text = (BASE / 'portable_replay.py').read_text()
tree = ast.parse(text)
helpers = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in ('frames', 'qualified', 'historical')]
assert {node.name for node in helpers} == {'frames', 'qualified', 'historical'}
namespace = {'re': re, 'Path': Path}
exec(compile(ast.Module(body=helpers, type_ignores=[]), 'bound portable process-coordinate helpers', 'exec'), namespace)
legacy = json.loads(Path('docs/audits/record-value-field-join-20261004/child-replays.json').read_text())
old = next(row for row in legacy if row['archive'] == 'record-value-fields-20261004' and row['command'][-1] == '--omit-type')
root = Path('.artifacts/record-value-portable-coordinate-oracle-20261004')
fixture = root / old['working_directory']
source = json.loads(Path('docs/audits/record-value-field-join-20261004/join.json').read_text())
for path, row in source['sources'].items():
    target = fixture / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(row['body'])
archive = Path('docs/audits') / old['archive']
(fixture / 'docs/knowledge/isf-aggregate-port-request-baseline.md').write_bytes((archive / 'card-after.txt').read_bytes())
for path, row in old['inputs'].items():
    raw = (fixture / path).read_bytes()
    assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
link = fixture / 'docs/audits'
expected_link = os.path.relpath(Path.cwd() / 'docs/audits', Path.cwd() / fixture / 'docs')
if link.is_symlink():
    assert os.readlink(link) == expected_link
else:
    assert not link.exists()
    link.symlink_to(expected_link, target_is_directory=True)
run = subprocess.run(old['command'], cwd=fixture, text=True, capture_output=True)
assert run.returncode == old['status'] == 1
new_output = run.stdout + run.stderr
relative = old['working_directory'] + '/' + old['command'][2]
new_filename = str(Path.cwd() / root / relative)
old_frames = namespace['frames'](old['output'])
assert len(old_frames) == 1
old_filename = old_frames[0][2]
assert old_filename.endswith('/' + relative) and old_filename != new_filename
# Independent oracle: replace only the known complete File-header coordinate,
# retaining the exact rest of this real interpreter's failure stream.
assert new_output == old['output'].replace('  File "' + old_filename + '", line ',
    '  File "' + new_filename + '", line ', 1)
qualified_old = namespace['historical'](old['output'], relative)
qualified_new = namespace['qualified'](new_output, new_filename, relative)
assert qualified_old == qualified_new
old_root = old_filename[:-len('/' + relative)]
new_root = str(Path.cwd() / root)
old_echo = old['output'] + 'AssertionError: actual argument ' + old_root + '/native-wanted-cause\n'
new_echo = new_output + 'AssertionError: actual argument ' + new_root + '/native-wanted-cause\n'
assert old_echo.replace(old_root + '/', '${REPO_ROOT}/') == new_echo.replace(new_root + '/', '${REPO_ROOT}/'), 'competing blanket prefix rule would erase changed argument data'
assert namespace['historical'](old_echo, relative) != namespace['qualified'](new_echo, new_filename, relative), 'exact process qualifier must preserve changed message/argument data'
changed_line = new_output.replace(', line 96,', ', line 97,', 1)
assert changed_line != new_output
assert namespace['qualified'](changed_line, new_filename, relative) != qualified_old
changed_message = new_output.replace('complete authored local type membership', 'wrong type membership', 1)
assert changed_message != new_output
assert namespace['qualified'](changed_message, new_filename, relative) != qualified_old
print('PASS independent real old/new control streams differ only in exact process filename coordinate. Qualified full streams agree; line/message changes and root echoes in actual argument data stay different. A blanket prefix rule demonstrably erases that competing data change and is refused.')
