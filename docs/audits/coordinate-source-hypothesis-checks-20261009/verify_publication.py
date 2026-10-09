"""Independently qualify scoped book publication and complete native receipts."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-source-hypothesis-checks-20261009')
REVISION = 'f5d2e81710ddbd2dd10f406551220d1a5ff2c32a'
CHAPTER = 'docs/book/src/90-reference-map.md'
OLD = b'Whole source-hypothesis publication and original-coordinate joining remain\npending, with original private runtime meanings and alias downstream still\nowned separately. The binding establishes source hypotheses, without choosing\nwhich line or filename an original runtime actually reported.\n'
NEW = b'Original-coordinate joining remains pending, with original private runtime\nmeanings and alias downstream still owned separately. The binding establishes\nsource hypotheses, without choosing which line or filename an original\nruntime actually reported.\n'


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def git(*args):
    run = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(run.returncode == 0 and not run.stderr, 'independent complete native publication source')
    return run.stdout


def counts(rows):
    need(all(raw.endswith(b'\n') for raw in rows), 'complete publication source line endings')
    return {'files': len(rows), 'lines_total': sum(len(raw.splitlines(keepends=True)) for raw in rows),
            'bytes_total': sum(map(len, rows))}


def expectation():
    paths = sorted(p for p in git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                   if Path(p).parent == Path('docs/book/src') and p.endswith('.md'))
    need(paths == sorted(str(p) for p in Path('docs/book/src').glob('*.md')), 'complete independent book source membership')
    previous = [git('show', REVISION + ':' + p) for p in paths]
    current = [Path(p).read_bytes() for p in paths]
    need([p for p, a, b in zip(paths, previous, current) if a != b] == [CHAPTER], 'unique whole-book publication change')
    old, new = previous[paths.index(CHAPTER)], current[paths.index(CHAPTER)]
    start = new.index(b'The complete source-hypothesis qualification')
    end = new.index(b'<div id="knowledge-map-architecture">', start)
    need(new.count(NEW) == 1 and (new[:start] + new[end:]).replace(NEW, OLD) == old,
         'whole independently reversible book publication')
    surface = next(json.loads(row) for row in Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()
                   if json.loads(row).get('surface_id') == 'task_evidence')
    files = sorted({p for pattern in surface['targets'] for p in Path('.').glob(pattern)})
    rows = [p.read_bytes() for p in files]
    metrics = {**counts(rows), 'lines_each': max(len(r.splitlines(keepends=True)) for r in rows),
               'bytes_each': max(map(len, rows)),
               'line_bytes_each': max(len(line.rstrip(b'\r')) for raw in rows for line in raw.split(b'\n'))}
    return {'revision': REVISION, 'source': CHAPTER, 'before': pin(old), 'after': pin(new),
            'addition': new[start:end].decode(), 'book_before': counts(previous), 'book_after': counts(current),
            'owner': Path('docs/audits/coordinate-source-hypotheses-20261009/scope.txt').read_text().strip(),
            'previous_registry': pin(git('show', REVISION + ':doctrine/live_document_size/surfaces.jsonl')),
            'task_metrics': metrics}


def check(actual, expected):
    for key in expected:
        need(same(actual[key], expected[key]), 'complete source publication field: ' + key)


def main():
    expected = expectation()
    actual = json.loads((BASE / 'publication.json').read_bytes())
    check(actual, expected)
    controls = {}
    for name, change, field in (
        ('borrowed-source', lambda p:p.update(before=p['after']), 'before'),
        ('omitted-addition', lambda p:p.update(addition=''), 'addition'),
        ('Boolean-book-count', lambda p:p['book_after'].update(files=True), 'book_after'),
        ('borrowed-owner', lambda p:p.update(owner='foreign'), 'owner'),
        ('wrong-task-bytes', lambda p:p['task_metrics'].update(bytes_total=0), 'task_metrics')):
        bad = copy.deepcopy(actual)
        change(bad)
        try:
            check(bad, expected)
        except ValueError as error:
            need(str(error) == 'complete source publication field: ' + field, 'intended source-publication predicate')
            controls[name] = str(error)
        else:
            raise ValueError('false-green source publication: ' + name)
    checks = json.loads((BASE / 'checks.json').read_bytes())
    commands = {
        'source-current': ['python3', '-B', 'scripts/book_source_references.py', '--check'],
        'book-build': ['mdbook', 'build', 'docs/book'],
        'native-staged': ['python3', '-B', 'scripts/book_source_references.py', '--check', '--verify-build', 'docs/book/book'],
        'current-native': ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', 'docs/book/book']}
    for name, command in commands.items():
        row = checks[name]
        need(type(row['status']) is int and row['status'] == 0
             and row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command], 'complete actual native publication receipt')
        required = {str(BASE / 'checks.py'), 'scripts/run_with_ram_guard.sh'} | {arg for arg in command if Path(arg).is_file()}
        need(same(row['instruments'], {p: pin(Path(p).read_bytes()) for p in required}), 'complete actual native publication instruments')
        need(type(row['stdout']) is str and type(row['stderr']) is str, 'complete actual native publication streams')
    for name in ('source-current', 'native-staged'):
        need(checks[name]['stdout'] == 'book-source-references: complete source/role/member/relative-endpoint/current-byte/ignore contracts hold\n',
             'complete actual copied-source qualification')
    need(checks['current-native']['stdout'] == 'PASS current class/frame facts, complete current source/query allocation and unchanged capacity/source contracts.\n',
         'complete actual current source/query/native qualification')
    print(json.dumps({'result': 'PASS whole source/native book publication and actual receipts', 'controls': controls}, sort_keys=True))


if __name__ == '__main__':
    main()
