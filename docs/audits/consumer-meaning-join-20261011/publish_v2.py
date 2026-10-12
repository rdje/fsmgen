"""Publish only the complete original consumer source/meaning/operand/truth join."""
import gzip
import io
import json
from pathlib import Path
import re
import subprocess

from join_common import *
import intake

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
COMMANDS = {
    'focused': ['prove', '-v', 't/2066-record-value-current-publication.t', 't/2067-record-value-gate-streams.t',
                't/1549-task-tree-integrity-doctrine.t', 't/1636-claim-verification-doctrine.t',
                't/1638-claim-verification-dispositions.t', 't/1303-isf-public-live-book-paths-audit.t', 't/1305-isf-book-feature-matrix-audit.t'],
    'book': ['mdbook', 'build', 'docs/book'],
    'native': ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', 'docs/book/book'],
    'size': ['scripts/check_live_document_size.sh'], 'claims': ['scripts/check_claim_verification.pl'],
    'inventory-write': ['scripts/check_claim_verification_inventory.pl', '--write'],
    'inventory': ['scripts/check_claim_verification_inventory.pl']}


def metrics(sources):
    rows = [dict(bytes=len(body), lines=body.count(b'\n'), width=max(map(len, body.splitlines()), default=0)) for body in sources.values()]
    return dict(files=len(rows), bytes_total=sum(row['bytes'] for row in rows), lines_total=sum(row['lines'] for row in rows),
                bytes_each=max(row['bytes'] for row in rows), lines_each=max(row['lines'] for row in rows),
                line_bytes_each=max(row['width'] for row in rows))


def fixed(names):
    requested = b''.join((PLAN['revision'] + ':' + name + '\n').encode() for name in names)
    result = subprocess.run(['git', '--no-replace-objects', 'cat-file', '--batch'], input=requested, capture_output=True)
    need(result.returncode == 0 and result.stderr == b'', 'complete bounded publication Git batch')
    stream, bodies = io.BytesIO(result.stdout), {}
    for name in names:
        header = stream.readline().split()
        need(len(header) == 3 and header[1] == b'blob', 'complete publication source blob header')
        body = stream.read(int(header[2]))
        need(len(body) == int(header[2]) and stream.read(1) == b'\n', 'whole publication source blob')
        bodies[name] = body
    need(stream.read(1) == b'', 'whole publication source membership')
    return bodies


def transformation(before):
    task, owner = before[TASK], PLAN['owner']
    original = nodes(task)[owner]
    need(field(original, 'Status') == 'active' and field(original, 'Commit') == 'pending', 'exact active complete consumer join leaf')
    evidence = 'Complete fixed original/current source/native/product/cause and source-contract roles retain. Fresh whole committed helper and remaining reader replays plus isolated independent source-model reconstruction qualify every original meaning. An independently derived disjoint source assertion partition joins every own helper/actor/type/path/API/copy/cause source meaning to complete typed native operands and comparison truth across all unchanged modes. Native passed flags never supply truth authority. Every complete original and qualified Storable copy witness/synthetic opaque trace/private boundary retains. Genuine complete native forced green/red, wrong source/role/helper/API/primary/borrowed meaning, primitive/structural/Storable/synthetic/outcome and omission controls reach their intended first refusals. Distinct claim legs are own original source partition and fresh independent child meaning/comparison rederivation, actual complete native separating controls, and whole committed programmes/source/commands/streams/products/candidates/snapshots/normal receipts with saved default recovery. The prior successful development-only isolated interface probe remains a separately declared non-acceptance programme epoch. Current source/query/capacity/book/native/focused/size/claim/inventory/staged/normal delivery qualifies only complete join child. Full unchanged meaning acceptance, canonical/original consumer parent and every higher owner remain separate.'
    evidence += 'The first formal control run failed before the Storable candidate: its mutation incorrectly assumed numeric width where the qualified original test-copy witness retains string "7". The exact first programme and all prior native terminals remain immutable; a separate corrected mutator changes the actual string to number, reproduces the first construction refusal and completes every native control. '
    changed = original.replace(b'  Status: `active`', b'  Status: `done`', 1)
    changed = changed.replace(('  Verification: `' + field(original, 'Verification') + '`').encode(), ('  Verification: `' + evidence + '`').encode(), 1)
    changed = changed.replace(b'  Commit: `pending`', ('  Commit: `' + owner + ': join every original consumer meaning and outcome`').encode(), 1)
    changed = changed.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S Independently derive complete original consumer operands and truth. locates the unchanged whole meaning obligation. Separate helper/nonhelper truths leave source association incomplete: each original assertion must join its own source contract, freshly rederived meaning, whole typed operands and actual comparison outcome.\n'
        '  - [x] **ADDRESSED (verified)** — Independent original source partition and isolated committed child readers join every assertion across all unchanged modes without native passed authority. The first Storable control-construction failure is preserved and reproduced; corrected complete genuine native source/role/helper/API/primary/borrowed-meaning/primitive/structural/Storable/synthetic/outcome/false-green/red/omission candidates reach intended first refusals. Original source/native/product and opaque/private boundaries retain.\n'
        '  - [x] **NO REGRESSION** — All tests successful in focused publication/stream/task/claim/disposition/book audits. Whole fresh source-contract/helper/remaining replays, current source/query/capacity/book/native, size/claim/inventory, staged scripts/check_doctrines.sh and normal hooks qualify this join child. Complete meaning, canonical/original parent and every higher acceptance remain open.\n\n').encode()
    task = task.replace(original, changed, 1)
    review = json.loads((BASE / 'book-review.json').read_bytes())
    anchor = Path(PLAN['publication'] + '/guide.txt').read_bytes()
    guide = (BASE / 'guide.txt').read_bytes()
    need(before[BOOK].count(anchor) == 1, 'whole unique committed remaining consumer guidance')
    book = before[BOOK].replace(anchor, anchor + b'\n' + guide, 1)
    for original, compact in review['book_compactions']:
        need(book.count(original.encode()) == 1, 'whole explicitly reviewed replay prose beforeimage')
        book = book.replace(original.encode(), compact.encode(), 1)
    need(len(before[BOOK]) == review['before_bytes'] and len(book) == review['after_bytes'] <= 292485,
         'unchanged book ceiling and exact reviewed compaction')
    for block in re.findall(rb'```(?:bash|sh)\n(.*?)```', before[BOOK], re.S):
        need(book.count(block) == before[BOOK].count(block), 'every original runnable command retains')
    names = intake.git('ls-tree', '-r', '--name-only', PLAN['revision']).decode().splitlines()
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
                need(value <= row['enforcement_ceilings'][key], 'unchanged task ceilings')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(authority_id='CONSUMER-MEANING-JOIN-20261011', owner=owner,
                baseline={key: measured_before[key] for key in keys}, delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Document complete original source/meaning/typed operand/comparison truth join and separately retained full meaning acceptance. Reviewed prose preserves every prior fact/example/source/native/private limit and encoding disposition; all commands/claims and canonical authority/ceilings retain.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active complete consumer join pointer')
    memory = memory.replace(owner + '` (active)', PLAN['parent'] + '.4` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate unchanged complete consumer-meaning acceptance .3.3.2.4 from clean committed complete join. Freshly qualify all helper/remaining/join meanings, original custody and native controls with current/source/query/capacity/book/native/focused/claim/staged/normal recovery. Canonical/original consumer parent and higher scopes remain separate.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after complete original consumer join verification and commit; derive later receipts under docs/audits/consumer-meaning-join-20261011.', memory, flags=re.M)
    marker = b'both truths done; complete consumer join active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique active complete consumer join frontier')
    index = before['docs/TASK_TREE.md'].replace(marker, b'complete consumer join done; meaning acceptance next.', 1)
    need(max(map(len, index.splitlines())) <= 862, 'unchanged index width')
    after = {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows), 'MEMORY.md': memory.encode(), 'docs/TASK_TREE.md': index}
    return after, dict(task_names=task_names, book_names=book_names, task_metrics=measured_tasks,
                       book_before=measured_before, book_after=measured_books)


def qualify(*, current=False):
    row = json.loads((BASE / 'publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == {TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md'},
         'whole owned consumer join publication population')
    before, after = {}, {}
    for name, roles in row['snapshots'].items():
        need(set(roles) == {'before', 'after'}, 'complete publication source roles')
        for role, entry in roles.items():
            path = Path(entry['snapshot'])
            need(path.parent == BASE and path.name.startswith('publication-' + role + '-') and path.suffix == '.gz' and not path.is_symlink(),
                 'exact ordinary owned source snapshot')
            body = gzip.decompress(path.read_bytes())
            need(pin(body) == entry['identity'], 'whole publication source snapshot bytes')
            (before if role == 'before' else after)[name] = body
        if current:
            need(Path(name).read_bytes() == after[name], 'whole explicit current publication source')
    wanted, measured = transformation(before)
    need(wanted == after and all(row[key] == value for key, value in measured.items()), 'whole independently reconstructed consumer join publication')
    first, final = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == final.keys(), 'whole task graph conserves')
    for name, block in first.items():
        if name == PLAN['owner']:
            need(all(field(block, key) == field(final[name], key) for key in ('Goal', 'Acceptance', 'Children'))
                 and field(final[name], 'Status') == 'done', 'only unchanged consumer join child closes')
        else:
            need(block == final[name], 'every unrelated complete task block retains')
    need(field(final[PLAN['parent']], 'Status') == 'active'
         and all(field(final[PLAN['parent'] + '.' + str(i)], 'Status') == 'done' for i in (1, 2, 3))
         and field(final[PLAN['parent'] + '.4'], 'Status') == 'pending',
         'complete meaning acceptance and every higher owner retain')
    return row


if __name__ == '__main__':
    names = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md')
    before = {name: Path(name).read_bytes() for name in names}
    need(all(before[name] == body for name, body in intake.overlays().items()), 'whole unchanged source-qualified activation metadata')
    after, measured = transformation(before)
    snapshots = {}
    for i, name in enumerate(names):
        snapshots[name] = {}
        for role, body in (('before', before[name]), ('after', after[name])):
            path = BASE / ('publication-' + role + '-' + str(i) + '.gz')
            need(not path.exists(), 'fresh complete publication snapshot')
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    need(not (BASE / 'publication.json').exists(), 'fresh complete consumer join publication')
    for name, roles in snapshots.items():
        for role, row in roles.items():
            Path(row['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, **measured))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole final publication input conservation')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published only complete original consumer join; meaning/canonical/original parent and higher acceptance retain.')
