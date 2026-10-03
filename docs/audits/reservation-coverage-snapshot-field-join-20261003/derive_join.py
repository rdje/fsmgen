import argparse
import json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--write',action='store_true');options=p.parse_args()
b=Path('docs/audits/reservation-coverage-snapshot-field-join-20261003')
c=Path('docs/audits/reservation-coverage-snapshot-capture-20261003')
x=json.loads((c/'ordinary.json').read_text())
selected={'success_snapshot','refusal_snapshot','module_mutation_seed','unexpected_module_seed','allocation_mutation_seed'}
def delta(a,b,path=''):
    if type(a) is not type(b):return [path]
    if isinstance(a,dict):
        assert a.keys()==b.keys()
        return [p for k in a for p in delta(a[k],b[k],path+'/'+k)]
    if isinstance(a,list):
        assert len(a)==len(b)
        return [p for i,(x,y) in enumerate(zip(a,b)) for p in delta(x,y,path+'/'+str(i))]
    assert a==b,path
    return []
rows=[{'ordinal':i,'site':row['site'],'cohort':'producer_removal' if i==35 else 'normal','paths':sorted(delta(row['before'],row['copy']))} for i,row in enumerate(x['copies']) if row['site'] in selected]
text=json.dumps(rows,sort_keys=True,indent=2)+'\n'
if options.write:(b/'joined-fields.json').write_text(text)
else:assert (b/'joined-fields.json').read_text()==text
print('PASS complete snapshot/seed field membership and cohort roster; independent completed semantic readers are required.')
