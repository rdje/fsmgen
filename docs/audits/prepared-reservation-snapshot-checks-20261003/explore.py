import json
from pathlib import Path
base = Path('docs/audits/prepared-reservation-snapshot-diagnosis-20261003')
rows = json.loads((base/'observations.json').read_text())
def diffs(a,b,path=''):
    if type(a) is not type(b):
        return [(path,type(a).__name__,type(b).__name__,a,b)]
    if isinstance(a,dict):
        assert a.keys()==b.keys(),path
        return sum((diffs(a[k],b[k],path+'/'+k) for k in sorted(a)),[])
    if isinstance(a,list):
        assert len(a)==len(b),path
        return sum((diffs(x,y,path+'/'+str(i)) for i,(x,y) in enumerate(zip(a,b))),[])
    assert a==b,path
    return []
changed=[]
for i,row in enumerate(rows['clones']):
    assert not diffs(row['before'],row['after']),('original',i)
    delta=diffs(row['before'],row['clone'])
    if delta: changed.append({'index':i,'line':row['line'],'differences':delta})
for i,row in enumerate(rows['calls']):
    assert not diffs(row['before'],row['after']),('caller',i)
print('Actual clones:',len(rows['clones']),'calls:',len(rows['calls']))
print(json.dumps(changed,sort_keys=True,indent=2))
(base/'clone-differences.json').write_text(json.dumps(changed,sort_keys=True,indent=2)+'\n')
