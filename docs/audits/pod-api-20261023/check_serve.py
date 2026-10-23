#!/usr/bin/env python3
"""Bounded live watcher probe; restore the exact stylesheet in a finally block."""
import hashlib
import json
from pathlib import Path
import sys
import time
from urllib.request import urlopen

root = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == root
assert len(sys.argv) == 2 and sys.argv[1].isdigit(), 'Usage: check_serve.py LOOPBACK_PORT'
base = 'http://127.0.0.1:' + sys.argv[1]
style = root / 'docs/pod-reference.css'
log = root / '.artifacts/pod-api/native-serve.log'
original = style.read_bytes()
changed = original + b'\n/* POD_API_WATCH_PROBE: source change must reach native served assets. */\n'


def count():
    return log.read_text().count('Book building has started')


def wait_for(expected):
    deadline = time.monotonic() + 25
    while time.monotonic() < deadline:
        try:
            with urlopen(base + '/perl-api/reference.css', timeout=2) as response:
                if response.read() == expected:
                    return
        except OSError:
            pass
        time.sleep(.25)
    raise AssertionError('Native served stylesheet did not refresh')


wait_for(original)
before = count()
try:
    style.write_bytes(changed)
    wait_for(changed)
    after_change = count()
    assert after_change > before
finally:
    style.write_bytes(original)
wait_for(original)
after_restore = count()
time.sleep(4)
idle = count()
assert after_restore > after_change and idle == after_restore, 'Unexpected self-triggered rebuild'
assert style.read_bytes() == original
print(json.dumps({'loopback_port': int(sys.argv[1]), 'builds_before': before,
                  'builds_after_source_change': after_change, 'builds_after_restore': after_restore,
                  'builds_after_idle_observation': idle, 'idle_observation_seconds': 4,
                  'original_style_sha256': hashlib.sha256(original).hexdigest(),
                  'source_change_reached_served_asset': True, 'exact_source_restored': True}, indent=2))
