"""Publish only the qualified independent cause-association child."""
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
    evidence = ('Complete original cause/canonical and completed primary/raw/prerequisite/association contracts retain without narrowing. '
        'The fixed original and current source graph explicitly adds the complete canonical documents and Knowledge Map query tooling. Whole before/after source membership, modes and bodies conserve around fresh saved independent-association, original current-data/query and canonical preparation executions. '
        'The complete canonical proposal adds only admitted whole finite cause/raw/empty/nested source joins and four explicitly reviewed equivalent contractions. Every front-matter/fact/question/evidence/probe byte and every untouched meaning retains; complete ordered old/new paragraphs and their review remain replayable. All physical canonical metrics and the complete target byte/line size do not grow under unchanged authority. '
        'Independent fixed-source reconstruction and genuine omission/borrowed/Boolean/native-boundary interventions qualify the proposal. Explicit engineering equivalence review is supported by whole source/cause products and byte correspondence, not asserted as a universal automated natural-language proof. All original failed epochs, source-model assumptions and native/private/provider/identity unknowns retain. '
        'Claim legs are complete fixed source/contract/cause/canonical/query/capacity rederivation, genuine separating controls with every inherited original product retained, and committed complete beforeimages/proposal/source/native/receipt custody with saved recovery. Whole current book/native/focused/size/claim/inventory/staged/normal gates accompany this preparation. Live canonical production, publication and complete cause-parent acceptance remain open; all higher owners retain.')
    changed = original.replace(b'  Status: `active`', b'  Status: `done`', 1)
    changed = changed.replace(b'  Verification: `pending`', ('  Verification: `' + evidence + '`').encode(), 1)
    changed = changed.replace(b'  Commit: `pending`', ('  Commit: `' + owner + ': prepare source-bound cause canonical meanings`').encode(), 1)
    changed = changed.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S Publish and close complete unchanged primary/raw cause acceptance. locates the unchanged canonical/parent obligation. Independent cause association is committed while canonical source meanings and whole parent acceptance remain open; the prospective extension must retain all old facts and original limits without collection growth.\n'
        '  - [x] **ADDRESSED (verified)** — Complete fixed original/current canonical and cause source roles, whole reviewed before/after correspondence, source-derived direct/cached questions and non-growing capacity qualify. Genuine omitted/borrowed/Boolean/native-boundary proposals reject. Production canonical bytes and original factory retain; no live publication or parent closure is inferred.\n'
        '  - [x] **NO REGRESSION** — All tests successful in focused current-publication, stream-recovery, task/claim and book audits. Whole current book/native/source/query/capacity, saved preparation and association, claim/inventory, staged scripts/check_doctrines.sh and normal hooks accompany this commit; original failures/unknowns and higher scopes retain.\n\n').encode()
    task = task.replace(original, changed, 1)
    old_guide = Path(PLAN['association'] + '/guide.txt').read_bytes()
    guide = (BASE / 'guide.txt').read_bytes()
    need(before[BOOK].count(old_guide) == 1 and len(guide) <= len(old_guide) + 292485 - len(before[BOOK]), 'unique owned guide within unchanged chapter capacity')
    book = before[BOOK].replace(old_guide, guide, 1)
    need(len(book) <= 292485, 'unchanged book chapter allowance')
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
            row['reference_contract']['aggregate_change'] = dict(authority_id='PRIMARY-RAW-CAUSE-CANONICAL-PREPARATION-20261011', owner=owner,
                baseline={key: measured_before[key] for key in keys}, delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Replace owned cause status prose with prospective non-growing canonical preparation and its runnable saved reader. Preserve all existing replay examples and native/private unknowns within the unchanged chapter ceiling; canonical bytes and all authority ceilings do not grow.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active association pointer')
    memory = memory.replace(owner + '` (active)', PLAN['parent'] + '.2` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate governed cause canonical publication .3.3.2 from clean committed source-bound preparation. Admit only the complete reviewed non-growing candidate and extend current factory plus meaningful first-admission/source-role controls; preserve all original facts/questions/probes/native limits. Full unchanged cause-parent acceptance follows its commit.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after complete cause canonical preparation verification and commit; derive later gates under docs/audits/primary-raw-cause-canonical-preparation-20261011.', memory, flags=re.M)
    marker = b'cause association done; cause preparation active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique active cause association index pointer')
    index = before['docs/TASK_TREE.md'].replace(marker, b'cause canonical preparation done; publication next.', 1)
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
    need(field(final[PLAN['parent']], 'Status') == 'active' and field(final[PLAN['parent'] + '.1'], 'Status') == 'done'
         and field(final[PLAN['parent'] + '.3'], 'Status') == 'pending', 'canonical and cause-parent acceptance remain open')
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
    need(not (BASE / 'publication.json').exists(), 'fresh complete association publication')
    for name, roles in snapshots.items():
        for role, row in roles.items():
            Path(row['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, **measured))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole final publication input conservation')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Prepared source-bound cause canonical meanings; live publication and cause-parent acceptance remain next.')
