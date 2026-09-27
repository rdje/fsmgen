#!/usr/bin/env python3
"""Verify saved host evidence and its visibility limits without querying logs."""
import copy
from datetime import datetime, timedelta, timezone
import hashlib
import json
import math
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent


def read(name):
    return json.loads((HERE / name).read_bytes())


def validate(window, query, stats, visibility, output, overview):
    assert window['failure_pid'] == 43538
    assert window['window_start_unix'] == math.floor(window['birthtime_seconds']) - 2
    assert window['window_end_unix'] == math.ceil(window['mtime_seconds']) + 2
    assert window['birthtime_seconds'] < window['mtime_seconds']
    start, end = '@' + str(window['window_start_unix']), '@' + str(window['window_end_unix'])
    assert query['command'] == ['/usr/bin/log', 'show', '--style', 'json', '--info', '--debug',
        '--start', start, '--end', end, '--timezone', 'UTC', '--predicate',
        'processID == 43538 OR eventMessage CONTAINS[c] "setpgid" OR eventMessage CONTAINS "43538"']
    assert query['exit_code'] == 0 and query['capture_failure'] is None
    assert query['deadline_seconds'] == 30 and query['capture_limit_bytes'] == 1_048_576
    assert output == []
    assert stats['command'] == ['/usr/bin/log', 'stats', '--overview', '--style', 'human',
        '--count', '1', '--start', start, '--end', end]
    assert stats['exit_code'] == 0 and stats['deadline_seconds'] == 30
    zone = timezone(timedelta(seconds=visibility['statistics_utc_offset_seconds']))
    shown_start = datetime.fromtimestamp(window['window_start_unix'], zone).strftime('%a %b %d %H:%M:%S %Y')
    assert 'start:              ' + shown_start in overview
    # Presence control only: no attempt to promote these host statistics to
    # product measurements or claim that every rejected syscall was logged.
    match = re.search(r'events:.*\n\s*\[\s*([\d\u202f]+)', overview)
    assert match and int(match[1].replace('\u202f', '')) > 0
    assert 'does not prove' in visibility['conclusion']


def main():
    manifest = read('manifest.json')
    assert manifest['schema'] == 'fsmgen.native_group_host_correlation.v1'
    expected = {'capture.py', 'statistics.py', 'statistics_human.py', 'verify.py',
                'window.json', 'visibility.json', 'original-failure.txt'}
    expected |= {label + '-' + name for label in ('query', 'statistics-json', 'statistics-human')
                 for name in ('result.json', 'stdout.txt', 'stderr.txt')}
    assert set(manifest['sha256']) == expected
    for name, digest in manifest['sha256'].items():
        assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == digest
    window, query = read('window.json'), read('query-result.json')
    assert window['sha256'] == manifest['sha256']['original-failure.txt']
    failure = (HERE / 'original-failure.txt').read_text()
    assert 'pid=43538 operation=setpgid result=undef errno=1 ' in failure
    assert 'Result: FAIL' in failure
    rejected = read('statistics-json-result.json')
    assert rejected['exit_code'] == 64
    assert (HERE / 'statistics-json-stderr.txt').read_text() == 'log: --count and --sort are ignored in JSON output style\n'
    assert (HERE / 'query-stderr.txt').read_bytes() == (HERE / 'statistics-human-stderr.txt').read_bytes() == b''
    args = [window, query, read('statistics-human-result.json'), read('visibility.json'),
            read('query-stdout.txt'), (HERE / 'statistics-human-stdout.txt').read_text()]
    validate(*args)
    for index, field, value in [(0, 'window_end_unix', 0), (1, 'exit_code', 1),
                                (1, 'capture_failure', 'truncated'), (2, 'exit_code', 64)]:
        changed = copy.deepcopy(args)
        changed[index][field] = value
        try:
            validate(*changed)
        except AssertionError:
            continue
        raise AssertionError('corrupt host correlation was accepted')
    print('Saved failure window, bounded host query and store-presence control verified; no causal attribution is supported.')


if __name__ == '__main__':
    main()
