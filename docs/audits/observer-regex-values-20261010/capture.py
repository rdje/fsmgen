"""Capture complete source-neutral current public regex results."""
import subprocess
from common import BASE, load, need, pin, same, save
import oracle
from common import AUTHORITY, CENSUS, read


def main():
    proof=oracle.source(read(AUTHORITY),read(CENSUS/'source-models.json'),load('regexes.json'),load('plan.json'))
    need(same(proof,load('source-proof.json')),'whole independent source proof precedes public capture')
    prerequisite=load('actual-prerequisites-1.json')
    need(type(prerequisite['status']) is int and prerequisite['status']==0 and prerequisite['stderr']=='',
         'whole prerequisite execution completes before native observation')
    inputs={str(BASE/n):pin((BASE/n).read_bytes()) for n in
            ('native.pl','plan.json','pre-observation.json','source-proof.json',
             'prerequisites.json','actual-prerequisites-1.json','public-contracts.json')}
    need(not (BASE/'native.json').exists(),'first current public regex observation')
    save('capture-admission.json',dict(native_present=False,inputs=inputs,scope=load('plan.json')['scope'],
        programs={str(p):dict(identity=pin(p.read_bytes()),body=p.read_text())
                  for p in sorted(BASE.iterdir()) if p.suffix in ('.py','.pl')}))
    inputs[str(BASE/'capture-admission.json')]=pin((BASE/'capture-admission.json').read_bytes())
    command=['perl','-Iperl',str(BASE/'native.pl')]
    result=subprocess.run(command,capture_output=True,text=True)
    save('native.json',dict(command=command,status=result.returncode,stdout=result.stdout,stderr=result.stderr,
        inputs=inputs))
    need(result.returncode==0 and result.stderr=='','actual complete public regex capture success')
    print('PASS full current public regex capture; original native identity/settings unmeasured.')


if __name__=='__main__':
    main()
