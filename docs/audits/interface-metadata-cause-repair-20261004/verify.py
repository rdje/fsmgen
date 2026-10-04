"""Independent complete metadata causes, native contexts and conserved streams."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
BASE=Path(__file__).parent
parser=argparse.ArgumentParser()
parser.add_argument('--omit-cause',action='store_true')
parser.add_argument('--trust-location',action='store_true')
parser.add_argument('--trust-bypass',action='store_true')
args=parser.parse_args()
subprocess.run(['python3','-B','docs/audits/interface-metadata-source-product-join-20261004/verify.py'],check=True)
if (BASE/'manifest.json').exists():
    manifest=json.loads((BASE/'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()}==set(manifest)|{'manifest.json'}
    for name,row in manifest.items():
        raw=(BASE/name).read_bytes();assert len(raw)==row['bytes'] and hashlib.sha256(raw).hexdigest()==row['sha256']
binding=json.loads((BASE/'binding-before.json').read_text())
after=json.loads((BASE/'sources-after.json').read_text())
for name,row in binding['sources'].items():
    raw=subprocess.check_output(['git','show',binding['revision']+':'+name])
    assert raw.decode()==row['body'] and len(raw)==row['bytes'] and hashlib.sha256(raw).hexdigest()==row['sha256']
    if name!='t/1983-isf-interface-port-metadata.t':assert after[name]==row['body']
assert set(after)==set(binding['sources'])|{'t/2064-isf-interface-metadata-diagnostic-context.t'}
source=after['t/1983-isf-interface-port-metadata.t']
assert source==(BASE/'test-after.t').read_text()
assert after['t/2064-isf-interface-metadata-diagnostic-context.t']==(BASE/'context-test-after.t').read_text()
before_source=binding['sources']['t/1983-isf-interface-port-metadata.t']['body']
def section(body,start,end):
    offset=body.index(start);return body[offset:body.index(end,offset)]
assert section(source,'sub source_value_copy {','my $parser =')==section(before_source,'sub source_value_copy {','my $parser =')
assert section(source,'sub stringify_numeric_properties {',"subtest 'capture and snapshot")==section(before_source,'sub stringify_numeric_properties {',"subtest 'capture and snapshot")
assert section(source,'    my $ok = eval { $parser->parse_source(', '\n};')==section(before_source,'    my $ok = eval { $parser->parse_source(', '\n};')
assert source[source.index('sub write_file {'):]==before_source[before_source.index('sub write_file {'):]
causes=json.loads((BASE/'expected-causes.json').read_text())
assert causes==json.loads(Path('docs/audits/interface-metadata-runtime-20261004/expected-causes.json').read_text())
assert 'my $error = $@;' in source and 'diagnostic_cause_matches($error, "Invalid ISF interface port metadata: $reason")' in source
for reasons in (causes['snapshot'],causes['capture']):
    block='    my @reasons = (\n'+''.join('        '+('"'+v+'"' if "'" in v else "'"+v+"'")+',\n' for v in reasons)+'    );\n'
    assert block in source

def equal(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(equal(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(equal(x,y) for x,y in zip(a,b))
    return a==b

def primary(error):return error.splitlines()[:1]
old=json.loads(Path('docs/audits/interface-metadata-copy-repair-20261004/ordinary.json').read_text())
data={m:json.loads((BASE/(m+'.json')).read_text()) for m in ('ordinary','bypass')}
ordinary=data['ordinary']
for mode,row in data.items():
    assert row['sources_before']==row['sources_after']=={k:after[k] for k in binding['sources']}
    assert len(row['api'])==105 and len(row['copies'])==144 and len(row['helpers'])==44 and len(row['parses'])==3
    assert len(row['consumers'])==336 and len(row['cause_consumers'])==46
    assert row['changed']==(2 if mode=='bypass' else 0)
    assert int((BASE/(mode+'.status')).read_text())==(1 if mode=='bypass' else 0)
    assert len(re.findall(r'^    (?:not )?ok [0-9]+ ',(BASE/(mode+'.txt')).read_text(),re.M))==336
for current,previous in zip(ordinary['api'],old['api']):
    for key in ('kind','helper','before','after','result','accepted','warnings'):assert equal(current[key],previous[key]),('whole ordinary API',key)
    assert equal(current['before'],current['after']) and current['warnings']==[] and primary(current['error'])==primary(previous['error'])
for current,previous in zip(ordinary['copies'],old['copies']):
    for key in ('kind','api','before','after','copy','original_reference_count','copy_reference_count','shared_with_original'):assert equal(current[key],previous[key]),('whole ordinary copy',key)
assert all(r['passed'] for r in ordinary['consumers'])
new_consumers=[r for r in ordinary['consumers'] if r['label'] not in (
    'every malformed snapshot declares its complete intended cause',
    'every invalid producer input declares its complete intended cause')]
assert len(new_consumers)==len(old['consumers'])==334
for current,previous in zip(new_consumers,old['consumers']):
    assert current['label']==previous['label'] and current['helper']==previous['helper'] and current['passed']==previous['passed']==1
    if current['kind']!=previous['kind']:
        assert previous['kind']=='like' and current['kind']=='ok' and current['actual']==1
        assert current['label']=='contextual bounded diagnostic' or current['label'] in (
            'capture retains a classified first diagnostic','snapshot retains a classified first diagnostic')
    elif current['kind']=='like':
        assert current['expected']==previous['expected'] and primary(current['actual'])==primary(previous['actual'])
    else:
        assert equal(current['actual'],previous['actual'])
        if 'expected' in current:assert equal(current['expected'],previous['expected'])
for current,previous in zip(ordinary['parses'],old['parses']):
    assert current['kind']==previous['kind'] and current['accepted']==previous['accepted']
    assert equal(current['result'],previous['result']) and primary(current['error'])==primary(previous['error'])
    assert current['before']==current['after'] and current['documents_before']==current['documents_after']
    assert {Path(k).name:v for k,v in current['documents_before'].items()}=={Path(k).name:v for k,v in previous['documents_before'].items()}
cycle=ordinary['cycles'][0]
assert len(ordinary['cycles'])==1 and equal(cycle['before'],cycle['after']) and equal(cycle['before'],cycle['copy'])
assert cycle['original_reference_count']==cycle['copy_reference_count']==7 and cycle['shared_with_original']==0
selected=ordinary['cause_consumers'][:-1] if args.omit_cause else ordinary['cause_consumers']
assert len(selected)==46,'complete helper and first-read cause membership'
helper_checks=[r for r in selected if r['helper'] is not None]
assert [r['helper'] for r in helper_checks]==list(range(44))
for index,(helper,check) in enumerate(zip(ordinary['helpers'],helper_checks)):
    reason=(causes['snapshot']+causes['capture'])[index]
    assert helper['reason']==reason and check['expected']=='Invalid ISF interface port metadata: '+reason
    assert check['matched']==1 and primary(check['error'])==[check['expected']]
    api=ordinary['api'][helper['api_start']]
    assert api['helper']==index and api['accepted']==0 and check['error']==api['error']
first=[r for r in selected if r['helper'] is None]
assert [r['expected'] for r in first]==causes['adjacent'][:2]
assert all(r['matched']==1 and primary(r['error'])==[r['expected']] for r in first)
changed=[i for i,(a,b) in enumerate(zip(ordinary['api'],data['bypass']['api'])) if a['accepted']!=b['accepted']]
assert changed==[ordinary['helpers'][i]['api_start'] for i in (5,27)]
for index,(a,b) in enumerate(zip(ordinary['api'],data['bypass']['api'])):
    for key in ('kind','helper','caller','before','after','warnings'):assert equal(a[key],b[key])
    if index in changed:
        assert a['accepted']==0 and b['accepted']==1 and b['error']==''
        assert equal(b['result'],b['before'][1][0]),'genuine name-guard bypass returns actual invalid input metadata'
    else:assert a['accepted']==b['accepted'] and equal(a['result'],b['result']) and primary(a['error'])==primary(b['error'])
failures=[r for r in data['bypass']['consumers'] if not r['passed']]
assert [r['label'] for r in failures]==['malformed snapshot 5 fails closed','contextual bounded diagnostic','malformed snapshot 27 fails closed','contextual bounded diagnostic']
safe=bool(failures)
if args.trust_bypass:safe=all(r['passed'] for r in data['bypass']['consumers'])
assert safe,'genuine validation bypass cannot be promoted to passing diagnostic assurance'
context=json.loads((BASE/'context-native.json').read_text())
permanent=after['t/2064-isf-interface-metadata-diagnostic-context.t']
assert context['driver']==section(permanent,"write_file($driver, <<'PERL');\n",'\nPERL\n').split('\n',1)[1]+'\n'
assert context['provider']==after['perl/FSM/Support/ISFInterfacePortMetadata.pm']
assert int((BASE/'context-native.status').read_text())==0
assert 'Files=1, Tests=73' in (BASE/'context-native.txt').read_text() and 'All tests successful' in (BASE/'context-native.txt').read_text()
def helper(body):return body[body.index('sub rejects {'):body.index('sub write_file {')]
assert [r['mode'] for r in context['runs']]==['ordinary','location_echo']
for run in context['runs']:
    capture=run['capture']
    assert capture['current_helper']==helper(source)
    assert capture['old_helper']==helper(binding['sources']['t/1983-isf-interface-port-metadata.t']['body'])
    assert [r['id'] for r in capture['rows']]==['real_metadata','earlier_storable','caller_label_echo','caller_argument_echo']
    if run['mode']=='ordinary':assert capture['loaded_module']=='perl/FSM/Support/ISFInterfacePortMetadata.pm'
    else:assert re.fullmatch(r'\$\{REPO_ROOT\}/\.artifacts/tmp/tests/[A-Za-z0-9_]+/Invalid ISF interface port metadata:/FSM/Support/ISFInterfacePortMetadata\.pm',capture['loaded_module'])
    for row in capture['rows']:
        prior,current=row['subjects'];real=row['id']=='real_metadata'
        assert prior['bits']==[1,int(real or run['mode']=='location_echo'),1]
        assert current['bits']==[1,int(real),1] and prior['accepted']==current['accepted']==0
        assert prior['warnings']==current['warnings']==[] and primary(prior['error'])==primary(current['error'])
        assert equal(prior['after'],row['before']) and equal(current['after'],row['before'])
        assert current['causes']==[[current['error'],'Invalid ISF interface port metadata: expected port metadata entry']]
        if not real:
            assert current['error'].startswith("Can't store CODE items at ")
            if run['mode']=='location_echo':
                accepted=current['bits'][1]==1
                if args.trust_location:accepted=prior['bits'][1]==1
                assert not accepted,'file/caller/argument echo cannot establish intended metadata primary cause'
print('PASS complete44 helper and2 first-read causes, ordinary105 API/144 copy/336 native consumers and exact prior/current permanent73-check native context proof. Immediate errors/complete intended causes conserve; genuine wanted-prefix Storable false GREEN now rejects and actual name-guard bypass fails refusal/cause checks. Source kinds/sharing/cycle/numeric final products remain qualified; writer adjacent repair stays separately owned.')
