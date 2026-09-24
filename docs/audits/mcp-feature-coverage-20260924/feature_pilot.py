from pathlib import Path
import json,subprocess,hashlib
root=Path.cwd();folder=Path('.artifacts/mcp-feature-coverage');results=[]
sources=['t/corpus/direct_size_expression_widths.fsm','t/corpus/direct_rhs_concat_pack.fsm','t/corpus/computed_test_selector.fsm','t/corpus/standalone_dtc_explicit_system_autowire.fsm','isf/storage_fields.isf','isf/verification_observation_metadata.isf','ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif']
def normalize(value):
 if isinstance(value,dict):return {k:normalize(v) for k,v in value.items()}
 if isinstance(value,list):return [normalize(v) for v in value]
 if isinstance(value,str):return '.' if value==str(root) else value.replace(str(root)+'/', '')
 return value
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def diff(a,b,path=''):
 if type(a)!=type(b):return path,a,b
 if isinstance(a,dict):
  if a.keys()!=b.keys():return path,sorted(a),sorted(b)
  for k in a:
   d=diff(a[k],b[k],path+'/'+str(k))
   if d:return d
 elif isinstance(a,list):
  if len(a)!=len(b):return path,{'length':len(a)},{'length':len(b)}
  for i,(x,y) in enumerate(zip(a,b)):
   d=diff(x,y,path+'/'+str(i))
   if d:return d
 elif a!=b:return path,a,b
 return None
for source in sources:
 for kind in (['semantic','schedule'] if source.endswith(('.isf','.ppif')) else ['semantic']):
  flags=['--strict','--emit-semantic-json'] if kind=='semantic' else ['--emit-schedule-json']
  argv=['bin/fsmgen']+flags+[str(root/source)]
  native=subprocess.run(argv,capture_output=True,text=True)
  report=json.loads(native.stdout)
  assert native.returncode==0,(source,kind,native.stderr,report)
  request={'jsonrpc':'2.0','id':1,'method':'tools/call','params':{'name':'fsmgen_semantic_introspect' if kind=='semantic' else 'fsmgen_schedule_preview','arguments':{'source_id':source}}}
  mcp=subprocess.run(['perl','bin/fsmgen-mcp','--workspace-root','.'],input=json.dumps(request)+'\n',capture_output=True,text=True)
  response=json.loads(mcp.stdout)
  actual=response.get('result',{}).get('structuredContent',{}).get('report')
  expected=normalize(report);delta=diff(expected,actual)
  row={'source':source,'kind':kind,'source_sha256':hashlib.sha256((root/source).read_bytes()).hexdigest(),'native_exit':native.returncode,'mcp_exit':mcp.returncode,'native_report_sha256':digest(expected),'mcp_report_sha256':digest(actual),'first_difference':delta,'native_stderr_empty':not native.stderr,'mcp_stderr_empty':not mcp.stderr}
  results.append(row);(folder/'feature-pilot-results.json').write_text(json.dumps(results,sort_keys=True,indent=2)+'\n')
  if delta or mcp.returncode or 'error' in response:
   (folder/'feature-pilot-failed-native.json').write_text(json.dumps(expected,sort_keys=True,indent=2)+'\n');(folder/'feature-pilot-failed-mcp.json').write_text(json.dumps(response,sort_keys=True,indent=2)+'\n')
   raise RuntimeError((source,kind,delta,response.get('error')))
  if source=='isf/storage_fields.isf' and kind=='schedule':
   entry=next(x for x in actual['inferred_storage'] if x['name']=='control')
   assert [x['name'] for x in entry['fields']]==['mode','prio','enable']
   row['authored_observation']={'storage':'control','fields':[x['name'] for x in entry['fields']]}
  if source=='isf/verification_observation_metadata.isf' and kind=='schedule':
   observations=actual['verification_observations'];assert observations[0]['name']=='link_rx'
   assert [x['name'] for x in observations[0]['signals']]==['valid','ready','data']
   row['authored_observation']={'observation':'link_rx','signals':[x['name'] for x in observations[0]['signals']]}
  (folder/'feature-pilot-results.json').write_text(json.dumps(results,sort_keys=True,indent=2)+'\n')
  print(kind,source,'PASS',flush=True)
