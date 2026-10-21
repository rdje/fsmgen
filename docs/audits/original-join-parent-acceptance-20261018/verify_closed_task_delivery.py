"""Join exact native task declaration, retained subtrees and final delivery."""
import argparse
import copy
import gzip
import json

import closed_task_capacity as capacity

SELF = 'verify_closed_task_delivery.py'
PATH = capacity.BASE / 'closed-task-delivery-qualified.json.gz'
SCOPE = ('Dated whole native source/declaration/compaction/final task conservation. '
         'The complete original source and extracted subtrees overlap; nothing is '
         'discarded. Current owner/terminal eligibility is a separate explicit check. '
         'No semantic reader, original model/recipe/cohort or full helper executes.')


def equal(left, right):
    capacity.bounded.strict_equal(left, right)


def unpack(row):
    raw = capacity.prepare.unblob(row)
    equal(row, capacity.prepare.blob(raw))
    return raw


def conservation(original, before, compacted, final):
    old, declared, retained, delivered = map(capacity.common.nodes,
                                           (original, before, compacted, final))
    owner, tree = capacity.OWNER, capacity.common.TREE
    assert declared.keys() == old.keys() | {owner}, 'only the exact owning declaration added'
    equal(declared[tree], old[tree].replace(b'`\n\n', (', ' + owner + '`\n\n').encode(), 1))
    for name, raw in old.items():
        if name != tree:
            equal(declared[name], raw)
    restored = before.replace(declared[tree], old[tree], 1).replace(declared[owner], b'', 1)
    equal(restored, original)
    # The retained source proof separately reconstructs every selected subtree.
    assert delivered.keys() == retained.keys(), 'complete final task membership'
    for name, raw in retained.items():
        if name != owner:
            equal(delivered[name], raw)
    equal(final, compacted.replace(retained[owner], delivered[owner], 1))
    for field in ('Goal', 'Acceptance'):
        equal(capacity.common.field(delivered[owner], field),
              capacity.common.field(declared[owner], field))
    equal(capacity.common.field(delivered[owner], 'Status'), 'done')
    for field in ('Verification', 'Commit'):
        assert capacity.common.field(delivered[owner], field) != 'pending', 'complete owning signoff'
    return True


def context():
    raw = capacity.execute.read(capacity.PATH)
    proof = json.loads(gzip.decompress(raw))
    admission = {name: unpack(row) for name, row in proof['admission_registry_sources'].items()}
    equal(capacity.derive(False, admission), proof)
    return raw, proof


def review(value, raw, proof):
    assert set(value) == {'schema', 'scope', 'proof', 'final', 'programmes'}
    equal(value['schema'], 'fsmgen.closed_task_delivery.v1')
    equal(value['scope'], SCOPE)
    equal(unpack(value['proof']), raw)
    equal(value['programmes'], {name: capacity.prepare.blob(capacity.execute.read(capacity.BASE / name))
                               for name in (SELF, 'closed_task_capacity.py')})
    return conservation(unpack(proof['original']), unpack(proof['before']),
                        unpack(proof['compacted']), unpack(value['final']))


def controls(value, raw, proof):
    original, before, compacted, final = (unpack(row) for row in
        (proof['original'], proof['before'], proof['compacted'], value['final']))
    graph = capacity.common.nodes(before)
    selected = capacity.common.TREE + '.82'
    assert selected in graph and all(not capacity.common.selected(selected, root) for root in capacity.ROOTS)
    source = graph[selected]
    changed = source.replace(capacity.common.field(source, 'Goal').encode(), b'Altered unrelated goal.', 1)
    assert changed != source
    cases = (
        ('changed-declared-goal', before.replace(source, changed, 1),
         compacted.replace(source, changed, 1), final.replace(source, changed, 1)),
        ('omitted-declared-node', before.replace(source, b'', 1),
         compacted.replace(source, b'', 1), final.replace(source, b'', 1)),
        ('lost-final-node', before, compacted, final.replace(source, b'', 1)),
        ('changed-final-goal', before, compacted, final.replace(source, changed, 1)),
        ('changed-final-footer', before, compacted, final + b'\nUnowned footer.\n'),
    )
    outcomes = []
    for label, declared, retained, delivered in cases:
        try:
            conservation(original, declared, retained, delivered)
        except AssertionError as error:
            outcomes.append(dict(label=label, before=capacity.prepare.blob(declared),
                                 compacted=capacity.prepare.blob(retained), final=capacity.prepare.blob(delivered),
                                 refusal=str(error)))
        else:
            raise AssertionError('changed whole task delivery admitted: ' + label)
    for label in ('pending-owner', 'narrowed-owner-goal', 'float-proof-size'):
        candidate = copy.deepcopy(value)
        if label == 'float-proof-size':
            candidate['proof']['bytes'] = float(candidate['proof']['bytes'])
        else:
            current = capacity.common.nodes(final)[capacity.OWNER]
            if label == 'pending-owner':
                changed = current.replace(b'  Status: `done`', b'  Status: `pending`', 1)
            else:
                changed = current.replace(capacity.common.field(current, 'Goal').encode(), b'Narrowed owner goal.', 1)
            assert changed != current
            candidate['final'] = capacity.prepare.blob(final.replace(current, changed, 1))
        try:
            review(candidate, raw, proof)
        except AssertionError as error:
            if label == 'float-proof-size':
                assert str(error) == 'JSON value kind'
            outcomes.append(dict(label=label, candidate=candidate, refusal=str(error)))
        else:
            raise AssertionError('changed final task record admitted: ' + label)
    return outcomes


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--write', action='store_true')
    mode.add_argument('--current', action='store_true')
    args = parser.parse_args()
    raw, proof = context()
    if args.write:
        value = dict(schema='fsmgen.closed_task_delivery.v1', scope=SCOPE,
            proof=capacity.prepare.blob(raw), final=capacity.prepare.blob(capacity.execute.read(capacity.common.TASK)),
            programmes={name: capacity.prepare.blob(capacity.execute.read(capacity.BASE / name))
                        for name in (SELF, 'closed_task_capacity.py')})
    else:
        record = json.loads(gzip.decompress(capacity.execute.read(PATH)))
        assert set(record) == {'result', 'controls'}
        value = record['result']
    assert review(value, raw, proof)
    result = dict(result=value, controls=controls(value, raw, proof))
    if args.write:
        capacity.execute.save(PATH, result)
    else:
        equal(result, record)
    if args.current:
        capacity.current_admission()
        graph = capacity.common.nodes(capacity.execute.read(capacity.common.TASK))
        for root in capacity.ROOTS:
            equal(graph[root], capacity.terminal(root, unpack(proof['original']), len(proof['subtrees'][root])))
    print('Complete native declaration, retained task source and final delivery reconstruct; genuine unrelated-edit/member/owner/type controls refuse.')
