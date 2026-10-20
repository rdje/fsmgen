"""Shared qualification for a reader's original programme-metadata role."""
import argparse
import contextlib
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

import bounded_runtime_inventory as bounded
import epoch_constraints as epoch
import execute
import prepare
import saved_reader_sources as source

ROOT, AUDIT = prepare.ROOT, execute.AUDIT
MODES = ('saved', 'current', 'assertions-disabled')
NORMALIZATION = 'Literal repository root becomes . in stderr; raw stderr SHA256 identifies the original stream.'
LIMITS = ('Original programme metadata only. The complete native original proof and its source-model '
          'premises, controls and limits retain. Actual saved/current/disabled-assertion CLI results '
          'qualify this target. Historical images are metadata, never executed source. Current/write '
          'selection and exclusive publication retain without recapturing the original proof. No '
          'stronger source/default/effects/custody/native/private/HIAL/full-CI or semantic/cohort '
          'permission follows. Previously admitted readers and qualifiers remain unchanged.')


def equal(left, right):
    return bounded.strict_equal(left, right)


def unblob(row):
    raw = prepare.unblob(row)
    equal(row, prepare.blob(raw))
    return raw


def outcome(action):
    try:
        action()
    except AssertionError as error:
        return dict(accepted=False, error=str(error))
    return dict(accepted=True, error=None)


class Qualification:
    """A repository-declared target; no CLI accepts arbitrary modules or paths."""

    def __init__(self, reader, qualifier, output, line, scope):
        self.reader = reader
        self.sources = (reader.SELF, 'saved_reader_sources.py', 'saved_source_roles.py', qualifier)
        assert len(set(self.sources)) == len(self.sources)
        for name in self.sources:
            source.source_name(name)
        assert type(reader.PREMISES) is tuple and len(set(reader.PREMISES)) == len(reader.PREMISES)
        assert reader.SELF in reader.PREMISES and 'prepare.py' in reader.PREMISES
        assert type(output) is str and Path(output).name == output and output.endswith('.json.gz')
        self.output = AUDIT / output
        self.line, self.scope = line, scope

    def current_sources(self):
        return {name: prepare.blob(execute.read(AUDIT / name)) for name in self.sources}

    def reference(self):
        original = {name: source.original(name) for name in self.reader.PREMISES}
        raw = execute.read(self.reader.PATH)
        equal(raw, epoch.read(source.REVISION, str(self.reader.PATH)))
        metadata = {name: row['body'] for name, row in original.items()}
        equal(json.loads(gzip.decompress(raw))['programmes'], metadata)
        equal(self.reader.source_metadata(), metadata)
        return dict(original=original, metadata=metadata,
                    proof=dict(revision=source.REVISION, path=str(self.reader.PATH),
                               identity=prepare.identity(raw), retention_contract='fsmgen_required_history'))

    @contextlib.contextmanager
    def supplied_images(self, images, denied=False):
        read = execute.read
        paths = {str(AUDIT / name): name for name in images}
        attempted = []

        def supplied(path):
            name = paths.get(str(path))
            if name is None:
                return read(path)
            attempted.append(name)
            if denied:
                raise AssertionError('deliberately denied current metadata')
            return images[name]

        try:
            execute.read = supplied
            yield attempted
        finally:
            execute.read = read

    def controls(self, fixed):
        images = {name: unblob(row['body']) for name, row in fixed['original'].items()}
        changed = dict(images, **{'prepare.py': b'x' + images['prepare.py'][1:]})
        rows = []
        for label, supplied, denied in (('historical-image', images, False),
                                        ('changed-image', changed, False),
                                        ('denied-image', images, True)):
            for current in (False, True):
                with self.supplied_images(supplied, denied) as attempted:
                    result = outcome(lambda: equal(self.reader.source_metadata(current=current), fixed['metadata']))
                assert result['accepted'] is (not current or label == 'historical-image')
                assert bool(attempted) is current
                rows.append(dict(label=label, current=current, reads=attempted, result=result))
        for label in ('float-bytes', 'boolean-bytes', 'missing-member', 'rehashed-body', 'borrowed-reader'):
            candidate = copy.deepcopy(fixed['metadata'])
            if label == 'float-bytes':
                candidate['prepare.py']['bytes'] = float(candidate['prepare.py']['bytes'])
            elif label == 'boolean-bytes':
                candidate['prepare.py']['bytes'] = True
            elif label == 'missing-member':
                del candidate['prepare.py']
            elif label == 'rehashed-body':
                candidate['prepare.py'] = prepare.blob(changed['prepare.py'])
            else:
                candidate[self.reader.SELF] = candidate['prepare.py']
            result = outcome(lambda: equal(candidate, self.reader.source_metadata()))
            assert not result['accepted']
            rows.append(dict(label=label, candidate=candidate, result=result))
        for name in ('../prepare.py', 'inventory.json.gz', 'missing-source-control.py'):
            result = outcome(lambda: source.original(name))
            assert not result['accepted']
            rows.append(dict(label='closed-native-member', name=name, result=result))
        command = source.execute.command
        try:
            def changed_show(argv):
                raw = command(argv)
                return b'x' + raw[1:] if argv[2] == 'show' else raw
            source.execute.command = changed_show
            result = outcome(lambda: source.original('prepare.py'))
            assert not result['accepted']
            rows.append(dict(label='changed-native-show', result=result))
        finally:
            source.execute.command = command
        return rows

    def command(self, mode):
        assert mode in MODES
        argv = ['python3', '-B']
        if mode == 'assertions-disabled':
            argv.append('-O')
        argv.append(str(AUDIT / self.reader.SELF))
        if mode == 'current':
            argv.append('--current')
        return argv

    def collect(self):
        fixed = self.reference()
        actual = []
        for mode in MODES:
            argv = self.command(mode)
            result = subprocess.run(argv, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True)
            actual.append(dict(command=argv, status=result.returncode, stdout=prepare.blob(result.stdout),
                               stderr=prepare.blob(result.stderr.replace(str(ROOT).encode(), b'.')),
                               raw_stderr_sha256=hashlib.sha256(result.stderr).hexdigest()))
        equal(self.reference(), fixed)
        return dict(schema='fsmgen.saved_source_roles.v1', reader=self.reader.SELF,
                    scope=self.scope, limits=LIMITS, normalization=NORMALIZATION,
                    sources=self.current_sources(), reference=fixed,
                    controls=self.controls(fixed), actual=actual)

    def review(self, value):
        assert set(value) == {'schema', 'reader', 'scope', 'limits', 'normalization', 'sources', 'reference', 'controls', 'actual'}
        equal(value['schema'], 'fsmgen.saved_source_roles.v1')
        equal(value['reader'], self.reader.SELF)
        equal(value['scope'], self.scope)
        equal(value['limits'], LIMITS)
        equal(value['normalization'], NORMALIZATION)
        equal(value['sources'], self.current_sources())
        fixed = self.reference()
        equal(value['reference'], fixed)
        equal(value['controls'], self.controls(fixed))
        assert type(value['actual']) is list and len(value['actual']) == len(MODES)
        for row, mode in zip(value['actual'], MODES):
            assert set(row) == {'command', 'status', 'stdout', 'stderr', 'raw_stderr_sha256'}
            equal(row['command'], self.command(mode))
            equal(row['status'], 0 if mode == 'saved' else 1)
            equal(unblob(row['stdout']), self.line.encode() if mode == 'saved' else b'')
            stderr = unblob(row['stderr'])
            assert type(row['raw_stderr_sha256']) is str and re.fullmatch('[0-9a-f]{64}', row['raw_stderr_sha256'])
            if mode == 'current':
                assert stderr.endswith(b'AssertionError: exact scalar\n') and b'ram-guard:' not in stderr
            else:
                equal(stderr, b'Acceptance assertions must be enabled.\n' if mode == 'assertions-disabled' else b'')
                equal(row['raw_stderr_sha256'], hashlib.sha256(stderr).hexdigest())

    def main(self):
        if not __debug__:
            raise SystemExit('Acceptance assertions must be enabled.')
        parser = argparse.ArgumentParser(description=self.scope)
        parser.add_argument('--write', action='store_true')
        args = parser.parse_args()
        value = self.collect() if args.write else json.loads(gzip.decompress(execute.read(self.output)))
        self.review(value)
        if args.write:
            with execute.safe(self.output).open('xb') as target:
                with gzip.GzipFile(filename='', mode='wb', fileobj=target, mtime=0) as stream:
                    for chunk in json.JSONEncoder(sort_keys=True, separators=(',', ':')).iterencode(value):
                        stream.write(chunk.encode())
        print('Native saved metadata and complete original proof qualify for ' + self.reader.SELF + '; current metadata and disabled assertions refuse.')
