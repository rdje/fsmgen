"""Verify saved unary public-pin runtime evidence; never replay HDL or fixtures."""
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
LABELS = ['compile_a', 'runtime_b', 'compile_c', 'runtime_d', 'compile_e', 'runtime_f']


def digest(data):
    return hashlib.sha256(data).hexdigest()


def load(path):
    def distinct(pairs):
        result = {}
        for key, value in pairs:
            assert key not in result
            result[key] = value
        return result
    return json.loads(path.read_bytes(), object_pairs_hook=distinct)


def clean(result, timeout, cap):
    assert result['ok'] == 1 and result['status'] == 'success' and result['exit_code'] == 0
    assert result['timeout_seconds'] == timeout and result['capture_limit_bytes'] == cap
    assert result['timed_out'] == result['output_limited'] == result['signal'] == 0
    assert result['exec_error'] is None and result['stderr'] == ''
    c = result['cleanup']
    assert c['leader_started'] == c['leader_reaped'] == c['group_gone'] == 1
    assert c['surviving_descendants'] == c['term_sent'] == c['kill_sent'] == 0


def validate(outer, summary, stages, post):
    result = outer['result']
    clean(result, 600, 8_388_608)
    assert 'All tests successful.' in result['stdout'] and 'Files=1, Tests=4,' in result['stdout']
    assert not re.search(r'^\s*not ok|#\s*SKIP', result['stdout'], re.M | re.I)
    assert summary['schema'] == 'fsmgen.priority_stage_observation.v1' and summary['stages'] == 6
    assert summary['input_error'] is None and summary['test_error'] is None
    assert summary['capture_gaps'] == summary['retention_errors'] == []
    assert [r['label'] for r in summary['receipts']] == LABELS
    assert set(stages) == set(LABELS)
    assert len(post['workspaces']) == 1 and post['workspaces_absent'] is True
    assert post['matching_commands'] == [] and post['cache_devices_match_repository'] is True
    assert post['successful_child_births_observed'] is False
    work = post['workspaces'][0]
    assert re.fullmatch(r'\.artifacts/tmp/tests/[A-Za-z0-9_]+', work)
    for i, target in enumerate(('systemverilog', 'verilog', 'wrong')):
        compile_label, runtime_label = LABELS[2*i:2*i+2]
        compile_stage, runtime_stage = stages[compile_label], stages[runtime_label]
        obj = f'{work}/obj_{target}'
        source = f'{work}/' + ('wrong.sv' if target == 'wrong' else f'design_{target}.sv')
        assert compile_stage['arguments'] == [['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'tb', '--Mdir', obj, source, 't/data/unary_reduction_runtime_tb.sv']]
        assert runtime_stage['arguments'] == [[obj + '/Vtb']]
        clean(compile_stage['result'], 120, 8_388_608)
        clean(runtime_stage['result'], 30, 67_108_864)
        assert compile_stage['result']['stage'] == 'compile' and runtime_stage['result']['stage'] == 'runtime'
        text = runtime_stage['result']['stdout']
        if target == 'wrong':
            match = re.search(r'^UNARY_RUNTIME_MISMATCH row=1 expected=([0-9a-f]{10}) actual=([0-9a-f]{10})$', text, re.M)
            assert match and 'UNARY_RUNTIME_PASS' not in text
            expected, actual = (int(s, 16) for s in match.groups())
            assert expected == int('5015cc01ce', 16) and actual == (expected ^ (1 << 38))
        else:
            for marker in ('UNARY_RUNTIME_HOLD_PASS', 'UNARY_RUNTIME_RESET_PASS', 'UNARY_RUNTIME_PASS checked=512'):
                assert text.splitlines().count(marker) == 1
            assert not re.search(r'UNARY_RUNTIME_(?:MISMATCH|COUNT_MISMATCH|DEADLINE)', text)


def main():
    manifest = load(HERE / 'manifest.json')
    assert manifest['schema'] == 'fsmgen.unary_runtime_observation.v1'
    actual = {str(p.relative_to(HERE)) for p in HERE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    assert actual == set(manifest['sha256'])
    for name, sha in manifest['sha256'].items():
        assert digest((HERE / name).read_bytes()) == sha
    observer = ROOT / 'docs/audits/unary-observer-20261022'
    assert digest((observer / 'manifest.json').read_bytes()) == manifest['observer_manifest_sha256']
    qualification = load(observer / 'manifest.json')
    for name, sha in qualification['sha256'].items():
        assert digest((observer / name).read_bytes()) == sha
    evidence = HERE / 'evidence'
    before, after = load(evidence / 'before.json'), load(evidence / 'after.json')
    admission = load(evidence / 'admission.json')
    assert before['revision'] == manifest['baseline_revision'] and admission['capture'] == manifest['capture']
    assert digest((evidence / 'admission.json').read_bytes()) == before['admission_sha256']
    assert admission['schema'] == 'fsmgen.fixed_unary_observer_admission.v1'
    assert admission['mode'] == 'unary' and admission['scenario'] == 'none'
    assert admission['target'] == 't/2090-isf-unary-reduction-runtime.t'
    assert admission['expected_stages'] == {'compile': 3, 'runtime': 3}
    before_map = {r['path']: r['sha256'] for r in before['before_inputs']}
    assert len(before_map) == len(before['before_inputs'])
    assert before_map == {r['path']: r['sha256'] for r in after} == admission['sha256']
    baseline = manifest['baseline_revision']
    for row in before['before_inputs']:
        raw = subprocess.check_output(['git', 'show', baseline + ':' + row['path']], cwd=ROOT)
        assert digest(raw) == row['sha256']
        assert subprocess.check_output(['git', 'rev-parse', baseline + ':' + row['path']], cwd=ROOT, text=True).strip() == row['git_blob']
    for name in ('2090-isf-unary-reduction-runtime.t', 'unary_reduction_runtime.isf',
                 'unary_reduction_runtime_tb.sv', 'unary_reduction_runtime_vectors.hex'):
        path = 't/' + name if name.startswith('2090') else 't/data/' + name
        assert digest((evidence / 'inputs' / name).read_bytes()) == before_map[path]
    summary = load(evidence / 'summary.json')
    assert summary['admission_sha256'] == before['admission_sha256']
    assert (evidence / 'events.jsonl').read_bytes() == b''
    stages = {}
    for row in summary['receipts']:
        assert row['path'] == row['label'] + '.json' and row['stage'] == row['label'].split('_')[0]
        assert digest((evidence / row['path']).read_bytes()) == row['sha256']
        stages[row['label']] = load(evidence / row['path'])
    outer, post = load(evidence / 'outer.json'), load(evidence / 'postcheck.json')
    validate(outer, summary, stages, post)
    mutations = [
        ('lost positive marker', lambda s: s['runtime_b']['result'].update(stdout='')),
        ('wrong-source false success', lambda s: s['runtime_f']['result'].update(stdout='UNARY_RUNTIME_PASS checked=512\n')),
        ('wrong unrelated value', lambda s: s['runtime_f']['result'].update(stdout='UNARY_RUNTIME_MISMATCH row=1 expected=5015cc01ce actual=1015cc01cf\n')),
        ('changed native bound', lambda s: s['compile_a']['result'].update(timeout_seconds=121)),
        ('changed command', lambda s: s['compile_c'].update(arguments=[['verilator', '--binary']])),
        ('missing cleanup', lambda s: s['runtime_d']['result']['cleanup'].update(group_gone=0)),
    ]
    for label, mutate in mutations:
        changed = copy.deepcopy(stages)
        mutate(changed)
        try:
            validate(outer, summary, changed, post)
        except AssertionError:
            continue
        raise AssertionError('corrupt saved evidence accepted: ' + label)
    for label, mutate in (
        ('missing stage', lambda s: s['receipts'].pop()),
        ('diagnostic gap', lambda s: s.update(capture_gaps=[{'kind': 'missing'}])),
    ):
        changed = copy.deepcopy(summary)
        mutate(changed)
        try:
            validate(outer, changed, stages, post)
        except AssertionError:
            continue
        raise AssertionError('corrupt saved summary accepted: ' + label)
    changed = copy.deepcopy(post)
    changed['matching_commands'] = ['unexpected retained process']
    try:
        validate(outer, summary, stages, changed)
    except AssertionError:
        pass
    else:
        raise AssertionError('corrupt independent cleanup accepted')
    print('Both HDL positives, exact wrong-source bit mismatch, complete identities/bounds/results and independent cleanup verified; hostile saved controls reject.')


if __name__ == '__main__':
    main()
