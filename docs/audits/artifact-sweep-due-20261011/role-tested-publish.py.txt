"""Publish the dated cleanup guidance and close only its owning leaf."""
import gzip
import json
from pathlib import Path
import re
import subprocess

from capture import BASE, canonical, pin, save

PLAN = json.loads((BASE / 'plan.json').read_bytes())
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
BOOK = 'docs/book/src/09-generated-hdl-debugging-and-inspection.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
OLD = '''A sweep may retain every candidate when disposal has not been proved. Its
dated census records node metadata and independent file membership; it does
not establish artifact byte identity or future absence. Replay a saved example:

```sh
python3 -B docs/audits/artifact-sweep-due-20261010/verify.py
```
'''
NEW = '''A sweep retains candidates without disposal authority. Its ordinary census
records dated node metadata and independent file membership; it does not prove
artifact byte identity or future absence. Duplicate Git-source checkpoints need
separate complete source, byte, mode, member and immediate node checks before
removal. Original evidence and the current book remain protected. Verify a saved
cleanup without repeating deletion:

```sh
python3 -B docs/audits/artifact-sweep-due-20261011/verify.py
```

Legitimate replay can reconstruct a removed checkpoint from committed Git
source. This example recreates the raw preparation view and runs its unchanged
dated parent verifier; it creates project-local generated data:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/raw-canonical-preparation-20261011/restore.py
```
'''


def need(value, message):
    if not value:
        raise ValueError(message)


def metrics(sources):
    rows = [dict(bytes=len(raw), lines=raw.count(b'\n'), width=max(map(len, raw.splitlines()), default=0))
            for raw in sources.values()]
    return dict(files=len(rows), bytes_total=sum(r['bytes'] for r in rows), lines_total=sum(r['lines'] for r in rows),
                bytes_each=max(r['bytes'] for r in rows), lines_each=max(r['lines'] for r in rows),
                line_bytes_each=max(r['width'] for r in rows))


def main():
    names = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md', 'docs/ARTIFACT_CLEANUP.md')
    before = {name: Path(name).read_bytes() for name in names}
    need(before[BOOK].count(OLD.encode()) == 1, 'unique complete owned cleanup guidance')
    owner = PLAN['owner']
    task = before[TASK].decode()
    start = task.index('- ID: `' + owner + '`\n')
    end = task.index('\n## Version-Retrievable Historical Views', start)
    block = task[start:end]
    need(block.count('  Status: `active`\n') == 1 and block.count('  Verification: `pending`') == 1,
         'exact active cleanup frontier')
    evidence = ('Complete due-date Git history, ordinary artifact/Rust census and independent membership retain. '
        'Four explicitly selected untracked duplicate source checkpoints authenticate against their complete fixed Git '
        'graphs, whole byte/mode/file/directory populations, unshared same-volume nodes and immediate descriptor identities '
        'before exact removal. Original preparation/publication archives and current book bytes conserve through deletion; '
        'all other ordinary artifact identities retain. Per-copy completed outcomes and dated empty residue retain. '
        'Actual current canonical core passes with every selected ignored checkpoint absent. The saved reader repeats no '
        'deletion and rederives fixed Git authority, typed outcomes, complete membership and custody. Actual protected-path, '
        'omitted-member and changed-whole-byte controls reject before deletion; saved independent protected/member/Boolean '
        'controls reject. Distinct claim legs: whole fixed-source/node/native rederivation, genuine separating authority '
        'interventions, and committed complete classification/source/native/custody records. Logical sizes are not physical '
        'disk reclamation measurements; dated residue is not a future absence promise. Latest-only record and book explain '
        'the saved reader and tested Git-only reconstruction. Focused/book/size/claim/inventory/staged/normal gates accompany '
        'commit. Only daily cleanup closes; unchanged full raw acceptance .5.3.3 resumes from clean state.')
    block = block.replace('  Status: `active`\n', '  Status: `done`\n', 1)
    block = block.replace('  Verification: `pending`', '  Verification: `' + evidence + '`', 1)
    block = block.replace('  Commit: `pending`', '  Commit: `' + owner + ': remove authenticated duplicate checkpoints`', 1)
    block = block.rstrip() + (
        '\n  Acceptance Checklist (enforced):\n'
        '  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S 2026-10-10T15:51:37 identifies the committed prior cleanup in root-history. Its whole record and actual UTC establish the due interval. Ordinary artifact metadata alone cannot authorize deletion; the fixed explicit checkpoint copies require complete Git-byte/member/mode and immediate-node authority.\n'
        '  - [x] **ADDRESSED (verified)** — Actual gate-cleanup native0 records exact qualified duplicate removal, dated empty residue, protected original/native/book bytes and conservation of every other ordinary candidate. Actual gate-post-core native0 passes the unchanged current canonical core with all selected ignored views absent. Complete saved authority and genuine controls verify without repeating deletion.\n'
        '  - [x] **NO REGRESSION** — All tests successful in the focused task/claim/book gate. Saved source/authority and exact publication readers, mdBook build, unchanged ceiling and canonical allowances, claim/inventory, staged scripts/check_doctrines.sh and normal hooks gate commit before unchanged raw acceptance resumes. Complete actual commands, source epochs and terminal streams retain.\n\n')
    task = (task[:start] + block + task[end:]).encode()
    book = before[BOOK].replace(OLD.encode(), NEW.encode(), 1)
    selected = subprocess.check_output(['git', '--no-replace-objects', 'ls-tree', '-r', '--name-only', PLAN['revision']]).decode().splitlines()
    task_names = sorted(n for n in selected if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', n))
    book_names = sorted(n for n in selected if re.fullmatch(r'docs/book/src/[^/]+\.md', n))
    tasks, books = ({name: Path(name).read_bytes() for name in group} for group in (task_names, book_names))
    old_book = metrics(books)
    tasks[TASK], books[BOOK] = task, book
    task_metrics, book_metrics = metrics(tasks), metrics(books)
    rows = list(map(json.loads, before[REGISTRY].splitlines()))
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            for key, value in task_metrics.items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged task ceiling')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(authority_id='ARTIFACT-SWEEP-DUE-20261011', owner=owner,
                baseline={k: old_book[k] for k in keys}, delta={k: book_metrics[k] - old_book[k] for k in keys},
                rationale='Explain separately authenticated duplicate checkpoint disposal, saved no-deletion verification and tested Git-source reconstruction. Only cleanup guidance changes; ceilings and Knowledge Map allowances retain.')
    memory = before['MEMORY.md'].decode()
    need(memory.count(owner + '` (active)') == 1, 'exact active cleanup pointer')
    memory = memory.replace(owner + '` (active)', PLAN['resume'] + '` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Activate unchanged complete raw acceptance .5.3.3 from clean committed daily cleanup. Join every original raw/container/descendant obligation with complete fixed-source/native/current canonical and separating control evidence before closing only full raw owners; all higher scopes retain.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: None after daily cleanup verification and commit; derive later gate state under docs/audits/artifact-sweep-due-20261011.', memory, flags=re.M)
    marker = b'daily cleanup .84 active.'
    need(before['docs/TASK_TREE.md'].count(marker) == 1, 'unique cleanup frontier marker')
    after = {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows), 'MEMORY.md': memory.encode(),
             'docs/TASK_TREE.md': before['docs/TASK_TREE.md'].replace(marker, b'cleanup .84 done; raw .5.3.3 next.', 1),
             'docs/ARTIFACT_CLEANUP.md': before['docs/ARTIFACT_CLEANUP.md']}
    need(max(map(len, after['docs/TASK_TREE.md'].splitlines())) <= 862, 'unchanged bounded index line width')
    snapshots = {}
    need(not (BASE / 'publication.json').exists(), 'fresh cleanup publication')
    for i, name in enumerate(names):
        snapshots[name] = {}
        for role, body in (('before', before[name]), ('after', after[name])):
            path = BASE / ('publication-' + role + '-' + str(i) + '.gz')
            need(not path.exists(), 'all publication targets preflight before writes')
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    for name in names:
        for role in ('before', 'after'):
            Path(snapshots[name][role]['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('publication.json', dict(owner=owner, snapshots=snapshots, old_guide=OLD, guide=NEW,
        task_names=task_names, book_names=book_names, task_metrics=task_metrics, book_before=old_book, book_after=book_metrics))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'unchanged whole cleanup publication inputs')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published dated cleanup guidance and closed only daily cleanup; unchanged full raw acceptance remains next.')


if __name__ == '__main__':
    main()
