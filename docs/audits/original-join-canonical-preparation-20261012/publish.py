"""Close only canonical preparation; production and original parent acceptance stay open."""
from preparation_common import *
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
         'exact active owned canonical preparation')
    evidence = (
        'Complete non-growing original join canonical preparation binds fixed committed 192c9dae source-first associations and every unchanged original parent/descendant contract. '
        'The complete independent association meaning is freshly rederived; source/current epochs conserve every original model, native/control/failure/repair product. '
        'F2 declaration-order invariance failed at the intended native first cause and passes after the exact one-line sorted-key repair with every case meaning retained. All earlier valid native cases, the raced queue annotation/correction, parent exit143 and incomplete source census with unknown native outcome remain separately bound; fresh versioned source/control/delivery epochs qualify only this preparation. Every old canonical fact/question/probe and unrelated source retains. Only the reviewed joined-source statement, equivalent prose contractions and fact date change prospectively; maintained production and all twelve helper bodies remain unchanged. '
        'The first oversized static projection remains a rejected read-only design measurement, not a native verification failure. Both prior actual0/declared1 primitive-kind false greens remain failed with exact typed repairs and corrected native first refusals. '
        'Genuine whole prospective source/meaning/omission/kind/false-green/native-promotion/scope/capacity controls reach intended actual native first refusals. '
        'Claim legs are complete independent original association and unchanged contract/fact/route/capacity rederivation; genuinely changed native candidates separating borrowed, omitted, malformed, false-green or promoted meanings; and committed complete source/input/native/failure/repair/programme/publication epochs with sealed/default recovery and normal hooks. '
        'Explicit engineering equivalence review is not universal natural-language proof. Qualified old source-derived causes and typed truths are shared premises; native passed flags never supply truth. '
        'The first complete association replay remains actual137/declared0 at the unchanged host88.2%/cutoff88%; full source/native custody and the post-stop survey retain. External resource trajectories qualify subsequent conserving native delivery without attributing an unobserved first-run allocation or changing the original verifier/guard. A local mutation script syntax failure occurred before execution and is separately retained. Current source/query/book/native/focused/size/claim/inventory/staged/normal delivery closes only preparation. Original assumptions and dated execution/native/private/provider/formatter/encoding/hidden identity limits retain. '
        'Production, original parents, full alias and broader product/semantic/cold/permanent/host-native/private/visual/HIAL/full-CI/push remain separate.')
    changed = block.replace(b'  Status: `active`', b'  Status: `done`', 1)
    changed, count = re.subn(rb'^  Verification: `.*`$', ('  Verification: `' + evidence + '`').encode(), changed, count=1, flags=re.M)
    need(count == 1, 'exact owned preparation verification field')
    changed = changed.replace(b'  Commit: `pending`',
        ('  Commit: `' + owner + ': prepare non-growing original join canonical meanings`').encode(), 1)
    changed, count = re.subn(rb'^  Finding F2 P2.*$', b'  Finding F2 resolution: `Canonical roundtrip declaration order is invariant after the exact one-line sorted-key repair; the identical probe changed native1 to native0 with complete case meanings conserved. Full first and repaired source/native epochs, the first inaccurate queue annotation and explicit correction, driver exit143 and incomplete census with unknown native outcome retain. Fresh versioned source/control/current/delivery and saved reconstruction qualify only preparation.`', changed, count=1, flags=re.M)
    need(count == 1, 'exact owned ordering finding resolution')
    changed = changed.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S locates the unchanged full original join requirement. Complete independently qualified context/cause/coordinate/consumer associations need a source-bound, non-growing canonical proposal before production admission; existing fact/question/probe and native/private boundaries remain mandatory.\n'
        '  - [x] **ADDRESSED (verified)** — Independent unchanged association reexecution and complete paragraph/source/contract/capacity correspondence qualify only reviewed finite joined meanings. Genuine native wrong-source, omission, typed-kind, false-green, scope, promotion and capacity candidates reach intended first refusals. All prior first failures and exact repairs remain bound.\n'
        '  - [x] **NO REGRESSION** — All tests successful in focused publication/stream/task/claim/disposition/book audits. Current source/query/capacity/book/native/size/claim/inventory, sealed/default saved reconstruction, staged scripts/check_doctrines.sh and normal hooks qualify preparation with unchanged production and all twelve maintained helper interfaces.\n'
        '  Finding F1 resolution: `First association native replay remains actual137/declared0, with complete first source/metadata/native epochs and unchanged host cutoff report. The post-stop survey cannot retrospectively attribute allocations. Subsequent complete replay and delivery require external host/process trajectories and unchanged source/guard; no first-run allocation or universal timing guarantee is inferred. The pre-execution local edit syntax failure retains its exact terminal and complete unaffected programme epoch.`\n\n').encode()
    need(before[TASK].count(block) == 1, 'whole unique owned preparation beforeimage')
    task = before[TASK].replace(block, changed, 1)
    review = json.loads((BASE / 'book-review.json').read_bytes())
    book = before[BOOK]
    anchor, guide = review['anchor'].encode(), (BASE / 'guide.txt').read_bytes()
    need(book.count(anchor) == 1, 'unique retained independent association notice')
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
                authority_id='ORIGINAL-JOIN-CANONICAL-PREPARATION-20261012', owner=owner,
                baseline={key: measured_before[key] for key in keys},
                delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Document the reviewed prospective non-growing canonical original join and separate production/parent acceptance. Every existing prose fact, command, numeric claim, encoding disposition, native/private limit and unchanged ceiling retains.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active preparation pointer')
    memory = memory.replace(owner + '` (active)', PLAN['publication'] + '` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Publish the committed reviewed non-growing original join canonical proposal; preserve all facts, contracts and native/private limits.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None; derive preparation receipts under docs/audits/original-join-canonical-preparation-20261012.', memory, flags=re.M)
    marker = b'context/cause/consumer canonical preparation active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique owned index marker')
    index = before['docs/TASK_TREE.md'].replace(marker, b'context/cause/consumer canonical publication next.', 1)
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
                 and field(last[name], 'Status') == 'done', 'unchanged complete closed preparation contract')
        else:
            need(block == last[name], 'every unrelated whole task block retains')
    need(field(last[PLAN['parent']], 'Status') == 'active'
         and all(field(last[PLAN[name]], 'Status') == 'pending' for name in ('publication', 'acceptance', 'full_alias')),
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
    print('Published only preparation evidence; canonical production and original parents remain separate.')
