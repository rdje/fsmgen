import hashlib,json,subprocess
from pathlib import Path
B=Path(__file__).parent;rev=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip();assert rev=='00abbe80401c7d36f481dd2a65d01bf7ac41dca6'
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',rev,'--','bin','perl','t','scripts']).decode().splitlines()
selected=['t/1944-isf-formal-resource-products.t','perl/FSM/Scheduler/ISF/LoweringIR.pm','perl/FSM/Adapter/ISF.pm','perl/FSM/Adapter/ISF/Parser.pm']
(B/'bindings.json').write_text(json.dumps({'baseline':rev,'metadata':{p:{'bytes':len(Path(p).read_bytes()),'sha256':hashlib.sha256(Path(p).read_bytes()).hexdigest()} for p in paths},'sources':{p:Path(p).read_text() for p in selected}},sort_keys=True,indent=2)+'\n');print('Bound unchanged whole source closure before probe.')
