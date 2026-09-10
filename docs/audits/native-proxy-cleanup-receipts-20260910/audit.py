"""Independent synthetic cleanup truth table; no process or fixture execution."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-cleanup-receipts-20260910'
FIELDS = ('leader_started', 'leader_reaped', 'group_gone')
ROLES = ('compiler', 'outer', 'inner-first', 'inner-last')


def baseline() -> list:
    def receipt(stage: str) -> dict:
        return dict(stage=stage, status='nonzero_exit', ok=0,
                    cleanup=dict(leader_started=1, leader_reaped=1, group_gone=1))
    return [receipt('compile_proxy'), receipt('probe'),
            [receipt('tool_resolution'), receipt('tool_admission')]]


def owners(arguments: list) -> list:
    return arguments[:2] + arguments[2]


def build_plan() -> dict:
    rows = []

    def add(name: str, arguments: list, expected: int, family: str) -> None:
        rows.append(dict(name=name, arguments=arguments, expected=expected, family=family))

    # The explicit accepted tuples are taken from the existing ownership rule,
    # independently of the Perl predicate. Unstarted leaders need no reap.
    settled = {(0, 0, 1), (0, 1, 1), (1, 1, 1)}
    for position, role in enumerate(ROLES):
        for state in range(8):
            bits = tuple((state >> shift) & 1 for shift in (2, 1, 0))
            arguments = baseline()
            owners(arguments)[position]['cleanup'] = dict(zip(FIELDS, bits))
            add(f'{role}: flags {state:03b}', arguments, int(bits in settled), 'truth-table')
        for field in FIELDS:
            for label, value in [('null', None), ('boolean', True), ('array', []),
                                 ('map', {}), ('negative', -1), ('fraction', .5),
                                 ('out-of-range', 2), ('padded', '01'),
                                 ('newline', '1\n'), ('empty', '')]:
                arguments = baseline()
                owners(arguments)[position]['cleanup'][field] = value
                add(f'{role}: {field} {label}', arguments, 0, 'malformed-flag')
            arguments = baseline()
            del owners(arguments)[position]['cleanup'][field]
            add(f'{role}: missing {field}', arguments, 0, 'missing-flag')
        for label, value in [('null', None), ('array', []), ('scalar', 1)]:
            arguments = baseline()
            owners(arguments)[position]['cleanup'] = value
            add(f'{role}: cleanup {label}', arguments, 0, 'malformed-cleanup')
        arguments = baseline()
        del owners(arguments)[position]['cleanup']
        add(f'{role}: missing cleanup', arguments, 0, 'missing-cleanup')
        arguments = baseline()
        if position < 2:
            arguments[position] = None
        else:
            arguments[2][position - 2] = None
        add(f'{role}: absent owner', arguments, 0, 'missing-owner')
    for label, stages in [('empty', []), ('null', None), ('map', {}), ('scalar', 1)]:
        arguments = baseline()
        arguments[2] = stages
        add(f'stage array {label}', arguments, 0, 'missing-stages')
    for count in range(3):
        add(f'arity {count}', baseline()[:count], 0, 'arity')
    add('extra argument', baseline() + [None], 0, 'arity')
    arguments = baseline()
    for owner in owners(arguments):
        owner['cleanup'] = dict(zip(FIELDS, ('1', '1', '1')))
    add('scalar flag strings retain current compatibility', arguments, 1, 'compatibility')
    arguments = baseline()
    for owner in owners(arguments):
        owner.update(ok=1, status='success')
        owner['cleanup']['group_gone'] = 0
    add('success cannot substitute for cleanup', arguments, 0, 'status')
    add('failed but settled owners', baseline(), 1, 'status')
    arguments = baseline()
    for owner in owners(arguments):
        owner['cleanup'] = dict(leader_started=0, leader_reaped=0, group_gone=1)
        owner.update(status='invocation_error')
    add('prelaunch failures with no started leaders', arguments, 1, 'status')
    assert len({row['name'] for row in rows}) == len(rows)
    return dict(schema='fsmgen.inactive_cleanup_receipt_plan.v1', cases=rows,
                limits='Synthetic receipt structure only. The caller must establish complete transport, '
                       'actual process ownership and current filesystem custody before any retirement.')


def validate_result(result: dict, plan: dict) -> None:
    assert result['success'] is True
    assert type(result['forbidden_process_attempts']) is int and result['forbidden_process_attempts'] == 0
    expected = [dict(name=row['name'], actual=row['expected'], input_unchanged=1)
                for row in plan['cases']]
    assert result['cases'] == expected
    assert all(type(row['actual']) is int and type(row['input_unchanged']) is int for row in result['cases'])
    expected_mutants = {'omitted compiler': ('compiler: flags 110'),
                        'omitted outer': ('outer: flags 110'),
                        'omitted later inner': ('inner-last: flags 110'),
                        'omitted leader reap': ('inner-first: flags 101')}
    assert set(result['mutants']) == set(expected_mutants)
    by_name = {row['name']: row for row in plan['cases']}
    for name, case_name in expected_mutants.items():
        mutant = result['mutants'][name]
        assert all(type(mutant[field]) is int for field in ('actual', 'expected', 'input_unchanged'))
        assert mutant == dict(case_name=case_name, actual=1, expected=0, input_unchanged=1)
        assert by_name[case_name]['expected'] == 0


def tap_count(raw: str) -> int:
    assert not re.search(r'^(?:not ok|Bail out!)', raw, re.M)
    plans = re.findall(r'^1\.\.([0-9]+)$', raw, re.M)
    assert len(plans) == 1
    total = int(plans[0])
    assert [int(n) for n in re.findall(r'^ok ([0-9]+) - ', raw, re.M)] == list(range(1, total + 1))
    return total


def identity(path: Path) -> dict:
    raw = path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def main() -> None:
    plan = build_plan()
    if sys.argv[1:] == ['--plan']:
        (BASE / 'plan.json').write_text(json.dumps(plan, sort_keys=True, indent=2) + '\n')
        print(f"fixed independent receipt plan: {len(plan['cases'])} cases")
        return
    assert not sys.argv[1:]
    assert json.loads((BASE / 'plan.json').read_bytes()) == plan
    result = json.loads((LOG / 'qualification.json').read_bytes())
    validate_result(result, plan)
    codec_path = BASE.parent / 'native-proxy-runtime-records-20260910/audit.py'
    spec = importlib.util.spec_from_file_location('qualified_runtime_codec_audit', codec_path)
    codec = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(codec)
    codec.validate_result(json.loads((LOG / 'codec-regression.json').read_bytes()), codec.build_vectors())
    regression_assertions = codec.tap_count((LOG / 'codec-regression.tap').read_text())
    falsifiers = []
    for name, mutate in [
        ('hidden failure', lambda x: x.update(success=False)),
        ('missing owner position', lambda x: x['cases'].pop()),
        ('unknown cleanup accepted', lambda x: x['cases'][8].update(actual=1)),
        ('input mutated', lambda x: x['cases'][0].update(input_unchanged=0)),
        ('missing omitted-owner control', lambda x: x['mutants'].pop('omitted outer')),
        ('unproved counterimplementation', lambda x: x['mutants']['omitted leader reap'].update(actual=0)),
        ('process attempted', lambda x: x.update(forbidden_process_attempts=1)),
        ('boolean counter', lambda x: x.update(forbidden_process_attempts=False)),
    ]:
        altered = copy.deepcopy(result)
        mutate(altered)
        try:
            validate_result(altered, plan)
        except AssertionError:
            falsifiers.append(name)
        else:
            raise AssertionError(f'counterfactual accepted: {name}')
    report = dict(schema='fsmgen.inactive_cleanup_receipt_audit.v1', success=True,
                  cases=len(plan['cases']), truth_table_cases=sum(row['family'] == 'truth-table' for row in plan['cases']),
                  rejected_cases=sum(not row['expected'] for row in plan['cases']),
                  assertions=tap_count((LOG / 'qualify.tap').read_text()),
                  regression_assertions=regression_assertions,
                  mutants=sorted(result['mutants']), falsifiers=falsifiers,
                  inputs=[identity(path) for path in [BASE / 'CleanupReceipts.pm', BASE / 'qualify.t',
                          BASE / 'plan.json', LOG / 'qualification.json', LOG / 'qualify.tap',
                          LOG / 'codec-regression.json', LOG / 'codec-regression.tap', codec_path]],
                  limits=plan['limits'])
    (LOG / 'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps({key: report[key] for key in ('success', 'cases', 'truth_table_cases', 'rejected_cases', 'assertions')}))


if __name__ == '__main__':
    main()
