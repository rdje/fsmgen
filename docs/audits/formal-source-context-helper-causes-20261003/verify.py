"""Independent complete input/cause/source closure for the finite helper diagnosis."""
import copy,hashlib,json,re,subprocess,sys
from pathlib import Path
B=Path(__file__).parent
REV='09c9dcbaea274020207dc0f4d8d6c43623dcae62'
enc=lambda x:json.dumps(x,sort_keys=True,separators=(',',':'))
def same(a,b):assert enc(a)==enc(b),'whole typed mismatch'
def load(p):return json.loads(p.read_text())
def blob(p):return subprocess.check_output(['git','show',REV+':'+str(p)])
bind=load(B/'bindings.json');assert set(bind)=={'baseline','metadata','sources'} and bind['baseline']==REV
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',REV,'--','bin','perl','t','scripts']).decode().splitlines();assert set(paths)==set(bind['metadata'])
for p,row in bind['metadata'].items():
 raw=Path(p).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
actual=subprocess.check_output(['git','hash-object','--stdin-paths'],input=('\n'.join(paths)+'\n').encode()).decode().splitlines()
gitrows=subprocess.check_output(['git','ls-tree','-r',REV,'--','bin','perl','t','scripts']).decode().splitlines();expected={r.split('\t',1)[1]:r.split()[2] for r in gitrows}
assert len(actual)==len(paths)
for p,h in zip(paths,actual):assert h==expected[p]
for p,source in bind['sources'].items():assert source.encode()==blob(p)==Path(p).read_bytes()
test=blob('t/1936-isf-formal-source-context.t').decode()
def fixture(variable):
 marker="my $"+variable+" = <<'ISF';\n";start=test.index(marker)+len(marker);return test[start:test.index('\nISF',start)+1]
direct=fixture('source');zero=fixture('base')
def replace(source,before,after):assert before in source;return source.replace(before,after,1)
specs=[
('live binding',zero,'(repeat ZERO','(repeat 1',"unknown transaction port 'missing'","unknown transaction port 'missing'"),
('malformed dead binding',zero,'(input missing unknown)','(input missing)','bind.*(?:entries|input|requires)','bind input'),
('unknown dead target',zero,'(do worker','(do absent','not a declared transaction','not a declared transaction'),
('local option',direct,'(local scratch (width 4) (init 1))','(local scratch (width 4) (typo 1))','unsupported local option','unsupported local option'),
('wait operator',direct,'(wait count)','(wait (bogus count))','supported expression operator shape','supported expression operator shape'),
('nested local',direct,'(repeat count (set value count))','(repeat count (local nested (width 4)))','unsupported.*local','unsupported local')]
causes={
'live binding':"Transaction 'main': when-body nested repeat generated do bindings require static '(params ...)' overrides in the current nested generated blocking-do subset",
'malformed dead binding':"Transaction 'main': do target 'worker' bind entries must be '(input port expr [(timing snapshot|live)])' or '(output port signal)'",
'unknown dead target':"Transaction 'main': do target 'absent' is not a declared transaction",
'local option':"Transaction 'main': unsupported local option 'typo'",
'wait operator':"Transaction 'main': runtime dynamic wait count expression '(bogus count)' must use a supported expression operator shape in transaction body",
'nested local':"Transaction 'main': unsupported '(local ...)' clause in repeat body"}
root="Error: no (actor ...) root found in 'source_context.isf'"
data=load(B/'causes.json')
def verify_rows(candidate):
 assert set(candidate)=={'rows'} and len(candidate['rows'])==24
 desired=[]
 for identity,source,before,after,pattern,echo in specs:
  assert source.count(before)==(2 if identity=='malformed dead binding' else 1)
  for band in ('current_fixture','wrong_parser','wrong_parser_isolated','source_echo_isolated'):
   desired.append((identity,band,replace(source,before,after) if band=='current_fixture' else '; '+echo+'\n(not_actor)' if band=='source_echo_isolated' else '(not_actor)',pattern))
 for row,(identity,band,input_source,pattern) in zip(candidate['rows'],desired):
  assert set(row)=={'id','band','input','pattern','error','matched','primary_matched'}
  same([row['id'],row['band'],row['input'],row['pattern']],[identity,band,input_source,pattern])
  assert row['error'].splitlines()[0]==(causes[identity] if band=='current_fixture' else root)
  same(row['primary_matched'],int(band=='current_fixture' and identity!='live binding'))
  same(row['matched'],int(band!='wrong_parser_isolated'))
verify_rows(data)
same(json.loads(subprocess.check_output(['perl',str(B/'replay.pl')])),[{k:r[k] for k in ('id','band','matched','primary_matched')} for r in data['rows']])
if '--trust-current' in sys.argv:assert all(r['matched']==r['primary_matched'] for r in data['rows']),'actual helper promotes thirteen unrelated primary causes'
def verify_products(products):
 assert set(products)=={'direct','zero'}
 for name,source in [('direct',direct),('zero',zero)]:
  p=products[name];assert set(p)=={'source','actor','prepared'} and p['source']==source
  assert set(p['prepared'])=={'actor','actor_context','deferred_formal_collisions','domain_partition','domain_source_products','generated_child_products','generated_children','parent_activation_products','parent_completion_products','parent_named_completion_products','parent_payload_snapshot_products','parent_point_products','parent_storage_read_products','parent_storage_write_products','parent_wiring_products','pruned_transactions','resource_signal_products','reusable_child_products','transaction_binding_report_products','transaction_products','transactions'}
  same(p['actor'],p['prepared']['actor'])
  tx=p['actor']['transactions'][0];assert tx['name']=='main'
  if name=='direct':
   same(tx['clauses'],[['params',['count','2']],['on','start'],['local','scratch',['width','4'],['init','1']],['sample','payload','as','count'],['sample','payload','as','inferred'],['wait','count'],['wait',['+','count',"4'd1"]],['repeat','count',['set','value','count']],['set','scratch','count'],['set','observed','value'],['complete','done']])
   ctx=p['prepared']['transactions']['main'];same(ctx['locals'],{'scratch':1});same(ctx['static_symbols'],{'LIMIT':1,'ACTOR_COUNT':1});same(ctx['static_count_symbols'],{'LIMIT':1,'ACTOR_COUNT':1,'count':1})
  else:
   same(p['prepared']['pruned_transactions'],{'worker':1})
   assert 'worker' not in p['prepared']['transactions']
   same(p['prepared']['transactions']['main']['pruned_repeats'],{'clauses/1/2':1,'clauses/2/2/1':1})
products=load(B/'products.json');verify_products(products)
for label in ('whole_kind','whole_guard','whole_field'):
 bad=copy.deepcopy(products)
 if label=='whole_kind':bad['direct']['prepared']['transactions']['main']['locals']['scratch']=True
 elif label=='whole_guard':
  bad['direct']['actor']['transactions'][0]['clauses'][5][1]='forged'
  bad['direct']['prepared']['actor']['transactions'][0]['clauses'][5][1]='forged'
 else:bad['direct']['prepared']['unknown']=1
 try:verify_products(bad)
 except AssertionError:print('whole corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
# Fully retained returned products are source/Git-bound observations. Literal
# clauses/scopes/pruning and whole clone/kind equality are cold-qualified;
# other internal lowering-product semantics are not independently signed off.
corrected=load(B/'corrected-live.json');assert set(corrected)=={'source','actor','accepted','error','unchanged'}
correct_source=replace(replace(replace(zero,'(repeat ZERO','(repeat 1'),'(do worker (bind','(do worker (params (COUNT 1)) (bind'),'(transaction worker (ports (input data (width 4)))','(transaction worker (ports (input data (width 4))) (params (COUNT 1))')
assert corrected['source']==correct_source==(B/'corrected-source.isf').read_text()
same(corrected['accepted'],0);same(corrected['unchanged'],1)
assert corrected['error'].splitlines()[0]=="Transaction 'main': repeat-body do target 'worker' binds unknown transaction port 'missing' on 'worker'"
# The exact desired primary cause is supplied by the binding contract, while
# the current fixture's earlier cause is supplied by the repeat subset contract.
for label in ('cause','input','matched_kind','primary_kind','extra_field','membership'):
 bad=copy.deepcopy(data)
 if label=='cause':bad['rows'][0]['error']='wrong cause\n'
 elif label=='input':bad['rows'][0]['input']='(not_actor)'
 elif label=='matched_kind':bad['rows'][0]['matched']=True
 elif label=='primary_kind':bad['rows'][0]['primary_matched']=0.0
 elif label=='extra_field':bad['rows'][0]['unknown']=1
 else:bad['rows'].pop()
 try:verify_rows(bad)
 except AssertionError:print('shared corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
assert (B/'probe.status').read_text()=='13\n' and 'failed 13 tests of 76' in (B/'probe.txt').read_text()
assert (B/'current.status').read_text()=='0\n' and 'Files=1, Tests=6' in (B/'current.txt').read_text()
if (B/'manifest.json').exists():
 m=load(B/'manifest.json')['members'];assert set(m)=={str(p.relative_to(B)) for p in B.rglob('*') if p.is_file() and p.name!='manifest.json'}
 for name,row in m.items():
  raw=(B/name).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
print('PASS six current inputs/four bands: five genuine primary matches, thirteen wrong primary matches, six isolated rejects; exact current consumer, corrected live fixture and finite source/product/kind closure. Wider semantics remain open.')
