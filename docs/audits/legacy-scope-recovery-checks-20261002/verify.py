from pathlib import Path
import hashlib,json,subprocess
r=Path('docs/audits/hlink-matcher-20261002');m=json.loads((r/'manifest.json').read_text())
assert set(m)=={str(p.relative_to(r)) for p in r.rglob('*') if p.is_file() and p.name!='manifest.json'}
for name,entry in m.items():
 b=(r/name).read_bytes();assert len(b)==entry['bytes'];assert hashlib.sha256(b).hexdigest()==entry['sha256']
for name in ('perl/HLinkSubst.pm','perl/Global.pm','perl/HUtils.pm','perl/PathSearch.pm','perl/LinkedRE.pm'):
 assert Path(name).read_bytes()==subprocess.check_output(['git','show','69eeda3f68b4074cb6376df8a478f5ea2391491c:'+name])
assert not Path('t/2051-hlink-matcher-dispatch.t').exists()
body=Path('docs/book/src/11-extensions-and-embedding.md').read_text()
assert 'PathSearch' in body and 'HLink' not in body and 'Global' not in body
render=Path('docs/book/book/11-extensions-and-embedding.html').read_text()
assert 'Working directories and legacy search initialization' in render
assert 'Global' not in render and 'HLink' not in render
print('PASS sealed candidate membership, restored original legacy production, committed PathSearch repair, absent live candidate, source and rendered book scope')
