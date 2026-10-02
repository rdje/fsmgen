import ast,copy,hashlib,json
from pathlib import Path
base=Path('docs/audits/current-diagnostic-lexical-inventory-20261002')
data=json.loads((base/'inventory.json').read_text());tree=ast.parse((base/'verify.py').read_text())
function=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='verify')
scope={'files':data['files'],'patterns':data['patterns'],'expected':data['sites']}
exec(compile(ast.Module(body=[function],type_ignores=[]),str(base/'verify.py'),'exec'),scope)
bad=copy.deepcopy(data);old=bad['sites'][0][3];bad['sites'][0][3]=float(old)
scope['verify'](bad)
assert json.dumps(data['sites'][0])!=json.dumps(bad['sites'][0])
print('CONFIRMED exact cold predicate accepts line integer -> JSON float with unchanged mathematical value; original artifact is unchanged')
print('reader sha256: '+hashlib.sha256((base/'verify.py').read_bytes()).hexdigest())
