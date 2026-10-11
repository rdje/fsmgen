"""Publish only the qualified independent cause-association child."""
import gzip
import io
import json
from pathlib import Path
import re
import subprocess

from publication_common import *
import intake
import sys

_previous = sys.path[:]
try:
    sys.path.insert(0, 'scripts')
    import record_value_cause_fact as fact
finally:
    sys.path[:] = _previous

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
    original = nodes(task)[owner]
    need(field(original, 'Status') == 'active' and field(original, 'Commit') == 'pending', 'exact active cause association leaf')
    evidence = ('The complete admitted preparation, fixed original/current source graph, full reviewed before/after meanings and original cause/native/product/failure domains authenticate. '
        'The unchanged predecessor actually refuses the complete prepared cause meanings at its target contract. A separate maintained cause-fact wrapper admits only the exact reviewed finite extension and four equivalent contractions; all ten historical helper bodies and historical success streams retain. '
        'Every old front-matter/fact/question/evidence/probe byte, native/private/provider/identity limit and original failure remains. All physical canonical dimensions and target bytes/lines conserve under unchanged authority. '
        'Permanent first-admission/schema/native-promotion, complete current meaning/query/native scope, typed actual result and borrowed source-role controls reject genuine changes. Exact prior/current programme and declared source roles remain separate. '
        'Explicitly reviewed book prose compacts within the unchanged chapter ceiling, preserving all facts, existing runnable commands and limitations while adding the dated publication example. '
        'Distinct claim legs are whole fixed source/contract/canonical/query/capacity and admitted evidence rederivation, actual predecessor and permanent separating controls, and full committed before/after/source/native/failure/receipt custody with saved recovery independent of ignored views. '
        'Whole current source/query/capacity/book/native/focused/claim/inventory/staged/normal gates qualify this publication. Only this publication child closes; complete cause/canonical parent acceptance and every higher successor remain open.')
    changed = original.replace(b'  Status: `active`', b'  Status: `done`', 1)
    changed = changed.replace(b'  Verification: `pending`', ('  Verification: `' + evidence + '`').encode(), 1)
    changed = changed.replace(b'  Commit: `pending`', ('  Commit: `' + owner + ': publish admitted finite cause canonical meanings`').encode(), 1)
    changed = changed.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S raw_fact.cards locates the predecessor factory chain. Actual before native1 refuses complete prepared cause meanings at the unchanged target contract. The separate new admission must preserve all historical helper/source roles, old meanings and canonical authority.\n'
        '  - [x] **ADDRESSED (verified)** — Complete fixed preparation/source/native/candidate custody authenticates and only exact reviewed non-growing meanings publish. The separate current wrapper checks admitted cause meanings and full current sources/questions/probes/capacity/native guidance; meaningful first-admission, altered meaning, Boolean, borrowed source and native-promotion controls reject. Every historical helper and source boundary retains.\n'
        '  - [x] **NO REGRESSION** — All tests successful in focused current-publication, stream recovery, task/claim and book audits. Whole current source/query/capacity/book/native, saved preparation/publication, claim/inventory, staged scripts/check_doctrines.sh and normal hooks accompany this commit; complete cause-parent and higher acceptance remain open.\n\n').encode()
    task = task.replace(original, changed, 1)
    review = json.loads((BASE / 'book-review.json').read_bytes())
    old_guide = Path(PLAN['preparation'] + '/guide.txt').read_bytes()
    guide = (BASE / 'guide.txt').read_bytes()
    need(before[BOOK].count(old_guide) == 1, 'unique owned preparation guidance')
    book = before[BOOK].replace(old_guide, guide, 1)
    for old, new in review['book_compactions']:
        need(book.count(old.encode()) == 1, 'whole owned explicit prose beforeimage')
        book = book.replace(old.encode(), new.encode(), 1)
    need(len(book) == review['after_bytes'] <= len(before[BOOK]) == review['before_bytes'] <= 292485,
         'non-growing book under unchanged chapter allowance')
    for block in re.findall(rb'```(?:bash|sh)\n(.*?)```', before[BOOK], re.S):
        need(book.count(block) == before[BOOK].count(block), 'every original runnable example retains exactly')
    need(book.count(fact.GUIDE.encode()) == 1, 'complete admitted cause guidance')
    candidate = fact.admission()
    need(before[fact.CARD] == candidate['before'].encode(), 'whole canonical predecessor before publication')
    card = fact.published(candidate).encode()
    names = intake.git('ls-tree', '-r', '--name-only', PLAN['revision']).decode().splitlines()
    task_names = sorted(name for name in names if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name))
    book_names = sorted(name for name in names if re.fullmatch(r'docs/book/src/[^/]+\.md', name))
    tasks, books = fixed(task_names), fixed(book_names)
    measured_before = metrics(books)
    cards = {name: body for name, body in canonical_sources().items() if Path(name).parent == Path('docs/knowledge')}
    previous_cards = metrics(cards)
    cards[fact.CARD] = card
    measured_cards = metrics(cards)
    need(measured_cards == previous_cards, 'every physical canonical dimension conserves')
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
            row['reference_contract']['aggregate_change'] = dict(authority_id='PRIMARY-RAW-CAUSE-CANONICAL-PUBLICATION-20261011', owner=owner,
                baseline={key: measured_before[key] for key in keys}, delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Publish only admitted finite cause meanings and its runnable saved reader. Explicitly reviewed prose compacts within the unchanged chapter ceiling while every prior fact/example/native/private limit retains; no Knowledge Map metric or authority ceiling grows.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active association pointer')
    memory = memory.replace(owner + '` (active)', PLAN['parent'] + '.3` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate unchanged complete cause-parent acceptance .3.3.3 from clean committed governed canonical publication. Independently join every original cause/canonical parent and completed descendant contract with whole original/current source/native/product/failure custody and genuine controls before closing only cause/canonical owners; all higher successors retain.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after complete cause canonical publication verification and commit; derive later gates under docs/audits/primary-raw-cause-canonical-publication-20261011.', memory, flags=re.M)
    marker = b'cause canonical publication active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique active cause publication index pointer')
    index = before['docs/TASK_TREE.md'].replace(marker, b'cause canonical publication done; parent acceptance next.', 1)
    need(max(map(len, index.splitlines())) <= 862, 'unchanged index width')
    after = {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows), 'MEMORY.md': memory.encode(), 'docs/TASK_TREE.md': index, fact.CARD: card}
    return after, dict(task_names=task_names, book_names=book_names, task_metrics=measured_tasks,
                       book_before=measured_before, book_after=measured_books,
                       previous_cards=previous_cards, measured_cards=measured_cards)


def qualify(*, current=False):
    row = json.loads((BASE / 'publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == {TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md', fact.CARD},
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
    need(field(final[PLAN['parent']], 'Status') == 'active' and field(final[PLAN['parent'] + '.1'], 'Status') == 'done'
         and field(final[PLAN['parent'] + '.3'], 'Status') == 'pending'
         and field(final[PLAN['cause']], 'Status') == 'active', 'canonical and cause-parent acceptance remain open')
    if current:
        for name, body in after.items():
            need(Path(name).read_bytes() == body, 'whole current published finite cause source')
    return row


if __name__ == '__main__':
    names = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md', fact.CARD)
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
    print('Published admitted finite cause meanings; complete cause-parent acceptance remains next.')
