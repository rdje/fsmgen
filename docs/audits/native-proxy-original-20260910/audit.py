import copy,hashlib,json,re,subprocess,sys
from pathlib import Path
root=Path.cwd(); out=root/'.artifacts/logs/native-proxy-original-20260910'
sys.path.insert(0,str(root/'scripts'))
import fixture_kernel_sampler as sampler
program="use TAP::Parser; use JSON::PP; my $raw=do {local $/; <STDIN>}; my $p=TAP::Parser->new({tap=>$raw}); $p->run; print encode_json({run=>$p->tests_run,planned=>$p->tests_planned,passed=>[$p->passed],failed=>[$p->failed],errors=>[$p->parse_errors]});"
def pin(path):
 data=path.read_bytes(); return {'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
def parse(raw):
 return json.loads(subprocess.run(['/usr/bin/perl','-e',program],input=raw,capture_output=True,check=True,timeout=5).stdout)
def validate(raw,result):
 parsed=parse(raw); rows=re.findall(rb'^(not )?ok (\d+) - (.*)$',raw,re.M)
 assert parsed['planned']==parsed['run']==15 and not parsed['errors']
 assert [int(row[1]) for row in rows]==list(range(1,16))
 assert [int(row[1]) for row in rows if row[0]]==parsed['failed']==[10,11,12]
 assert result['returncode']==3 and result['native_wait_status']==768
 assert result['released'] and result['leader_reaped'] and not result['timeout']
 return parsed
report=json.loads((out/'qualification.json').read_text()); result=json.loads((out/'test-result.json').read_text()); identity=json.loads((out/'original-identity.json').read_text()); admission=json.loads((out/'admission.json').read_text())
tap=(out/'test.tap').read_bytes(); stderr=(out/'test.stderr').read_text()
parsed=validate(tap,result)
assert result==report['result'] and result['pid']==identity['pid']==7409
assert not report['errors'] and report['input_bytes_unchanged'] and report['selection_context_unchanged'] and report['original_native_birth_absent']
for name in ('test.tap','test.stderr'): assert pin(out/name)==report['outputs'][name]
for path,expected in admission['source_pins'].items():
 assert pin(root/path)==expected
 raw=subprocess.run(['git','show',admission['revision']+':'+path],capture_output=True,check=True,timeout=5).stdout
 assert hashlib.sha256(raw).hexdigest()==expected['sha256']
assert len(admission['source_pins'])==24
assert not any(admission['fixture_census'].values()) and not any(report['fixture_census_after'].values()) and not any(report['new_fixture_entries'].values())
try: current=sampler.NativeProcesses().identity(identity['pid'])
except (ProcessLookupError,FileNotFoundError): current=None
assert current is None or any(current[key]!=identity[key] for key in sampler.IDENTITY_FIELDS)
rust=[json.loads(line.split('Rust tool-resolution result: ',1)[1]) for line in stderr.splitlines() if 'Rust tool-resolution result: ' in line]
legacy=[json.loads(line.split('Legacy main-entry result: ',1)[1]) for line in stderr.splitlines() if 'Legacy main-entry result: ' in line]
assert [item['mode'] for item in rust]==['proxy_nonzero','proxy_decoy']
for item in rust:
 adapter=item['adapter']; stage=adapter['stages'][0]
 assert len(adapter['stages'])==1 and adapter['failure_stage']==stage['stage']=='tool_resolution'
 assert adapter['status']==stage['status']=='timed_out' and stage['timeout_seconds']==10
 assert stage['stdout']==stage['stderr']=='' and stage['first_output_monotonic_ns'] is None
 assert stage['signal']==15 and stage['cleanup']['leader_reaped'] and stage['cleanup']['group_gone']
 assert item['outer']['ok'] and json.loads(item['outer']['stdout'])==adapter
assert [item['mode'] for item in legacy]==['signal','streams']
for item in legacy:
 assert not item['marker']['regular_file'] and item['marker']['content'] is None
 assert item['result']['status']=='timed_out' and item['result']['timeout_seconds']==5
 assert not (root/item['fixture']['path']).parent.exists()
assert "only sealed policy adapters call the low-level supervisor" in stderr and "t/lib/FSM/Test/RustProxyFixture.pm" in stderr
mutants=[]
for field,value in [('returncode',0),('native_wait_status',0),('leader_reaped',False)]:
 changed=copy.deepcopy(result); changed[field]=value
 try: validate(tap,changed)
 except AssertionError: mutants.append(field)
 else: raise AssertionError('changed result accepted: '+field)
try: validate(re.sub(rb'^1\.\.15\n',b'',tap,flags=re.M),result)
except AssertionError: mutants.append('missing_plan')
else: raise AssertionError('missing TAP plan accepted')
summary={'original_result':'failed','identity':identity,'result':result,'tap':pin(out/'test.tap'),'stderr':pin(out/'test.stderr'),'tap_parser':parsed,'independent_root_rows':15,'inputs_match':24,'native_root_birth_absent':True,'recorded_fixture_roots_empty':True,'legacy_workspaces_independently_absent':True,'rust_failure_records':rust,'legacy_failure_records':legacy,'known_integration_defect':'RustProxyFixture missing from explicit architecture adapter list','native_producer_implementation':'inferred by admission, not directly observed','unobserved_descendants':'unknown','rejected_retained_mutants':mutants,'original_reexecuted':False}
(out/'independent-audit.json').write_text(json.dumps(summary,sort_keys=True,indent=2)+'\n')
print(json.dumps({'audit':pin(out/'independent-audit.json'),'failed_roots':parsed['failed'],'rejected_mutants':mutants,'root_absent':True},sort_keys=True))
