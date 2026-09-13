"""Small bounded worker protocol shared only by the Python peer and probe."""

import json
import os

MAX_EVENT_BYTES = 4096
MAX_COMMAND_BYTES = 32


def emit(event, **fields):
    body = (json.dumps(dict(event=event, pid=os.getpid(), **fields),
                       sort_keys=True, separators=(',', ':')) + '\n').encode()
    if len(body) > MAX_EVENT_BYTES:
        raise ValueError('worker event exceeds bound')
    offset = 0
    while offset < len(body):
        count = os.write(1, body[offset:])
        if count <= 0:
            raise OSError('worker event write made no progress')
        offset += count


def command(expected):
    # Do not buffer the next command: the exec probe temporarily owns this pipe.
    body = bytearray()
    while len(body) < MAX_COMMAND_BYTES:
        byte = os.read(0, 1)
        if not byte:
            raise EOFError('controller command pipe closed')
        body.extend(byte)
        if byte == b'\n':
            if body != expected.encode() + b'\n':
                raise ValueError('unexpected controller command')
            return
    raise ValueError('controller command exceeds bound')
