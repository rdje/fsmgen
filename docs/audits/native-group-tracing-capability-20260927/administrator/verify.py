#!/usr/bin/env python3
"""Verify the retained administrator report without treating exit zero as admission."""
import copy
import hashlib
import json
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent


def validate(report):
    assert report['schema'] == 'fsmgen.native_group_administrator_report.v1'
    assert report['command'] == ['sudo', '/usr/sbin/dtrace', '-l', '-n', 'syscall::setpgid:*']
    assert report['source'] == 'user-provided terminal transcript in this conversation'
    assert report['reported_later_exit_status'] == 0
    assert report['command_exit_status'] is None
    assert report['probe_discovery_outcome'] == 'blocked_by_sip'
    assert report['native_failure_attribution'] == 'unresolved'
    transcript = report['transcript']
    assert 'dtrace: failed to match syscall::setpgid:*: System Integrity Protection is on' in transcript
    assert 'ID   PROVIDER' in transcript and transcript.endswith('exit=0\n')
    assert not re.search(r'^\s*\d+\s+syscall\s', transcript, re.MULTILINE)


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert set(manifest['sha256']) == {'report.json', 'verify.py'}
    for name, digest in manifest['sha256'].items():
        assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == digest
    report = json.loads((HERE / 'report.json').read_bytes())
    validate(report)
    mutations = []
    for key, value in [('probe_discovery_outcome', 'available'), ('command_exit_status', 0),
                       ('native_failure_attribution', 'sip_caused_setpgid_eperm')]:
        changed = copy.deepcopy(report)
        changed[key] = value
        mutations.append(changed)
    changed = copy.deepcopy(report)
    changed['transcript'] = changed['transcript'].replace('failed to match', 'matched')
    mutations.append(changed)
    for changed in mutations:
        try:
            validate(changed)
        except AssertionError:
            continue
        raise AssertionError('unsupported administrator-report conclusion accepted')
    print('Administrator-reported probe denial and separate zero-status report verified; original EPERM cause remains unresolved.')


if __name__ == '__main__':
    main()
