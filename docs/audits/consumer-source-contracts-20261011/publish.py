"""Publish only complete original consumer source contracts."""
import gzip
import io
import json
from pathlib import Path
import re
import subprocess

from consumer_common import *
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
    need(field(original, 'Status') == 'active' and field(original, 'Commit') == 'pending', 'exact active source-contract leaf')
    evidence = ('The first copied capture route refused before native launch; its complete original programme/tool terminal retain. BASE-derived routing and a separate actual native exclusive-route reproduction qualify the correction without touching prior evidence. Complete fixed original/current source/native/product/cause custody and the unchanged consumer parent authenticate. '
        'A producer extracts every whole finite authored assertion and argument span; a separate statement/quote-masked traversal reconstructs every expression, expanded helper/loop context and full actor/type/path/API/mutation dataflow scope. '
        'Every original mode consumer context joins its exact source owner. Typed scalar/graph roles and the synthetic trace/native/private boundaries retain; no native passed flag supplies operand or outcome truth. '
        'Complete genuine omitted/borrowed/expression/span/helper/loop/source/Boolean/native-promotion candidates execute the independent native reader and reject at their intended first assertions. '
        'Distinct claim legs are independent full source/context/operand-contract rederivation, whole genuine native separating controls, and committed complete original/current source/programme/command/terminal/candidate/publication custody with saved replay. '
        'Current book/native/source/query/capacity/focused/size/claim/inventory/staged/normal checks qualify only this source-contract leaf. Consumer operands/truth, canonical publication and complete original parent acceptance remain separately owned, with full alias downstream and higher scopes unchanged.')
    changed = original.replace(b'  Status: `active`', b'  Status: `done`', 1)
    changed = changed.replace(b'  Verification: `pending`', ('  Verification: `' + evidence + '`').encode(), 1)
    changed = changed.replace(b'  Commit: `pending`', ('  Commit: `' + owner + ': prepare complete original consumer source contracts`').encode(), 1)
    changed = changed.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — First external capture FileExistsError pins the copied artifact-route locus; capture-route-recovery.json and the separate native reproduction retain it. git log -S Independently qualify every original consumer operand and outcome. locates the unchanged original consumer obligation. Qualified original source contexts and cause acceptance do not establish consumer operand or outcome truth; exact source expressions and dataflow roles must precede that derivation.\n'
        '  - [x] **ADDRESSED (verified)** — Complete original/current source/native/product/cause custody authenticates. Independent finite statement traversal admits every authored assertion/argument and full helper/loop/dataflow/typed operand role; genuine complete native source-expression/span/helper/loop/source/Boolean/boundary controls reject. Original Goal/Acceptance, facts, questions, probes, native/private limits and higher scopes retain.\n'
        '  - [x] **NO REGRESSION** — All tests successful in focused current-publication, stream recovery, task/claim/disposition and book audits. Current source/query/capacity/book/native, saved cause-parent and source-contract readers, claim/inventory, staged scripts/check_doctrines.sh and normal hooks qualify delivery. Consumer operand/outcome and canonical/parent acceptance remain open.\n\n').encode()
    task = task.replace(original, changed, 1)
    review = json.loads((BASE / 'book-review.json').read_bytes())
    anchor = Path(PLAN['publication'] + '/notice-recovered.txt').read_bytes()
    guide = (BASE / 'guide.txt').read_bytes()
    need(before[BOOK].count(anchor) == 1, 'whole unique committed cause-parent guidance')
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
            row['reference_contract']['aggregate_change'] = dict(authority_id='CONSUMER-SOURCE-CONTRACTS-20261011', owner=owner,
                baseline={key: measured_before[key] for key in keys}, delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Document complete original consumer assertion/source operand contracts. Explicit whole-paragraph review preserves every old fact/example/limit and reviewed encoding line; existing canonical authority and book ceiling do not grow.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active source-contract pointer')
    memory = memory.replace(owner + '` (active)', PLAN['parent'] + '.2` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate independent complete consumer operands/truth .3.3.2 from clean committed source contracts. Derive every original typed operand and assertion outcome from own authored actor/type/path/API/helper/cause models and exact expressions; native passed flags are insufficient. Preserve synthetic trace/native/private limits and full alias downstream ownership.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after complete consumer source-contract verification and commit; derive later gates under docs/audits/consumer-source-contracts-20261011.', memory, flags=re.M)
    marker = b'cause parent done; consumer source contracts active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique active consumer source-contract frontier')
    index = before['docs/TASK_TREE.md'].replace(marker, b'consumer source contracts done; operand truth next.', 1)
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
        if name == PLAN['owner']:
            need(all(field(block, key) == field(final[name], key) for key in ('Goal', 'Acceptance', 'Children'))
                 and field(final[name], 'Status') == 'done', 'only unchanged association child closes')
        else:
            need(block == final[name], 'every unrelated complete task block retains')
    need(field(final[PLAN['parent']], 'Status') == 'active'
         and all(field(final[PLAN['parent'] + '.' + str(index)], 'Status') == 'pending' for index in (2, 3, 4)),
         'consumer operand truth canonical publication and parent acceptance remain open')
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
    need(not (BASE / 'publication.json').exists(), 'fresh complete association publication')
    for name, roles in snapshots.items():
        for role, row in roles.items():
            Path(row['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, **measured))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole final publication input conservation')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published only complete consumer source contracts; operands/truth and canonical/parent acceptance retain.')
