"""Close only exact archive Git custody before independent semantic work."""
import re
from common import *
import verify

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
MARKER = b'Only the finite observer and class/frame predecessor containers close here.\n'
ADDITION = (b'The required recovery archive is explicitly tracked in Git. The custody gate\n'
    b'compares every complete construction and repair member, executable mode,\n'
    b'directory and whole staged blob with source bytes. Its default freshly checks\n'
    b'current Git custody; complete semantic and original native/private meanings\n'
    b'remain open:\n\n'
    b'```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/raw-semantic-archive-durability-20261011/verify.py\n```\n\n')


def authority(before, task_sources, book_sources, book_after):
    rows = [json.loads(line) for line in before.splitlines()]
    measured = metrics(task_sources)['metrics']
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            need(row['state'] == 'warning_debt' and measured['lines_each'] < 7200, 'bounded owned task growth before rollover')
            for key, value in measured.items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged task ceilings')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            baseline = metrics(book_sources)['metrics']
            current = dict(book_sources)
            current[BOOK] = book_after
            after = metrics(current)['metrics']
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(authority_id='RAW-SEMANTIC-ARCHIVE-CUSTODY-20261011', owner=OWNER,
                baseline={key: baseline[key] for key in keys}, delta={key: after[key] - baseline[key] for key in keys},
                rationale='Document exact required archive tracking and independent complete staged Git/source custody. Complete semantic independence and original native/private scopes remain open.')
    return b''.join(canonical(row) for row in rows)


def main():
    verify.core()
    actual = load('checks.json')['git-custody-before-final']
    locus = re.search(r' at [^\s]+ line [0-9]+', actual['stderr'])
    need(locus is not None, 'actual native missing-member diagnostic locus')
    task = local(TASK).read_bytes()
    graph = verify.nodes(task)
    block = graph[OWNER]
    need(verify.field(block, 'Status') == b'active', 'active required-archive custody leaf')
    final = block.replace(b'  Status: `active`\n', b'  Status: `done`\n', 1)
    text = ('Actual missing archived Git member and ZIP ignore reproduce before correction. Exact authenticated ZIP is force-added; '
        'separate native complete filesystem/index/whole-blob/mode/directory census and Python fixed/current source equality qualify every '
        'construction/repair member. Both complete sealed defaults freshly execute in proper roles; original programmes, source/native/products '
        'and every Goal/Acceptance clause conserve. Current default freshly reruns complete Git custody. Current/book/native/focused/claim/staged/normal '
        'gates require actual success before commit; complete semantic and original native/private scopes remain open.')
    final = final.replace(b'  Verification: `pending`\n', ('  Verification: `' + text + '`\n').encode(), 1)
    final = final.replace(b'  Commit: `pending`\n', ('  Commit: `' + OWNER + ': track complete authenticated recovery archive`\n').encode(), 1)
    final = final.rstrip() + (f'\n  Acceptance Checklist (enforced):\n'
        f'  - [x] **ROOT CAUSE (WHY + WHERE)** — Actual required archived member is absent from Git index{locus[0]}; checks.json git-custody-before-final retains complete programmes, command and both streams. before-gap.json retains the actual ZIP ignore and post-commit absence, explaining why a clean status alone missed required durability.\n'
        '  - [x] **ADDRESSED (verified)** — Force-add only the complete authenticated first-epoch.zip. Separate native whole index/blob/source/mode/directory census, Python whole fixed/current custody and fresh complete construction/layout defaults qualify; every original acceptance and native/private gap conserves.\n'
        '  - [x] **NO REGRESSION** — All tests successful in checks.json focused; complete sealed source defaults, fresh current Git custody, current/book/native/claim/staged scripts/check_doctrines.sh and normal hooks require actual success before commit.\n\n').encode()
    task = task.replace(block, final, 1)
    parent = OWNER.rsplit('.', 1)[0]
    block = verify.nodes(task)[parent]
    need(verify.field(block, 'Status') == b'active', 'construction parent reopened solely for required custody')
    final = block.replace(b'  Status: `active`\n', b'  Status: `done`\n', 1)
    old_verification = verify.field(final, 'Verification')
    new_verification = old_verification + b' Complete exact recovery ZIP tracking and independent whole Git/source custody also qualify under .1.1; complete semantic reconstruction remains .5.2.2.2.'
    final = final.replace(b'  Verification: `' + old_verification + b'`', b'  Verification: `' + new_verification + b'`', 1)
    gap = verify.field(final, 'Durability gap')
    final = final.replace(b'  Durability gap: `' + gap + b'`', b'  Durability gap: `' + gap + b' Closed by complete .1.1 custody qualification; the first missing-member result is retained.`', 1)
    task = task.replace(block, final, 1)
    local(TASK).write_bytes(task)
    verify.contracts(task)
    successor = parent.rsplit('.', 1)[0] + '.2'
    memory = local('MEMORY.md').read_text().replace(OWNER + '` (active)', successor + '` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Confirm terminal required-archive custody checks and commit any dirty owned state, then activate .5.2.2.2. Follow docs/audits/raw-semantic-archive-durability-20261011/semantic-successor-plan.json for complete independent semantic links and genuine prior-preserving controls; original native/private scopes stay open.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: Derive incomplete started/actual checks under docs/audits/raw-semantic-archive-durability-20261011/checks.json. Consume every required result before handoff.', memory, flags=re.M)
    local('MEMORY.md').write_text(memory)
    index = local('docs/TASK_TREE.md').read_text()
    need('raw admitted; archive tracking repair.' in index, 'owned bounded custody frontier')
    local('docs/TASK_TREE.md').write_text(index.replace('raw admitted; archive tracking repair.', 'raw admitted; candidates done; semantic check next.', 1))
    book_before = git('show', REVISION + ':' + BOOK)
    need(local(BOOK).read_bytes() == book_before and book_before.count(MARKER) == 1, 'whole unique fixed custody publication baseline')
    local(BOOK).write_bytes(book_before.replace(MARKER, ADDITION + MARKER, 1))
    names = git('ls-tree', '-r', '--name-only', REVISION).decode().splitlines()
    task_names = sorted(name for name in names if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name))
    book_names = sorted(name for name in names if re.fullmatch(r'docs/book/src/[^/]+\.md', name))
    fixed = fixed_sources(task_names + book_names + [SURFACES])
    tasks = {name: local(name).read_bytes() for name in task_names}
    need(all(raw == fixed[name] for name, raw in tasks.items() if name != TASK), 'every unrelated task source conserves')
    need(sorted(str(p) for pattern in ('docs/tasks/*.md', 'docs/tasks/segments/*/*.md') for p in Path('.').glob(pattern)) == task_names,
         'whole unchanged task collection membership')
    save('task-census.json', metrics(tasks))
    need(local(SURFACES).read_bytes() == fixed[SURFACES], 'whole unchanged registry before measured custody authority')
    registry = authority(fixed[SURFACES], tasks, {name: fixed[name] for name in book_names}, local(BOOK).read_bytes())
    local(SURFACES).write_bytes(registry)
    for name, raw in (('registry-before.txt', fixed[SURFACES]), ('registry-after.txt', registry)):
        path = local(BASE / name, exists=False)
        need(not path.exists(), 'retain first complete custody registry source')
        path.write_bytes(raw)
    for name, raw in (('qualified-task.md.gz', task), ('book-before.md.gz', book_before), ('book-after.md.gz', local(BOOK).read_bytes())):
        path = local(BASE / name, exists=False)
        need(not path.exists(), 'retain first complete custody publication source')
        path.write_bytes(gzip.compress(raw, mtime=0))
    save('publication.json', dict(task_names=task_names, book_names=book_names, revision=REVISION,
                                book_before=pin(book_before), book_after=pin(local(BOOK).read_bytes()), registry_after=pin(registry)))
    print('Prepared complete required-archive custody publication and unchanged original acceptance; all external gates require actual success.')


if __name__ == '__main__':
    main()

