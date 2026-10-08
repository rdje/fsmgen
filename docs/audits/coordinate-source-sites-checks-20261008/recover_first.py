"""Retain exact first sources; task files have no native book-copy endpoint."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-source-sites-checks-20261008')
TASK = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def retain(path, raw):
    if path.exists():
        need(path.is_file() and not path.is_symlink() and path.read_bytes() == raw,
             'exact retained first-source conservation')
    else:
        path.write_bytes(raw)


def first_blob(path, expected=None):
    retained = BASE / ('first-' + path.name + '.txt')
    if retained.exists():
        raw = retained.read_bytes()
    else:
        result = subprocess.run(['git', '--no-replace-objects', 'show', ':' + str(path)], capture_output=True)
        need(result.returncode == 0 and not result.stderr, 'complete first staged Git source')
        raw = result.stdout
    need(expected is None or pin(raw) == expected, 'exact first actual instrument identity')
    retain(retained, raw)
    return retained, raw


def metrics(rows):
    return {'files': len(rows), 'lines_total': sum(raw.count(b'\n') for raw in rows),
            'bytes_total': sum(map(len, rows)), 'lines_each': max(raw.count(b'\n') for raw in rows),
            'bytes_each': max(map(len, rows)),
            'line_bytes_each': max(len(line.rstrip(b'\r')) for raw in rows for line in raw.split(b'\n'))}


def check_sources(sources, expected):
    need(json.dumps(sources, sort_keys=True) == json.dumps(expected, sort_keys=True),
         'complete exact first continuity-source binding')


def main():
    results = json.loads((BASE / 'checks.json').read_bytes())
    interrupted = BASE / 'interrupted-recover_first.py.txt'
    need(pin(interrupted.read_bytes()) == results['recover-first-interrupted']['instruments'][str(BASE / 'recover_first.py')],
         'exact interrupted recovery programme identity')
    need(type(results['recover-first-interrupted']['status']) is int
         and results['recover-first-interrupted']['status'] != 0
         and 'FileNotFoundError' in results['recover-first-interrupted']['stderr']
         and str(TASK.with_suffix('.markdown.source.txt')) in results['recover-first-interrupted']['stderr'],
         'complete original unavailable native task-copy failure')
    reader = BASE / 'verify_publication.py'
    expected_reader = results['publication-independent']['instruments'][str(reader)]
    retained_reader, raw_reader = first_blob(reader, expected_reader)
    sources = {}
    for logical, native in (
        ('MEMORY.md', 'MEMORY.markdown.source.txt'),
        ('docs/TASK_TREE.md', 'docs/TASK_TREE.markdown.source.txt'),
    ):
        endpoint = Path('.artifacts/coordinate-source-sites-book/reference-source', native)
        retained = BASE / ('first-' + Path(logical).name + '.txt')
        raw = retained.read_bytes() if retained.exists() else endpoint.read_bytes()
        if endpoint.exists():
            need(endpoint.read_bytes() == raw, 'unchanged first native continuity bytes')
        retain(retained, raw)
        sources[logical] = {'retained': str(retained), 'identity': pin(raw), 'origin': str(endpoint)}
    retained_task, raw_task = first_blob(TASK)
    sources[str(TASK)] = {'retained': str(retained_task), 'identity': pin(raw_task),
                          'origin': 'first staged Git task blob; no native book-copy endpoint'}
    first = json.loads((BASE / 'first-publication.json').read_bytes())
    registry = [json.loads(line) for line in Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()]
    surface = next(row for row in registry if row.get('surface_id') == 'task_evidence')
    paths = sorted({path for pattern in surface['targets'] for path in Path('.').glob(pattern)})
    measured = metrics([raw_task if path == TASK else path.read_bytes() for path in paths])
    need(json.dumps(measured, sort_keys=True) == json.dumps(first['task_metrics'], sort_keys=True),
         'complete first staged task population and publication metrics')
    controls = []
    for name, change in (
        ('missing-task', lambda p: p.pop(str(TASK))),
        ('borrowed-task', lambda p: p[str(TASK)].update(identity=p['MEMORY.md']['identity'])),
        ('invented-native-task', lambda p: p[str(TASK)].update(origin='native book-copy endpoint')),
    ):
        candidate = copy.deepcopy(sources)
        change(candidate)
        try:
            check_sources(candidate, sources)
        except ValueError as error:
            need(str(error) == 'complete exact first continuity-source binding', 'intended first-source refusal')
            controls.append({'name': name, 'status': 'refused', 'cause': str(error)})
        else:
            raise ValueError('false-green first-source recovery control')
    binding = {'first_publication': pin((BASE / 'first-publication.json').read_bytes()),
               'first_reader': {'retained': str(retained_reader), 'identity': pin(raw_reader)},
               'sources': sources, 'task_metrics': measured, 'controls': controls,
               'interrupted_programme': {'retained': str(interrupted), 'identity': pin(interrupted.read_bytes())},
               'role': 'Historical first publication only; current publication uses the superseding sealed reader.'}
    retain(BASE / 'first-publication-binding.json', (json.dumps(binding, sort_keys=True, indent=2) + '\n').encode())
    print('PASS exact first instrument/native continuity/staged task sources, publication metrics and genuine recovery controls; missing native task endpoint stays explicit.')


if __name__ == '__main__':
    main()
