"""Commit prerequisite preparation without closing cause or higher scopes."""
import copy
import gzip
import io
import json
from pathlib import Path
import re
import subprocess

from capture import BASE, canonical, pin, save
import intake
from verify import TASK, field, gate, need, nodes

PLAN = intake.PLAN
BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
COMMANDS = {
    'focused-corrected': ['prove', '-v', 't/2066-record-value-current-publication.t', 't/2067-record-value-gate-streams.t',
                't/1549-task-tree-integrity-doctrine.t', 't/1636-claim-verification-doctrine.t',
                't/1303-isf-public-live-book-paths-audit.t', 't/1305-isf-book-feature-matrix-audit.t'],
    'book-corrected': ['mdbook', 'build', 'docs/book'],
    'native-corrected': ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', 'docs/book/book'],
    'size-corrected': ['scripts/check_live_document_size.sh'], 'claims': ['scripts/check_claim_verification.pl'],
    'inventory-write-corrected': ['scripts/check_claim_verification_inventory.pl', '--write'],
    'inventory-corrected': ['scripts/check_claim_verification_inventory.pl']}


def metrics(sources):
    rows = [dict(bytes=len(body), lines=body.count(b'\n'), width=max(map(len, body.splitlines()), default=0))
            for body in sources.values()]
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
    task = before[TASK]
    old = nodes(task)
    owner = PLAN['owner']
    block = old[owner]
    need(field(block, 'Status') == 'active' and field(block, 'Commit') == 'pending', 'exact active prerequisite preparation')
    evidence = ('Complete original/current Git source/native/product domains and all whole committed primary/raw/coordinate/address descendant contracts retain. '
        'The original primary reader independently authenticates its complete pinned source/native graph; its first run predates the separate retained source census, so no temporal before-census for that run is claimed. '
        'A separate fresh primary replay, complete coordinate/address and dated full raw readers execute between matching whole source censuses; every actual programme, command, status and stream retains before typed judgement. '
        'The original coordinate reader updates its separately tracked progress during execution; the retained observation names its original write sites and whole after-census proves the exact terminal source is restored. Review caught the new verifier conditions tuple/list round-trip defect before sealing; the retained first programme and actual JSON comparison reproduce rejection before and equality after the list repair, with both original conditions conserved. Source models, native/private/identity gaps, original failures and unknowns retain. Genuine source/contract/Boolean-primary/raw-command/coordinate/native-promotion join interventions reject. '
        'Claim legs are complete fixed-source/contract and native-reader rederivation, inherited semantic plus separating join controls, and complete committed source/native/product/receipt custody with a saved reader. '
        'Whole current book/native/focused/size/claim/inventory/staged/normal gates accompany this source prerequisite commit. Independent every-operation cause association and cause-parent closure remain pending; consumer/alias/cold/permanent/host-native/private/visual/HIAL/full-CI/push keep their owners.')
    changed = block.replace(b'  Status: `active`', b'  Status: `done`', 1)
    changed = changed.replace(b'  Verification: `pending`', ('  Verification: `' + evidence + '`').encode(), 1)
    changed = changed.replace(b'  Commit: `pending`', ('  Commit: `' + owner + ': qualify primary raw prerequisites`').encode(), 1)
    changed = changed.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S Join complete original primary and raw native cause semantics locates the unchanged cause obligation. The committed full raw proof and primary proof existed separately; complete source-role prerequisite reexecution was the first explicit open cause child.\n'
        '  - [x] **ADDRESSED (verified)** — Whole original primary/raw and eleven coordinate/address native readers pass in their exact source or dated roles. Complete source membership and modes conserve around coordinate/address/raw execution. Whole original prerequisite contracts and cause Goal/Acceptance retain; six genuine source/contract/status/command/membership/native-boundary interventions reject. No cause association or parent closure is claimed.\n'
        '  - [x] **NO REGRESSION** — All tests successful in focused current publication, stream recovery, task/claim and book audits. Complete current book/native/source/query/capacity, saved/current prerequisite proof, claim/inventory and staged scripts/check_doctrines.sh plus normal hooks gate the commit. Original semantic/native/private limitations remain explicit.\n\n').encode()
    task = task.replace(block, changed, 1)
    old_guide = Path(PLAN['raw_acceptance'] + '/guide.txt').read_bytes()
    guide = (BASE / 'guide.txt').read_bytes()
    need(before[BOOK].count(old_guide) == 1 and len(guide) <= len(old_guide), 'unique non-growing owned guide replacement')
    book = before[BOOK].replace(old_guide, guide, 1)
    need(len(book) <= 292485, 'unchanged book chapter allowance')
    names = intake.git('ls-tree', '-r', '--name-only', PLAN['revision']).decode().splitlines()
    task_names = sorted(n for n in names if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', n))
    book_names = sorted(n for n in names if re.fullmatch(r'docs/book/src/[^/]+\.md', n))
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
            row['reference_contract']['aggregate_change'] = dict(authority_id='PRIMARY-RAW-CAUSE-PREPARATION-20261011', owner=owner,
                baseline={k: measured_before[k] for k in keys}, delta={k: measured_books[k] - measured_before[k] for k in keys},
                rationale='Replace owned raw status prose with source/dated primary/raw prerequisite progress and runnable saved reader. Preserve original examples and native/private unknowns; book shrinks, ceilings and canonical allowances retain.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact prerequisite active pointer')
    memory = memory.replace(owner + '` (active)', PLAN['parent'] + '.2` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate independent primary/raw cause association .3.2 from clean committed prerequisite preparation. Reconstruct every original source/context/helper/API/parser first cause, acceptance, raw body, coordinate/address and nested/empty membership; preserve all prior controls and original native/private limits before canonical or parent closure.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after complete cause prerequisite verification and commit; derive later gates under docs/audits/primary-raw-cause-preparation-20261011.', memory, flags=re.M)
    marker = b'raw done; cause preparation active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique cause preparation index pointer')
    after = {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows), 'MEMORY.md': memory.encode(),
             'docs/TASK_TREE.md': before['docs/TASK_TREE.md'].replace(marker, b'raw/prerequisites done; cause association next.', 1)}
    need(max(map(len, after['docs/TASK_TREE.md'].splitlines())) <= 862, 'unchanged index width')
    return after, dict(task_names=task_names, book_names=book_names, task_metrics=measured_tasks,
        book_before=measured_before, book_after=measured_books)


def main():
    names = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md')
    before = {name: Path(name).read_bytes() for name in names}
    need(before[TASK] == gzip.decompress((BASE / 'activation-task.md.gz').read_bytes()), 'whole source-qualified activation task')
    need(all(before[name] == body for name, body in intake.overlays().items()), 'whole unchanged activation metadata')
    after, measured = transformation(before)
    snapshots = {}
    for i, name in enumerate(names):
        snapshots[name] = {}
        for role, body in (('before', before[name]), ('after', after[name])):
            path = BASE / ('publication-' + role + '-' + str(i) + '.gz')
            need(not path.exists(), 'fresh complete publication snapshot')
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    need(not (BASE / 'publication.json').exists(), 'fresh complete prerequisite publication')
    for name, roles in snapshots.items():
        for role, row in roles.items():
            Path(row['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, **measured))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole final publication input conservation')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published source-bound cause prerequisites; independent association remains next.')


def qualify_original(*, current=False):
    row = json.loads((BASE / 'publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == {TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md'},
         'whole owned prerequisite publication population')
    before, after = {}, {}
    for name, roles in row['snapshots'].items():
        need(set(roles) == {'before', 'after'}, 'complete publication source roles')
        for role, entry in roles.items():
            path = Path(entry['snapshot'])
            need(path.parent == BASE and path.name.startswith('publication-' + role + '-') and path.suffix == '.gz',
                 'exact ordinary owned source snapshot')
            body = gzip.decompress(path.read_bytes())
            need(pin(body) == entry['identity'], 'whole publication source snapshot bytes')
            (before if role == 'before' else after)[name] = body
        if current:
            need(Path(name).read_bytes() == after[name], 'whole explicit current publication source')
    wanted, measured = transformation(before)
    need(wanted == after and all(row[key] == value for key, value in measured.items()), 'whole independently reconstructed prerequisite publication')
    first, final = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == final.keys(), 'whole task graph conserves')
    for name, block in first.items():
        if name == PLAN['owner']:
            need(all(field(block, key) == field(final[name], key) for key in ('Goal', 'Acceptance', 'Children'))
                 and field(final[name], 'Status') == 'done', 'only unchanged prerequisite preparation closes')
        else:
            need(block == final[name], 'every unrelated whole task block retains')
    need(field(final[PLAN['parent']], 'Status') == 'active'
         and all(field(final[PLAN['parent'] + '.' + str(i)], 'Status') == 'pending' for i in (2, 3)),
         'cause association and final parent acceptance remain open')
    return row




def original_after():
    row = qualify_original()
    return {name: gzip.decompress(Path(roles['after']['snapshot']).read_bytes())
            for name, roles in row['snapshots'].items()}


def recovered(original):
    finding = json.loads((BASE / 'import-finding.json').read_bytes())
    need(finding['owner'] == PLAN['owner'], 'exact owned final-import recovery')
    task = original[TASK]
    block = nodes(task)[PLAN['owner']]
    original_block = block
    resolution = ('  Finding F1 resolution: `The temporary original replay import now restores its prior sys.path in finally. '
        'The complete first and corrected runner bodies differ only by scoped import handling; all original child commands, '
        'reader programmes and predicates retain. A fresh direct import check and corrected full seal/default verify the '
        'actual publisher resolves this owned verifier. Corrected focused/book/native/size/claim/inventory/staged/normal '
        'gates accompany commit. First native1/declared0 retains as unexpected metadata failure; original prerequisite '
        'successes remain in their unchanged source/dated roles. Independent cause association remains next.`\n')
    additions = {
        'ROOT CAUSE (WHY + WHERE)': ' First seal native1/declared0 names publish.py12 and the historical verify.py import: the original prerequisite runner leaked its temporary first sys.path entry. Complete actual trace and first programmes are retained in import-finding.json.',
        'ADDRESSED (verified)': ' A scoped try/finally import restores the prior path while complete original child commands and predicates conserve; actual corrected import and full seal/default exercise the repaired interface.',
        'NO REGRESSION': ' Corrected focused/book/native/size/claim/inventory and final saved/current gates repeat after the owned import repair and tracked failure finding.'}
    for label, addition in additions.items():
        pattern = rb'^(  - \[x\] \*\*' + re.escape(label.encode()) + rb'\*\*.*)$'
        block, count = re.subn(pattern, lambda match: match[1] + addition.encode(), block, count=1, flags=re.M)
        need(count == 1, 'exact box-scoped recovered cause fix and regression evidence')
    second = json.loads((BASE / 'recovery-finding.json').read_bytes())
    need(second['owner'] == PLAN['owner'], 'exact owned recovery block finding')
    second_resolution = ('  Finding F2 resolution: `The original block is now retained before box edits, then uniquely matched and replaced. Corrected complete recovery publication, final seal/default and delivery/staged/normal gates verify this change; both first unexpected native failures remain preserved.`\n')
    updated = (block.rstrip() + b'\n' + finding['finding'].encode() + resolution.encode()
               + second['finding'].encode() + second_resolution.encode() + b'\n')
    need(task.count(original_block) == 1 and field(original_block, 'Status') == 'done', 'exact original proposed prerequisite closure')
    task = task.replace(original_block, updated, 1)
    rows = list(map(json.loads, original[REGISTRY].splitlines()))
    publication = json.loads((BASE / 'publication.json').read_bytes())
    tasks = fixed(publication['task_names']); tasks[TASK] = task
    measured = metrics(tasks)
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            for key, value in measured.items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged recovered task ceilings')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
    return dict(original, **{TASK: task, REGISTRY: b''.join(canonical(row) for row in rows)}), measured


def recover():
    original = original_after()
    before = {name: Path(name).read_bytes() for name in original}
    need(before[TASK] == gzip.decompress((BASE / 'recovery-active-task.md.gz').read_bytes())
         and before['MEMORY.md'] == gzip.decompress((BASE / 'recovery-active-memory.md.gz').read_bytes())
         and all(before[name] == original[name] for name in (BOOK, REGISTRY, 'docs/TASK_TREE.md')),
         'whole exact current-owned import recovery activation; unrelated publication retains')
    after, measured = recovered(original)
    snapshots = {}
    need(not (BASE / 'recovery-publication.json').exists(), 'fresh owned recovery publication')
    for i, name in enumerate(sorted(original)):
        snapshots[name] = {}
        for role, body in (('before', before[name]), ('after', after[name])):
            path = BASE / ('recovery-publication-' + role + '-' + str(i) + '.gz')
            need(not path.exists(), 'fresh complete recovery source snapshot')
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    for name, roles in snapshots.items():
        for role, row in roles.items():
            Path(row['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('recovery-publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, task_metrics=measured,
        condition='Only the owned import-failure finding/resolution and exact task size ratchet supplement the original publication. Every original source/contract/book/canonical meaning, ceiling and native/private gap retains.'))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole unchanged recovery publication inputs')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published corrected owned import recovery; original reader results and scopes retain.')


def qualify(*, current=False):
    first = qualify_original()
    original = original_after()
    expected, measured = recovered(original)
    row = json.loads((BASE / 'recovery-publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == set(original)
         and row['task_metrics'] == measured, 'whole recovered owned source and measured population')
    for name, roles in row['snapshots'].items():
        need(set(roles) == {'before', 'after'}, 'whole recovery source roles')
        for role, entry in roles.items():
            path = Path(entry['snapshot'])
            need(path.parent == BASE and path.name.startswith('recovery-publication-' + role + '-')
                 and path.suffix == '.gz', 'exact ordinary recovery snapshot')
            body = gzip.decompress(path.read_bytes())
            need(pin(body) == entry['identity'], 'whole recovery source role bytes')
            if role == 'after':
                need(body == expected[name], 'whole independently rederived recovery publication')
            elif name == TASK:
                need(body == gzip.decompress((BASE / 'recovery-active-task.md.gz').read_bytes()), 'exact active task recovery input')
            elif name == 'MEMORY.md':
                need(body == gzip.decompress((BASE / 'recovery-active-memory.md.gz').read_bytes()), 'exact active pointer recovery input')
            else:
                need(body == original[name], 'every unrelated recovery input retains')
        if current:
            need(Path(name).read_bytes() == expected[name], 'whole current recovered publication')
    return dict(original=first, recovery=row)


if __name__ == '__main__':
    main()
