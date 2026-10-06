"""Derive the whole proposed corpus and reject capacity growth before publication."""
import json
import subprocess
from pathlib import Path

base = Path('docs/audits/record-value-class-frame-retention-20261006')
proposal = json.loads((base / 'proposal.json').read_text())
before,after = {},{}
for path,row in proposal.items():
    original = subprocess.check_output(['git','show',row['revision'] + ':' + path])
    assert original == row['before'].encode(), 'whole original card body'
    assert Path(path).read_bytes() == original, 'live card remains unchanged'
    before[path],after[path] = original,row['after'].encode()
metrics = lambda blobs: dict(files=len(blobs),bytes=sum(map(len,blobs.values())),LF=sum(r.count(b'\n') for r in blobs.values()))
a,b = metrics(before),metrics(after)
print(json.dumps(dict(before=a,proposal=b,delta={k:b[k]-a[k] for k in a}),sort_keys=True),flush=True)
assert b['files'] == a['files'] and b['bytes'] <= a['bytes'] and b['LF'] <= a['LF'], 'complete retention proposal must not grow bytes or LF'
print('PASS complete unchanged-source non-growing retention proposal budget.')
