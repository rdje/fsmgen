import hashlib,json,subprocess
from pathlib import Path
B=Path(__file__).parent
rev=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()
assert rev=='9c6b6191de86218abae3f29d292373bf935aac1f'
allowed={'t/1959-isf-prepared-formal-reservations.t','t/2062-isf-prepared-reservation-diagnostic-causes.t'}
raw_tree=subprocess.check_output(['git','ls-tree','-r','-z',rev,'--','bin','perl','t','scripts','isf'])
metadata={}
for record in raw_tree.split(b'\0'):
    if not record:continue
    declaration,name=record.split(b'\t',1);mode,kind,oid=declaration.decode().split();name=name.decode()
    assert kind=='blob' and mode in ('100644','100755'),name
    raw=Path(name).read_bytes()
    current_oid=hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
    assert name in allowed or current_oid==oid,name
    metadata[name]={'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'baseline_blob':oid}
selected=sorted(allowed|{'perl/FSM/Scheduler/ISF/PreparedFormalReservations.pm','perl/FSM/Scheduler/ISF/FormalReservationInventory.pm','perl/FSM/Scheduler/ISF/LoweringIR.pm','t/lib/FSM/Test/DiagnosticCause.pm'})
bindings={'baseline':rev,'allowed':sorted(allowed),'metadata':metadata,
          'sources':{name:Path(name).read_text() for name in selected},
          'baseline_sources':{name:subprocess.check_output(['git','show',rev+':'+name]).decode() for name in selected}}
(B/'bindings.json').write_text(json.dumps(bindings,sort_keys=True,indent=2)+'\n')
(B/'source-delta.patch').write_bytes(subprocess.check_output(['git','diff',rev,'--',*sorted(allowed)]))
print('Bound exact two-test delta, selected whole sources and unchanged complete Git source closure.')
