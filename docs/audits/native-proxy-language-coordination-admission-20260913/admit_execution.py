"""Issue one committed permit; authenticate it again before any worker allocation."""

import argparse
import hashlib
import json
import os
import re
import subprocess

from contract import BASE, ROOT, OWNER, EXECUTION_OWNER, OUTPUT, cases
from local_files import direct, pin, private_directory, read_bytes, write_json
from toolchain import resolve

TASK = 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md'


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def section(text, owner):
    marker = '- ID: `' + owner + '`\n'
    assert text.count(marker) == 1
    return text.split(marker)[1].split('- ID: `', 1)[0]


def validate_state(state, plan):
    assert re.fullmatch('[0-9a-f]{40}', state['revision'])
    assert state['subject'].startswith(OWNER + ':')
    assert 'Status: `done`' in section(state['committed_task'], OWNER)
    assert 'Status: `done`' in section(state['current_task'], OWNER)
    assert 'Status: `proposed`' in section(state['committed_task'], EXECUTION_OWNER)
    assert 'Status: `active`' in section(state['current_task'], EXECUTION_OWNER)
    assert 'active_work_unit: `' + EXECUTION_OWNER + '`' in state['memory']
    assert set(state['dirty_paths']) <= {'MEMORY.md', 'docs/TASK_TREE.md', TASK}
    assert state['staged_paths'] == state['untracked_paths'] == []
    assert type(state['uid']) is int and state['uid'] > 0 and state['uid'] == state['euid']
    assert state['platform'] == plan['platform'] == 'darwin'
    assert state['absent_objects'] == plan['prospective_objects']
    assert state['absent_outputs'] == plan['prospective_outputs']
    assert state['journal_absent'] is True
    return True


def current_state(plan):
    import sys
    revision = git('rev-parse', 'HEAD').decode().strip()
    return dict(revision=revision, subject=git('log', '-1', '--format=%s').decode(),
                committed_task=git('show', revision + ':' + TASK).decode(),
                current_task=(ROOT / TASK).read_text(), memory=(ROOT / 'MEMORY.md').read_text(),
                dirty_paths=git('diff', '--name-only', 'HEAD').decode().splitlines(),
                staged_paths=git('diff', '--cached', '--name-only').decode().splitlines(),
                untracked_paths=git('ls-files', '--others', '--exclude-standard').decode().splitlines(),
                uid=os.getuid(), euid=os.geteuid(), platform=sys.platform,
                absent_objects=[relative for relative in plan['prospective_objects'] if direct(relative, absent_ok=True) is None],
                absent_outputs=[relative for relative in plan['prospective_outputs'] if direct(relative, absent_ok=True) is None],
                journal_absent=direct(OUTPUT + '/journal.jsonl', absent_ok=True) is None)


def authenticated_sources(plan, revision):
    pins = json.loads(read_bytes((BASE / 'preflight-pins.json').relative_to(ROOT).as_posix(), 65536))
    for row in pins:
        if pin(row['path']) != row or git('show', revision + ':' + row['path']) != (ROOT / row['path']).read_bytes():
            raise ValueError('source differs from committed coordination admission')
    for name in ('preflight-pins.json', 'review.json'):
        relative = (BASE / name).relative_to(ROOT).as_posix()
        if git('show', revision + ':' + relative) != read_bytes(relative, 4 * 1024 * 1024):
            raise ValueError('final admission review differs from commit')
    if plan['owner'] != OWNER or plan['execution_owner'] != EXECUTION_OWNER or plan['cases'] != cases():
        raise ValueError('closed coordination plan differs')


def authenticate_execution():
    plan_path = (BASE / 'plan.json').relative_to(ROOT).as_posix()
    plan = json.loads(read_bytes(plan_path, 65536))
    state = current_state(plan)
    validate_state(state, plan)
    authenticated_sources(plan, state['revision'])
    permit = json.loads(read_bytes(OUTPUT + '/execution-admission.json', 4096))
    expected = dict(schema='fsmgen.language_coordination_execution_admission.v1',
                    execution_owner=EXECUTION_OWNER, admission_commit=state['revision'],
                    plan_sha256=pin(plan_path)['sha256'],
                    preflight_sha256=pin((BASE / 'preflight-pins.json').relative_to(ROOT).as_posix())['sha256'],
                    task_sha256=hashlib.sha256(state['current_task'].encode()).hexdigest())
    if permit != expected:
        raise ValueError('execution permit is not exact for current admission and task')
    return plan, permit, resolve(plan)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--emit', action='store_true', required=True)
    parser.parse_args()
    import audit
    if audit.verify() != json.loads((BASE / 'review.json').read_bytes()):
        raise ValueError('saved source/data admission does not reconstruct')
    plan = json.loads((BASE / 'plan.json').read_bytes())
    state = current_state(plan)
    validate_state(state, plan)
    authenticated_sources(plan, state['revision'])
    resolve(plan)
    if direct(OUTPUT + '/execution-admission.json', absent_ok=True) is not None:
        raise FileExistsError('execution permit already exists')
    private_directory(OUTPUT)
    value = dict(schema='fsmgen.language_coordination_execution_admission.v1', execution_owner=EXECUTION_OWNER,
                 admission_commit=state['revision'], plan_sha256=pin((BASE / 'plan.json').relative_to(ROOT).as_posix())['sha256'],
                 preflight_sha256=pin((BASE / 'preflight-pins.json').relative_to(ROOT).as_posix())['sha256'],
                 task_sha256=hashlib.sha256(state['current_task'].encode()).hexdigest())
    write_json(OUTPUT + '/execution-admission.json', value)
    print('Committed coordination permit emitted for ' + EXECUTION_OWNER)


if __name__ == '__main__':
    main()
