#!/usr/bin/env python3
"""Verify the dated admitted priority defect; this does not execute HDL."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CASES = {'single_state': ['2'], 'multi_state': ['2', '3'], 'reversed_values': ['3', '2']}


def validate(results):
    assert [row['case'] for row in results] == list(CASES)
    for row in results:
        case = row['case']
        values = CASES[case]
        states = [f'main_set_{n}' for n in range(1, len(values) + 1)]
        assert row['check_success'] is True and row['compile_issues'] == []
        assert row['higher_writers'] == [
            {'state': state, 'transaction': 'main', 'operator': '<-', 'rhs': rhs, 'guard': None}
            for state, rhs in zip(states, values)]
        assert row['retained_states'] == [states[-1]]
        assert row['rule_header'] == {'port': 'force'}
        assert row['rule_output'] == {
            'lhs': 'out', 'op': '<-', 'rhs': '9', 'source_kind': 'rule_action',
            'guard': {'expr': f'(! (state_active {states[-1]}))'}, 'priority_suppressed_by': ['main']}
        assert row['unrelated_output'] == {'lhs': 'side', 'op': '<-', 'rhs': '7', 'source_kind': 'rule_action'}
        resolution = {'target': 'out', 'winner': 'main', 'winner_kind': 'transaction',
                      'loser': 'fallback', 'loser_kind': 'rule'}
        assert row['priority_resolutions'] == [resolution] * len(states)
        # Under the public one-hot state_active contract and force=1, the
        # retained inverse-last-state guard enables the rule in every other
        # winning state. This is a static overlap witness, not a simulation.
        overlap = [state for state in states if state != row['retained_states'][0]]
        assert overlap == ([] if case == 'single_state' else ['main_set_1'])


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert manifest['schema'] == 'fsmgen.priority_contributor_baseline.v1'
    for name, digest in manifest['sha256'].items():
        assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == digest
    source_path = 'perl/FSM/Scheduler/ISF/LoweringIR.pm'
    for entry in manifest['history']:
        source = subprocess.check_output(['git', 'show', entry['revision'] + ':' + source_path], cwd=ROOT)
        assert hashlib.sha256(source).hexdigest() == entry['source_sha256']
        assert entry['source_marker'].encode() in source
    results = json.loads((HERE / 'evidence/result.json').read_bytes())
    validate(results)
    for row in results:
        case = row['case']
        source = (HERE / f'{case}.isf').read_bytes()
        assert hashlib.sha256(source).hexdigest() == row['source_sha256']
        assert re.findall(r'\(set out ([0-9]+)\)', source.decode()) == CASES[case] + ['9']
        check = json.loads((HERE / f'evidence/{case}-check.json').read_bytes())
        schedule = json.loads((HERE / f'evidence/{case}-schedule.json').read_bytes())
        semantic = json.loads((HERE / f'evidence/{case}-semantic.json').read_bytes())
        carrier = (HERE / f'evidence/{case}.fsm').read_text()
        assert check['success'] is True
        assert schedule['compile_issues'] == []
        assert schedule['priority_resolutions'] == row['priority_resolutions']
        assert f'(<- (out> 9) <{row["rule_output"]["guard"]["expr"]})' in carrier
        assert '(<- (side> 7))' in carrier
        for writer in row['higher_writers']:
            assert f'  ({writer["state"]}\n    (<- (out> {writer["rhs"]}))' in carrier
        forward = semantic['semantic']['forward_ir']
        output, = [entry for entry in forward['lowered_rtl_ir']['output_drive_families']
                   if entry['signal_name'] == 'out']
        assert output['driver_blocks'] == ['-fallback'] + [w['state'] for w in row['higher_writers']]
        assert output['rhs_values'] == sorted(CASES[case] + ['9'])
        assert len(output['driver_enable_signals']) == len(CASES[case]) + 1
        lower_enable, = [entry for entry in forward['structural_rtl_ir']['assignment_records']
                         if entry.get('provenance', {}).get('role') == 'dt_specific_enable'
                         and entry['provenance'].get('lhs_signal') == 'out'
                         and entry['provenance'].get('dt_name') == '-fallback']
        assert lower_enable['provenance']['rhs_value'] == '9'
        assert lower_enable['provenance']['dte_gate_signal'] == 'fallback_en'
    for mutate in (
        lambda rows: rows[1]['retained_states'].insert(0, 'main_set_1'),
        lambda rows: rows[1]['higher_writers'].pop(0),
        lambda rows: rows[0].update(check_success=False),
        lambda rows: rows[1]['rule_output'].update(priority_suppressed_by=[]),
        lambda rows: rows[1]['higher_writers'][0].update(transaction='other'),
    ):
        altered = copy.deepcopy(results)
        mutate(altered)
        try:
            validate(altered)
        except AssertionError:
            continue
        raise AssertionError('corrupt baseline accepted')
    print('Dated admission, missing same-owner condition, public carriers/selectors, history and hostile controls verified; runtime remains unmeasured.')


if __name__ == '__main__':
    main()
