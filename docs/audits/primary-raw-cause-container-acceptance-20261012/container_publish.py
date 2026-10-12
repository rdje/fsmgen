"""Publish only the unchanged original primary/raw cause container acceptance."""
from container_common import *
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
    task = before[TASK]
    owner, parent = PLAN['owner'], PLAN['parent']
    evidence = ('The unchanged original primary/raw container and every completed primary/raw/cause-join descendant contract qualify. '
        'The complete recovered cause reader freshly rederives its whole saved proof: source/context/primary API/helper/parser first causes, acceptance, full raw/empty/nested bodies, class/frame/source-coordinate/address roles, and every genuine original native control retain. '
        'Original source-model assumptions and dated primary/coordinate/address execution epochs remain explicit; no original native/private recapture or later historical-programme currency is inferred. '
        'Complete original/current source censuses conserve around reexecution. Every canonical fact/question/probe and all twelve maintained helper interfaces retain. '
        'F1 is resolved by separately qualifying the containing task after its three completed children; the earlier publisher and all child contracts/proofs remain unchanged. '
        'F2 retains both unwrapped actual1 preparation terminals, null predeclared-status fields, original partial metadata and after-invocation source reconstructions. The corrected proposal binds the fixed-current recovered complete.py command rather than the dated notice. '
        'F3 retains the first complete guarded development preflight actual1/declared0, all seven first programmes/input metadata and the legitimate registry control-row KeyError. Only the two surface selectors change in the minimal repair; the separately successful complete preflight and full source/native epoch ledger precede formal freeze. '
        'Claim legs are unchanged complete contracts and fresh independent recovered cause/current rederivation; complete inherited genuine native wrong-cause/full-stack/caller/context/false-green/omission/source/boundary controls with their intended first outcomes; and committed complete source/programmes/commands/streams/products/failures/snapshots with saved recovery and normal hooks. '
        'Current source/query/book/native/capacity/focused/claim/inventory/staged/normal gates close only this container and acceptance leaf. Higher context/cause/coordinate/consumer join, full alias, product/semantic/cold/permanent/host-native/private/visual/HIAL/full-CI/push owners remain open.')
    for name in (owner, parent):
        block = original[name]
        need(field(block, 'Status') == 'active' and field(block, 'Commit') == 'pending',
             'exact active cause container and owned acceptance leaf')
        changed = block.replace(b'  Status: `active`', b'  Status: `done`', 1)
        changed = changed.replace(('  Verification: `' + field(block, 'Verification') + '`').encode(),
                                  ('  Verification: `' + evidence + '`').encode(), 1)
        changed = changed.replace(b'  Commit: `pending`',
            ('  Commit: `' + owner + ': accept unchanged primary raw cause container`').encode(), 1)
        if name == owner:
            changed = changed.rstrip() + (
                '\n  Acceptance Checklist (enforced):\n'
                '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S CLOSE locates the c7916ce publisher tuple that closed cause-join/canonical nodes while the containing primary/raw task remained active. All three children are done; the higher join requires a complete cause container. The first preparation used a dated notice anchor; the maintained recovered command is complete.py.\n'
                '  - [x] **ADDRESSED (verified)** — Fresh complete recovered cause acceptance and unchanged whole container/descendant contracts qualify source first causes, raw coordinate/address/body custody and genuine original controls. Whole source censuses, canonical facts/questions/probes and every helper interface conserve. Only the original primary/raw container and its new acceptance leaf close; both preparation refusals and original source/native/private limits retain.\n'
                '  - [x] **NO REGRESSION** — All tests successful in focused publication/stream/task/claim/disposition/book audits. Current complete source/query/capacity/book/native, saved recovered-cause and container reconstruction, size/claim/inventory, staged scripts/check_doctrines.sh and normal hooks qualify delivery. The higher join and full alias remain pending.\n'
                '  Finding F1 resolution: `The unchanged containing Goal/Acceptance and all original descendant contracts are separately qualified against complete recovered cause evidence. Only after current delivery gates does the container close; the higher join retains its own pending acceptance.`\n'
                '  Finding F2 resolution: `The fixed-current complete.py command block supplies the reviewed proposal anchor. Both actual1 unwrapped terminals remain failures with null predeclared status and explicit after-invocation source reconstruction. Original notice, reader, predicates and first/repaired child proof epochs remain unchanged; development projection and formal source/book/native/saved gates qualify the correction.`\n\n').encode()
            changed = changed.rstrip() + (
                '\n  Finding F3 resolution: `Preflight uses row.get for both surface selections, preserving the legitimate registry control row. The complete first seven-programme/input/native epoch remains actual1/declared0; the exact minimal repair and independently successful complete second preflight retain. Later verifier changes only authenticate the dated failure/repair epochs, while owned publication evidence records them. Original readers/inputs/predicates/native records remain unchanged; all affected formal/source/book/native/claim/staged/normal gates qualify before closure.`\n\n').encode()
        need(task.count(block) == 1, 'whole unique closure block beforeimage')
        task = task.replace(block, changed, 1)
    review = json.loads((BASE / 'book-review.json').read_bytes())
    anchor, guide = review['anchor'].encode(), (BASE / 'guide.txt').read_bytes()
    book = before[BOOK]
    need(book.count(anchor) == 1, 'unique fixed-current recovered cause command')
    book = book.replace(anchor, anchor + b'\n' + guide, 1)
    for old, new in review['book_compactions']:
        need(book.count(old.encode()) == 1, 'whole reviewed introduction beforeimage')
        book = book.replace(old.encode(), new.encode(), 1)
    need(len(before[BOOK]) == review['before_bytes'] and len(book) == review['after_bytes']
         <= review['before_bytes'] <= 292485, 'non-growing whole book under unchanged ceiling')
    for command in re.findall(rb'```(?:bash|sh)\n(.*?)```', before[BOOK], re.S):
        need(book.count(command) == before[BOOK].count(command), 'every original runnable command retains')
    old_numbers = [line for line in before[BOOK].splitlines() if re.search(rb'[0-9]', line)]
    need(all(book.splitlines().count(line) == before[BOOK].splitlines().count(line) for line in old_numbers),
         'every unchanged numeric claim line and disposition retains')
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
                     'every unchanged task ceiling')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(
                authority_id='PRIMARY-RAW-CAUSE-CONTAINER-ACCEPTANCE-20261012', owner=owner,
                baseline={key: measured_before[key] for key in keys},
                delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Document separately qualified original cause-container acceptance and unchanged source/native/private limits. One reviewed introduction compaction retains examples and navigation; all commands, numeric claims, encoding dispositions and canonical authority remain unchanged.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact owned cause-container pointer')
    memory = memory.replace(owner + '` (active)', PLAN['higher_join'] + '` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate the complete original context/cause/coordinate/consumer join from clean committed cause-container acceptance; qualify all unchanged child meanings.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None; derive cause-container receipts under docs/audits/primary-raw-cause-container-acceptance-20261012.', memory, flags=re.M)
    marker = b'cause container acceptance active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique owned cause-container index marker')
    index = before['docs/TASK_TREE.md'].replace(marker, b'cause container done; meaning join next.', 1)
    after = {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows),
             'MEMORY.md': memory.encode(), 'docs/TASK_TREE.md': index}
    return after, dict(task_names=task_names, book_names=book_names, task_metrics=measured_tasks,
                       book_before=measured_before, book_after=measured_books)


def qualify(current=False):
    row = json.loads((BASE / 'publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == set(NAMES), 'whole owned publication population')
    before, after = {}, {}
    for name, roles in row['snapshots'].items():
        need(set(roles) == {'before', 'after'}, 'whole publication role pair')
        for role, entry in roles.items():
            path = Path(entry['snapshot'])
            need(path.parent == BASE and path.name.startswith('publication-' + role + '-')
                 and path.suffix == '.gz' and not path.is_symlink(), 'ordinary owned source snapshot')
            body = gzip.decompress(path.read_bytes())
            need(pin(body) == entry['identity'], 'whole publication snapshot bytes')
            (before if role == 'before' else after)[name] = body
        if current:
            need(Path(name).read_bytes() == after[name], 'whole current publication source')
    wanted, measured = transformation(before)
    need(wanted == after and all(row[key] == value for key, value in measured.items()),
         'independently reconstructed whole cause-container publication')
    first, last = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == last.keys(), 'complete task graph membership retains')
    for name, block in first.items():
        if name in (PLAN['owner'], PLAN['parent']):
            need(all(field(block, key) == field(last[name], key) for key in ('Goal', 'Acceptance', 'Children'))
                 and field(last[name], 'Status') == 'done', 'unchanged complete closed contracts')
        else:
            need(block == last[name], 'every unrelated whole task block retains')
    need(all(field(last[name], 'Status') == 'done' for name in last if name.startswith(PLAN['parent'] + '.'))
         and field(last[PLAN['higher_join']], 'Status') == field(last[PLAN['full_alias']], 'Status') == 'pending',
         'all complete children and separately pending higher/full-alias owners')
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
    print('Published only unchanged original primary/raw cause-container acceptance; higher owners retain.')
