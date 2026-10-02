import importlib.util, json
from pathlib import Path
p=Path('docs/audits/record-output-predecessors-20261002')
spec=importlib.util.spec_from_file_location('v',p/'verify.py'); v=importlib.util.module_from_spec(spec); spec.loader.exec_module(v)
m=json.loads((p/'manifest.json').read_bytes())
a,b=[json.loads(b''.join((p/f).read_bytes() for f in m['phase_fragments'][n]['members'])) for n in ('baseline','current')]
a=v.products(a['products']); b=v.products(b['products'])
rows=[]
def diff(a,b,path):
 if type(a)!=type(b): rows.append(dict(path=path,kind='type',old=str(type(a)),current=str(type(b)))); return
 if isinstance(a,dict):
  if set(a)!=set(b): rows.append(dict(path=path,kind='keys',old=list(a),current=list(b)))
  for k in sorted(set(a)&set(b)): diff(a[k],b[k],path+'/'+k)
 elif isinstance(a,list):
  if len(a)!=len(b): rows.append(dict(path=path,kind='length',old=len(a),current=len(b)))
  for i,(x,y) in enumerate(zip(a,b)): diff(x,y,path+'/'+str(i))
 elif a!=b: rows.append(dict(path=path,kind='value',old=str(a)[:500],current=str(b)[:500]))
diff(a,b,'products')
Path('.artifacts/record-output-predecessors/verify-differences.json').write_text(json.dumps(rows,indent=2)+'\n')
print(json.dumps(rows,indent=2))
