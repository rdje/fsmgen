#!/usr/bin/env python3
"""Verify the complete saved priority observation, never rerun native work."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
LABELS = ['compile_a', 'runtime_b', 'compile_c', 'runtime_d', 'compile_e', 'runtime_f']


def digest(data):
    return hashlib.sha256(data).hexdigest()


def load(path):
    return json.loads(path.read_bytes())


def validate(admission, summary, stages, events, extra, postcheck):
    assert admission['capture'] == 'priority_reset_corrected'
    assert admission['mode'] == 'priority' and admission['scenario'] == 'none'
    assert admission['target'] == 't/1974-isf-priority-contributor-union.t'
    assert admission['expected_stages'] == {'compile': 3, 'runtime': 3}
    assert summary['stages'] == 6
    assert [r['label'] for r in summary['receipts']] == LABELS
    assert summary['input_error'] is None and summary['test_error'] is None
    assert summary['capture_gaps'] == summary['retention_errors'] == [] and events == b''
    assert extra['before'] == extra['after']
    assert extra['before']['t/1974-isf-priority-contributor-union.t']['sha256'] == admission['sha256']['t/1974-isf-priority-contributor-union.t']
    object_dirs = []
    for i, label in enumerate(LABELS):
        result = stages[label]['result']
        args = stages[label]['arguments']
        stage = 'compile' if i % 2 == 0 else 'runtime'
        assert result['stage'] == stage
        assert result['schema'] == 'fsmgen.test.verilator_runtime_result.v1' and result['schema_version'] == 1
        assert len(args) == 1 and isinstance(args[0], list)
        argv = args[0]
        assert result['exec_failed'] == 0 and result['exec_error'] is None
        assert result['timed_out'] == result['output_limited'] == result['signal'] == 0
        assert result['cleanup'] == {'containment': 'test_runtime_process_group', 'group_gone': 1,
            'kill_sent': 0, 'leader_reaped': 1, 'leader_started': 1,
            'surviving_descendants': 0, 'term_sent': 0}
        assert result['timeout_seconds'] == (120 if stage == 'compile' else 30)
        assert result['capture_limit_bytes'] == (8_388_608 if stage == 'compile' else 67_108_864)
        if stage == 'compile':
            assert argv[:10] == ['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
                                  '-j', '1', '--top-module', 'tb', '--Mdir']
            object_dirs.append(argv[10])
            assert len(argv[11:]) == (10 if i < 4 else 2)
            assert '--no-assert' not in argv
        else:
            assert argv == [object_dirs[-1] + '/Vtb']
        if label == 'runtime_f':
            assert result['ok'] == 0 and result['status'] == 'nonzero_exit' and result['exit_code'] == 1
            assert 'Assertion failed in tb.dut: selector multi-value conflict: out\n' in result['stdout']
            assert 'MISSING_DIFFERENT_VALUE_ASSERTION' not in result['stdout']
        else:
            assert result['ok'] == 1 and result['exit_code'] == 0 and result['status'] == 'success'
            if stage == 'runtime':
                assert 'PRIORITY_CONTRIBUTOR_UNION_PASS' in result['stdout']
                assert '%Error' not in result['stdout'] + result['stderr']
    work = str(Path(object_dirs[0]).parent)
    assert object_dirs == [work + '/obj_' + name for name in ('systemverilog', 'verilog', 'negative')]
    assert postcheck['work'] == work and postcheck['workspace_absent'] is True
    assert postcheck['selected_command_residue'] == []
    assert postcheck['native_pid_absence'].startswith('not independently measured;')


def main():
    manifest = load(HERE / 'manifest.json')
    assert manifest['schema'] == 'fsmgen.priority_runtime_qualification.v1'
    assert manifest['native_cause'] == 'historical_EPERM_not_attributed'
    assert set(manifest['sha256']) == {str(p.relative_to(HERE)) for p in HERE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    for name, expected in manifest['sha256'].items():
        assert digest((HERE / name).read_bytes()) == expected
    for name, expected in manifest['prerequisites'].items():
        assert digest((ROOT / name).read_bytes()) == expected
    for name, record in manifest['producers'].items():
        data = (ROOT / name).read_bytes() if (ROOT / name).exists() else b''
        if digest(data) != record['sha256']:
            data = subprocess.check_output(['git', 'cat-file', 'blob', record['git_blob']], cwd=ROOT)
        assert digest(data) == record['sha256']
    admission_bytes = (HERE / 'observation/admission.json').read_bytes()
    admission, summary = json.loads(admission_bytes), load(HERE / 'observation/summary.json')
    stages = {label: load(HERE / ('observation/' + label + '.json')) for label in LABELS}
    events = (HERE / 'observation/events.jsonl').read_bytes()
    extra, postcheck = load(HERE / 'extra-identities.json'), load(HERE / 'postcheck.json')
    assert summary['admission_sha256'] == digest(admission_bytes)
    for receipt in summary['receipts']:
        assert receipt['path'] == receipt['label'] + '.json'
        assert receipt['stage'] == receipt['label'].split('_')[0]
        assert receipt['sha256'] == digest((HERE / 'observation' / receipt['path']).read_bytes())
    for name, expected in admission['sha256'].items():
        assert manifest['producers'][name]['sha256'] == expected
    assert all(manifest['producers'][name] == record for name, record in extra['before'].items())
    record = load(HERE / 'observed-result.json')
    assert record['exit_code'] == 0 and record['log_sha256'] == digest(record['log'].encode())
    source = (HERE / 'observed-test.t.source').read_bytes()
    assert record['test_sha256'] == digest(source) == admission['sha256']['t/1974-isf-priority-contributor-union.t']
    assert 'All tests successful.' in record['log'] and 'Files=1, Tests=4,' in record['log']
    assert '# skip qualified Verilator runtime unavailable' not in record['log']
    assert 'enabled different-value assertion rejects the deliberately lost contributor' in record['log']
    args = (admission, summary, stages, events, extra, postcheck)
    validate(*args)
    mutations = []
    bad = copy.deepcopy(stages); bad['compile_c']['result']['timeout_seconds'] = 121; mutations.append((admission, summary, bad, events, extra, postcheck))
    bad = copy.deepcopy(stages); bad['runtime_b']['result']['stdout'] = ''; mutations.append((admission, summary, bad, events, extra, postcheck))
    bad = copy.deepcopy(stages); bad['runtime_f']['result']['stdout'] = 'unrelated failure'; mutations.append((admission, summary, bad, events, extra, postcheck))
    bad = copy.deepcopy(stages); bad['compile_a']['arguments'][0][3] = '--no-assert'; mutations.append((admission, summary, bad, events, extra, postcheck))
    bad = copy.deepcopy(stages); bad['runtime_d']['result']['cleanup']['group_gone'] = 0; mutations.append((admission, summary, bad, events, extra, postcheck))
    bad = copy.deepcopy(stages); bad['runtime_f']['result']['exec_failed'] = 1; mutations.append((admission, summary, bad, events, extra, postcheck))
    bad = copy.deepcopy(extra); bad['after']['t/1974-isf-priority-contributor-union.t']['sha256'] = '0' * 64; mutations.append((admission, summary, stages, events, bad, postcheck))
    bad = copy.deepcopy(postcheck); bad['workspace_absent'] = False; mutations.append((admission, summary, stages, events, extra, bad))
    bad = copy.deepcopy(summary); bad['stages'] = 4; mutations.append((admission, bad, stages, events, extra, postcheck))
    mutations.append((admission, summary, stages, b'failure\n', extra, postcheck))
    for candidate in mutations:
        try:
            validate(*candidate)
        except AssertionError:
            continue
        raise AssertionError('corrupt runtime qualification accepted')
    print('Two-target priority controls and actual different-value assertion rejection verified with unchanged sources, original bounds and cleanup; historical native causality remains unproved.')


if __name__ == '__main__':
    main()
