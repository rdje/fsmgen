from pathlib import Path
p=Path('docs/audits/caller-formal-binding-helper-causes-20261003/verify.py')
ns={'__file__':str(p)};exec(p.read_text().split("data=load(B/'causes.json')")[0],ns)
def diff(a,b,p=''):
 if type(a)!=type(b):print(p,'kinds',type(a).__name__,type(b).__name__);return
 if isinstance(a,dict):
  if set(a)!=set(b):print(p,'keys',set(a)-set(b),set(b)-set(a))
  for k in a.keys()&b.keys():diff(a[k],b[k],p+'/'+k)
 elif isinstance(a,list):
  if len(a)!=len(b):print(p,'length',len(a),len(b))
  for i,(x,y) in enumerate(zip(a,b)):diff(x,y,p+'/'+str(i))
 elif a!=b:print(p,a,b)
for r in ns['load'](p.parent/'causes.json')['rows']:
 s=next(s for s in ns['specs'] if s['id']==r['id']);a,c=ns['expected_actor'](s,r['band'])
 if ns['enc'](r['actor'])!=ns['enc'](a):print(r['id'],r['band']);diff(r['actor'],a);break
