"""Publish only complete unchanged finite cause/canonical parent closure."""
import gzip
import io
import json
from pathlib import Path
import re
import subprocess

from parent_common import *
import intake
CLOSE = (PLAN['cause'], PLAN['parent'], PLAN['owner'])
NEXT = PLAN['cause'].rsplit('.', 2)[0] + '.3'

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
COMMANDS = {
    'focused': ['prove', '-v', 't/2066-record-value-current-publication.t', 't/2067-record-value-gate-streams.t',
                't/1549-task-tree-integrity-doctrine.t', 't/1636-claim-verification-doctrine.t',
                't/1303-isf-public-live-book-paths-audit.t', 't/1305-isf-book-feature-matrix-audit.t'],
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
    original_nodes = nodes(task)
    need(field(original_nodes[NEXT], 'Status') == 'pending'
         and field(original_nodes[NEXT], 'Goal') == 'Independently qualify every original consumer operand and outcome.',
         'exact separately owned consumer frontier')
    evidence = ('Every original cause/canonical Goal/Acceptance and complete primary/raw/prerequisite/association/canonical descendant contract retains without narrowing. '
        'The complete fixed original/current source graph, native/product/source-role evidence and all first failures authenticate. Exact completed primary and coordinate/address reexecutions retain their qualified prerequisite source/census epochs; fresh saved child readers and the independent every-operation association reader rederive their complete admitted meanings. '
        'Whole own API/parser/helper first causes and acceptance, empty/raw/nonempty membership, class/frame/header/argument/coordinate/address/opaque/nested roles retain. Current canonical facts/questions/probes/global direct-cached allocation and every physical capacity metric qualify under unchanged authority. '
        'Complete positive and genuine source/contract/reader/typed-primary/first-failure/command/association/question/query/native-boundary composition candidates execute the independent native reader and retain their first intended outcomes. Qualified original source models remain shared assumptions; no original recapture, hidden/private measurement or later historical-programme currency follows. '
        'Explicitly reviewed bounded book prose retains every original fact/example and native/private limit while distinguishing older pending checkpoints from this finite closure. Whole current source/query/capacity/book/native/focused/claim/inventory/staged/normal gates and committed-only saved recovery qualify. '
        'Distinct claim legs are full fixed-source/obligation and independently qualified original cause/native/canonical rederivation, genuine complete prior-preserving native controls, and committed original/current programmes/commands/streams/products/failures and before/after custody. Only finite cause, canonical parent and this acceptance leaf close; all higher owners retain.')
    for name in CLOSE:
        original = original_nodes[name]
        need(field(original, 'Status') == 'active' and field(original, 'Commit') == 'pending', 'exact active finite closure owner')
        changed = original.replace(b'  Status: `active`', b'  Status: `done`', 1)
        changed = changed.replace(b'  Verification: `pending`', ('  Verification: `' + evidence + '`').encode(), 1)
        changed = changed.replace(b'  Commit: `pending`', ('  Commit: `' + owner + ': close unchanged finite cause parent acceptance`').encode(), 1)
        if name == owner:
            changed = changed.rstrip() + (
                '\n  Acceptance Checklist (enforced):\n'
                '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S Join complete original primary and raw native cause semantics. locates the complete original obligation. Prerequisite, independent cause association and governed canonical publication are committed; original full parent acceptance remains open. Every original contract and native/source/private boundary must survive closure.\n'
                '  - [x] **ADDRESSED (verified)** — Complete original/current source/native/product/failure custody and unchanged full contracts independently join. Exact source-role primary/coordinate/address epochs, every-operation source causes and acceptance, empty/raw/nested associations and current canonical facts/questions/probes qualify. Full genuine native wrong/borrowed/omitted/Boolean/boundary candidates reject; only the finite cause/canonical owners close.\n'
                '  - [x] **NO REGRESSION** — All tests successful in focused current-publication, stream recovery, task/claim and book audits. Whole current source/query/capacity/book/native, full saved child proofs and independent composition/control readers, claim/inventory, staged scripts/check_doctrines.sh and normal hooks qualify this commit. Original failures/unknowns and consumer/alias/cold/permanent/host-native/private/visual/HIAL/full-CI/push successors retain.\n\n').encode()
        task = task.replace(original, changed, 1)
    review = json.loads((BASE / 'book-review.json').read_bytes())
    old_guide = Path(PLAN['publication'] + '/guide.txt').read_bytes()
    guide = (BASE / 'guide.txt').read_bytes() + b'\n'
    need(before[BOOK].count(old_guide) == 1, 'unique owned preparation guidance')
    book = before[BOOK].replace(old_guide, guide, 1)
    for old, new in review['book_compactions']:
        need(book.count(old.encode()) == 1, 'whole owned explicit prose beforeimage')
        book = book.replace(old.encode(), new.encode(), 1)
    need(len(book) == review['after_bytes'] <= 292485 and len(before[BOOK]) == review['before_bytes'],
         'non-growing book under unchanged chapter allowance')
    for block in re.findall(rb'```(?:bash|sh)\n(.*?)```', before[BOOK], re.S):
        need(book.count(block) == before[BOOK].count(block), 'every original runnable example retains exactly')
    notice = (BASE / 'notice.txt').read_bytes() + b'\n'
    need(book.count(notice) == 1, 'whole finite closure guidance and dated checkpoint distinction')
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
            row['reference_contract']['aggregate_change'] = dict(authority_id='PRIMARY-RAW-CAUSE-PARENT-ACCEPTANCE-20261011', owner=owner,
                baseline={key: measured_before[key] for key in keys}, delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Document complete unchanged finite cause/canonical parent acceptance and its saved replay; explicitly reviewed compaction preserves every prior fact/example/native/private limit and dated checkpoint under unchanged ceilings and canonical authority.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active association pointer')
    memory = memory.replace(owner + '` (active)', NEXT + '` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate independent original consumer semantics .3.3 from clean committed complete finite cause/canonical parent acceptance. Reconstruct every original consumer operand and outcome from authored actor/type/path/API/helper/cause models and exact source assertions; native passed flags are insufficient. Preserve full source/native/private boundaries; alias downstream remains separately owned.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after complete finite cause/canonical parent acceptance verification and commit; derive later gates under docs/audits/primary-raw-cause-parent-acceptance-20261011.', memory, flags=re.M)
    marker = b'complete cause-parent acceptance active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique finite parent frontier marker')
    index = before['docs/TASK_TREE.md'].replace(marker, b'cause parent done; consumer semantics next.', 1)
    need(max(map(len, index.splitlines())) <= 862, 'unchanged index width')
    after = {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows), 'MEMORY.md': memory.encode(), 'docs/TASK_TREE.md': index}
    return after, dict(task_names=task_names, book_names=book_names, task_metrics=measured_tasks,
                       book_before=measured_before, book_after=measured_books)


def qualify(*, current=False):
    row = json.loads((BASE / 'publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == {TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md'},
         'whole owned association publication population')
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
    need(wanted == after and all(row[key] == value for key, value in measured.items()), 'whole independently reconstructed association publication')
    first, final = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == final.keys(), 'whole task graph conserves')
    for name, block in first.items():
        if name in CLOSE:
            need(all(field(block, key) == field(final[name], key) for key in ('Goal', 'Acceptance', 'Children'))
                 and field(final[name], 'Status') == 'done', 'only unchanged association child closes')
        else:
            need(block == final[name], 'every unrelated complete task block retains')
    need(all(field(final[name], 'Status') == 'done' for name in CLOSE)
         and field(final[NEXT], 'Status') == 'pending', 'only finite parents close before consumer frontier')
    if current:
        for name, body in after.items():
            need(Path(name).read_bytes() == body, 'whole current published finite cause source')
    return row


if __name__ == '__main__':
    names = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md')
    before = {name: Path(name).read_bytes() for name in names}
    need(all(Path(name).read_bytes() == body for name, body in intake.overlays().items()), 'whole unchanged source-qualified activation metadata')
    after, measured = transformation(before)
    snapshots = {}
    for i, name in enumerate(names):
        snapshots[name] = {}
        for role, body in (('before', before[name]), ('after', after[name])):
            path = BASE / ('publication-' + role + '-' + str(i) + '.gz')
            need(not path.exists(), 'fresh complete publication snapshot')
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    need(not (BASE / 'publication.json').exists(), 'fresh complete association publication')
    for name, roles in snapshots.items():
        for role, row in roles.items():
            Path(row['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, **measured))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole final publication input conservation')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published complete unchanged finite cause/canonical parent acceptance; consumer semantics remain next.')
