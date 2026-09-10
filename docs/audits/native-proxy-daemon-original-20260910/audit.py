"""Independent retained-result audit; never executes the original or a collector."""
import copy
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
CAPSULE = ROOT / '.artifacts/logs/native-proxy-daemon-original-20260910'
DURABLE = ROOT / 'docs/audits/native-proxy-daemon-original-20260910'
sys.path.insert(0, str(ROOT / 'scripts'))
import fixture_kernel_sampler as sampler


def read(path, limit=16777216):
    before = path.lstat()
    assert path.resolve() == path and before.st_dev == ROOT.stat().st_dev
    assert stat.S_ISREG(before.st_mode) and before.st_uid == os.getuid()
    assert before.st_size <= limit
    with path.open('rb') as stream:
        raw = stream.read(limit + 1)
    after = path.lstat()
    assert len(raw) == before.st_size <= limit
    assert all(getattr(before, key) == getattr(after, key) for key in
               ('st_dev', 'st_ino', 'st_size', 'st_mtime_ns', 'st_ctime_ns'))
    return raw


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def load(path):
    return json.loads(read(path))


def validate_tap(raw, result):
    program = ('use TAP::Parser; use JSON::PP; my $raw=do {local $/; <STDIN>}; '
               'my $p=TAP::Parser->new({tap=>$raw}); $p->run; '
               'print encode_json({run=>$p->tests_run,planned=>$p->tests_planned,'
               'passed=>[$p->passed],failed=>[$p->failed],errors=>[$p->parse_errors]});')
    parsed = json.loads(subprocess.run(['/usr/bin/perl', '-e', program], input=raw,
                        capture_output=True, check=True, timeout=5).stdout)
    rows = re.findall(rb'^(not )?ok (\d+) - (.*)$', raw, re.M)
    assert parsed['run'] == parsed['planned'] == 15
    assert not parsed['failed'] and not parsed['errors']
    assert [int(row[1]) for row in rows] == list(range(1, 16))
    assert not re.search(rb'^\s*not ok\b', raw, re.M)
    assert result['returncode'] == result['native_wait_status'] == 0
    assert result['released'] is True and result['leader_reaped'] is True
    assert result['timeout'] is False
    return parsed


def validate_native(preparation, candidate, identity, archive):
    prepared = preparation['prepared']
    assert prepared['ok'] == 1 and prepared['implementation'] == 'native'
    assert prepared['selection_reason'] == 'darwin_arm64_command_line_tools'
    compiler = prepared['compilation']
    assert compiler['ok'] == 1 and compiler['exit_code'] == compiler['signal'] == 0
    assert compiler['timeout_seconds'] == 10 and compiler['capture_limit_bytes'] == 4096
    assert compiler['cleanup']['leader_started'] == compiler['cleanup']['leader_reaped'] == compiler['cleanup']['group_gone'] == 1
    assert not compiler['timed_out'] and not compiler['output_limited']
    assert candidate['target_role'] == 'rust-proxy'
    assert candidate['ancestor'] == identity
    assert candidate['child']['ppid'] == candidate['parent']['pid']
    assert candidate['parent']['ppid'] == identity['pid']
    assert candidate['fixture'] == prepared['executable']
    observed = {item['path']: item for item in candidate['sources']}
    assert len(prepared['sources']) == 2 and len(observed) == 3
    for item in prepared['sources']:
        assert observed[item['path']] == item
        body = archive(item['sha256'])
        assert pin(body) == {'bytes': item['size_bytes'], 'sha256': item['sha256']}
    binary = observed[prepared['executable']]
    assert candidate['fixture_sha256'] == binary['sha256']
    body = archive(binary['sha256'])
    assert struct.unpack('<IIII', body[:16]) == (0xfeedfacf, 0x0100000c, 0, 2)
    return {'mode': preparation['mode'], 'child': candidate['child'],
            'parent': candidate['parent'], 'sources': prepared['sources'],
            'prepared_to_observed_identity': 'exact_path_device_inode_size_sha256',
            'loaded_image_attestation': 'not_provided'}


def validate_policy(collector, raw):
    assert collector['schema'] == 'fsmgen.fixture_policy_log.v1'
    assert collector['scope'] == 'daemon_context'
    assert collector['command'] == ['/usr/bin/log', 'stream', '--style', 'ndjson',
        '--level', 'debug', '--timeout', '240', '--predicate', 'process == "syspolicyd"']
    assert collector['leader_reaped'] is True and collector['returncode'] == 0
    assert not collector['forced_kill'] and not collector['failures']
    manifest = collector['outputs']['stdout']
    assert pin(raw) == {'bytes': manifest['bytes'], 'sha256': manifest['sha256']}
    assert manifest['hash_complete'] is True and manifest['path_identity_matches'] is True
    lines = raw.splitlines(keepends=True)
    assert lines[0].rstrip() == b'Filtering the log data using "process == "syspolicyd""'
    rows = []
    for number, line in enumerate(lines[1:], 2):
        if line.strip():
            row = json.loads(line)
            assert isinstance(row, dict)
            rows.append((number, line, row))
    return rows


assert os.environ.get('FSMGEN_RAM_GUARD_ACTIVE') == '1'
plan = load(DURABLE / 'admission.json')
outcome = load(CAPSULE / 'outcome.json')
directory = ROOT / outcome['evidence_directory']
assert directory.parent == ROOT / '.artifacts/logs/t1669-startup-observation'
assert re.fullmatch(r'run-[0-9a-f]{32}', directory.name)
result = load(directory / 'test-result.json')
identity = load(CAPSULE / 'original-identity.json')
assert result == load(CAPSULE / 'original-result.json') == outcome['original']
assert result['pid'] == identity['pid']
assert outcome['cli_status'] == 0 and not outcome['errors']
assert outcome['constructor_attempts'] == outcome['release_attempts'] == 1
assert outcome['inputs_unchanged'] and outcome['original_birth_absent']
assert not any(outcome['fixture_census_after'].values())
tap = read(directory / 'test.tap')
tap_result = validate_tap(tap, result)
stderr = read(directory / 'test.stderr')
preparations = [json.loads(line.split('Rust proxy preparation: ', 1)[1])
                for line in stderr.decode().splitlines() if 'Rust proxy preparation: ' in line]
assert [row['mode'] for row in preparations] == ['proxy_nonzero', 'proxy_decoy']
assert len(stderr.decode().splitlines()) == len(preparations)
journal = [json.loads(line) for line in read(directory / 'observations.jsonl').splitlines()]
candidates = [row['evidence'] for row in journal if row['event'] == 'candidate']
assert len(candidates) == 8 and journal[-1]['event'] == 'caller_complete'
assert journal[-1]['result'] == result and journal[-1]['scope'] == 'daemon_context'
assert not (directory / 'failure.json').exists()
native_candidates = [row for row in candidates if row['target_role'] == 'rust-proxy']
assert len(native_candidates) == 2
archive = lambda digest: read(directory / (digest + '.source'), 65536)
joins = [validate_native(prepared, next(row for row in native_candidates
         if row['fixture'] == prepared['prepared']['executable']), identity, archive)
         for prepared in preparations]
all_sources = {}
for candidate in candidates:
    for source in candidate['sources']:
        assert source['path'] not in all_sources or all_sources[source['path']] == source
        all_sources[source['path']] = source
        assert pin(archive(source['sha256'])) == {'bytes': source['size_bytes'], 'sha256': source['sha256']}
        assert not (ROOT / source['path']).exists()
for relative, expected in plan['source_pins'].items():
    assert pin(read(ROOT / relative)) == expected
    raw = subprocess.check_output(['git', 'show', plan['source_revision'] + ':' + relative], cwd=ROOT, timeout=5)
    assert pin(raw) == expected
for relative in outcome['fixture_census_after']:
    assert not any((ROOT / relative).iterdir())
collector = load(directory / 'policy-result.json')
policy_raw = read(directory / 'policy.stdout')
policy_rows = validate_policy(collector, policy_raw)
assert collector['capture_root_sha256'] == hashlib.sha256(str(ROOT).encode()).hexdigest()
for channel in ('stdout', 'stderr'):
    manifest = collector['outputs'][channel]
    assert manifest['path'] == str((directory / ('policy.' + channel)).relative_to(ROOT))
    assert pin(read(ROOT / manifest['path'])) == {'bytes': manifest['bytes'], 'sha256': manifest['sha256']}
settled = load(directory / 'fixture-result.json')
assert settled == {'observed_fixture_count': 8, 'observed_fixtures_gone': True, 'unobserved_descendants': 'unknown'}
native = sampler.NativeProcesses()
identities = [identity, collector['identity']] + [item['child'] for item in candidates]
for old in identities:
    try:
        current = native.identity(old['pid'])
    except (ProcessLookupError, FileNotFoundError):
        current = None
    assert current is None or any(current[key] != old[key] for key in sampler.IDENTITY_FIELDS)

# Literal same-row path/token evidence only; no native path-hash calibration is implied.
policy_joins = []
for joined in joins:
    path = next(item['path'] for item in joined['sources'] if not item['path'].endswith('.c'))
    literal = str(ROOT / path)
    matching = [(n, raw, row) for n, raw, row in policy_rows
                if literal in row.get('eventMessage', '') and 'PST: (path: ' in row['eventMessage']]
    assert len(matching) == 1
    n, raw, row = matching[0]
    tokens = re.findall(r'PST: \(path: ([0-9a-f]{1,16})\)', row['eventMessage'])
    assert len(tokens) == 1
    token = tokens[0].zfill(16)
    phases = {}
    for prefix, phase in [('queueing up scan', 'queued'), ('starting work for scan', 'started'),
                          ('scan finished, waking', 'wakeups')]:
        found = [(num, line, event) for num, line, event in policy_rows
                 if event.get('eventMessage', '').startswith(prefix)
                 and token in re.findall(r'PST: \(path: ([0-9a-f]{16})\)', event['eventMessage'])]
        assert len(found) == 1
        num, line, event = found[0]
        phases[phase] = {'line': num, 'raw_line': pin(line), 'timestamp': event['timestamp']}
    policy_joins.append({'mode': joined['mode'], 'path': path, 'token': token,
        'literal_join_line': n, 'literal_join_raw_line': pin(raw), 'phases': phases,
        'join_kind': 'same_run_literal_path_token', 'calibration_publication': 'not_selected'})

rejected = []
def rejects(label, operation):
    try:
        operation()
    except AssertionError:
        rejected.append(label)
    else:
        raise AssertionError('retained mutation accepted: ' + label)

for field, value in [('returncode', 1), ('native_wait_status', 256), ('leader_reaped', False)]:
    changed = copy.deepcopy(result); changed[field] = value
    rejects(field, lambda: validate_tap(tap, changed))
rejects('missing_tap_plan', lambda: validate_tap(re.sub(rb'^1\.\.15\n', b'', tap, flags=re.M), result))
changed = copy.deepcopy(preparations[0]); changed['prepared']['sources'][0]['inode'] += 1
rejects('preparation_inode', lambda: validate_native(changed, native_candidates[0], identity, archive))
changed = copy.deepcopy(native_candidates[0]); changed['ancestor']['start_usec'] += 1
rejects('original_birth_join', lambda: validate_native(preparations[0], changed, identity, archive))
rejects('archived_bytes', lambda: validate_native(preparations[0], native_candidates[0], identity,
    lambda digest: archive(digest) + b'changed'))
changed = copy.deepcopy(collector); changed['command'][-1] = 'process == "other"'
rejects('collector_command', lambda: validate_policy(changed, policy_raw))
rejects('policy_bytes', lambda: validate_policy(collector, policy_raw + b' '))

report = {'schema': 'fsmgen.native_proxy_daemon_original_audit.v1',
    'admission_commit': '5a6a6cc8fc55be97a5f846f88e7beeddf5fbea35',
    'evidence_directory': outcome['evidence_directory'], 'original_identity': identity,
    'original_result': result, 'tap_parser': tap_result, 'tap': pin(tap), 'stderr': pin(stderr),
    'source_pin_count': len(plan['source_pins']), 'prepared_native_joins': joins,
    'observed_fixture_count': len(candidates), 'independently_absent_identities': identities,
    'fixture_roots_empty': True, 'archived_source_paths': len(all_sources),
    'archived_source_digests': len({item['sha256'] for item in all_sources.values()}),
    'collector_result': collector, 'retained_policy_rows': len(policy_rows),
    'retained_log_events': sum(row.get('eventType') == 'logEvent' for _, _, row in policy_rows),
    'retained_nonlog_rows': sum(row.get('eventType') != 'logEvent' for _, _, row in policy_rows),
    'policy_native_joins': policy_joins, 'rejected_retained_mutations': rejected,
    'original_reexecuted': False, 'collector_reexecuted': False,
    'limits': {'startup_causal_repair': 'unproved', 'kernel_sample': 'not_collected',
               'complete_policy_delivery': 'unproved', 'loaded_image_attestation': 'not_provided',
               'host_isolation': 'unproved', 'unobserved_descendants': 'unknown',
               'policy_raw_durability': 'private ignored raw stream; pinned availability gap'}}
encoded = (json.dumps(report, sort_keys=True, indent=2) + '\n').encode()
with (CAPSULE / 'independent-audit.json').open('xb') as stream:
    stream.write(encoded)
print(json.dumps({'audit': pin(encoded), 'tap_roots': tap_result['run'],
    'native_preparation_joins': len(joins), 'absent_identities': len(identities),
    'policy_rows': len(policy_rows), 'rejected_controls': rejected}, sort_keys=True))
