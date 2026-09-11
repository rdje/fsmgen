"""Authenticated tracked inputs and isolated saved-oracle loading for the join."""
from __future__ import annotations

import builtins
from contextlib import contextmanager
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-final-join-20260911'
REVISION = '6e6eab4442f4c08714edbea003e5ba7406640a09'
INVENTORY = 'docs/audits/native-proxy-observation-archive-inventory-20260911'
SAFE_PATH = 'docs/audits/native-proxy-observation-archive-close-join-20260911/inventory.py'
_spec = importlib.util.spec_from_file_location('final_archive_safe_reads', ROOT / SAFE_PATH)
SAFE = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(SAFE)
read, historical = SAFE.read, SAFE.historical


def digest(raw):
    return dict(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def document(path):
    return json.loads(read(path)[0])


def authenticate(plan):
    assert plan['source_revision'] == REVISION and plan['inventory'] == INVENTORY
    assert plan['input_limits'] == dict(files=1024, file_bytes=33554432, total_bytes=536870912)
    package = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION, '--', INVENTORY], cwd=ROOT).decode().splitlines()
    assert package
    for path in package:
        assert read(path)[0] == historical(REVISION, path)
    previous = document(INVENTORY + '/plan.json')
    observed = document(INVENTORY + '/result/inventory.json')
    audit = document(INVENTORY + '/result/audit.json')
    assert audit['success'] is True and audit['source_semantics_join_pending'] is True
    assert observed['source_revision'] == previous['source_revision']
    paths = sorted(set(package) | {row['path'] for row in observed['inputs']})
    assert len(paths) <= plan['input_limits']['files']
    originals = {row['path']: row for row in observed['inputs']}
    records = []
    for path in paths:
        raw, identity = read(path, plan['input_limits']['file_bytes'])
        assert raw == historical(REVISION, path)
        if path in originals:
            assert digest(raw) == {key: originals[path][key] for key in ('size_bytes', 'sha256')}
            assert raw == historical(previous['source_revision'], path)
        records.append(dict(path=path, **identity))
    assert sum(row['size_bytes'] for row in records) <= plan['input_limits']['total_bytes']
    assert audit['domains'] == len(previous['domains']) == len(observed['domains'])
    assert audit['source_files'] == len(originals) and audit['source_bytes'] == observed['total_bytes']
    assert plan['domain_order'] + plan['support_order'] != []
    assert set(plan['domain_order'] + plan['support_order']) == {row['name'] for row in previous['domains']}
    assert len(plan['domain_order'] + plan['support_order']) == len(previous['domains'])
    return previous, observed, records


def load_file(path, label):
    specification = importlib.util.spec_from_file_location(label, ROOT / path)
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


def load_oracle(base, label):
    """Bind a package-local inventory import without leaking its global name."""
    sentinel = object(); previous = sys.modules.get('inventory', sentinel)
    inventory_path = ROOT / base / 'inventory.py'
    try:
        if inventory_path.is_file():
            sys.modules['inventory'] = load_file(base + '/inventory.py', label + '_inventory')
        return load_file(base + '/audit.py', label)
    finally:
        if previous is sentinel:
            sys.modules.pop('inventory', None)
        else:
            sys.modules['inventory'] = previous


@contextmanager
def saved_only():
    """Legacy ignored content is unavailable; metadata absence checks are allowed."""
    original_builtin, original_io = builtins.open, io.open
    def wrap(original):
        def call(path, *args, **kwargs):
            if isinstance(path, (str, bytes, Path)):
                candidate = Path(path).absolute()
                if candidate.is_relative_to(ROOT / '.artifacts') and not candidate.is_relative_to(LOG):
                    raise AssertionError('historical ignored content is forbidden')
            return original(path, *args, **kwargs)
        return call
    builtins.open, io.open = wrap(original_builtin), wrap(original_io)
    try:
        yield
    finally:
        builtins.open, io.open = original_builtin, original_io


def own_pins():
    pins = document(str((BASE / 'preflight-pins.json').relative_to(ROOT)))
    assert [pin['path'] for pin in pins] == [str((BASE / name).relative_to(ROOT)) for name in
                                           ['plan.json', 'replay-preservation-scope.json', 'evidence.py', 'replay.py', 'join.py', 'audit.py']]
    for pin in pins:
        assert digest(read(pin['path'])[0]) == {key: pin[key] for key in ('size_bytes', 'sha256')}
    return pins
