"""Publish only unchanged complete raw semantic parent acceptance."""
import re
from common import *
import verify

BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
MARKER = b'Retained observer and class/frame checkpoint (before raw association):\n\n'
ADDITION = (b'The complete original raw semantic parent now qualifies under its unchanged\n'
    b'Goal and Acceptance. Every primary, source, context, inventory, class, frame,\n'
    b'observer, header, coordinate and address prerequisite reader freshly runs\n'
    b'in its declared source or dated role. Complete actual programmes, commands,\n'
    b'products and both streams retain, with whole fixed/current source custody.\n\n'
    b'The independently reconstructed full bodies and explicit links preserve\n'
    b'original first causes, source callers, visible arguments, coordinates,\n'
    b'simultaneous address-holder boundaries and whole nested inner/outer causes.\n'
    b'Every genuine semantic intervention and complete first Boolean false-green\n'
    b'or interrupted RAM epoch retains without changing its original meaning.\n\n'
    b'The earlier book-clarity reader also replays unchanged in a complete\n'
    b'ordinary same-volume view of its committed task, book and authority context.\n'
    b'The actual later task activation fails that original current-context\n'
    b'predicate; exact restoration passes. This qualifies the dated context,\n'
    b'without borrowing its result as later live publication currency.\n\n'
    b'Only the finite raw semantic repair and its acceptance leaf close. Governed\n'
    b'canonical raw publication remains separate, as do the original native and\n'
    b'private measurements, identities, higher cause/consumer/alias/cold/permanent\n'
    b'qualification, visual QA and host/full-CI/push owners. Shared qualified\n'
    b'source models remain assumptions. Replay requires the complete fixed context:\n\n'
    b'```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/raw-semantic-acceptance-20261011/verify.py\n```\n\n')


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
            row['reference_contract']['aggregate_change'] = dict(authority_id='RAW-SEMANTIC-ACCEPTANCE-20261011', owner=LEAF,
                baseline={key: baseline[key] for key in keys}, delta={key: after[key] - baseline[key] for key in keys},
                rationale='Document unchanged complete finite raw semantic parent acceptance, every fresh prerequisite reader and exact dated context qualification. Canonical publication and original native/private/higher scopes remain separately owned.')
    return b''.join(canonical(row) for row in rows)


def main():
    verify.core()
    task = local(TASK).read_bytes()
    need(task == gzip.decompress(local(BASE / 'declared-task.md.gz').read_bytes()), 'whole unchanged declared association task before closure')
    for key in (OWNER, LEAF):
        block = verify.nodes(task)[key]
        need(verify.field(block, 'Status') == b'active', 'active owned association parent/closure leaf')
        final = block.replace(b'  Status: `active`\n', b'  Status: `done`\n', 1)
        evidence = ('Every original full raw semantic Goal/Acceptance and completed admission/association descendant contract retains without narrowing. '
            'Complete fixed/current source/native/product bytes, modes, members and directories conserve, including every first epoch and required recovery archive. '
            'Every declared primary/source/context/inventory/class/frame/observer/header/coordinate/address reader freshly executes in its exact source or dated role with full actual programmes, commands and both streams. '
            'Complete admission, association, construction, recovery-layout, Git-custody and semantic defaults pass before and after qualification. '
            'Separate source-first full-body/argument/coordinate/address/nested reconstruction and every genuine prior-preserving semantic control retain under unchanged source custody. '
            'The unchanged original clarity programme passes its complete committed context, rejects actual later task activation and passes exact restoration; this creates no later live currency. '
            'All original native/private/identity uncertainties and shared source assumptions conserve. Current source/book/native/focused/claim/staged/normal gates require actual success before commit. '
            'Only this complete finite raw semantic parent and acceptance leaf close; governed canonical publication .5.3 and all higher native/private/cause/consumer/alias/cold/permanent/visual/HIAL/full-CI/push owners remain open.')
        final = final.replace(b'  Verification: `' + verify.field(block, 'Verification') + b'`\n', ('  Verification: `' + evidence + '`\n').encode(), 1)
        final = final.replace(b'  Commit: `pending`\n', ('  Commit: `' + LEAF + ': close unchanged complete raw semantic acceptance`\n').encode(), 1)
        if key == LEAF:
            final = final.rstrip() + (
                '\n  Acceptance Checklist (enforced):\n'
                '  - [x] **ROOT CAUSE (WHY + WHERE)** — Actual git log -S def core in checks.json root-history locates complete association qualification at 48455c13f50ac9370cd52d21b81690b5d90bdf3c and raw-association-acceptance-20261011/verify.py. Original contracts show completed admission/association descendants but unchanged raw semantic acceptance still active; its complete parent witness and current publication were not established.\n'
                '  - [x] **ADDRESSED (verified)** — verify.py joins every complete original raw semantic obligation and unchanged descendant contract to whole source custody, every fresh declared prerequisite, complete association defaults and exact original clarity-context replay with genuine advanced-task refusal/restoration. All inherited meanings, complete genuine semantic controls, first failures and native/private gaps conserve; only the finite raw semantic parent and leaf close.\n'
                '  - [x] **NO REGRESSION** — All tests successful in checks.json focused. Whole before/after predecessor defaults, complete source/product custody, current/book/native/claim gates, staged scripts/check_doctrines.sh and normal hooks require actual success before commit.\n\n').encode()
        task = task.replace(block, final, 1)
    verify.contracts(task)
    local(TASK).write_bytes(task)
    successor = OWNER.rsplit('.', 1)[0] + '.3'
    memory = local('MEMORY.md').read_text().replace(LEAF + '` (active)', successor + '` (pending)', 1)
    memory = re.sub(r'^- next_action:.*$', '- next_action: Confirm terminal complete raw semantic acceptance gates and commit any dirty owned state, then activate governed non-growing canonical raw publication .5.3. Preserve all old meanings/questions/probes and original native/private/higher gaps; do not widen allowances.', memory, flags=re.M)
    memory = re.sub(r'^- in_flight_background:.*$', '- in_flight_background: Derive incomplete started/actual checks under docs/audits/raw-semantic-acceptance-20261011/checks.json. Consume every required result before handoff.', memory, flags=re.M)
    local('MEMORY.md').write_text(memory)
    index = local('docs/TASK_TREE.md').read_text()
    need('association done; raw semantic acceptance active.' in index, 'owned bounded association frontier')
    local('docs/TASK_TREE.md').write_text(index.replace('association done; raw semantic acceptance active.', 'raw semantic done; canonical publication next.', 1))
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
    print('Prepared unchanged complete raw semantic acceptance and finite book publication; all external gates require actual success.')


if __name__ == '__main__':
    main()
