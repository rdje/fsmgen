"""Recover only pointer health and truthful current preparation metadata."""
import argparse
from canonical_common import *
import intake
import publish

NAMES = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md')
SHORT_NEXT = '- next_action: Activate maintained consumer canonical publication .2 from the committed proposal; preserve original facts, probes, limits and authority. Canonical/original consumer acceptance follows separately.'


def snapshots():
    publication = json.loads((BASE / 'publication.json').read_bytes())
    return {name: gzip.decompress(Path(row['after']['snapshot']).read_bytes()) for name, row in publication['snapshots'].items()}


def transformation():
    first = snapshots()
    reopened = dict(first)
    reopened[TASK] = gzip.decompress((BASE / 'reopened-0.gz').read_bytes())
    reopened['MEMORY.md'] = gzip.decompress((BASE / 'reopened-1.gz').read_bytes())
    original, active = nodes(first[TASK]), nodes(reopened[TASK])
    need(original.keys() == active.keys(), 'whole recovery task domain retains')
    owner = PLAN['owner']
    for name, block in original.items():
        if name != owner:
            need(active[name] == block, 'every unrelated recovery task contract retains')
        else:
            expected = block.replace(b'  Status: `done`', b'  Status: `active`', 1)
            expected = re.sub(rb'^  Verification: `.*`$', b'  Verification: `First formal size gate failed actual1/expected0: the new next_action pointer pushed active_resume to 81.8 percent and the existing milestone requires warning_debt. The publisher omitted the pointer health threshold from development capacity checks. Own and repair now under this unchanged preparation leaf; retain all first programmes/source/publication/native evidence and verify bounded pointer recovery without authority growth. See docs/audits/consumer-canonical-preparation-20261012/defect.json.`', expected, flags=re.M)
            need(active[name] == expected, 'whole exact actual-failure owner reopening')
            need(all(field(block, key) == field(active[name], key) for key in ('Goal', 'Acceptance', 'Commit', 'Children'))
                 and field(block, 'Status') == 'done' and field(active[name], 'Status') == 'active',
                 'only current unchanged owner reopens for actual formal failure')
    wanted_memory = re.sub(rb'^- active_work_unit:.*$', ('- active_work_unit: `' + owner + '` (active)').encode(), first['MEMORY.md'], flags=re.M)
    wanted_memory = re.sub(rb'^- next_action:.*$', b'- next_action: Repair the owned resume-pressure delivery failure; preserve the first epoch and qualify bounded pointer recovery before committing canonical preparation.', wanted_memory, flags=re.M)
    need(reopened['MEMORY.md'] == wanted_memory, 'whole explicit bounded recovery input pointer')
    after = dict(first)
    before_owner = original[owner]
    evidence = field(before_owner, 'Verification') + ' First formal size gate failed actual1/expected0 because the publisher next_action crossed the active_resume warning milestone. Original eleven programmes, first proposal/publication and failed native terminal remain immutable. A separately source-bound recovery shortens only the pointer, reopens and requalifies this unchanged owner, recalculates task ratchets without widening ceilings, and preserves all other metadata/book/canonical meanings. Controlled old-pointer native size refusal and restored-pointer success isolate the mechanism; exact first/current programme correspondence and default recovery retain both epochs.'
    changed = before_owner.replace(('  Verification: `' + field(before_owner, 'Verification') + '`').encode(), ('  Verification: `' + evidence + '`').encode(), 1)
    changed = changed.replace(b'git log -S Publish only admitted source-bound consumer canonical meanings. locates', b'First formal live-doc-size active_resume warning refusal locates the pointer health omission. git log -S Publish only admitted source-bound consumer canonical meanings. locates', 1)
    changed = changed.rstrip() + b'\n  Finding F1: `First native size gate actual1/expected0: next_action reached the active_resume warning threshold. Pointer health was absent from the development capacity probe. Repair is owned here now; preserve first source/native evidence, demonstrate old-pointer refusal and bounded-pointer success, then admit exact recovered metadata/default custody without allowance growth.`\n\n'
    after[TASK] = first[TASK].replace(before_owner, changed, 1)
    after['MEMORY.md'] = re.sub(rb'^- next_action:.*$', SHORT_NEXT.encode(), first['MEMORY.md'], flags=re.M)
    rows = list(map(json.loads, first[REGISTRY].splitlines()))
    publication = json.loads((BASE / 'publication.json').read_bytes())
    tasks = fixed(publication['task_names']); tasks[TASK] = after[TASK]
    measured = metrics(tasks)
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            for key, value in measured.items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged recovery task ceilings')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'active_resume':
            actual = metrics({'MEMORY.md': after['MEMORY.md']})
            # Warning semantics use the reviewed health target, not the larger ceiling.
            need(all(value * 100 < row['milestones']['warning_pct'] * row['health_targets'][key]
                     for key, value in actual.items() if key != 'files'), 'bounded recovered resume health')
    after[REGISTRY] = b''.join(canonical(row) for row in rows)
    need(all(after[name] == first[name] for name in (BOOK, 'docs/TASK_TREE.md')), 'whole book/index and all original canonical scope retain')
    return first, reopened, after, measured


def qualify(*, current=False):
    first, reopened, after, measured = transformation()
    row = json.loads((BASE / 'recovery.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and row['task_metrics'] == measured and row['repair'] == 'pointer health and truthful owner verification only', 'closed exact recovery role')
    need(row['snapshots'] == {name: pin(body) for name, body in after.items()}, 'whole recovered metadata afterimages')
    for i, name in enumerate(NAMES):
        body = gzip.decompress((BASE / ('recovery-after-' + str(i) + '.gz')).read_bytes())
        need(body == after[name], 'whole exact saved recovery metadata')
        if current:
            need(Path(name).read_bytes() == body, 'whole explicitly current recovered metadata')
    return row


def source():
    qualify(current=True)
    _, _, after, _ = transformation()
    roles = json.loads((BASE / 'source-roles.json').read_bytes())
    previous = intake.overlays
    try:
        intake.overlays = lambda after_epoch=False: after if after_epoch else previous()
        result = intake.live(roles, True)
    finally:
        intake.overlays = previous
    save('recovery-source.json', result)
    print('PASS complete current repaired source census and exact pointer metadata.')


def negative(before):
    _, _, after, _ = transformation()
    first = snapshots()
    if before:
        qualify(current=True)
        save('negative-source-before.json', dict(before={name: pin(body) for name, body in after.items()},
            changed_only='MEMORY.md', replacement=pin(first['MEMORY.md']), role='Controlled source intervention for actual native size refusal, never original semantic recapture.'))
        Path('MEMORY.md').write_bytes(first['MEMORY.md'])
        print('Prepared only the original over-warning pointer for the native separating control.')
    else:
        need(Path('MEMORY.md').read_bytes() == first['MEMORY.md']
             and all(Path(name).read_bytes() == body for name, body in after.items() if name != 'MEMORY.md'), 'only intended negative pointer intervention occurred')
        refusal = json.loads((BASE / 'size-reproduce-actual.json').read_bytes())
        need(type(refusal['status']) is int and refusal['status'] == 1
             and type(refusal['expected_status']) is int and refusal['expected_status'] == 1
             and 'live-doc-size: surface active_resume is at 81.8% and must declare warning_debt' in refusal['stderr'], 'actual intended old-pointer native refusal')
        Path('MEMORY.md').write_bytes(after['MEMORY.md'])
        qualify(current=True)
        save('negative-source-after.json', dict(after={name: pin(body) for name, body in after.items()},
             refusal=pin(canonical(refusal)), residue='Only MEMORY.md was replaced and it exactly regains the repaired bytes; all other maintained metadata conserved.'))
        print('Restored the exact bounded pointer after the genuine native size refusal.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--preview', action='store_true'); parser.add_argument('--source', action='store_true')
    parser.add_argument('--negative-before', action='store_true'); parser.add_argument('--negative-after', action='store_true')
    args = parser.parse_args()
    need(sum((args.preview, args.source, args.negative_before, args.negative_after)) <= 1, 'one explicit recovery role')
    if args.source:
        source()
    elif args.negative_before or args.negative_after:
        negative(args.negative_before)
    else:
        first, reopened, after, measured = transformation()
        need(all(Path(name).read_bytes() == body for name, body in reopened.items()), 'whole current reopened recovery beforeimages')
        if args.preview:
            save_product('recovery-preview.json.gz', {name: body.decode() for name, body in after.items()})
            print('PASS development-only bounded pointer recovery proposal; first formal failure remains non-success.')
        else:
            for i, name in enumerate(NAMES):
                path = BASE / ('recovery-after-' + str(i) + '.gz')
                need(not path.exists(), 'fresh complete recovery metadata snapshot')
                path.write_bytes(gzip.compress(after[name], mtime=0))
            save('recovery.json', dict(owner=PLAN['owner'], task_metrics=measured,
                 snapshots={name: pin(body) for name, body in after.items()}, repair='pointer health and truthful owner verification only'))
            for name, body in after.items():
                Path(name).write_bytes(body)
            print('Published only bounded pointer and truthful preparation recovery; canonical meanings retain.')
