"""Finite declared cause/mutation/scope and whole source/graph readback."""
import copy, hashlib, json, re, subprocess, sys
from pathlib import Path
B=Path(__file__).parent
REV='9b3e87db0befc7c1559e8dd8c6af7618a8108f7c'
TEST='t/1959-isf-prepared-formal-reservations.t'
def load(name):return json.loads((B/name).read_text())
def same(a,b):
 assert json.dumps(a,sort_keys=True,separators=(',',':'))==json.dumps(b,sort_keys=True,separators=(',',':')),'value/kind/field mismatch'
fields=set('actor actor_context deferred_formal_collisions domain_source_products generated_child_products generated_children parent_activation_products parent_completion_products parent_named_completion_products parent_point_products parent_payload_snapshot_products parent_storage_read_products parent_storage_write_products parent_wiring_products pruned_transactions reusable_child_products transaction_products transactions resource_signal_products domain_partition transaction_binding_report_products'.split())
prefix='Prepared formal reservations '
contracts=[]
for field in sorted(fields):
 contracts += [('missing '+field,prefix+'have incomplete preparation (missing: '+field+'; unexpected: )','incomplete preparation.*missing: '+field,False),
  ('malformed '+field,prefix+"have malformed preparation field '"+field+"'","malformed preparation field '"+field+"'",False)]
contracts += [
 ('unknown producer must be classified',prefix+'have incomplete preparation (missing: ; unexpected: new_producer_products)','incomplete preparation.*unexpected: new_producer_products',False),
 ('missing live transaction producer',prefix+'have incomplete transaction products (missing: main; unexpected: )','incomplete transaction products.*main',False),
 ('unknown context',prefix+'have incomplete transaction contexts (missing: ; unexpected: ghost)','incomplete transaction contexts.*ghost',False),
 ('unknown generated child',prefix+'have unknown generated_children membership','unknown generated_children membership',False),
 ('unknown partition',prefix+'have an unknown domain partition kind','unknown domain partition kind',False),
 ('unclassified reusable product',prefix+'have incomplete reusable children (missing: ; unexpected: unclassified)','incomplete reusable children',False),
 ('cycle diagnostic retained',"Formal reservation inventory has a cycle at '/actor_context/cycle'",'has a cycle',True),
 ('missing domain',prefix+'have incomplete domain products (missing: aux; unexpected: )','incomplete domain products',False),
 ('wrong domain owner',prefix+'have mismatched domain identity','mismatched domain identity',False),
 ('missing nested actor',prefix+'have incomplete preparation (missing: actor; unexpected: )','incomplete preparation',False),
 ('missing child module',prefix+'have incomplete generated children (missing: worker; unexpected: )','incomplete generated children',False),
 ('missing nested producer',prefix+'have incomplete preparation (missing: parent_completion_products; unexpected: )','incomplete preparation',False),
 ('erased domain in both product maps',prefix+'have incomplete source domain membership (missing: aux; unexpected: )','incomplete source domain membership',False),
 ('wrong partition realization',prefix+'have mismatched domain partition kind','mismatched domain partition kind',False),
 ('erased child IR',prefix+"have malformed child scope 'worker'",'malformed child scope',False),
 ('erased partition',prefix+'are missing the source domain partition','missing the source domain partition',False),
]
safe={'missing parent_named_completion_products','missing parent_payload_snapshot_products','missing transaction_binding_report_products','malformed transaction_binding_report_products'}
binding=load('bindings.json')
assert set(binding)=={'baseline','metadata','sources'} and binding['baseline']==REV
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',REV,'--','bin','perl','t','scripts','isf']).decode().splitlines()
assert set(binding['metadata'])==set(paths)
for path,row in binding['metadata'].items():
 raw=Path(path).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
hashes=subprocess.check_output(['git','hash-object','--stdin-paths'],input=('\n'.join(paths)+'\n').encode()).decode().splitlines()
gitrows=subprocess.check_output(['git','ls-tree','-r',REV,'--','bin','perl','t','scripts','isf']).decode().splitlines()
wanted={r.split('\t',1)[1]:r.split()[2] for r in gitrows}
for p,h in zip(paths,hashes):assert h==wanted[p]
for p,body in binding['sources'].items():assert body==Path(p).read_text()
api=load('default-api.json')
assert set(api)=={'rows'} and len(api['rows'])==64
failures=[r for r in api['rows'] if not r['accepted']]
assert len(failures)==len(contracts)
for row in api['rows']:
 assert set(row)=={'before','after','accepted','error','result'}
 same(row['before'],row['after'])
 if row['accepted']:assert row['accepted']==1 and row['error']==''
 else:same(row['accepted'],0);same(row['result'],None)
def verify_rows(data):
 assert set(data)=={'rows'} and len(data['rows'])==len(contracts)*3
 for index,(label,cause,pattern,direct) in enumerate(contracts):
  full_label=label if direct else label+' has a focused diagnostic'
  for offset,band in enumerate(('current_fixture','earlier_reference','primary_cause_echo')):
   row=data['rows'][index*3+offset]
   assert set(row)=={'label','direct','band','expected_cause','pattern','before','after','error','assertions','primary_matched'}
   same([row[k] for k in ('label','direct','band','expected_cause','pattern')],[full_label,int(direct),band,cause,'(?^:'+pattern+')'])
   expected=copy.deepcopy(failures[index]['before'])
   if band!='current_fixture':expected[cause if band=='primary_cause_echo' else '_early_reference']={'$blessed':'PreparedCauseSentinel','$value':{}}
   same(row['before'],expected);same(row['after'],expected)
   key=cause if band=='primary_cause_echo' else '_early_reference'
   path='/'+key.replace('~','~0').replace('/','~1')
   primary=cause if band=='current_fixture' else "Formal reservation inventory has unsupported reference at '"+path+"'"
   assert row['error'].splitlines()[0]==primary and "\teval '" not in row['error']
   matched=int(band!='earlier_reference' or (not direct and label not in safe))
   same(row['assertions'],[1,matched]);same(row['primary_matched'],int(band!='earlier_reference'))
   base=failures[index]['before']
   if label.startswith('missing ') and label[8:] in fields:assert label[8:] not in base
   if label.startswith('malformed ') and label[10:] in fields:same(base[label[10:]],'wrong shape')
   if label=='cycle diagnostic retained':same(base['actor_context']['cycle'],{'$cycle':''})
   if label=='unknown producer must be classified':same(base['new_producer_products'],{})
   elif label=='missing live transaction producer':assert 'main' not in base['transaction_products']
   elif label=='unknown context':same(base['transactions']['ghost'],{})
   elif label=='unknown generated child':same(base['generated_children']['ghost'],1)
   elif label=='unknown partition':same(base['domain_partition'],{'kind':'future_partition'})
   elif label=='unclassified reusable product':same(base['reusable_child_products']['unclassified'],{})
   elif label=='missing domain':assert 'aux' not in base['domain_source_products']
   elif label=='wrong domain owner':same(base['domain_source_products']['aux']['identity'],['actor_domain','scoped_reservations','core'])
   elif label=='missing nested actor':assert 'actor' not in base['domain_source_products']['aux']['preparation']
   elif label=='missing child module':assert 'worker' not in base['domain_source_products']['core']['preparation']['generated_child_products']
   elif label=='missing nested producer':assert 'parent_completion_products' not in base['domain_source_products']['core']['preparation']
   elif label=='erased domain in both product maps':
    same([d['name'] for d in base['domain_partition']['domains']],['core']);assert 'aux' not in base['domain_source_products']
   elif label=='wrong partition realization':same(base['domain_partition']['kind'],'single_domain')
   elif label=='erased child IR':same(base['domain_source_products']['core']['preparation']['generated_child_products']['worker'],{})
   elif label=='erased partition':same(base['domain_partition'],None);same(base['domain_source_products'],{})

verify_rows(load('causes.json'))
data=load('causes.json')
replay=json.loads(subprocess.check_output(['perl',str(B/'replay.pl')]))
same(replay,[[r['assertions'][1],r['primary_matched']] for r in data['rows']])
if '--trust-current' in sys.argv:
 assert all(r['assertions'][1]==int(r['band']=='current_fixture') for r in data['rows']),'current full-error consumers accept111 wrong causes'
# Complete conservative token/pointer inventory is independently reconstructed
# from actual selected prepared products; constructor meanings remain cold.
parent_fields='parent_activation_products parent_completion_products parent_named_completion_products parent_point_products parent_payload_snapshot_products parent_storage_read_products parent_storage_write_products parent_wiring_products resource_signal_products transaction_products transaction_binding_report_products'.split()
def inventory(value):
 origins={}
 def add(text,path,position):
  for token in sorted(set(re.findall('[A-Za-z_][A-Za-z0-9_]*',text))):
   origins.setdefault(token,[]).append({'path':path,'position':position})
 def walk(value,path):
  if isinstance(value,dict):
   for key in sorted(value):
    child=path+'/'+key.replace('~','~0').replace('/','~1');add(key,child,'key');walk(value[key],child)
  elif isinstance(value,list):
   for i,item in enumerate(value):walk(item,path+'/'+str(i))
  elif value is not None:
   assert not isinstance(value,bool)
   add(str(value).replace('${REPO_ROOT}',str(Path.cwd())),path,'value')
 walk(value,'')
 return {'reserved_names':{key:1 for key in origins},'origins':origins}
def expected_scopes(p,prefix=None):
 if p['domain_partition'] and p['domain_partition']['kind']=='multi_domain':
  return sum((expected_scopes(p['domain_source_products'][name]['preparation'],['actor_domain',p['actor']['actor_name'],name]) for name in sorted(p['domain_source_products'])),[])
 identity=prefix or ['actor_module',p['actor']['actor_name']]
 rows=[{'identity':identity+['parent'],**inventory({key:p[key] for key in ['actor']+parent_fields})}]
 children={**p['generated_child_products'],**p['reusable_child_products']['children']}
 rows.extend({'identity':identity+['child',name],**inventory({'child':children[name]})} for name in sorted(children))
 return rows
def verify_successes(rows):
 assert len(rows)==6
 expected_actors=['checked_reservations','checked_reservations','scoped_reservations','fifo_library_use','pruned','single']
 for row,actor in zip(rows,expected_actors):
  assert set(row)=={'before','after','accepted','error','result'} and set(row['before'])==fields
  same(row['before']['actor']['actor_name'],actor);same(row['after'],row['before']);same([row['accepted'],row['error']],[1,''])
  result=row['result'];assert set(result)=={'model','reserved_names','origins','scopes'}
  selected={key:row['before'][key] for key in ['actor','domain_partition']+parent_fields+['generated_child_products','reusable_child_products','domain_source_products']}
  same(result,{'model':'isf_prepared_formal_reservations_v1',**inventory(selected),'scopes':expected_scopes(row['before'])})
verify_successes([r for r in api['rows'] if r['accepted']])
for label in ('cause','graph-kind','marker','field','member','pattern'):
 bad=copy.deepcopy(data)
 if label=='cause':bad['rows'][0]['error']='wrong cause\n'
 elif label=='graph-kind':bad['rows'][0]['before']['actor_context']['watchdog']=True
 elif label=='marker':bad['rows'][1]['before']['_early_reference']['$blessed']='WrongMarker'
 elif label=='field':bad['rows'][0]['unexpected']=1
 elif label=='member':bad['rows'].pop()
 else:bad['rows'][0]['pattern']='(?^:wrong)'
 try:verify_rows(bad)
 except AssertionError:print('cause corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
for label in ('scope','token','kind'):
 bad=copy.deepcopy([r for r in api['rows'] if r['accepted']])
 if label=='scope':bad[0]['result']['scopes'][0]['identity'][1]='wrong'
 elif label=='token':bad[0]['result']['reserved_names']['unexpected']=1
 else:bad[0]['result']['reserved_names']['start']=True
 try:verify_successes(bad)
 except AssertionError:print('whole corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
assert (B/'probe.status').read_text()=='0\n'
assert (B/'desired-red.status').read_text()=='111\n' and 'failed 111 tests of 519' in (B/'desired-red.txt').read_text()
assert 'Files=1, Tests=4' in (B/'default.txt').read_text() and 'All tests successful' in (B/'default.txt').read_text()
if (B/'manifest.json').exists():
 members=load('manifest.json')['members'];assert set(members)=={str(p.relative_to(B)) for p in B.rglob('*') if p.is_file() and p.name!='manifest.json'}
 for name,row in members.items():
  raw=(B/name).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
print('PASS finite complete causes/graphs/source/mutations and whole conservative inventories/scopes; wider constructors and relocated-root semantics remain owned.')
