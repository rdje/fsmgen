import hashlib,json,subprocess
from pathlib import Path
B=Path(__file__).parent;rev=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip();assert rev=='9b3e87db0befc7c1559e8dd8c6af7618a8108f7c'
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',rev,'--','bin','perl','t','scripts','isf']).decode().splitlines()
selected=['t/1959-isf-prepared-formal-reservations.t','perl/FSM/Scheduler/ISF/PreparedFormalReservations.pm','perl/FSM/Scheduler/ISF/FormalReservationInventory.pm','perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm','perl/FSM/Scheduler/ISF/LoweringIR.pm','perl/FSM/Adapter/ISF.pm','perl/FSM/Adapter/ISF/Parser.pm']
(B/'bindings.json').write_text(json.dumps({'baseline':rev,'metadata':{p:{'bytes':len(Path(p).read_bytes()),'sha256':hashlib.sha256(Path(p).read_bytes()).hexdigest()} for p in paths},'sources':{p:Path(p).read_text() for p in selected}},sort_keys=True,indent=2)+'\n');print('Bound unchanged checked reservation test/provider source closure.')
