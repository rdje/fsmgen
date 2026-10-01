"""Authenticate output-profile preparation without source or HDL promotion."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASE = '05469eb51d62d0e1d1511145b58aaee06ecd5010'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def validate_probe(before, current):
    names = ['local', 'imported', 'alias', 'mixed', 'unused']
    assert [r['case'] for r in before['cases']] == [r['case'] for r in current['cases']] == names
    for old, new in zip(before['cases'], current['cases']):
        assert old['source'] == new['source']
        assert '(output placeholder (width 6))' in new['source']
        assert old['actor']['interface_port_metadata'] == new['actor']['interface_port_metadata']
        port = next(p for p in new['actor']['interface_port_metadata'] if p['name'] == 'packet')
        assert port['direction'] == 'output' and port['width'] == '6'
        expected_type = 'shared.frame' if new['case'] == 'imported' else 'frame'
        assert port['type'] == expected_type and port['type_kind'] == 'record'
        assert port['fields'] == [
            dict(path='tag', width='2', msb='5', lsb='4', signed='0'),
            dict(path='body.data', width='3', msb='3', lsb='1', signed='1', state_model='four_state'),
            dict(path='body.flag', width='1', msb='0', lsb='0', signed='0')]
        assert [t['target'] for t in old['targets']] == [t['target'] for t in new['targets']] == ['verilog', 'v', 'vhdl', 'systemverilog', 'sv']
        for previous, target in zip(old['targets'], new['targets']):
            assert previous['legacy_error'] == target['legacy_error']
            assert previous['profile_error'].startswith('Undefined subroutine &FSM::Support::ISFHDLProfile::assert_record_port_hdl_profile called at ')
            language = 'verilog' if target['target'] == 'v' else target['target']
            actor = 'profile_' + new['case']
            input_reason = f"ISF actor '{actor}' record input 'incoming' (type 'frame') cannot generate target 'verilog': packed record inputs require SystemVerilog; use --language systemverilog. Verilog-2005 record lowering is not implemented.\n"
            if new['case'] == 'mixed' and language == 'verilog':
                assert target['profile_error'] == target['legacy_error'] == input_reason
            elif language in ['systemverilog', 'sv']:
                assert target['profile_error'] == target['legacy_error'] == ''
            else:
                detail = 'Verilog-2005 record lowering is not implemented.' if language == 'verilog' else 'VHDL record-output lowering is not implemented.'
                assert target['legacy_error'] == ''
                assert target['profile_error'] == f"ISF actor '{actor}' record output 'packet' (type '{expected_type}') cannot generate target '{language}': packed record outputs require SystemVerilog; use --language systemverilog. {detail}\n"


def main():
    m = json.loads((HERE / 'manifest.json').read_bytes())
    assert m['baseline_revision'] == BASE
    assert set(m['sha256']) == {p.name for p in HERE.iterdir() if p.is_file() and p.name != 'manifest.json'}
    for name, digest in m['sha256'].items():
        assert sha((HERE / name).read_bytes()) == digest
    for path, item in m['baseline_sources'].items():
        blob = subprocess.check_output(['git', 'rev-parse', BASE + ':' + path], cwd=ROOT).decode().strip()
        assert blob == item['git_blob']
        raw = subprocess.check_output(['git', 'cat-file', 'blob', blob], cwd=ROOT)
        assert sha(raw) == item['sha256'] == sha((HERE / item['snapshot']).read_bytes())
    for dirname, members in m['parent_members'].items():
        parent = ROOT / 'docs/audits' / dirname
        assert set(members) == {p.name for p in parent.iterdir() if p.is_file()}
        for name, digest in members.items():
            assert sha((parent / name).read_bytes()) == digest
    for name, p in m['receipt_projections'].items():
        assert len((HERE / name).read_bytes()) == p['raw_bytes'] - p['replacement_count'] * (p['root_prefix_bytes'] - len(b'<repo>'))
    assert m['terminal_exit_codes'] == dict(unprivileged_guard=2, draft_red=1, valid_red=1,
        focused=0, regression=0, docs=0, book=0, syntax=0, probe=0, baseline_probe=4, parent_verifier=0)
    for name, count in [('focused.txt', 'Files=1, Tests=6'), ('regression.txt', 'Files=7, Tests=198'), ('docs.txt', 'Files=3, Tests=310')]:
        text = (HERE / name).read_text()
        assert count in text and 'All tests successful.' in text and 'Result: PASS' in text
    assert 'HTML book written to' in (HERE / 'book.txt').read_text()
    assert (HERE / 'syntax.txt').read_text().count('syntax OK') == 4
    red = (HERE / 'valid-red.txt').read_text()
    assert 'Undefined subroutine &FSM::Support::ISFHDLProfile::assert_record_port_hdl_profile' in red and 'Result: FAIL' in red
    assert 'resolved prototypes preserve independently literal layout' not in red
    before = (HERE / 'baseline-profile.pm.source').read_text()
    after = (HERE / 'profile.pm.source').read_text()
    assert before[before.index('sub assert_record_input_hdl_profile {'):before.index('\n1;')] == after[after.index('sub assert_record_input_hdl_profile {'):after.index('\n# Keep the legacy')]
    for name in ['cli.source', 'facade.pm.source']:
        assert (HERE / name).read_text() == (HERE / ('baseline-' + name)).read_text().replace('FSM::Support::ISFHDLProfile::assert_record_input_hdl_profile(', 'FSM::Support::ISFHDLProfile::assert_record_port_hdl_profile(')
    assert set((HERE / 'production-paths.txt').read_text().splitlines()) == set(m['baseline_sources'])
    for path, item in m['unchanged_sources'].items():
        raw = subprocess.check_output(['git', 'show', BASE + ':' + path], cwd=ROOT)
        assert sha(raw) == item['baseline_sha256'] == item['captured_current_sha256']
    old = json.loads((HERE / 'baseline-probe.json').read_bytes())
    current = json.loads((HERE / 'probe.json').read_bytes())
    validate_probe(old, current)
    mutations = [lambda p: p['cases'][0]['targets'][0].update(profile_error=''),
                 lambda p: p['cases'][1]['targets'][2].update(profile_error='unrelated failure'),
                 lambda p: p['cases'][3]['targets'][0].update(profile_error=p['cases'][0]['targets'][0]['profile_error']),
                 lambda p: p['cases'][0]['actor']['interface_port_metadata'][-1].update(width='5')]
    for mutate in mutations:
        bad = copy.deepcopy(current)
        mutate(bad)
        try:
            validate_probe(old, bad)
        except AssertionError:
            continue
        raise AssertionError('Hostile success, cause, input-priority or declared-width substitution accepted')
    print('Exact old/new resolved output profile and metadata decisions authenticate unsupported output reasons, legacy input bytes and input priority. Parser/lowering and prior sealed evidence are unchanged; full regression/docs/book receipts authenticate. Hostile success, cause, priority and width substitutions reject. No output source or HDL promotion.')


if __name__ == '__main__':
    main()
