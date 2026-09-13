"""Emit one exclusive permit after final admission commits; no fixture execution."""
import argparse
import hashlib
import os
import re
import stat
import subprocess
from support_final_corrected import BASE, ROOT, H, M, pin, read, write

TASK = 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md'
OUTPUT = '.artifacts/logs/native-proxy-lifetime-controls-20260913'


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def section(text, owner):
    marker = '- ID: `' + owner + '`\n'
    assert text.count(marker) == 1
    return text.split(marker)[1].split('- ID: `', 1)[0]


def absent(relative):
    path = ROOT
    for part in relative.split('/'):
        assert part not in ('', '.', '..')
        path /= part
        try: metadata = path.lstat()
        except FileNotFoundError: return True
        assert stat.S_ISDIR(metadata.st_mode) and metadata.st_dev == ROOT.stat().st_dev and metadata.st_uid == os.getuid()
    return False


def validate_state(state, plan):
    """Pure admission checks shared by the actual writer and inert countermodels."""
    assert re.fullmatch('[0-9a-f]{40}', state['revision'])
    assert state['subject'].startswith(plan['owner'] + ':')
    for owner in plan['completed_owners']:
        assert 'Status: `done`' in section(state['committed_task'], owner)
        assert 'Status: `done`' in section(state['current_task'], owner)
    assert 'Status: `active`' in section(state['current_task'], plan['execution_owner'])
    assert 'active_work_unit: `' + plan['execution_owner'] + '`' in state['memory']
    assert set(state['dirty_paths']) <= {'MEMORY.md', 'docs/TASK_TREE.md', TASK}
    assert state['staged_paths'] == state['untracked_paths'] == []
    assert type(state['uid']) is int and state['uid'] > 0 and state['uid'] == state['euid']
    assert state['roots_absent'] == plan['prospective_roots']
    assert state['journal_absent'] is state['permit_absent'] is True
    return True


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--emit', action='store_true', required=True); parser.parse_args()
    import audit_final
    plan = read(BASE / 'plan.json')
    assert audit_final.verify() == read(BASE / 'review.json')
    revision = git('rev-parse', 'HEAD').decode().strip()
    pins = read(H / 'final-preflight-pins.json')
    for row in pins + [pin(H / 'final-preflight-pins.json'), pin(BASE / 'review.json')]:
        assert git('show', revision + ':' + row['path']) == (ROOT / row['path']).read_bytes()
    selection = read(M / 'selection.json')
    current_task = (ROOT / TASK).read_text()
    state = dict(revision=revision, subject=git('log', '-1', '--format=%s').decode(),
        committed_task=git('show', revision + ':' + TASK).decode(), current_task=current_task,
        memory=(ROOT / 'MEMORY.md').read_text(), uid=os.getuid(), euid=os.geteuid(),
        dirty_paths=git('diff', '--name-only', 'HEAD').decode().splitlines(),
        staged_paths=git('diff', '--cached', '--name-only').decode().splitlines(),
        untracked_paths=git('ls-files', '--others', '--exclude-standard').decode().splitlines(),
        roots_absent=[relative for relative in plan['prospective_roots'] if absent(relative)],
        journal_absent=absent(selection['journal']), permit_absent=not (ROOT / OUTPUT / 'execution-admission.json').exists())
    validate_state(state, plan)
    path = ROOT
    for part in OUTPUT.split('/'):
        path /= part
        try: metadata = path.lstat()
        except FileNotFoundError: path.mkdir(mode=0o700); metadata = path.lstat()
        assert stat.S_ISDIR(metadata.st_mode) and metadata.st_dev == ROOT.stat().st_dev and metadata.st_uid == os.getuid()
    value = dict(schema='fsmgen.inactive_lifetime_execution_admission.v1', execution_owner=plan['execution_owner'],
        admission_commit=revision, plan_sha256=pin(H / 'harness-plan.json')['sha256'],
        preflight_sha256=pin(H / 'final-preflight-pins.json')['sha256'],
        native_open_flags={name: getattr(os, name) for name in ('O_WRONLY', 'O_RDWR', 'O_CREAT', 'O_TRUNC', 'O_EXCL')},
        task_sha256=hashlib.sha256(current_task.encode()).hexdigest())
    write(path / 'execution-admission.json', value)
    print('Committed final admission emitted for ' + plan['execution_owner'])


if __name__ == '__main__':
    main()
