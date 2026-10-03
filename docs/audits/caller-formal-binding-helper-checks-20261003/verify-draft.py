"""Finite independent source, actor, complete-cause and binding-report models."""
import copy,hashlib,json,re,subprocess,sys
from pathlib import Path
B=Path(__file__).parent
REV='64628a4089349f7a23e333eef70584c30dc08dad'
def enc(x):return json.dumps(x,sort_keys=True,separators=(',',':'))
def same(a,b):assert enc(a)==enc(b),'whole typed mismatch'
def load(p):return json.loads(p.read_text())
bind=load(B/'bindings.json');assert set(bind)=={'baseline','metadata','sources'} and bind['baseline']==REV
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',REV,'--','bin','perl','t','scripts']).decode().splitlines();assert set(paths)==set(bind['metadata'])
for p,row in bind['metadata'].items():
 raw=Path(p).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
actual=subprocess.check_output(['git','hash-object','--stdin-paths'],input=('\n'.join(paths)+'\n').encode()).decode().splitlines()
gitrows=subprocess.check_output(['git','ls-tree','-r',REV,'--','bin','perl','t','scripts']).decode().splitlines();expected={r.split('\t',1)[1]:r.split()[2] for r in gitrows}
assert len(actual)==len(paths)
for p,h in zip(paths,actual):assert h==expected[p]
for p,source in bind['sources'].items():assert source.encode()==subprocess.check_output(['git','show',REV+':'+p])==Path(p).read_bytes()
# The small independent reader handles only the declared literal fixture grammar.
def sexpr(text):
 stack=[[]]
 for t in re.findall(r'\(|\)|[^\s()]+',text):
  if t=='(':stack.append([])
  elif t==')':
   assert len(stack)>1;v=stack.pop();stack[-1].append(v)
  else:stack[-1].append(t)
 assert len(stack)==1;return stack[0]
def source(a):
 k=a['actor_kind'];decl='(storage (var value (width 8) (reset 19)))' if k=='storage' else ''
 port=f'({k} value (width 8))' if k in ('input','output') else ''
 formal=a.get('formal','(ports (input value (width 4)))');callee=a.get('callee','(ports (input payload (width 4)))');body=a.get('body','(do worker (bind (input payload value)))')
 return '(actor binding_scope (clock clk) (reset (rst_n async active_low))\n'+f'(interface (input start) (input observed (width 4)) (output done) {port})\n'+f'{decl} (transaction caller {formal} (on start) {body} (complete done))\n'+f'(transaction worker {callee} (on worker_start) (complete worker_done)))\n'
def ports(text):
 if not text:return None
 out={'inputs':[],'outputs':[]}
 for role,name,width in sexpr(text)[0][1:]:out[role+'s'].append({'name':name,'width':int(width[1])})
 return out
def actor(a):
 v={k:[] for k in ('constants','crossings','enum_declarations','imports','library_uses','package_imports','package_roots','params','phases','priorities','reset_provenance','resources','rules','stages','storage','transactions','type_declarations','uses','verification_observations')}
 v.update({k:{} for k in ('drives','handshakes','procs')})
 v.update({k:None for k in ('actor_network','clock_domains','verification_bridge')})
 v.update(actor_name='binding_scope',clock='clk',watchdog='65535',constant_symbols={'packages':{}},enum_symbols={'local':{},'packages':{}},type_symbols={'local':{},'packages':{}},reset={'kind':'async','name':'rst_n','polarity':'active_low'},reset_provenance=[{'domain':None,'origin':'explicit'}])
 ins=[{'name':'start','width':1},{'name':'observed','width':'4'}];outs=[{'name':'done','width':1}]
 k=a['actor_kind']
 if k in ('input','output'):(ins if k=='input' else outs).append({'name':'value','width':'8'})
 v['interface']={'inputs':ins,'outputs':outs};v['interface_port_metadata']=[{'direction':r,'name':p['name'],'width':int(p['width'])} for r,ps in [('input',ins),('output',outs)] for p in ps]
 if k=='storage':v['storage']=[{'kind':'var','name':'value','reset_value':19,'signals':[{'name':'value','reset_value':19,'width':8}],'width':8}]
 for name,text,clauses in [('caller',a.get('formal','(ports (input value (width 4)))'),[['on','start']]+sexpr(a.get('body','(do worker (bind (input payload value)))'))+[['complete','done']]),('worker',a.get('callee','(ports (input payload (width 4)))'),[['on','worker_start'],['complete','worker_done']])]:
  tx={'name':name,'clauses':clauses};p=ports(text)
  if p is not None:tx['ports']=p
  v['transactions'].append(tx)
 return v
def assign(v,path,value):
 for p in path[:-1]:v=v[p]
 v[path[-1]]=copy.deepcopy(value)
specs=[]
for ak in ('input','output','storage'):
 for fk in ('input','output'):
  for actual in ('value','(+ value observed)'):
   specs.append({'id':f'shadow/input/{ak}/{fk}/{actual}','args':{'actor_kind':ak,'formal':f'(ports ({fk} value (width 4)))','body':f'(do worker (bind (input payload {actual})))'},'mutation':{'path':['transactions',1,'ports','inputs',0,'width'],'value':8},'pattern':"width (?:8 does not match actor signal 'value' width 4|4 does not match transaction port width 8)"})
  specs.append({'id':f'shadow/output/{ak}/{fk}','args':{'actor_kind':ak,'formal':f'(ports ({fk} value (width 4)))','callee':'(ports (output result (width 4)))','body':'(do worker (bind (output result value)))'},'mutation':{'path':['transactions',1,'ports','outputs',0,'width'],'value':8},'pattern':"width 8 does not match actor signal 'value' width 4"})
specs += [
 {'id':'actor input write','args':{'actor_kind':'input','formal':'','callee':'(ports (output result (width 8)))','body':'(do worker (bind (output result value)))'},'pattern':"targets actor input 'value'.*read-only"},
 {'id':'actor output read','args':{'actor_kind':'output','formal':'','callee':'(ports (input payload (width 8)))'},'pattern':"reads actor output 'value'.*readback"},
 {'id':'callee formal is not caller variable','args':{'actor_kind':'none','formal':'','callee':'(ports (input value (width 4)))','body':'(do worker (bind (input value value)))'},'pattern':"unknown actor signal 'value'"},
 {'id':'rule scope','args':{'actor_kind':'output'},'rule':1,'pattern':"Rule 'dispatch'.*reads actor output 'value'"}]
for ident,body,pattern in [
 ('wrong direction','(do worker (bind (output payload value)))',"uses role 'output'.*declares 'input'"),
 ('unknown callee port','(do worker (bind (input missing value)))',"unknown transaction port 'missing'"),
 ('missing binding','(do worker)',r"requires '\(bind"),
 ('duplicate binding','(do worker (bind (input payload value) (input payload value)))','duplicate binding'),
 ('wrong timing','(do worker (bind (input payload value (timing live))))',"requested timing 'live'.*activation_region"),
 ('live repeat','(repeat 1 (do worker (bind (input missing nonexistent))))',"unknown transaction port 'missing'")]:specs.append({'id':ident,'args':{'actor_kind':'storage','body':body},'pattern':pattern})
context="Transaction 'caller': do target 'worker'"
reasons={
 'actor input write':context+" output binding for port 'result' targets actor input 'value', but actor inputs are read-only",
 'actor output read':context+" input binding for port 'payload' reads actor output 'value', but actor output readback is not public",
 'callee formal is not caller variable':context+" binding for port 'value' references unknown actor signal 'value'",
 'rule scope':"Rule 'dispatch': trigger target 'worker' input binding for port 'payload' reads actor output 'value', but actor output readback is not public",
 'wrong direction':context+" binding for port 'payload' uses role 'output' but the transaction declares 'input'",
 'unknown callee port':context+" binds unknown transaction port 'missing' on 'worker'",
 'missing binding':context+" requires '(bind ...)' because transaction 'worker' declares ports",
 'duplicate binding':"Transaction 'caller': activation has duplicate binding for transaction port 'payload'",
 'wrong timing':context+" input binding for port 'payload' requested timing 'live', but this activation currently uses 'activation_region'; behavior-changing timing conversion is not supported yet",
 'live repeat':"Transaction 'caller': repeat-body do target 'worker' binds unknown transaction port 'missing' on 'worker'"}
def primary(s):
 ident=s['id']
 if ident.startswith('shadow/input/'):
  return context+(" input binding expression for port 'payload' width 4 does not match transaction port width 8" if ident.endswith('(+ value observed)') else " binding for port 'payload' width 8 does not match actor signal 'value' width 4")
 if ident.startswith('shadow/output/'):return context+" binding for port 'result' width 8 does not match actor signal 'value' width 4"
 return reasons[ident]
def expected_actor(s,band):
 v=actor(s['args'])
 if 'mutation' in s:assign(v,s['mutation']['path'],s['mutation']['value'])
 if s.get('rule'):v['transactions'][0]['clauses']=[];v['rules']=[{'name':'dispatch','actions':[['trigger','worker',['bind',['input','payload','value']]]]}]
 control=None
 if band=='wrong_native_shape':
  path=['rules',0,'actions',0,2,1,0] if s.get('rule') else ['transactions',1,'ports','inputs',0,'_isf_formal_identity'] if s['id']=='missing binding' else ['transactions',0,'clauses',1,2,2,1,0] if s['id']=='live repeat' else ['transactions',0,'clauses',1,2,1,0]
  control={'path':path,'value':{} if s['id']=='missing binding' else 'bogus'};assign(v,path,control['value'])
 return v,control
def verify_rows(data):
 assert set(data)=={'rows'} and len(data['rows'])==56
 for s,pair in zip(specs,[data['rows'][i:i+2] for i in range(0,56,2)]):
  for r,band in zip(pair,('current_fixture','wrong_native_shape')):
   assert set(r)=={'id','band','spec','source','actor','control','error','matched','primary_matched'}
   same([r['id'],r['band'],r['spec'],r['source']],[s['id'],band,s,source(s['args'])]);a,c=expected_actor(s,band);same(r['actor'],a);same(r['control'],c)
   cause=primary(s) if band=='current_fixture' else "Transaction 'worker': malformed or stale formal identity projection" if s['id']=='missing binding' else "Transaction 'dispatch': activation bind role must be input or output" if s.get('rule') else "Transaction 'caller': activation bind role must be input or output"
   assert r['error'].splitlines()[0]==cause
   same(r['primary_matched'],int(band=='current_fixture'))
   false=not(s['id'].startswith('shadow/input/') or s['id']=='missing binding')
   same(r['matched'],int(band=='current_fixture' or false))
data=load(B/'causes.json');verify_rows(data)
same(json.loads(subprocess.check_output(['perl',str(B/'replay.pl')])),[{k:r[k] for k in ('id','band','matched','primary_matched')} for r in data['rows']])
if '--trust-current' in sys.argv:assert all(r['matched']==r['primary_matched'] for r in data['rows']),'actual helper promotes fifteen unrelated primary causes'
prepkeys=set('actor actor_context deferred_formal_collisions domain_partition domain_source_products generated_child_products generated_children parent_activation_products parent_completion_products parent_named_completion_products parent_payload_snapshot_products parent_point_products parent_storage_read_products parent_storage_write_products parent_wiring_products pruned_transactions resource_signal_products reusable_child_products transaction_binding_report_products transaction_products transactions'.split())
def verify_products(data):
 assert set(data)=={'rows'} and len(data['rows'])==18
 for s,r in zip(specs[:18],data['rows']):
  assert set(r)=={'id','source','actor','prepared'};same([r['id'],r['source']],[s['id'],source(s['args'])]);same(r['actor'],actor(s['args']));p=r['prepared'];assert set(p)==prepkeys;same(p['actor'],actor(s['args']))
  out=s['id'].startswith('shadow/output/');expr=s['id'].endswith('(+ value observed)')
  report={'actor_endpoint_kind':'expression' if expr else 'signal','actor_expression':'(+ value observed)' if expr else 'value','actor_signal':None if expr else 'value','authored_timing_mode':None,'binding_timing':'done_guarded' if out else 'activation_region','child_port':None,'done_signal':'worker_done','instance':None,'owner':'caller','owner_kind':'transaction','parent_port':None,'payload_source':None,'port':'result' if out else 'payload','role':'output' if out else 'input','site_kind':'do','start_signal':'worker_start','target_transaction':'worker','trigger_source':None,'width':4}
  same(p['transaction_binding_report_products'],[report]);assert set(p['transaction_products'])==set(p['transactions'])=={'caller','worker'}
  # Other complete returned internals remain retained observations, with no universal semantic signoff.
products=load(B/'products.json');verify_products(products)
for label in ('cause','input','matched_kind','primary_kind','extra_field','membership'):
 bad=copy.deepcopy(data)
 if label=='cause':bad['rows'][0]['error']='wrong cause\n'
 elif label=='input':bad['rows'][0]['source']='(not_actor)'
 elif label=='matched_kind':bad['rows'][0]['matched']=True
 elif label=='primary_kind':bad['rows'][0]['primary_matched']=1.0
 elif label=='extra_field':bad['rows'][0]['unknown']=1
 else:bad['rows'].pop()
 try:verify_rows(bad)
 except AssertionError:print('shared corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
for label in ('whole_kind','whole_binding','whole_field'):
 bad=copy.deepcopy(products)
 if label=='whole_kind':bad['rows'][0]['actor']['transactions'][0]['ports']['inputs'][0]['width']=4.0
 elif label=='whole_binding':bad['rows'][0]['prepared']['transaction_binding_report_products'][0]['actor_expression']='forged'
 else:bad['rows'][0]['prepared']['unknown']=1
 try:verify_products(bad)
 except AssertionError:print('whole corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
assert (B/'probe.status').read_text()=='28\n' and 'failed 28 tests of 224' in (B/'probe.txt').read_text()
assert (B/'current.status').read_text()=='0\n' and 'Files=1, Tests=12' in (B/'current.txt').read_text()
assert (B/'ordinary.status').read_text()=='0\n'
if (B/'manifest.json').exists():
 m=load(B/'manifest.json')['members'];assert set(m)=={str(p.relative_to(B)) for p in B.rglob('*') if p.is_file() and p.name!='manifest.json'}
 for name,row in m.items():
  raw=(B/name).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
print('PASS 28 current primary categories, 15 wrong cause matches and 13 wrong cause rejects; complete finite actors/source/binding reports/kinds. Wider prepared semantics remain open.')
