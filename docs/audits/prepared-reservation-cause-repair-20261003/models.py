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
