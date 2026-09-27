#!/usr/bin/env python3
"""Verify the failed observation and static reset-oracle correction only."""
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


def load(path):
    return json.loads(path.read_bytes())


def reset_check(source):
    segment = source.split('  run_lap(); run_lap();\n', 1)[1].split('  run_lap();\n', 1)[0]
    # An independent event-order model of the literal mid-run bench sequence.
    # clk rises at 5+10n and falls at 10+10n. Derive both preceding laps
    # from the literal bounded loop and startup waits, rather than using the
    # observed failure time as an input to the oracle.
    assert 'always #5 clk=~clk;' in source
    assert '#2; rst_n=0; repeat(2) @(negedge clk); #1; check_reset(); rst_n=1;\n  repeat(2) @(negedge clk);' in source
    cycles = int(re.search(r'for \(integer cycle=0; cycle<(\d+); cycle=cycle\+1\)', source).group(1))
    time = 40  # startup's two reset-active and two reset-inactive falling edges
    for _ in range(2):
        time = 10 * (time // 10 + 1)  # request edge
        for _ in range(cycles):
            time = 10 * (time // 10 + 1) + 1  # sampled falling edge plus #1
    asserted, applied = False, False
    for token in re.findall(r'@\(negedge clk\)|rst_n=[01]|#1|check_reset\(\)', segment):
        if token in ('@(negedge clk)', '#1'):
            until = 10 * (time // 10 + 1) if token[0] == '@' else time + 1
            applied |= asserted and any(time < edge <= until for edge in range(5, until + 1, 10))
            time = until
        elif token.startswith('rst_n='):
            asserted = token.endswith('0')
        else:
            return time, applied
    raise AssertionError('missing reset check')


def validate(admission, summary, stages, events, extra, postcheck):
    assert admission['capture'] == 'priority_repair_corrected'
    assert admission['mode'] == 'priority' and admission['scenario'] == 'none'
    assert admission['expected_stages'] == {'compile': 3, 'runtime': 3}
    assert summary['stages'] == 2
    assert [r['label'] for r in summary['receipts']] == ['compile_a', 'runtime_b']
    assert summary['input_error'] is None
    assert summary['test_error'] == 'runtime oracle failed; retained result requires diagnosis\n'
    assert summary['capture_gaps'] == summary['retention_errors'] == [] and events == b''
    assert extra['before'] == extra['after']
    assert extra['before']['t/1974-isf-priority-contributor-union.t']['sha256'] == admission['sha256']['t/1974-isf-priority-contributor-union.t']
    build, run = stages['compile_a']['result'], stages['runtime_b']['result']
    assert build['ok'] == 1 and build['exit_code'] == 0 and build['status'] == 'success'
    assert run['ok'] == 0 and run['exit_code'] == 1 and run['status'] == 'nonzero_exit'
    assert '[311] %Fatal: tb.sv:20: Assertion failed in tb.check_reset.unnamedblk1: reset did not clear public outputs\n' in run['stdout']
    assert 'selector same-value conflict' not in run['stdout']
    for stage, result in [('compile', build), ('runtime', run)]:
        assert result['stage'] == stage and result['schema'] == 'fsmgen.test.verilator_runtime_result.v1'
        assert result['exec_failed'] == 0 and result['exec_error'] is None
        assert result['timed_out'] == result['output_limited'] == result['signal'] == 0
        assert result['timeout_seconds'] == (120 if stage == 'compile' else 30)
        assert result['capture_limit_bytes'] == (8_388_608 if stage == 'compile' else 67_108_864)
        assert result['cleanup'] == {'containment': 'test_runtime_process_group', 'group_gone': 1,
            'kill_sent': 0, 'leader_reaped': 1, 'leader_started': 1,
            'surviving_descendants': 0, 'term_sent': 0}
    argv = stages['compile_a']['arguments'][0]
    assert argv[:10] == ['verilator', '--binary', '--timing', '--assert', '-Wno-fatal', '-j', '1', '--top-module', 'tb', '--Mdir']
    assert len(argv[11:]) == 10
    assert stages['runtime_b']['arguments'] == [[argv[10] + '/Vtb']]
    work = str(Path(argv[10]).parent)
    assert postcheck['work'] == work and postcheck['workspace_absent'] is True
    assert postcheck['selected_command_residue'] == []
    assert postcheck['native_pid_absence'].startswith('not independently measured;')


def main():
    manifest = load(HERE / 'manifest.json')
    assert manifest['schema'] == 'fsmgen.priority_reset_oracle_repair.v1'
    assert manifest['remaining_runtime'] == 'two_target_and_negative_execution_pending'
    assert manifest['native_cause'] == 'historical_EPERM_not_attributed'
    assert set(manifest['sha256']) == {str(p.relative_to(HERE)) for p in HERE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    for name, expected in manifest['sha256'].items():
        assert digest((HERE / name).read_bytes()) == expected
    for name, expected in manifest['prerequisites'].items():
        assert digest((ROOT / name).read_bytes()) == expected
    observed = (HERE / 'observed-test.t.source').read_bytes()
    for name, record in manifest['producers'].items():
        data = (ROOT / name).read_bytes() if (ROOT / name).exists() else b''
        if digest(data) != record['sha256']:
            data = observed if digest(observed) == record['sha256'] else subprocess.check_output(['git', 'cat-file', 'blob', record['git_blob']], cwd=ROOT)
        assert digest(data) == record['sha256']
    admission_bytes = (HERE / 'observation/admission.json').read_bytes()
    admission, summary = json.loads(admission_bytes), load(HERE / 'observation/summary.json')
    assert summary['admission_sha256'] == digest(admission_bytes)
    stages = {label: load(HERE / ('observation/' + label + '.json')) for label in ('compile_a', 'runtime_b')}
    for receipt in summary['receipts']:
        assert receipt['path'] == receipt['label'] + '.json'
        assert receipt['sha256'] == digest((HERE / 'observation' / receipt['path']).read_bytes())
    for name, expected in admission['sha256'].items():
        assert manifest['producers'][name]['sha256'] == expected
    extra, postcheck = load(HERE / 'extra-identities.json'), load(HERE / 'postcheck.json')
    assert all(manifest['producers'][name] == record for name, record in extra['before'].items())
    preflight = (HERE / 'preflight-test.t.source').read_bytes()
    corrected = (HERE / 'corrected-test.t.source').read_bytes()
    assert observed == preflight.replace(b'negative control restores only the lost first-state suppressor', b'negative control restores only the original missing-contributor defect')
    assert digest(observed) == admission['sha256']['t/1974-isf-priority-contributor-union.t']
    assert digest(corrected) == manifest['corrected_test']['sha256']
    for name, source, code in [('preflight', preflight, 0), ('observed', observed, 1), ('static', corrected, 0)]:
        record = load(HERE / (name + '-result.json'))
        assert record['exit_code'] == code and record['test_sha256'] == digest(source)
        assert record['log_sha256'] == digest(record['log'].encode())
        assert ('Result: PASS' in record['log']) == (code == 0)
    assert 'Files=2, Tests=7,' in load(HERE / 'static-result.json')['log']
    prior = ROOT / 'docs/audits/same-value-selector-repair-20260928'
    semantic = load(prior / 'semantic.json')['semantic']
    for name in ('explicit_system_contract', 'system_contract'):
        assert semantic[name]['reset_kind'] == 'sync' and semantic[name]['reset_keyword'] == 'sreset'
        assert semantic[name]['reset_active_level'] == 0
    hdl = load(prior / 'hdl.json')['hdl']
    sequential = re.findall(r'always_ff @\(([^)]*)\) begin\n    if \(!rst_n\)', hdl)
    assert len(sequential) == 4 and set(sequential) == {'posedge clk'}
    assert reset_check(observed.decode()) == (311, False)
    assert reset_check(corrected.decode()) == (321, True)
    args = (admission, summary, stages, (HERE / 'observation/events.jsonl').read_bytes(), extra, postcheck)
    validate(*args)
    mutations = []
    bad = copy.deepcopy(stages); bad['runtime_b']['result']['stdout'] = 'unrelated failure'; mutations.append((admission, summary, bad, args[3], extra, postcheck))
    bad = copy.deepcopy(stages); bad['compile_a']['arguments'][0][3] = '--no-assert'; mutations.append((admission, summary, bad, args[3], extra, postcheck))
    bad = copy.deepcopy(stages); bad['runtime_b']['result']['cleanup']['group_gone'] = 0; mutations.append((admission, summary, bad, args[3], extra, postcheck))
    bad = copy.deepcopy(stages); bad['runtime_b']['result']['exec_failed'] = 1; mutations.append((admission, summary, bad, args[3], extra, postcheck))
    bad = copy.deepcopy(extra); bad['after']['t/1974-isf-priority-contributor-union.t']['sha256'] = '0' * 64; mutations.append((admission, summary, stages, args[3], bad, postcheck))
    bad = copy.deepcopy(postcheck); bad['workspace_absent'] = False; mutations.append((admission, summary, stages, args[3], extra, bad))
    bad = copy.deepcopy(summary); bad['stages'] = 6; mutations.append((admission, bad, stages, args[3], extra, postcheck))
    for candidate in mutations:
        try:
            validate(*candidate)
        except AssertionError:
            continue
        raise AssertionError('corrupt reset-oracle evidence accepted')
    print('Failed reset observation, synchronous emitted contract, corrected bench event ordering and static controls verified; corrected runtime remains pending.')


if __name__ == '__main__':
    main()
