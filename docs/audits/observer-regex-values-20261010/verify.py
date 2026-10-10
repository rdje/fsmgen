"""Replay whole authored regex qualification with genuine independent controls."""
import base64
import copy
import gzip
import json
import subprocess
from pathlib import Path
from common import AUTHORITY, BASE, CENSUS, SCALAR, REVISION, SCOPE, canonical, load, need, pin, read, same, save
import derive
import oracle
import prerequisites
import scope_verify
import public_contracts


def validation(product,plan,native):
    result=oracle.source(read(AUTHORITY),read(CENSUS/'source-models.json'),product,plan)
    need(native['command']==['perl','-Iperl',str(BASE/'native.pl')],'exact current regex public capture command')
    need(native['inputs']=={str(BASE/n):pin((BASE/n).read_bytes()) for n in
         ('native.pl','plan.json','pre-observation.json','source-proof.json',
          'prerequisites.json','actual-prerequisites-1.json','public-contracts.json','capture-admission.json')},
         'whole selected regex driver/corpus capture identity')
    result['native']=oracle.native(plan,native,(BASE/'native.pl').read_bytes())
    return result


def falsify(product,plan,native):
    controls=[]
    def trial(name,mutation,cause):
        p,h,n=copy.deepcopy((product,plan,native))
        mutation(p,h,n)
        need(not same([p,h,n],[product,plan,native]),'genuine complete regex hostile candidate')
        try:
            validation(p,h,n)
        except ValueError as error:
            need(str(error)==cause,'intended regex rejection: '+name+': '+str(error))
            candidate=canonical(dict(product=p,plan=h,native=n))
            controls.append(dict(name=name,cause=cause,status='rejected',
                candidate_gzip_base64=base64.b64encode(gzip.compress(candidate,mtime=0)).decode()))
        else:
            raise ValueError('accepted hostile regex candidate: '+name)
    authored='whole independent authored regex expressions/flags/encoding'
    members='complete independent regex member/order/role/schema allocation'
    hypothesis='whole independent regex constructor/value/flags/encoding/display hypotheses'
    trial('changed-authored-expression',lambda p,h,n:p['authored'][0].update(expression='qr/borrowed/'),authored)
    trial('changed-whole-pattern',lambda p,h,n:p['authored'][0].update(body='borrowed'),authored)
    trial('invented-authored-modifier',lambda p,h,n:p['authored'][0].update(authored_modifiers='i'),authored)
    trial('invented-original-native-encoding',lambda p,h,n:p['authored'][0].update(original_native_flags_encoding='measured'),authored)
    trial('omitted-member',lambda p,h,n:p['members'].pop(),members)
    trial('reordered-members',lambda p,h,n:p['members'].reverse(),members)
    trial('borrowed-helper',lambda p,h,n:p['members'][0].update(helper=42),members)
    trial('wrong-role',lambda p,h,n:p['members'][0]['operand'].update(role='borrowed'),members)
    trial('extra-schema-field',lambda p,h,n:p['members'][0]['operand'].update(utf8=True),members)
    trial('original-native-promotion',lambda p,h,n:p.update(scope=SCOPE+' Original identity measured.'),'original versus current regex scope')
    trial('borrowed-profile',lambda p,h,n:h['profile'].update(MaxArgNums=8),'selected complete public profile')
    trial('wrong-selected-flag',lambda p,h,n:h['cases'][0].update(modifiers='i'),hypothesis)
    trial('wrong-selected-encoding',lambda p,h,n:h['cases'][0].update(pattern_utf8=True),hypothesis)
    trial('lost-pattern-tail',lambda p,h,n:h['cases'][0].update(body=h['cases'][0]['body'][:3]),hypothesis)
    trial('false-complete-prefix',lambda p,h,n:h['cases'][0]['display'].update(complete=True),hypothesis)
    def change(n,action):
        d=json.loads(n['stdout']); action(d); n['stdout']=canonical(d).decode()
    trial('boolean-status',lambda p,h,n:n.update(status=False),'actual typed public regex success')
    trial('omitted-native-case',lambda p,h,n:change(n,lambda d:d['rows'].pop()),'complete ordered public regex corpus')
    trial('native-borrowed-profile',lambda p,h,n:change(n,lambda d:d['rows'][0]['profile'].update(MaxArgLen=0)),
          'actual complete selected regex profile')
    trial('native-input-encoding',lambda p,h,n:change(n,lambda d:d['rows'][0].update(source_utf8=True)),
          'current selected constructor input encoding')
    trial('native-pattern-tail',lambda p,h,n:change(n,lambda d:d['rows'][0]['value']['codepoints'].append(88)),
          'whole public compiled pattern/flags/encoding/normalized value')
    trial('native-wrong-flags',lambda p,h,n:change(n,lambda d:d['rows'][0]['value'].update(modifiers='i')),
          'whole public compiled pattern/flags/encoding/normalized value')
    trial('native-wrong-pattern-encoding',lambda p,h,n:change(n,lambda d:d['rows'][0]['value'].update(pattern_utf8=True)),
          'whole public compiled pattern/flags/encoding/normalized value')
    trial('native-whole-trace',lambda p,h,n:change(n,lambda d:d['rows'][0].update(trace=d['rows'][0]['trace']+'borrowed\n')),
          'whole source-generated regex public header and trace')
    return controls


def main():
    need(same(scope_verify.derive(),load('task-contracts.json')),'complete unchanged task contracts')
    need(same(public_contracts.derive(),load('public-contracts.json')),'complete public API contract evidence')
    custody_command=['python3','-B',str(SCALAR/'verify.py')]
    custody=subprocess.run(custody_command,capture_output=True,text=True)
    need(type(custody.returncode) is int and custody.returncode==0 and custody.stderr=='' and custody.stdout.startswith('PASS '),
         'whole current committed scalar/source custody and replay')
    prior=load('prerequisites.json')
    need(prior['revision']==REVISION and prior['scope']==SCOPE and set(prior['fixed'])=={str(p) for p in prerequisites.inputs()},
         'complete fixed regex prerequisite domain')
    for path in prerequisites.inputs():
        command=['git','--no-replace-objects','show',REVISION+':'+str(path)]
        result=subprocess.run(command,capture_output=True)
        need(result.returncode==0 and not result.stderr and result.stdout==path.read_bytes()
             and prior['fixed'][str(path)]==dict(command=command,status=0,identity=pin(result.stdout)),
             'whole fixed/current regex input identity')
    readers=prerequisites.readers()
    need(set(prior['readers'])==set(readers),'whole prerequisite reader population')
    for name,arguments in readers.items():
        actual=load('actual-prerequisite-'+name+'-1.json')
        need(actual['command']==['python3','-B',*arguments] and type(actual['status']) is int and actual['status']==0
             and actual['stderr']=='' and 'PASS ' in actual['stdout'] and prior['readers'][name]==pin(canonical(actual)),
             'complete actual fresh prerequisite execution')
    product,plan,native=load('regexes.json'),load('plan.json'),load('native.json')
    need(same(derive.collect(read(AUTHORITY),read(CENSUS/'census.json'),read(CENSUS/'source-models.json')),product)
         and same(derive.plan(product),plan),'entire source product and selected corpus rederive')
    result=validation(product,plan,native)
    admission=load('capture-admission.json')
    need(admission['native_present'] is False and admission['scope']==SCOPE
         and admission['inputs']=={k:v for k,v in native['inputs'].items() if k!=str(BASE/'capture-admission.json')},
         'whole source-first capture admission and completed prerequisite identity')
    for name,program in admission['programs'].items():
        need(pin(program['body'].encode())==program['identity'],'whole admitted capture programme epoch')
    need(admission['programs'][str(BASE/'native.pl')]['body'].encode()==(BASE/'native.pl').read_bytes(),
         'whole explicit byte-literal constructor selected before observation')
    need(same({k:v for k,v in result.items() if k!='native'},load('source-proof.json')),'entire independent pre-observation proof')
    need(same(result['native'],load('native-proof.json')),'whole separate current regex proof')
    pre=load('pre-observation.json')
    need(pre['native_present'] is False and pre['scope']==SCOPE,'whole source-first hypothesis scope')
    selection=load('actual-source-selection-2.json')
    need(type(selection['status']) is int and selection['status']==0 and selection['stderr']=='','actual corrected source selection success')
    for name,identity in pre['inputs'].items():
        raw=selection['programs'][name]['body'].encode() if name in selection['programs'] else Path(name).read_bytes()
        need(pin(raw)==identity,'whole source-first program/input epoch')
    history=load('actual-root-history-1.json')
    need(history['command']==['git','--no-pager','log','-1','-S','regex_constructor_flags_encoding','--',str(CENSUS/'model.py')]
         and history['status']==0 and type(history['status']) is int and history['stderr']==''
         and history['stdout'].startswith('commit 6715ce66cf7b8a63c3a7f3125d722b578b29ad87\n'),'actual original regex-obligation history')
    controls=falsify(product,plan,native)
    need(same(controls,load('controls.json')),'whole independently replayed genuine regex controls')
    for path in BASE.glob('actual-*.json'):
        record=read(path)
        need(type(record['status']) is int and type(record['stdout']) is str and type(record['stderr']) is str,
             'complete typed actual result including first failures')
        for program in record['programs'].values():
            need(pin(program['body'].encode())==program['identity'],'whole actual program epoch')
    failed=load('actual-source-selection-1.json')
    need(failed['status']!=0 and 'finite authored ASCII pattern alphabet and absent modifiers' in failed['stderr'],
         'retained first finite source alphabet rejection')
    if (BASE/'manifest.json').exists():
        need(load('manifest.json')=={str(p.relative_to(BASE)):pin(p.read_bytes()) for p in BASE.rglob('*')
             if p.is_file() and p.name not in ('manifest.json','checks.json')},'whole immutable regex qualification namespace')
    proof=dict(result=result,controls=pin(canonical(controls)),scope=SCOPE,custody=dict(command=custody_command,
        status=custody.returncode,stdout=custody.stdout,stderr=custody.stderr,program=pin((SCALAR/'verify.py').read_bytes())))
    if (BASE/'proof.json').exists():
        need(same(proof,load('proof.json')),'whole immutable regex qualification proof')
    else:
        save('proof.json',proof)
    print('PASS whole authored regex expressions/source allocations, independent public constructors/flags/encoding/headers and genuine controls; original native identity/settings and parent scopes retain.')


if __name__=='__main__':
    main()
