import argparse,ast,copy,hashlib,json,re,subprocess
from pathlib import Path
B=Path(__file__).parent
OLD=Path('docs/audits/prepared-reservation-snapshot-diagnosis-20261003')
CAUSE=Path('docs/audits/prepared-reservation-cause-repair-20261003')
parser=argparse.ArgumentParser()
parser.add_argument('--trust-prior-copy',action='store_true')
parser.add_argument('--trust-mutation',action='store_true')
args=parser.parse_args()
def authenticate(base):
    manifest=json.loads((base/'manifest.json').read_text())
    for name,record in manifest['members'].items():
        raw=(base/name).read_bytes()
        assert len(raw)==record['bytes'] and hashlib.sha256(raw).hexdigest()==record['sha256'],name
    return manifest
# Reuse only authenticated independent tagged-graph grammar helpers, never the
# predecessor's current-source gate or its conclusions.
authenticate(OLD);authenticate(CAUSE)
source=(OLD/'verify.py').read_text()
tree=ast.parse(source)
names={'load','equal','restore','plain','differences'}
functions=[ast.get_source_segment(source,node) for node in tree.body
           if isinstance(node,ast.FunctionDef) and node.name in names]
assert len(functions)==len(names)
exec('\n\n'.join(functions))
bindings=load(B/'bindings.json')
rev=bindings['baseline'];assert rev=='9c6b6191de86218abae3f29d292373bf935aac1f'
allowed={'t/1959-isf-prepared-formal-reservations.t','t/2062-isf-prepared-reservation-diagnostic-causes.t'}
assert set(bindings['allowed'])==allowed
tree_records=subprocess.check_output(['git','ls-tree','-r','-z',rev,'--','bin','perl','t','scripts','isf'])
git_members={}
for declaration in tree_records.split(b'\0'):
    if not declaration:continue
    header,name=declaration.split(b'\t',1)
    mode,kind,oid=header.decode().split()
    assert kind=='blob' and mode in ('100644','100755')
    git_members[name.decode()]=oid
assert set(git_members)==set(bindings['metadata'])
assert not subprocess.check_output(['git','ls-files','--others','--exclude-standard','--','bin','perl','t','scripts','isf'])
for name,record in bindings['metadata'].items():
    assert record['baseline_blob']==git_members[name],name
    raw=Path(name).read_bytes()
    assert len(raw)==record['bytes'] and hashlib.sha256(raw).hexdigest()==record['sha256'],name
    oid=hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
    assert name in allowed or oid==record['baseline_blob'],name
for name,recorded in bindings['sources'].items():
    assert recorded==Path(name).read_text(),name
    prior=subprocess.check_output(['git','show',rev+':'+name]).decode()
    assert prior==bindings['baseline_sources'][name],name
    if name not in allowed:assert prior==recorded,name
assert (B/'source-delta.patch').read_bytes()==subprocess.check_output(['git','diff',rev,'--',*sorted(allowed)])
test=bindings['sources']['t/1959-isf-prepared-formal-reservations.t']
prior_test=bindings['baseline_sources']['t/1959-isf-prepared-formal-reservations.t']
for variable in ('simple','domains'):
    pattern=r'my \$'+variable+r" = prepare\(<<'ISF'\);\n(.*?)\nISF"
    assert re.search(pattern,test,re.S).group(1)==re.search(pattern,prior_test,re.S).group(1)
assert 'dclone(' not in test
assert 'my $before = input_snapshot($prepared);' in test
assert 'is(input_snapshot($prepared), $before,' in test
assert "ref($value) eq 'PreparedCauseSentinel'" in test and "reftype($value) eq 'HASH' && !keys %$value" in test
assert 'return $copies->{$address} if exists $copies->{$address};' in test
for label in ('domain mutation fixture preserves complete source kinds','cycle refusal preserves the complete input graph',
              'FIFO collection preserves complete source kinds and references','static-zero collection preserves complete source kinds and references',
              'single-domain collection preserves complete source kinds and references'):
    assert label in test,label
ordinary=load(B/'observations-ordinary.json')
mutated=load(B/'observations-mutate.json')
prior_copy=load(B/'observations-prior-copy.json')
old=load(OLD/'observations-ordinary.json')
fields=sorted(f'/1/{prefix}generated_child_products/1/worker/1/{tail}'
        for prefix in ('','domain_source_products/1/core/1/preparation/1/')
        for tail in ('assignment_provenance/1/0/1/rhs','assignment_provenance/1/1/1/rhs',
                     'states/1/2/1/assignments/1/0/1/rhs','states/1/2/1/assignments/1/1/1/rhs'))
expected_clone=[(path,'int','str',1,'1') for path in fields]
def copies_preserve(rows):
    assert len(rows)==58
    for i,row in enumerate(rows):
        assert equal(row['before'],row['after']),('copy caller',i)
        assert equal(row['before'],row['clone']),('complete copy kind/topology',i)
copies_preserve(ordinary['clones'])
for i,row in enumerate(prior_copy['clones']):
    assert equal(row['before'],row['after']),('prior caller',i)
    delta=sorted(differences(row['before'],row['clone']))
    assert delta==(expected_clone if i>=49 else []),('prior clone',i,delta)
assert len(prior_copy['clones'])==58
for j in range(9):
    assert equal(ordinary['clones'][49+j]['before'],old['clones'][98+2*j]['before']),('fresh domain source',j)
corrections=[]
for i,(current,previous,counter) in enumerate(zip(ordinary['calls'],old['calls'],prior_copy['calls'])):
    assert equal(current['before'],current['after']),('ordinary caller',i)
    delta=sorted(differences(previous['before'],current['before']))
    for difference in delta:
        path,kind_before,kind_after,value_before,value_after=difference
        assert path in fields and (kind_before,kind_after,value_before,value_after)==('str','int','1',1),('undeclared input correction',i,difference)
    assert bool(delta)==(52<=i<=60),('correction cohort',i)
    corrections.append(len(delta))
    assert current['accepted']==previous['accepted']==counter['accepted'],('acceptance',i)
    assert current['error'].split('\n')[0]==previous['error'].split('\n')[0]==counter['error'].split('\n')[0],('cause',i)
    assert equal(current['result'],previous['result']) and equal(current['result'],counter['result']),('whole results',i)
assert len(ordinary['calls'])==len(mutated['calls'])==len(prior_copy['calls'])==len(old['calls'])==64
assert sum(row['accepted'] for row in ordinary['calls'])==6
mutations=[]
mutation_path='/1/generated_child_products/1/worker/1/assignment_provenance/1/0/1/rhs'
for i,(current,control) in enumerate(zip(ordinary['calls'],mutated['calls'])):
    assert current['accepted']==control['accepted']
    assert current['error'].split('\n')[0]==control['error'].split('\n')[0]
    assert equal(current['result'],control['result']),('mutated whole result',i)
    delta=differences(control['before'],control['after'])
    if control['mutation']:
        assert len(delta)==1 and delta[0][0]==mutation_path
        assert delta[0][1:] in (('int','str',1,'1'),('str','int','1',1)),delta
        mutations.append(i)
    else:assert not delta,('unintended mutation',i)
assert mutations==list(range(51,61)),mutations
for mode,expected,inner in (('ordinary',0,None),('mutate',1,10),('prior-copy',1,9)):
    assert (B/(mode+'.status')).read_text().strip()==str(expected)
    receipt=(B/(mode+'.txt')).read_text()
    assert 'Files=1, Tests=4,' in receipt
    if expected:assert f'failed {inner} tests of 42' in receipt and 'Failed test:  3' in receipt
    else:assert 'All tests successful.' in receipt
cause=load(B/'current-causes.json');before_cause=load(CAUSE/'current-causes.json')
assert len(cause['rows'])==len(before_cause['rows'])==174
for i,(current,previous) in enumerate(zip(cause['rows'],before_cause['rows'])):
    for field in ('label','direct','band','expected_cause','before','after'):
        assert equal(current[field],previous[field]),('cause control',i,field)
    assert current['error'].split('\n')[0]==previous['error'].split('\n')[0]
    assert current['assertions']==previous['assertions']+[1],('snapshot decision',i)
labels={'missing domain','wrong domain owner','missing nested actor','missing child module','missing nested producer',
        'erased domain in both product maps','wrong partition realization','erased child IR','erased partition'}
originals={row['label']:row for row in before_cause['rows'] if row['band']=='current_fixture'}
assert len(cause['kind_controls'])==9
assert {row['label'].removesuffix(' has a focused diagnostic') for row in cause['kind_controls']}==labels
for control in cause['kind_controls']:
    previous=originals[control['label']]
    assert equal(control['before'],previous['before'])
    assert differences(control['before'],control['after'])==[('/generated_child_products/worker/assignment_provenance/0/rhs','str','int','1',1)]
    assert control['assertions']==[1,1,0]
    assert control['error'].split('\n')[0]==previous['expected_cause']
assert (B/'current.status').read_text().strip()=='0'
assert 'Files=2, Tests=554,' in (B/'current.txt').read_text()
assert (B/'bypass.pl').read_bytes()==(CAUSE/'bypass.pl').read_bytes()
assert (B/'bypass-red.status').read_text().strip()=='1'
assert 'Failed 2/4 subtests' in (B/'bypass-red.txt').read_text()
if args.trust_prior_copy:copies_preserve(prior_copy['clones'])
if args.trust_mutation:
    for i,row in enumerate(mutated['calls']):assert equal(row['before'],row['after']),('false input preservation',i)
corrupt=copy.deepcopy(ordinary['clones'])
corrupt[49]['clone'][1]['generated_child_products'][1]['worker'][1]['assignment_provenance'][1][0][1]['rhs']='1'
try:copies_preserve(corrupt)
except AssertionError:pass
else:raise AssertionError('kind corruption accepted')
cycle=next(row for row in ordinary['calls'] if row['error'].startswith('Formal reservation inventory has a cycle'))
corrupt=copy.deepcopy(cycle['after']);corrupt[1]['actor_context'][1]['cycle']=['reference','/actor']
assert not equal(cycle['before'],corrupt)
print('PASS exact test-only/source closure; complete current source copies and ordinary caller kinds/topology; explicitly bounded source-kind corrections:',corrections)
print('PASS whole acceptance/results/primary-cause conservation, permanent complete-cause/kind controls and genuine mutation/prior-copy RED; kind/topology corruptions reject. Wider native/constructor/moved-root semantics remain cold.')
