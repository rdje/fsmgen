"""Independent actual-member, errno and retained-directory custody oracle."""
from __future__ import annotations

import copy
import errno
import hashlib
import json
import os
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT/'.artifacts/logs/native-proxy-image-members-20260911'
PLAN_SHA = '7468bc5a701a977c7e2c60423f21c5f733ba981862822fb1abc7c7eb6ae5207a'


def equal(a, b) -> None:
    assert json.dumps(a, sort_keys=True, separators=(',', ':')) == json.dumps(b, sort_keys=True, separators=(',', ':'))


def integer(value, minimum=0) -> None:
    assert type(value) is int and value >= minimum


def check_row(row: dict, spec: dict, plan: dict, phase: str, mutant=None, strict=False) -> None:
    name = spec['name']
    assert row['fault'] == name and 'names' not in row
    allocation = row['allocation']
    before = row['before']
    equal(before, row['after'])
    assert set(before) == {''} | set(spec['members'])
    for path, node in before.items():
        integer(node['device']); integer(node['inode'], 1)
        assert node['device'] == ROOT.stat().st_dev
        if path == '':
            equal(node, dict(kind='directory', mode=0o700, uid=os.getuid(),
                             device=allocation['device'], inode=allocation['inode']))
        else:
            raw = plan['payloads'][path].encode('ascii')
            equal(node, dict(kind='file', mode=0o400, uid=os.getuid(), device=node['device'],
                inode=node['inode'], links=1, bytes=raw.decode('ascii'), size_bytes=len(raw),
                sha256=hashlib.sha256(raw).hexdigest()))
    integer(row['allocation_absent']); assert row['allocation_absent'] == 1
    calls = row['calls']
    assert calls and set(calls[0]) == {'kind', 'returned', 'errno'}
    assert calls[0]['kind'] == 'open'
    integer(calls[0]['returned']); assert calls[0]['returned'] == 1
    integer(calls[0]['errno'])
    reads = [c for c in calls if c['kind'] == 'read']
    closes = [c for c in calls if c['kind'] == 'close']
    equal(calls, [calls[0], *reads, *closes])
    actual = [c['entry'] for c in reads if c['entry'] not in (None, '.', '..')]
    equal(actual, row['actual_members'])
    assert len(actual) == len(set(actual)) and set(actual) <= set(spec['members'])
    for call in reads:
        assert set(call) == {'kind', 'entry', 'incoming_errno', 'errno', 'injected'}
        for field in ('incoming_errno', 'errno', 'injected'): integer(call[field])
        assert call['injected'] in (0, 1)
        assert call['entry'] in (None, '.', '..') or call['entry'] in spec['members']
        if phase == 'qualification': assert call['incoming_errno'] == 0
    real = [c for c in reads if not c['injected']]
    assert all(sum(c['entry'] == dot for c in real) <= 1 for dot in ('.', '..'))
    injected = [c for c in reads if c['injected']]
    count = {'read_entry': 0, 'read_after_one': 1, 'read_after_all': 3, 'read_and_close': 1}.get(name)
    if count is not None:
        assert len(injected) == 1 and reads[-1] == injected[0]
        assert injected[0]['entry'] is None and injected[0]['errno'] == errno.EIO
        assert len(actual) == count and all(c['entry'] is not None for c in real)
    else:
        assert not injected
        equal(sorted(actual), sorted(spec['members']))
        if name.startswith('capacity'):
            assert len(actual) == 4 and all(c['entry'] is not None for c in reads)
        else:
            assert reads[-1]['entry'] is None and reads[-1]['errno'] == 0
            assert sum(c['entry'] is None for c in reads) == 1
    integer(row['read_error_injected']); assert row['read_error_injected'] == int(count is not None)
    baseline_capacity = phase == 'baseline' and name == 'capacity'
    assert len(closes) == int(not baseline_capacity)
    for call in closes:
        assert set(call) == {'kind', 'actual_close', 'returned', 'errno'}
        for field in ('actual_close', 'returned', 'errno'): integer(call[field])
        omitted = mutant == 'omit_directory_close'
        reported = name in ('close_error', 'capacity_and_close', 'read_and_close')
        assert call['actual_close'] == int(not omitted) and call['returned'] == int(omitted or not reported)
        if reported: assert call['errno'] == errno.EIO
    assert len(row['handles']) == 1
    handle = row['handles'][0]
    integer(handle['descriptor']); integer(handle['observer_descriptor'])
    assert handle['descriptor'] != handle['observer_descriptor'] and handle['path'] == allocation['path']
    equal(handle['identity'], {key: before[''][key] for key in ('device', 'inode', 'mode', 'uid')})
    for field in ('observer_close_ok', 'observer_closed', 'closed_after_recovery'):
        integer(handle[field]); assert handle[field] == 1
    remains_open = baseline_capacity or mutant == 'omit_directory_close'
    integer(handle['closed_before_recovery']); assert handle['closed_before_recovery'] == int(not remains_open)
    if remains_open:
        assert not strict
        integer(handle['recovery_close_ok']); assert handle['recovery_close_ok'] == 1
    else: assert handle['recovery_close_ok'] is None
    ignored_error = (phase == 'baseline' and name == 'read_after_all') or mutant == 'omit_read_error_check'
    returned = spec['returns'] or ignored_error
    integer(row['returned']); assert row['returned'] == int(returned)
    if returned:
        assert row['error'] == '' and set(actual) == {'image.json', 'rustup', 'rustup.c'}
        if ignored_error: assert not strict
    else:
        diagnostic = 'incomplete or unknown image members' if phase == 'baseline' and name.startswith('read_') else spec['diagnostic']
        expected = diagnostic + (': '+os.strerror(errno.EIO) if diagnostic.startswith('cannot ') else '') + '\n'
        assert row['error'] == expected


def validate(result: dict, plan: dict, phase: str) -> None:
    assert result['schema'] == 'fsmgen.inactive_image_member_qualification.v1' and result['phase'] == phase
    assert result['completed'] is True and 'first_failure' not in result
    assert result['success'] is (phase == 'qualification') and result['qualified'] is (phase == 'qualification')
    assert result['perl_version'] == 'v5.34.1' and result['directory_descriptor_support'] == 'define'
    integer(result['forbidden_process_attempts']); assert result['forbidden_process_attempts'] == 0
    specs = {r['name']: r for r in plan['cases']}
    selected = plan['baseline'] if phase == 'baseline' else list(specs)
    mutants = [] if phase == 'baseline' else plan['mutants']
    assert [r['name'] for r in result['cases']] == selected
    assert [r['name'] for r in result['mutants']] == [r['name'] for r in mutants]
    ledger = [json.loads(line) for line in (LOG/(phase+'-admission.jsonl')).read_text().splitlines()]
    equal(ledger, result['allocated'])
    equal(ledger, [r['allocation'] for r in result['cases']+result['mutants']])
    assert len(ledger) == len(selected)+len(mutants) == len({r['path'] for r in ledger})
    for row in ledger:
        assert set(row) == {'path', 'device', 'inode'}
        integer(row['device']); integer(row['inode'], 1)
        assert row['device'] == ROOT.stat().st_dev
        assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+', row['path'])
        assert not (ROOT/row['path']).exists() and not (ROOT/row['path']).is_symlink()
    for row in result['cases']: check_row(row, specs[row['name']], plan, phase)
    for row, mutant in zip(result['mutants'], mutants):
        spec = specs[mutant['case']]
        check_row(row, spec, plan, phase, mutant['name'])
        try: check_row(row, spec, plan, phase, mutant['name'], strict=True)
        except AssertionError: pass
        else: raise AssertionError('strict oracle accepted omitted image-member guard')


def main() -> None:
    assert len(sys.argv) == 2 and sys.argv[1] in ('--baseline', '--qualification')
    phase = sys.argv[1][2:]
    raw = (BASE/'plan.json').read_bytes(); assert hashlib.sha256(raw).hexdigest() == PLAN_SHA
    plan = json.loads(raw); result = json.loads((LOG/(phase+'.json')).read_bytes())
    validate(result, plan, phase)
    tap = (LOG/(phase+'.tap')).read_text()
    assertions = 2*(len(result['cases'])+len(result['mutants']))+1
    assert not re.search(r'^(?:not ok|Bail out!)', tap, re.M)
    assert re.findall(r'^1\.\.(\d+)$', tap, re.M) == [str(assertions)]
    assert [int(n) for n in re.findall(r'^ok (\d+) - ', tap, re.M)] == list(range(1, assertions+1))
    falsifiers = []
    for name, change in [
        ('false qualification', lambda x: x.update(qualified=not x['qualified'])),
        ('lost allocation', lambda x: x['allocated'].pop()),
        ('lost read calls', lambda x: x['cases'][0].update(calls=[x['cases'][0]['calls'][0]])),
        ('invented directory identity', lambda x: x['cases'][0]['handles'][0]['identity'].update(inode=1)),
        ('lost observer close', lambda x: x['cases'][0]['handles'][0].update(observer_closed=0)),
        ('changed member bytes', lambda x: x['cases'][0]['after']['rustup'].update(bytes='changed')),
        ('forbidden process', lambda x: x.update(forbidden_process_attempts=1)),
    ]:
        changed = copy.deepcopy(result); change(changed)
        try: validate(changed, plan, phase)
        except (AssertionError, KeyError): falsifiers.append(name)
        else: raise AssertionError('image-member oracle missed falsifier: '+name)
    report = dict(schema='fsmgen.inactive_image_member_audit.v1', phase=phase, completed=True,
        qualified=phase == 'qualification', assertions=assertions, cases=len(result['cases']),
        allocations=len(result['allocated']), mutants=[r['name'] for r in result['mutants']],
        falsifiers=falsifiers, limits=plan['limits'])
    (LOG/(phase+'-audit.json')).write_text(json.dumps(report, sort_keys=True, indent=2)+'\n')
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()
