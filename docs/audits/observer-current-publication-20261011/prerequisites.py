"""Fresh full source/value/display/publication qualification before header acceptance."""
import subprocess
from pathlib import Path
from common import BASE, VALUES, PUBLICATION, PREDICATE, SCALAR, REGEX, HEADERS, HEADER_REPAIR, REPAIR, DIAGNOSIS, REVISION, SCOPE, canonical, inputs, need, pin, save
from run import execute


def readers():
    namespace={'__name__':'header_source_prerequisites'}
    exec(compile((PREDICATE/'common.py').read_bytes(),str(PREDICATE/'common.py'),'exec'),namespace)
    result=dict(namespace['READERS'])
    boundary=Path('docs/audits/observer-value-profile-boundaries-20261010')
    result.update({
        'predicate-values':[str(PREDICATE/'verify.py')],
        'scalar-values':[str(SCALAR/'verify.py')],
        'regex-values':[str(REGEX/'verify.py')],
        'regex-dated-publication':[str(boundary/'checkpoint.py'),'--replay'],
        'remaining-value-boundaries':[str(boundary/'verify.py')],
        'remaining-value-dated-publication':[str(boundary/'publication_verify.py')],
        'source-value-parent':[str(VALUES/'verify.py')],
        'source-value-dated-publication':[str(VALUES/'publication_verify.py')],
        'source-value-dated-final-repair':[str(PUBLICATION/'verify.py')],
        'source-header-parent':[str(HEADERS/'verify.py')],
        'source-header-dated-publication':[str(HEADERS/'publication_verify.py')],
        'source-header-dated-final-repair':[str(HEADER_REPAIR/'verify.py')],
        'complete-original-header-repair':[str(REPAIR/'verify.py')],
        'observer-diagnosis':[str(DIAGNOSIS/'verify.py')],
    })
    return result


if __name__=='__main__':
    fixed={}
    for path in inputs():
        command=['git','--no-replace-objects','show',REVISION+':'+str(path)]
        actual=subprocess.run(command,capture_output=True)
        need(actual.returncode==0 and actual.stderr==b'' and actual.stdout==path.read_bytes(),
             'whole fixed/current source-header prerequisite input')
        fixed[str(path)]=dict(command=command,status=actual.returncode,identity=pin(actual.stdout))
    receipts={}
    for name,arguments in readers().items():
        actual=execute('prerequisite-'+name,['python3','-B',*arguments])
        receipts[name]=dict(context='complete fixed committed inputs' if 'dated-' in name else 'current fixed source inputs',
            receipt='actual-prerequisite-'+name+'-1.json',identity=pin(canonical(actual)))
    save('prerequisites.json',dict(revision=REVISION,fixed=fixed,readers=receipts,scope=SCOPE))
    print('PASS complete fresh source/value/display/header prerequisites and explicit dated-publication contexts.')
