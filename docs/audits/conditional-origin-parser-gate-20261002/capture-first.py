import hashlib
import json
import shutil
from pathlib import Path

root = Path('docs/audits/conditional-origin-parser-gate-20261002')
shutil.copyfile('docs/TASK_TREE.md', root / 'task-index-after.txt')
shutil.copyfile('.artifacts/conditional-origin/capacity.json', root / 'capacity-after.json')
shutil.copyfile('.artifacts/conditional-origin/capacity-gate.txt', root / 'capacity-after.txt')
shutil.copyfile('.artifacts/conditional-origin/refresh_capacity.py', root / 'refresh_capacity.py')
before = (root / 'task-index-before.txt').read_bytes()
after = (root / 'task-index-after.txt').read_bytes()
old_lines, new_lines = before.splitlines(), after.splitlines()
assert len(old_lines) == len(new_lines)
changed = [(i + 1, a, b) for i, (a, b) in enumerate(zip(old_lines, new_lines)) if a != b]
assert len(changed) == 1 and changed[0][0] == 53
assert b'SEMANTIC-INTROSPECTION-MCP-FRONTIER' in changed[0][1]
assert b'SEMANTIC-INTROSPECTION-MCP-FRONTIER' in changed[0][2]
assert max(map(len, old_lines)) == 1024
assert max(map(len, new_lines)) == 852
before_capacity = json.loads((root / 'capacity-before.json').read_text())
after_capacity = json.loads((root / 'capacity-after.json').read_text())
assert before_capacity['focused_documents']['line_bytes_each'] == 1024
assert after_capacity['focused_documents']['line_bytes_each'] == 852
assert after_capacity['focused_documents']['line_bytes_each'] < 1024 * .9
registry = [json.loads(line) for line in Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()]
surface = next(row for row in registry if row['surface_id'] == 'focused_documents')
assert surface['baseline']['line_bytes_each'] == 790
assert surface['health_targets']['line_bytes_each'] == 1024
assert surface['enforcement_ceilings']['line_bytes_each'] == 1024
assert surface['transition']['max_growth']['line_bytes_each'] == 126
receipt = {'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.1',
    'changed_line': 53, 'before_max_line_bytes': 1024, 'after_max_line_bytes': 852,
    'scope': 'Only duplicate task-index summary shortened; detailed canonical task evidence retained. No production, tests, ceiling, baseline, health target or sealed parser evidence changed.',
    'files': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(root.iterdir()) if p.is_file()}}
(root / 'correction.json').write_text(json.dumps(receipt, indent=2, sort_keys=True) + '\n')
print('Gate correction: exact single-row narrowing and independent capacity agreement PASS')
