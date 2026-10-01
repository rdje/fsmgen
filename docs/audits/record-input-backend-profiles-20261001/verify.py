"""Authenticate bounded backend-profile evidence without replaying HDL."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SOURCES = [
    't/data/isf_record_input_runtime.isf',
    't/data/isf_record_input_generated_domains_runtime.isf',
    't/data/isf_record_input_generated_blocking_runtime.isf',
    'docs/audits/specforge-aggregate-intake-20260930/record-port.isf',
    'docs/audits/specforge-aggregate-intake-20260930/record-port-field-guard.isf',
    'docs/audits/specforge-aggregate-intake-20260930/baseline-good.isf',
    't/corpus/direct_aggregate_constant_target_autogrowth.fsm',
]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def primary(error):
    lines = error.splitlines()
    if lines and lines[0].startswith('Source file: '):
        lines.pop(0)
    return lines[0] if lines else ''


def profiles(rows):
    assert [row['source'] for row in rows] == SOURCES
    for index, row in enumerate(rows):
        native = row['native']
        assert native['signal'] == 0
        if index < 5:
            assert native['exit_code'] == 1 and row['destination_unchanged'] is True
            assert row['api_result_defined'] is False and row['api_hdl'] is None
            for error in (native['stderr'], row['api_error']):
                message = primary(error)
                if index == 0:
                    assert message.startswith('Error generating HDL: [VHDL.pm][direct scaffold] ')
                    assert "unsupported packed struct member 'logic signed [4:0] data; struct packed { bit item_0; '" in message
                elif index in (1, 2):
                    top = 'packed_input_generated_domains_top' if index == 1 else 'packed_input_generated_blocking_top'
                    assert message.startswith("Composition source '?top:" + top + "' ")
                    assert "Target language 'vhdl' is not implemented for this composition shape yet: generated-child composition VHDL is outside" in message
                    assert message.endswith('See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.')
                else:
                    assert message.startswith('Error generating HDL: [VHDL.pm][direct scaffold] ')
                    assert re.search(r"unsupported generated port declaration 'input fsmgen_m[1-9][0-9]*_link_rx_lmp_t_fsmgen_t lmp_in'", message)
            assert not re.search(r'\b(entity|architecture|module|typedef)\b', native['stdout'])
        else:
            assert native['exit_code'] == 0 and native['stderr'] == ''
            assert row['api_result_defined'] is True and row['api_error'] is None
            assert row['destination_unchanged'] is False
            text = row['api_hdl']
            if index == 5:
                assert 'entity link_rx is' in text
                assert 'subtype_in : in std_logic_vector(3 downto 0)' in text
            else:
                assert 'entity direct_aggregate_constant_target_autogrowth is' in text
                assert 'OUT_FRAME : out std_logic_vector(4 downto 0)' in text
                assert 'OUT_LANES <= "10101";' in text


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert manifest['schema'] == 'fsmgen.record_input_backend_profiles.v1'
    assert manifest['baseline_revision'] == 'b76058bbfaa8f0d476b6beebd892d5559dbc3f2f'
    files = {str(path.relative_to(HERE)) for path in HERE.rglob('*')
             if path.is_file() and path.name != 'manifest.json'}
    assert files == set(manifest['sha256'])
    for name, expected in manifest['sha256'].items():
        assert digest((HERE / name).read_bytes()) == expected
    for name, identity in manifest['producers'].items():
        blob = subprocess.check_output(['git', 'rev-parse', manifest['baseline_revision'] + ':' + name], cwd=ROOT).decode().strip()
        assert blob == identity['git_blob']
        assert digest(subprocess.check_output(['git', 'cat-file', 'blob', blob], cwd=ROOT)) == identity['sha256']
    rows = json.loads((HERE / 'census.json').read_bytes())
    profiles(rows)
    for field, value in (('exit_code', 0), ('signal', 9)):
        bad = copy.deepcopy(rows)
        bad[0]['native'][field] = value
        rejected(bad)
    for index in range(5):
        bad = copy.deepcopy(rows)
        bad[index]['native']['stderr'] = 'Error generating HDL: unrelated failure\n\t' + primary(rows[index]['native']['stderr'])
        rejected(bad)
        bad = copy.deepcopy(rows)
        bad[index]['api_result_defined'] = True
        rejected(bad)
        bad = copy.deepcopy(rows)
        bad[index]['destination_unchanged'] = False
        rejected(bad)
    for index, token in ((5, '3 downto 0'), (6, '4 downto 0')):
        bad = copy.deepcopy(rows)
        bad[index]['api_hdl'] = bad[index]['api_hdl'].replace(token, '2 downto 0')
        rejected(bad)
    receipt = (HERE / 'regression.txt').read_text()
    assert 'All tests successful.' in receipt and 'Result: PASS' in receipt and 'Result: FAIL' not in receipt
    for test in ('2027-isf-record-input-backend-profiles', '1420-vhdl-direct-backend-scaffold',
                 '386-hdl-generator-facade-target-language-boundary-audit', '114-composition-target-support-diagnostics'):
        assert re.search(r't/' + re.escape(test) + r'\.t\s+\.+ ok', receipt)
    assert digest((HERE / 'test.t.source').read_bytes()) == manifest['test_source_sha256']
    print('Exact record-input backend refusals, destination preservation and supported VHDL controls authenticated; hostile false-success, stack-only diagnostic, partial-product, destination and width substitutions reject. Published backend regression passes. No HDL/analyzer/runtime replay or wider-profile claim.')


def rejected(rows):
    try:
        profiles(rows)
    except AssertionError:
        return
    raise AssertionError('hostile backend-profile evidence accepted')


if __name__ == '__main__':
    main()
