"""Recover only owned metadata and whitespace after the sealed first epoch."""
import argparse
from publication_common import *
import intake
import publish

NAMES = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md', PLAN['target'])
REOPEN = ('Staged whitespace gate failed native2 before doctrine execution: new guide.txt and publication_common.py have blank lines at EOF. Own the style repair here; preserve the sealed first epoch and qualify exact current recovery. First completed delivery evidence: ')
FINDING = ('First staged git diff --cached --check refused native2 on exactly two new EOF blank lines. Development omitted this inspection. Preserve the complete sealed first programme/proof/catalogue/native epoch; exact source patches trim the two lines, restore the original guide inside the publisher, and delegate only the default entrypoint to recovered qualification. Published card/book/current input, old helpers, original failures and scope remain unchanged. Fresh source, focused, size, claim/inventory, staged whitespace/doctrine and normal gates qualify this same owner without widening authority.')


def snapshots():
    row = json.loads((BASE / 'publication.json').read_bytes())
    result = {}
    for name in NAMES:
        role = row['snapshots'][name]['after']
        body = gzip.decompress(Path(role['snapshot']).read_bytes())
        need(pin(body) == role['identity'], 'whole immutable first publication afterimage')
        result[name] = body
    return result


def transformation():
    first = snapshots()
    reopened = dict(first)
    for i, name in enumerate((TASK, 'MEMORY.md', 'docs/TASK_TREE.md')):
        reopened[name] = gzip.decompress((BASE / ('reopened-' + str(i) + '.gz')).read_bytes())
    owner = PLAN['owner']
    block = nodes(first[TASK])[owner]
    active = block.replace(b'  Status: `done`', b'  Status: `active`', 1)
    active = active.replace(b'  Verification: `', ('  Verification: `' + REOPEN).encode(), 1)
    need(reopened[TASK] == first[TASK].replace(block, active, 1), 'whole exact whitespace-failure owner reopening')
    memory = first['MEMORY.md'].replace((PLAN['parent'] + '.3` (pending)').encode(), (owner + '` (active)').encode(), 1)
    memory = re.sub(rb'^- next_action:.*$', b'- next_action: Repair the owned staged whitespace failure; retain sealed first evidence and qualify the corrected source epoch before committing publication.', memory, flags=re.M)
    need(reopened['MEMORY.md'] == memory and reopened['docs/TASK_TREE.md'] == first['docs/TASK_TREE.md'].replace(
        b'canonical publication done; acceptance next.', b'canonical publication recovery active.', 1), 'whole exact bounded recovery pointers')
    after = dict(first)
    verification = field(block, 'Verification')
    final = block.replace(('  Verification: `' + verification + '`').encode(), ('  Verification: `' + verification + ' ' + FINDING + '`').encode(), 1)
    final = final.replace(b'git log -S cause_fact.cards locates', b'First staged git diff --cached --check native2 locates the omitted EOF-whitespace inspection. git log -S cause_fact.cards locates', 1)
    final = final.rstrip() + ('\n  Finding F2: `' + FINDING + '`\n\n').encode()
    after[TASK] = first[TASK].replace(block, final, 1)
    rows = list(map(json.loads, first[REGISTRY].splitlines()))
    publication = json.loads((BASE / 'publication.json').read_bytes())
    tasks = fixed(publication['task_names'])
    tasks[TASK] = after[TASK]
    measured = metrics(tasks)
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            for key, value in measured.items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged recovered task ceilings')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'active_resume':
            need(all(value * 100 < row['milestones']['warning_pct'] * row['health_targets'][key]
                     for key, value in metrics({'MEMORY.md': after['MEMORY.md']}).items() if key != 'files'), 'complete recovered resume health')
    after[REGISTRY] = b''.join(canonical(row) for row in rows)
    first_nodes, final_nodes = nodes(first[TASK]), nodes(after[TASK])
    need(first_nodes.keys() == final_nodes.keys() and all(first_nodes[name] == final_nodes[name]
         for name in first_nodes if name != owner), 'all unrelated complete task contracts retain')
    need(all(field(block, key) == field(final_nodes[owner], key) for key in ('Goal', 'Acceptance', 'Children', 'Commit', 'Status')),
         'unchanged owner contract and completion role')
    need(all(after[name] == first[name] for name in (BOOK, 'MEMORY.md', 'docs/TASK_TREE.md', PLAN['target'])),
         'whole published book/card and final pointers remain exact')
    return first, reopened, after, measured


def qualify(*, current=False):
    first, reopened, after, measured = transformation()
    row = json.loads((BASE / 'recovery.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and row['task_metrics'] == measured
         and row['snapshots'] == {name: pin(body) for name, body in after.items()}, 'whole recovered metadata qualification')
    for i, name in enumerate(NAMES):
        body = gzip.decompress((BASE / ('recovery-after-' + str(i) + '.gz')).read_bytes())
        need(body == after[name], 'whole exact recovered metadata snapshot')
        if current:
            need(Path(name).read_bytes() == body, 'whole explicitly current recovered metadata')
    return row


def source():
    qualify(current=True)
    _, _, after, _ = transformation()
    roles = json.loads((BASE / 'source-roles.json').read_bytes())
    previous = intake.overlays
    try:
        intake.overlays = lambda after_epoch=False: dict(previous(after_epoch), **after) if after_epoch else previous()
        result = intake.live(roles, True)
    finally:
        intake.overlays = previous
    save('recovery-source.json', result)
    print('PASS whole recovered current source and exact metadata overlays; original and first epochs retain.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', action='store_true')
    args = parser.parse_args()
    if args.source:
        source()
    else:
        first, reopened, after, measured = transformation()
        need(all(Path(name).read_bytes() == body for name, body in reopened.items()), 'whole current reopened whitespace-repair input')
        for i, name in enumerate(NAMES):
            path = BASE / ('recovery-after-' + str(i) + '.gz')
            need(not path.exists(), 'fresh whole recovered metadata snapshot')
            path.write_bytes(gzip.compress(after[name], mtime=0))
        save('recovery.json', dict(owner=PLAN['owner'], task_metrics=measured,
             snapshots={name: pin(body) for name, body in after.items()},
             scope='Owned source-whitespace recovery and truthful task evidence only; all published meanings and authority limits retain.'))
        for name, body in after.items():
            Path(name).write_bytes(body)
        print('Published exact owned whitespace-recovery metadata; whole canonical card/book retain.')
