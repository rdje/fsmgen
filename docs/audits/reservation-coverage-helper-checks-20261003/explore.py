import json
from pathlib import Path
B=Path('docs/audits/reservation-coverage-helper-causes-20261003')
rows=json.loads((B/'initial-observations-unqualified.json').read_text())
def diffs(a,b,path=''):
    if type(a) is not type(b):return [(path,type(a).__name__,type(b).__name__,a,b)]
    if isinstance(a,dict):
        assert a.keys()==b.keys(),path
        return sum((diffs(a[k],b[k],path+'/'+k) for k in sorted(a)),[])
    if isinstance(a,list):
        assert len(a)==len(b),path
        return sum((diffs(x,y,path+'/'+str(i)) for i,(x,y) in enumerate(zip(a,b))),[])
    assert a==b,path
    return []
print('Observed API calls:',len(rows['api']),'refusal consumers:',len(rows['consumers']))
for i,row in enumerate(rows['api']):
    delta=diffs(row['before'],row['after'])
    if delta:print('Actual input-kind difference',i,delta)
for consumer in rows['consumers']:
    print(consumer['api_index'],consumer['label'],consumer['pattern'])
