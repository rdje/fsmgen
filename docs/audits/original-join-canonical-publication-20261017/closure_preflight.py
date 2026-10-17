"""Test the repaired frozen import graph before the fresh v2 delivery epoch."""
import base64
import gzip
import json
from pathlib import Path
import verify as publication

row=publication.load('native-final-actual.json.gz')
ref=row['sources_before']
archive=Path(ref['path']).read_bytes()
assert publication.identity(archive)['sha256']==ref['sha256']
entries=json.loads(gzip.decompress(archive))
bodies={name:base64.b64decode(entry['body_base64']) for name,entry in entries.items()}
aliases={name:entry['symlink_target'] for name,entry in entries.items() if 'symlink_target' in entry}
declaration=publication.load('module-closure-v2.json')
for name,expected in declaration['modules'].items():
    current=Path(name).read_bytes()
    assert publication.identity(current)==expected
    if name in bodies:
        assert bodies[name]==current
    else:
        assert name=='scripts/decision_catalog.py'
        bodies[name]=current
bodies[str(publication.BASE/'module-closure-v2.json')]=(publication.BASE/'module-closure-v2.json').read_bytes()
with publication.frozen_factory(bodies) as factory:
    publication.core(factory=factory,snapshot=bodies,aliases=aliases,record=publication.load('proof.json.gz')['current'])
print('PASS proposed frozen import closure over retained native inputs plus the explicitly later captured decision_catalog; fresh v2 delivery remains required.')
