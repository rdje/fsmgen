#!/usr/bin/env python3
"""Verify the contributor repair and its retained, unresolved runtime blocker."""
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read(name):
    return json.loads((HERE / name).read_bytes())


def validate(red, focused, runtime, summary, stages, check, semantic, hdl, postcheck):
    assert red['exit_code'] == 1 and focused['exit_code'] == 0 and runtime['exit_code'] == 1
    assert 'Failed 1/2 subtests' in red['log'] and 'ok 2 - complete native, API, newline' in red['log']
    failures = re.findall(r'^    not ok [0-9]+ - (.+)$', red['log'], re.M)
    assert failures == [f'{case} {label}' for case in ('multi', 'reversed', 'rule_first', 'named', 'equal_states', 'resource')
        for label in ('retains the independently declared contributor union', 'actual emitted fallback has the full predicate')]
    assert 'All tests successful.' in focused['log'] and 'Files=5, Tests=29,' in focused['log']
    assert 'ok 3 # skip qualified Verilator runtime unavailable' in focused['log']
    assert '1..89' in focused['log'] and '1..171' in focused['log']
    assert 'systemverilog independent priority/progress/reset oracle passes' in runtime['log']
    assert 'not ok 3 - both HDL targets' in runtime['log'] and 'Result: FAIL' in runtime['log']
    assert summary['stages'] == 2 and [r['label'] for r in summary['receipts']] == ['compile_a', 'runtime_b']
    assert summary['input_error'] is None and summary['capture_gaps'] == summary['retention_errors'] == []
    assert summary['test_error'] == 'runtime oracle failed; retained result requires diagnosis\n'
    for label, timeout, cap in (('compile_a', 120, 8_388_608), ('runtime_b', 30, 67_108_864)):
        result = stages[label]['result']
        assert result['timeout_seconds'] == timeout and result['capture_limit_bytes'] == cap
        assert result['timed_out'] == result['output_limited'] == result['exec_failed'] == result['signal'] == 0
        assert result['exec_error'] is None
        cleanup = result['cleanup']
        assert cleanup['leader_started'] == cleanup['leader_reaped'] == cleanup['group_gone'] == 1
        assert cleanup['surviving_descendants'] == cleanup['kill_sent'] == cleanup['term_sent'] == 0
        assert result['stage'] == label.split('_')[0]
    compile_result, run_result = stages['compile_a']['result'], stages['runtime_b']['result']
    assert compile_result['ok'] == 1 and compile_result['exit_code'] == 0
    assert run_result['ok'] == 0 and run_result['exit_code'] == 1 and run_result['status'] == 'nonzero_exit'
    assert run_result['stderr'] == ''
    assert '[55] %Error: priority_compatible_systemverilog.sv:230: Assertion failed in tb.dut_4: selector same-value conflict: out 9' in run_result['stdout']
    assert 'PRIORITY_CONTRIBUTOR_UNION_PASS' not in run_result['stdout']
    args = stages['compile_a']['arguments'][0]
    assert args[0:5] == ['verilator', '--binary', '--timing', '--assert', '-Wno-fatal']
    assert args.count('--Mdir') == 1
    work = str(Path(args[args.index('--Mdir') + 1]).parent)
    assert stages['runtime_b']['arguments'] == [[work + '/obj_systemverilog/Vtb']]
    assert postcheck['work'] == work and postcheck['workspace_absent'] is True
    assert postcheck['selected_command_residue'] == []
    assert postcheck['native_pid_absence'].startswith('not independently measured;')
    assert check['success'] is True and check['diagnostics'] == []
    target, = [t for t in semantic['semantic']['forward_ir']['lowered_rtl_ir']['selector_conflict_targets'] if t['signal_name'] == 'out']
    family, = [f for f in target['rhs_enable_families'] if f['rhs_value'] == '9']
    assert family['driver_enable_signals'] == ['fallback_out__9_en', 'main_set_1_out__9_en']
    assert family['same_value_assertion'] == {'input_count': 2, 'input_enable_signals': family['driver_enable_signals'],
        'kind': 'onehot0', 'rhs_value': '9', 'target_signal': 'out'}
    for line in (
        'assign main_set_1_en = current_state == MAIN_SET_1;',
        'assign fallback_en = override_req;',
        'assign fallback_out__9_en = fallback_en & not_current_state_eq_const_MAIN_SET_2;',
        'assign main_set_1_out__9_en = main_set_1_en;',
        'assign out__9_en = fallback_out__9_en | main_set_1_out__9_en;',
        'assert ($onehot0({fallback_out__9_en, main_set_1_out__9_en})) else $error("selector same-value conflict: out 9");',
    ):
        assert line in hdl
    # Independent Boolean witness: distinct state constants and the literal
    # emitted equations permit both sources while their OR still selects 9.
    state_codes = {name: int(code) for name, code in re.findall(r"localparam (MAIN_SET_[12]) = 3'd([0-9]+);", hdl)}
    assert len(set(state_codes.values())) == 2
    current_state, override_req = state_codes['MAIN_SET_1'], True
    first_writer = current_state == state_codes['MAIN_SET_1']
    fallback_writer = override_req and current_state != state_codes['MAIN_SET_2']
    assert first_writer and fallback_writer and (first_writer or fallback_writer)


def main():
    manifest = read('manifest.json')
    assert manifest['schema'] == 'fsmgen.priority_contributor_repair_blocker.v1'
    assert manifest['runtime_qualification'] == 'incomplete_same_value_assertion_failure'
    assert manifest['historical_native_cause'] == 'unresolved'
    assert set(manifest['sha256']) == {str(p.relative_to(HERE)) for p in HERE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    for name, expected in manifest['sha256'].items():
        assert digest((HERE / name).read_bytes()) == expected
    sources = {}
    for path, record in manifest['producers'].items():
        data = (ROOT / path).read_bytes() if (ROOT / path).exists() else b''
        if digest(data) != record['sha256']:
            data = subprocess.check_output(['git', 'cat-file', 'blob', record['git_blob']], cwd=ROOT)
        assert digest(data) == record['sha256']
        sources[path] = data
    red, focused, runtime = (read(n + '-result.json') for n in ('red', 'focused', 'first-runtime'))
    for result in (red, focused, runtime):
        assert digest(result['log'].encode()) == result['log_sha256']
    assert digest((HERE / 'red-test.t.source').read_bytes()) == red['test_sha256']
    old = subprocess.check_output(['git', 'show', red['baseline_revision'] + ':perl/FSM/Scheduler/ISF/LoweringIR.pm'], cwd=ROOT)
    assert digest(old) == red['lowering_sha256']
    assert b'$lower->{suppressed_by}{$higher_owner} = _priority_record_condition($higher);' in old
    fixed = sources['perl/FSM/Scheduler/ISF/LoweringIR.pm']
    assert b'$lower->{suppressed_by}{$higher_owner}{_priority_record_condition($higher)} = 1;' in fixed
    assert b'_expr_or(sort keys %{$suppressed_by->{$_}})' in fixed
    assert sources['t/1974-isf-priority-contributor-union.t'] == (HERE / 'observed-test.t.source').read_bytes()
    observation = HERE / 'first-observation'
    admission = read('first-observation/admission.json')
    summary = read('first-observation/summary.json')
    assert admission['target'] == 't/1974-isf-priority-contributor-union.t' and admission['mode'] == 'priority'
    assert admission['expected_stages'] == {'compile': 2, 'runtime': 2}
    assert summary['admission_sha256'] == digest((observation / 'admission.json').read_bytes())
    assert (observation / 'events.jsonl').read_bytes() == b''
    for path, expected in admission['sha256'].items():
        assert manifest['producers'][path]['sha256'] == expected
    stages = {}
    for receipt in summary['receipts']:
        assert receipt['path'] == receipt['label'] + '.json'
        assert digest((observation / receipt['path']).read_bytes()) == receipt['sha256']
        stages[receipt['label']] = read('first-observation/' + receipt['path'])
    check = read('assertion-rootcause/check.json')
    semantic = read('assertion-rootcause/semantic.json')
    hdl_record = read('assertion-rootcause/priority_compatible.sv.json')
    hdl = hdl_record['hdl']
    assert digest(hdl.encode()) == hdl_record['sha256']
    postcheck = read('postcheck.json')
    args = [red, focused, runtime, summary, stages, check, semantic, hdl, postcheck]
    validate(*args)
    mutations = []
    for index, mutation in (
        (0, lambda r: r.update(exit_code=0)),
        (3, lambda r: r.update(stages=4)),
        (4, lambda r: r['runtime_b']['result'].update(exec_failed=1)),
        (4, lambda r: r['runtime_b']['result'].update(ok=1)),
        (4, lambda r: r['compile_a']['result'].update(timeout_seconds=121)),
        (5, lambda r: r.update(success=False)),
        (8, lambda r: r.update(workspace_absent=False)),
    ):
        changed = copy.deepcopy(args)
        mutation(changed[index])
        mutations.append(changed)
    for changed in mutations:
        try:
            validate(*changed)
        except AssertionError:
            continue
        raise AssertionError('corrupt repair/blocker evidence accepted')
    print('Contributor red/green evidence, incomplete real runtime, same-value assertion mechanism and cleanup verified; repair signoff remains open.')


if __name__ == '__main__':
    main()
