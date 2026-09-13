"""Join the new harness source, inert checks and original first-failure epochs."""
from __future__ import annotations
import argparse
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess
from support_controls import BASE, ROOT, A
import audit_data

LOG=ROOT/'.artifacts/logs'/BASE.name
STAGES=('first-syntax','first-data-prepare','first-data-bridge','archive-alias-diagnostic','corrected-data-bridge','reader-data')


def document(path):return json.loads(path.read_bytes())
def sha(body):return hashlib.sha256(body).hexdigest()
def pin(path):
    body=path.read_bytes();return dict(path=path.relative_to(ROOT).as_posix(),size_bytes=len(body),sha256=sha(body))
def capture(row):
    body=bytes.fromhex(row['bytes_hex']);assert sha(body)==row['sha256'] and len(body)==row['size_bytes'];return body


def body(text,name):
    matches=list(re.finditer(r'^sub ([A-Za-z_][A-Za-z0-9_]*)\s*\{',text,re.M))
    position=next(i for i,m in enumerate(matches) if m[1]==name)
    return text[matches[position].start():matches[position+1].start() if position+1<len(matches) else text.rfind('\nmain()')].rstrip()


def source_join():
    old=(A/'qualify.pl').read_text();new=(BASE/'qualify_controls.pl').read_text()
    shared=re.findall(r'^sub (\w+)\s*\{',old,re.M)
    for name in shared:
        if name=='main':continue
        previous=body(old,name)
        if name=='journal':previous=previous.replace('fsmgen.inactive_lifetime_files_event.v1','fsmgen.inactive_lifetime_controls_event.v1')
        assert previous==body(new,name),name
    expected_main=body(old,'main')
    changes=[
        ("my $base = 'docs/audits/native-proxy-lifetime-files-admission-20260913';","my $base = 'docs/audits/native-proxy-lifetime-control-harness-20260913';"),
        ('$PLAN = document("$base/plan.json"); $SELECTION = document("$base/selection.json");','$PLAN = document("$base/harness-plan.json");\n    $SELECTION = document("docs/audits/native-proxy-lifetime-controls-admission-20260913/selection.json");'),
        ('$PINS = document("$base/preflight-pins.json");','$PINS = document("$base/final-preflight-pins.json");'),
        ('native-proxy-lifetime-files-20260913/execution-admission.json','native-proxy-lifetime-controls-20260913/execution-admission.json'),
        ('"$base/plan.json"','"$base/harness-plan.json"'),('"$base/preflight-pins.json"','"$base/final-preflight-pins.json"'),
        ('"$base/selection.json"','"docs/audits/native-proxy-lifetime-controls-admission-20260913/selection.json"'),
        ('execute_event($context, $_) for @{$case->{order}};','execute_event($context, $_) for @{$case->{prefix}};\n                execute_control($context, $case);')]
    for before,after in changes:expected_main=expected_main.replace(before,after)
    assert expected_main==body(new,'main')
    expected_header=old[:old.index('sub read_bytes')].replace('package NativeProxyLifetimeQualification;','package NativeProxyLifetimeControlQualification;').replace('use LifetimeTrace;','use lib "$FindBin::Bin/../native-proxy-lifetime-files-admission-20260913";\nuse LifetimeTrace;').replace('use FixtureClone;','use FixtureClone;\nuse Controls;')
    assert new[:new.index('sub read_bytes')]==expected_header
    extra=['closed_trace','invoke_control','measure_control','execute_control']
    assert set(re.findall(r'^sub (\w+)\s*\{',new,re.M))==set(shared+extra)
    fragment=(BASE/'control-routines.pl.source').read_text();assert fragment in new
    measure=body(new,'measure_control')
    assert measure.index("journal('stage', {case => $context->{name}, name => $name, before => $before, operation => $trace")<measure.index('control caller inputs changed')
    assert measure.index('my $trace = observe')<measure.index('my $after = probe')<measure.index('primary control descriptors incomplete')
    helper=(BASE/'Controls.pm').read_text();start=helper.index('sub with_fault');end=helper.index('sub expected_error',start);hook=helper[start:end]
    assert hook.index('$original->(@_)')<hook.index('return unless matches')<hook.index('push @$hits')<hook.index('die $selector->{error}')
    assert 'local *NativeProxyLifetimeTrace::_call' in hook
    assert new.endswith('main() unless caller;\n1;\n')
    return dict(unchanged_complete_harness_functions=len(shared)-2,adapted_journal_and_main=2,new_control_functions=len(extra))


def retained_epochs():
    known={}
    for filename,key in (('first-syntax.json','sources'),('first-data-failure.json','sources')):
        report=document(BASE/filename)
        for row in report[key]:
            old=row['source'];retained=(ROOT/row['retained_path']).read_bytes()
            assert sha(retained)==old['sha256'] and len(retained)==old['size_bytes']
            known[(old['path'],old['sha256'])]=retained
        for row in report['raw_captures']:capture(row)
    original_plan=(BASE/'reader-data-plan.json.source').read_bytes()
    known[(str((BASE/'harness-plan.json').relative_to(ROOT)),sha(original_plan))]=original_plan
    for filename in ('first-syntax-pins.json','first-data-pins.json','corrected-data-pins.json','reader-data-pins.json'):
        for row in document(BASE/filename):
            current=(ROOT/row['path']).read_bytes()
            value=current if sha(current)==row['sha256'] else known[(row['path'],row['sha256'])]
            assert sha(value)==row['sha256'] and len(value)==row['size_bytes']
    correction=document(BASE/'archive-alias-correction.json')
    previous=(ROOT/correction['original_source']).read_bytes().decode()
    assert previous.count(correction['before_block'])==1
    assert previous.replace(correction['before_block'],correction['after_block'])==(BASE/'Controls.pm').read_text()
    for row in correction['raw_captures']:capture(row)
    output=capture(correction['raw_captures'][0]).splitlines()
    assert [json.loads(line) for line in output]==[dict(after_map=dict(archives=dict(a=None))),dict(after_exists_guard=dict(archives={}))]
    original=(BASE/'qualify_data.t').read_text()
    corrected=original.replace('my @hits;',"my @hits;\n        no warnings 'once';").replace('"$FindBin::Bin/data-qualification.json"','"$FindBin::Bin/corrected-data-qualification.json"')
    assert corrected==(BASE/'qualify_data_corrected.t').read_text()
    return dict(original_bridge_failure_preserved=True,guarded_missing_archive_copy=True,fixture_and_process_attempts=0)


def verify(outputs):
    plan=document(BASE/'harness-plan.json')
    for row in plan['inputs']+document(BASE/'harness-pins.json'):assert pin(ROOT/row['path'])==row
    for row in plan['inputs']:
        assert subprocess.check_output(['git','show',plan['source_revision']+':'+row['path']],cwd=ROOT)==(ROOT/row['path']).read_bytes()
    assert document(BASE/'data-review.json')==audit_data.verify()
    source=source_join();epochs=retained_epochs()
    values={row['path'].rsplit('/',1)[1]:capture(row) for row in outputs}
    assert len(values)==len(outputs)==3*len(STAGES)
    for stage in STAGES:assert values[stage+'.exit']==(b'1\n' if stage=='first-data-bridge' else b'0\n')
    assert b'syntax OK' in values['first-syntax.stderr']
    assert values['corrected-data-bridge.stdout'].endswith(b'1..96\n') and b'not ok' not in values['corrected-data-bridge.stdout']
    assert b'not ok' in values['first-data-bridge.stdout']
    selection=document(ROOT/plan['selection']);roots=[path for case in selection['cases'] for path in case['roots'].values()]
    assert len(roots)==len(set(roots))==56
    for relative in roots+[selection['journal']]:
        path=ROOT/relative;assert not path.exists() and not path.is_symlink()
    data=document(BASE/'data-review.json')
    return dict(schema='fsmgen.inactive_lifetime_control_harness_review.v1',owner=plan['owner'],source_revision=plan['source_revision'],
        source_inputs=len(plan['inputs']),source_join=source,original_epochs=epochs,data=pin(BASE/'data-review.json'),
        selected_cases=len(data['cases']),corrected_perl_checks=data['corrected_perl_checks'],reader_countermodels=len(data['rejected_countermodels']),
        healthy_resource_traces=len(data['retained_healthy_resource_traces']),prospective_roots_absent=roots,
        raw_output_count=len(outputs),actual_fixture_operations=0,
        missing_legs=['Final committed execution admission and permit','Actual interruption file effects and complete actual journal review'],
        native_process_authentication=False,runtime_qualification=False)


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    if args.retain:
        outputs=[]
        for stage in STAGES:
            for suffix in ('stdout','stderr','exit'):
                path=LOG/(stage+'.'+suffix);outputs.append(dict(**pin(path),bytes_hex=path.read_bytes().hex()))
        result=verify(outputs);result['raw_captures']=outputs
        with (BASE/'harness-review.json').open('xb') as stream:stream.write(json.dumps(result,sort_keys=True,indent=2).encode()+b'\n')
    else:
        saved=document(BASE/'harness-review.json');result=verify(saved['raw_captures'])
        assert {k:v for k,v in saved.items() if k!='raw_captures'}==result
    print(json.dumps(dict(cases=result['selected_cases'],perl_checks=result['corrected_perl_checks'],reader_countermodels=result['reader_countermodels'],actual_fixture_operations=0,success=True),sort_keys=True))


if __name__=='__main__':main()
