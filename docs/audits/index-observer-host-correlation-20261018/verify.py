"""Replay retained correlation and hostile controls without querying host logs."""
from pathlib import Path
import copy
import gzip
import hashlib
import json
import math
import sys

if not __debug__:
    raise SystemExit('Verification assertions must be enabled.')

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
PRIOR = Path('docs/audits/task-acceptance-index-observer-20261017')
sys.path.insert(0, str(ROOT / PRIOR))
from verify_failure import validate_failure
from verify import unblob


def sha(body):
    return hashlib.sha256(body).hexdigest()


def validate(record, failed):
    assert validate_failure(failed)
    assert record['schema'] == 'fsmgen.index_observer_host_correlation.v1'
    assert record['visibility'] == 'host'
    assert record['source_sha256'] == sha((HERE / 'capture.py').read_bytes())
    assert record['failed_capture_sha256'] == sha((ROOT / PRIOR / 'controls.json.gz').read_bytes())
    span = record['window']
    assert set(span['anchors']) == {'control_retention_gap/ordinary-6828.json',
                                   'control_retention_gap/stage_k.json'}
    for name, row in span['anchors'].items():
        body = unblob(failed['captures'][name])
        assert row['sha256'] == sha(body) and row['bytes'] == len(body)
        assert 0 < row['birth_unix'] <= row['mtime_unix']
    assert span['start_unix'] == math.floor(min(row['birth_unix'] for row in span['anchors'].values())) - 2
    assert span['end_unix'] == math.ceil(max(row['mtime_unix'] for row in span['anchors'].values())) + 2
    assert 0 < span['end_unix'] - span['start_unix'] <= 10
    assert span['limit'] == 'Filesystem times supply a candidate window, not an exact syscall timestamp.'
    result = record['result']
    assert result['command'] == ['/usr/bin/log', 'show', '--style', 'json', '--info', '--debug',
        '--start', '@' + str(span['start_unix']), '--end', '@' + str(span['end_unix']),
        '--timezone', 'UTC', '--predicate',
        'processID == 6828 OR eventMessage CONTAINS[c] "setpgid" OR eventMessage CONTAINS "6828"']
    assert result['exit_code'] == 0 and result['capture_failure'] is None
    assert result['deadline_seconds'] == 15 and result['capture_limit_bytes'] == 262144
    assert result['stdout'] == '[]' and result['stderr'] == ''
    return True


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert manifest['schema'] == 'fsmgen.index_observer_host_correlation_manifest.v1'
    assert set(manifest['sha256']) == {'capture.py', 'verify.py', 'host.json'}
    for name, digest in manifest['sha256'].items():
        assert sha((HERE / name).read_bytes()) == digest
    for path, digest in manifest['dependency_sha256'].items():
        assert sha((ROOT / path).read_bytes()) == digest
    assert manifest['guard_preflight']['query_started'] is False
    assert manifest['guard_preflight']['exit_code'] == 2
    assert manifest['causal_attribution'] == 'unproved'
    failed = json.loads(gzip.decompress((ROOT / PRIOR / 'controls.json.gz').read_bytes()))
    record = json.loads((HERE / 'host.json').read_bytes())
    validate(record, failed)
    # These compete with the claimed evidence properties, rather than testing
    # the collector's own interpretation of an absent host message.
    for mutation in ('visibility', 'status', 'truncation', 'window', 'anchor', 'output', 'source'):
        candidate = copy.deepcopy(record)
        if mutation == 'visibility':
            candidate['visibility'] = 'sandbox'
        elif mutation == 'status':
            candidate['result']['exit_code'] = 1
        elif mutation == 'truncation':
            candidate['result']['capture_failure'] = 'capture limit exceeded'
        elif mutation == 'window':
            candidate['window']['end_unix'] += 1
        elif mutation == 'anchor':
            next(iter(candidate['window']['anchors'].values()))['sha256'] = '0' * 64
        elif mutation == 'output':
            candidate['result']['stdout'] = '[{"eventMessage":"setpgid denied"}]'
        else:
            candidate['source_sha256'] = '0' * 64
        try:
            validate(candidate, failed)
        except AssertionError:
            continue
        raise AssertionError('host correlation corruption admitted: ' + mutation)
    print('Saved PID6828 candidate window and bounded empty host query verify; native cause remains unproved.')


if __name__ == '__main__':
    main()
