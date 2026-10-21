"""Qualify the diagnostic's physical leaf gate without real invalid-path I/O."""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
from types import SimpleNamespace

import diagnose_allocation_data_sources as diagnostic

AUDIT, ROOT = diagnostic.AUDIT, diagnostic.ROOT
SELF = AUDIT / 'qualify_allocation_data_source_guard.py'
BEFORE = AUDIT / 'allocation-data-physical-read-first-control.json.gz'
OUTPUT = AUDIT / 'allocation-data-physical-read-guard-qualified.json.gz'
FIRST_DATA = AUDIT / 'allocation-data-source-diagnosis.json.gz'
FIRST_SOURCE = AUDIT / 'diagnose_allocation_data_sources.first.py.source'
CASES = ('regular', 'non-file', 'symlink', 'foreign-volume')
SCOPE = ('Controlled Path-interface metadata and a native source-byte fixture. '
         'No real symlink/foreign-volume access, qualifier, audit reader or historical '
         'programme executes. Before cases stub the qualifier and runpy target; '
         'after cases call only the physical source gate. This qualifies current '
         'rejection-before-read behavior, not unobserved first-run leaf/device custody.')


class Probe:
    def __init__(self, case, body):
        self.case, self.body, self.reads = case, body, 0

    def is_file(self):
        return self.case != 'non-file'

    def is_symlink(self):
        return self.case == 'symlink'

    def stat(self):
        return SimpleNamespace(st_dev=ROOT.stat().st_dev + (self.case == 'foreign-volume'))

    def read_bytes(self):
        self.reads += 1
        return self.body


def probe(case, *, before):
    native = diagnostic.epoch.read(diagnostic.BASE, diagnostic.TARGET)
    path = Probe(case, native)
    previous_safe = diagnostic.execute.safe
    previous_qualify = diagnostic.qualifier.qualify
    previous_runpy = diagnostic.qualifier.runpy.run_path

    def supplied(name):
        return path if Path(name) == ROOT / diagnostic.TARGET else previous_safe(name)

    def target_stub(*args, **kwargs):
        return dict(control_stub=True)

    def qualifier_stub():
        return diagnostic.qualifier.runpy.run_path(diagnostic.TARGET, run_name='__main__')

    try:
        diagnostic.execute.safe = supplied
        if before:
            diagnostic.qualifier.qualify = qualifier_stub
            diagnostic.qualifier.runpy.run_path = target_stub
            value, calls = diagnostic.product()
            diagnostic.equal(value, dict(control_stub=True))
            assert len(calls) == 1
            accepted, error = True, None
        else:
            try:
                result = diagnostic.physical_source(diagnostic.TARGET)
            except AssertionError as failure:
                accepted, error = False, str(failure)
            else:
                diagnostic.equal(result, native)
                accepted, error = True, None
    finally:
        diagnostic.execute.safe = previous_safe
        diagnostic.qualifier.qualify = previous_qualify
        diagnostic.qualifier.runpy.run_path = previous_runpy
    expected = before or case == 'regular'
    assert accepted is expected
    assert path.reads == (1 if expected else 0), 'invalid leaf must refuse before reading bytes'
    return dict(case=case, accepted=accepted, reads=path.reads, error=error,
                source_identity=diagnostic.prepare.identity(native), real_invalid_path_io=False)


def first():
    raw = diagnostic.execute.read(BEFORE)
    value = json.loads(gzip.decompress(raw))
    source = diagnostic.execute.read(FIRST_SOURCE)
    diagnostic.equal(value['first_source'], diagnostic.prepare.blob(source))
    data = diagnostic.execute.read(FIRST_DATA)
    diagnostic.equal(value['first_data'], diagnostic.prepare.identity(data))
    original = json.loads(gzip.decompress(data))
    diagnostic.equal(diagnostic.unpack(original['programmes'][diagnostic.SELF]), source)
    assert [row['case'] for row in value['cases']] == list(CASES)
    for row in value['cases']:
        assert row['accepted'] is True and row['reads'] == 1 and row['real_invalid_path_io'] is False
    return diagnostic.prepare.blob(raw)


def derive():
    return dict(schema='fsmgen.allocation_data_physical_source_guard.v1', scope=SCOPE,
        first_control=first(), cases=[probe(case, before=False) for case in CASES],
        programmes={str(path): diagnostic.prepare.blob(diagnostic.execute.read(path))
                    for path in (SELF, AUDIT / diagnostic.SELF)})


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--before', action='store_true')
    modes.add_argument('--write', action='store_true')
    args = parser.parse_args()
    if args.before:
        data = diagnostic.execute.read(FIRST_DATA)
        original = json.loads(gzip.decompress(data))
        source = diagnostic.execute.read(AUDIT / diagnostic.SELF)
        diagnostic.equal(diagnostic.unpack(original['programmes'][diagnostic.SELF]), source)
        value = dict(schema='fsmgen.allocation_data_physical_source_first_control.v1', scope=SCOPE,
            first_data=diagnostic.prepare.identity(data), first_source=diagnostic.prepare.blob(source),
            cases=[probe(case, before=True) for case in CASES],
            programme=diagnostic.prepare.blob(diagnostic.execute.read(SELF)))
        with diagnostic.execute.safe(FIRST_SOURCE).open('xb') as stream:
            stream.write(source)
            stream.flush()
            os.fsync(stream.fileno())
        diagnostic.execute.save(BEFORE, value)
        print('Controlled pre-fix Path metadata reaches a byte read for invalid leaves; no real invalid-path I/O or reader execution occurs. Complete first source/data retain.')
    else:
        value = derive()
        if args.write:
            diagnostic.execute.save(OUTPUT, value)
        else:
            diagnostic.equal(json.loads(gzip.decompress(diagnostic.execute.read(OUTPUT))), value)
        print('Regular native source reads pass; non-file, symlink and foreign-volume controls refuse before reading. Complete first producer/data remain unchanged.')
