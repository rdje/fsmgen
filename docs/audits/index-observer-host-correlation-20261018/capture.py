"""One bounded read-only log query for the retained PID6828 rejection."""
from pathlib import Path
import argparse
import gzip
import hashlib
import json
import math
import os
import selectors
import subprocess
import time

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
PRIOR = Path('docs/audits/task-acceptance-index-observer-20261017')
WORK = Path('.artifacts/task-acceptance-index-observer-20261017')
OUTPUT = Path('.artifacts/index-observer-host-correlation-20261018')
ANCHORS = ('control_retention_gap/ordinary-6828.json',
           'control_retention_gap/stage_k.json')


def sha(body):
    return hashlib.sha256(body).hexdigest()


def window():
    import sys
    sys.path.insert(0, str(ROOT / PRIOR))
    from verify import unblob
    record = json.loads(gzip.decompress((ROOT / PRIOR / 'controls.json.gz').read_bytes()))
    anchors = {}
    for name in ANCHORS:
        path = ROOT / WORK / name
        assert not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
        body = path.read_bytes()
        assert body == unblob(record['captures'][name]), 'original capture bytes changed'
        stat = path.stat()
        anchors[name] = {'sha256': sha(body), 'bytes': len(body),
                         'birth_unix': stat.st_birthtime, 'mtime_unix': stat.st_mtime}
    start = math.floor(min(row['birth_unix'] for row in anchors.values())) - 2
    end = math.ceil(max(row['mtime_unix'] for row in anchors.values())) + 2
    assert 0 < end - start <= 10, 'candidate window is not bounded'
    return {'anchors': anchors, 'start_unix': start, 'end_unix': end,
            'limit': 'Filesystem times supply a candidate window, not an exact syscall timestamp.'}


def query(command):
    environment = dict(os.environ, TMPDIR=str(ROOT / '.artifacts/tmp'))
    child = subprocess.Popen(command, cwd=ROOT, env=environment,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    streams = {'stdout': bytearray(), 'stderr': bytearray()}
    selector = selectors.DefaultSelector()
    for name, stream in (('stdout', child.stdout), ('stderr', child.stderr)):
        selector.register(stream, selectors.EVENT_READ, name)
    deadline, failure = time.monotonic() + 15, None
    try:
        while selector.get_map():
            if time.monotonic() >= deadline:
                failure = 'query deadline exceeded'
                break
            for key, _ in selector.select(timeout=0.1):
                data = os.read(key.fd, 65536)
                if not data:
                    selector.unregister(key.fileobj)
                    key.fileobj.close()
                elif sum(map(len, streams.values())) + len(data) > 262144:
                    failure = 'query capture limit exceeded'
                    break
                else:
                    streams[key.data].extend(data)
            if failure:
                break
    finally:
        selector.close()
        if child.poll() is None and failure:
            child.terminate()
        try:
            status = child.wait(timeout=2)
        except subprocess.TimeoutExpired:
            child.kill()
            status = child.wait(timeout=2)
            failure = failure or 'query exit deadline exceeded'
        for stream in (child.stdout, child.stderr):
            stream.close()
    return {'command': command, 'exit_code': status, 'capture_failure': failure,
            'deadline_seconds': 15, 'capture_limit_bytes': 262144,
            **{name: bytes(body).decode('utf-8') for name, body in streams.items()}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('visibility', choices=('sandbox', 'host'))
    args = parser.parse_args()
    assert Path.cwd().resolve() == ROOT
    output = ROOT / OUTPUT
    for parent in (output, *output.parents):
        if parent == ROOT:
            break
        assert not parent.is_symlink()
        if parent.exists():
            assert parent.is_dir() and parent.stat().st_dev == ROOT.stat().st_dev
    output.mkdir(exist_ok=True)
    # Exclusive admission precedes the query; a spent label is never replayed.
    with (output / (args.visibility + '-started')).open('xb') as stream:
        stream.write(b'Fixed read-only host query; no original native execution.\n')
    span = window()
    command = ['/usr/bin/log', 'show', '--style', 'json', '--info', '--debug',
               '--start', '@' + str(span['start_unix']), '--end', '@' + str(span['end_unix']),
               '--timezone', 'UTC', '--predicate',
               'processID == 6828 OR eventMessage CONTAINS[c] "setpgid" OR eventMessage CONTAINS "6828"']
    result = {'schema': 'fsmgen.index_observer_host_correlation.v1',
              'visibility': args.visibility, 'window': span,
              'source_sha256': sha(Path(__file__).read_bytes()),
              'failed_capture_sha256': sha((ROOT / PRIOR / 'controls.json.gz').read_bytes()),
              'log_tool_sha256': sha(Path('/usr/bin/log').read_bytes()),
              'result': query(command)}
    with (output / (args.visibility + '.json')).open('x') as stream:
        json.dump(result, stream, sort_keys=True, indent=2)
        stream.write('\n')
    print(json.dumps({'visibility': args.visibility, 'exit_code': result['result']['exit_code'],
                      'capture_failure': result['result']['capture_failure'],
                      'stdout': result['result']['stdout'], 'stderr': result['result']['stderr']}))


if __name__ == '__main__':
    main()
