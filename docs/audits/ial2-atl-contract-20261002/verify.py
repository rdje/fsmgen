import hashlib,json,re,subprocess,sys
from pathlib import Path
r=Path(__file__).parent
base=json.loads((r/'baseline.json').read_text())
for name,digest in base['inputs'].items():
 data=(r/'sources'/name).read_bytes()
 assert hashlib.sha256(data).hexdigest()==digest
 assert data==subprocess.check_output(['git','show',base['head']+':'+name])
 assert data==Path(name).read_bytes()
apb={p.name:p.read_text() for p in (r/'products/apb').iterdir()}
assert set(apb)=={'apb_requester.isf','apb_completer.isf','apb_requester.fsm','apb_completer.fsm','apb_tb.fsm'}
if '--require-network' in sys.argv:
 assert 'apb_tb.isf' in apb, 'missing required IAL1 ATL network artifact: apb_tb.isf'
report=json.loads((r/'apb-schedule.json').read_text())
assert report['schema']=='fsmgen.ial2.protocol_intent.apb_composition.v1'
artifacts=report['generated_artifacts']
assert artifacts['ial1']=={'format':'isf','items':[{'format':'isf','name':'apb_requester.isf','object_name':'apb_requester','role':'requester'},{'format':'isf','name':'apb_completer.isf','object_name':'apb_completer','role':'completer'}]}
assert artifacts['ial0']['files']==['apb_completer.fsm','apb_requester.fsm','apb_tb.fsm']
assert artifacts['hdl_entry']['entry_artifact']=='apb_tb.fsm'
assert report['layering']['direct_ial2_to_ial0']==0
for name in ('apb_requester','apb_completer'):
 assert apb[name+'.isf'].startswith('(actor '+name)
 assert '(instance ' not in apb[name+'.isf']
# Frozen observed output for conservation controls; not a protocol correctness oracle.
prefix='(?top:apb_tb\n  (?ports:public_io\n    clk\n    rst_n\n    =start\n    =req_write\n    =req_addr<32\n    =req_wdata<32\n    =wait_cycles<4\n    =done>\n    =last_error>\n    =last_read_data>32\n  )\n  (?fsmc:requester apb_requester)\n  (?fsmc:completer apb_completer)\n  (?wiring:apb_bus\n    (requester.PSEL completer.PSEL)\n    (requester.PENABLE completer.PENABLE)\n    (requester.PWRITE completer.PWRITE)\n    (requester.PADDR completer.PADDR)\n    (requester.PWDATA completer.PWDATA)\n    (completer.PREADY requester.PREADY)\n    (completer.PRDATA requester.PRDATA)\n    (completer.PSLVERR requester.PSLVERR)\n  )\n)\n'
def check_top(text):
 assert text.startswith(prefix)
 assert len(re.findall(r'\(\?fsmc:',prefix))==2
check_top(apb['apb_tb.fsm'])
for bad in (apb['apb_tb.fsm'].replace('(requester.PSEL completer.PSEL)','(requester.PSEL completer.PENABLE)',1),apb['apb_tb.fsm'].replace('(?fsmc:completer apb_completer)','',1)):
 try:check_top(bad)
 except AssertionError:continue
 raise AssertionError('hostile wiring/topology claim accepted')
for kind in ('apb','atl'):
 for file in (r/'products'/kind).iterdir():
  assert file.read_bytes()==Path('.artifacts/ial2-atl-contract-20261002/'+kind+'/'+file.name).read_bytes()
trigger=json.loads((r/'atl-trigger-schedule.json').read_text())['actor_network']
assert len(trigger['instances'])==3 and len(trigger['association_schedules'])==1
assert len(trigger['transaction_triggers'])==3 and trigger['data_movements']==[]
data=json.loads((r/'atl-data-schedule.json').read_text())['actor_network']
assert len(data['instances'])==2 and len(data['data_movements'])==1 and data['association_schedules']==[]
assert data['data_movements'][0]['route_lifetime']=='drive_call_cycle'
assert data['data_movements'][0]['storage']=='none'
atl={p.name:p.read_text() for p in (r/'products/atl').iterdir()}
assert set(atl)=={'atl_resolved_child_pipeline.fsm','atl_resolved_child_pipeline__worker.fsm','atl_resolved_child_pipeline_top.fsm'}
assert atl['atl_resolved_child_pipeline_top.fsm'].startswith('(?top:atl_resolved_child_pipeline_top')
assert '(?fsmc:worker atl_resolved_child_pipeline__worker)' in atl['atl_resolved_child_pipeline_top.fsm']
assert 'All tests successful' in (r/'docs.tap').read_text()
assert 'Files=3, Tests=293' in (r/'docs.tap').read_text()
assert '115 complete fixtures lowered cleanly' in (r/'docs.tap').read_text()
for path,terms in {'13f-composition':['Actor Transfer Level (ATL)','ATL And IAL2 Lowering','architectural requirement with an implementation gap'],'16-ial2-protocol-platform-intent':['Actor Networks In The Lowering Chain','no <code>apb_tb.isf</code>']}.items():
 rendered=Path('docs/book/book/'+path+'.html').read_text()
 for term in terms:assert term in rendered,term
print('PASS exact complete source/Git and actual generated artifacts, fixed-APB missing-network boundary, frozen topology/wiring conservation and hostile saved controls, current ATL commands and source/rendered book scope')
