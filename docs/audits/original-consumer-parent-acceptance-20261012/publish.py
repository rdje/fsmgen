"""Publish only unchanged complete original finite consumer acceptance."""
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
         'exact unchanged active original consumer parent and final acceptance leaf')
    evidence = ('The complete unchanged original consumer Goal/Acceptance and every source-contract, meaning and canonical descendant contract qualify together. '
        'Fresh whole source/meaning/canonical replays and isolated independent original readers derive every exact source assertion/context/actor/type/path/API/helper/cause, complete typed operand and comparison outcome across all original ordinary/Storable/unchanged-input-control modes. '
        'A separately reconstructed source-first association consumes every full qualified source/meaning/operand/truth binding exactly once. Native passed flags supply no independent truth. Every original source/native/product/cause body, qualified Storable kind witness, opaque synthetic trace and native/private limit retains. '
        'Every canonical fact/question/probe and all twelve maintained helper interfaces remain byte-exact. Complete genuine parent-link, original source-expression/context/helper/coordinate/role/source/boundary and original meaning false-green/operand/source/helper/primary/kind/structural/omission controls reach intended native first causes. '
        'All first child failures, pre-launch refusals, source epochs, actual/declared status distinctions and verified repairs retain, including canonical preparation size, publication whitespace/staging and the repaired canonical-parent development null-ceiling refusal. '
        'Development complete interfaces/candidate/native controls and whole publication/capacity/staging/saved-proof preflight precede formal freeze; complete source/native epochs and a revised static book proposal retain. '
        'Claim legs are complete unchanged contracts and source-first independent source/typed-meaning/operand/outcome/admission/current reconstruction; whole genuine native separating candidates with intended first causes and permanent admission regressions; and committed complete source/programmes/commands/statuses/streams/products/candidates/publication/native snapshots with sealed/default recovery and normal hooks. '
        'Current source/query/capacity/book/native/focused/size/claim/inventory/staged/normal delivery closes only original finite consumer parent and acceptance leaf. Higher context/cause/coordinate join, full alias downstream and every product/semantic/cold/permanent/host-native/private/visual/HIAL/full-CI/push owner remain open.')
    for name in (owner, parent):
        original = first[name]
        changed = original.replace(b'  Status: `active`', b'  Status: `done`', 1)
        changed = changed.replace(('  Verification: `' + field(original, 'Verification') + '`').encode(),
                                  ('  Verification: `' + evidence + '`').encode(), 1)
        changed = changed.replace(b'  Commit: `pending`', ('  Commit: `' + owner + ': accept complete original consumer operands and outcomes`').encode(), 1)
        if name == owner:
            changed = changed.rstrip() + (
                '\n  Acceptance Checklist (enforced):\n'
                '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S Independently qualify every original consumer operand and outcome. locates the unchanged original obligation. Separate source contracts, independent meanings and canonical acceptance leave the complete original parent open; every original source/context/typed operand/outcome must join without native passed authority.\n'
                '  - [x] **ADDRESSED (verified)** — Fresh complete source/meaning/canonical replays and isolated independent readers join every unchanged descendant and original source assertion to every typed operand/outcome in all original modes. Complete actual parent-link/source/meaning native controls reach intended first causes; all first failures/repairs, Storable/synthetic/private limits and canonical facts/questions/probes retain. Only original finite consumer parent/acceptance close.\n'
                '  - [x] **NO REGRESSION** — All tests successful in focused publication/stream/task/claim/disposition/book audits. Current complete source/query/capacity/book/native, permanent admission, full saved/fresh source/meaning/link/native-control reconstruction, size/claim/inventory, staged scripts/check_doctrines.sh and normal hooks qualify delivery. Higher context/cause/coordinate join, full alias and every higher owner remain open.\n\n').encode()
        need(task.count(original) == 1, 'whole unique unchanged parent/acceptance block beforeimage')
        task = task.replace(original, changed, 1)
    review = json.loads((BASE / 'book-review.json').read_bytes())
    anchor = Path(PLAN['canonical_parent'] + '/guide.txt').read_bytes()
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
            row['reference_contract']['aggregate_change'] = dict(authority_id='ORIGINAL-CONSUMER-PARENT-ACCEPTANCE-20261012', owner=owner,
                baseline={key: measured_before[key] for key in keys}, delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Document complete unchanged original consumer-parent/descendant source/typed-meaning/operand/outcome acceptance with preserved source/native/private limits and separately owned higher context/cause/coordinate/full-alias scopes. Reviewed whole prose preserves all prior facts, examples, controls, commands and encoding dispositions without widening any ceiling or canonical collection authority.')
    ancestor = parent.rsplit('.', 1)[0]
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active complete original consumer acceptance pointer')
    memory = memory.replace(owner + '` (active)', PLAN['next_join'] + '` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate complete original context/cause/coordinate/consumer join .4 from clean consumer acceptance; qualify all unchanged child meanings. Preserve full alias and higher successors.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None; derive original consumer acceptance receipts under docs/audits/original-consumer-parent-acceptance-20261012.', memory, flags=re.M)
    marker = b'original consumer acceptance active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique active complete original consumer acceptance frontier')
    index = before['docs/TASK_TREE.md'].replace(marker, b'consumer done; meaning join next.', 1)
    need(max(map(len, index.splitlines())) <= 862, 'unchanged index width')
    return {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows), 'MEMORY.md': memory.encode(), 'docs/TASK_TREE.md': index}, dict(
        task_names=task_names, book_names=book_names, task_metrics=measured_tasks, book_before=measured_before, book_after=measured_books)


def qualify(*, current=False):
    row = json.loads((BASE / 'publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == {TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md'},
         'whole owned unchanged original-consumer publication population')
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
    need(wanted == after and all(row[key] == value for key, value in measured.items()), 'whole independently reconstructed unchanged original consumer acceptance publication')
    first, final = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == final.keys(), 'whole task graph conserves')
    for name, block in first.items():
        if name in (PLAN['owner'], PLAN['parent']):
            need(all(field(block, key) == field(final[name], key) for key in ('Goal', 'Acceptance', 'Children'))
                 and field(final[name], 'Status') == 'done', 'only full unchanged original consumer parent and acceptance leaf close')
        else:
            need(block == final[name], 'every unrelated whole task block retains')
    parent = PLAN['parent']
    need(all(field(final[name], 'Status') == 'done' for name in final if name.startswith(parent + '.'))
         and field(final[PLAN['next_join']], 'Status') == field(final[PLAN['full_alias']], 'Status') == 'pending',
         'all complete original consumer descendants and separately open higher/full-alias owners retain')
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
    print('Published only unchanged original finite consumer acceptance; full alias downstream and higher owners retain.')
