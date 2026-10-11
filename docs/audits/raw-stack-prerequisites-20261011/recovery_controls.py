"""Observe real missing/changed required-archive refusals without changing history."""
import json
import subprocess
import tempfile
from pathlib import Path
from common import BASE, canonical, need, pin, save
from intake import RECOVERY, recovery

PROGRAM='''import sys
from pathlib import Path
sys.path.insert(0, "docs/audits/raw-stack-prerequisites-20261011")
from intake import recovery
from common import canonical, pin
print(pin(canonical(recovery(Path(sys.argv[1])))))
'''


def main():
    original=Path(RECOVERY).read_bytes();wanted=recovery();results=[]
    local=Path('.artifacts/raw-stack-prerequisites-20261011');local.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(dir=local,prefix='required-archive-') as directory:
        root=Path(directory).resolve().relative_to(Path.cwd().resolve())
        need(root.stat().st_dev==Path.cwd().stat().st_dev,'same-volume archive control workspace')
        for name,raw,cause in (
            ('complete',original,''),('missing',None,'FileNotFoundError'),
            ('changed-tail',original[:-1]+bytes([original[-1]^1]),'complete recovered archive fixed-catalog byte identity')):
            path=root/(name+'.tar.gz')
            if raw is not None:path.write_bytes(raw)
            command=['python3','-B','-c',PROGRAM,str(path)]
            actual=subprocess.run(command,capture_output=True,text=True)
            number=len(list(BASE.glob('actual-archive-'+name+'-*.json')))+1
            receipt='actual-archive-'+name+'-'+str(number)+'.json'
            save(receipt,dict(command=command,status=actual.returncode,stdout=actual.stdout,stderr=actual.stderr,
                              candidate=pin(raw) if raw is not None else None,programme=PROGRAM))
            print(receipt,actual.returncode,actual.stdout,actual.stderr,flush=True)
            need(type(actual.returncode) is int,'actual required archive integer status')
            if name=='complete':
                need(actual.returncode==0 and actual.stderr=='' and actual.stdout==str(pin(canonical(wanted)))+'\n',
                     'whole positive required archive actual result')
            else:need(actual.returncode!=0 and actual.stdout=='' and cause in actual.stderr,'actual intended whole archive refusal')
            results.append(dict(name=name,programme=PROGRAM,command_role=['python3','-B','-c','whole retained programme','same-volume candidate'],
                                candidate=pin(raw) if raw is not None else None,status=actual.returncode,stdout=actual.stdout,
                                # Retain the complete actual traceback, including
                                # its incidental temporary path, as dated evidence.
                                stderr=actual.stderr,cause=cause))
    save('recovery-controls.json',dict(original=pin(original),fixed_catalog=wanted,actual_results=results))
    print('PASS actual complete required-archive positive and missing/changed-tail refusals; original whole archive remains unchanged.')


if __name__=='__main__':main()
