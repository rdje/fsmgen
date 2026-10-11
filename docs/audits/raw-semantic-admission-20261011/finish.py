"""Publish only completed admission; raw semantic association stays pending."""
import base64
import copy
import gzip
import re
from pathlib import Path
from common import *
import run
import verify

SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'


def authority(before, task_sources, book_sources, book_after):
    rows = [json.loads(line) for line in before.splitlines()]
    measured = metrics(task_sources)['metrics']
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            need(row['state'] == 'warning_debt' and measured['lines_each'] < 7200, 'owned warning-debt work before rollover')
            for key, value in measured.items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged task ceilings')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            baseline = metrics(book_sources)['metrics']
            current = dict(book_sources)
            current[BOOK] = book_after
            after = metrics(current)['metrics']
            keys = ('files', 'bytes_total', 'lines_total')
            row['reference_contract']['aggregate_change'] = dict(authority_id='RAW-SEMANTIC-ADMISSION-20261011',
                owner=OWNER, baseline={key: baseline[key] for key in keys},
                delta={key: after[key]-baseline[key] for key in keys},
                rationale='Document complete fresh raw-semantic source/prerequisite admission and explicit fixed-instrument replay condition; full raw association/publication and original native/private scopes stay open.')
    return b''.join(canonical(row) for row in rows)


def main():
    actuals = verify.actual_readers()
    native_paths = sorted(BASE.glob('actual-native-census-*.json'))
    need(len(native_paths) == 1, 'complete first independent native census')
    actual = json.loads(native_paths[0].read_bytes())
    need(type(actual['status']) is int and actual['status'] == 0 and actual['stderr'] == '', 'actual full native source census')
    save('native-census.json', dict(receipt=str(native_paths[0]), identity=pin(native_paths[0].read_bytes())))
    need(load('intake-before.json') == load('intake-after.json'), 'whole source condition before publication')
    topology = load('topology-controls.json')
    diagnostic = topology['cases']['changed-tail']['native']['stderr']
    locus = re.search(r' at [^\s]+ line [0-9]+', diagnostic)
    need(locus is not None, 'actual native control diagnostic locus')
    current = local(TASK).read_bytes()
    graph = verify.task_nodes(current)
    block = graph[OWNER]
    need(verify.field(block, 'Status') == 'active', 'own live admission leaf before finish')
    save('reader-summary.json', dict(readers=actuals, scope=SCOPE))
    wording = ('Whole clean 3a5229ffa source/native/product and complete predecessor namespaces authenticate byte for byte, '
        'including directory closure and the recovered coordinate archive. Every declared prerequisite reader freshly executes '
        'in its exact source or dated-instrument role; complete commands/programmes and both durable streams retain before status judgement. '
        'Independent native filesystem/source census and genuine topology/byte/missing/link/foreign/typed-result/borrowed-role controls qualify. '
        'Whole original raw contracts and every unrelated task node conserve. Source condition remains explicit; later changed publication '
        'instruments require a separately qualified complete dated checkpoint. Complete current/book/native/focused/claim/staged/normal '
        'gates require actual success before commit. Full raw association/publication and original native/private scopes remain open.')
    updated = block.replace(b'  Status: `active`\n', b'  Status: `done`\n', 1)
    updated = updated.replace(b'  Verification: `pending`\n', ('  Verification: `' + wording + '`\n').encode(), 1)
    updated = updated.replace(b'  Commit: `pending`\n', ('  Commit: `' + OWNER + ': qualify complete raw semantic admission`\n').encode(), 1)
    updated = updated.rstrip() + (f'\n  Acceptance Checklist (enforced):\n'
        f'  - [x] **ROOT CAUSE (WHY + WHERE)** — Actual whole-byte native control refuses{locus[0]}; topology-controls.json retains its complete candidate, programme-bound outcome and both streams. Fixed predecessor/source intake and unchanged raw contracts require fresh admission before full-body association.\n'
        '  - [x] **ADDRESSED (verified)** — Complete Git/current byte and directory closure, separate native census, all fresh explicit source/dated reader roles and complete durable child streams qualify. Whole original acceptance and all prior source/native/private boundaries conserve; semantic association remains pending.\n'
        '  - [x] **NO REGRESSION** — All tests successful in checks.json focused; current source/native/book publication, independent input/result controls, exact saved reader, source/claim/staged scripts/check_doctrines.sh and normal hooks require actual success before commit.\n\n').encode()
    local(TASK).write_bytes(current.replace(block, updated, 1))
    memory = local('MEMORY.md').read_text().replace(OWNER + '` (active)', OWNER.rsplit('.', 1)[0] + '.2` (pending)', 1)
    start, end = memory.index('- next_action:'), memory.index('- in_flight_uncommitted:')
    memory = memory[:start] + '- next_action: Activate independent complete raw-body association .5.2.2 from committed whole admission; preserve every source/class/frame/header/coordinate/address and inner/outer cause contract, prior meanings and original native/private gaps.\n' + memory[end:]
    local('MEMORY.md').write_text(memory)
    index = local('docs/TASK_TREE.md').read_text()
    need('raw join admission active.' in index, 'owned task-index frontier')
    local('docs/TASK_TREE.md').write_text(index.replace('raw join admission active.', 'raw admission done; full-body association next.', 1))
    book_before = git('show', REVISION + ':' + BOOK)
    need(local(BOOK).read_bytes() == book_before, 'exact book baseline before owned addition')
    marker = b'Only the finite observer and class/frame predecessor containers close here.\n'
    addition = (b'Complete raw-semantic admission now authenticates the whole source/native/product\n'
        b'domain again before independent raw-body association. Every prerequisite runs\n'
        b'in its declared source or dated-instrument role. Child stdout and stderr are\n'
        b'saved while each command runs, so interruption leaves recoverable streams. A\n'
        b'separate native filesystem census checks every member, byte digest, executable\n'
        b'mode and directory. Missing members, changed tails, unlisted files, empty\n'
        b'directories, links, foreign paths and borrowed or Boolean results reject.\n\n'
        b'This reader requires its admitted source instruments to remain byte-identical\n'
        b'to the fixed predecessor. Later publication changes require an explicit whole\n'
        b'dated checkpoint; this result supplies no later native/current currency:\n\n'
        b'```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/raw-semantic-admission-20261011/verify.py\n```\n\n')
    need(book_before.count(marker) == 1, 'unique current admission publication boundary')
    local(BOOK).write_bytes(book_before.replace(marker, addition + marker, 1))
    names = git('ls-tree', '-r', '--name-only', REVISION).decode().splitlines()
    task_names = sorted(name for name in names if re.fullmatch(r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', name))
    book_names = sorted(name for name in names if re.fullmatch(r'docs/book/src/[^/]+\.md', name))
    fixed = fixed_sources(task_names + book_names + [SURFACES])
    tasks = {name: local(name).read_bytes() for name in task_names}
    need(all(raw == fixed[name] for name, raw in tasks.items() if name != TASK), 'all other current task sources exact')
    observed = sorted(str(path) for pattern in ('docs/tasks/*.md', 'docs/tasks/segments/*/*.md') for path in Path('.').glob(pattern))
    need(observed == task_names, 'complete unchanged task collection membership')
    save('task-census.json', metrics(tasks))
    registry = authority(fixed[SURFACES], tasks, {name: fixed[name] for name in book_names}, local(BOOK).read_bytes())
    need(local(SURFACES).read_bytes() == fixed[SURFACES], 'complete unchanged registry before exact owned allowance')
    local(SURFACES).write_bytes(registry)
    for name, raw in (('registry-before.txt', fixed[SURFACES]), ('registry-after.txt', registry)):
        path = local(BASE / name, exists=False)
        need(not path.exists(), 'retain full registry source bodies')
        path.write_bytes(raw)
    path = local(BASE / 'qualified-task.md.gz', exists=False)
    need(not path.exists(), 'retain full qualified task source')
    path.write_bytes(gzip.compress(local(TASK).read_bytes(), mtime=0))
    for name, raw in (('book-before.md.gz', book_before), ('book-after.md.gz', local(BOOK).read_bytes())):
        path = local(BASE / name, exists=False)
        need(not path.exists(), 'retain complete book publication sources')
        path.write_bytes(gzip.compress(raw, mtime=0))
    save('publication.json', dict(book_before=pin(book_before), book_after=pin(local(BOOK).read_bytes()),
        registry_before=pin(fixed[SURFACES]), registry_after=pin(registry), source_revision=REVISION,
        task_names=task_names, book_names=book_names))
    print('Prepared complete admission publication and exact measured authority; all external gates still require actual success.')


if __name__ == '__main__':
    main()
