"""Inert admission-state countermodels; the permit writer main never runs."""
import argparse
from copy import deepcopy
from support_final_corrected import BASE, H, M, read, write
from admit_execution import TASK, validate_state


def verify():
    plan = read(BASE / 'plan.json')
    task = ''.join('- ID: `' + owner + '`\n  Status: `done`\n' for owner in plan['completed_owners'])
    state = dict(revision='a'*40, subject=plan['owner']+': synthetic admission', committed_task=task,
        current_task=task+'- ID: `'+plan['execution_owner']+'`\n  Status: `active`\n',
        memory='active_work_unit: `'+plan['execution_owner']+'`', uid=501, euid=501,
        dirty_paths=['MEMORY.md','docs/TASK_TREE.md',TASK], staged_paths=[], untracked_paths=[],
        roots_absent=plan['prospective_roots'], journal_absent=True, permit_absent=True)
    assert validate_state(state,plan)
    changes = {
        'wrong_commit_shape': dict(revision='uncommitted'),
        'wrong_commit_owner': dict(subject='another-owner: unrelated'),
        'admission_not_committed': dict(committed_task=task.replace('`done`','`active`',1)),
        'current_admission_reopened': dict(current_task=state['current_task'].replace('`done`','`active`',1)),
        'execution_not_active': dict(current_task=state['current_task'].replace('`active`','`proposed`')),
        'wrong_memory_owner': dict(memory='active_work_unit: `unrelated`'),
        'unrelated_dirty_source': dict(dirty_paths=['source.pm']),
        'staged_work': dict(staged_paths=[TASK]),
        'untracked_work': dict(untracked_paths=['unrelated.py']),
        'root_user': dict(uid=0,euid=0),
        'different_effective_user': dict(euid=502),
        'existing_fixture_root': dict(roots_absent=plan['prospective_roots'][1:]),
        'existing_journal': dict(journal_absent=False),
        'existing_permit': dict(permit_absent=False),
    }
    rejected=[]
    for label, change in changes.items():
        altered=deepcopy(state);altered.update(change)
        try:validate_state(altered,plan)
        except AssertionError:rejected.append(label)
        else:raise AssertionError('accepted invalid admission state: '+label)
    return dict(schema='fsmgen.lifetime_final_permit_data_qualification.v1',
        synthetic_accepted_state=True,rejected_states=rejected,actual_permits_written=0,actual_fixture_operations=0)


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    result=verify()
    if args.retain:write(BASE/'permit-review.json',result)
    else:assert read(BASE/'permit-review.json')==result
    print('Permit state qualification: OK; no actual permit written.')


if __name__=='__main__':main()
