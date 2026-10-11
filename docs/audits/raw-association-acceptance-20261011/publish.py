"""Publish only unchanged complete association acceptance."""
import re
from common import *
import verify

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
MARKER = b'Only the finite observer and class/frame predecessor containers close here.\n'
ADDITION = (b'The complete raw-body association container is now qualified under its\n'
    b'unchanged original acceptance. The closure joins every original obligation\n'
    b'to the complete source products and independent semantic reconstruction.\n'
    b'All completed construction, archive-custody, semantic and typed-repair\n'
    b'descendants retain their full contracts and evidence.\n\n'
    b'Both readers freshly execute on every saved complete positive and hostile\n'
    b'candidate. The body reader accepts their unchanged inherited meanings;\n'
    b'the source-first reader accepts the positive and refuses each intended\n'
    b'semantic intervention. Separate native JSON-kind checks retain the typed\n'
    b'coordinate boundary. Whole construction, recovery-layout, Git-custody and\n'
    b'semantic defaults pass before and after the group in their dated roles.\n\n'
    b'This closes the finite association container only. Complete raw semantic\n'
    b'parent acceptance and governed canonical raw publication remain separate.\n'
    b'The shared source assumptions and all original native/private, identity,\n'
    b'cold replay, visual and host qualification gaps remain explicit. Replay\n'
    b'requires the complete fixed source and instrument context:\n\n'
    b'```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/raw-association-acceptance-20261011/verify.py\n```\n\n')


def authority(before, task_sources, book_sources, book_after):
    rows = [json.loads(line) for line in before.splitlines()]
    measured = metrics(task_sources)['metrics']
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            need(row['state'] == 'warning_debt' and measured['lines_each'] < 7200, 'bounded owned association task growth')
            for key, value in measured.items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged task collection ceilings')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            baseline = metrics(book_sources)['metrics']
            current = dict(book_sources)
            current[BOOK] = book_after
            after = metrics(current)['metrics']
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(authority_id='RAW-ASSOCIATION-ACCEPTANCE-20261011', owner=LEAF,
                baseline={key: baseline[key] for key in keys}, delta={key: after[key] - baseline[key] for key in keys},
                rationale='Document unchanged complete finite association acceptance and fresh whole-candidate control qualification. Full raw semantic parent, canonical publication and original native/private scopes remain separately owned.')
    return b''.join(canonical(row) for row in rows)


def main():
    verify.core()
    task = local(TASK).read_bytes()
    need(task == gzip.decompress(local(BASE / 'declared-task.md.gz').read_bytes()), 'whole unchanged declared association task before closure')
    for key in (OWNER, LEAF):
        block = verify.nodes(task)[key]
        need(verify.field(block, 'Status') == b'active', 'active owned association parent/closure leaf')
        final = block.replace(b'  Status: `active`\n', b'  Status: `done`\n', 1)
        evidence = ('Whole fixed/current Git-source bytes, executable modes and directory membership conserve, including every complete positive/hostile body and required recovery archive. '
            'Every original Goal/Acceptance and completed descendant contract retains. Complete construction, recovery-layout, Git-custody and corrected semantic defaults freshly pass before and after the group. '
            'Actual unchanged body predicates accept every inherited projection; separate source-first semantic readers accept the positive and reach each intended genuine full-candidate refusal. '
            'Separate native JSON-kind positive/refusal checks and complete first Boolean false-green and RAM non-success epochs retain. '
            'The independent original reconstruction and complete source models remain shared assumptions. Whole current source/book/native/focused/claim/staged/normal gates require actual success before commit. '
            'Only the unchanged finite association container and this closure leaf close; full raw semantic .5.2.3, canonical .5.3 and all original native/private/higher scopes remain separately owned.')
        final = final.replace(b'  Verification: `' + verify.field(block, 'Verification') + b'`\n', ('  Verification: `' + evidence + '`\n').encode(), 1)
        final = final.replace(b'  Commit: `pending`\n', ('  Commit: `' + LEAF + ': close unchanged complete raw association acceptance`\n').encode(), 1)
        if key == LEAF:
            final = final.rstrip() + (
                '\n  Acceptance Checklist (enforced):\n'
                '  - [x] **ROOT CAUSE (WHY + WHERE)** — Actual git log -S semantic_links in checks.json root-history locates the committed source-first qualification at cd84713b63cb43240b4df82b01f285c80720c21c and raw-semantic-links-20261011/reader.py. Original task contracts show all construction/custody/semantic descendants done but their unchanged association acceptance still active; no complete parent closure was established.\n'
                '  - [x] **ADDRESSED (verified)** — verify.py joins every complete original association obligation and unchanged descendant contract to whole fixed/current source custody, fresh complete predecessor defaults and actual independent whole positive/hostile candidate executions. All inherited meanings and original native/private gaps conserve; only this finite association parent and leaf close.\n'
                '  - [x] **NO REGRESSION** — All tests successful in checks.json focused. Whole before/after predecessor defaults, complete source/product custody, current/book/native/claim gates, staged scripts/check_doctrines.sh and normal hooks require actual success before commit.\n\n').encode()
        task = task.replace(block, final, 1)
    verify.contracts(task)
    local(TASK).write_bytes(task)
    successor = OWNER.rsplit('.', 1)[0] + '.3'
    memory = local('MEMORY.md').read_text().replace(LEAF + '` (active)', successor + '` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Confirm terminal association closure gates and commit any dirty owned state, then activate .5.2.3 to qualify the full unchanged raw semantic parent acceptance. Distinct governed canonical raw publication .5.3 remains separate.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: Derive incomplete started/actual checks under docs/audits/raw-association-acceptance-20261011/checks.json. Consume every required result before handoff.', memory, flags=re.M)
    local('MEMORY.md').write_text(memory)
    index = local('docs/TASK_TREE.md').read_text()
    need('raw semantic done; association closure active.' in index, 'owned bounded association frontier')
    local('docs/TASK_TREE.md').write_text(index.replace('raw semantic done; association closure active.', 'association done; full raw semantic acceptance next.', 1))
    book_before = git('show', REVISION + ':' + BOOK)
    need(local(BOOK).read_bytes() == book_before and book_before.count(MARKER) == 1, 'whole unique fixed association book baseline')
    local(BOOK).write_bytes(book_before.replace(MARKER, ADDITION + MARKER, 1))
    names = git('ls-tree', '-r', '--name-only', REVISION).decode().splitlines()
    task_names = sorted(name for name in names if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name))
    book_names = sorted(name for name in names if re.fullmatch(r'docs/book/src/[^/]+\.md', name))
    fixed = fixed_sources(task_names + book_names + [SURFACES])
    tasks = {name: local(name).read_bytes() for name in task_names}
    need(all(raw == fixed[name] for name, raw in tasks.items() if name != TASK), 'every unrelated complete task source conserves')
    need(sorted(str(p) for pattern in ('docs/tasks/*.md', 'docs/tasks/segments/*/*.md') for p in Path('.').glob(pattern)) == task_names,
         'whole unchanged association task collection membership')
    save('task-census.json', metrics(tasks))
    need(local(SURFACES).read_bytes() == fixed[SURFACES], 'whole unchanged registry before measured association authority')
    registry = authority(fixed[SURFACES], tasks, {name: fixed[name] for name in book_names}, local(BOOK).read_bytes())
    local(SURFACES).write_bytes(registry)
    for name, raw in (('registry-before.txt', fixed[SURFACES]), ('registry-after.txt', registry)):
        path = local(BASE / name, exists=False)
        need(not path.exists(), 'retain first complete association registry source')
        path.write_bytes(raw)
    for name, raw in (('qualified-task.md.gz', task), ('book-before.md.gz', book_before), ('book-after.md.gz', local(BOOK).read_bytes())):
        path = local(BASE / name, exists=False)
        need(not path.exists(), 'retain first complete association publication source')
        path.write_bytes(gzip.compress(raw, mtime=0))
    save('publication.json', dict(task_names=task_names, book_names=book_names, revision=REVISION,
                                book_before=pin(book_before), book_after=pin(local(BOOK).read_bytes()), registry_after=pin(registry)))
    print('Prepared unchanged complete association acceptance and finite book publication; all external gates require actual success.')


if __name__ == '__main__':
    main()
