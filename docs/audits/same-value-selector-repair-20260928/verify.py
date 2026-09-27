#!/usr/bin/env python3
"""Verify the static selector policy repair without claiming runtime closure."""
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
PRIOR = HERE.parent / 'priority-contributor-repair-20260928'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def load(path):
    return json.loads(path.read_bytes())


def banner_free(hdl):
    rows = hdl.splitlines(keepends=True)
    assert sum(line.startswith('// Date: ') for line in rows) == 1
    return ''.join(line for line in rows if not line.startswith('// Date: '))


def validate(old_semantic, new_semantic, old_hdl, new_hdl):
    expected = copy.deepcopy(old_semantic)
    for target in expected['forward_ir']['lowered_rtl_ir']['selector_conflict_targets']:
        for family in target['rhs_enable_families']:
            assert family['same_value_assertion']['kind'] == 'onehot0'
            family['same_value_assertion']['kind'] = 'compatible_fanin'
    assert new_semantic == expected
    removed = '    assert ($onehot0({fallback_out__9_en, main_set_1_out__9_en})) else $error("selector same-value conflict: out 9");\n'
    assert old_hdl.count(removed) == 1
    assert banner_free(new_hdl) == banner_free(old_hdl.replace(removed, ''))
    assert 'assign out__9_en = fallback_out__9_en | main_set_1_out__9_en;' in new_hdl
    assert 'assert ($onehot0({out__3_en, out__9_en})) else $error("selector multi-value conflict: out");' in new_hdl


def main():
    manifest = load(HERE / 'manifest.json')
    assert manifest['schema'] == 'fsmgen.same_value_selector_static_repair.v1'
    assert manifest['corrected_runtime'] == 'pending_separately_owned_observation'
    assert manifest['prior_evidence_sha256'] == digest((PRIOR / 'manifest.json').read_bytes())
    assert set(manifest['sha256']) == {str(p.relative_to(HERE)) for p in HERE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    for name, expected in manifest['sha256'].items():
        assert digest((HERE / name).read_bytes()) == expected
    for path, record in manifest['producers'].items():
        data = (ROOT / path).read_bytes() if (ROOT / path).exists() else b''
        if digest(data) != record['sha256']:
            data = subprocess.check_output(['git', 'cat-file', 'blob', record['git_blob']], cwd=ROOT)
        assert digest(data) == record['sha256']
    red = load(HERE / 'red-result.json')
    focused = load(HERE / 'focused-result.json')
    public = load(HERE / 'public-contract-result.json')
    for row in (red, focused, public):
        assert digest(row['log'].encode()) == row['log_sha256']
    assert red['exit_code'] == 1 and focused['exit_code'] == public['exit_code'] == 0
    assert digest((HERE / 'red-test.t.source').read_bytes()) == red['test_sha256']
    assert re.findall(r'^    not ok [0-9]+ - (.+)$', red['log'], re.M) == [
        'legacy metadata key explicitly identifies compatible source fan-in',
        'SystemVerilog does not forbid admitted same-value source overlap']
    assert 'Files=4, Tests=9,' in focused['log'] and 'All tests successful.' in focused['log']
    assert 'an explicitly declared exclusive-source policy still emits its check' in focused['log']
    assert 'Files=3, Tests=16,' in public['log'] and 'All tests successful.' in public['log']
    assert 'ok 3 # skip qualified Verilator runtime unavailable' in public['log']
    old_semantic = load(PRIOR / 'assertion-rootcause/semantic.json')['semantic']
    new_semantic = load(HERE / 'semantic.json')['semantic']
    old_record, new_record = load(PRIOR / 'assertion-rootcause/priority_compatible.sv.json'), load(HERE / 'hdl.json')
    assert digest(new_record['hdl'].encode()) == new_record['sha256']
    old_hdl, new_hdl = old_record['hdl'], new_record['hdl']
    validate(old_semantic, new_semantic, old_hdl, new_hdl)
    bad_semantic = copy.deepcopy(new_semantic)
    bad_semantic['forward_ir']['lowered_rtl_ir']['selector_conflict_targets'][0]['multi_value_assertion']['kind'] = 'compatible_fanin'
    mutation_args = [
        (old_semantic, old_semantic, old_hdl, new_hdl),
        (old_semantic, bad_semantic, old_hdl, new_hdl),
        (old_semantic, new_semantic, old_hdl, old_hdl),
        (old_semantic, new_semantic, old_hdl, new_hdl.replace('selector multi-value conflict: out', 'hidden conflict')),
        (old_semantic, new_semantic, old_hdl, new_hdl.replace('fallback_out__9_en | main_set_1_out__9_en', 'fallback_out__9_en')),
    ]
    for args in mutation_args:
        try:
            validate(*args)
        except AssertionError:
            continue
        raise AssertionError('corrupt selector-policy repair accepted')
    print('Compatible selector policy, unchanged semantic structure/data HDL, retained different-value checks and static contracts verified; corrected runtime is not part of this slice.')


if __name__ == '__main__':
    main()
