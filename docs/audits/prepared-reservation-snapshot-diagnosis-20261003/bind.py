import hashlib,json,subprocess
from pathlib import Path
B=Path(__file__).parent
rev=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()
assert rev=='3193b92c3669daec5d0a6f2053ed471e015087b0'
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',rev,'--','bin','perl','t','scripts','isf']).decode().splitlines()
selected=['t/1959-isf-prepared-formal-reservations.t','t/2062-isf-prepared-reservation-diagnostic-causes.t','perl/FSM/Scheduler/ISF/PreparedFormalReservations.pm','perl/FSM/Scheduler/ISF/FormalReservationInventory.pm','perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm','perl/FSM/Scheduler/ISF/LoweringIR.pm','perl/FSM/Adapter/ISF.pm','perl/FSM/Adapter/ISF/Parser.pm']
metadata={}
for p in paths:
    raw=Path(p).read_bytes();assert raw==subprocess.check_output(['git','show',rev+':'+p]),p
    metadata[p]={'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}
(B/'bindings.json').write_text(json.dumps({'baseline':rev,'metadata':metadata,'sources':{p:Path(p).read_text() for p in selected}},sort_keys=True,indent=2)+'\n')
print('Bound complete unchanged source closure and selected current test/provider bodies.')
