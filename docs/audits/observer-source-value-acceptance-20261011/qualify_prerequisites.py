"""Conserve all fresh readers and authenticate the corrected complete fixture input."""
import subprocess
from common import PREDICATE, REVISION, SCOPE, canonical, fixed_inputs, load, need, pin, save
import prerequisites


if __name__=='__main__':
    first=load('prerequisites.json')
    added=str(PREDICATE/'fixture-plan-qualified.json')
    need(set(first['fixed'])=={str(p) for p in fixed_inputs()}-{added},'entire first fixed-input epoch')
    need(set(first['readers'])==set(prerequisites.readers()),'complete fresh prerequisite reader membership')
    for name,args in prerequisites.readers().items():
        item=first['readers'][name];actual=load(item['receipt'])
        need(actual['command']==['python3','-B',*args] and type(actual['status']) is int and actual['status']==0
             and actual['stderr']=='' and 'PASS ' in actual['stdout'] and pin(canonical(actual))==item['identity'],
             'whole actual fresh reader success')
    fixed={}
    for path in fixed_inputs():
        command=['git','--no-replace-objects','show',REVISION+':'+str(path)]
        actual=subprocess.run(command,capture_output=True)
        need(actual.returncode==0 and actual.stderr==b'' and actual.stdout==path.read_bytes(),
             'complete corrected current/fixed input binding')
        fixed[str(path)]=dict(command=command,status=actual.returncode,identity=pin(actual.stdout))
    need(all(fixed[k]==v for k,v in first['fixed'].items()),'every original fixed input conserves')
    save('prerequisites-input-extension.json',dict(fixed={added:fixed[added]},first=pin(canonical(first)),scope=SCOPE))
    save('prerequisites-qualified.json',dict(revision=REVISION,fixed=fixed,readers=first['readers'],scope=SCOPE))
    print('PASS every actual fresh prerequisite and complete independently authenticated main-fixture plan extension; initial epoch retains.')
