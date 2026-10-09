"""Authenticate exact closed-history rollover and real unchanged gate controls."""
import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'fc60d62ad51d844481cd4b9e6ae78eefa31c0b11'
TREE = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER'
TASK = 'docs/tasks/' + TREE + '.md'
HISTORY = 'docs/tasks/history/' + TREE + '/acceptance-history.jsonl'
RETENTION = 'doctrine/live_document_size/version_retention_contracts.jsonl'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
BOOK = 'docs/book/src/90-reference-map.md'
BOUNDARY = 'Completed Historical Implementation Notes'


def git(*args):
    return subprocess.check_output(['git', '--no-replace-objects', *args], cwd=ROOT)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def history(record):
    source = git('show', record['source_revision'] + ':' + record['source_path'])
    marker = ('## ' + record['start_heading'] + '\n').encode()
    assert source.count(marker) == 1
    suffix = source[source.index(marker):]
    dimensions = {'source_sha256': pin(source)['sha256'], 'source_bytes': len(source),
        'source_lines': source.count(b'\n'), 'history_sha256': pin(suffix)['sha256'],
        'history_bytes': len(suffix), 'history_lines': suffix.count(b'\n'),
        'history_sections': len(re.findall(rb'^## ', suffix, re.M))}
    for key, value in dimensions.items():
        assert type(record[key]) is type(value) and record[key] == value, key
    assert record['retention_contract'] == 'fsmgen_required_history'
    return source, suffix


def nodes(raw):
    lines = raw.splitlines(keepends=True)
    start = lines.index(b'## Task Tree\n') + 1
    result, key = {}, None
    for line in lines[start:]:
        if line.startswith(b'## '):
            break
        match = re.fullmatch(rb'- ID: `([^`]+)`\n', line)
        if match:
            key = match[1].decode()
            assert key not in result
            result[key] = []
        if key is not None:
            result[key].append(line)
        else:
            assert not line.strip()
    return {key: b''.join(value).strip() for key, value in result.items()}


def graph(source, current, owner):
    old, new = nodes(source), nodes(current)
    assert set(old) == set(new)
    for key in old:
        if key != owner:
            assert old[key] == new[key], key
    for field in (b'Goal', b'Acceptance'):
        pattern = rb'(?m)^  ' + field + rb': .*?$'
        assert re.search(pattern, old[owner])[0] == re.search(pattern, new[owner])[0]
    assert b'Status: `done`' in new[owner]
    assert source.split(b'## Task Tree\n', 1)[0] == current.split(b'## Task Tree\n', 1)[0]


def fixture(name, task, manifest, success, diagnostic=None):
    root = ROOT / '.artifacts/coordinate-task-history-rollover-controls-20261009' / name
    for parent in (root, *root.parents):
        if parent == ROOT:
            break
        assert not parent.is_symlink() and not (parent / '.git').exists()
        if parent.exists():
            assert parent.stat().st_dev == ROOT.stat().st_dev
    for relative, raw in ((TASK, task), (HISTORY, manifest),
                          (RETENTION, git('show', REVISION + ':' + RETENTION))):
        destination = root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(raw)
    (root / 'docs/TASK_TREE.md').write_text('# Controlled index\n\n'
        '| Tree | Status | Lane | Frontier | File |\n| --- | --- | --- | --- | --- |\n'
        f'| `{TREE}` | `active` | `fixture` | `rollover` | [task]({TASK}) |\n')
    command = ['perl', 'scripts/check_task_tree_integrity.pl', '--root', str(root.relative_to(ROOT))]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    assert (result.returncode == 0) == success, result.stdout + result.stderr
    if diagnostic is not None:
        assert diagnostic in result.stdout + result.stderr
    return {'case': name, 'command': command, 'status': result.returncode,
            'stdout': result.stdout, 'stderr': result.stderr}


def main():
    proof = json.loads((BASE / 'binding.json').read_bytes())
    owner = (BASE / 'scope.txt').read_text().strip()
    assert proof['revision'] == REVISION and proof['owner'] == owner
    assert proof['verifier'] == pin(Path(__file__).read_bytes())
    after = {}
    for path, identity in proof['afterimages'].items():
        raw = git('cat-file', 'blob', identity['blob'])
        assert pin(raw) == identity['pin']
        after[path] = raw
    registry, record = list(map(json.loads, after[HISTORY].splitlines()))
    assert record['source_revision'] == REVISION and record['source_path'] == TASK
    assert record['start_heading'] == BOUNDARY
    source, suffix = history(record)
    native = subprocess.check_output(['perl', '-MJSON::PP', '-MDigest::SHA=sha256_hex', '-e',
        r'''local $/; binmode STDIN; my $s=<STDIN>; my $n="## $ARGV[0]\n";
        my $h=substr($s,index($s,$n)); my $sl=()=$s=~/\n/g; my $hl=()=$h=~/\n/g;
        my $hs=()=$h=~/^## /mg; print encode_json({source_sha256=>sha256_hex($s),
        source_bytes=>length($s),source_lines=>$sl,history_sha256=>sha256_hex($h),
        history_bytes=>length($h),history_lines=>$hl,history_sections=>$hs});''',
        BOUNDARY], input=source)
    for key, value in json.loads(native).items():
        assert type(record[key]) is type(value) and record[key] == value
    previous_manifest = git('show', REVISION + ':' + HISTORY)
    assert registry == json.loads(previous_manifest.splitlines()[0])
    chain, seen, cursor = [], set(), previous_manifest
    while True:
        old_registry, old_record = list(map(json.loads, cursor.splitlines()))
        revision = old_record['source_revision']
        assert revision not in seen
        seen.add(revision)
        old_source, old_suffix = history(old_record)
        chain.append({'revision': revision, 'source': pin(old_source), 'suffix': pin(old_suffix), 'manifest': pin(cursor)})
        run = subprocess.run(['git', '--no-replace-objects', 'show', revision + ':' + HISTORY],
                             cwd=ROOT, capture_output=True)
        if run.returncode:
            assert ('- Acceptance history manifest: `' + HISTORY + '`').encode() not in old_source
            break
        cursor = run.stdout
    graph(source, after[TASK], owner)
    assert ('## ' + BOUNDARY + '\n').encode() not in after[TASK]
    view = b'## Version-Retrievable Historical Views\n'
    old_view = source[source.index(view):]
    expected_view = old_view.replace(b'scripts/check_task_tree_integrity.pl\n',
        b'scripts/check_task_tree_integrity.pl\npython3 -B docs/audits/coordinate-task-history-rollover-20261009/verify.py\n', 1)
    assert after[TASK][after[TASK].index(view):] == expected_view
    controls = [fixture('qualified', after[TASK], after[HISTORY], True)]
    for name, key, value, diagnostic in (
        ('source_digest', 'source_sha256', '0' * 64, 'source digest mismatch'),
        ('suffix_digest', 'history_sha256', '0' * 64, 'suffix digest mismatch'),
        ('string_dimension', 'source_lines', str(record['source_lines']), 'source_lines'),
        ('absent_heading', 'start_heading', 'Absent History Boundary', 'absent or duplicated'),
    ):
        candidate = copy.deepcopy(record)
        candidate[key] = value
        raw = b''.join(json.dumps(row, sort_keys=True).encode() + b'\n' for row in (registry, candidate))
        controls.append(fixture(name, after[TASK], raw, False, diagnostic))
    controls.append(fixture('displaced_pointer', after[TASK].replace(view, b'## Displaced Historical Views\n', 1),
                            after[HISTORY], False, 'live heading'))
    bad = after[TASK].replace(b'- ID: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4`', b'- ID: `lost`', 1)
    try:
        graph(source, bad, owner)
    except AssertionError:
        controls.append({'case': 'lost_live_contract', 'rejected': True})
    else:
        raise AssertionError('lost live contract accepted')
    transform = json.loads((BASE / 'book-transform.json').read_bytes())
    paths = sorted(p for p in after if re.fullmatch(r'docs/book/src/[^/]+\.md', p))
    fixed_paths = git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src', 'docs/tasks').decode().splitlines()
    assert paths == sorted(p for p in fixed_paths if re.fullmatch(r'docs/book/src/[^/]+\.md', p))
    assert proof['task_paths'] == sorted(p for p in fixed_paths if re.fullmatch(
        r'docs/tasks/(?:[^/]+|segments/[^/]+/[^/]+)\.md', p))
    original = [git('show', REVISION + ':' + p) for p in paths]
    current = [after[p] for p in paths]
    assert [p for p, a, b in zip(paths, original, current) if a != b] == [BOOK]
    old_book = original[paths.index(BOOK)]
    assert old_book.count(transform['old'].encode()) == 1
    assert old_book.replace(transform['old'].encode(), transform['new'].encode(), 1) == after[BOOK]
    prior_rows = list(map(json.loads, git('show', REVISION + ':' + SURFACES).splitlines()))
    rows = list(map(json.loads, after[SURFACES].splitlines()))
    assert len(rows) == len(prior_rows)
    for prior, row in zip(prior_rows, rows):
        expected = copy.deepcopy(prior)
        if row.get('surface_id') == 'task_evidence':
            expected['state'] = 'warning_debt'
            expected['transition']['max_growth'] = row['transition']['max_growth']
            raw = [after[p] for p in proof['task_paths']]
            actual = {'files': len(raw), 'bytes_total': sum(map(len, raw)),
                'lines_total': sum(x.count(b'\n') for x in raw), 'bytes_each': max(map(len, raw)),
                'lines_each': max(x.count(b'\n') for x in raw),
                'line_bytes_each': max(len(line.rstrip(b'\r')) for x in raw for line in x.split(b'\n'))}
            for key, value in actual.items():
                wanted = max(0, min(value + prior['transition']['ratchet_step'][key], prior['enforcement_ceilings'][key]) - prior['baseline'][key])
                assert row['transition']['max_growth'][key] == wanted <= prior['transition']['max_growth'][key]
        if row.get('surface_id') == 'shipped_behavior':
            expected['reference_contract']['aggregate_change'] = row['reference_contract']['aggregate_change']
            change = row['reference_contract']['aggregate_change']
            metric = lambda values: {'files': len(values), 'bytes_total': sum(map(len, values)), 'lines_total': sum(x.count(b'\n') for x in values)}
            a, b = metric(original), metric(current)
            assert change['owner'] == owner and change['baseline'] == a
            assert change['delta'] == {key: b[key] - a[key] for key in a}
        assert row == expected, row.get('surface_id', 'collection-header')
    print(json.dumps({'result': 'PASS exact closed-history rollover, retained chain, live graph and real gate controls',
        'source': pin(source), 'suffix': pin(suffix), 'history_chain': chain, 'controls': controls,
        'scope': 'Task containment only; whole independent coordinate qualification remains pending.'}, sort_keys=True))


if __name__ == '__main__':
    main()
