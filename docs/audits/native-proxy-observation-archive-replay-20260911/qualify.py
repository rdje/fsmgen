"""Qualify saved-evidence reconstruction; never invoke a historical producer."""
from __future__ import annotations

import builtins
import contextlib
import copy
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
from unittest.mock import patch

sys.dont_write_bytecode = True
BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-archive-replay-20260911'
spec = importlib.util.spec_from_file_location('archive_saved_replay', BASE / 'replay.py')
REPLAY = importlib.util.module_from_spec(spec)
spec.loader.exec_module(REPLAY)


def digest(raw):
    return dict(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def save(name, value):
    (LOG / name).write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def census(paths):
    result = {}
    for path in sorted(set(paths)):
        relative = str(path.relative_to(ROOT))
        info = REPLAY.direct(path)
        row = dict(device=info.st_dev, inode=info.st_ino, mode=stat.S_IMODE(info.st_mode),
                   size_bytes=info.st_size, mtime_ns=info.st_mtime_ns)
        if stat.S_ISREG(info.st_mode):
            row.update(kind='file', **digest(REPLAY.read_bytes(path)))
        else:
            assert stat.S_ISDIR(info.st_mode), relative
            row['kind'] = 'directory'
        result[relative] = row
    return result


def original_paths(plan):
    paths = [ROOT / pin['path'] for pin in plan['inputs']]
    for matrix in plan['matrices'].values():
        directory = ROOT / matrix['historical_log']
        if directory.exists():
            paths.extend([directory, *directory.rglob('*')])
    return paths


@contextlib.contextmanager
def evidence_guard(receipt):
    """Instrument Python content opens and subprocess entry; stat probes are allowed."""
    artifact_root = ROOT / '.artifacts'
    allowed = ROOT / REPLAY.RUN_PARENT
    original_open, original_io_open, original_os_open = builtins.open, io.open, os.open
    original_popen = subprocess.Popen

    def check_path(value):
        if isinstance(value, int):  # fdopen consumes a descriptor already admitted by os.open.
            return
        path = Path(os.fsdecode(value)).absolute()
        if path.is_relative_to(artifact_root) and not path.is_relative_to(allowed):
            receipt['forbidden_content_attempts'].append(str(path.relative_to(ROOT)))
            raise AssertionError('legacy artifact content is forbidden')
        receipt['content_opens'] += 1

    def checked_open(value, *args, **kwargs):
        check_path(value)
        return original_open(value, *args, **kwargs)

    def checked_io_open(value, *args, **kwargs):
        check_path(value)
        return original_io_open(value, *args, **kwargs)

    def checked_os_open(value, *args, **kwargs):
        check_path(value)
        assert kwargs.get('dir_fd') is None
        return original_os_open(value, *args, **kwargs)

    def checked_popen(argv, *args, **kwargs):
        permitted = (type(argv) is list and argv and argv[0] == 'git'
                     and ((len(argv) == 4 and argv[1:3] == ['cat-file', '-s'])
                          or (len(argv) == 3 and argv[1] == 'show'))
                     and re.fullmatch(r'[0-9a-f]{40}:(?:docs|perl|t)/[A-Za-z0-9_./-]+', argv[-1])
                     and kwargs.get('cwd') == ROOT and not kwargs.get('shell', False))
        if not permitted:
            receipt['forbidden_process_attempts'].append(str(argv).replace(str(ROOT), '.'))
            raise AssertionError('only pinned read-only Git commands are permitted')
        receipt['git_commands'].append(argv)
        return original_popen(argv, *args, **kwargs)

    with patch.object(builtins, 'open', checked_open), patch.object(io, 'open', checked_io_open), \
            patch.object(os, 'open', checked_os_open), patch.object(subprocess, 'Popen', checked_popen):
        yield


def run_cli(names, receipt, cwd=None):
    output = io.StringIO()
    previous = Path.cwd()
    try:
        if cwd is not None:
            os.chdir(cwd)
        with evidence_guard(receipt), contextlib.redirect_stdout(output):
            code = REPLAY.main(['--matrix', names])
    finally:
        os.chdir(previous)
    report = json.loads(output.getvalue())
    assert code == 0 and report['success'] is True, report
    return dict(exit=code, stdout=output.getvalue(), report=report)


def main():
    assert LOG.is_dir()
    plan = REPLAY.load_plan()
    pins = json.loads((LOG / 'preflight-pins.json').read_bytes())
    for pin in pins:
        assert digest((ROOT / pin['path']).read_bytes()) == {key: pin[key] for key in ('size_bytes', 'sha256')}
    assert not (LOG / 'qualification.json').exists(), 'preserve the original qualification before rerunning'
    before = census(original_paths(plan))
    save('original-before.json', before)
    report = dict(schema='fsmgen.inactive_archive_saved_replay_qualification.v1', success=False,
                  controls=[], executions=[], prospective_pins=pins,
                  guard=dict(content_opens=0, forbidden_content_attempts=[], forbidden_process_attempts=[], git_commands=[]))
    save('qualification.json', report)

    # Reconstruct the absent prerequisite state, without entering the historical Perl harness.
    empty = LOG / 'fresh-checkout-view'
    empty.mkdir(mode=0o700)
    absent = empty / '.artifacts/logs/native-proxy-observation-archive-existing-calls-20260911/preflight-pins.json'
    source_path = 'docs/audits/native-proxy-observation-archive-existing-calls-20260911/qualify.t'
    source = (ROOT / source_path).read_text()
    read_line = next(i for i, line in enumerate(source.splitlines(), 1) if 'read_bytes(' in line and 'preflight-pins.json' in line)
    init_line = next(i for i, line in enumerate(source.splitlines(), 1) if 'ArchiveFixture::initialize(' in line)
    assert read_line < init_line and not absent.exists()
    try:
        absent.read_bytes()
    except FileNotFoundError:
        pass
    else:
        raise AssertionError('fresh checkout preflight unexpectedly exists')
    assert subprocess.check_output(['git', 'ls-files', '--', plan['matrices']['ordinary-existing']['historical_log'] + '/preflight-pins.json'], cwd=ROOT) == b''
    report['root_cause'] = dict(source=source_path, read_line=read_line, initialize_line=init_line,
        missing_path=str(absent.relative_to(ROOT)), missing_read='FileNotFoundError', original_producer_executed=False)
    empty.rmdir()
    save('qualification.json', report)

    def reject(name, operation, expected):
        parent = ROOT / REPLAY.RUN_PARENT
        prior = sorted(path.name for path in parent.iterdir()) if parent.exists() else []
        try:
            operation()
        except (REPLAY.ReplayError, FileNotFoundError) as error:
            assert expected in str(error), (name, str(error))
            message = (type(error).__name__ + ': ' + str(error)).replace(str(ROOT), '.')
        else:
            raise AssertionError('control was accepted: ' + name)
        after = sorted(path.name for path in parent.iterdir()) if parent.exists() else []
        assert prior == after, name
        report['controls'].append(dict(name=name, rejected=True, error=message, allocated_output=False))
        save('qualification.json', report)

    target = ROOT / 'docs/audits/native-proxy-observation-archive-records-20260911/result/qualification.json'
    original_read = REPLAY.read_bytes
    def missing(path, *args, **kwargs):
        if path == target:
            raise FileNotFoundError('injected missing tracked input')
        return original_read(path, *args, **kwargs)
    def altered(path, *args, **kwargs):
        raw = original_read(path, *args, **kwargs)
        return raw + b' ' if path == target else raw
    with patch.object(REPLAY, 'read_bytes', missing):
        reject('missing tracked input', lambda: REPLAY.run_selected(['records']), 'injected missing')
    with patch.object(REPLAY, 'read_bytes', altered):
        reject('altered tracked input', lambda: REPLAY.run_selected(['records']), 'source pin mismatch')
    changed = copy.deepcopy(plan)
    removed = changed['matrices']['records']['source_paths'].pop()
    if not any(removed in matrix['source_paths'] for matrix in changed['matrices'].values()):
        changed['inputs'] = [pin for pin in changed['inputs'] if pin['path'] != removed]
    with patch.object(REPLAY, 'load_plan', lambda: changed):
        reject('missing catalogue dependency', lambda: REPLAY.run_selected(['records']), 'missing')
    for name, field, expected in [('wrong seed digest', 'seed', 'seed set differs'),
                                  ('wrong expected audit', 'expected_audit', 'expected audit pin differs')]:
        changed = copy.deepcopy(plan)
        pin = changed['matrices']['records'][field]
        if field == 'seed':
            pin = pin[0]
        pin['sha256'] = '0' * 64
        with patch.object(REPLAY, 'load_plan', lambda: changed):
            reject(name, lambda: REPLAY.run_selected(['records']), expected)
    reject('unknown matrix', lambda: REPLAY.run_selected(['absent']), 'unknown or duplicate')
    reject('duplicate matrix', lambda: REPLAY.run_selected(['records', 'records']), 'unknown or duplicate')
    link = LOG / 'symlink-control'
    link.symlink_to('fresh-checkout-view', target_is_directory=True)
    try:
        with patch.object(REPLAY, 'RUN_PARENT', str(link.relative_to(ROOT))):
            reject('symlink output parent', REPLAY.ensure_run_parent, 'symlink')
    finally:
        link.unlink()

    # Prove the instrumentation rejects content access before running real saved auditors.
    probe = dict(content_opens=0, forbidden_content_attempts=[], forbidden_process_attempts=[], git_commands=[])
    with evidence_guard(probe):
        try:
            (ROOT / plan['matrices']['records']['historical_log'] / 'qualification.json').read_bytes()
        except AssertionError as error:
            assert str(error) == 'legacy artifact content is forbidden'
        else:
            raise AssertionError('legacy content guard did not fire')
    assert len(probe['forbidden_content_attempts']) == 1
    report['controls'].append(dict(name='legacy-log content access forbidden', rejected=True, probe=probe))
    save('qualification.json', report)

    report['executions'].append(run_cli('all', report['guard']))
    save('qualification.json', report)
    for name, replacement, expected in [
            ('auditor failure', lambda matrix, output: (_ for _ in ()).throw(ValueError('injected auditor failure')), 'saved audit failed'),
            ('altered audit result', lambda matrix, output: (output / 'audit.json').write_text('{}\n'), 'regenerated audit differs')]:
        with patch.object(REPLAY, 'invoke_audit', replacement), evidence_guard(report['guard']):
            failed = REPLAY.run_selected(['records'])
        assert failed['success'] is False and expected in failed['error'], failed
        report['controls'].append(dict(name=name, rejected=True, failure_report=failed))
        save('qualification.json', report)
    nonroot = ROOT / REPLAY.RUN_PARENT
    second = run_cli('records', report['guard'], cwd=nonroot)
    third = run_cli('records', report['guard'], cwd=nonroot)
    report['executions'].extend([second, third])
    assert len({row['report']['output'] for row in report['executions']}) == 3
    report['controls'].extend([
        dict(name='non-root caller working directory', accepted=True, cwd=str(nonroot.relative_to(ROOT))),
        dict(name='repeated invocation uses a distinct output', accepted=True)])
    after = census(original_paths(plan))
    save('original-after.json', after)
    assert before == after
    for pin in pins:
        assert digest((ROOT / pin['path']).read_bytes()) == {key: pin[key] for key in ('size_bytes', 'sha256')}
    assert report['guard']['forbidden_content_attempts'] == report['guard']['forbidden_process_attempts'] == []
    report['controls'].append(dict(name='original evidence remains unchanged', accepted=True, entries=len(before)))
    assert {row['name'] for row in report['controls']} == set(plan['controls'])
    report['original_evidence_unchanged'] = True
    report['success'] = True
    save('qualification.json', report)
    print(json.dumps(dict(success=True, matrices=len(plan['matrices']), controls=len(report['controls']),
                         source_inputs=len(plan['inputs']), original_entries=len(before)), sort_keys=True))


if __name__ == '__main__':
    main()
