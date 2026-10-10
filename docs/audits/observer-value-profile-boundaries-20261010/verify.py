"""Qualify complete remaining-value acceptance with independent whole controls."""
import base64
import copy
import gzip
import subprocess
from pathlib import Path
from common import BASE,CENSUS,PREDICATE,SCALAR,REGEX,PUBLIC,RAW,REPAIR,REVISION,SCOPE,canonical,load,need,pin,read,same,save
import derive
import opaque
import oracle
import prerequisites
import checkpoint
import scope_verify


def validate(product,evidence,contracts):
    need(same(contracts,scope_verify.derive()),'whole unchanged original parent/child/higher acceptance')
    source=read(CENSUS/'source-models.json')
    result=oracle.verify_source(source,read(PREDICATE/'predicate-values-qualified.json'),read(SCALAR/'scalars.json'),
        read(REGEX/'regexes.json'),read(REGEX/'plan.json'),product)
    result['opaque']=oracle.verify_opaque(source,read(PUBLIC),read(RAW),evidence)
    return result


def falsify(product,evidence,contracts):
    result=[]
    def trial(name,change,cause):
        p,e,c=copy.deepcopy((product,evidence,contracts));change(p,e,c)
        need(not same([p,e,c],[product,evidence,contracts]),'genuine complete value/profile hostile candidate')
        try:
            validate(p,e,c)
        except ValueError as error:
            need(str(error)==cause,'intended value/profile rejection: '+name+': '+str(error))
            result.append(dict(name=name,cause=cause,status='rejected',candidate_gzip_base64=base64.b64encode(
                gzip.compress(canonical(dict(product=p,evidence=e,contracts=c)),mtime=0)).decode()))
        else:
            raise ValueError('accepted whole value/profile candidate: '+name)
    operands='whole independent source/profile field: operands'
    phases='whole independent source/profile field: phases'
    trial('omitted-source-member',lambda p,e,c:p['operands'].pop(),operands)
    trial('reordered-source-members',lambda p,e,c:p['operands'].reverse(),operands)
    trial('wrong-source-role',lambda p,e,c:p['operands'][0]['input'].update(role='borrowed'),operands)
    trial('wrong-schema',lambda p,e,c:p['operands'][0].update(schema='reference'),operands)
    trial('borrowed-predicate-zero',lambda p,e,c:next(r for r in p['operands'] if r['qualification']['kind']=='qualified whole guard construction'
        and r['qualification']['string_value']=='')['qualification'].update(string_value='0'),operands)
    trial('lost-complete-scalar-tail',lambda p,e,c:next(r for r in p['operands'] if r['qualification']['kind']=='qualified complete scalar value'
        and type(r['qualification']['value']) is str and len(r['qualification']['value'])>64)['qualification'].update(value='borrowed prefix'),operands)
    trial('promoted-inherited-inner',lambda p,e,c:next(r for r in p['operands'] if r['qualification'].get('evidence_role')=='inherited serialized evidence')
        ['qualification'].update(evidence_role='independent semantic source'),operands)
    trial('wrong-regex-modifiers',lambda p,e,c:next(r for r in p['operands'] if r['schema']=='regex_source')
        ['qualification']['authored'].update(authored_modifiers='i'),operands)
    trial('borrowed-original-reference-identity',lambda p,e,c:next(r for r in p['operands'] if r['schema']=='reference')
        ['qualification'].update(original_address_identity_flags_referent='current fixture address'),operands)
    trial('original-settings-promotion',lambda p,e,c:p['phases'][0].update(original_settings_formatter='measured'),phases)
    trial('private-eval-purpose-promotion',lambda p,e,c:p['phases'][0].update(private_framework_eval_meaning='known implementation'),phases)
    trial('require-replaces-source-do',lambda p,e,c:p['phases'][0]['source_public'].update(source_operator='require'),phases)
    trial('diagnostic-marker-promotes-operator',lambda p,e,c:p['phases'][0].update(diagnostic_marker_changes_source_operator=True),phases)
    trial('omitted-obligation',lambda p,e,c:p['obligations']['source_scalar_constructor_encoding'].pop(),
          'whole independent source/profile field: obligations')
    trial('reordered-obligation',lambda p,e,c:p['obligations']['original_display_profile'].reverse(),
          'whole independent source/profile field: obligations')
    trial('wrong-load-role',lambda p,e,c:p['loads'][0].update(source_operator='require'),'whole independent source/profile field: loads')
    trial('borrowed-current-profile',lambda p,e,c:p['regex_public_profile'].update(MaxArgNums=8),
          'whole independent source/profile field: regex_public_profile')
    trial('source-scope-promotion',lambda p,e,c:p.update(scope='Full original headers qualified.'),'unchanged source/profile/native scope')
    trial('omitted-opaque-phase',lambda p,e,c:e['phases'].pop(),'whole independent original opaque field: phases')
    trial('borrowed-receiver-token',lambda p,e,c:e['phases'][0]['original_public_boundary']['public_header_compatibility'].update(receiver_opaque='current fixture receiver'),
          'whole independent original opaque field: phases')
    trial('omitted-private-frame',lambda p,e,c:next(r for r in e['phases'] if r['original_public_boundary']['remaining_framework'])
        ['original_public_boundary']['remaining_framework'].pop(),'whole independent original opaque field: phases')
    trial('borrowed-eval-boundary',lambda p,e,c:e['phases'][0]['original_public_boundary'].update(own_eval_positions=[]),
          'whole independent original opaque field: phases')
    trial('lost-original-body-tail',lambda p,e,c:next(iter(e['original_records'].values()))['record'].update(body='borrowed prefix'),
          'whole independent original opaque field: original_records')
    trial('opaque-scope-promotion',lambda p,e,c:e.update(scope='Original private meanings measured.'),'unchanged inherited original-evidence scope')
    owner=(BASE/'scope.txt').read_text().splitlines()[0];parent=owner.rsplit('.',1)[0]
    trial('narrowed-parent-acceptance',lambda p,e,c:c['original_bodies'].update({parent:c['original_bodies'][parent].replace('Acceptance:','Borrowed:',1)}),
          'whole unchanged original parent/child/higher acceptance')
    trial('lost-child-contract',lambda p,e,c:c['original_bodies'].pop(parent+'.1'),
          'whole unchanged original parent/child/higher acceptance')
    return result


def prerequisites_check():
    qualified=load('prerequisites-qualified.json')
    need(qualified['revision']==REVISION and qualified['scope']==SCOPE
         and set(qualified['readers'])==set(prerequisites.readers()),'whole qualified prerequisite population and scope')
    need(set(qualified['fixed'])=={str(p) for p in prerequisites.inputs()},'whole fixed prerequisite input membership')
    for path in prerequisites.inputs():
        command=['git','--no-replace-objects','show',REVISION+':'+str(path)]
        actual=subprocess.run(command,capture_output=True)
        need(actual.returncode==0 and actual.stderr==b'' and actual.stdout==path.read_bytes()
             and qualified['fixed'][str(path)]==dict(command=command,status=0,identity=pin(actual.stdout)),
             'whole current/fixed prerequisite byte identity')
    for name,arguments in prerequisites.readers().items():
        item=qualified['readers'][name]
        record=load(item['receipt'])
        need(item['identity']==pin(canonical(record)) and type(record['status']) is int and record['status']==0
             and record['stderr']=='' and 'PASS ' in record['stdout'],'complete actual fresh prerequisite success')
        need(record['command']==['python3','-B',*arguments],'whole exact successful reader command')
        if name=='regex-publication-repair':
            wrong=load('actual-prerequisite-'+name+'-1.json')
            need(item['context']=='complete fixed committed inputs' and item['first_wrong_context']==pin(canonical(wrong))
                 and type(wrong['status']) is int and wrong['status']!=0,'wrong current-task context remains rejected')
            listing=['git','--no-replace-objects','ls-tree','-r','--name-only',REVISION,'--',*checkpoint.PREFIXES]
            names=subprocess.check_output(listing,text=True).splitlines()
            need(set(record['members'])==set(names) and record['cwd']==str(checkpoint.ROOT)
                 and record['revision']==REVISION and record['scope']==SCOPE,'whole exact fixed publication execution context')
            for path in names:
                raw=subprocess.check_output(['git','--no-replace-objects','show',REVISION+':'+path])
                need(record['members'][path]==dict(command=['git','--no-replace-objects','show',REVISION+':'+path],
                     status=0,identity=pin(raw)) and record['before'][path]==record['after'][path]==pin(raw),
                     'every whole committed checkpoint input and before/after byte identity')
        else:
            need(item['context']=='current fixed source inputs','current source versus dated publication context')
    command=['python3','-B',str(BASE/'checkpoint.py'),'--replay']
    fresh=subprocess.run(command,capture_output=True,text=True)
    need(type(fresh.returncode) is int and fresh.returncode==0 and fresh.stderr=='' and fresh.stdout.startswith('PASS '),
         'fresh complete fixed-context publication replay')
    return dict(command=command,status=fresh.returncode,stdout=fresh.stdout,stderr=fresh.stderr,
        program=pin((BASE/'checkpoint.py').read_bytes()))


def main():
    custody=prerequisites_check()
    product,evidence,contracts=(load(n) for n in ('source-products.json','opaque-evidence.json','task-contracts.json'))
    result=validate(product,evidence,contracts)
    need(same({k:v for k,v in result.items() if k!='opaque'},load('source-proof.json')),'complete independent source join proof')
    need(same(result['opaque'],load('opaque-proof.json')),'complete separate original opaque custody proof')
    need(same(derive.source_product(read(CENSUS/'source-models.json'),read(CENSUS/'census.json'),
        read(PREDICATE/'predicate-values-qualified.json'),read(SCALAR/'scalars.json'),read(REGEX/'regexes.json'),read(REGEX/'plan.json')),product)
        and same(opaque.derive(product,read(PUBLIC),read(RAW)),evidence),'whole source and opaque products rederive independently of saved results')
    selection=load('source-selection.json');epoch=load('actual-source-selection-1.json')['programs']
    need(selection['opaque_evidence_present'] is False and selection['scope']==SCOPE
         and selection['product']==pin(canonical(product)),'whole source-first hypothesis selection')
    for name,identity in selection['programs'].items():
        need(pin(epoch[name]['body'].encode())==identity,'complete retained source-first programme epoch')
    for path in (PUBLIC,RAW):
        actual=subprocess.check_output(['git','--no-replace-objects','show',REVISION+':'+str(path)])
        need(actual==path.read_bytes() and load('boundary-inputs.json')['inputs'][str(path)]['identity']==pin(actual),
             'whole original opaque input custody')
    controls=falsify(product,evidence,contracts)
    need(same(controls,load('controls.json')),'whole independently replayed genuine acceptance/profile/value controls')
    for path in BASE.glob('actual-*.json'):
        actual=read(path)
        need(type(actual['status']) is int and type(actual['stdout']) is str and type(actual['stderr']) is str,
             'complete typed actual result including first failure')
        for program in actual['programs'].values():
            need(pin(program['body'].encode())==program['identity'],'whole actual programme epoch')
    proof=dict(result=result,contracts=pin(canonical(contracts)),controls=pin(canonical(controls)),
        fresh_dated_publication=custody,scope=SCOPE)
    if (BASE/'proof.json').exists():
        need(same(proof,load('proof.json')),'whole immutable remaining-value qualification proof')
    else:
        save('proof.json',proof)
    if (BASE/'manifest.json').exists():
        need(load('manifest.json')=={str(p.relative_to(BASE)):pin(p.read_bytes()) for p in BASE.rglob('*')
             if p.is_file() and p.name not in ('manifest.json','checks.json')},'whole immutable value/profile qualification namespace')
    print('PASS complete original remaining-value acceptance, independently reconstructed source obligations and explicit original opaque/profile boundaries, whole inherited bodies and genuine controls; higher header/raw/native/private scopes retain.')


if __name__=='__main__':
    main()
