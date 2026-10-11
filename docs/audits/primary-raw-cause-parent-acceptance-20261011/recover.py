"""Recover the reviewed encoding-line identity without rewriting the first epoch."""
from parent_common import *
import publish

NAMES = (TASK, BOOK, REGISTRY)


def transformation(before):
    finding = json.loads((BASE / 'inventory-finding.json').read_bytes())
    first = json.loads((BASE / 'inventory-write-actual.json').read_bytes())
    need(type(first['status']) is int and first['status'] == 1
         and type(first['expected_status']) is int and first['expected_status'] == 0
         and first['stdout'] == '' and first['stderr'].endswith(
             'claim-inventory: disposition registry names stale candidate_id ' + finding['candidate_id'] + '\n'),
         'whole first unexpected inventory failure remains non-success')
    old, new = (finding[key].encode() for key in ('first_compacted', 'restored_compaction'))
    book = before[BOOK]
    need(book.count(old) == 1, 'whole first compacted encoding source before recovery')
    book = book.replace(old, new, 1)
    command_before = ('docs/audits/primary-raw-cause-parent-acceptance-20261011/verify.py').encode()
    command_after = command_before.replace(b'/verify.py', b'/complete.py')
    need(book.count(command_before) == 1, 'one initial parent replay route')
    book = book.replace(command_before, command_after, 1)
    need(len(book) == len(before[BOOK]) + finding['book_delta'] <= 292485,
         'exact unchanged book allowance after claim-line and final reader repair')
    import hashlib
    line = finding['original_line']
    need(book.decode().splitlines().count(line) == 1
         and 'published-' + hashlib.sha256((BOOK + '\0' + line + '\0' + '1').encode()).hexdigest()[:24] == finding['candidate_id'],
         'independently restored original reviewed encoding-line identity')
    task = before[TASK]
    original = nodes(task)[PLAN['owner']]
    need(field(original, 'Status') == 'done', 'whole first proposed closure before owned recovery')
    changed = original.rstrip() + (
        '\n  Finding F1: `Initial inventory-write native1/declared0: reviewed_incidental UTF-8 source line was rewrapped during bounded book compaction, changing normalized-line candidate_id published-a159ded6caeda163a2d8d7fa while its disposition retained the original ID. Reproduce with scripts/check_claim_verification_inventory.pl --write at the first publication epoch. Impact: required inventory delivery failed; source/cause controls and original native/private scopes remain qualified in their recorded epochs. Own the exact source-line restoration, preserve the complete first native failure, and qualify corrected current/book/source/claim/disposition/staged/normal delivery before closure. Evidence: docs/audits/primary-raw-cause-parent-acceptance-20261011/inventory-finding.json.`\n'
        '  Finding F1 resolution: `Restore the whole originally reviewed encoding line and its independently rederived candidate ID without changing its reviewed-incidental meaning, disposition, verifier or authority. The final complete.py entry retains the initial partial verifier and every original native/source/control epoch, separately authenticates recovery snapshots and qualifies complete corrected delivery. Both the failed initial epoch and successful correction remain committed; no original failure is normalized.`\n\n').encode()
    for header, replacement in (
        ('ROOT CAUSE (WHY + WHERE)', 'First inventory-write native1/declared0 identifies a stale reviewed UTF-8 normalized-line candidate ID after book rewrap; inventory-finding.json pins the exact mechanism and first actual terminal. '),
        ('ADDRESSED (verified)', 'The complete reviewed encoding line and original disposition identity restore; complete.py authenticates unchanged initial scope plus separate corrected delivery and failure custody. '),
    ):
        marker = ('**' + header + '** — ').encode()
        need(changed.count(marker) == 1, 'whole unique current recovery acceptance box')
        changed = changed.replace(marker, marker + replacement.encode(), 1)
    task = task.replace(original, changed, 1)
    first_nodes, final_nodes = nodes(before[TASK]), nodes(task)
    need(first_nodes.keys() == final_nodes.keys() and all(
        all(field(first_nodes[name], key) == field(final_nodes[name], key) for key in ('Goal', 'Acceptance', 'Children', 'Status'))
        and (name == PLAN['owner'] or first_nodes[name] == final_nodes[name]) for name in first_nodes),
        'only owned failure metadata changes; every complete task obligation and status retains')
    publication = publish.qualify(current=False)
    tasks = fixed(publication['task_names'])
    tasks[TASK] = task
    rows = list(map(json.loads, before[REGISTRY].splitlines()))
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            for key, value in metrics(tasks).items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged task ceilings through recovery')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
        elif row.get('surface_id') == 'shipped_behavior':
            books = fixed(publication['book_names'])
            measured_before = metrics(books)
            books[BOOK] = book
            measured_after = metrics(books)
            authority = row['reference_contract']['aggregate_change']
            need(authority['owner'] == PLAN['owner'], 'same exact book recovery owner')
            for key in ('files', 'bytes_total', 'lines_total'):
                need(authority['baseline'][key] == measured_before[key], 'whole unchanged original book baseline')
                authority['delta'][key] = measured_after[key] - measured_before[key]
            authority['rationale'] += ' Restore the exact reviewed UTF-8 line after its retained first stale-disposition refusal and document the separately qualified final recovery entry; all ceilings and canonical authority retain.'
    return {TASK: task, BOOK: book, REGISTRY: b''.join(canonical(row) for row in rows)}


def overlays():
    result = {}
    initial = json.loads((BASE / 'publication.json').read_bytes())
    for name, roles in initial['snapshots'].items():
        body = gzip.decompress(Path(roles['after']['snapshot']).read_bytes())
        need(pin(body) == roles['after']['identity'], 'whole original publication afterimage')
        result[name] = body
    row = json.loads((BASE / 'recovery-publication.json').read_bytes())
    for name, roles in row['snapshots'].items():
        body = gzip.decompress(Path(roles['after']['snapshot']).read_bytes())
        need(pin(body) == roles['after']['identity'], 'whole corrected recovery afterimage')
        result[name] = body
    return result


def qualify(*, current=False):
    row = json.loads((BASE / 'recovery-publication.json').read_bytes())
    need(row['owner'] == PLAN['owner'] and set(row['snapshots']) == set(NAMES), 'closed complete owned recovery population')
    before, after = {}, {}
    initial = publish.qualify(current=False)
    for name, roles in row['snapshots'].items():
        need(set(roles) == {'before', 'after'}, 'whole recovery source epochs')
        for role, entry in roles.items():
            path = Path(entry['snapshot'])
            need(path.parent == BASE and path.name.startswith('recovery-' + role + '-') and not path.is_symlink(),
                 'ordinary whole owned recovery snapshot')
            body = gzip.decompress(path.read_bytes())
            need(pin(body) == entry['identity'], 'whole recovery snapshot identity')
            (before if role == 'before' else after)[name] = body
        need(before[name] == gzip.decompress(Path(initial['snapshots'][name]['after']['snapshot']).read_bytes()),
             'whole original publication becomes exact recovery beforeimage')
    need(transformation(before) == after, 'whole independently reconstructed encoding-line and failure-metadata recovery')
    if current:
        need(all(Path(name).read_bytes() == body for name, body in overlays().items()), 'whole explicit current recovered publication')
    return row


if __name__ == '__main__':
    initial = publish.qualify(current=True)
    before = {name: Path(name).read_bytes() for name in NAMES}
    after = transformation(before)
    snapshots = {}
    for index, name in enumerate(NAMES):
        snapshots[name] = {}
        for role in ('before', 'after'):
            path = BASE / ('recovery-' + role + '-' + str(index) + '.gz')
            need(not path.exists(), 'fresh complete recovery snapshot')
            snapshots[name][role] = dict(snapshot=str(path), identity=pin((before if role == 'before' else after)[name]))
    need(not (BASE / 'recovery-publication.json').exists(), 'fresh whole owned recovery')
    for name, roles in snapshots.items():
        for role, entry in roles.items():
            Path(entry['snapshot']).write_bytes(gzip.compress((before if role == 'before' else after)[name], mtime=0))
    save('recovery-publication.json', dict(owner=PLAN['owner'], snapshots=snapshots))
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'whole final recovery source conservation before writes')
    for name, body in after.items():
        Path(name).write_bytes(body)
    print('Published exact reviewed encoding-line recovery and owned first-failure metadata; corrected delivery remains required.')
