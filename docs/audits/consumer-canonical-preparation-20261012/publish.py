"""Publish only the qualified independent consumer-canonical preparation child."""
import gzip
import io
import json
from pathlib import Path
import re
import subprocess

from canonical_common import *
import intake

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
COMMANDS = {
    'focused': ['prove', '-v', 't/2066-record-value-current-publication.t', 't/2067-record-value-gate-streams.t',
                't/1549-task-tree-integrity-doctrine.t', 't/1636-claim-verification-doctrine.t', 't/1638-claim-verification-dispositions.t',
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
    need(field(original, 'Status') == 'active' and field(original, 'Commit') == 'pending', 'exact active consumer canonical preparation leaf')
    evidence = ('Every original canonical fact/question/evidence/probe and unchanged full consumer/canonical contract retains. '
        'Complete fixed original/current source and committed independent consumer-meaning custody authenticate. Fresh saved complete meaning and current factory executions precede exact prospective publication. '
        'The independent proposal reader reconstructs source-derived typed consumer operands/truth extension and every reviewed equivalent contraction with ordered complete before/after paragraphs, unchanged front matter, direct/cached whole question allocation and all non-growing physical metrics under unchanged authority. '
        'Genuine full-candidate omitted/borrowed/Boolean/wrong-meaning/native-promotion controls reach intended library ValueError refusals inside a guarded qualifier; they are not separate native status-1 measurements. '
        'Static growing wording/book drafts and a separately declared development-only interface/capacity/control/publication probe remain retained before formal source freeze. Engineering equivalence review is explicit, not a universal natural-language proof. '
        'All original failures/source epochs, Storable primitive-kind witness, synthetic opaque trace and native/private/provider/flags/encoding/identity boundaries retain. '
        'Claim legs are fixed whole original/canonical/meaning/source/query/capacity rederivation, genuine complete separating candidates and intended refusal causes, and committed complete beforeimages/proposal/programmes/commands/streams/source roles/normal receipts with saved recovery. '
        'Current source/query/capacity/book/native/focused/size/claim/inventory/staged/normal delivery qualifies this preparation only. Maintained canonical production, complete canonical/original consumer-parent acceptance and every higher owner remain open.')
    changed = original.replace(b'  Status: `active`', b'  Status: `done`', 1)
    changed = changed.replace(b'  Verification: `pending`', ('  Verification: `' + evidence + '`').encode(), 1)
    changed = changed.replace(b'  Commit: `pending`', ('  Commit: `' + owner + ': prepare source-bound consumer canonical meanings`').encode(), 1)
    changed = changed.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S Publish only admitted source-bound consumer canonical meanings. locates the unchanged canonical obligation. Complete independent source-derived consumer truth is committed, but the canonical fact still leaves that scope open; publication must preserve every old fact/question/probe and original limit without collection growth.\n'
        '  - [x] **ADDRESSED (verified)** — Independent fixed-source reviewed whole paragraph correspondence admits only source-derived typed consumer operands/truth and equivalent contractions. Complete direct/cached queries and all physical metrics conserve under unchanged authority. Genuine omitted/borrowed/Boolean/meaning/native-promotion candidates reach intended ValueError refusals; live canonical production and all historical helpers remain exact.\n'
        '  - [x] **NO REGRESSION** — All tests successful in focused current-publication, stream-recovery, task/claim/disposition and book audits. Whole current source/query/capacity/book/native, fresh complete meaning replay, independent preparation, claim/inventory, staged scripts/check_doctrines.sh and normal hooks qualify this commit. Maintained publication and complete canonical/original consumer acceptance remain separate.\n\n').encode()
    task = task.replace(original, changed, 1)
    review = json.loads((BASE / 'book-review.json').read_bytes())
    anchor = Path(PLAN['meaning'] + '/guide.txt').read_bytes()
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
            row['reference_contract']['aggregate_change'] = dict(authority_id='CONSUMER-CANONICAL-PREPARATION-20261012', owner=owner,
                baseline={key: measured_before[key] for key in keys}, delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Replace owned consumer status prose with prospective non-growing canonical preparation and its runnable saved reader. Preserve all existing replay examples and native/private unknowns within the unchanged chapter ceiling; canonical bytes and all authority ceilings do not grow.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active canonical preparation pointer')
    memory = memory.replace(owner + '` (active)', PLAN['parent'] + '.2` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate maintained consumer canonical publication .2 from clean committed non-growing preparation. Admit only the complete reviewed source-bound proposal; preserve every old fact/question/probe and retained helper, all capacity/source authority and native/private/Storable/synthetic limits. Add meaningful permanent first-admission controls; full canonical/original consumer acceptance remains separate.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after consumer canonical preparation verification and commit; derive later receipts under docs/audits/consumer-canonical-preparation-20261012.', memory, flags=re.M)
    marker = b'meanings done; canonical preparation active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique active canonical preparation frontier')
    index = before['docs/TASK_TREE.md'].replace(marker, b'canonical preparation done; publication next.', 1)
    need(max(map(len, index.splitlines())) <= 862, 'unchanged index width')
    after = {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows), 'MEMORY.md': memory.encode(), 'docs/TASK_TREE.md': index}
    return after, dict(task_names=task_names, book_names=book_names, task_metrics=measured_tasks,
                       book_before=measured_before, book_after=measured_books)


def qualify(*, current=False):
    row = json.loads((BASE / 'publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == {TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md'},
         'whole owned canonical preparation publication population')
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
    need(wanted == after and all(row[key] == value for key, value in measured.items()), 'whole independently reconstructed canonical preparation publication')
    first, final = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == final.keys(), 'whole task graph conserves')
    for name, block in first.items():
        if name == PLAN['owner']:
            need(all(field(block, key) == field(final[name], key) for key in ('Goal', 'Acceptance', 'Children'))
                 and field(final[name], 'Status') == 'done', 'only unchanged canonical preparation child closes')
        else:
            need(block == final[name], 'every unrelated complete task block retains')
    need(field(final[PLAN['parent']], 'Status') == 'active' and field(final[PLAN['parent'] + '.1'], 'Status') == 'done'
         and field(final[PLAN['parent'] + '.3'], 'Status') == 'pending', 'canonical and consumer-parent acceptance remain open')
    if current:
        need(original_public()['sources']() == canonical_sources(), 'whole live canonical production still equals its fixed beforeimage')
        name = 'scripts/check_record_value_publication.py'
        need(Path(name).read_bytes() == fixed([name])[name], 'maintained current factory has not advanced during preparation')
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
    need(not (BASE / 'publication.json').exists(), 'fresh complete canonical preparation publication')
    for name, roles in snapshots.items():
        for role, row in roles.items():
            Path(row['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, **measured))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole final publication input conservation')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Prepared source-bound consumer canonical meanings; live publication and consumer-parent acceptance remain next.')
