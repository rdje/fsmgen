"""Check the independent snapshot allocation against the complete committed actual queries."""
import json,runpy
from pathlib import Path
n=runpy.run_path('docs/audits/coordinate-current-closure-20261010/verify.py')
names=n['git']('ls-tree','-r','--name-only',n['REVISION'],'--','docs/knowledge','docs/decisions').decode().splitlines()
paths=sorted(p for p in names if p.endswith('.md'))
canonical=n['objects'](paths)
actual=json.loads(n['git']('show',n['REVISION']+':docs/audits/coordinate-current-publication-20261010/current-input.json'))['record']['queries']
expected=n['allocation'](canonical)
assert actual['direct']['stdout']==actual['cached']['stdout']==expected, 'whole independent exact-case source allocation'
print('PASS independent complete committed source/question allocation matches both actual query roles; final semantic/publication proof still pending.')
