#!/usr/bin/env python3
"""Bounded current diagnosis; preserve the original incomplete source capture."""
import datetime
import gzip
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
os.chdir(ROOT)
OUTPUT = Path('docs/audits/library-source-interruption-20261022.json.gz')
RECIPE = 'docs/audits/library-source-interruption-20261022.py'
SOURCE = '.artifacts/library-source-retention-qualified-20261022/defaults.isf'
TRACE = '.artifacts/library-source-defaults-diagnostic-20261022.trace'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def run(argv, timeout):
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    t0 = time.monotonic_ns()
    process = subprocess.Popen(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    launched = time.monotonic_ns()
    try:
        stdout, stderr = process.communicate(timeout=timeout)
        status = process.returncode
    except subprocess.TimeoutExpired:
        process.kill()
        stdout, stderr = process.communicate()
        status = 'timeout'
    return {'argv': argv, 'bound_seconds': timeout, 'started_utc': started,
            'ended_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'launch_elapsed_ns': launched - t0, 'elapsed_ns': time.monotonic_ns() - t0,
            'pid': process.pid, 'exit': status, 'reaped_returncode': process.returncode,
            **{key: {'text': data.decode().replace(str(ROOT), '<repo>'),
                     'raw_sha256': sha(data), 'raw_bytes': len(data)}
               for key, data in (('stdout', stdout), ('stderr', stderr))}}


def main():
    paths = (RECIPE, 'perl/FSM/Adapter/ISF/Parser.pm', SOURCE,
             'docs/audits/library-source-retention-after-20261022.json.gz',
             '.artifacts/library-source-retention-after.log')
    record = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.1.2.3.1', 'schema_version': 1,
              'inputs': {path: {'sha256': sha(Path(path).read_bytes())} for path in paths},
              'recipe': Path(RECIPE).read_text(), 'results': {},
              'limits': 'Current bounded source-only diagnosis, not a reconstructed historical environment. No HDL or historical HIAL execution. OS power output is read-only; only sleep/wake events are retained. Captured elapsed values are individual observations, not a latency distribution or capacity claim. Full transitive producer footprint and original timed-out partial streams remain unavailable.'}
    try:
        for label, argv, bound in (
            ('clock', ['/bin/date', '-u', '+%Y-%m-%dT%H:%M:%SZ'], 10),
            ('control_before', ['/bin/echo', 'independent-process-control'], 10),
            ('timeout_control', ['python3', '-c', 'import sys,time; print("before-timeout",flush=True); print("timeout-stderr",file=sys.stderr,flush=True); time.sleep(2)'], 1),
            ('native_diagnostic', ['perl', 'bin/fsmgen', '--quiet', '--strict', '--trace-verbosity=debug',
                                   '--trace-log=' + TRACE, '--emit-schedule-json', SOURCE], 60),
            ('control_after', ['/bin/echo', 'independent-process-control'], 10),
        ):
            print('observing', label, flush=True)
            record['results'][label] = run(argv, bound)
        control = record['results']['timeout_control']
        if control['exit'] != 'timeout' or control['stdout']['text'] != 'before-timeout\n' or control['stderr']['text'] != 'timeout-stderr\n':
            raise ValueError('timeout stream/reaping control failed')
        if any(record['results'][name]['exit'] != 0 for name in ('clock', 'control_before', 'control_after')):
            raise ValueError('independent process control refused or timed out')
        if record['results']['native_diagnostic']['exit'] != 0:
            raise ValueError('native diagnostic failed; inspect its complete streams and trace')
        record['current_observation_passed'] = True
    except BaseException as error:
        record['error'] = str(error).replace(str(ROOT), '<repo>')
        raise
    finally:
        if Path(TRACE).exists():
            raw = Path(TRACE).read_bytes()
            record['trace'] = {'text': raw.decode().replace(str(ROOT), '<repo>'), 'raw_sha256': sha(raw), 'raw_bytes': len(raw)}
        with OUTPUT.open('xb') as stream:
            with gzip.GzipFile(fileobj=stream, mode='wb', mtime=0) as compressed:
                compressed.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('current interruption diagnosis recorded; historical cause remains open')


if __name__ == '__main__':
    main()
