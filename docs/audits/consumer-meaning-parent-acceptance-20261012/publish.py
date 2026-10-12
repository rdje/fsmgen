"""Publish only complete original refusal-helper consumer truth."""
import gzip
import io
import json
from pathlib import Path
import re
import subprocess

from acceptance_common import *
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
    task, owner, parent = before[TASK], PLAN['owner'], PLAN['parent']
    first = nodes(task)
    need(field(first[owner], 'Status') == field(first[parent], 'Status') == 'active'
         and field(first[owner], 'Commit') == field(first[parent], 'Commit') == 'pending',
         'exact unchanged active meaning parent and final acceptance leaf')
    evidence = ('The full original independent operand/truth Goal/Acceptance and every complete descendant contract remain unchanged. '
        'Fresh complete helper, remaining and join replays plus isolated independent readers rederive every own source assertion/helper/actor/type/path/API/copy/cause meaning, typed operand and comparison outcome across all original modes. '
        'Exact complementary child allocation joins every original observation without native passed authority. Every whole original source/native/product/cause, qualified Storable kind witness, opaque synthetic trace and native/private boundary retains. '
        'All first child failures, source epochs, actual/expected statuses, repairs and genuine controls remain authenticated. Complete genuine native join and parent/descendant/borrowed narrower success/false-green/kind/source/structural/omission controls reach intended first refusals. '
        'Three development-only interface/construction/library-refusal probes precede formal freeze; their full source epochs retain and their caught library errors are never native status-1 controls. A source-reviewed expected-cause adjustment and over-budget static book proposals retain as development evidence. '
        'Distinct claim legs are whole original source and parent/descendant rederivation through fresh independent meaning readers, complete genuine native separating candidates with intended first causes, and committed complete source/programmes/commands/statuses/streams/products/proposals/snapshots/normal receipts with default recovery. '
        'Current source/query/capacity/book/native/focused/size/claim/inventory/sealed/default/staged/normal delivery qualifies only independent meanings and this acceptance leaf. Canonical publication, original consumer-parent acceptance, full alias downstream and every higher scope remain open.')
    for name in (owner, parent):
        original = first[name]
        changed = original.replace(b'  Status: `active`', b'  Status: `done`', 1)
        changed = changed.replace(('  Verification: `' + field(original, 'Verification') + '`').encode(),
                                  ('  Verification: `' + evidence + '`').encode(), 1)
        changed = changed.replace(b'  Commit: `pending`', ('  Commit: `' + owner + ': accept complete independent consumer meanings`').encode(), 1)
        if name == owner:
            changed = changed.rstrip() + (
                '\n  Acceptance Checklist (enforced):\n'
                '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S Independently derive complete original consumer operands and truth. locates the unchanged full meaning obligation. Separate committed source, helper, remaining and join qualifications leave complete parent/descendant acceptance open; original typed operands and source-derived outcomes must qualify together without native passed authority.\n'
                '  - [x] **ADDRESSED (verified)** — Fresh complete helper/remaining/join replays and isolated independent model readers join every unchanged parent/child requirement to all original source assertions, whole typed operands and actual comparison outcomes. Genuine native full join, parent weakening, borrowed narrower success, independent child false-green/kind and omission candidates reach intended first refusals. Every original first failure/repair and Storable/synthetic/private limit retains.\n'
                '  - [x] **NO REGRESSION** — All tests successful in focused publication/stream/task/claim/disposition/book audits. Whole current source/query/capacity/book/native, complete saved/fresh meaning/native-control reconstruction, size/claim/inventory, staged scripts/check_doctrines.sh and normal hooks qualify only independent meaning parent/acceptance. Canonical/original consumer parent and every higher scope stay open.\n\n').encode()
        need(task.count(original) == 1, 'whole unique unchanged parent/acceptance block beforeimage')
        task = task.replace(original, changed, 1)
    review = json.loads((BASE / 'book-review.json').read_bytes())
    anchor = Path(PLAN['publication'] + '/guide.txt').read_bytes()
    guide = (BASE / 'guide.txt').read_bytes()
    need(before[BOOK].count(anchor) == 1, 'whole unique committed complete consumer join guidance')
    book = before[BOOK].replace(anchor, anchor + b'\n' + guide, 1)
    for original, compact in review['book_compactions']:
        need(book.count(original.encode()) == 1, 'whole explicitly reviewed book paragraph beforeimage')
        book = book.replace(original.encode(), compact.encode(), 1)
    need(len(before[BOOK]) == review['before_bytes'] and len(book) == review['after_bytes'] <= 292485,
         'unchanged book ceiling and whole reviewed proposal')
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
            row['reference_contract']['aggregate_change'] = dict(authority_id='CONSUMER-MEANING-PARENT-ACCEPTANCE-20261012', owner=owner,
                baseline={key: measured_before[key] for key in keys}, delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Document complete unchanged independent meaning-parent/descendant acceptance with preserved source/native/private limits and separately owned canonical/original consumer acceptance. Reviewed whole prose preserves all prior facts, examples, controls, commands and encoding dispositions without widening any ceiling or canonical collection authority.')
    ancestor = parent.rsplit('.', 1)[0]
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active complete meaning acceptance pointer')
    memory = memory.replace(owner + '` (active)', ancestor + '.3` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate governed consumer canonical publication .3.3.3 from clean committed complete independent meanings. Preserve every old fact/question/probe and retained helper, non-growing collection authority, full source/native/private/Storable/synthetic boundaries and genuine controls. Original consumer-parent acceptance and all higher owners remain separate.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after complete independent consumer-meaning acceptance verification and commit; derive later receipts under docs/audits/consumer-meaning-parent-acceptance-20261012.', memory, flags=re.M)
    marker = b'complete join done; meaning acceptance active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique active complete meaning acceptance frontier')
    index = before['docs/TASK_TREE.md'].replace(marker, b'independent meanings done; canonical next.', 1)
    need(max(map(len, index.splitlines())) <= 862, 'unchanged index width')
    return {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows), 'MEMORY.md': memory.encode(), 'docs/TASK_TREE.md': index}, dict(
        task_names=task_names, book_names=book_names, task_metrics=measured_tasks, book_before=measured_before, book_after=measured_books)


def qualify(*, current=False):
    row = json.loads((BASE / 'publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == {TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md'},
         'whole owned unchanged meaning-parent publication population')
    before, after = {}, {}
    for name, roles in row['snapshots'].items():
        need(set(roles) == {'before', 'after'}, 'complete parent publication source roles')
        for role, entry in roles.items():
            path = Path(entry['snapshot'])
            need(path.parent == BASE and path.name.startswith('publication-' + role + '-') and path.suffix == '.gz'
                 and not path.is_symlink(), 'exact ordinary owned parent publication snapshot')
            body = gzip.decompress(path.read_bytes())
            need(pin(body) == entry['identity'], 'whole parent publication snapshot bytes')
            (before if role == 'before' else after)[name] = body
        if current:
            need(Path(name).read_bytes() == after[name], 'whole explicit current parent publication source')
    wanted, measured = transformation(before)
    need(wanted == after and all(row[key] == value for key, value in measured.items()), 'whole independently reconstructed unchanged meaning acceptance publication')
    first, final = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == final.keys(), 'whole task graph conserves')
    for name, block in first.items():
        if name in (PLAN['owner'], PLAN['parent']):
            need(all(field(block, key) == field(final[name], key) for key in ('Goal', 'Acceptance', 'Children'))
                 and field(final[name], 'Status') == 'done', 'only full unchanged independent meaning parent and acceptance leaf close')
        else:
            need(block == final[name], 'every unrelated whole task block retains')
    parent = PLAN['parent']
    ancestor = parent.rsplit('.', 1)[0]
    need(all(field(final[parent + '.' + str(i)], 'Status') == 'done' for i in range(1, 5))
         and field(final[ancestor], 'Status') == 'active'
         and field(final[ancestor + '.3'], 'Status') == field(final[ancestor + '.4'], 'Status') == 'pending',
         'complete meaning descendants and separately open canonical/original consumer parents retain')
    return row


if __name__ == '__main__':
    names = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md')
    before = {name: Path(name).read_bytes() for name in names}
    need(all(before[name] == body for name, body in intake.overlays().items()), 'whole unchanged qualified parent activation metadata')
    after, measured = transformation(before)
    snapshots = {}
    for i, name in enumerate(names):
        snapshots[name] = {}
        for role, body in (('before', before[name]), ('after', after[name])):
            path = BASE / ('publication-' + role + '-' + str(i) + '.gz')
            need(not path.exists(), 'fresh whole parent publication snapshot')
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    need(not (BASE / 'publication.json').exists(), 'fresh complete parent publication')
    for name, roles in snapshots.items():
        for role, row in roles.items():
            Path(row['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, **measured))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole final parent publication input conservation')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published only complete unchanged independent consumer meanings; canonical/original parent and higher owners retain.')
