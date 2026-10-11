"""Close only complete finite raw owners and publish bounded current guidance."""
import copy
import gzip
import io
import json
from pathlib import Path
import re
import subprocess

from capture import BASE, canonical, pin, save
import intake
from verify import CLOSE, RAW, TASK, field, gate, need, nodes

PLAN = intake.PLAN
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


def main():
    names = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md')
    before = {name: Path(name).read_bytes() for name in names}
    need(before[TASK] == gzip.decompress((BASE / 'post-source-task.md.gz').read_bytes()),
         'exact source-qualified frontier plus tracked post-source metadata finding')
    task = before[TASK]
    original_nodes = nodes(task)
    evidence = ('Every unchanged original full raw/container Goal and Acceptance and all completed descendants rederive '
        'without narrowing. Complete original and current publication Git source graphs, modes, file/directory membership '
        'and native custody qualify; only explicit maintained publication instruments advance. Original e428 prerequisite '
        'receipt roles and later complete source checkpoint remain distinct. All original positive/hostile and typed '
        'semantic candidates freshly execute with independent native-body conservation before each intended semantic '
        'refusal. Current canonical meanings/questions/probes and source/query/capacity qualify under the unchanged factory. '
        'Whole original source-model assumptions, native/private/identity gaps, first failures and unmeasured interrupted '
        'peak RSS/first outer launch diagnostic retain. The first owned metadata import refusal retains; corrected helper '
        'interfaces pass unchanged original predicates. Whole source conservation permits only its exact tracked finding. '
        'Complete source/obligation/original-checkpoint/current-status/native-boundary interventions reject. Distinct claim '
        'legs are full fixed-source/contract and fresh semantic/native/current rederivation, genuine separating controls, '
        'and committed complete native/source/candidate/failure custody with a saved ignored-view-independent reader. '
        'This supplies no original native/private recapture or later historical-programme currency. Whole current '
        'book/native/focused/size/claim/inventory/staged/normal gates accompany commit. Only complete finite raw owners '
        'close; cause/consumer/alias/cold/permanent/host-native/private/visual/HIAL/full-CI/push retain their owners.')
    for owner in CLOSE:
        block = original_nodes[owner]
        need(field(block, 'Status') == 'active' and field(block, 'Commit') == 'pending', 'exact active full raw owner')
        updated = re.sub(rb'^  Status: `active`$', b'  Status: `done`', block, count=1, flags=re.M)
        updated = re.sub(rb'^  Verification: `.*`$', lambda _: ('  Verification: `' + evidence + '`').encode(), updated, count=1, flags=re.M)
        updated = updated.replace(b'  Commit: `pending`', ('  Commit: `' + PLAN['owner'] + ': close complete finite raw acceptance`').encode(), 1)
        if owner == PLAN['owner']:
            updated = updated.rstrip() + (
                '\n  Acceptance Checklist (enforced):\n'
                '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S Qualify complete original raw stacks identifies the unchanged full raw obligation in root-history. All child proofs and canonical publication were committed, while complete original raw/container acceptance remained open. First actual metadata harness failure names prior.py13 and its wrong helper import; complete programme and terminal retain.\n'
                '  - [x] **ADDRESSED (verified)** — Complete source/contract/native/prerequisite/current joins rederive. Every whole original positive/hostile and typed semantic candidate freshly executes while independent native bodies conserve. Genuine complete-source/obligation/typed-original/current/native-boundary joins refuse. Only full finite raw owners close, with every original source condition and native/private unknown explicit.\n'
                '  - [x] **NO REGRESSION** — All tests successful in the focused gate, including permanent current publication/recovery and task/claim/book controls. Whole book/native/source/query/capacity, saved/current proof, claim/inventory, staged scripts/check_doctrines.sh and normal hooks gate this commit; cause and every higher successor remain separately owned.\n\n').encode()
        need(task.count(block) == 1, 'unique complete task block replacement')
        task = task.replace(block, updated, 1)
    old_book = intake.git('show', PLAN['revision'] + ':' + BOOK)
    need(before[BOOK] == old_book, 'whole original raw guide before closure')
    start = old_book.index(b'The body reader changes only its own candidate-path boundary.')
    end = old_book.index(b'Canonical raw facts qualify finite source joins', start)
    old_guide = old_book[start:end]
    guide = (BASE / 'guide.txt').read_bytes()
    book = old_book[:start] + guide + old_book[end:]
    need(len(book) <= 292485 and len(book) <= len(old_book), 'non-growing raw guide within unchanged chapter allowance')
    tracked = intake.git('ls-tree', '-r', '--name-only', PLAN['revision']).decode().splitlines()
    task_names = sorted(name for name in tracked if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name))
    book_names = sorted(name for name in tracked if re.fullmatch(r'docs/book/src/[^/]+\.md', name))
    tasks, books = fixed(task_names), fixed(book_names)
    previous_book = metrics(books)
    tasks[TASK], books[BOOK] = task, book
    measured_task, measured_book = metrics(tasks), metrics(books)
    rows = list(map(json.loads, before[REGISTRY].splitlines()))
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            for key, value in measured_task.items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged full raw task ceiling')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(authority_id='RAW-FULL-ACCEPTANCE-20261011', owner=PLAN['owner'],
                baseline={key: previous_book[key] for key in keys}, delta={key: measured_book[key] - previous_book[key] for key in keys},
                rationale='Replace only owned raw status prose with complete finite acceptance, preserved original unknowns and exact saved/dated replay roles. Book shrinks; ceilings and Knowledge Map allowances retain.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(PLAN['owner'] + '` (active)') == 1, 'exact active full raw pointer')
    memory = memory.replace(PLAN['owner'] + '` (active)', PLAN['next'] + '` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate complete original primary/raw cause joining from clean committed finite raw acceptance. Reexecute qualified primary and raw coordinate/address proofs in their exact source roles; join every source/context/helper/API/parser/raw cause identity and genuine controls. Consumer/alias/cold/native and higher successors retain their unchanged owners.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after complete finite raw acceptance verification and commit; derive later gates under docs/audits/raw-full-acceptance-20261011.', memory, flags=re.M)
    marker = b'cleanup .84 done; raw acceptance active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique full raw frontier marker')
    after = {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows), 'MEMORY.md': memory.encode(),
             'docs/TASK_TREE.md': before['docs/TASK_TREE.md'].replace(marker, b'cleanup .84/raw done; cause join next.', 1)}
    need(max(map(len, after['docs/TASK_TREE.md'].splitlines())) <= 862, 'unchanged full raw index width')
    snapshots = {}
    need(not (BASE / 'publication.json').exists(), 'fresh complete raw publication')
    for index, name in enumerate(names):
        snapshots[name] = {}
        for role, body in (('before', before[name]), ('after', after[name])):
            path = BASE / ('publication-' + role + '-' + str(index) + '.gz')
            need(not path.exists(), 'all publication targets preflight before writes')
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    for name, roles in snapshots.items():
        for role, entry in roles.items():
            Path(entry['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, old_guide=old_guide.decode(), guide=guide.decode(),
        task_names=task_names, book_names=book_names, task_metrics=measured_task, book_before=previous_book, book_after=measured_book))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole unchanged final publication inputs')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published complete finite raw acceptance; original native/private boundaries and higher owners remain explicit.')


def qualify(*, current=False):
    row = json.loads((BASE / 'publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == {TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md'},
         'complete owned full raw publication population')
    source = {}
    for name, roles in row['snapshots'].items():
        source[name] = {}
        need(set(roles) == {'before', 'after'}, 'whole raw publication source roles')
        for role, entry in roles.items():
            path = Path(entry['snapshot'])
            need(path.parent == BASE and path.name.startswith('publication-' + role + '-') and path.suffix == '.gz',
                 'ordinary exact full raw publication snapshot')
            body = gzip.decompress(path.read_bytes())
            need(pin(body) == entry['identity'], 'whole raw publication role bytes')
            source[name][role] = body
        if current:
            need(Path(name).read_bytes() == source[name]['after'], 'whole current full raw publication source')
    old, new = (nodes(source[TASK][role]) for role in ('before', 'after'))
    need(old.keys() == new.keys(), 'whole task graph conserves during full raw closure')
    for name in old:
        need(all(field(old[name], key) == field(new[name], key) for key in ('Goal', 'Acceptance', 'Children')),
             'every whole original task contract conserves')
        if name in CLOSE:
            need(field(old[name], 'Status') == 'active' and field(new[name], 'Status') == 'done', 'only full finite raw owners close')
        else:
            need(old[name] == new[name], 'every unrelated whole task node conserves')
    need(source[BOOK]['after'] == source[BOOK]['before'].replace(row['old_guide'].encode(), row['guide'].encode(), 1)
         and len(source[BOOK]['after']) <= len(source[BOOK]['before']) <= 292485, 'sole non-growing raw status replacement')
    tasks, books = fixed(row['task_names']), fixed(row['book_names'])
    previous_book = metrics(books)
    tasks[TASK], books[BOOK] = source[TASK]['after'], source[BOOK]['after']
    measured_task, measured_book = metrics(tasks), metrics(books)
    need(row['task_metrics'] == measured_task and row['book_before'] == previous_book and row['book_after'] == measured_book,
         'whole independently rederived task/book measures')
    before, after = (list(map(json.loads, source[REGISTRY][role].splitlines())) for role in ('before', 'after'))
    need(len(before) == len(after), 'whole unchanged capacity surface population')
    for old_row, new_row in zip(before, after, strict=True):
        expected = copy.deepcopy(old_row)
        if old_row.get('surface_id') == 'task_evidence':
            for key, value in measured_task.items():
                need(value <= old_row['enforcement_ceilings'][key], 'unchanged full raw task ceiling')
                expected['transition']['max_growth'][key] = max(0, value + old_row['transition']['ratchet_step'][key] - old_row['baseline'][key])
        elif old_row.get('surface_id') == 'shipped_behavior':
            authority = new_row['reference_contract']['aggregate_change']
            need(authority['owner'] == PLAN['owner'] and authority['authority_id'] == 'RAW-FULL-ACCEPTANCE-20261011'
                 and authority['baseline'] == {key: previous_book[key] for key in ('files', 'bytes_total', 'lines_total')}
                 and authority['delta'] == {key: measured_book[key] - previous_book[key] for key in ('files', 'bytes_total', 'lines_total')},
                 'exact full raw book authority')
            expected['reference_contract']['aggregate_change'] = authority
        need(new_row == expected, 'all other allowances and ceilings including Knowledge Map retain')
    native = gate('gate-publish', ['python3', '-B', str(BASE / 'publish.py')],
        'Published complete finite raw acceptance; original native/private boundaries and higher owners remain explicit.\n', current=current)
    return dict(identity=pin(canonical(row)), native=pin(canonical(native)))


if __name__ == '__main__':
    main()
