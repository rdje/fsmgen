"""Complete original header repair acceptance and independently qualified actual results."""
import copy
import re
import subprocess
from common import BASE, CLASS, HEADERS, REVISION, SCOPE, canonical, inputs, load, need, pin, read, same, save
import contracts
import controls
import join_headers
import local_repairs
import oracle
import prerequisites
import source_selection


def custody():
    qualified=load('prerequisites.json')
    need(qualified['revision']==REVISION and qualified['scope']==SCOPE and
         set(qualified['fixed'])=={str(p) for p in inputs()},'complete fixed original-header prerequisite epoch/membership')
    for path in inputs():
        command=['git','--no-replace-objects','show',REVISION+':'+str(path)]
        actual=subprocess.run(command,capture_output=True)
        need(actual.returncode==0 and actual.stderr==b'' and actual.stdout==path.read_bytes() and
             qualified['fixed'][str(path)]==dict(command=command,status=0,identity=pin(actual.stdout)),
             'whole fixed/current original-header prerequisite input')
    readers=prerequisites.readers()
    need(set(qualified['readers'])==set(readers),'every complete fresh original-header prerequisite reader')
    for name,arguments in readers.items():
        context='complete fixed committed inputs' if 'dated-' in name else 'current fixed source inputs'
        row=qualified['readers'][name];actual=load(row['receipt'])
        need(row['context']==context and actual['command']==['python3','-B',*arguments] and
             type(actual['status']) is int and actual['status']==0 and actual['stderr']=='' and
             'PASS ' in actual['stdout'] and row['identity']==pin(canonical(actual)),
             'whole actual fresh prerequisite and proper publication context')
    command=['python3','-B',str(HEADERS/'verify.py')]
    actual=subprocess.run(command,capture_output=True,text=True)
    need(type(actual.returncode) is int and actual.returncode==0 and actual.stderr=='' and actual.stdout.startswith('PASS '),
         'fresh complete source-header/source-value/whole-control custody replay')
    return dict(command=command,status=actual.returncode,stdout=actual.stdout,stderr=actual.stderr,
                programme=pin((HEADERS/'verify.py').read_bytes()))


def parent(task_contracts):
    def qualify(candidate):
        need(same(candidate,contracts.derive()),'whole unchanged original observer repair acceptance and child contracts')
    qualify(task_contracts)
    owner=(BASE/'scope.txt').read_text().splitlines()[0];repair=owner.rsplit('.',1)[0];outer=repair.rsplit('.',1)[0]
    text=subprocess.check_output(task_contracts['command'],text=True)
    for identifier in (owner,repair):
        old=contracts.block(text,identifier)
        new=re.sub(r'^  Status: `[^`]+`$','  Status: `done`',old,count=1,flags=re.M)
        text=text.replace(old,new,1)
    successor=outer+'.3';old=contracts.block(text,successor);progress=[]
    for status in ('active','done'):
        new=old.replace('  Status: `pending`','  Status: `'+status+'`',1);candidate=text.replace(old,new,1)
        need(same(contracts.derive(current=candidate),task_contracts),'valid separately owned complete observer publication progress')
        progress.append(dict(status=status,source_command=task_contracts['command'],candidate=pin(candidate.encode()),
                             whole_changed_successor=new,result='accepted'))
    altered=copy.deepcopy(task_contracts)
    altered['original_bodies'][repair]=altered['original_bodies'][repair].replace('Acceptance:','Borrowed:',1)
    lost=copy.deepcopy(task_contracts);lost['original_bodies'].pop(repair+'.2')
    rejected=[]
    for name,candidate in [('narrowed-parent',altered),('lost-child',lost)]:
        need(not same(candidate,task_contracts),'genuine complete original task-contract intervention')
        try:
            qualify(candidate)
        except ValueError as error:
            need(str(error)=='whole unchanged original observer repair acceptance and child contracts','intended complete task-contract refusal')
            rejected.append(dict(name=name,status='rejected',cause=str(error),whole_candidate=candidate))
        else:
            raise ValueError('accepted hostile whole original repair contract')
    return dict(progress=progress,contract_controls=rejected,
                scope='Complete unchanged original repair contracts; full observer publication remains separately owned.')


def main():
    fresh=custody()
    source=read(HEADERS/'headers.json');native=read(CLASS/'raw-product.json')['inventories'];selected=load('selected.json');joined=load('joined.json')
    need(same(source_selection.selected(),selected),'entire original source role selection replay')
    need(same(join_headers.join(native,selected,source),joined),'entire original full header producer replay')
    result=oracle.validate(joined,native,selected,source)
    need(same(result,load('independent-proof.json')),'whole independent original encoded-header/source/raw proof')
    need(same(controls.controls(),load('controls.json')),'every genuine whole original-header intervention and limited-predecessor actual result')
    need(same(local_repairs.replay(),load('local-repair-proof-qualified.json')),'complete first local failures and independently corrected portable contracts')
    task_contracts=contracts.derive()
    if (BASE/'contracts.json').exists():
        need(same(task_contracts,load('contracts.json')),'complete immutable original observer repair task contracts')
    else:
        save('contracts.json',task_contracts)
    original=load('original-raw-intake.json')
    need(original==dict(scope=SCOPE,original=pin((CLASS/'raw-product.json').read_bytes()),
        committed_source_selection=pin((HEADERS/'selection.json').read_bytes()),own_source_selection=pin((BASE/'selected.json').read_bytes()),
        meaning='First own encoded comparison uses complete prior canonical raw inventory; no original recapture.'),
        'complete source-before-original-comparison intake')
    selected_actual=load('actual-source-selection-1.json')
    need(type(selected_actual['status']) is int and selected_actual['status']==0 and selected_actual['stderr']=='' and
         selected_actual['command']==['python3','-B',str(BASE/'source_selection.py')] and
         str(BASE/'join_headers.py') not in selected_actual['programs'],'actual complete source selection precedes own encoded comparison programme')
    for path in BASE.glob('actual-*.json'):
        actual=read(path)
        need(type(actual['status']) is int and type(actual['stdout']) is str and type(actual['stderr']) is str,
             'complete typed actual original-header result including first failures')
        for programme in actual['programs'].values():
            need(pin(programme['body'].encode())==programme['identity'],'every whole retained actual programme epoch')
    proof=dict(result=result,original=original,contracts=pin(canonical(task_contracts)),parent=parent(task_contracts),
               controls=pin((BASE/'controls.json').read_bytes()),local_repairs=pin((BASE/'local-repair-proof-qualified.json').read_bytes()),
               fresh_source_header_custody=fresh,scope=SCOPE)
    if (BASE/'proof.json').exists():
        need(same(load('proof.json'),proof),'entire immutable original header repair proof')
    else:
        save('proof.json',proof)
    if (BASE/'manifest.json').exists():
        need(load('manifest.json')=={str(p.relative_to(BASE)):pin(p.read_bytes()) for p in BASE.rglob('*')
             if p.is_file() and p.name not in ('manifest.json','checks.json')},'whole immutable original-header repair namespace')
    print('PASS complete original full source/public headers, quoting/truncation/count/member/order/role, complete raw/opaque conservation and unchanged repair acceptance; original settings/native/private identities and full observer publication remain separately owned.')


if __name__=='__main__':
    main()
