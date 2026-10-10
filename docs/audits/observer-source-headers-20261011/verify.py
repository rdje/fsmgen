"""Complete source-header acceptance, genuine whole controls and immutable custody."""
import copy
import gzip
import subprocess
from pathlib import Path
from common import BASE, VALUES, CENSUS, REVISION, SCOPE, canonical, inputs, load, need, pin, read, same, save
import contracts
import derive
import current_headers
import oracle
import prerequisites


def validate(product,current,task_contracts):
    result=oracle.validate(product,current)
    need(same(task_contracts,contracts.derive()),'complete unchanged source-header parent/child/raw-join acceptance')
    return result


def controls(product,current,task_contracts,write=False):
    result=[]
    def trial(name,mutate,cause):
        p,c,t=copy.deepcopy((product,current,task_contracts));mutate(p,c,t)
        need(not same([p,c,t],[product,current,task_contracts]),'genuine whole source-header hostile input')
        try:
            validate(p,c,t)
        except ValueError as error:
            need(str(error)==cause,'intended whole source-header control: '+name+': '+str(error))
        else:
            raise ValueError('accepted hostile source header: '+name)
        raw=gzip.compress(canonical(dict(product=p,current=c,contracts=t)),mtime=0)
        path=BASE/'controls'/('candidate-'+name+'.json.gz')
        if write:
            path.parent.mkdir(exist_ok=True)
            need(not path.exists(),'retain complete first hostile candidate')
            path.write_bytes(raw)
        else:
            need(path.read_bytes()==raw,'whole retained candidate and actual replay: '+name)
        result.append(dict(name=name,cause=cause,status='rejected',candidate=str(path.relative_to(BASE)),identity=pin(raw)))
    field=lambda name:'entire independent source-header field: '+name
    trial('omitted-source-header',lambda p,c,t:p['headers'].pop(),field('headers'))
    trial('reordered-source-headers',lambda p,c,t:p['headers'].reverse(),field('headers'))
    trial('wrong-full-function',lambda p,c,t:p['headers'][0]['source_metadata'].update(function='borrowed'),field('headers'))
    header=next(i for i,r in enumerate(product['headers']) if len(r['source_argument_ids'])>1)
    trial('reordered-arguments',lambda p,c,t:p['headers'][header]['source_argument_ids'].reverse(),field('headers'))
    trial('wrong-header-delimiter',lambda p,c,t:p['headers'][header]['expression'].update(separator='; '),field('headers'))
    trial('borrowed-header-member',lambda p,c,t:p['headers'][header]['expression'].update(function=p['headers'][0]['expression']['function']),field('headers'))
    operand=next(k for k,v in product['operands'].items() if v['source']['qualification']['kind']=='qualified complete scalar value'
                 and type(v['source']['qualification']['value']) is str and len(v['source']['qualification']['value'])>64)
    trial('lost-complete-scalar-tail',lambda p,c,t:p['operands'][operand]['source']['qualification'].update(value=p['operands'][operand]['source']['qualification']['value'][:61]),field('operands'))
    trial('wrong-source-role',lambda p,c,t:p['operands'][operand]['source']['input'].update(role='borrowed'),field('operands'))
    trial('wrong-operand-schema',lambda p,c,t:p['operands'][operand]['source'].update(schema='borrowed'),field('operands'))
    guard=next(k for k,v in product['operands'].items() if v['source']['qualification']['kind']=='qualified whole guard construction'
               and v['source']['qualification']['string_value']=='')
    trial('borrowed-logical-zero-token',lambda p,c,t:p['operands'][guard]['source']['qualification'].update(string_value='0'),field('operands'))
    trial('convenient-wildcard-token',lambda p,c,t:p['operands'][operand]['original_token'].update(state='.*'),field('operands'))
    inherited=next(k for k,v in product['operands'].items() if v['source']['qualification'].get('evidence_role')=='inherited serialized evidence')
    trial('inherited-operand-promotion',lambda p,c,t:p['operands'][inherited]['source']['qualification'].update(evidence_role='new independent semantic oracle'),field('operands'))
    case=next(k for k,v in product['current_construction_cases'].items() if v['kind']=='regex')
    trial('wrong-current-regex-encoding',lambda p,c,t:p['current_construction_cases'][case]['case'].update(pattern_utf8=not p['current_construction_cases'][case]['case']['pattern_utf8']),field('current_construction_cases'))
    trial('lost-constructor-case',lambda p,c,t:p['current_construction_cases'].pop(case),field('current_construction_cases'))
    trial('lost-unframed-operand',lambda p,c,t:p['unframed_operand_ids'].pop(),field('unframed_operand_ids'))
    trial('lost-source-phase',lambda p,c,t:p['source_allocation'][0]['cases'].pop(),field('source_allocation'))
    trial('reordered-phase-groups',lambda p,c,t:p['source_allocation'].reverse(),field('source_allocation'))
    trial('source-do-promoted-to-require',lambda p,c,t:p['loads'][0].update(source_operator='require'),field('loads'))
    trial('diagnostic-marker-as-source',lambda p,c,t:p['loads'][0].update(diagnostic_marker_is_source_operator=True),field('loads'))
    trial('original-profile-borrowing',lambda p,c,t:p['original_unmeasured'].update(settings_formatter=dict(MaxArgLen=64)),field('original_unmeasured'))
    trial('original-private-meaning-promotion',lambda p,c,t:p['original_unmeasured'].update(private_framework_eval_meanings='qualified'),field('original_unmeasured'))
    trial('boolean-profile-integer',lambda p,c,t:p['current_profile'].update(MaxEvalLen=False),field('current_profile'))
    trial('omitted-fixed-source-input',lambda p,c,t:p['inputs'].pop(next(iter(p['inputs']))),field('inputs'))
    trial('original-raw-comparison-promotion',lambda p,c,t:p.update(raw_comparison='Full original encoded headers matched.'),field('raw_comparison'))
    conditional='entire independent known conditional header/unresolved/hidden allocation'
    known=next(i for i,r in enumerate(current['headers']) if r['known_conditional_header'] is not None)
    unresolved=next(i for i,r in enumerate(current['headers']) if r['unresolved_slots'])
    trial('wrong-whole-known-header-tail',lambda p,c,t:c['headers'][known].update(known_conditional_header=c['headers'][known]['known_conditional_header']+'borrowed'),conditional)
    trial('unresolved-reference-guessed',lambda p,c,t:c['headers'][unresolved].update(known_conditional_header='HASH(0x123)'),conditional)
    trial('lost-unresolved-slot',lambda p,c,t:c['headers'][unresolved]['unresolved_slots'].pop(),conditional)
    trial('omitted-conditional-header',lambda p,c,t:c['headers'].pop(),conditional)
    trial('raw-scope-promotion',lambda p,c,t:p.update(scope='Original raw/native/private observer qualified.'),'unchanged complete source-header qualification scope')
    owner=(BASE/'scope.txt').read_text().splitlines()[0];parent=owner.rsplit('.',1)[0]
    task='complete unchanged source-header parent/child/raw-join acceptance'
    trial('narrowed-original-parent-acceptance',lambda p,c,t:t['original_bodies'].update({parent:t['original_bodies'][parent].replace('Acceptance:','Borrowed:',1)}),task)
    trial('lost-prerequisite-child-contract',lambda p,c,t:t['original_bodies'].pop(parent+'.2'),task)
    return result


def custody():
    qualified=load('prerequisites.json')
    need(qualified['revision']==REVISION and qualified['scope']==SCOPE,'complete source-header qualification epoch/scope')
    need(set(qualified['fixed'])=={str(p) for p in inputs()},'whole source-header fixed input membership')
    for path in inputs():
        command=['git','--no-replace-objects','show',REVISION+':'+str(path)]
        actual=subprocess.run(command,capture_output=True)
        need(actual.returncode==0 and actual.stderr==b'' and actual.stdout==path.read_bytes()
             and same(qualified['fixed'][str(path)],dict(command=command,status=0,identity=pin(actual.stdout))),
             'whole fixed/current source-header input custody')
    readers=prerequisites.readers();need(set(qualified['readers'])==set(readers),'complete fresh header prerequisite reader set')
    for name,arguments in readers.items():
        item=qualified['readers'][name];actual=load(item['receipt'])
        context='complete fixed committed inputs' if 'dated-' in name else 'current fixed source inputs'
        need(item['context']==context and actual['command']==['python3','-B',*arguments]
             and type(actual['status']) is int and actual['status']==0 and actual['stderr']=='' and 'PASS ' in actual['stdout']
             and item['identity']==pin(canonical(actual)),'whole actual fresh prerequisite and its qualified publication context')
    command=['python3','-B',str(VALUES/'verify.py')]
    actual=subprocess.run(command,capture_output=True,text=True)
    need(type(actual.returncode) is int and actual.returncode==0 and actual.stderr=='' and actual.stdout.startswith('PASS '),
         'fresh whole source-value parent and dated-publication custody replay')
    return dict(command=command,status=actual.returncode,stdout=actual.stdout,stderr=actual.stderr,
                programme=pin((VALUES/'verify.py').read_bytes()))


def main():
    fresh=custody();product,current,task_contracts=(load(name) for name in ('headers.json','current-headers.json','contracts.json'))
    result=validate(product,current,task_contracts)
    need(same(result,load('independent-proof.json')),'complete independent source-header proof')
    need(same(oracle.public_contract(),load('public-grammar-proof.json')),'whole independently replayed public grammar and native bindings')
    need(same(derive.product(),product) and same(current_headers.evaluate(product),current),
         'whole complete producer source and known-header hypothesis replay')
    selection=load('selection.json');epoch=load('actual-source-selection-1.json')['programs']
    need(selection['scope']==SCOPE and selection['original_raw_intake_present'] is False
         and selection['product']==pin(canonical(product)),'complete pre-comparison source selection')
    for name,identity in selection['programmes'].items():
        need(pin(epoch[name]['body'].encode())==identity,'every whole actual pre-comparison programme epoch')
    need(same(controls(product,current,task_contracts),load('controls.json')),'every whole genuine source/header/value/profile/acceptance candidate')
    for path in BASE.glob('actual-*.json'):
        actual=read(path)
        need(type(actual['status']) is int and type(actual['stdout']) is str and type(actual['stderr']) is str,
             'complete typed actual source-header result including first failures')
        for programme in actual['programs'].values():
            need(pin(programme['body'].encode())==programme['identity'],'whole retained actual source-header programme body')
    source=subprocess.check_output(task_contracts['command'],text=True)
    owner=(BASE/'scope.txt').read_text().splitlines()[0];successor=owner.rsplit('.',2)[0]+'.3'
    predecessor=source
    for identifier in (owner,owner.rsplit('.',1)[0]):
        block=contracts.block(predecessor,identifier)
        import re
        complete=re.sub(r'^  Status: `[^`]+`$', '  Status: `done`',block,count=1,flags=re.M)
        predecessor=predecessor.replace(block,complete,1)
    old=contracts.block(predecessor,successor);progress=[]
    for status in ('active','done'):
        new=old.replace('  Status: `pending`','  Status: `'+status+'`',1);candidate=predecessor.replace(old,new,1)
        need(candidate!=source and same(contracts.derive(current=candidate),task_contracts),
             'valid separately owned original raw-join successor progress')
        progress.append(dict(status=status,source_command=task_contracts['command'],source=pin(source.encode()),
            candidate=pin(candidate.encode()),whole_changed_successor=new,result='accepted'))
    proof=dict(result=result,contracts=pin(canonical(task_contracts)),controls=pin((BASE/'controls.json').read_bytes()),
        public_grammar=pin((BASE/'public-grammar-proof.json').read_bytes()),fresh_source_value_custody=fresh,
        successor_progress=progress,scope=SCOPE)
    if (BASE/'proof.json').exists():
        need(same(load('proof.json'),proof),'whole immutable complete source-header qualification proof')
    else:
        save('proof.json',proof)
    if (BASE/'manifest.json').exists():
        need(load('manifest.json')=={str(p.relative_to(BASE)):pin(p.read_bytes()) for p in BASE.rglob('*')
             if p.is_file() and p.name not in ('manifest.json','checks.json')},'entire immutable source-header qualification namespace')
    print('PASS complete source-selected own header/argument/member/order/role hypotheses and unchanged parent acceptance, whole known conditional texts, typed original uncertainties, genuine controls and full custody; original raw joining/native/private/visual scopes retain.')


if __name__=='__main__':
    main()
