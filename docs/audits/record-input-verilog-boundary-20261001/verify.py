"""Authenticate saved source/profile evidence; never invoke an HDL tool."""
import hashlib,json,subprocess
from pathlib import Path
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
BASE='f3c4436d6466c699f93ac962a6199a90f6422092'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def reject(fn):
    try:fn()
    except AssertionError:return
    raise AssertionError('hostile boundary was accepted')
def validate_guard(text):
    assert 'snapshot_interface_port_metadata($args{interface_ports})' in text
    assert r'/\A(?:verilog|v)\z/' in text
    assert "$port->{direction} eq 'input'" in text
    assert "($port->{type_kind} // '') eq 'record'" in text
    assert 'use --language systemverilog.' in text
    assert 'die ' in text and 'confess' not in text
    assert 'Verilog-2005 record lowering is not implemented.\\n' in text

def main():
    m=json.loads((HERE/'manifest.json').read_bytes())
    assert m['schema']=='fsmgen.record_input_verilog_boundary.v1' and m['baseline_revision']==BASE
    assert {p.name for p in HERE.iterdir() if p.is_file() and p.name!='manifest.json'}==set(m['sha256'])
    for name,digest in m['sha256'].items():assert sha((HERE/name).read_bytes())==digest
    for path,digest in m['prerequisites'].items():assert sha((ROOT/path).read_bytes())==digest
    for p,d in m['producers'].items():
        assert sha((HERE/d['snapshot']).read_bytes())==d['sha256']
        if 'baseline_git_blob' in d:
            blob=subprocess.check_output(['git','rev-parse',BASE+':'+p],cwd=ROOT).decode().strip()
            assert blob==d['baseline_git_blob']
            assert sha(subprocess.check_output(['git','cat-file','blob',blob],cwd=ROOT))==d['baseline_sha256']
    for name,d in m['receipts'].items():
        raw=(HERE/name).read_bytes()
        assert sha(raw)==d['projected_sha256']
        assert len(raw)==d['raw_bytes']+d['exact_root_replacements']*(len(b'{REPOSITORY_ROOT}')-d['root_prefix_bytes'])
    guard=(HERE/'producer-2.source').read_text();validate_guard(guard)
    reject(lambda:validate_guard(guard.replace('(?:verilog|v)','(?:systemverilog|sv)')))
    reject(lambda:validate_guard(guard.replace("eq 'input'","eq 'output'")))
    reject(lambda:validate_guard(guard.replace('snapshot_interface_port_metadata','unvalidated_ports')))
    cli=(HERE/'producer-0.source').read_text();facade=(HERE/'producer-1.source').read_text()
    assert cli.index("if ($emit_schedule_json)")<cli.index('assert_record_input_hdl_profile(')<cli.index('my $result = eval { $scheduler->lower($actor); };')
    block=cli[cli.index('assert_record_input_hdl_profile('):cli.index('my $result = eval { $scheduler->lower($actor); };')]
    assert 'emit_machine_failure_if_requested(' in block and 'exit 1;' in block
    assert facade.index('assert_record_input_hdl_profile(')<facade.index('my $lowered = $scheduler->lower($actor);')
    test=(HERE/'producer-5.source').read_text()
    for required in ['imported_record_profile','unused_record_profile','packed_input_runtime','packed_input_generated_domains','packed_input_generated_blocking','link_rx','--check --json'.replace(' ',' '),"['semantic', '--emit-semantic-json']","'EXISTING DESTINATION"]:
        # CLI flags are authored as a qw list, not a command string.
        if required=='--check --json':assert 'qw(--check --json)' in test
        elif required=="'EXISTING DESTINATION":assert 'EXISTING DESTINATION' in test
        else:assert required in test
    for fragment in ['exit_code=>0','signal=>9',"stderr=>''",'unrelated failure',"normalize_date(read_file($output))",'sha256_hex(read_file($_))']:
        assert fragment in test
    for i in [3,4]:
        text=(HERE/f'producer-{i}.source').read_text()
        assert text.count('qw(systemverilog)')==2 and 'qw(systemverilog verilog)' not in text
        assert 'explicit' in text and 'plan skip_all' in text
    before=(HERE/'before.txt').read_text();draft=(HERE/'draft-status.txt').read_text()
    assert 'Failed 5/8 subtests' in before and 'Result: FAIL' in before
    assert 'Failed 7/10 subtests' in draft and 'Result: FAIL' in draft
    probe=json.loads((HERE/'draft-status.json').read_bytes())
    assert type(probe['exit_code']) is int and probe['exit_code']==255 and probe['signal']==0
    assert probe['first_line'].startswith("ISF actor 'packed_input_runtime' record input 'packet' (type 'frame')")
    for name,summary in [('intermediate-focused.txt','Files=1, Tests=10'),('final-focused.txt','Files=1, Tests=10'),('regression.txt','Files=7, Tests=7328'),('docs.txt','Files=3, Tests=310')]:
        raw=(HERE/name).read_text();assert summary in raw and 'All tests successful.' in raw and 'Result: PASS' in raw
    assert 'HTML book written to' in (HERE/'book.txt').read_text()
    for name in ['direct-saved.txt','generated-saved.txt']:
        assert 'verified with exact sources, original bounds/results and cleanup' in (HERE/name).read_text()
    print('Saved RED/draft-status and final contextual profile checks authenticate, including imported/unused declarations, destination atomicity, machine/facade reports, full SystemVerilog predecessor products and supported controls. Broader regression and original runtime archives remain valid at their declared revision boundaries; hostile target/direction/validation controls reject. No HDL execution or spent capture replay.')
if __name__=='__main__':main()
