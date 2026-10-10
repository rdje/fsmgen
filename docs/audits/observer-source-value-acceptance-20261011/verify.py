"""Independent complete source-value parent and unchanged-contract qualification."""
import base64
import copy
import gzip
import subprocess
from pathlib import Path
from common import BASE, CENSUS, PREDICATE, SCALAR, REGEX, BOUNDARY, REVISION, SCOPE, canonical, fixed_inputs, load, need, pin, read, same, save
import contracts
import prerequisites
import value_oracle


def expected():
    source=read(CENSUS/'source-models.json')
    predicate=read(PREDICATE/'predicate-values-qualified.json')
    scalar=read(SCALAR/'scalars.json')
    regex=read(REGEX/'regexes.json')
    values=value_oracle.source_expected(source,predicate,scalar,regex,read(REGEX/'plan.json'))
    obligations={}
    for name,resolutions in values['obligations'].items():
        obligations[name]=[]
        for resolution in resolutions:
            rows=values['operands'] if resolution['resolution_kind']=='operand' else values['phases']
            value=rows[resolution['resolution_index']]
            need(value['path']==resolution['path'],'independent whole obligation/source-member allocation')
            obligations[name].append(dict(resolution=resolution,value=value))
    # Read each entire fixture/driver/public contract independently. Prior
    # constructor readers qualify their native meaning; this join conserves
    # every byte and never reinterprets a current capture as original settings.
    public={}
    for kind,directory in [('predicate',PREDICATE),('scalar',SCALAR),('regex',REGEX)]:
        public[kind]=dict(
            plan=read(directory/('fixture-plan-qualified.json' if kind=='predicate' else 'plan.json')),
            native=read(directory/('native-qualified.json' if kind=='predicate' else 'native.json')),
            driver=(directory/('native-qualified.pl' if kind=='predicate' else 'native.pl')).read_text())
        if kind=='predicate':
            public[kind]['intervention_plan']=read(directory/'native-control-plan.json')
        if kind!='scalar':
            public[kind]['public_contracts']=read(directory/'public-contracts.json')
    public['meaning']='Whole qualified source-neutral public constructions only; no current fixture supplies an original setting, native identity or private meaning.'
    return dict(scope=SCOPE,source_values=values,obligations=obligations,predicate=predicate,scalar=scalar,regex=regex,
        public_constructions=public,dependencies={str(p):pin(p.read_bytes()) for p in fixed_inputs()},
        source_selection=read(BOUNDARY/'source-selection.json'),
        original_opaque=dict(source='separately retained whole original boundary evidence',
            identity=pin((BOUNDARY/'opaque-evidence.json').read_bytes()),semantic_oracle=False,
            native_identity='unmeasured',private_meanings='unmeasured'),
        next_scope='Full source-generated original headers remain separately owned; no original raw-header comparison occurs here.')


def constructor_bindings(public):
    for kind,directory in [('predicate',PREDICATE),('scalar',SCALAR),('regex',REGEX)]:
        fixture=public[kind]
        plan=pin(canonical(fixture['plan']))
        driver=pin(fixture['driver'].encode())
        native=fixture['native']
        if kind=='predicate':
            need(native['plan']==plan and native['driver']==driver,
                 'actual whole native plan/driver binding: '+kind)
        else:
            need(native['inputs'][str(directory/'plan.json')]==plan
                 and native['inputs'][str(directory/'native.pl')]==driver,
                 'actual whole native plan/driver binding: '+kind)


def validate(product,task_contracts):
    wanted=expected()
    need(product['scope']==SCOPE,'unchanged complete source-value acceptance scope')
    need(set(product)==set(wanted),'closed complete source-value product fields')
    for kind in ('predicate','scalar','regex'):
        native=product['public_constructions'][kind]['native']
        need(type(native['status']) is int and native['status']==0 and native['stderr']=='',
             'typed whole public constructor success: '+kind)
    constructor_bindings(product['public_constructions'])
    for field,value in wanted.items():
        need(same(product[field],value),'entire independent source-value parent field: '+field)
    need(same(task_contracts,contracts.derive()),'complete unchanged source-value parent/child/header contracts')
    return dict(product=pin(canonical(wanted)),contracts=pin(canonical(task_contracts)),scope=SCOPE)


def falsify(product,task_contracts):
    result=[]
    def trial(name,mutate,cause):
        p,c=copy.deepcopy((product,task_contracts))
        mutate(p,c)
        need(not same([p,c],[product,task_contracts]),'genuine complete hostile parent candidate')
        try:
            validate(p,c)
        except ValueError as error:
            need(str(error)==cause,'intended parent control failure: '+name+': '+str(error))
            result.append(dict(name=name,cause=cause,status='rejected',
                candidate_gzip_base64=base64.b64encode(gzip.compress(canonical(dict(product=p,contracts=c)),mtime=0)).decode()))
        else:
            raise ValueError('accepted hostile source-value parent: '+name)
    field=lambda name:'entire independent source-value parent field: '+name
    trial('omitted-source-member',lambda p,c:p['source_values']['operands'].pop(),field('source_values'))
    trial('reordered-source-members',lambda p,c:p['source_values']['operands'].reverse(),field('source_values'))
    trial('wrong-whole-source-expression',lambda p,c:p['source_values']['operands'][0]['input'].update(role='borrowed'),field('source_values'))
    trial('wrong-whole-source-schema',lambda p,c:p['source_values']['operands'][0].update(schema='borrowed'),field('source_values'))
    name=next(iter(product['obligations']))
    trial('omitted-original-obligation',lambda p,c:p['obligations'].pop(name),field('obligations'))
    trial('reordered-obligation-members',lambda p,c:p['obligations'][name].reverse(),field('obligations'))
    trial('borrowed-obligation-value',lambda p,c:p['obligations'][name][0].update(value=p['obligations'][name][1]['value']),field('obligations'))
    trial('borrowed-predicate-logical-zero',lambda p,c:p['predicate']['rows'][0].update(string_value='0'),field('predicate'))
    key=next(k for k,v in product['scalar']['values'].items() if type(v['value']) is str and len(v['value'])>64)
    trial('lost-entire-scalar-tail',lambda p,c:p['scalar']['values'][key].update(value=p['scalar']['values'][key]['value'][:61]),field('scalar'))
    trial('wrong-scalar-constructor',lambda p,c:p['scalar']['values'][key].update(constructor='numeric literal'),field('scalar'))
    trial('inherited-inner-meaning-promotion',lambda p,c:next(r for r in p['scalar']['members'] if r['evidence_role']=='inherited serialized evidence').update(evidence_role='new semantic oracle'),field('scalar'))
    trial('wrong-regex-modifiers',lambda p,c:p['regex']['authored'][0].update(modifiers='i'),field('regex'))
    trial('wrong-current-regex-encoding',lambda p,c:p['public_constructions']['regex']['plan']['cases'][0].update(pattern_utf8=True),'actual whole native plan/driver binding: regex')
    trial('borrowed-current-scalar-profile',lambda p,c:p['public_constructions']['scalar']['plan']['profile'].update(MaxArgNums=8),'actual whole native plan/driver binding: scalar')
    trial('lost-entire-public-native-tail',lambda p,c:p['public_constructions']['scalar']['native'].update(stdout=p['public_constructions']['scalar']['native']['stdout'][:-1]),field('public_constructions'))
    trial('boolean-public-native-status',lambda p,c:p['public_constructions']['predicate']['native'].update(status=False),'typed whole public constructor success: predicate')
    trial('borrowed-public-driver',lambda p,c:p['public_constructions']['regex'].update(driver='borrowed driver'),'actual whole native plan/driver binding: regex')
    trial('first-accepted-wrong-predicate-plan',lambda p,c:p['public_constructions']['predicate'].update(plan=read(PREDICATE/'native-control-plan.json')),'actual whole native plan/driver binding: predicate')
    trial('borrowed-public-language-contract',lambda p,c:p['public_constructions']['predicate'].update(public_contracts={}),field('public_constructions'))
    trial('source-do-replaced-by-require',lambda p,c:p['source_values']['phases'][0]['source_public'].update(source_operator='require'),field('source_values'))
    trial('original-private-meaning-promotion',lambda p,c:p['original_opaque'].update(private_meanings='qualified'),field('original_opaque'))
    trial('original-native-identity-promotion',lambda p,c:p['original_opaque'].update(native_identity='current fixture'),field('original_opaque'))
    trial('original-raw-as-source-oracle',lambda p,c:p['original_opaque'].update(semantic_oracle=True),field('original_opaque'))
    trial('borrowed-fixed-input-identity',lambda p,c:p['dependencies'].pop(next(iter(p['dependencies']))),field('dependencies'))
    trial('borrowed-source-first-selection',lambda p,c:p['source_selection'].update(opaque_evidence_present=True),field('source_selection'))
    trial('full-header-scope-promotion',lambda p,c:p.update(next_scope='Full original headers qualified.'),field('next_scope'))
    trial('native-scope-promotion',lambda p,c:p.update(scope=SCOPE+' Original flags qualified.'),'unchanged complete source-value acceptance scope')
    owner=(BASE/'scope.txt').read_text().splitlines()[0];parent=owner.rsplit('.',1)[0]
    trial('narrowed-original-parent-acceptance',lambda p,c:c['original_bodies'].update({parent:c['original_bodies'][parent].replace('Acceptance:','Borrowed:',1)}),'complete unchanged source-value parent/child/header contracts')
    trial('lost-complete-child-contract',lambda p,c:c['original_bodies'].pop(parent+'.1'),'complete unchanged source-value parent/child/header contracts')
    return result


def custody():
    qualified=load('prerequisites-qualified.json')
    first=load('prerequisites.json')
    extension=load('prerequisites-input-extension.json')
    need(set(first['fixed'])==set(qualified['fixed'])-{str(PREDICATE/'fixture-plan-qualified.json')}
         and all(first['fixed'][k]==qualified['fixed'][k] for k in first['fixed'])
         and first['readers']==qualified['readers']
         and extension['fixed']=={str(PREDICATE/'fixture-plan-qualified.json'):qualified['fixed'][str(PREDICATE/'fixture-plan-qualified.json')]}
         and extension['first']==pin(canonical(first)) and extension['scope']==SCOPE,
         'whole first prerequisite epoch plus independently authenticated exact input extension')
    need(qualified['scope']==SCOPE and qualified['revision']==REVISION,'complete fixed source-value qualification epoch')
    need(set(qualified['fixed'])=={str(p) for p in fixed_inputs()},'whole fixed source-value input population')
    for path in fixed_inputs():
        command=['git','--no-replace-objects','show',REVISION+':'+str(path)]
        actual=subprocess.run(command,capture_output=True)
        need(actual.returncode==0 and actual.stderr==b'' and actual.stdout==path.read_bytes()
             and same(qualified['fixed'][str(path)],dict(command=command,status=0,identity=pin(actual.stdout))),
             'whole fixed/current complete source-value input')
    readers=prerequisites.readers()
    need(set(qualified['readers'])==set(readers),'complete actual prerequisite reader set')
    for name,args in readers.items():
        item=qualified['readers'][name];record=load(item['receipt'])
        context='complete fixed committed inputs' if 'dated-publication' in name else 'current fixed source inputs'
        need(item['context']==context and record['command']==['python3','-B',*args]
             and type(record['status']) is int and record['status']==0 and record['stderr']=='' and 'PASS ' in record['stdout']
             and item['identity']==pin(canonical(record)),'whole actual fresh prerequisite and proper publication context')
    command=['python3','-B',str(BOUNDARY/'verify.py')]
    actual=subprocess.run(command,capture_output=True,text=True)
    need(type(actual.returncode) is int and actual.returncode==0 and actual.stderr=='' and actual.stdout.startswith('PASS '),
         'fresh complete current child and dated-publication custody replay')
    return dict(command=command,status=actual.returncode,stdout=actual.stdout,stderr=actual.stderr,
                program=pin((BOUNDARY/'verify.py').read_bytes()))


def main():
    fresh=custody()
    product,task_contracts=load('product-qualified.json'),load('contracts.json')
    proof=validate(product,task_contracts)
    need(same(proof,load('independent-proof-qualified.json')),'complete corrected independent parent proof')
    first=load('product.json')
    try:
        validate(first,task_contracts)
    except ValueError as error:
        need(str(error)=='actual whole native plan/driver binding: predicate','first accepted wrong-plan product now rejects at intended native binding')
    else:
        raise ValueError('first wrong-plan product accepted')
    need(same(falsify(product,task_contracts),load('controls-qualified.json')),'whole genuine parent acceptance controls replay')
    for path in BASE.glob('actual-*.json'):
        record=read(path)
        need(type(record['status']) is int and type(record['stdout']) is str and type(record['stderr']) is str,
             'typed complete actual result including first failures')
        for program in record['programs'].values():
            need(pin(program['body'].encode())==program['identity'],'entire retained actual programme epoch')
    need(same(load('binding-repair-proof.json'),dict(first_product=pin(canonical(first)),
        actual_initial_acceptance=pin(canonical(load('actual-independent-products-1.json'))),
        corrected=validate(product,task_contracts),first_rejection='actual whole native plan/driver binding: predicate',scope=SCOPE)),
        'complete independent first-acceptance and corrected-binding repair proof')
    source=subprocess.check_output(task_contracts['command'],text=True)
    owner=(BASE/'scope.txt').read_text().splitlines()[0]
    successor=owner.rsplit('.',2)[0]+'.3'
    prior=contracts.block(source,successor)
    progress=[]
    for status in ('active','done'):
        advanced=prior.replace('  Status: `pending`','  Status: `'+status+'`',1)
        candidate=source.replace(prior,advanced,1)
        need(candidate!=source and source.count(prior)==1,
             'genuine whole fixed-task successor progress candidate')
        need(same(contracts.derive(current=candidate),task_contracts),
             'valid separately owned successor progress preserves complete parent contracts')
        progress.append(dict(status=status,source_command=task_contracts['command'],source=pin(source.encode()),
            candidate=pin(candidate.encode()),whole_changed_successor=advanced,result='accepted'))
    proof.update(successor_progress=progress)
    proof.update(fresh_complete_child_custody=fresh,controls=pin((BASE/'controls-qualified.json').read_bytes()))
    if (BASE/'proof.json').exists():
        need(same(proof,load('proof.json')),'entire immutable source-value parent proof')
    else:
        save('proof.json',proof)
    if (BASE/'manifest.json').exists():
        need(load('manifest.json')=={str(p.relative_to(BASE)):pin(p.read_bytes()) for p in BASE.rglob('*')
             if p.is_file() and p.name not in ('manifest.json','checks.json')},'whole immutable parent qualification namespace')
    print('PASS complete unchanged source-value parent acceptance, every original obligation and whole source-neutral public construction; full headers and original raw/native/private/visual scopes remain separately owned.')


if __name__=='__main__':
    main()
