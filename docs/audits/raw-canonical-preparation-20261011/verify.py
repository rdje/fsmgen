"""Qualify the fixed-source preparation without depending on an ignored checkpoint."""
import argparse
import copy
import gzip
import io
import json
from pathlib import Path
import re
import subprocess

from capture import BASE, canonical, pin, save
import checkpoint

PLAN = checkpoint.PLAN
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
SUCCESS = 'PASS complete raw canonical preparation, original source conditions and non-growing candidate; production publication remains open.\n'
EXCLUDED = {'proof.json', 'manifest.json'} | {
    label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def need(value, message):
    if not value:
        raise ValueError(message)


def read(name):
    return json.loads((BASE / name).read_bytes())


def nodes(raw):
    matches = list(re.finditer(rb'^- ID: `([^`]+)`\n', raw, re.M))
    result = {m[1].decode(): raw[m.start():matches[i+1].start() if i+1 < len(matches) else len(raw)]
              for i, m in enumerate(matches)}
    need(len(matches) == len(result), 'unique whole original task nodes')
    return result


def field(block, name):
    match = re.search(rb'^  ' + name.encode() + rb': `(.*)`$', block, re.M)
    return match[1].decode() if match else None


def contracts():
    original = checkpoint.git('show', PLAN['revision'] + ':' + TASK)
    targets = {k: v for k, v in nodes(original).items() if k == PLAN['raw'] or k.startswith(PLAN['raw'] + '.')}
    active = nodes(gzip.decompress((BASE / 'activation-task.md.gz').read_bytes()))
    result = {}
    for key, block in targets.items():
        result[key] = {name: field(block, name) for name in ('Goal', 'Acceptance', 'Children')}
        need(all(field(active[key], name) == value for name, value in result[key].items()
                 if not (key == PLAN['parent'] and name == 'Children')),
             'every unchanged original full raw/container/descendant contract')
        if key.startswith(PLAN['raw'] + '.5.1') or key.startswith(PLAN['raw'] + '.5.2'):
            need(field(block, 'Status') == 'done', 'every prerequisite and semantic descendant completed before canonical preparation')
    need(field(active[PLAN['parent']], 'Children') == ', '.join(PLAN['parent'] + '.' + str(i) for i in (1, 2, 3)),
         'only explicit safe canonical children supplement original parent contract')
    return dict(revision=PLAN['revision'], task=pin(original), nodes=result,
                condition=PLAN['condition'])


def candidate():
    target = PLAN['canonical_target']
    before = checkpoint.git('show', PLAN['revision'] + ':' + target)
    old, new = (PLAN[key].encode() for key in ('candidate_old', 'candidate_new'))
    need(before.count(old) == 1, 'unique bounded original raw canonical meaning')
    after = before.replace(old, new, 1)
    for change in PLAN['compactions']:
        previous, compact = (change[k].encode() for k in ('old', 'new'))
        need(after.count(previous) == 1, 'unique exact meaning-preserving compaction source')
        after = after.replace(previous, compact, 1)
    need(after.split(b'---\n', 2)[:2] == before.split(b'---\n', 2)[:2],
         'every original fact id/question/evidence/reverification byte conserves')
    restored = after
    for change in reversed(PLAN['compactions']):
        restored = restored.replace(change['new'].encode(), change['old'].encode(), 1)
    need(restored.replace(new, old, 1) == before, 'every old meaning and uncertainty conserves outside declared finite extension and equivalent contractions')
    names = checkpoint.git('ls-tree', '-r', '--name-only', PLAN['revision'], '--', 'docs/knowledge').decode().splitlines()
    names = [n for n in names if re.fullmatch(r'docs/knowledge/[^/]+\.md', n)]
    requests = b''.join((PLAN['revision'] + ':' + n + '\n').encode() for n in names)
    native = subprocess.run(['git', '--no-replace-objects', 'cat-file', '--batch'],
                            input=requests, capture_output=True)
    need(native.returncode == 0 and native.stderr == b'', 'complete fixed canonical Git batch terminal')
    stream, raw = io.BytesIO(native.stdout), {}
    for name in names:
        header = stream.readline().split()
        need(len(header) == 3 and header[1] == b'blob', 'whole fixed canonical blob header')
        size = int(header[2])
        body = stream.read(size)
        need(len(body) == size and stream.read(1) == b'\n', 'whole fixed canonical body and EOF')
        raw[name] = body
    need(stream.read(1) == b'', 'complete canonical batch member population')
    registry = checkpoint.git('show', PLAN['revision'] + ':' + REGISTRY)
    authority = next(r for r in map(json.loads, registry.splitlines()) if r.get('surface_id') == 'knowledge_cards')
    previous = metrics(raw)
    raw[target] = after
    measured = metrics(raw)
    for key, value in measured.items():
        allowed = min(authority['enforcement_ceilings'][key], authority['baseline'][key] + authority['transition']['max_growth'][key])
        need(value <= allowed, 'candidate fits unchanged canonical ' + key + ' allowance')
    non_growth(previous, measured)
    need(previous['files'] == measured['files'], 'no canonical file growth')
    return dict(target=target, before=before.decode(), after=after.decode(),
                before_identity=pin(before), after_identity=pin(after),
                previous=previous, proposed=measured, authority=authority,
                compactions=PLAN['compactions'],
                condition='Proposed finite source-derived raw joining only. All original facts/questions/probes and opaque/native/private uncertainty retain; no production change yet.')


def metrics(sources):
    rows = [dict(bytes=len(raw), lines=raw.count(b'\n'), width=max(map(len, raw.splitlines()), default=0))
            for raw in sources.values()]
    return dict(files=len(rows), bytes_total=sum(r['bytes'] for r in rows),
                lines_total=sum(r['lines'] for r in rows), bytes_each=max(r['bytes'] for r in rows),
                lines_each=max(r['lines'] for r in rows), line_bytes_each=max(r['width'] for r in rows))


def non_growth(previous, proposed):
    need(previous.keys() == proposed.keys(), 'complete canonical metric population')
    for key, value in proposed.items():
        need(type(value) is int and type(previous[key]) is int and value <= previous[key],
             'rollover-debt candidate does not grow ' + key)


def gate(label, command, stdout=None):
    row, started = read(label + '-actual.json'), read(label + '-started.json')
    need(all(row[k] == value for k, value in started.items()), 'whole started gate declaration')
    need(type(row['status']) is int and row['status'] == 0
         and type(row['expected_status']) is int and row['expected_status'] == 0,
         'typed complete successful gate ' + label)
    need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
         and row['programmes'] == row['programmes_after'], 'whole actual gate command and conserved source epoch')
    for name, entry in row['programmes'].items():
        body = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(body) == entry['identity'] and Path(name).read_bytes() == body, 'complete current direct gate programme/input')
    need(re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', row['stderr'])
         and 'ram-guard: terminating PID tree' not in row['stderr'], 'unchanged successful guard')
    if stdout is not None:
        need(row['stdout'] == stdout and row['stderr'].count('\n') == 1, 'whole intended native gate result')
    return pin(canonical(row))


def qualify(joined, expected):
    need(joined['source'] == expected['source'], 'complete original committed source join')
    need(joined['contracts'] == expected['contracts'], 'complete unchanged original raw obligations')
    actual = joined['actual']
    need(type(actual['status']) is int and actual['status'] == 0, 'actual successful unchanged parent checkpoint')
    need(actual == expected['actual'], 'whole actual fixed-source result')


def core():
    source = checkpoint.derive()
    need(source == read('source-v3.json'), 'whole fixed Git source graph independent of ignored view')
    actual = read('parent-checkpoint-v3-actual.json')
    need(actual['revision'] == PLAN['revision'] and actual['cwd'] == str(checkpoint.VIEW)
         and actual['command'] == ['python3', '-B', PLAN['raw_parent'] + '/verify.py']
         and actual['source'] == actual['after'] == pin(canonical(source))
         and actual['stdout'] == 'PASS complete unchanged raw semantic parent acceptance; canonical and higher native/private scopes remain open.\n'
         and actual['stderr'] == '', 'whole original parent checkpoint role, source and native terminal')
    outer = gate('checkpoint-v3', ['python3', '-B', str(BASE / 'checkpoint.py'), '--prepare'], checkpoint.SUCCESS)
    prerequisite = PLAN['original_prerequisite']
    proof = json.loads(checkpoint.git('show', PLAN['revision'] + ':' + prerequisite + '/proof.json'))
    need(proof['revision'] == PLAN['original_prerequisite_revision'], 'original prerequisite explicitly retains e428 source condition')
    archive = checkpoint.git('ls-tree', '-r', '-z', PLAN['revision'], '--', prerequisite)
    for row in archive.rstrip(b'\0').split(b'\0'):
        header, name = row.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        need(kind == 'blob' and source['members'][name.decode()]['mode'] == mode
             and source['members'][name.decode()]['oid'] == oid, 'complete committed original prerequisite archive in later checkpoint')
    failed = read('checkpoint-first-failure.json')
    inner = read('checkpoint-actual.json')
    need(type(inner['status']) is int and inner['status'] == 1
         and "ModuleNotFoundError: No module named 'restore_record_value_gate_streams'" in inner['stderr']
         and failed['outer_shell_status'] == 1 and failed['outer_guard_terminal'] is None,
         'complete first import failure and explicitly missing outer terminal remain authoritative')
    original_source = read('source.json')
    additions = set(source['members']) - set(original_source['members'])
    needed = {'scripts/restore_record_value_gate_streams.py', 't/python/test_record_value_gate_streams.py'}
    for path in checkpoint.git('ls-tree', '-r', '--name-only', PLAN['revision'], '--', PLAN['raw_parent']).decode().splitlines():
        if path.endswith('-actual.json'):
            needed.update(json.loads(checkpoint.git('show', PLAN['revision'] + ':' + path)).get('programmes', {}))
    need(additions == needed - set(original_source['members']), 'every and only complete parent direct gate dependency supplements source selection')
    need(set(source['members']) == set(original_source['members']) | additions
         and all(source['members'][n] == row for n, row in original_source['members'].items()),
         'only declared direct public dependencies supplement failed original source selection')
    failed_v2 = read('parent-checkpoint-v2-actual.json')
    outer_v2 = read('checkpoint-v2-actual.json')
    need(type(failed_v2['status']) is int and failed_v2['status'] == 1
         and type(outer_v2['status']) is int and outer_v2['status'] == 1
         and "No such file or directory: 't/1549-task-tree-integrity-doctrine.t'" in failed_v2['stderr'],
         'whole second direct gate source closure failure remains non-success')
    normal = read('parent-normal-commit.json')
    need(type(normal['status']) is int and normal['status'] == 0
         and '[doctrine] all doctrine checks passed' in normal['stdout'] + normal['stderr'],
         'complete clean committed parent normal-hook prerequisite')
    restoration = read('restoration-actual.json')
    census = read('restoration-census.json')
    recording = read('restoration-recorder-finding.json')
    need(type(restoration['status']) is int and restoration['status'] == 0
         and restoration['command'] == ['python3', '-B', str(BASE / 'restore.py')]
         and restoration['stdout'] == checkpoint.SUCCESS and restoration['stderr'] == ''
         and restoration['before'] == pin(canonical(source))
         and set(census) == {'before', 'restored', 'retained'}
         and all(value == pin(canonical(source)) for value in census.values()),
         'actual committed-only restoration with whole original and restored source populations')
    need(type(recording['outer_shell_status']) is int and recording['outer_shell_status'] == 1
         and recording['outer_guard_terminal'] is None,
         'first restoration recorder failure retains without invented outer terminal')
    restored_gate = gate('gate-restoration', ['python3', '-B', str(BASE / 'restore.py')], checkpoint.SUCCESS)
    joined = dict(source=source, contracts=contracts(), actual=actual)
    qualify(joined, joined)
    controls = []
    for name, mutate, cause in (
        ('omitted source', lambda c: c['source']['members'].pop(next(iter(c['source']['members']))), 'complete original committed source join'),
        ('omitted obligation', lambda c: c['contracts']['nodes'].pop(PLAN['raw']), 'complete unchanged original raw obligations'),
        ('Boolean checkpoint status', lambda c: c['actual'].update(status=False), 'actual successful unchanged parent checkpoint')):
        changed = copy.deepcopy(joined)
        mutate(changed)
        try:
            qualify(changed, joined)
        except ValueError as error:
            need(str(error) == cause, 'actual intended preparation intervention refusal')
            controls.append(dict(name=name, cause=str(error)))
        else:
            raise ValueError('changed preparation accepted: ' + name)
    proposed = candidate()
    need(proposed == read('candidate.json'), 'whole final non-growing candidate and meaning-preserving contractions')
    first = read('candidate-first.json')
    old_plan = read('plan-first.json')
    need(first['before'] == proposed['before']
         and first['after'] == first['before'].replace(old_plan['candidate_old'], old_plan['candidate_new'], 1)
         and first['proposed']['bytes_total'] > first['previous']['bytes_total'],
         'whole genuine first growing candidate retains without promotion')
    try:
        non_growth(first['previous'], first['proposed'])
    except ValueError as error:
        need(str(error) == 'rollover-debt candidate does not grow bytes_total', 'intended first growing candidate refusal')
        controls.append(dict(name='original growing candidate', cause=str(error)))
    else:
        raise ValueError('first growing rollover candidate accepted')
    return dict(owner=PLAN['owner'], source=pin(canonical(source)), contracts=joined['contracts'],
                actual=pin(canonical(actual)), outer=outer, restoration=pin(canonical(restoration)),
                restored_gate=restored_gate, candidate=proposed, controls=controls,
                prerequisite=dict(source_revision=proof['revision'], archive_revision=PLAN['revision'],
                    condition='The e428 prerequisite was qualified at its declared source epoch. Its complete later committed archive and first failures retain. No fresh prerequisite execution or later current-programme currency is claimed.'),
                legs=dict(rederive='Whole original raw obligations and Git object/file/directory/mode/body population; actual unchanged full parent in its complete committed source context.',
                    falsify='Real omitted-source, omitted-obligation and Boolean-terminal interventions reach distinct intended refusals; inherited original source/semantic/context/recovery controls remain in unchanged full parent qualification.',
                    durability='Complete committed source graph, parent and prerequisite namespaces, native before/after checkpoint and first failed import retain. Qualification needs no ignored view; checkpoint reconstruction uses Git only.'))


def catalogue():
    return {p.name: dict(**pin(p.read_bytes()), executable=bool(p.stat().st_mode & 0o111))
            for p in sorted(BASE.iterdir()) if p.is_file() and p.name not in EXCLUDED}


def publication():
    row = read('publication.json')
    snapshots = {}
    for name, epochs in row['snapshots'].items():
        snapshots[name] = {}
        for role, entry in epochs.items():
            body = gzip.decompress(Path(entry['snapshot']).read_bytes())
            need(pin(body) == entry['identity'], 'whole preparation publication snapshot')
            snapshots[name][role] = body
    correction = read('candidate-correction.json')
    need(set(correction['snapshots']) == {TASK, REGISTRY}, 'only owned candidate finding and task measurement change after publication')
    for name, epochs in correction['snapshots'].items():
        bodies = {}
        for role, entry in epochs.items():
            bodies[role] = gzip.decompress(Path(entry['snapshot']).read_bytes())
            need(pin(bodies[role]) == entry['identity'], 'whole candidate correction snapshot')
        need(bodies['before'] == snapshots[name]['after'], 'exact first publication predecessor for candidate correction')
        if name == TASK:
            block = nodes(bodies['before'])[PLAN['owner']]
            needle = b'  Acceptance Checklist (enforced):\n'
            need(bodies['after'] == bodies['before'].replace(block, block.replace(needle, correction['addition'].encode() + needle, 1), 1),
                 'only exact owned rollover candidate finding supplements publication')
        snapshots[name]['after'] = bodies['after']
    for name, epochs in snapshots.items():
        need(Path(name).read_bytes() == epochs['after'], 'whole final current preparation publication')
    before, after = (nodes(snapshots[TASK][role]) for role in ('before', 'after'))
    need(before.keys() == after.keys(), 'whole task graph conserves during preparation closure')
    for key in before:
        need(all(field(before[key], name) == field(after[key], name) for name in ('Goal', 'Acceptance', 'Children')),
             'every complete task contract conserves during preparation closure')
        if key == PLAN['owner']:
            need(field(before[key], 'Status') == 'active' and field(after[key], 'Status') == 'done',
                 'only fully qualified source preparation closes')
        else:
            need(before[key] == after[key], 'every unrelated task node conserves whole')
    need(snapshots[BOOK]['after'] == snapshots[BOOK]['before'].replace(row['old_notice'].encode(), row['notice'].encode(), 1)
         and len(snapshots[BOOK]['after']) <= 292485, 'only bounded own fixed-source checkpoint guide changes')
    old_rows = list(map(json.loads, snapshots[REGISTRY]['before'].splitlines()))
    new_rows = list(map(json.loads, snapshots[REGISTRY]['after'].splitlines()))
    need(len(old_rows) == len(new_rows), 'whole size authority population conserves')
    for old, new in zip(old_rows, new_rows, strict=True):
        wanted = copy.deepcopy(old)
        if old.get('surface_id') == 'task_evidence':
            measured = metrics({n: Path(n).read_bytes() for n in row['task_names']})
            for key, value in measured.items():
                need(value <= old['enforcement_ceilings'][key], 'unchanged task authority ceiling')
                wanted['transition']['max_growth'][key] = max(0, value + old['transition']['ratchet_step'][key] - old['baseline'][key])
        elif old.get('surface_id') == 'shipped_behavior':
            wanted['reference_contract']['aggregate_change'] = new['reference_contract']['aggregate_change']
            authority = wanted['reference_contract']['aggregate_change']
            need(authority['owner'] == PLAN['owner'] and authority['authority_id'] == 'RAW-CANONICAL-SOURCE-PREPARATION-20261011',
                 'exact own book aggregate authority')
            books = {n: Path(n).read_bytes() for n in row['book_names']}
            measured = metrics(books)
            books[BOOK] = snapshots[BOOK]['before']
            previous = metrics(books)
            keys = ('files', 'bytes_total', 'lines_total')
            need(authority['baseline'] == {k: previous[k] for k in keys}
                 and authority['delta'] == {k: measured[k] - previous[k] for k in keys},
                 'independently complete own book aggregate measurement')
        need(new == wanted, 'every other capacity field, Knowledge Map allowance and ceiling conserves')
    return {name: pin(epochs['after']) for name, epochs in snapshots.items()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one explicit preparation qualification role')
    result = core()
    if args.core:
        print('PASS complete committed-source preparation core; current delivery remains separate.')
        return
    result['publication'] = publication()
    commands = {
        'gate-publication': ['python3', '-B', str(BASE / 'publish.py')],
        'root-history': ['git', 'log', '-1', '-S', 'import restore_record_value_gate_streams',
                         '--format=%H %s', '--', PLAN['raw_parent'] + '/intake.py'],
        'focused-v2': ['prove', '-v', 't/2067-record-value-gate-streams.t', 't/1549-task-tree-integrity-doctrine.t',
                    't/1636-claim-verification-doctrine.t', 't/1303-isf-public-live-book-paths-audit.t', 't/1305-isf-book-feature-matrix-audit.t'],
        'book': ['mdbook', 'build', 'docs/book'],
        'native': ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', 'docs/book/book'],
        'size-v2': ['scripts/check_live_document_size.sh'], 'claims-v2': ['scripts/check_claim_verification.pl'],
        'inventory-write-v2': ['scripts/check_claim_verification_inventory.pl', '--write'],
        'inventory-v2': ['scripts/check_claim_verification_inventory.pl']}
    result['external'] = {n: gate(n, command) for n, command in commands.items()}
    need('All tests successful' in read('focused-v2-actual.json')['stdout'], 'complete actual focused regression success')
    if args.seal:
        save('proof.json', result)
        save('manifest.json', catalogue())
    else:
        need(read('proof.json') == result and read('manifest.json') == catalogue(), 'whole immutable preparation evidence catalogue')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
