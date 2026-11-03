#!/usr/bin/env python3
"""Classify native test failure lines and verify the retained full13 boundary."""
from pathlib import Path
import gzip
import hashlib
import json
import re


_FAILURE_LINE = re.compile(
    r'^[ \t]*(?:not ok\b|#[ \t]+Failed (?:test|[0-9]+ tests?)\b|Dubious,)'
)


def failure_diagnostic_lines(text):
    """Retain complete diagnostic lines, including their original indentation."""
    return [line for line in text.splitlines() if _FAILURE_LINE.match(line)]


def verify_saved():
    root = Path(__file__).resolve().parents[3]
    base = root / 'docs/audits/push-readiness-20261025'
    receipt = json.loads((base / 'local-full-ci-13.json').read_text())
    assert receipt['log'] == 'docs/audits/push-readiness-20261025/local-full-ci-13.log.gz'
    raw = gzip.decompress((root / receipt['log']).read_bytes())
    assert hashlib.sha256(raw).hexdigest() == receipt['retained_log_sha256']
    expected = [
        "    #   Failed test 'mixed read-data burst-last report-only burst-length --verify-hdl succeeds'",
        "    #   Failed test 'mixed read-data burst-last report-only burst-length --verify-hdl keeps stderr clean'",
        "#   Failed test 'CLI emits IAL2 report JSON for mixed auto-ID and same-ID queue-head read-data .ppif'",
    ]
    actual = failure_diagnostic_lines(raw.decode())
    if actual != expected:
        raise AssertionError(f'native failed-body coverage differs: {actual!r}')

    intake = json.loads(gzip.decompress(
        (base / 'full13-outcome-intake-20261103.json.gz').read_bytes()
    ))
    samples = intake['monitor_missed_samples']
    assert samples and all(row['reported_failure'] is False for row in samples)
    for sample in samples:
        assert failure_diagnostic_lines(sample['tail']), sample['observed_utc']

    # These controls are independent of the native producer's formatting.
    positive = ['not ok 1 - case', '  not ok - case', '\t# Failed 2 tests', '  Dubious, test returned 1']
    assert failure_diagnostic_lines('\n'.join(positive)) == positive
    clean = [
        'ok 1 - message mentions not ok',
        '# note: Failed test is quoted in this description',
        "print('not ok')", 'not okay', 'All tests successful.',
        'Files=3, Tests=22', 'ordinary text # Failed test',
    ]
    assert failure_diagnostic_lines('\n'.join(clean)) == []
    first_failure = raw.decode().index(expected[0])
    assert failure_diagnostic_lines(raw.decode()[:first_failure]) == []
    print(json.dumps({
        'native_failure_lines': len(expected), 'missed_samples_detected': len(samples),
        'positive_controls': len(positive), 'clean_controls': len(clean),
        'scope': 'Saved log and pure classifier only; no native workload replay or full success.',
    }))


if __name__ == '__main__':
    verify_saved()
