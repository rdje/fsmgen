import ast,copy,hashlib,json,os
from pathlib import Path
root=Path.cwd(); base=root/'.artifacts/tmp/native-proxy-original-20260910'
plan=json.loads((base/'admission.json').read_text()); source=(base/'run.py').read_bytes()
assert len(source)==plan['driver']['bytes'] and hashlib.sha256(source).hexdigest()==plan['driver']['sha256']
tree=ast.parse(source)
assert sum(isinstance(n,ast.Call) and isinstance(n.func,ast.Attribute) and n.func.attr=='GatedTest' for n in ast.walk(tree))==1
assert sum(isinstance(n,ast.Call) and isinstance(n.func,ast.Attribute) and n.func.attr=='release' for n in ast.walk(tree))==1
function=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='selection_context_matches')
namespace={'PLAN':plan,'Path':Path,'os':os,'hashlib':hashlib}
exec(compile(ast.Module(body=[function],type_ignores=[]),str(base/'run.py'),'exec'),namespace)
assert namespace['selection_context_matches']()
for name,value in [('machine','unqualified'),('compiler_digest','0'*64),('sdk_inode',0)]:
 changed=copy.deepcopy(plan); namespace['PLAN']=changed
 if name=='machine': changed['host_selection_inputs']['machine']=value
 elif name=='compiler_digest': changed['host_selection_inputs']['compiler']['sha256']=value
 else: changed['host_selection_inputs']['sdk']['inode']=value
 assert not namespace['selection_context_matches'](),name
assert not (root/'.artifacts/logs/native-proxy-original-20260910').exists()
report={'original_launched':False,'driver_sha256':plan['driver']['sha256'],'positive_selection':True,'rejected_context_changes':['machine','compiler_digest','sdk_inode'],'one_gated_constructor_and_release':True}
(base/'preflight.json').write_text(json.dumps(report,sort_keys=True)+'\n')
print(json.dumps(report,sort_keys=True))
