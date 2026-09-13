"""Reproduce an inherited terminal-before-admission recovery gap with no process."""
import hashlib
import json
from pathlib import Path
import sys
import traceback
from unittest.mock import patch

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PRIOR = BASE.parent / 'native-proxy-language-coordination-admission-20260913'
sys.path.insert(0, str(PRIOR))
import qualify_runtime_data as model


def reproduce():
    # Reuse only the prior qualification's in-memory pipe and process doubles.
    # The child is already terminal; its streams still need bounded draining.
    worker = model.make_worker([(3, b'failed before ready\n'), (3, b''), (4, b'')])
    worker.native = None
    calls = []

    def forbidden(*args, **kwargs):
        calls.append('unadmitted OS operation')
        raise AssertionError('a recovery model attempted an actual OS operation')

    failure = None
    frames = []
    with patch.object(model.runtime.subprocess, 'Popen', forbidden), \
         patch.object(model.runtime.os, 'killpg', forbidden), \
         patch.object(model.runtime.os, 'kill', forbidden), \
         patch.object(model.runtime.os, 'read', forbidden), \
         patch.object(model.runtime.os, 'close', forbidden):
        try:
            worker.recover()
        except ValueError as error:
            failure = str(error)
            frames = [dict(path=str(Path(f.filename).resolve().relative_to(ROOT)),
                           line=f.lineno, function=f.name) for f in traceback.extract_tb(error.__traceback__)]
    assert failure == 'refusing to signal a worker without admitted native ownership'
    assert calls == [] and worker.process.poll() == 0
    assert worker.closed is False and worker.reaped is False
    assert worker.selector.active == {3, 4} and len(worker.selector.chunks) == 3
    assert worker.buffers == dict(stdout=bytearray(), stderr=bytearray())
    sources = []
    for name in ['runtime.py', 'qualify_runtime_data.py']:
        path = PRIOR / name
        raw = path.read_bytes()
        sources.append(dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw),
                            sha256=hashlib.sha256(raw).hexdigest()))
    return dict(defect_reproduced=True, scope='In-memory terminal child before native admission, with undrained pipes.',
                failure=failure, frames=frames, sources=sources, actual_os_operations=calls,
                worker_invocations=0, fixture_allocations=0, compiler_invocations=0,
                terminal_model_child=True, native_identity_admitted=False,
                recovery_complete=False, pending_model_streams=2, pending_model_chunks=3,
                historical_actual_runs_reclassified=False,
                required_resolution='The fresh populated controller must consume terminal output and its failed outcome without first requiring a signal or promoting native admission.')


if __name__ == '__main__':
    print(json.dumps(reproduce(), sort_keys=True))
