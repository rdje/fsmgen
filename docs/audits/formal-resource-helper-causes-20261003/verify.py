"""Independent finite literal actors/causes/pointers; wider module semantics open."""
import copy,hashlib,json,re,subprocess,sys
from pathlib import Path
B=Path(__file__).parent
REV='00abbe80401c7d36f481dd2a65d01bf7ac41dca6'
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
for p,body in bind['sources'].items():assert body.encode()==subprocess.check_output(['git','show',REV+':'+p])==Path(p).read_bytes()
HELPER='isf_rr_shared_bus_turn'
def source(kind,count,formal='payload'):
 resource='work' if kind=='transaction_start' else 'shared_bus';members='(members valid)' if kind=='output_bundle' else '(members value_reg)' if kind=='storage_port' else ''
 inputs=' '.join(f'(input req{i})' for i in range(count));users=' '.join(f'user{i}' for i in range(count))
 rules=' '.join(f'(rule user{i} req{i} '+('(trigger work)' if kind=='transaction_start' else f'({"value_reg" if kind=="storage_port" else "valid"} {i%2})')+')' for i in range(count))
 return f'''(actor resource_products (clock clk) (reset rst_n)
 (interface (input fire) {inputs} (output valid) (output observed (width 4)) (output work_done))
 (storage (var value_reg (width 1)))
 (transaction main (ports (input {formal} (width 4))) (on fire) (set observed {formal}))
 (transaction work (on work_start) (wait 1) (complete work_done))
 (resources (resource {resource} (kind {kind}) (arbiter round_robin) {members} (users {users})))
 {rules})
'''
def actor(kind,count,formal='payload'):
 v={k:[] for k in ('constants','crossings','enum_declarations','imports','library_uses','package_imports','package_roots','params','phases','priorities','resources','rules','stages','storage','transactions','type_declarations','uses','verification_observations')};v.update({k:{} for k in ('drives','handshakes','procs')});v.update({k:None for k in ('actor_network','clock_domains','verification_bridge')})
 v.update(actor_name='resource_products',clock='clk',watchdog='65535',constant_symbols={'packages':{}},enum_symbols={'local':{},'packages':{}},type_symbols={'local':{},'packages':{}},reset={'kind':'sync','name':'rst_n','polarity':'active_low'},reset_provenance=[{'domain':None,'origin':'explicit'}])
 ins=[{'name':'fire','width':1}]+[{'name':f'req{i}','width':1} for i in range(count)];outs=[{'name':'valid','width':1},{'name':'observed','width':'4'},{'name':'work_done','width':1}]
 v['interface']={'inputs':ins,'outputs':outs};v['interface_port_metadata']=[{'direction':r,'name':p['name'],'width':int(p['width'])} for r,ps in [('input',ins),('output',outs)] for p in ps]
 v['storage']=[{'kind':'var','name':'value_reg','width':1,'signals':[{'name':'value_reg','width':1}]}]
 v['transactions']=[{'name':'main','ports':{'inputs':[{'name':formal,'width':4}],'outputs':[]},'clauses':[['on','fire'],['set','observed',formal]]},{'name':'work','ports':{'inputs':[],'outputs':[]},'clauses':[['on','work_start'],['wait','1'],['complete','work_done']]}]
 resource={'arbiter':'round_robin','kind':kind,'name':'work' if kind=='transaction_start' else 'shared_bus','users':[f'user{i}' for i in range(count)]}
 if kind in ('output_bundle','storage_port'):resource['members']=['valid' if kind=='output_bundle' else 'value_reg']
 v['resources']=[resource];v['rules']=[{'name':f'user{i}','when':['when',f'req{i}'],'actions':[['trigger','work']] if kind=='transaction_start' else [['value_reg' if kind=='storage_port' else 'valid',str(i%2)]]} for i in range(count)]
 return v
cases=[('raw formal alias','isf_resource_round_robin_pointer_collision',None),('fixed','isf_resource_round_robin_pointer_collision','append_fixed_pointer'),('unknown_user','isf_resource_unknown_user','replace_first_user'),('overlap','isf_resource_round_robin_user_overlap','append_other_resource'),('malformed name','isf_resource_round_robin_name_shape','malformed_resource_name'),('unsupported kind','isf_resource_unsupported_kind','unsupported_resource_kind')]
reasons={
'raw formal alias':f"ISF resource arbitration 'isf_resource_round_robin_pointer_collision' on resource 'shared_bus': generated round_robin pointer '{HELPER}' collides with an existing actor symbol",
'fixed':f"ISF resource arbitration 'isf_resource_round_robin_pointer_collision' on resource 'shared_bus': generated round_robin pointer '{HELPER}' collides with an existing actor symbol",
'unknown_user':"ISF resource arbitration 'isf_resource_unknown_user' on resource 'shared_bus': user 'missing' is not a lowered rule",
'overlap':"ISF resource arbitration 'isf_resource_round_robin_user_overlap' on resource 'other': rule user 'user0' is already bound to round_robin resource 'shared_bus'",
'malformed name':"ISF resource arbitration 'isf_resource_round_robin_name_shape' on resource 'shared-bus': round_robin resource names must be HDL identifiers because FSMGen generates pointer storage from the resource name",
'unsupported kind':"ISF resource arbitration 'isf_resource_unsupported_kind' on resource 'shared_bus': resource kind 'backlog_kind' is not enforced yet"}
def submitted(ident,band,code):
 v=actor('rule_slot',3,HELPER if ident=='raw formal alias' else 'payload')
 if ident=='fixed':v['storage'][0]['signals'].append({'name':HELPER,'width':2})
 elif ident=='unknown_user':v['resources'][0]['users'][0]='missing'
 elif ident=='overlap':extra=copy.deepcopy(v['resources'][0]);extra['name']='other';v['resources'].append(extra)
 elif ident=='malformed name':v['resources'][0]['name']='shared-bus'
 elif ident=='unsupported kind':v['resources'][0]['kind']='backlog_kind'
 if band!='current_fixture':v['transactions'][0]['clauses'][1]=[code if band=='primary_body_echo' else 'unsupported_clause']
 return v
def cause(ident,band,code):return reasons[ident] if band=='current_fixture' else f"Transaction 'main': unsupported '({code if band=='primary_body_echo' else 'unsupported_clause'} ...)' clause in transaction body"
def verify_rows(data):
 assert set(data)=={'helper_name','rows'} and data['helper_name']==HELPER and len(data['rows'])==18
 for (ident,code,mutation),triplet in zip(cases,[data['rows'][i:i+3] for i in range(0,18,3)]):
  for r,band in zip(triplet,('current_fixture','wrong_body','primary_body_echo')):
   assert set(r)=={'id','code','band','source','mutation','actor_before','actor_after','error','matched','primary_matched'}
   same([r['id'],r['code'],r['band'],r['source'],r['mutation']],[ident,code,band,source('rule_slot',3,HELPER if ident=='raw formal alias' else 'payload'),mutation]);v=submitted(ident,band,code);same(r['actor_before'],v);same(r['actor_after'],v)
   assert r['error'].splitlines()[0]==cause(ident,band,code);same(r['matched'],1);same(r['primary_matched'],int(band!='wrong_body'))
helper=load(B/'causes.json');verify_rows(helper)
def verify_direct(data):
 assert set(data)=={'rows'} and len(data['rows'])==3
 ident='malformed name';code='isf_resource_round_robin_name_shape'
 for r,band in zip(data['rows'],('current_fixture','wrong_body','primary_body_echo')):
  assert set(r)=={'band','source','actor_before','actor_after','error','matched','primary_matched'}
  same([r['band'],r['source']],[band,source('rule_slot',3)]);same(r['actor_before'],submitted(ident,band,code));same(r['actor_after'],r['actor_before']);assert r['error'].splitlines()[0]==cause(ident,band,code)
  same(r['matched'],int(band!='wrong_body'));same(r['primary_matched'],int(band!='wrong_body'))
  assert "\teval '" not in r['error'],'active consumer-string eval contaminates evidence'
  if band=='wrong_body':assert code not in r['error']
direct=load(B/'direct-causes.json');verify_direct(direct)
same(json.loads(subprocess.check_output(['perl',str(B/'replay.pl')])),{'helper':[{k:r[k] for k in ('matched','primary_matched')} for r in helper['rows']],'direct':[{k:r[k] for k in ('matched','primary_matched')} for r in direct['rows']]})
if '--trust-helper' in sys.argv:assert all(r['matched']==int(r['band']=='current_fixture') for r in helper['rows']),'actual helper accepts twelve unrelated causes'
if '--trust-first-line-code' in sys.argv:assert all(r['primary_matched']==int(r['band']=='current_fixture') for r in helper['rows']),'actual first-line code predicate accepts six unrelated causes'
if '--trust-direct' in sys.argv:assert all(r['matched']==int(r['band']=='current_fixture') for r in direct['rows']),'actual direct consumer accepts an unsupported-statement code echo'
prepkeys=set('actor actor_context deferred_formal_collisions domain_partition domain_source_products generated_child_products generated_children parent_activation_products parent_completion_products parent_named_completion_products parent_payload_snapshot_products parent_point_products parent_storage_read_products parent_storage_write_products parent_wiring_products pruned_transactions resource_signal_products reusable_child_products transaction_binding_report_products transaction_products transactions'.split())
modulekeys=set('actor_name actor_network actor_phases actor_stages assignment_provenance atl_top_instances bank_accesses children clock compatible_fanin_groups conflict_issues constants counters declared_storage dt_blocks enum_declarations explicit_interface_ports explicit_internal_signals immediate_assertions interface_port_metadata library_uses logical_controllers output_defaults package_imports package_roots params ports priority_resolution reset reset_provenance reset_values resource_activation resource_arbitration signal_type_refs signal_widths spawn_instances states storage_roles temporal_contracts transaction_port_bindings type_declarations verification_bridge verification_observations watchdog'.split())
ordinary=[('rule_slot',3),('output_bundle',3),('transaction_start',3),('storage_port',3),('rule_slot',1),('rule_slot',2),('rule_slot',5)]
def verify_products(data):
 assert set(data)=={'rows'} and len(data['rows'])==7
 for r,(kind,count) in zip(data['rows'],ordinary):
  assert set(r)=={'kind','count','source','actor','prepared','module'};same([r['kind'],r['count'],r['source']],[kind,count,source(kind,count)]);same(r['actor'],actor(kind,count));p=r['prepared'];m=r['module'];assert set(p)==prepkeys and set(m)==modulekeys;same(p['actor'],actor(kind,count))
  name='work' if kind=='transaction_start' else 'shared_bus';pointer=f'isf_rr_{name}_turn';width=max(1,(count-1).bit_length())
  same(p['resource_signal_products'],[{'resource':name,'kind':kind,'declaration':{'name':pointer,'width':width,'storage_role':'resource_round_robin_pointer'}}]);same(m['counters'][pointer],width);same(m['storage_roles'][pointer],'resource_round_robin_pointer');same(sorted(k for k,v in m['storage_roles'].items() if v=='resource_round_robin_pointer'),[pointer])
  assignments=[a for dt in m['dt_blocks'] for a in dt.get('assignments',[]) if a.get('source_kind')=='resource_round_robin_pointer'];same(sorted(a['rhs'] for a in assignments),list(range(count)));same(sorted(set(a['lhs'] for a in assignments)),[pointer])
products=load(B/'products.json');verify_products(products)
for label in ('cause','source','matched_kind','actor','field','member'):
 bad=copy.deepcopy(helper)
 if label=='cause':bad['rows'][0]['error']='wrong cause\n'
 elif label=='source':bad['rows'][0]['source']='(not_actor)'
 elif label=='matched_kind':bad['rows'][0]['matched']=True
 elif label=='actor':bad['rows'][0]['actor_before']['transactions'][0]['ports']['inputs'][0]['width']=4.0
 elif label=='field':bad['rows'][0]['unknown']=1
 else:bad['rows'].pop()
 try:verify_rows(bad)
 except AssertionError:print('shared corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
for label in ('whole_kind','whole_pointer','whole_field'):
 bad=copy.deepcopy(products)
 if label=='whole_kind':bad['rows'][0]['prepared']['resource_signal_products'][0]['declaration']['width']=2.0
 elif label=='whole_pointer':bad['rows'][0]['module']['storage_roles']['isf_rr_shared_bus_turn']='forged'
 else:bad['rows'][0]['module']['unknown']=1
 try:verify_products(bad)
 except AssertionError:print('whole corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
assert (B/'probe.status').read_text()=='12\n' and 'failed 12 tests of 72' in (B/'probe.txt').read_text()
assert (B/'direct.status').read_text()=='2\n' and 'failed 2 tests of 9' in (B/'direct.txt').read_text()
assert (B/'current.status').read_text()=='0\n' and 'Files=1, Tests=3' in (B/'current.txt').read_text()
assert (B/'ordinary.status').read_text()=='0\n'
if (B/'manifest.json').exists():
 m=load(B/'manifest.json')['members'];assert set(m)=={str(p.relative_to(B)) for p in B.rglob('*') if p.is_file() and p.name!='manifest.json'}
 for name,row in m.items():
  raw=(B/name).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
print('PASS six genuine helper causes/twelve false matches, corrected direct one false match; seven complete ordinary actors and finite pointer/schema/kind models. Wider prepared/module semantics open.')
