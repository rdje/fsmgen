import hashlib,json,subprocess
from pathlib import Path
B=Path(__file__).parent
rev=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()
assert rev=='d404427cb03f420ff03aa3d49f921cb42020b0ed'
records=subprocess.check_output(['git','ls-tree','-r','-z',rev,'--','bin','perl','t','scripts','isf'])
metadata={}
for record in records.split(b'\0'):
    if not record:continue
    header,name=record.split(b'\t',1);mode,kind,oid=header.decode().split();name=name.decode()
    assert kind=='blob' and mode in ('100644','100755')
    raw=Path(name).read_bytes()
    assert hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()==oid,name
    metadata[name]={'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'blob':oid}
selected=['t/1960-isf-formal-reservation-coverage.t','perl/FSM/Scheduler/ISF/FormalReservationCoverage.pm',
          'perl/FSM/Scheduler/ISF/FormalReservationInventory.pm',
          'perl/FSM/Scheduler/ISF/PreparedFormalReservations.pm','perl/FSM/Scheduler/ISF/FormalIdentityPlan.pm',
          'perl/FSM/Scheduler/ISF/FormalClauseResolver.pm','perl/FSM/Scheduler/ISF/LoweringIR.pm']
(B/'bindings.json').write_text(json.dumps({'baseline':rev,'metadata':metadata,
                                        'sources':{name:Path(name).read_text() for name in selected}},sort_keys=True,indent=2)+'\n')
print('PASS complete unchanged Git/source closure and selected test/provider bodies.')
