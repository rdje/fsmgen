"""Replay complete source, public fixtures, first failures, controls and custody."""
import json
from common import BASE, ROLE, canonical, load, need, pin, same, save
import controls
import custody_verify
import fixtures
import model
import native_verify
import oracle
import source
import scope_verify


def main():
    seal=next((name for name in ('manifest-final.json','manifest-qualified.json','manifest.json') if (BASE/name).exists()),'manifest.json')
    if (BASE/seal).exists():
        members={str(p.relative_to(BASE)):pin(p.read_bytes()) for p in BASE.rglob('*')
            if p.is_file() and p.name not in (seal,'checks.json')}
        need(same(members,load(seal)),'entire immutable predicate qualification namespace')
    need(same(scope_verify.derive(),load('task-contracts.json')),'complete unchanged ancestor and successor contracts')
    custody=custody_verify.verify()
    own=load('source-inputs.json'); values=load('predicate-values-qualified.json')
    need(same(source.derive(),own),'entire complete source inputs and guards rederived')
    need(same(model.derive(),values),'entire complete source value derivation repeated')
    result=oracle.verify(own,values)
    raw,plan=fixtures.select()
    need(raw == (BASE/'native-qualified.pl').read_bytes() and same(dict(**plan,driver=pin(raw)),load('fixture-plan-qualified.json')),'whole preselected public constructor source and plan')
    native=native_verify.verify(load('fixture-plan-qualified.json'),load('native-qualified.json'))
    separating=controls.replay()
    history=load('root-history.json')
    need(history['command'] == ['git','--no-pager','log','-1','-S','sub _role','--','perl/FSM/Support/ISFRecordPortValues.pm']
        and history['status'] == 0 and not history['stderr'] and history['stdout'].startswith('commit 02827d840254d6cdbfa4020be7910bb7ae9ac4cb\n'),'actual whole source-normalization history')
    executions={}
    for path in sorted(BASE.glob('actual-*.json')):
        # The complete-reader command writes its receipt after this proof. Its
        # transport belongs to checks, not to the proof's input executions.
        if path.name == 'actual-complete-reader.json': continue
        actual=json.loads(path.read_bytes()); name=path.stem[len('actual-'):]
        for program,identity in actual['programs'].items():
            saved=BASE/'epochs'/name/(program.rsplit('/',1)[1]+'.txt')
            need(saved.is_file() and pin(saved.read_bytes()) == identity,'whole actual program epoch, including first failures')
        need(type(actual['status']) is int and type(actual['stdout']) is str and type(actual['stderr']) is str,'complete actual command result')
        executions[path.name]=pin(path.read_bytes())
    failed={'actual-source-values.json','actual-source-values-qualified.json','actual-source-values-complete.json',
            'actual-independent-source.json','actual-fixture-reader.json'}
    need({p.name for p in BASE.glob('actual-*.json') if load(p.name)['status'] != 0} == failed,'all first failed hypotheses preserved')
    proof=dict(role=ROLE,custody=custody,result=result,native=pin(canonical(native)),controls=separating,executions=executions,
        public_contracts=pin((BASE/'public-contracts.json').read_bytes()))
    if (BASE/'qualified-proof.json').exists(): need(same(load('qualified-proof.json'),proof),'entire immutable predicate proof')
    else: save('qualified-proof.json',proof)
    print('PASS complete predicate source values, independent branches, public constructor/header fixtures, genuine controls, first failures and fixed source custody; original native/settings and all successor scopes stay open.')


if __name__ == '__main__': main()
