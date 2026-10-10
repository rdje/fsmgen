"""Join fresh successes with exact dated-context replay, retaining first rejection."""
import subprocess
from pathlib import Path
from common import BASE,REVISION,SCOPE,canonical,load,need,pin,save
import prerequisites


def main():
    failed=load('actual-prerequisites-1.json')
    need(type(failed['status']) is int and failed['status']!=0 and failed['stderr'],
         'complete first wrong-context prerequisite result retained')
    readers=prerequisites.readers()
    result={}
    for name,arguments in readers.items():
        record=load('actual-prerequisite-'+name+'-1.json')
        need(record['command']==['python3','-B',*arguments],'complete exact first prerequisite command')
        if name=='regex-publication-repair':
            need(type(record['status']) is int and record['status']!=0
                 and ('entire independently measured final task declaration' in record['stderr']
                      or 'whole owning task and unchanged acceptance' in record['stderr']),
                 'dated current-publication reader rejects a changed task epoch')
            checkpoint=load('checkpoint-publication.json')
            need(type(checkpoint['status']) is int and checkpoint['status']==0 and checkpoint['stderr']==''
                 and checkpoint['stdout'].startswith('PASS ') and checkpoint['revision']==REVISION
                 and checkpoint['command']==record['command'] and checkpoint['before']==checkpoint['after'],
                 'actual fresh exact committed-context publication reader success')
            result[name]=dict(context='complete fixed committed inputs',receipt='checkpoint-publication.json',
                identity=pin(canonical(checkpoint)),first_wrong_context=pin(canonical(record)))
        else:
            need(type(record['status']) is int and record['status']==0 and record['stderr']==''
                 and 'PASS ' in record['stdout'],'complete fresh current source/value prerequisite success')
            result[name]=dict(context='current fixed source inputs',receipt='actual-prerequisite-'+name+'-1.json',
                identity=pin(canonical(record)))
    fixed={}
    for path in prerequisites.inputs():
        command=['git','--no-replace-objects','show',REVISION+':'+str(path)]
        actual=subprocess.run(command,capture_output=True)
        need(actual.returncode==0 and actual.stderr==b'' and actual.stdout==path.read_bytes(),
             'whole fixed/current complete prerequisite input')
        fixed[str(path)]=dict(command=command,status=actual.returncode,identity=pin(actual.stdout))
    save('prerequisites-qualified.json',dict(revision=REVISION,readers=result,fixed=fixed,scope=SCOPE,
        context_contract='Every source/value reader executes fresh on current fixed source inputs; the dated publication reader executes fresh against every committed input at its exact epoch. The wrong current-task-context result remains a rejection and supplies no success.'))
    print('PASS complete fresh prerequisite set with distinct current-source and exact dated-publication contexts; first wrong-context result retains.')


if __name__=='__main__':
    main()
