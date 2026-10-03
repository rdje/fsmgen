"""Finite current/prior/bypass qualification; wider internal semantics stay open."""
import copy,hashlib,json,subprocess,sys
from pathlib import Path
B=Path(__file__).parent
OLD=Path('docs/audits/caller-formal-binding-helper-causes-20261003')
REV='6254f4c8db7373c1df0a02cc380b85115cd64cbb'
def load(p):return json.loads(p.read_text())
exec(compile((B/'models.py').read_text(),str(B/'models.py'),'exec'))
bind=load(B/'bindings.json');assert set(bind)=={'baseline','metadata','sources'} and bind['baseline']==REV
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',REV,'--','bin','perl','t','scripts']).decode().splitlines()
new='t/2057-isf-caller-formal-binding-diagnostic-causes.t';changed='t/1933-isf-caller-formal-binding-scope.t'
assert set(bind['metadata'])==set(paths)|{new}
for p,row in bind['metadata'].items():
 raw=Path(p).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
for p,source in bind['sources'].items():assert source.encode()==Path(p).read_bytes()
unchanged=[p for p in paths if p!=changed]
actual=subprocess.check_output(['git','hash-object','--stdin-paths'],input=('\n'.join(unchanged)+'\n').encode()).decode().splitlines()
gitrows=subprocess.check_output(['git','ls-tree','-r',REV,'--','bin','perl','t','scripts']).decode().splitlines();expected={r.split('\t',1)[1]:r.split()[2] for r in gitrows}
assert len(actual)==len(unchanged)
for p,h in zip(unchanged,actual):assert h==expected[p]
# Independent literal complete source delta, including each context-specific caller.
test=subprocess.check_output(['git','show',REV+':'+changed]).decode()
test=test.replace('use FSM::Test::SourceQueryRunner;','use FSM::Test::SourceQueryRunner;\nuse FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);')
test=test.replace('my ($actor, $pattern, $label) = @_;','my ($actor, $expected_cause, $label) = @_;').replace('like($error, $pattern, "$label diagnostic");','ok(diagnostic_cause_matches($error, $expected_cause), "$label diagnostic")\n        or diag($error);')
before="rejects($actor, qr/width (?:8 does not match actor signal 'value' width 4|4 does not match transaction port width 8)/,"
after='''my $expected_cause = "Transaction 'caller': do target 'worker' "
                    . ($actual eq 'value'
                        ? "binding for port 'payload' width 8 does not match actor signal 'value' width 4"
                        : "input binding expression for port 'payload' width 4 does not match transaction port width 8");
                rejects($actor, $expected_cause,'''
assert before in test;test=test.replace(before,after)
s=specs[2];before="rejects($actor, qr/"+s['pattern']+"/,";assert before in test;test=test.replace(before,'rejects($actor, '+json.dumps(primary(s))+',')
for s in specs[18:]:
 if s['id']=='live repeat':continue
 before='qr/'+s['pattern']+'/';assert before in test;test=test.replace(before,json.dumps(primary(s)))
start=test.index("body => '(repeat 1 (do worker (bind (input missing nonexistent))))'")
test=test[:start]+test[start:].replace(json.dumps(reasons['unknown callee port']),json.dumps(reasons['live repeat']),1)
assert test==bind['sources'][changed]==Path(changed).read_text(),'whole T1933 delta mismatch'
assert bind['sources'][new]==Path(new).read_text()
# Exact original reader model supplies independent prior input/cause/flag closure.
prior=load(B/'prior-causes.json');verify_rows(prior)
# Preserve exact prior inputs/actors/observed outcome flags, excluding trace addresses/coordinates.
old=load(OLD/'causes.json')
for a,b in zip(prior['rows'],old['rows']):same({k:v for k,v in a.items() if k!='error'},{k:v for k,v in b.items() if k!='error'})
def verify_current(data):
 assert set(data)=={'rows'} and len(data['rows'])==84
 for s,triplet in zip(specs,[data['rows'][i:i+3] for i in range(0,84,3)]):
  for r,band in zip(triplet,('positive','wrong_native_shape','label_echo')):
   assert set(r)=={'id','band','source','actor','expected_cause','label','error','assertions'}
   label=s['id']+' / '+band+(' / '+primary(s) if band=='label_echo' else '')
   same([r['id'],r['band'],r['source'],r['expected_cause'],r['label']],[s['id'],band,source(s['args']),primary(s),label])
   a,c=expected_actor(s,'current_fixture' if band=='positive' else 'wrong_native_shape');same(r['actor'],a)
   cause=primary(s) if band=='positive' else "Transaction 'worker': malformed or stale formal identity projection" if s['id']=='missing binding' else "Transaction 'dispatch': activation bind role must be input or output" if s.get('rule') else "Transaction 'caller': activation bind role must be input or output"
   assert r['error'].splitlines()[0]==cause;same(r['assertions'],[1,int(band=='positive')])
current=load(B/'current-causes.json');verify_current(current)
replay=json.loads(subprocess.check_output(['perl',str(B/'replay.pl')]))
same(replay,[r['assertions'][1] for r in current['rows']])
if '--prior-consumer' in sys.argv:assert all(r['matched']==r['primary_matched'] for r in prior['rows']),'real prior consumer accepts fifteen wrong causes'
bypass=load(B/'bypass-input.json');assert set(bypass)=={'source','actor','error','accepted','unchanged'}
same(bypass['source'],current['rows'][0]['source']);same(bypass['actor'],expected_actor(specs[0],'current_fixture')[0]);same([bypass['error'],bypass['accepted'],bypass['unchanged']],['',1,1])
if '--binding-bypass' in sys.argv:assert bypass['accepted']==0,'real binding-validation bypass accepts an invalid width'
products=load(B/'products.json');same(products,load(OLD/'products.json'))
# This whole conservation includes JSON kinds. The predecessor's literal actor/
# complete binding-report/schema/member semantics carry forward; other internals
# remain retained observations under .1.3, never universal signoff.
for label in ('cause','input','expectation','matched_kind','extra_field','membership'):
 bad=copy.deepcopy(current)
 if label=='cause':bad['rows'][0]['error']='wrong cause\n'
 elif label=='input':bad['rows'][0]['source']='(not_actor)'
 elif label=='expectation':bad['rows'][0]['expected_cause']='wrong expectation'
 elif label=='matched_kind':bad['rows'][0]['assertions'][1]=True
 elif label=='extra_field':bad['rows'][0]['unknown']=1
 else:bad['rows'].pop()
 try:verify_current(bad)
 except AssertionError:print('shared corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
for label in ('whole_kind','whole_binding','whole_field'):
 bad=copy.deepcopy(products)
 if label=='whole_kind':bad['rows'][0]['prepared']['transaction_binding_report_products'][0]['width']=4.0
 elif label=='whole_binding':bad['rows'][0]['prepared']['transaction_binding_report_products'][0]['actor_expression']='forged'
 else:bad['rows'][0]['prepared']['unknown']=1
 try:same(bad,load(OLD/'products.json'))
 except AssertionError:print('whole corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
assert (B/'current.status').read_text()=='0\n' and 'Files=2, Tests=264' in (B/'current.txt').read_text()
assert (B/'prior-consumer-red.status').read_text()=='28\n' and 'failed 28 tests of 224' in (B/'prior-consumer-red.txt').read_text()
assert int((B/'binding-bypass-red.status').read_text())>0 and 'Failed' in (B/'binding-bypass-red.txt').read_text()
assert (B/'ordinary.status').read_text()=='0\n'
if (B/'manifest.json').exists():
 m=load(B/'manifest.json')['members'];assert set(m)=={str(p.relative_to(B)) for p in B.rglob('*') if p.is_file() and p.name!='manifest.json'}
 for name,row in m.items():
  raw=(B/name).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
print('PASS current complete causes/84 rows, exact prior false matches, real bypass, full ordinary conservation and finite source/kind closure; wider internal semantics remain open.')
