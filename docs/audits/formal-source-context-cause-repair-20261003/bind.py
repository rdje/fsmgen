import hashlib,json,subprocess
from pathlib import Path
B=Path(__file__).parent
rev=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()
assert rev=='4ed8478c149cf632238dd120570756c96c717dcb'
names=subprocess.check_output(['git','ls-tree','-r','--name-only',rev,'--','bin','perl','t','scripts']).decode().splitlines()
names+=['t/2056-isf-formal-source-context-diagnostic-causes.t']
selected=['t/2056-isf-formal-source-context-diagnostic-causes.t','t/lib/FSM/Test/DiagnosticCause.pm','t/1936-isf-formal-source-context.t','perl/FSM/Scheduler/ISF/LoweringIR.pm','perl/FSM/Adapter/ISF.pm','perl/FSM/Adapter/ISF/Parser.pm','perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm','perl/FSM/Scheduler/ISF/FormalClauseResolver.pm']
(B/'bindings.json').write_text(json.dumps({'baseline':rev,'metadata':{p:{'bytes':len(Path(p).read_bytes()),'sha256':hashlib.sha256(Path(p).read_bytes()).hexdigest()} for p in names},'sources':{p:Path(p).read_text() for p in selected}},sort_keys=True,indent=2)+'\n')
print('Bound all tracked source metadata and exact selected bodies before probes.')
