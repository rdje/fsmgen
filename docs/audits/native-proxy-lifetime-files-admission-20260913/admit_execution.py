"""Emit a one-use local permit only after the admission is durably committed."""
from __future__ import annotations

import argparse
import hashlib
import os
import stat
import subprocess

from support import BASE, ROOT, authenticate, document, pin, write
import audit


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def section(text, owner):
    marker = '- ID: `' + owner + '`\n'
    assert text.count(marker) == 1
    return text.split(marker)[1].split('- ID: `', 1)[0]


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--emit', action='store_true', required=True)
    parser.parse_args()
    plan = document(BASE / 'plan.json'); selection = document(BASE / 'selection.json')
    pins = document(BASE / 'preflight-pins.json'); authenticate(plan, pins)
    expected = audit.verify(plan); saved = document(BASE / 'review.json')
    audit.raw_checks(saved['raw_captures'])
    assert {key: value for key, value in saved.items() if key != 'raw_captures'} == expected
    revision = git('rev-parse', 'HEAD').decode().strip()
    assert git('log', '-1', '--format=%s').decode().startswith(plan['owner'] + ':')
    for row in pins + [pin(BASE / 'preflight-pins.json'), pin(BASE / 'review.json')]:
        assert git('show', revision + ':' + row['path']) == (ROOT / row['path']).read_bytes()
    task = 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md'
    committed = git('show', revision + ':' + task).decode(); current = (ROOT / task).read_text()
    assert 'Status: `done`' in section(committed, selection['owner'])
    assert 'Status: `done`' in section(current, selection['owner'])
    assert 'Status: `active`' in section(current, selection['execution_owner'])
    assert 'active_work_unit: `' + selection['execution_owner'] + '`' in (ROOT / 'MEMORY.md').read_text()
    allowed = {'MEMORY.md', 'docs/TASK_TREE.md', task}
    assert set(git('diff', '--name-only', 'HEAD').decode().splitlines()) <= allowed
    assert not git('diff', '--cached', '--name-only').strip()
    # A new execution-owned receipt directory may exist; no other untracked
    # project work is silently admitted by this source-only permit writer.
    assert not git('ls-files', '--others', '--exclude-standard').strip()
    uid = os.getuid(); assert uid > 0 and uid == os.geteuid()
    device = ROOT.stat().st_dev
    for case in selection['cases']:
        for relative in case['roots'].values():
            try: os.lstat(ROOT / relative)
            except FileNotFoundError: pass
            else: raise AssertionError('prospective fixture root already exists: ' + relative)
    relative = '.artifacts/logs/native-proxy-lifetime-files-20260913'
    path = ROOT
    for part in relative.split('/'):
        path /= part
        try: metadata = os.lstat(path)
        except FileNotFoundError:
            path.mkdir(mode=0o700); metadata = os.lstat(path)
        assert stat.S_ISDIR(metadata.st_mode) and metadata.st_dev == device and metadata.st_uid == uid
    value = dict(schema='fsmgen.inactive_lifetime_execution_admission.v1', execution_owner=selection['execution_owner'],
        admission_commit=revision, plan_sha256=pin(BASE / 'plan.json')['sha256'],
        preflight_sha256=pin(BASE / 'preflight-pins.json')['sha256'],
        native_open_flags={name: getattr(os, name) for name in ('O_WRONLY', 'O_RDWR', 'O_CREAT', 'O_TRUNC', 'O_EXCL')},
        task_sha256=hashlib.sha256((ROOT / task).read_bytes()).hexdigest())
    destination = path / 'execution-admission.json'
    # support.write uses open('xb'); a prior permit can never be overwritten.
    write(destination, value)
    print('committed lifetime admission emitted for ' + selection['execution_owner'])


if __name__ == '__main__':
    main()
