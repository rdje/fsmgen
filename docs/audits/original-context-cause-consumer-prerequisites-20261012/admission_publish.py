"""Publish only prerequisite admission; association and parent remain separate."""
from admission_common import *
import intake

NAMES = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md')
COMMANDS = {
    'focused': ['prove', '-v', 't/2066-record-value-current-publication.t',
        't/2067-record-value-gate-streams.t', 't/1549-task-tree-integrity-doctrine.t',
        't/1636-claim-verification-doctrine.t', 't/1638-claim-verification-dispositions.t',
        't/1303-isf-public-live-book-paths-audit.t', 't/1305-isf-book-feature-matrix-audit.t'],
    'book': ['mdbook', 'build', 'docs/book'],
    'native': ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', 'docs/book/book'],
    'size': ['scripts/check_live_document_size.sh'],
    'claims': ['scripts/check_claim_verification.pl'],
    'inventory-write': ['scripts/check_claim_verification_inventory.pl', '--write'],
    'inventory': ['scripts/check_claim_verification_inventory.pl']}


def transformation(before):
    original = nodes(before[TASK])
    owner = PLAN['owner']
    block = original[owner]
    need(field(block, 'Status') == 'active' and field(block, 'Commit') == 'pending',
         'exact active owned prerequisite admission')
    evidence = (
        'Complete original context/cause/coordinate/consumer prerequisites are admitted at fixed e646348. '
        'Every unchanged join/container/descendant Goal and Acceptance, source/native/model/product population, first failure/repair and qualified source-role/native/private boundary retains. '
        'Fresh native complete context, cause-container and original-consumer saved readers execute between identical whole source censuses; isolated whole-source executions independently reconstruct every complete saved meaning and control. '
        'The context reader records caught library ValueError refusals, not separate native exit1 receipts. Dated primary/coordinate/address native epochs remain dated; no original recapture or later historical-programme currency follows. '
        'All canonical facts/questions/probes and twelve maintained helper interfaces conserve. Both unwrapped preparation actual1 terminals retain with null predeclared statuses and explicit after-invocation source reconstructions. The failed first proposal precedes all writes; the second informational print failure follows the preserved corrected metadata and five programmes. '
        'Claim legs are unchanged whole contracts and fresh complete saved-meaning/source/current rederivation; complete inherited genuine source/context/cause/coordinate/address/consumer separating controls and their actual intended outcomes; and committed whole programmes/inputs/native commands/statuses/streams/products/failures/source/publication snapshots with sealed/default recovery and normal hooks. '
        'Current source/query/capacity/book/native/focused/claim/inventory/staged/normal delivery closes only admission. Independent association, canonical/parent acceptance, full alias and product/semantic/cold/permanent/host-native/private/visual/HIAL/full-CI/push remain open.')
    changed = block.replace(b'  Status: `active`', b'  Status: `done`', 1)
    changed = changed.replace(b'  Verification: `pending`', ('  Verification: `' + evidence + '`').encode(), 1)
    changed = changed.replace(b'  Commit: `pending`',
        ('  Commit: `' + owner + ': admit original context cause consumer prerequisites`').encode(), 1)
    changed = changed.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S locates the unchanged original join requirement. Its three completed children qualify separate meanings; a join must admit their whole contracts/source/native epochs before independently associating them. The context reader catches library refusals, and historical coordinate/address receipts remain dated.\n'
        '  - [x] **ADDRESSED (verified)** — Complete native context/cause/consumer saved replays and isolated whole-source proof rederivation conserve all source roles, meanings, genuine controls, first failures and native/private assumptions. Only admission closes; association and parent acceptance remain separately pending.\n'
        '  - [x] **NO REGRESSION** — All tests successful in focused publication/stream/task/claim/disposition/book audits. Current source/query/capacity/book/native/size/claim/inventory, sealed/default reconstruction, staged scripts/check_doctrines.sh and normal hooks qualify delivery without changing canonical facts or maintained helper interfaces.\n'
        '  Finding F1 resolution: `Both unwrapped failed preparations retain their complete terminals, null predeclared statuses and explicit after-invocation source reconstructions. The corrected static proposal uses one additional equivalent interface-prose compaction; all existing partial files retain. Final programmes do not execute the broken informational creation tail. Complete projected and actual source/book/native/capacity/saved gates verify the admitted correction.`\n\n').encode()
    need(before[TASK].count(block) == 1, 'whole unique owned admission beforeimage')
    task = before[TASK].replace(block, changed, 1)
    review = json.loads((BASE / 'book-review.json').read_bytes())
    book = before[BOOK]
    anchor, guide = review['anchor'].encode(), (BASE / 'guide.txt').read_bytes()
    need(book.count(anchor) == 1, 'unique retained cause-container notice')
    book = book.replace(anchor, anchor + b'\n' + guide, 1)
    for old, new in review['book_compactions']:
        need(book.count(old.encode()) == 1, 'whole reviewed prose beforeimage')
        book = book.replace(old.encode(), new.encode(), 1)
    need(len(before[BOOK]) == review['before_bytes'] and len(book) == review['after_bytes']
         <= review['before_bytes'] <= 292485, 'non-growing chapter and unchanged ceiling')
    for command in re.findall(rb'```(?:bash|sh)\n(.*?)```', before[BOOK], re.S):
        need(book.count(command) == before[BOOK].count(command), 'all original runnable commands retain')
    for line in before[BOOK].splitlines():
        if re.search(rb'[0-9]', line):
            need(book.splitlines().count(line) == before[BOOK].splitlines().count(line),
                 'all original numeric claims/dispositions retain')
    names = git('ls-tree', '-r', '--name-only', PLAN['revision']).decode().splitlines()
    task_names = sorted(name for name in names if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name))
    book_names = sorted(name for name in names if re.fullmatch(r'docs/book/src/[^/]+\.md', name))
    tasks, books = fixed(task_names), fixed(book_names)
    measured_before = metrics(books)
    tasks[TASK], books[BOOK] = task, book
    measured_tasks, measured_books = metrics(tasks), metrics(books)
    rows = list(map(json.loads, before[REGISTRY].splitlines()))
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            for key, value in measured_tasks.items():
                need(row['enforcement_ceilings'][key] is None or value <= row['enforcement_ceilings'][key],
                     'all unchanged task ceilings')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(
                authority_id='ORIGINAL-CONTEXT-CAUSE-CONSUMER-PREREQUISITES-20261012', owner=owner,
                baseline={key: measured_before[key] for key in keys},
                delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Document admission of separately qualified context/cause/consumer meanings. Equivalent prose compactions preserve feature/support/navigation/interface boundaries; all commands, numeric claims, encoding dispositions and canonical authority retain.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active admission pointer')
    memory = memory.replace(owner + '` (active)', PLAN['association'] + '` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate independent original source/context/cause/coordinate/consumer association from committed complete prerequisite admission; preserve each original meaning and limit.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None; derive prerequisite receipts under docs/audits/original-context-cause-consumer-prerequisites-20261012.', memory, flags=re.M)
    marker = b'context/cause/consumer admission active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique owned index marker')
    index = before['docs/TASK_TREE.md'].replace(marker, b'context/cause/consumer association next.', 1)
    return {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows),
            'MEMORY.md': memory.encode(), 'docs/TASK_TREE.md': index}, dict(
                task_names=task_names, book_names=book_names, task_metrics=measured_tasks,
                book_before=measured_before, book_after=measured_books)


def qualify(current=False):
    row = json.loads((BASE / 'publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == set(NAMES), 'whole owned publication domain')
    before, after = {}, {}
    for name, roles in row['snapshots'].items():
        need(set(roles) == {'before', 'after'}, 'whole publication role pair')
        for role, entry in roles.items():
            path = Path(entry['snapshot'])
            need(path.parent == BASE and path.name.startswith('publication-' + role + '-')
                 and path.suffix == '.gz' and not path.is_symlink(), 'ordinary owned whole source snapshot')
            body = gzip.decompress(path.read_bytes())
            need(pin(body) == entry['identity'], 'whole snapshot identity')
            (before if role == 'before' else after)[name] = body
        if current:
            need(Path(name).read_bytes() == after[name], 'whole current publication')
    wanted, measured = transformation(before)
    need(wanted == after and all(row[key] == value for key, value in measured.items()), 'whole reconstructed publication')
    first, last = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == last.keys(), 'whole task membership retains')
    for name, block in first.items():
        if name == PLAN['owner']:
            need(all(field(block, key) == field(last[name], key) for key in ('Goal', 'Acceptance', 'Children'))
                 and field(last[name], 'Status') == 'done', 'unchanged complete closed admission contract')
        else:
            need(block == last[name], 'every unrelated whole task block retains')
    need(field(last[PLAN['parent']], 'Status') == 'active'
         and all(field(last[PLAN[name]], 'Status') == 'pending' for name in ('association', 'acceptance', 'full_alias')),
         'association/parent/full-alias closure remains separate')
    return row


if __name__ == '__main__':
    before = {name: Path(name).read_bytes() for name in NAMES}
    need(all(before[name] == body for name, body in intake.overlays().items()), 'whole qualified activation metadata')
    after, measured = transformation(before)
    snapshots = {}
    for i, name in enumerate(NAMES):
        snapshots[name] = {}
        for role, body in (('before', before[name]), ('after', after[name])):
            path = BASE / ('publication-' + role + '-' + str(i) + '.gz')
            need(not path.exists(), 'retain first whole publication source')
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    need(not (BASE / 'publication.json').exists(), 'retain first whole publication record')
    for name, roles in snapshots.items():
        for role, entry in roles.items():
            Path(entry['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, **measured))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole final beforeimage conservation')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published only original context/cause/consumer prerequisite admission; higher owners retain.')
