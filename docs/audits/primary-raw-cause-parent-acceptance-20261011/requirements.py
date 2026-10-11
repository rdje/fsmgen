"""Recover complete original and current cause obligations without narrowing."""
from parent_common import *
import intake


def contracts():
    original_plan_name = PLAN['preparation'] + '/plan.json'
    original_revision = json.loads(fixed([original_plan_name])[original_plan_name])['revision']
    original = nodes(git('show', original_revision + ':' + TASK))
    current = nodes(fixed([TASK])[TASK])
    active = nodes(intake.overlays()[TASK])
    need(current.keys() == active.keys(), 'whole original current activation task domain')
    for name, block in current.items():
        if name == PLAN['owner']:
            need(field(block, 'Status') == 'pending'
                 and active[name] == block.replace(b'  Status: `pending`', b'  Status: `active`', 1),
                 'only unchanged parent-acceptance leaf activates')
        else:
            need(block == active[name], 'every whole unrelated current task block retains')
    proof_names = [PLAN['preparation'] + '/proof.json', PLAN['canonical_preparation'] + '/proof.json']
    proofs = {name: json.loads(body) for name, body in fixed(proof_names).items()}
    prerequisite = proofs[proof_names[0]]['contracts']
    for name, text in prerequisite['prerequisites'].items():
        need(original[name] == current[name] == text.encode()
             and field(current[name], 'Status') == 'done', 'every complete original primary/raw descendant retains')
    cause, canonical_parent = PLAN['cause'], PLAN['parent']
    need(all(field(original[cause], key) == field(current[cause], key) == value
             for key, value in prerequisite['parent'].items()), 'whole unchanged original cause goal and acceptance')
    expected_children = prerequisite['children']
    need(field(current[cause], 'Children') == ', '.join(expected_children), 'exact original safe cause decomposition')
    for name, fields in expected_children.items():
        need(all(field(current[name], key) == value for key, value in fields.items()),
             'every whole unchanged prerequisite association and canonical contract')
    additions = proofs[proof_names[1]]['contracts']['children']
    need(field(current[canonical_parent], 'Children') == ', '.join(additions), 'exact safe canonical decomposition')
    for name, fields in additions.items():
        need(all(field(current[name], key) == fields[key] for key in ('Goal', 'Acceptance')),
             'every whole prepared canonical descendant contract')
    closing = {cause, canonical_parent, PLAN['owner']}
    forest = {name: block for name, block in active.items() if name == cause or name.startswith(cause + '.')}
    need(set(forest) == {cause, *expected_children, *additions}, 'complete original cause and safe descendant forest')
    need(all(field(block, 'Status') == ('active' if name in closing else 'done')
             and (name in closing or field(block, 'Commit') not in (None, 'pending'))
             for name, block in forest.items()), 'all complete descendants committed before only parent closure')
    return dict(original_revision=original_revision, current_revision=PLAN['revision'],
        original_cause={key: field(original[cause], key) for key in ('Goal', 'Acceptance')},
        original_prerequisites=prerequisite['prerequisites'],
        whole_current_forest={name: block.decode() for name, block in forest.items()},
        condition='Every original cause/canonical goal and acceptance and every complete primary/raw and safely added descendant contract retains. Only cause, canonical parent and this acceptance leaf may close.')
