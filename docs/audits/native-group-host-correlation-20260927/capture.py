#!/usr/bin/env python3
"""Capture one bounded, read-only host-log correlation; no test execution."""
import json
import os
from pathlib import Path
import selectors
import subprocess
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
WORK = ROOT / '.artifacts/native-group-host-correlation'
WORK.mkdir(exist_ok=False)
window = json.loads((HERE / 'window.json').read_bytes())
command = ['/usr/bin/log', 'show', '--style', 'json', '--info', '--debug',
           '--start', '@' + str(window['window_start_unix']),
           '--end', '@' + str(window['window_end_unix']), '--timezone', 'UTC',
           '--predicate', 'processID == 43538 OR eventMessage CONTAINS[c] "setpgid" '
                          'OR eventMessage CONTAINS "43538"']
environment = dict(os.environ, TMPDIR=str(ROOT / '.artifacts/tmp'))
process = subprocess.Popen(command, cwd=ROOT, env=environment,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
selector = selectors.DefaultSelector()
for name, stream in [('stdout', process.stdout), ('stderr', process.stderr)]:
    selector.register(stream, selectors.EVENT_READ, name)
buffers = {'stdout': bytearray(), 'stderr': bytearray()}
deadline = time.monotonic() + 30
failure = None
try:
    while selector.get_map():
        if time.monotonic() >= deadline:
            failure = 'query deadline exceeded'
            break
        for key, _ in selector.select(timeout=min(0.1, max(0, deadline - time.monotonic()))):
            data = os.read(key.fd, 65536)
            if not data:
                selector.unregister(key.fileobj)
                key.fileobj.close()
                continue
            if sum(map(len, buffers.values())) + len(data) > 1_048_576:
                failure = 'query capture envelope exceeded'
                break
            buffers[key.data].extend(data)
        if failure:
            break
    if failure:
        process.terminate()
    try:
        status = process.wait(timeout=2)
    except subprocess.TimeoutExpired:
        process.kill()
        status = process.wait(timeout=2)
        failure = failure or 'query exit deadline exceeded'
finally:
    selector.close()
    for stream in (process.stdout, process.stderr):
        stream.close()
for name, data in buffers.items():
    (WORK / (name + '.txt')).write_bytes(data)
result = {'schema': 'fsmgen.native_group_host_query.v1', 'command': command,
          'exit_code': status, 'capture_failure': failure,
          'deadline_seconds': 30, 'capture_limit_bytes': 1_048_576,
          'os_release': os.uname().release, 'kernel_version': os.uname().version,
          'scope': 'read-only bounded existing host evidence; no native test replay'}
(WORK / 'result.json').write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
print(json.dumps({'exit_code': status, 'capture_failure': failure,
                  'stdout_bytes': len(buffers['stdout']), 'stderr_bytes': len(buffers['stderr'])}))
