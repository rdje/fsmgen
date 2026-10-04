"""Independent final finite T1983 source/native/semantic outcome reader."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--trust-label-calls', action='store_true')
parser.add_argument('--omit-copy', action='store_true')
parser.add_argument('--omit-owner', action='store_true')
args = parser.parse_args()
for name in ('interface-metadata-helper-contract-20261003', 'interface-metadata-diagnostic-join-20261004'):
    subprocess.run(['python3', '-B', 'docs/audits/' + name + '/verify.py'], check=True)
if (BASE / 'manifest.json').exists():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
def equal(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(equal(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(equal(x, y) for x, y in zip(a, b))
    return a == b
binding = json.loads((BASE / 'binding.json').read_text())
task = subprocess.check_output(['git', 'show', binding['revision'] + ':docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md']).decode()
owners = list(binding['owners'].items())[:-1] if args.omit_owner else list(binding['owners'].items())
assert len(owners) == 4, 'complete source/native/source-product/diagnostic prerequisite owners'
for owner, body in owners:
    start = task.index('- ID: `' + owner + '`')
    assert task[start:task.index('\n- ID:', start)] == body and 'Status: `done`' in body
outcome = json.loads((BASE / 'outcome.json').read_text())
for name, path in [('original-contract', 'interface-metadata-helper-contract-20261003/contracts.json'),
                   ('diagnostic-join', 'interface-metadata-diagnostic-join-20261004/join.json')]:
    assert equal(outcome[name], json.loads((Path('docs/audits') / path).read_text())), 'complete typed original/current source/native/product evidence'
original = outcome['original-contract']
tokens = [dict(r) for r in original['tokens']]
if args.trust_label_calls:
    for row in tokens:
        if row['role'] == 'string_label':
            row['role'] = 'snapshot_helper_call'
assert len(tokens) == 5 and len([r for r in tokens if r['role'].endswith('_helper_call')]) == 2, 'original label tokens cannot establish actual helper calls'
copies = original['copies'][:-1] if args.omit_copy else original['copies']
assert len(copies) == 8, 'complete original source copy-site contract'
joined = outcome['diagnostic-join']
current = joined['writer']['ordinary']
source = joined['writer']['sources-after']['t/1983-isf-interface-port-metadata.t']
assert len(re.findall(r'^sub rejects \{', source, re.M)) == 1
assert len(re.findall(r'^\s*rejects\(sub \{ snapshot_interface_port_metadata', source, re.M)) == 1
assert len(re.findall(r'^\s*rejects\(sub \{ capture_interface_port_metadata', source, re.M)) == 1
assert not re.search(r'\bdclone\(', source)
assert len(current['helpers']) == 44 and len(current['api']) == 105 and len(current['copies']) == 144 and len(current['consumers']) == 336
assert len([r for r in current['copies'] if r['kind'] == 'test']) == 41
assert len([r for r in current['copies'] if r['kind'] == 'provider']) == 102
assert len([r for r in current['copies'] if r['kind'] == 'cycle']) == 1
assert len(current['cause_consumers']) == 47 and all(r['matched'] for r in current['cause_consumers'])
assert all(r['passed'] for r in current['consumers'])
assert [r['helper'] for r in current['cause_consumers'] if r['helper'] is not None] == list(range(44))
assert original['probe_plan']['excluded_execution'] == ['HDL compiler/simulator', 'native proxy/controller runtime', 'macro transport', 'submodule implementation']
print('PASS final finite T1983 outcome: exact original named/token/copy/adjacent contracts join complete current source/helper/API/copy/field/product/caller/cause/warning/kind/isolation/cycle consumers and all completed repairs. Original lexical units stay distinct from actual runtime roles; copy/read-only/product and both contextual assurance defects close. Public behavior/admission unchanged; T1986 and broader cold/native/HDL remain owned.')
