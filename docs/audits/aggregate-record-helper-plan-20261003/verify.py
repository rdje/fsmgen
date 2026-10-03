"""Independent line scanner and exact Git/source/task ownership reader."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--trust-cohort-owner', action='store_true')
parser.add_argument('--omit-member', action='store_true')
options = parser.parse_args()
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256'], name
plan = json.loads((BASE / 'plan.json').read_text())
prior_dir = Path('docs/audits/residual-named-helper-cohorts-20261003')
prior = json.loads((prior_dir / 'membership.json').read_text())
paths = json.loads((prior_dir / 'owners.json').read_text())['cohorts']['3']
rows = plan['rows'][:-1] if options.omit_member else plan['rows']
assert [row['path'] for row in rows] == paths, 'complete selected source membership'
assert len(rows) == len(paths) == len(set(paths)) == 14
task = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md').read_text()
section = task.split('## Task Tree\n', 1)[1].split('\n## ', 1)[0]
parent = plan['parent']
assert parent.endswith('.1.2.3.2.3.3.3')
nodes = {}
for block in section.split('\n- ID: `')[1:]:
    identity, body = block.split('`', 1)
    nodes[identity] = body
assert parent in nodes
children = [parent + '.' + str(number) for number in range(1, 17)]
assert '  Children: `' + ', '.join(children) + '`' in nodes[parent]
assert plan['split_owner'] == children[0] and plan['join_owner'] == children[-1]
for number, row in enumerate(rows, 2):
    path = row['path']
    original = [r for r in prior['definitions'] if r['path'] == path]
    assert len(original) == 1
    assert original[0]['review_owner'] == row['prior_review_owner'] == parent
    owner = original[0]['review_owner'] if options.trust_cohort_owner else row['review_owner']
    assert owner == parent + '.' + str(number), 'broad cohort owner cannot prove per-source review ownership'
    assert owner in nodes and path in nodes[owner]
    assert 'native applicability before execution' in nodes[owner]
    assert 'pending actual helper/caller/cause/product/copy/native applicability qualification' == row['scope']
    assert not Path(path).is_absolute() and '..' not in Path(path).parts
    raw = subprocess.check_output(['git', 'show', plan['revision'] + ':' + path])
    assert raw.decode() == row['source'] == prior['sources'][path]
    assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
    found, offset = [], 0
    for line_number, line in enumerate(raw.splitlines(keepends=True), 1):
        match = re.match(rb'[ \t]*sub[ \t]+([A-Za-z_][A-Za-z_0-9]*)\b', line)
        if match and any(match[1].startswith(prefix) for prefix in (b'refus', b'reject', b'fail', b'declin')):
            found.append({'function': match[1].decode(), 'line': line_number,
                'offset': offset, 'token': match[0].decode()})
        offset += len(line)
    assert found == row['definitions']
    assert all(original[0][key] == found[0][key] for key in found[0])
assert len({r['review_owner'] for r in rows}) == 14
print('PASS independently bound 14 complete source/declaration members, exact prior locators and distinct authoritative per-source review leaves; no cause/native/runtime admission is inferred.')
