"""Close only complete raw semantic acceptance and update its bounded book status."""
import ast
import gzip
import json
from pathlib import Path
import re

from capture import BASE, canonical, pin, save
import verify

NOTICE = (b'Full raw semantic acceptance joins original readers, source custody, nested\n'
          b'causes and separating controls. Recovery refuses unsafe paths and conflicts.\n'
          b'Earlier failures retain; interrupted peak RSS and the first outer launch\n'
          b'diagnostic remain unknown. Native/private gaps and canonical publication stay open.\n\n')
OLD_ASSOCIATION = (b'This closes the finite association container only. Complete raw semantic\n'
                   b'parent acceptance and governed canonical raw publication remain separate.\n')
ASSOCIATION = (b'At the association checkpoint, only the finite association container closed.\n'
               b'Complete raw semantic acceptance and canonical raw publication were separate.\n')


def metrics(sources):
    rows = [dict(bytes=len(raw), lines=raw.count(b'\n'),
                 width=max((len(line.removesuffix(b'\r')) for line in raw.split(b'\n')), default=0))
            for raw in sources.values()]
    return dict(files=len(rows), bytes_total=sum(r['bytes'] for r in rows),
                lines_total=sum(r['lines'] for r in rows), bytes_each=max(r['bytes'] for r in rows),
                lines_each=max(r['lines'] for r in rows), line_bytes_each=max(r['width'] for r in rows))


def main():
    verify.core()
    names = (verify.TASK, verify.BOOK, verify.REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md')
    before = {name: Path(name).read_bytes() for name in names}
    original = verify.nodes(verify.git('show', verify.REVISION + ':' + verify.TASK))
    current = verify.nodes(before[verify.TASK])
    verify.need(original.keys() == current.keys(), 'whole original task graph before parent closure')
    for key in original:
        verify.need(all(verify.field(original[key], f) == verify.field(current[key], f)
                        for f in ('Goal', 'Acceptance', 'Children')), 'all original complete task contracts before closure')
        if key != verify.OWNER:
            verify.need(original[key] == current[key], 'every unrelated activation node conserves whole')
    evidence = ('Complete original checkpoint and recovery predicates freshly qualify every saved unchanged original reader/source role, '
        'whole native product, first failure and genuine context/semantic/recovery control. An actual source-first reader independently '
        'reconstructs the complete semantic product. Whole fixed Git bytes, executable modes and file/directory populations conserve '
        'before/after reconstruction, including complete original checkpoint/recovery namespaces. Every original parent and completed '
        'descendant Goal/Acceptance retains. Genuine omitted obligation, Boolean native status and omitted source joins refuse their '
        'intended predicates. Earlier source-model assumptions, opaque boundaries, all failed epochs, unmeasured interrupted peak RSS '
        'and first outer launch diagnostic retain; no original native/private measurement or later source currency is inferred. '
        'Only .5.2, .5.2.3 and this acceptance leaf close. Canonical .5.3 and all higher native/private/cause/consumer/alias/cold/permanent/'
        'visual/HIAL/full-CI/push scopes remain open. Distinct claim legs are complete source/native and independent reconstruction '
        're-derivation, genuine semantic/context/recovery and whole join falsification, and committed complete evidence/source custody. '
        'Current book/native/focused/size/claims/inventory, staged doctrines and normal hooks gate delivery.')
    task = before[verify.TASK]
    for key in verify.CLOSE:
        block = verify.nodes(task)[key]
        verify.need(verify.field(block, 'Status') == 'active', 'exact active owning raw acceptance node')
        final = block.replace(b'  Status: `active`\n', b'  Status: `done`\n', 1)
        final = re.sub(rb'^  Verification: `.*`$', ('  Verification: `' + evidence + '`').encode(), final, count=1, flags=re.M)
        final = final.replace(b'  Commit: `pending`\n', ('  Commit: `' + verify.OWNER + ': qualify complete unchanged raw semantic acceptance`\n').encode(), 1)
        if key == verify.OWNER:
            final = final.rstrip() + (
                '\n  Acceptance Checklist (enforced):\n'
                '  - [x] **ROOT CAUSE (WHY + WHERE)** — Actual git log -S Join every complete original raw-stack meaning in root-history-actual.json identifies the unchanged parent obligation. Complete children were committed, but full original .5.2/.5.2.3 contract joining remained open; no parent closure follows merely from child success. First activation and binary-capture preflight refusals remain explicitly separate from original reader execution.\n'
                '  - [x] **ADDRESSED (verified)** — verify.py independently joins every unchanged original parent/descendant contract, whole fixed source and actual checkpoint/recovery metadata cores with actual source-first complete semantic reconstruction. Complete source census conserves before/after; original complete semantic/context/recovery counterexamples retain and new whole obligation/status/source join interventions reach intended refusals. Only the finite raw semantic acceptance closes; original native/private and canonical boundaries retain.\n'
                '  - [x] **NO REGRESSION** — All tests successful in focused-actual.json, including permanent recovery and existing task/claim/book contracts. Whole current book/native-copy, size, claims/inventory and committed-only qualification pass; staged scripts/check_doctrines.sh and normal hooks additionally gate commit.\n\n').encode()
        task = task.replace(block, final, 1)
    book = before[verify.BOOK]
    verify.need(book == verify.git('show', verify.REVISION + ':' + verify.BOOK), 'whole unchanged committed book before own status replacement')
    prior = ast.parse(Path(verify.PLAN['recovery'] + '/deliver.py').read_bytes())
    old_notice = next(ast.literal_eval(n.value) for n in prior.body if isinstance(n, ast.Assign)
                      and any(isinstance(t, ast.Name) and t.id == 'NOTICE' for t in n.targets))
    verify.need(book.count(old_notice) == book.count(OLD_ASSOCIATION) == 1, 'unique own notice and earlier association checkpoint paragraph')
    book_after = book.replace(old_notice, NOTICE, 1).replace(OLD_ASSOCIATION, ASSOCIATION, 1)
    verify.need(len(book_after) <= 292485, 'unchanged actual book allowance')
    tracked = verify.git('ls-tree', '-r', '--name-only', verify.REVISION).decode().splitlines()
    task_names = sorted(n for n in tracked if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', n))
    book_names = sorted(n for n in tracked if re.fullmatch(r'docs/book/src/[^/]+\.md', n))
    tasks = {n: Path(n).read_bytes() for n in task_names}
    books = {n: Path(n).read_bytes() for n in book_names}
    verify.need(sorted(str(p) for pattern in ('docs/tasks/*.md', 'docs/tasks/segments/*/*.md')
                       for p in Path('.').glob(pattern)) == task_names, 'complete current task collection membership')
    tasks[verify.TASK] = task
    registry = before[verify.REGISTRY]
    verify.need(registry == verify.git('show', verify.REVISION + ':' + verify.REGISTRY), 'whole unchanged prior authority')
    rows = [json.loads(line) for line in registry.splitlines()]
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            measured = metrics(tasks)
            verify.need(measured['lines_each'] < 7200, 'bounded full raw parent task evidence')
            for k, value in measured.items():
                verify.need(value <= row['enforcement_ceilings'][k], 'unchanged task ceiling')
                row['transition']['max_growth'][k] = max(0, value + row['transition']['ratchet_step'][k] - row['baseline'][k])
        elif row.get('surface_id') == 'shipped_behavior':
            keys = ('files', 'bytes_total', 'lines_total')
            baseline = metrics(books)
            books[verify.BOOK] = book_after
            measured = metrics(books)
            row['reference_contract']['aggregate_change'] = dict(
                authority_id='RAW-SEMANTIC-PARENT-ACCEPTANCE-20261011', owner=verify.OWNER,
                baseline={k: baseline[k] for k in keys}, delta={k: measured[k] - baseline[k] for k in keys},
                rationale='Replace only the owned raw semantic status and date the earlier association checkpoint. Canonical raw publication and all original native/private gaps remain open; no ceilings widen.')
    registry_after = b''.join(canonical(row) for row in rows)
    memory = before['MEMORY.md'].decode()
    verify.need(memory.count(verify.OWNER + '` (active)') == 1, 'exact current raw acceptance resume pointer')
    memory = memory.replace(verify.OWNER + '` (active)', verify.RAW + '.5.3` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate governed complete raw canonical publication .5.3 from clean committed parent acceptance. Preserve every original fact/question/probe and source/native uncertainty through non-growing publication; higher cause/consumer/alias/cold/permanent/native/HIAL/full-CI/push scopes retain.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after parent acceptance delivery and commit; derive new gate state under docs/audits/raw-semantic-parent-closure-20261011.', memory, flags=re.M)
    index = before['docs/TASK_TREE.md'].decode()
    marker = 'stream recovery committed; full raw-parent acceptance active.'
    verify.need(index.count(marker) == 1, 'exact active raw parent frontier index')
    after = {verify.TASK: task, verify.BOOK: book_after, verify.REGISTRY: registry_after,
             'MEMORY.md': memory.encode(), 'docs/TASK_TREE.md': index.replace(marker, 'full raw semantic acceptance done; canonical raw publication next.', 1).encode()}
    verify.need(not (BASE / 'publication.json').exists() and all(not (BASE / (role + '-' + str(i) + '.gz')).exists()
                 for role in ('before', 'after') for i in range(len(names))), 'all fresh publication targets preflight before writes')
    snapshots = {}
    for i, name in enumerate(names):
        snapshots[name] = {}
        for role, raw in (('before', before[name]), ('after', after[name])):
            path = BASE / (role + '-' + str(i) + '.gz')
            path.write_bytes(gzip.compress(raw, mtime=0))
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(raw))
    save('publication.json', dict(owner=verify.OWNER, snapshots=snapshots, task_names=task_names,
                                book_names=book_names, old_notice=old_notice.decode(), notice=NOTICE.decode(),
                                old_association=OLD_ASSOCIATION.decode(), association=ASSOCIATION.decode()))
    verify.need(all(Path(name).read_bytes() == raw for name, raw in before.items()), 'whole unchanged publication inputs at final write boundary')
    for name, raw in after.items():
        Path(name).write_bytes(raw)
    print('Prepared only complete original raw semantic acceptance; canonical and higher native/private scopes remain open.')


if __name__ == '__main__':
    main()
