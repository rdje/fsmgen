from pathlib import Path
import hashlib,json,subprocess
out=Path('.artifacts/mcp-feature-coverage')
def run(argv,stdin=None):
    r=subprocess.run(argv,input=stdin,capture_output=True,text=True)
    assert r.returncode==0 and not r.stderr,(argv,r.returncode,r.stderr)
    return json.loads(r.stdout)
def digest(v):
    return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
rows=[]
for version,source in [(1,'vial/ahb_subordinate_base_output_arbitration.vial'),(2,'vial/ahb_subordinate_base_output_arbitration_v2.vial'),(2,'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial')]:
    native_argv=['bin/fsmgen','vial','check','--json','--language-version',str(version),source]
    native=run(native_argv)
    request={'jsonrpc':'2.0','id':1,'method':'tools/call','params':{'name':'fsmgen_semantic_introspect','arguments':{'source_id':source,'language_version':version}}}
    reply=run(['perl','bin/fsmgen-mcp','--workspace-root','.'],json.dumps(request)+'\n')
    assert 'error' not in reply,reply
    response=reply['result']; payload=response['structuredContent']
    assert payload['report']==native and json.loads(response['content'][0]['text'])==payload and not response['isError']
    rows.append({'source':source,'language_version':version,'source_sha256':hashlib.sha256(Path(source).read_bytes()).hexdigest(),'native_command':native_argv,'stdio_request':request,'native_mcp_equal':True,'report_sha256':digest(native),'text_structured_equal':True})
paths=['docs/audits/mcp-feature-coverage-20260924/capture_vial_mcp.py','perl/FSM/Support/SemanticIntrospectionContract.pm','perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm','perl/FSM/VIAL/Tool.pm','perl/FSM/VIAL/ToolCLI.pm','t/1871-semantic-introspection-mcp-vial.t','t/1869-semantic-introspection-mcp-protocol-aliases.t','t/fixtures/semantic_introspection_mcp/read_only_schema_snapshot.json']
logs={}
for name in ['vial-mcp-baseline','vial-mcp-band-corrected','vial-mcp-completion']:
    raw=(out/(name+'.log')).read_bytes();text=raw.decode()
    if name!='vial-mcp-baseline': assert 'Result: PASS' in text
    logs[name]={'sha256':hashlib.sha256(raw).hexdigest(),'summary':[line for line in text.splitlines() if line.startswith(('Files=','Result:','All tests successful'))]}
record={'schema':'fsmgen.vial_mcp_projection_repair.v1','owner':'SEMANTIC-INTROSPECTION-MCP-FRONTIER.31.2.4.2','capture_base_revision':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'file_sha256':{p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in paths},'native_stdio_parity':rows,'book_example_results':json.loads((out/'vial-mcp-book-examples.json').read_text()),'qualification_logs':logs,
'evidence_legs':{'rederive':'T1871 and the recorded actual CLI/stdio requests compare complete native public reports, not just success flags. Book commands exercise actual one-shot MCP capability, discovery, semantic and resource routes.',
'falsify':'Initial T1871 rejected missing versioned capabilities/resources, absent VIAL discovery, wrong hardware routing and unchecked selectors. Final controls reject wrong versions, hardware selectors, scheduling/action expansion, malformed source identities, symlink sources/directories/imports, workspace escape and over-limit inputs. Native v2 source without a selector remains a v1 failure.',
'durability':'Tracked T1871, native source fixtures, reviewed schema snapshot and runnable book examples reproduce these contracts. File digests bind this capture; T1869 guards shipped suffix membership and T1806 freezes native v1 metadata.'},
'limits':['Read-only source checking and semantic projection only; no MCP planning, backend run or mutation capability.', 'Complete feature-level coverage remains owned by .31.3; these are named real v1/v2/lifecycle fixtures and explicit negative controls.', 'The first selected band invocation named a nonexistent T1868 path and was rejected; only the corrected 14-file band is accepted.', 'Visual browser inspection remains unavailable; mdBook build and rendered HTML checks pass.']}
Path('docs/audits/mcp-feature-coverage-20260924/vial-mcp-repair.json').write_text(json.dumps(record,sort_keys=True,indent=2)+'\n')
print('Actual native CLI / newline stdio VIAL result parity: PASS')
