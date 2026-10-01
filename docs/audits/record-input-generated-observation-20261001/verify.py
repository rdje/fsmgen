#!/usr/bin/env python3
"""Authenticate only the reached first-compile rejection; never execute HDL."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
TARGET = 't/2025-isf-record-input-generated-runtime.t'
CAPTURE = 'generated_input_oct01'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def load(name):
    return json.loads((HERE / name).read_bytes())


def validate(admission, summary, stage, events, before, after, postcheck):
    assert set(admission) == {'schema', 'capture', 'mode', 'scenario', 'target', 'expected_stages', 'sha256'}
    assert admission['schema'] == 'fsmgen.fixed_generated_input_observer_admission.v1'
    assert admission['capture'] == CAPTURE and admission['target'] == TARGET
    assert admission['mode'] == 'generated_input' and admission['scenario'] == 'none'
    assert admission['expected_stages'] == {'compile': 5, 'runtime': 5}
    assert all(type(v) is int for v in admission['expected_stages'].values())
    assert summary['schema'] == 'fsmgen.priority_stage_observation.v1'
    assert summary['stages'] == 1
    assert [row['label'] for row in summary['receipts']] == ['compile_a']
    assert summary['test_error'] == 'generated native compile failed; diagnose retained evidence\n'
    assert summary['input_error'] is None
    assert summary['capture_gaps'] == summary['retention_errors'] == [] and events == b''
    assert before == after
    assert {name: before[name]['sha256'] for name in admission['sha256']} == admission['sha256']
    result = stage['result']
    assert result['schema'] == 'fsmgen.test.verilator_runtime_result.v1'
    assert result['schema_version'] == 1 and result['stage'] == 'compile'
    assert result['status'] == 'nonzero_exit' and result['exit_code'] == 1 and result['ok'] == 0
    assert result['exec_failed'] == result['timed_out'] == result['output_limited'] == result['signal'] == 0
    assert result['exec_error'] is None and result['stdout'] == ''
    assert result['timeout_seconds'] == 120 and result['capture_limit_bytes'] == 8_388_608
    assert result['cleanup'] == {'containment': 'test_runtime_process_group', 'group_gone': 1,
        'kill_sent': 0, 'leader_reaped': 1, 'leader_started': 1, 'surviving_descendants': 0, 'term_sent': 0}
    stderr = result['stderr']
    assert "Net 'comp_link_io__writer_isf_write_held_data' data type must be 4-state integral" in stderr
    assert 'Location of failing data type' in stderr and "'bit'" in stderr
    assert ':1674:73:' in stderr and ':1636:13:' in stderr
    assert 'GENERATED_INPUT_RUNTIME_PASS' not in stderr
    argv, = stage['arguments']
    assert argv[:10] == ['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
                        '-j', '1', '--top-module', 'tb', '--Mdir']
    assert len(argv) == 13
    work = str(Path(argv[10]).parent)
    assert work.startswith('.artifacts/tmp/tests/') and '..' not in Path(work).parts
    assert argv[10:] == [work + '/obj_domains_systemverilog', work + '/domains_systemverilog.sv', work + '/domains_tb.sv']
    assert postcheck['workspaces'] == [work] and postcheck['workspace_absent'] == {work: True}
    assert postcheck['selected_command_residue'] == []
    assert postcheck['native_pid_absence'].startswith('not independently measured;')


def main():
    manifest = load('manifest.json')
    assert manifest['schema'] == 'fsmgen.generated_record_input_first_compile_failure.v1'
    paths = {str(p.relative_to(HERE)) for p in HERE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    assert set(manifest['sha256']) == paths
    for name, expected in manifest['sha256'].items():
        assert digest((HERE / name).read_bytes()) == expected, name
    for name, record in manifest['producers'].items():
        raw = subprocess.check_output(['git', 'cat-file', 'blob', record['git_blob']], cwd=ROOT)
        assert digest(raw) == record['sha256'], name
    for name, expected in manifest['prerequisites'].items():
        assert digest((ROOT / name).read_bytes()) == expected, name
    before = load('before.json')['producers']
    after = load('after.json')['producers']
    assert before == manifest['producers']
    assert load('before.json')['baseline_revision'] == manifest['baseline_revision']
    admission = load('observation/admission.json')
    summary = load('observation/summary.json')
    assert summary['admission_sha256'] == digest((HERE / 'observation/admission.json').read_bytes())
    row, = summary['receipts']
    assert row['path'] == 'compile_a.json' and row['stage'] == 'compile'
    assert row['sha256'] == digest((HERE / 'observation/compile_a.json').read_bytes())
    stages = {p.name for p in (HERE / 'observation').glob('*_*.json')}
    assert stages == {'compile_a.json'}
    result = load('observed-result.json')
    stdout, stderr = (HERE / 'prove-stdout.txt').read_bytes(), (HERE / 'prove-stderr.txt').read_bytes()
    assert result['exit_code'] == 1
    assert result['command'] == ['prove', '-v', 'docs/audits/generated-input-observer-20261001/observe.t', '::', CAPTURE]
    assert result['stdout_sha256'] == digest(stdout)
    assert result['archived_stderr_sha256'] == digest(stderr)
    assert result['archive_path_projection'] == manifest['normalization']
    assert b'Files=1, Tests=3,' in stdout and b'Result: FAIL' in stdout
    assert b'not ok 1 - domains_systemverilog fixed generated bench builds' in stdout
    assert b'All tests successful' not in stdout and b'# skip' not in stdout
    assert b'GENERATED_INPUT_RUNTIME_PASS' not in stdout + stderr
    assert b'original test failed: generated native compile failed' in stderr
    for saved, original in [('observed-test.t.source', TARGET),
        ('observed-domains.isf.source', 't/data/isf_record_input_generated_domains_runtime.isf'),
        ('observed-blocking.isf.source', 't/data/isf_record_input_generated_blocking_runtime.isf'),
        ('observed-bench.sv.source', 't/data/isf_record_input_generated_runtime_tb.sv')]:
        assert digest((HERE / saved).read_bytes()) == before[original]['sha256']
    emitted = (HERE / 're-emitted-domains-systemverilog.sv.source').read_text().splitlines()
    assert emitted[1635].strip() == 'bit item_0;'
    assert emitted[1636].strip() == 'bit [1:0] item_1;'
    assert emitted[1673].strip() == 'wire fsmgen_m34_packed_input_generated_domains_top__frame__fsmgen_t comp_link_io__writer_isf_write_held_data;'
    backend = subprocess.check_output(['git', 'cat-file', 'blob', before['perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm']['git_blob']], cwd=ROOT)
    assert b'sprintf("    wire %s %s;", $typedef_name, $net->{name})' in backend
    assert load('diagnosis.json')['runtime_observed'] is False
    args = (admission, summary, load('observation/compile_a.json'),
            (HERE / 'observation/events.jsonl').read_bytes(), before, after, load('postcheck.json'))
    validate(*args)
    controls = []
    for key, value in [('timeout_seconds', 121), ('capture_limit_bytes', 8_388_609),
                       ('exec_failed', 1), ('ok', 1), ('stderr', 'unrelated failure')]:
        bad = copy.deepcopy(args); bad[2]['result'][key] = value; controls.append(bad)
    bad = copy.deepcopy(args); bad[2]['result']['cleanup']['group_gone'] = 0; controls.append(bad)
    bad = copy.deepcopy(args); bad[1]['stages'] = 10; controls.append(bad)
    bad = copy.deepcopy(args); bad[1]['test_error'] = None; controls.append(bad)
    bad = copy.deepcopy(args); bad[1]['capture_gaps'] = [{'kind': 'unknown'}]; controls.append(bad)
    bad = copy.deepcopy(args); bad[5][TARGET]['sha256'] = '0' * 64; controls.append(bad)
    bad = copy.deepcopy(args); bad[6]['workspace_absent'][args[6]['workspaces'][0]] = False; controls.append(bad)
    bad = copy.deepcopy(args); bad[0]['target'] = 't/2024-isf-record-input-runtime.t'; controls.append(bad)
    controls.append((args[0], args[1], args[2], b'native rejection\n', *args[4:]))
    for bad in controls:
        try:
            validate(*bad)
        except AssertionError:
            continue
        raise AssertionError('Corrupt saved first-compile failure accepted')
    print('First compile rejection authenticated: illegal mixed-state typed composition wire; no runtime. Exact identities, original bounds/results and cleanup retained; hostile saved controls reject. Repair and genuine behavior remain open.')


if __name__ == '__main__':
    main()
