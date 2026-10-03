import hashlib,json,subprocess
from pathlib import Path
B=Path(__file__).parent;rev=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip();assert rev=='142da0b8cbb3d819dd69d34fe282f27f83f0f9c0'
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',rev,'--','bin','perl','t','scripts','isf']).decode().splitlines()
selected=['t/1947-isf-formal-reusable-products.t','t/2060-isf-reusable-diagnostic-causes.t','perl/FSM/Scheduler/ISF/LoweringIR.pm','perl/FSM/Adapter/ISF.pm','perl/FSM/Adapter/ISF/Parser.pm']
(B/'bindings.json').write_text(json.dumps({'baseline':rev,'metadata':{p:{'bytes':len(Path(p).read_bytes()),'sha256':hashlib.sha256(Path(p).read_bytes()).hexdigest()} for p in paths+['t/2060-isf-reusable-diagnostic-causes.t']},'sources':{p:Path(p).read_text() for p in selected}},sort_keys=True,indent=2)+'\n');print('Bound current helper/control and unchanged provider source closure.')
