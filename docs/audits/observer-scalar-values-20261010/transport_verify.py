"""Reproduce stale receipt loss and independently prove corrected conservation."""
import json
import subprocess
from pathlib import Path
from common import BASE, canonical, load, need, pin, same, save

SCRATCH=Path('.artifacts/observer-scalar-values-20261010/transport-control')
WORKER='''import json,sys,time
from pathlib import Path
name=sys.argv[1]
Path(name+'-ready').write_text('ready')
deadline=time.monotonic()+30
while not (Path('first-ready').exists() and Path('second-ready').exists()):
    if time.monotonic()>deadline: raise RuntimeError('both actual workers admitted')
    time.sleep(.01)
if name=='second':
    receipt=Path('docs/audits/observer-scalar-values-20261010/checks.json')
    while not receipt.exists():
        if time.monotonic()>deadline: raise RuntimeError('first receipt retained before second completion')
        time.sleep(.01)
print(name+' complete')
'''


def run(label, program):
    root=SCRATCH/label
    need(not root.exists(),'fresh whole transport control workspace')
    destination=root/BASE
    destination.mkdir(parents=True)
    (destination/'checks.py').write_bytes(program)
    (destination/'common.py').write_bytes((BASE/'common.py').read_bytes())
    (root/'worker.py').write_text(WORKER)
    children=[]
    for name in ('first','second'):
        command=['python3','-B',str(BASE/'checks.py'),name,'python3','-B','worker.py',name]
        children.append((name,command,subprocess.Popen(command,cwd=root,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)))
    results={}
    try:
        for name,command,child in children:
            stdout,stderr=child.communicate(timeout=45)
            need(type(child.returncode) is int and child.returncode==0 and stderr=='', 'whole successful actual transport worker')
            results[name]=dict(command=command,status=child.returncode,stdout=stdout,stderr=stderr)
    finally:
        for _,_,child in children:
            if child.poll() is None:
                child.kill();child.wait()
    checks=json.loads((destination/'checks.json').read_bytes())
    return dict(program=dict(identity=pin(program),body=program.decode()),worker=WORKER,
                cwd=str(root),results=results,receipts=checks)


def verify(record):
    old=record['original'];new=record['corrected']
    need(set(old['receipts'])=={'second'},'known-bad stale dictionary loses the first completed receipt')
    need(set(new['receipts'])=={'first','second'},'corrected locked merge conserves both actual completed receipts')
    for result in (old,new):
        need(pin(result['program']['body'].encode())==result['program']['identity'],'entire actual transport program')
        for name,receipt in result['receipts'].items():
            need(type(receipt['status']) is int and receipt['status']==0 and receipt['stderr']==''
                 and receipt['stdout']==name+' complete\n','complete unaltered actual transport result')
    need(old['program']['body']==(BASE/'checks-before-transport-repair.py.txt').read_text()
         and new['program']['body']==(BASE/'checks.py').read_text(),'whole original and corrected transport sources')
    return dict(scope='Deterministic actual two-worker before/after control of receipt conservation; original automatic overwritten metadata remains unrecovered and transcribed observed outputs are explicitly labeled.',
                original=pin(canonical(old)),corrected=pin(canonical(new)))


if __name__=='__main__':
    if (BASE/'transport-control.json').exists():
        record=load('transport-control.json')
    else:
        record=dict(original=run('original',(BASE/'checks-before-transport-repair.py.txt').read_bytes()),
                    corrected=run('corrected',(BASE/'checks.py').read_bytes()))
        save('transport-control.json',record)
    proof=verify(record)
    if (BASE/'transport-proof.json').exists():
        need(same(proof,load('transport-proof.json')),'whole immutable receipt-conservation control')
    else:
        save('transport-proof.json',proof)
    print('PASS actual known-bad receipt loss and corrected whole-result conservation; first automatic metadata gap remains explicit.')
