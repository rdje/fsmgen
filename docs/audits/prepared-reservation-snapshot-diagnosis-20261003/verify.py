import argparse,copy,hashlib,json,subprocess
from pathlib import Path
B=Path(__file__).parent
OLD=Path('docs/audits/prepared-reservation-cause-repair-20261003')
parser=argparse.ArgumentParser();parser.add_argument('--trust-mutated',action='store_true');args=parser.parse_args()
def load(p):return json.loads(p.read_text())
def equal(a,b):return json.dumps(a,sort_keys=True,separators=(',',':'))==json.dumps(b,sort_keys=True,separators=(',',':'))
def restore(node,nodes=None,path=''):
    nodes={} if nodes is None else nodes
    if not isinstance(node,list):return node
    assert len(node)==2 and node[0] in ('hash','array','reference'),('node',path)
    kind,value=node
    if kind=='reference':
        assert value in nodes,('reference',path,value)
        return nodes[value]
    out={} if kind=='hash' else [];nodes[path]=out
    if kind=='hash':
        assert isinstance(value,dict),path
        for key in sorted(value):out[key]=restore(value[key],nodes,path+'/'+key.replace('~','~0').replace('/','~1'))
    else:
        assert isinstance(value,list),path
        out.extend(restore(child,nodes,path+'/'+str(i)) for i,child in enumerate(value))
    return out
# Independent expansion to the sealed predecessor's active-back-edge format.
def plain(value,active=None,path=''):
    active={} if active is None else active
    if not isinstance(value,(dict,list)):return value
    identity=id(value)
    if identity in active:return {'$cycle':active[identity]}
    nested={**active,identity:path}
    if isinstance(value,dict):return {key:plain(child,nested,path+'/'+key) for key,child in value.items()}
    return [plain(child,nested,path+'/'+str(i)) for i,child in enumerate(value)]
def differences(a,b,path=''):
    if type(a) is not type(b):return [(path,type(a).__name__,type(b).__name__,a,b)]
    if isinstance(a,dict):
        assert a.keys()==b.keys(),('keys',path)
        return sum((differences(a[k],b[k],path+'/'+k) for k in sorted(a)),[])
    if isinstance(a,list):
        assert len(a)==len(b),('length',path)
        return sum((differences(x,y,path+'/'+str(i)) for i,(x,y) in enumerate(zip(a,b))),[])
    assert a==b,('value',path,a,b)
    return []
# Original worker wait/complete child: native rhs literals, source-bound to
# LoweringIR's entry/control and completion assignments. Both source copies
# are explicit; this finite table is not learned from captured differences.
fields=[f'/1/{prefix}generated_child_products/1/worker/1/{tail}'
        for prefix in ('','domain_source_products/1/core/1/preparation/1/')
        for tail in ('assignment_provenance/1/0/1/rhs','assignment_provenance/1/1/1/rhs',
                     'states/1/2/1/assignments/1/0/1/rhs','states/1/2/1/assignments/1/1/1/rhs')]
expected=sorted((path,'int','str',1,'1') for path in fields)
manifest=load(OLD/'manifest.json')
for name,declared in manifest['members'].items():
    raw=(OLD/name).read_bytes();assert len(raw)==declared['bytes'] and hashlib.sha256(raw).hexdigest()==declared['sha256'],name
bindings=load(B/'bindings.json');rev=bindings['baseline'];assert rev=='3193b92c3669daec5d0a6f2053ed471e015087b0'
for name,declared in bindings['metadata'].items():
    raw=Path(name).read_bytes();assert raw==subprocess.check_output(['git','show',rev+':'+name]),name
    assert len(raw)==declared['bytes'] and hashlib.sha256(raw).hexdigest()==declared['sha256'],name
for name,source in bindings['sources'].items():assert source==Path(name).read_text(),name
test=bindings['sources']['t/1959-isf-prepared-formal-reservations.t']
introduction='d57f11f450a4a39bd892ec21c2730ac6d4dd3cc6'
historical=(B/'introduction-source.txt').read_bytes()
assert historical==subprocess.check_output(['git','show',introduction+':t/1959-isf-prepared-formal-reservations.t'])
assert (B/'introduction.txt').read_text().startswith(introduction+' ')
assert b'my $bad = dclone($domains);' in historical
assert 'my $before = dclone($prepared);' in test and 'is_deeply($prepared, $before,' in test
assert 'my $bad = dclone($domains); $mutation->[0]->($bad);' in test
provider=bindings['sources']['perl/FSM/Scheduler/ISF/LoweringIR.pm']
assert "rhs=>1,op=>'<1',source_kind=>'complete_pulse'" in provider
ordinary=load(B/'observations-ordinary.json');mutated=load(B/'observations-mutate.json')
prior=load(OLD/'current-api.json')['rows']
assert len(ordinary['calls'])==len(mutated['calls'])==len(prior)==64
assert len(ordinary['clones'])==len(mutated['clones'])==116
assert sum(row['accepted'] for row in ordinary['calls'])==6
clone_gaps=[]
for i,row in enumerate(ordinary['clones']):
    assert equal(row['before'],row['after']),('clone caller',i)
    delta=sorted(differences(row['before'],row['clone']))
    if row['line']==123:
        assert delta==expected,('declared clone differences',i,delta)
        clone_gaps.append(i)
    else:assert not delta,('unexpected clone gap',i,delta)
assert clone_gaps==list(range(98,116,2)),clone_gaps
mutation_path='/1/generated_child_products/1/worker/1/assignment_provenance/1/0/1/rhs'
mutation_indices=[]
for i,(current,control,old) in enumerate(zip(ordinary['calls'],mutated['calls'],prior)):
    assert equal(current['before'],current['after']),('ordinary caller',i)
    assert equal(plain(restore(current['before'])),old['before']),('prior input',i)
    assert equal(plain(restore(current['after'])),old['after']),('prior after',i)
    assert current['accepted']==control['accepted']==old['accepted'],('acceptance',i)
    assert current['error'].split('\n')[0]==control['error'].split('\n')[0]==old['error'].split('\n')[0],('primary cause',i)
    assert equal(current['before'],control['before']),('mutated initial input',i)
    assert equal(current['result'],control['result']),('mutated provider result',i)
    assert equal(plain(restore(current['result'])) if current['accepted'] else None,old['result']),('whole result',i)
    delta=differences(control['before'],control['after'])
    if control['mutation'] is not None:
        assert control['mutation']=='/generated_child_products/worker/assignment_provenance/0/rhs'
        assert len(delta)==1 and delta[0][0]==mutation_path
        assert delta[0][1:]==(('int','str',1,'1') if current['accepted'] else ('str','int','1',1)),delta
        mutation_indices.append(i)
    else:assert not delta,('unintended mutation',i)
assert len(mutation_indices)==10,mutation_indices
for mode in ('ordinary','mutate'):
    assert (B/(mode+'.status')).read_text().strip()=='0'
    receipt=(B/(mode+'.txt')).read_text()
    assert 'All tests successful.' in receipt and 'Files=1, Tests=4,' in receipt
if args.trust_mutated:
    for i,row in enumerate(mutated['calls']):assert equal(row['before'],row['after']),('false kind conservation',i)
# Rejected corruptions independently falsify source-kind and native-topology
# equality; actual consumer mutation above is the behavioral falsifier.
corrupt=copy.deepcopy(ordinary['clones'][98]['clone'])
corrupt[1]['generated_child_products'][1]['worker'][1]['assignment_provenance'][1][0][1]['rhs']=1
assert sorted(differences(ordinary['clones'][98]['before'],corrupt))!=expected
cycle=next(row for row in ordinary['calls'] if row['error'].startswith('Formal reservation inventory has a cycle'))
corrupt=copy.deepcopy(cycle['after']);corrupt[1]['actor_context'][1]['cycle']=['reference','/actor']
assert not equal(cycle['before'],corrupt)
print('PASS complete unchanged source/Git closure; authenticated prior whole inputs, acceptance, causes and outputs; all ordinary callers and clone originals preserve kinds/topology.')
print('PASS literal domain clone-gap table and actual consumer kind-only mutation falsifier; value/kind and cycle-topology corruptions rejected. Wider native and constructor semantics stay cold.')
