"""Qualify prospective admission states without issuing a permit or launching."""

import argparse
import copy
import json

from admit_execution import validate_state
from contract import BASE, OWNER, EXECUTION_OWNER


def qualify():
    plan = json.loads((BASE / 'plan.json').read_bytes())
    committed = '- ID: `' + OWNER + '`\n  Status: `done`\n- ID: `' + EXECUTION_OWNER + '`\n  Status: `proposed`\n'
    current = committed.replace('Status: `proposed`', 'Status: `active`')
    state = dict(revision='a' * 40, subject=OWNER + ': synthetic committed admission',
                 committed_task=committed, current_task=current,
                 memory='active_work_unit: `' + EXECUTION_OWNER + '`',
                 dirty_paths=['MEMORY.md', 'docs/TASK_TREE.md', 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md'],
                 staged_paths=[], untracked_paths=[], uid=501, euid=501, platform='darwin',
                 absent_objects=plan['prospective_objects'], absent_outputs=plan['prospective_outputs'], journal_absent=True)
    assert validate_state(state, plan)
    controls = []
    for name, mutate in (
        ('wrong_revision', lambda s: s.update(revision='not-a-commit')),
        ('wrong_commit_owner', lambda s: s.update(subject='unrelated: change')),
        ('admission_not_committed', lambda s: s.update(committed_task=committed.replace('`done`', '`active`'))),
        ('current_admission_reopened', lambda s: s.update(current_task=current.replace('`done`', '`active`'))),
        ('execution_not_active', lambda s: s.update(current_task=committed)),
        ('execution_previously_active', lambda s: s.update(committed_task=current)),
        ('wrong_resume_pointer', lambda s: s.update(memory='unrelated')),
        ('dirty_implementation', lambda s: s['dirty_paths'].append('scripts/changed.py')),
        ('staged_work', lambda s: s.update(staged_paths=['MEMORY.md'])),
        ('untracked_work', lambda s: s.update(untracked_paths=['new-file'])),
        ('root_user', lambda s: s.update(uid=0, euid=0)),
        ('changed_effective_user', lambda s: s.update(euid=0)),
        ('unsupported_platform', lambda s: s.update(platform='linux')),
        ('existing_fixture', lambda s: s['absent_objects'].pop()),
        ('existing_capture', lambda s: s['absent_outputs'].pop()),
        ('existing_journal', lambda s: s.update(journal_absent=False)),
    ):
        changed = copy.deepcopy(state)
        mutate(changed)
        try:
            validate_state(changed, plan)
        except AssertionError:
            controls.append(name)
        else:
            raise AssertionError('unsafe admission state accepted: ' + name)
    return dict(schema='fsmgen.language_coordination_permit_state_review.v1',
                synthetic_positive_state=True, rejected_states=controls,
                actual_permit_issued=False, actual_worker_execution=False)


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    result = qualify()
    if args.retain:
        with (BASE / 'permit-state-review.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        assert result == json.loads((BASE / 'permit-state-review.json').read_bytes())
    print(json.dumps(dict(rejected_states=len(result['rejected_states']), actual_permit_issued=False), sort_keys=True))


if __name__ == '__main__':
    main()
