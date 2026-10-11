"""Publish only complete remaining original consumer operands/truth."""
import gzip
import io
import json
from pathlib import Path
import re
import subprocess

from remaining_common import *
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
    need(field(original, 'Status') == 'active' and field(original, 'Commit') == 'pending', 'exact active remaining-consumer leaf')
    evidence = ('Whole fixed original/current source/native/helper/source-contract and qualified JSON/type/actor/path/API/copy product custody authenticate under the unchanged full consumer meaning contract. '
        'A proposal selects qualified whole source products; the independent reader uses source recipes, complete authored values/literal grammar and exact lexical/dataflow/property allocation to reconstruct every nonhelper operand. '
        'Independent defined-scalar, complete structural scalar-string and finite regex rules derive truth before native custody and never accept passed flags as authority. Raw string/numeric/undefined/graph kinds remain independently exact. '
        'The first model failed actual1/declared0 by equating actor and Storable copy kinds. Complete first programmes/candidate/streams and separate unchanged-programme native reproduction retain; the corrected model binds already qualified original test-copy primitive kinds, with no new provider/flag/identity inference. '
        'Separate public installed Test::More cases corroborate finite positive/negative scalar/structural/regex rules. Whole synthetic trace stays an authenticated opaque original input, with own authored message/pattern/first-line roles qualified and native coordinates/framework/private/provider/identity/construction unmeasured. '
        'Complete genuine native false-green/false-red/source/API/property/actor/structure/kind/omission/synthetic/helper-promotion controls reach intended first refusals; every helper observation conserves without requalifying meaning. '
        'The first recovery attempt miscounted the RAM-guard launcher as an authored input; complete native failed reproduction/core and diagnosis retain. Exact launcher-prefix correction and separately successful original-reader failure reproduction qualify the repair; old native results never relabel. '
        'Claim legs are own source/model/operand/direct-comparison reconstruction, genuine complete native separating candidates plus public comparison cases, and committed complete programmes/commands/streams/products/source epochs/publication snapshots with saved-only replay. '
        'Current source/query/capacity/book/native/focused/size/claim/inventory/staged/normal delivery closes only remaining assertions; complete join/meaning acceptance, canonical/original parent and higher scopes retain.')
    changed = original.replace(b'  Status: `active`', b'  Status: `done`', 1)
    changed = changed.replace(b'  Verification: `pending`', ('  Verification: `' + evidence + '`').encode(), 1)
    changed = changed.replace(b'  Commit: `pending`', ('  Commit: `' + owner + ': qualify remaining original consumer truth`').encode(), 1)
    changed = changed.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S Independently qualify every remaining original consumer assertion. locates the unchanged source/type/actor/path/API/copy/dataflow obligation. Helper truth and source contracts do not qualify nonhelper operands. The first independent native gate failed actual1/declared0 at storable consumer16 expected string width; identical actor/copy-kind assumption omitted the qualified original Storable copy witness. Complete native first failure/diagnosis and separate unchanged-programme reproduction locate the mechanism; native passed flags cannot establish operands or truth.\n'
        '  - [x] **ADDRESSED (verified)** — Independent source literal/recipe/property/dataflow and complete typed graph reconstruction derives every remaining operand/outcome. Corrected actor-copy binding preserves the qualified original Storable primitive-kind witness; a genuine changed-copy-kind control rejects without any new provider/flag/identity claim. Finite public Test::More positive/negative cases corroborate separate comparison rules. Genuine full-candidate false-green/source/API/property/structure/kind/omission/synthetic-promotion controls reject; whole original synthetic trace remains opaque, with source first-line/pattern roles qualified.\n'
        '  - [x] **NO REGRESSION** — All tests successful in focused current-publication, stream recovery, task/claim/disposition and book audits. Whole current source/query/capacity/book/native, fresh saved source-contract/helper readers, claim/inventory, staged scripts/check_doctrines.sh and normal hooks qualify this child. Helper/full consumer join/meaning/canonical/original parent and higher acceptance remain separate.\n\n').encode()
    task = task.replace(original, changed, 1)
    review = json.loads((BASE / 'book-review.json').read_bytes())
    anchor = Path(PLAN['publication'] + '/guide.txt').read_bytes()
    guide = (BASE / 'guide.txt').read_bytes()
    need(before[BOOK].count(anchor) == 1, 'whole unique committed source-contract guidance')
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
            row['reference_contract']['aggregate_change'] = dict(authority_id='REMAINING-CONSUMER-TRUTH-20261011', owner=owner,
                baseline={key: measured_before[key] for key in keys}, delta={key: measured_books[key] - measured_before[key] for key in keys},
                rationale='Document all remaining source-derived typed consumer operands and independently evaluated scalar/structural/regex outcomes. Reviewed bounded prose preserves every prior fact/example/native/private limit and encoding disposition; canonical authority and book ceiling do not grow.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active remaining-consumer pointer')
    memory = memory.replace(owner + '` (active)', PLAN['parent'] + '.3` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate complete original consumer join .3.3.2.3 from clean committed helper and remaining-assertion qualifications. Independently join every original source/operand/outcome across all modes, preserving complete typed/native/source custody and synthetic/private limits. Full meaning acceptance, canonical publication and original consumer-parent closure remain separate.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after complete remaining original consumer truth verification and commit; derive later receipts under docs/audits/remaining-consumer-truth-20261011.', memory, flags=re.M)
    marker = b'helper truth done; remaining assertions active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique active remaining-consumer truth frontier')
    index = before['docs/TASK_TREE.md'].replace(marker, b'remaining truth done; complete consumer join next.', 1)
    need(max(map(len, index.splitlines())) <= 862, 'unchanged index width')
    after = {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows), 'MEMORY.md': memory.encode(), 'docs/TASK_TREE.md': index}
    return after, dict(task_names=task_names, book_names=book_names, task_metrics=measured_tasks,
                       book_before=measured_before, book_after=measured_books)


def qualify(*, current=False):
    row = json.loads((BASE / 'publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == {TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md'},
         'whole owned remaining-consumer publication population')
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
    need(wanted == after and all(row[key] == value for key, value in measured.items()), 'whole independently reconstructed remaining-consumer publication')
    first, final = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == final.keys(), 'whole task graph conserves')
    for name, block in first.items():
        if name == PLAN['owner']:
            need(all(field(block, key) == field(final[name], key) for key in ('Goal', 'Acceptance', 'Children'))
                 and field(final[name], 'Status') == 'done', 'only unchanged remaining-consumer child closes')
        else:
            need(block == final[name], 'every unrelated complete task block retains')
    need(field(final[PLAN['parent']], 'Status') == 'active'
         and all(field(final[PLAN['parent'] + '.' + str(index)], 'Status') == 'pending' for index in (3, 4)),
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
    need(not (BASE / 'publication.json').exists(), 'fresh complete remaining-consumer publication')
    for name, roles in snapshots.items():
        for role, row in roles.items():
            Path(row['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, **measured))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole final publication input conservation')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published only remaining original consumer truth; full join/meaning/canonical/parent acceptance retain.')
