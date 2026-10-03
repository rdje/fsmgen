import hashlib,json,subprocess
from pathlib import Path
B=Path(__file__).parent;rev=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip();assert rev=='3a4bb6f69920418cb3c059e089d73930793ff856'
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',rev,'--','bin','perl','t','scripts','isf']).decode().splitlines()
selected=['t/1959-isf-prepared-formal-reservations.t','t/2062-isf-prepared-reservation-diagnostic-causes.t','perl/FSM/Scheduler/ISF/PreparedFormalReservations.pm','perl/FSM/Scheduler/ISF/FormalReservationInventory.pm','perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm','perl/FSM/Scheduler/ISF/LoweringIR.pm','perl/FSM/Adapter/ISF.pm','perl/FSM/Adapter/ISF/Parser.pm']
(B/'bindings.json').write_text(json.dumps({'baseline':rev,'metadata':{p:{'bytes':len(Path(p).read_bytes()),'sha256':hashlib.sha256(Path(p).read_bytes()).hexdigest()} for p in paths+['t/2062-isf-prepared-reservation-diagnostic-causes.t']},'sources':{p:Path(p).read_text() for p in selected}},sort_keys=True,indent=2)+'\n');print('Bound repaired cause/control and unchanged provider source closure.')
