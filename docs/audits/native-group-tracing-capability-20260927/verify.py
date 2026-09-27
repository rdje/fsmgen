#!/usr/bin/env python3
"""Verify saved capability/access evidence without invoking privileged tools."""
import copy
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent


def read(name):
    return json.loads((HERE / name).read_bytes())


def validate(result, authorization, request):
    assert result['schema'] == 'fsmgen.native_group_tracing_capability.v1'
    assert result['uid'] > 0 and result['deadline_seconds_each'] == 15
    assert result['manual_listing_contract'] == 'List probes instead of enabling them.'
    version, probes = result['results']
    assert version['command'] == ['/usr/sbin/dtrace', '-V']
    assert version['exit_code'] == 0 and version['stdout'] == 'dtrace: Sun D 1.19\n'
    assert probes['command'] == ['/usr/sbin/dtrace', '-l', '-n', 'syscall::setpgid:*']
    assert probes['exit_code'] == 1 and probes['stdout'] == ''
    assert 'DTrace requires additional privileges' in probes['stderr']
    assert all(row['timed_out'] is False for row in result['results'])
    assert authorization['command'] == ['/usr/bin/sudo', '-n', *probes['command']]
    assert authorization['exit_code'] == 1 and authorization['timed_out'] is False
    assert authorization['stdout'] == ''
    assert authorization['stderr'] == 'sudo: a password is required\n'
    assert request['command'] == ['sudo', *probes['command']]
    assert request['schema'] == 'fsmgen.native_group_administrator_check.v1'


def main():
    manifest = read('manifest.json')
    assert manifest['schema'] == 'fsmgen.native_group_tracing_preflight.v1'
    assert set(manifest['sha256']) == {'preflight.py', 'authorization.py', 'result.json',
                                      'authorization.json', 'administrator-check.json', 'verify.py'}
    for name, digest in manifest['sha256'].items():
        assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == digest
    args = [read('result.json'), read('authorization.json'), read('administrator-check.json')]
    validate(*args)
    for index, field, value in [(0, 'uid', 0), (1, 'exit_code', 0),
                                (1, 'timed_out', True), (2, 'command', ['sudo', 'dtrace', '-p', '1'])]:
        changed = copy.deepcopy(args)
        changed[index][field] = value
        try:
            validate(*changed)
        except AssertionError:
            continue
        raise AssertionError('altered capability evidence was accepted')
    print('Saved read-only capability failure and unavailable non-interactive authorization verified; no trace was enabled.')


if __name__ == '__main__':
    main()
