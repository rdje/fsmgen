"""Publish only unchanged canonical-parent acceptance only."""
import gzip
import io
import json
from pathlib import Path
import re
import subprocess

from parent_common import *
import interfaces
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
         'exact unchanged active canonical parent and final acceptance leaf')
    evidence = ('Complete unchanged canonical Goal/Acceptance and all preparation/publication descendants qualify together. '
        'Fresh source-bound admission and isolated original complete consumer-meaning readers rederive every typed operand/outcome; all original source/native/product/cause custody, Storable kind witnesses, opaque synthetic trace and native/private boundaries retain. '
        'Whole prior canonical facts/questions/probes/source authority and all twelve maintained helper interfaces remain byte-exact. Complete genuine original meaning and canonical contract/question/query/scope/failure controls reach intended native first causes; permanent admission regressions qualify. '
        'Original unexpected preparation size 1/0, publication whitespace 2/0 and publication staged-source 1/0 failures retain complete source/native epochs and distinct actual/declared statuses; all committed repairs remain authenticated. '
        'Development interfaces/candidate/native controls and whole publication/capacity/staging preflight precede formal source freeze and retain complete epochs. '
        'Owned P3 development preflight null-ceiling TypeError (native 1/declared 0) is repaired before formal freeze: unset aggregate limits retain their governed contract while every numeric ceiling is checked; whole first source/native failure and successful retry retain. '
        'Claim legs are complete original unchanged contracts and source-derived independent admission/meaning/current reconstruction; genuine complete native separating mutations with intended first causes; and committed whole source/programmes/commands/statuses/streams/products/snapshots plus default recovery and normal hooks. '
        'Current complete source/query/capacity/book/native/focused/claim/inventory/staged/normal checks qualify only canonical parent/acceptance. Original consumer-parent acceptance, full aliases and every higher owner remain open.')
    for name in (owner, parent):
        original = first[name]
        changed = original.replace(b'  Status: `active`', b'  Status: `done`', 1)
        changed = changed.replace(('  Verification: `' + field(original, 'Verification') + '`').encode(),
                                  ('  Verification: `' + evidence + '`').encode(), 1)
        changed = changed.replace(b'  Commit: `pending`', ('  Commit: `' + owner + ': accept unchanged consumer canonical publication`').encode(), 1)
        if name == owner:
            changed = changed.rstrip() + (
                '\n  Acceptance Checklist (enforced):\n'
                '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S Publish only admitted source-bound consumer canonical meanings. locates the unchanged full canonical obligation; committed preparation and publication leave parent/descendant acceptance open. Whole original contracts, independently derived consumer meanings, admitted canonical facts and genuine native/permanent controls must qualify together.\n'
                '  - [x] **ADDRESSED (verified)** — Fresh complete preparation/publication/meaning replays, isolated source-derived meaning and admission readers, all original and parent separating native controls and permanent admission tests retain every canonical fact/question/probe/source authority, twelve helper bodies and all first failures/repairs. Only unchanged canonical parent and acceptance leaf close; original consumer and higher owners stay open.\n'
                '  - [x] **NO REGRESSION** — All tests successful in focused publication/stream/task/claim/disposition/book audits. Whole current source/query/capacity/book/native, permanent admission tests, full saved/fresh native control reconstruction, size/claim/inventory, staged scripts/check_doctrines.sh and normal hooks qualify this canonical acceptance.\n\n').encode()
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
    need(len(before[BOOK]) == review['before_bytes'] and len(book) == review['after_bytes'] <= review['before_bytes'] <= 292485,
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
            row['reference_contract']['aggregate_change'] = dict(authority_id='CONSUMER-CANONICAL-PARENT-ACCEPTANCE-20261012', owner=owner,
                baseline={key: measured_before[key] for key in keys}, delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Document complete unchanged canonical-parent/descendant acceptance with preserved source/native/private limits and separately owned original consumer acceptance. Reviewed whole prose preserves all prior facts, examples, controls, commands and encoding dispositions without widening any ceiling or canonical collection authority.')
    ancestor = parent.rsplit('.', 1)[0]
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active complete canonical acceptance pointer')
    memory = memory.replace(owner + '` (active)', PLAN['consumer'] + '.4` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate complete original consumer acceptance .4 from clean committed canonical acceptance; join unchanged contracts and full source-derived typed operands/truth with current gates. Preserve alias and higher successors.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None; derive canonical acceptance receipts under docs/audits/consumer-canonical-parent-acceptance-20261012.', memory, flags=re.M)
    marker = b'canonical acceptance active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique active complete canonical acceptance frontier')
    index = before['docs/TASK_TREE.md'].replace(marker, b'canonical done; consumer acceptance next.', 1)
    need(max(map(len, index.splitlines())) <= 862, 'unchanged index width')
    return {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows), 'MEMORY.md': memory.encode(), 'docs/TASK_TREE.md': index}, dict(
        task_names=task_names, book_names=book_names, task_metrics=measured_tasks, book_before=measured_before, book_after=measured_books)


def qualify(*, current=False):
    row = json.loads((BASE / 'publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == {TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md'},
         'whole owned unchanged canonical-parent publication population')
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
    need(wanted == after and all(row[key] == value for key, value in measured.items()), 'whole independently reconstructed unchanged canonical acceptance publication')
    first, final = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == final.keys(), 'whole task graph conserves')
    for name, block in first.items():
        if name in (PLAN['owner'], PLAN['parent']):
            need(all(field(block, key) == field(final[name], key) for key in ('Goal', 'Acceptance', 'Children'))
                 and field(final[name], 'Status') == 'done', 'only full unchanged canonical parent and acceptance leaf close')
        else:
            need(block == final[name], 'every unrelated whole task block retains')
    parent = PLAN['parent']
    need(all(field(final[parent + '.' + str(i)], 'Status') == 'done' for i in range(1, 4))
         and field(final[PLAN['consumer']], 'Status') == 'active'
         and field(final[PLAN['consumer'] + '.4'], 'Status') == 'pending',
         'complete canonical descendants and separately open original consumer acceptance retain')
    interfaces.contracts()
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
    print('Published only unchanged canonical-parent acceptance; original consumer parent and higher owners retain.')
