"""Authenticate the emitter-aligned import-token repair without HDL execution."""
import hashlib,json,subprocess
from pathlib import Path
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2]
BASE='eaed5ba1738935556f8ebff5ee1972e03181fd50'
def sha(b):return hashlib.sha256(b).hexdigest()
def main():
    m=json.loads((HERE/'manifest.json').read_bytes());assert m['baseline_revision']==BASE
    assert set(m['sha256'])=={p.name for p in HERE.iterdir() if p.is_file() and p.name!='manifest.json'}
    for p,d in m['sha256'].items():assert sha((HERE/p).read_bytes())==d
    for p,d in m['baseline_sources'].items():
        blob=subprocess.check_output(['git','rev-parse',BASE+':'+p],cwd=ROOT).decode().strip();assert blob==d['git_blob']
        assert sha(subprocess.check_output(['git','cat-file','blob',blob],cwd=ROOT))==d['sha256']
    code=(HERE/'collector.pm.source').read_text()
    old=subprocess.check_output(['git','show',BASE+':perl/FSM/Scheduler/ISF/PhysicalWriteDeclarations.pm'],cwd=ROOT).decode()
    before="""        confess "Physical write declaration '$name' has an invalid width token\\n"
            unless defined($token) && !ref($token)
                && ($token =~ /\\A[1-9][0-9]*\\z/ || _identifier($token));"""
    after="""        # The emitter preserves actor-local and package-qualified type aliases.
        # Signal/module names remain bare identifiers; only the type token may
        # carry the single package qualifier accepted by the source resolver.
        confess "Physical write declaration '$name' has an invalid width token\\n"
            unless defined($token) && !ref($token)
                && ($token =~ /\\A[1-9][0-9]*\\z/ || _identifier($token)
                    || $token =~ /\\A[A-Za-z_]\\w*\\.[A-Za-z_]\\w*\\z/);"""
    assert old.count(before)==1 and code==old.replace(before,after)
    valid=(HERE/'before-valid.txt').read_text()
    assert 'Result: FAIL' in valid and "invalid width token" in valid
    assert 'incompatible width' not in valid and 'strictly replays\'' not in valid
    draft=(HERE/'draft-before.txt').read_text();assert 'incompatible width 3 for LHS width 5' in draft
    source=(HERE/'test.t.source').read_text();original_draft=(HERE/'draft-test.t.source').read_text()
    assert source==original_draft.replace('(ports (output result (width 5)))','(ports (output result (width 3)))').replace('(output seen (width 5) $owned)','(output seen (width 3) $owned)')
    for name in ['direct','local_alias','generated','domain','generated_domain']:
        assert "['"+name+"'," in source
    for marker in ['shared.word','held.tag','[3,4,2]','shared..frame','shared.frame.extra','complete parsed caller JSON is unchanged','actual carrier reports success']:
        assert marker in source
    for name,count in [('focused.txt','Files=1, Tests=7'),('regression.txt','Files=3, Tests=11'),('docs.txt','Files=3, Tests=310')]:
        text=(HERE/name).read_text();assert count in text and 'All tests successful.' in text and 'Result: PASS' in text
    assert 'HTML book written to' in (HERE/'book.txt').read_text()
    assert (HERE/'baseline-production.txt').read_text().strip()=='perl/FSM/Scheduler/ISF/PhysicalWriteDeclarations.pm'
    print('Valid imported type-token RED and repaired direct/generated/domain/scalar controls authenticate with emitted token parity, strict carrier replay, caller JSON/ranges and malformed-token refusals. The unrelated draft width error is preserved and corrected explicitly. Exact collector replacement leaves signal/module identities and all other production code unchanged; regression/docs/book pass. No output admission or HDL execution.')
if __name__=='__main__':main()
