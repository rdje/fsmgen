import hashlib,json,re,subprocess
from pathlib import Path
B=Path(__file__).parent
revision=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()
paths=subprocess.check_output(['git','ls-files','-z','--','bin','perl','t','scripts']).decode().split('\0');paths=[p for p in paths if p]
metadata={}
for name in paths:
    raw=Path(name).read_bytes();metadata[name]={'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}
source_path='t/2052-isf-local-formal-origin-authority.t';source=Path(source_path).read_text()
helper=source[source.index('sub first_line {'):source.index('sub unrelated_refusal {')]
packages=source[source.index('package FSM::Test::LocalFormalOriginAuthority::DropClone;'):]
callers=[]
for m in re.finditer(r'\brefuses\([\s\S]*?;',source):
    pattern=re.search(r'qr/((?:\\.|[^/])*)/',m[0])[1]
    name=re.search(r",\s*'([^']*)'\);$",m[0])[1]
    callers.append({'path':source_path,'line':source[:m.start()].count('\n')+1,'offset':m.start(),'statement':m[0],'pattern':pattern,'name':name})
assert len(callers)==8
inputs=['t/2052-isf-local-formal-origin-authority.t','t/lib/FSM/Test/LocalFormalOriginAuthority.pm','t/lib/FSM/Test/ConditionalOriginAuthority.pm','t/lib/FSM/Test/ConditionalOriginParser.pm','perl/FSM/Adapter/ISF/Parser.pm','perl/FSM/Scheduler/ISF/FormalLowering.pm','perl/FSM/Scheduler/ISF/FormalClauseResolver.pm','perl/FSM/Scheduler/ISF/LoweringIR.pm']
result={'baseline':revision,'helper':helper,'packages':packages,'callers':callers,'all_source_metadata':metadata,'sources':{p:Path(p).read_text() for p in inputs},'scope':'Exact8 T2052 named-helper callers plus separately declared actual producer wrong-primary controls; direct qualify assertions/trace captures and wider runtime/cold consumers remain open.'}
(B/'bindings.json').write_text(json.dumps(result,sort_keys=True,indent=2)+'\n');print('exact helper/callers/current Git source bindings saved')
