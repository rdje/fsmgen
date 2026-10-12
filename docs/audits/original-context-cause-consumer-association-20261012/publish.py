"""Publish only the independent association; canonical/parent acceptance stays open."""
from association_common import *
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
         'exact active owned independent association')
    evidence = (
        'Complete original context/cause/coordinate/consumer associations are independently source-first qualified at fixed de401bf. '
        'Every original admitted source/native/model/product and unchanged contract retains. Mode-first proposals are consumed by independent helper/parser membership inversions and source-origin selection, including full caller/kind/span, private-copy recorded API, primary/raw/empty/nested/coordinate/address and typed consumer operand/truth roles. '
        'Every complete original saved admission meaning is freshly reexecuted between conserving whole source epochs. Qualified source-derived causes/truth are explicit shared premises; native passed flags never supply truth. '
        'Genuine complete mutations reach their intended actual native first refusals. Two first malformed Boolean/float development probes remain actual0/declared1 false greens with full source/input/native custody. Canonical typed equality repairs reject both at the intended checks and preserve the complete positive input. '
        'All original source-model assumptions, first failures, Storable primitive kinds and synthetic opaque traces retain. Dated native coordinate/address/control epochs remain dated; original native/private/provider/formatter/encoding/hidden identities remain unmeasured. '
        'Claim legs are complete source-first association and unchanged-contract/saved-meaning/source/current rederivation; genuine wrong/borrowed/omitted/ordered/mode/coordinate/kind/false-green/source/cause/native-promotion controls with real first refusals and preserved first false greens; and full committed programmes/inputs/native commands/statuses/streams/products/source/publication/failure/repair epochs plus sealed/default recovery and normal hooks. '
        'Current source/query/capacity/book/native/focused/claim/inventory/staged/normal delivery closes only association. Canonical/parent acceptance, full alias and product/semantic/cold/permanent/host-native/private/visual/HIAL/full-CI/push remain separate.')
    changed = block.replace(b'  Status: `active`', b'  Status: `done`', 1)
    changed, count = re.subn(rb'^  Verification: `.*`$', ('  Verification: `' + evidence + '`').encode(), changed, count=1, flags=re.M)
    need(count == 1, 'exact owned association verification field')
    changed = changed.replace(b'  Commit: `pending`',
        ('  Commit: `' + owner + ': qualify original context cause consumer associations`').encode(), 1)
    changed = changed.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S identifies the unchanged full original join requirement. Separate qualified meanings need complete source-first associations; Python equality at reader.py reference/pin comparisons accepted Boolean/integer and float/integer aliases in two genuine native probes (actual0/declared1).\n'
        '  - [x] **ADDRESSED (verified)** — Independent helper/parser inversions and consumer-origin selection bind every complete original mode/domain relationship. Canonical JSON equality rejects both malformed typed references at their intended actual native first refusals; complete positive, genuine separating controls and fresh whole saved admission reexecution qualify all original shared premises and limits.\n'
        '  - [x] **NO REGRESSION** — All tests successful in focused publication/stream/task/claim/disposition/book audits. Current source/query/capacity/book/native/size/claim/inventory, sealed/default complete reconstruction, staged scripts/check_doctrines.sh and normal hooks qualify delivery with unchanged canonical facts and twelve helper interfaces.\n'
        '  Finding F1 resolution: `Both actual0/declared1 false greens retain whole first programmes, inputs, command, status and streams. The exact canonical typed-equality repair and capture metadata expansion retain full before/after source/diffs. Both corrected native probes reach intended actual1/declared1 first refusals; the whole positive interface remains actual0/declared0. Formal controls and complete delivery/recovery verify the fix without changing any original admitted meaning or promoting either failed probe.`\n\n').encode()
    need(before[TASK].count(block) == 1, 'whole unique owned association beforeimage')
    task = before[TASK].replace(block, changed, 1)
    review = json.loads((BASE / 'book-review.json').read_bytes())
    book = before[BOOK]
    anchor, guide = review['anchor'].encode(), (BASE / 'guide.txt').read_bytes()
    need(book.count(anchor) == 1, 'unique retained prerequisite admission notice')
    book = book.replace(anchor, anchor + b'\n' + guide, 1)
    for old, new in review['book_compactions']:
        need(book.count(old.encode()) == 1, 'whole reviewed prose beforeimage')
        book = book.replace(old.encode(), new.encode(), 1)
    need(len(before[BOOK]) == review['before_bytes'] and len(book) == review['after_bytes']
         <= 292485, 'reviewed bounded chapter growth and unchanged ceiling')
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
                authority_id='ORIGINAL-CONTEXT-CAUSE-CONSUMER-ASSOCIATION-20261012', owner=owner,
                baseline={key: measured_before[key] for key in keys},
                delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Document independently qualified complete source-first associations and their exact saved-reader command. Reviewed interface/reset/feedback prose compactions retain all meanings; all old commands, numeric claims, encoding dispositions, native/private limits and unchanged ceilings retain.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active association pointer')
    memory = memory.replace(owner + '` (active)', PLAN['acceptance'] + '` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate whole original context/cause/consumer canonical and parent acceptance from the committed independent association; preserve every original contract and limit.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None; derive association receipts under docs/audits/original-context-cause-consumer-association-20261012.', memory, flags=re.M)
    marker = b'context/cause/consumer association active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique owned index marker')
    index = before['docs/TASK_TREE.md'].replace(marker, b'context/cause/consumer parent acceptance next.', 1)
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
                 and field(last[name], 'Status') == 'done', 'unchanged complete closed association contract')
        else:
            need(block == last[name], 'every unrelated whole task block retains')
    need(field(last[PLAN['parent']], 'Status') == 'active'
         and all(field(last[PLAN[name]], 'Status') == 'pending' for name in ('acceptance', 'full_alias')),
         'canonical/parent/full-alias closure remains separate')
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
    print('Published only independent original context/cause/coordinate/consumer association; canonical/parent and higher owners retain.')
