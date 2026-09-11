#!/usr/bin/env python3
"""Recheck tracked archive receipts without rerunning their original producers."""
from __future__ import annotations

import argparse
import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '698f99da3ca3dfe47b89fc17db142b3784f37907'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.5'
COMPONENTS = {
    'records': 'native-proxy-observation-archive-records-20260911',
    'files': 'native-proxy-observation-archive-20260911',
    'boundaries': 'native-proxy-observation-archive-boundaries-20260911',
    'ordinary-fresh': 'native-proxy-observation-archive-fresh-calls-20260911',
    'ordinary-existing': 'native-proxy-observation-archive-existing-calls-20260911',
    'equal-fresh': 'native-proxy-observation-archive-equal-fresh-calls-20260911',
    'equal-existing': 'native-proxy-observation-archive-equal-existing-calls-20260911',
}
LIMITS = dict(file_bytes=64 * 1024 * 1024, source_files=256,
              source_bytes=256 * 1024 * 1024, captured_stream_bytes=1024 * 1024)
RUN_PARENT = '.artifacts/logs/native-proxy-observation-archive-replay-20260911/runs'
SCOPE = 'saved evidence revalidation; no original producer, compiler, native experiment or release authority'


class ReplayError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise ReplayError(message)


def relative(value):
    require(type(value) is str and value and '\x00' not in value, 'invalid repository-relative path')
    path = PurePosixPath(value)
    require(not path.is_absolute() and path.as_posix() == value
            and all(part not in ('.', '..') for part in path.parts), 'noncanonical repository-relative path')
    return ROOT.joinpath(*path.parts)


def direct(path):
    require(path.is_relative_to(ROOT), 'path is outside repository')
    root_device = ROOT.stat().st_dev
    current = ROOT
    for part in path.relative_to(ROOT).parts:
        current = current / part
        info = current.lstat()
        require(not stat.S_ISLNK(info.st_mode) and info.st_dev == root_device,
                'symlink or foreign-volume project object: ' + str(current.relative_to(ROOT)))
        if current != path:
            require(stat.S_ISDIR(info.st_mode), 'project ancestor is not a directory')
    return path.lstat()


def read_bytes(path, ceiling=LIMITS['file_bytes']):
    named = direct(path)
    require(stat.S_ISREG(named.st_mode) and named.st_size <= ceiling,
            'source type or size exceeds replay contract: ' + str(path.relative_to(ROOT)))
    descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    with os.fdopen(descriptor, 'rb') as stream:
        opened = os.fstat(stream.fileno())
        require((opened.st_dev, opened.st_ino, opened.st_size) ==
                (named.st_dev, named.st_ino, named.st_size), 'source changed before read')
        raw = stream.read(ceiling + 1)
        final = os.fstat(stream.fileno())
    current = direct(path)
    identity = lambda item: (item.st_dev, item.st_ino, item.st_mode, item.st_size,
                             item.st_mtime_ns, item.st_ctime_ns)
    require(len(raw) == opened.st_size and len(raw) <= ceiling
            and identity(opened) == identity(final) == identity(current), 'source changed during read')
    return raw


def checked(pin, *, git=False):
    require(set(pin) == {'path', 'size_bytes', 'sha256'}, 'invalid source pin fields')
    require(type(pin['size_bytes']) is int and 0 <= pin['size_bytes'] <= LIMITS['file_bytes'], 'invalid source size')
    require(type(pin['sha256']) is str and re.fullmatch('[0-9a-f]{64}', pin['sha256']), 'invalid source digest')
    raw = read_bytes(relative(pin['path']))
    require(len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256'],
            'source pin mismatch: ' + pin['path'])
    if git:
        object_name = REVISION + ':' + pin['path']
        size = subprocess.check_output(['git', 'cat-file', '-s', object_name], cwd=ROOT)
        require(int(size) == len(raw), 'historical source size mismatch: ' + pin['path'])
        original = subprocess.check_output(['git', 'show', object_name], cwd=ROOT)
        require(raw == original, 'historical source bytes mismatch: ' + pin['path'])
    return raw


def load_plan():
    return json.loads(read_bytes(BASE / 'plan.json', 1024 * 1024))


def validate_selection(plan, names):
    require(set(plan) == {'schema', 'source_revision', 'owner', 'matrices', 'inputs', 'limits', 'contract', 'controls'},
            'unexpected replay plan fields')
    require(plan['schema'] == 'fsmgen.inactive_archive_saved_replay_plan.v1'
            and plan['source_revision'] == REVISION and plan['limits'] == LIMITS
            and plan['owner'] == OWNER, 'unsupported replay plan')
    require(set(plan['matrices']) == set(COMPONENTS), 'replay matrix domain differs')
    require(names and len(names) == len(set(names)) and all(name in COMPONENTS for name in names),
            'unknown or duplicate selected matrix')
    pins = {pin['path']: pin for pin in plan['inputs']}
    require(len(pins) == len(plan['inputs']) <= LIMITS['source_files'], 'source catalogue aliases or exceeds capacity')
    for pin in pins.values():
        require(set(pin) == {'path', 'size_bytes', 'sha256'} and type(pin['size_bytes']) is int
                and 0 <= pin['size_bytes'] <= LIMITS['file_bytes'], 'invalid catalogue source fields or size')
        relative(pin['path'])
        require(type(pin['sha256']) is str and re.fullmatch('[0-9a-f]{64}', pin['sha256']), 'invalid catalogue digest')
    require(sum(pin['size_bytes'] for pin in pins.values()) <= LIMITS['source_bytes'], 'source byte capacity exceeded')
    all_paths = {path for matrix in plan['matrices'].values() for path in matrix['source_paths']}
    require(all_paths == set(pins), 'source catalogue is not the exact dependency union')
    selected_paths = set()
    for name in names:
        matrix = plan['matrices'][name]
        require(set(matrix) == {'component', 'audit', 'source_paths', 'seed', 'expected_audit', 'historical_log'},
                'unexpected matrix fields')
        component = COMPONENTS[name]
        base = 'docs/audits/' + component
        require(matrix['component'] == component and matrix['audit'] == base + '/audit.py'
                and matrix['historical_log'] == '.artifacts/logs/' + component, 'matrix path binding differs')
        require(matrix['source_paths'] == sorted(set(matrix['source_paths'])), 'matrix dependency aliases')
        selected_paths.update(matrix['source_paths'])
    # Authenticate before importing an auditor or allocating replay output.
    for path in sorted(selected_paths):
        checked(pins[path], git=True)
    for name in names:
        matrix = plan['matrices'][name]
        base = 'docs/audits/' + COMPONENTS[name]
        def document(suffix):
            path = base + '/' + suffix
            require(path in pins, 'missing catalogue dependency: ' + path)
            return json.loads(checked(pins[path]))
        original = document('plan.json')
        prospective = document('result/preflight-pins.json')
        manifest = document('result/recovery-copies.json')
        require(manifest['all_copies_byte_exact'] is True, 'recovery copies are not certified')
        expected_paths = {pin['path'] for pin in original['inputs'] + prospective}
        expected_paths.update(base + '/' + suffix for suffix in
                              ('plan.json', 'audit.py', 'result/preflight-pins.json', 'result/recovery-copies.json'))
        saved = {}
        for row in manifest['files']:
            destination = PurePosixPath(row['destination'])
            require(destination.parent.as_posix() == base + '/result'
                    and row['source'] == matrix['historical_log'] + '/' + destination.name,
                    'recovery path binding differs')
            require(destination.name not in saved, 'recovery filename aliases')
            pin = dict(path=row['destination'], size_bytes=row['size_bytes'], sha256=row['sha256'])
            require(pins.get(pin['path']) == pin, 'recovery pin differs from catalogue')
            saved[destination.name] = pin
            expected_paths.add(pin['path'])
        require(matrix['source_paths'] == sorted(expected_paths), 'missing or extra matrix dependency')
        seed_names = ['preflight-pins.json', 'qualification.json', 'qualify.tap', 'qualify.exit']
        if name != 'records':
            seed_names.append('admission.jsonl')
        require(matrix['seed'] == [saved[key] for key in seed_names], 'replay seed set differs')
        require(matrix['expected_audit'] == saved['audit.json'], 'expected audit pin differs')
        for key in ('audit.exit', 'qualify.exit'):
            require(checked(saved[key]).strip() == b'0', 'historical qualification or audit failed')
    return pins, sorted(selected_paths)


def ensure_run_parent():
    current = ROOT
    for part in PurePosixPath(RUN_PARENT).parts:
        current = current / part
        try:
            current.mkdir(mode=0o700)
        except FileExistsError:
            pass
        info = direct(current)
        require(stat.S_ISDIR(info.st_mode), 'replay parent is not a directory')
    require(info.st_uid == os.getuid() and stat.S_IMODE(info.st_mode) == 0o700,
            'replay run parent must be private and caller-owned')
    return current


def write_new(path, raw):
    require(len(raw) <= LIMITS['file_bytes'], 'replay output exceeds file ceiling')
    direct(path.parent)
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
    with os.fdopen(descriptor, 'wb') as stream:
        stream.write(raw)
    require(read_bytes(path) == raw, 'replay output readback differs')


def json_bytes(value):
    return (json.dumps(value, indent=2, sort_keys=True) + '\n').encode('ascii')


class BoundedText(io.StringIO):
    def __init__(self):
        super().__init__()
        self.byte_count = 0

    def write(self, value):
        self.byte_count += len(value.encode('utf-8'))
        require(self.byte_count <= LIMITS['captured_stream_bytes'], 'audit stream exceeds capture ceiling')
        return super().write(value)


def invoke_audit(matrix, output):
    specification = importlib.util.spec_from_file_location('saved_archive_replay_' + output.name.replace('-', '_'),
                                                         relative(matrix['audit']))
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    require(module.ROOT == ROOT and str(module.LOG.relative_to(ROOT)) == matrix['historical_log'],
            'auditor root or original log binding differs')
    module.LOG = output
    module.main()


def run_selected(names):
    plan = load_plan()
    pins, paths = validate_selection(plan, names)
    parent = ensure_run_parent()
    run = Path(tempfile.mkdtemp(prefix='run-', dir=parent))
    info = direct(run)
    require(stat.S_IMODE(info.st_mode) == 0o700 and info.st_uid == os.getuid(), 'invalid replay namespace')
    relative_run = str(run.relative_to(ROOT))
    admission = dict(schema='fsmgen.inactive_archive_replay_admission.v1', path=relative_run,
                     device=info.st_dev, inode=info.st_ino, matrices=names, source_revision=REVISION)
    write_new(run / 'admission.json', json_bytes(admission))
    report = dict(schema='fsmgen.inactive_archive_saved_replay.v1', success=False, scope=SCOPE,
                  source_revision=REVISION, output=relative_run, matrices=[], source_inputs=len(paths))
    try:
        for name in names:
            matrix = plan['matrices'][name]
            output = run / name
            output.mkdir(mode=0o700)
            for pin in matrix['seed']:
                write_new(output / PurePosixPath(pin['path']).name, checked(pin))
            stdout, stderr = BoundedText(), BoundedText()
            audit_error = None
            try:
                with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                    invoke_audit(matrix, output)
            except Exception as error:
                audit_error = error
            write_new(output / 'replay.stdout', stdout.getvalue().encode('utf-8'))
            write_new(output / 'replay.stderr', stderr.getvalue().encode('utf-8'))
            if audit_error is not None:
                raise ReplayError('saved audit failed for ' + name + ': ' + str(audit_error)) from audit_error
            actual = read_bytes(output / 'audit.json', LIMITS['captured_stream_bytes'])
            expected = checked(matrix['expected_audit'])
            require(actual == expected, 'regenerated audit differs from tracked evidence: ' + name)
            # An audit may write its result, but cannot silently change its seeds.
            for pin in matrix['seed']:
                raw = read_bytes(output / PurePosixPath(pin['path']).name)
                require(hashlib.sha256(raw).hexdigest() == pin['sha256'] and len(raw) == pin['size_bytes'],
                        'auditor changed a replay input: ' + name)
            report['matrices'].append(dict(name=name, result=str((output / 'audit.json').relative_to(ROOT)),
                size_bytes=len(actual), sha256=hashlib.sha256(actual).hexdigest(), reconstructed_inputs=len(matrix['seed'])))
        for path in paths:
            checked(pins[path])
        report['success'] = True
    except Exception as error:
        report['error'] = (type(error).__name__ + ': ' + str(error)).replace(str(ROOT), '.')
    write_new(run / 'report.json', json_bytes(report))
    return report


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--matrix', choices=['all', *COMPONENTS], default='all',
                        help='saved audit to revalidate; defaults to all archive matrices')
    options = parser.parse_args(argv)
    names = list(COMPONENTS) if options.matrix == 'all' else [options.matrix]
    try:
        report = run_selected(names)
    except Exception as error:
        report = dict(success=False, scope=SCOPE,
                      error=(type(error).__name__ + ': ' + str(error)).replace(str(ROOT), '.'))
    print(json.dumps(report, sort_keys=True))
    return 0 if report['success'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
