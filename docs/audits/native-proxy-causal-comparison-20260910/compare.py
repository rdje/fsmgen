"""Compare pinned retained policy intervals; no process launch or clock conversion."""
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / '.artifacts/logs/native-proxy-causal-comparison-20260910'
FAILED = ROOT / '.artifacts/logs/t1669-startup-observation/run-2205e120533e4eb9aabcbc9f6c06e971'
PASSED = ROOT / '.artifacts/logs/t1669-startup-observation/run-56bb6ad5d9cc493daee047a8a9b92005'


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def read_policy(directory, expected):
    path = directory / 'policy.stdout'
    assert path.resolve() == path and path.stat().st_dev == ROOT.stat().st_dev
    assert path.stat().st_size <= 16777216
    raw = path.read_bytes()
    assert pin(raw) == expected
    rows = []
    for number, line in enumerate(raw.splitlines(keepends=True)[1:], 2):
        if line.strip():
            item = json.loads(line)
            assert isinstance(item, dict)
            rows.append({'number': number, 'line': pin(line), 'record': item})
    return rows


def tokens(message):
    found = re.findall(r'PST: \(path: ([0-9a-f]{1,16})\)', message)
    assert len(found) == message.count('PST: (path: ')
    return {item.zfill(16) for item in found}


def delta_us(start, end):
    elapsed = datetime.fromisoformat(end) - datetime.fromisoformat(start)
    return ((elapsed.days * 86400 + elapsed.seconds) * 1000000 + elapsed.microseconds)


def interval(rows, relative, token):
    absolute = str(ROOT / relative)
    literal = [row for row in rows if absolute in row['record'].get('eventMessage', '')
               and token in tokens(row['record']['eventMessage'])]
    assert len(literal) == 1
    phases = {}
    for prefix, name in [('queueing up scan', 'queued'), ('starting work for scan', 'started'),
                         ('scan finished, waking', 'wakeups')]:
        matches = [row for row in rows if row['record'].get('eventMessage', '').startswith(prefix)
                   and token in tokens(row['record']['eventMessage'])]
        assert len(matches) == 1
        row = matches[0]
        phases[name] = {'line': row['number'], 'raw_line': row['line'],
                        'timestamp': row['record']['timestamp']}
    waiting = delta_us(phases['queued']['timestamp'], phases['started']['timestamp'])
    scanning = delta_us(phases['started']['timestamp'], phases['wakeups']['timestamp'])
    assert waiting >= 0 and scanning >= 0
    return {'path': relative, 'token': token, 'literal_line': literal[0]['number'],
            'literal_raw_line': literal[0]['line'], 'phases': phases,
            'queue_to_start_us': waiting, 'start_to_wakeup_us': scanning,
            'clock_domain': 'retained_policy_timestamp_only'}


failed_pin = {'bytes': 7467562, 'sha256': 'bcd04952de64ccde9a1e952ed34cefb70c50aed602ce2d793f4328595fbe0034'}
passed_pin = {'bytes': 3709789, 'sha256': 'bc5a96e9db96f87ad573a318a44c8e4316d1806e76935a436acaa727c4116d20'}
failed = read_policy(FAILED, failed_pin)
passed = read_policy(PASSED, passed_pin)
old_path = '.artifacts/tmp/process-supervisor-tests/fsmgen-Y7FyEc4L/rust-tools/rustup'
old = interval(failed, old_path, 'c70948274239ac01')
native_audit = json.loads((ROOT / 'docs/audits/native-proxy-daemon-original-20260910/independent-audit.json').read_bytes())
assert pin((ROOT / 'docs/audits/native-proxy-daemon-original-20260910/independent-audit.json').read_bytes()) == {
    'bytes': 10067, 'sha256': '7d2a5f85d836d5ee66e710344ad0630aab1df205a8fdbb7dfd43ff7f502784c0'}
new = []
for item in native_audit['policy_native_joins']:
    measured = interval(passed, item['path'], item['token'])
    assert measured['phases'] == item['phases']
    new.append({'mode': item['mode'], **measured})
assert json.loads((FAILED / 'test-result.json').read_bytes())['returncode'] == 1
assert native_audit['original_result']['returncode'] == 0
assert old['queue_to_start_us'] == 14953485 and old['start_to_wakeup_us'] == 205212
old_source = (FAILED / 'dd39d5015afa146af4ecf8ec60573264ca37e38838d4248a395f9e3b2d3dbff7.source').read_bytes()
assert pin(old_source) == {'bytes': 62, 'sha256': 'dd39d5015afa146af4ecf8ec60573264ca37e38838d4248a395f9e3b2d3dbff7'}
assert old_source.startswith(b'#!/usr/bin/perl\n')

rejected = []
for label, operation in [
    ('changed_source_path', lambda: interval(passed, new[0]['path'] + '-changed', new[0]['token'])),
    ('changed_policy_token', lambda: interval(passed, new[0]['path'], '0000000000000000')),
    ('native_avoids_policy_queue', lambda: all(item['queue_to_start_us'] is None for item in new)),
    ('native_shortens_own_scan', lambda: all(item['start_to_wakeup_us'] < old['start_to_wakeup_us'] for item in new)),
]:
    try:
        value = operation()
        assert value is not False
    except AssertionError:
        rejected.append(label)
    else:
        raise AssertionError('unsupported counterclaim accepted: ' + label)

report = {'schema': 'fsmgen.native_proxy_retained_causal_comparison.v1',
    'failed_policy': failed_pin, 'passed_policy': passed_pin,
    'failed_retained_rows': len(failed), 'passed_retained_rows': len(passed),
    'failed_perl': old, 'passing_native': new,
    'rejected_claims': rejected,
    'interpretation': {'native_exec_contract': 'qualified by committed source/birth/TAP evidence',
        'native_policy_bypass': 'refuted by literal joined queue/start/wakeup records',
        'native_own_scan_shortening': 'refuted for these retained observations',
        'historical_queue_contention': 'consistent with previously qualified serial queue evidence',
        'native_cures_historical_startup': 'not_established; workload and preceding queue state differ',
        'original_clock_conversion': 'not_performed', 'loaded_image_attestation': 'not_provided',
        'kernel_sample': 'not_collected_in_native_run', 'new_original_or_collector': 'not_launched',
        'raw_policy_durability': 'private ignored streams; exact pins and projections retained'}}
raw = (json.dumps(report, sort_keys=True, indent=2) + '\n').encode()
with (OUT / 'comparison.json').open('xb') as stream:
    stream.write(raw)
print(json.dumps({'report': pin(raw), 'failed_intervals_us': [old['queue_to_start_us'], old['start_to_wakeup_us']],
    'native_intervals_us': [[x['queue_to_start_us'], x['start_to_wakeup_us']] for x in new],
    'rejected_claims': rejected}, sort_keys=True))
