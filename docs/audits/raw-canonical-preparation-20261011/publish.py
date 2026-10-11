"""Close only source preparation and publish its bounded reader guidance."""
import ast
import gzip
import json
from pathlib import Path
import re

from capture import BASE, canonical, pin, save
import verify

NOTICE = (b'Raw semantic acceptance joins original readers, source custody, nested causes\n'
          b'and controls. Fixed-source replay preserves the accepted source epoch.\n'
          b'Recovery refuses unsafe paths/conflicts. Earlier failures, unknown interrupted\n'
          b'peak RSS/first launch diagnostic retain. Native/private and canonical stay open.\n\n')


def main():
    owner = verify.PLAN['owner']
    names = (verify.TASK, verify.BOOK, verify.REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md')
    before = {n: Path(n).read_bytes() for n in names}
    planned = verify.read('candidate.json')
    verify.need(planned == verify.candidate()
                and Path(planned['target']).read_bytes() == planned['before'].encode(),
                'whole unchanged current canonical candidate and capacity preflight')
    factory = 'scripts/check_record_value_publication.py'
    verify.need(Path(factory).read_bytes() == verify.checkpoint.git('show', verify.PLAN['revision'] + ':' + factory),
                'maintained producer has not advanced before source preparation commits')
    task = before[verify.TASK]
    block = verify.nodes(task)[owner]
    verify.need(verify.field(block, 'Status') == 'active', 'only exact active preparation leaf closes')
    evidence = ('Complete original raw/container and descendant Goal/Acceptance contracts conserve. '
        'The unchanged complete semantic parent passes in an ordinary same-volume checkpoint derived solely from its committed '
        'Git source and full direct gate/publication dependencies. The original e428 prerequisite source condition and complete '
        'later committed archive retain, without implying new current-programme or original native/private measurements. '
        'Actual Git-only reconstruction succeeds with the earlier ignored view absent; all restored/retained file/directory/mode/body '
        'censuses conserve. Whole first import, missing gate dependency and outer recorder failures retain; absent outer guard terminals '
        'remain explicitly unmeasured. Gate-prefixed replay records actual0 independently. Genuine omitted-source/obligation and Boolean '
        'terminal controls refuse. The exact candidate preserves all fact/question/evidence/probe bytes and old meanings/uncertainty, '
        'fits unchanged capacity authority and remains unpublished. Distinct claim legs are whole fixed Git/source and unchanged actual '
        'parent re-derivation, separating whole-join and inherited semantic/context/recovery falsification, and committed complete native/'
        'source/first-failure custody with actual reconstruction. Focused/book/native/size/claim/inventory/staged/normal gates accompany '
        'this commit. Only preparation closes; canonical publication and full raw/higher owners remain open.')
    final = block.replace(b'  Status: `active`\n', b'  Status: `done`\n', 1)
    final = final.replace(b'  Verification: `pending`', ('  Verification: `' + evidence + '`').encode(), 1)
    final = final.replace(b'  Commit: `pending`', ('  Commit: `' + owner + ': qualify raw canonical source preparation`').encode(), 1)
    final = final.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S locates the original strict source intake; first unchanged parent actual1 names intake.py13 and the missing public recovery helper. The second actual1 names verify.py91 and missing focused gate input. Both establish why all direct committed gate dependencies must enter the source checkpoint before maintained producer advancement.\n'
        '  - [x] **ADDRESSED (verified)** — Complete Git-derived source selection, actual unchanged full parent checkpoint and real reconstruction with its earlier ignored view absent pass. Every original raw obligation and e428/later archive role retains; omitted source/obligation and Boolean terminal interventions reject. Canonical candidate preflights without changing a production fact or widening capacity.\n'
        '  - [x] **NO REGRESSION** — All tests successful in the focused gate; current book/native copied-source, size, claim/inventory, committed-only preparation, staged scripts/check_doctrines.sh and normal hooks gate delivery. First failures and all native/private uncertainties retain.\n\n').encode()
    task = task.replace(block, final, 1)
    syntax = ast.parse(Path(verify.PLAN['raw_parent'] + '/publish.py').read_bytes())
    old = next(ast.literal_eval(n.value) for n in syntax.body if isinstance(n, ast.Assign)
               and any(isinstance(t, ast.Name) and t.id == 'NOTICE' for t in n.targets))
    verify.need(before[verify.BOOK].count(old) == 1, 'unique own accepted raw notice')
    book = before[verify.BOOK].replace(old, NOTICE, 1)
    verify.need(len(book) <= 292485, 'unchanged current chapter allowance')
    source_names = verify.checkpoint.git('ls-tree', '-r', '--name-only', verify.PLAN['revision']).decode().splitlines()
    task_names = sorted(n for n in source_names if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', n))
    book_names = sorted(n for n in source_names if re.fullmatch(r'docs/book/src/[^/]+\.md', n))
    tasks = {n: Path(n).read_bytes() for n in task_names}
    books = {n: Path(n).read_bytes() for n in book_names}
    tasks[verify.TASK] = task
    previous = verify.metrics(books)
    books[verify.BOOK] = book
    measured = verify.metrics(books)
    rows = list(map(json.loads, before[verify.REGISTRY].splitlines()))
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            for key, value in verify.metrics(tasks).items():
                verify.need(value <= row['enforcement_ceilings'][key], 'unchanged task ceiling')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(
                authority_id='RAW-CANONICAL-SOURCE-PREPARATION-20261011', owner=owner,
                baseline={k: previous[k] for k in keys}, delta={k: measured[k] - previous[k] for k in keys},
                rationale='Replace only the owned raw status with its accepted fixed-source checkpoint boundary; canonical and native/private scopes stay open. No ceilings widen.')
    memory = before['MEMORY.md'].decode()
    verify.need(memory.count(owner + '` (active)') == 1, 'exact active preparation pointer')
    memory = memory.replace(owner + '` (active)', verify.PLAN['parent'] + '.2` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate raw canonical publication .5.3.2 from clean committed source preparation. Extend only the governed finite raw meaning and maintained factory within unchanged capacity; preserve original e428/parent source conditions through the complete committed checkpoint. Full raw acceptance .5.3.3 follows its commit.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after source preparation delivery and commit; derive new qualification state under docs/audits/raw-canonical-preparation-20261011.', memory, flags=re.M)
    index = before['docs/TASK_TREE.md']
    marker = b'raw canonical preparation active.'
    verify.need(index.count(marker) == 1, 'exact owned preparation frontier')
    after = {verify.TASK: task, verify.BOOK: book, verify.REGISTRY: b''.join(canonical(r) for r in rows),
             'MEMORY.md': memory.encode(), 'docs/TASK_TREE.md': index.replace(marker, b'raw source checkpoint done.', 1)}
    snapshots = {}
    verify.need(not (BASE / 'publication.json').exists(), 'fresh preparation publication receipt')
    for i, name in enumerate(names):
        snapshots[name] = {}
        for role, body in (('before', before[name]), ('after', after[name])):
            path = BASE / ('publication-' + role + '-' + str(i) + '.gz')
            verify.need(not path.exists(), 'fresh publication snapshot')
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    # All routes and transformations are preflighted before the first live write.
    for name in names:
        for role in ('before', 'after'):
            Path(snapshots[name][role]['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=owner, snapshots=snapshots, old_notice=old.decode(), notice=NOTICE.decode(),
                                task_names=task_names, book_names=book_names))
    verify.need(all(Path(n).read_bytes() == raw for n, raw in before.items()), 'complete unchanged live publication inputs')
    for name, raw in after.items():
        Path(name).write_bytes(raw)
    print('Prepared raw source checkpoint status only; production canonical publication remains open.')


if __name__ == '__main__':
    main()
