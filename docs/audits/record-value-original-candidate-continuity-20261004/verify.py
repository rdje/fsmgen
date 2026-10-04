"""Exact history retrieval and complete live-node preservation for the split."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-candidate-continuity-20261004')
PARENT = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def identity(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'), 'sha256': hashlib.sha256(raw).hexdigest()}


def get(revision, path):
    return subprocess.check_output(['git', 'show', revision + ':' + path])


def afterimage(role, path):
    row = json.loads((BASE / 'afterimages.json').read_text())[role]
    require(row['path'] == path and row['retention_contract'] == 'fsmgen_required_history',
            'captured afterimage role/retention authority')
    raw = subprocess.check_output(['git', 'cat-file', 'blob', row['object']])
    require(identity(raw) == row['identity'], 'exact captured afterimage identity')
    return raw


def history(record):
    source = get(record['source_revision'], record['source_path'])
    for key, value in identity(source).items():
        require(record['source_' + key] == value, 'complete historical source identity')
    needle = ('## ' + record['start_heading'] + '\n').encode()
    require(source.count(needle) == 1, 'unique historical suffix boundary')
    suffix = source[source.index(needle):]
    for key, value in identity(suffix).items():
        require(record['history_' + key] == value, 'exact historical suffix identity')
    require(record['history_sections'] == len(re.findall(rb'^## ', suffix, re.M)), 'history section closure')
    require(record['retention_contract'] == 'fsmgen_required_history', 'retention authority')
    return source


def nodes(raw):
    start = raw.index(b'## Task Tree\n')
    end = raw.index(b'\n## ', start + 1)
    graph = raw[start:end]
    matches = list(re.finditer(rb'^- ID: `([^`]+)`\n', graph, re.M))
    result = {}
    for index, match in enumerate(matches):
        owner = match[1].decode()
        require(owner not in result, 'unique live node identity')
        stop = matches[index + 1].start() if index + 1 < len(matches) else len(graph)
        result[owner] = graph[match.start():stop].strip()
    return result


def check():
    binding = json.loads((BASE / 'binding.json').read_text())
    source = get(binding['revision'], binding['task_path'])
    require(identity(source) == binding['source'], 'exact predecessor source')
    old_manifest = get(binding['revision'], binding['manifest_path'])
    require(old_manifest.decode() == binding['previous_manifest'], 'complete prior manifest authority')
    require(json.loads(old_manifest.splitlines()[1]) == binding['prior'], 'prior history authority')
    history(binding['prior'])
    current = json.loads(afterimage('manifest', binding['manifest_path']).splitlines()[1])
    retained = history(current)
    require(retained == source and current['source_revision'] == binding['revision'], 'exact selected predecessor')
    require(current['start_heading'] == binding['suffix']['start_heading'], 'selected history boundary')
    old, live = nodes(source), nodes(afterimage('task', binding['task_path']))
    require(set(live) == set(old) | {PARENT + '.' + str(i) for i in range(1, 5)}, 'complete original plus four-child node domain')
    for owner in old:
        if owner != PARENT:
            require(old[owner] == live[owner], 'unchanged whole original node: ' + owner)
    require(b'  Status: `active`' in live[PARENT] and
            all((PARENT + '.' + str(i)).encode() in live[PARENT] for i in range(1, 5)), 'exact original-input container split')
    require(all(b'  Status: `pending`' in live[PARENT + '.' + str(i)] for i in range(2, 5)), 'unimplemented successors stay pending')
    inputs = json.loads(Path('docs/audits/record-value-copy-inputs-20261004/inputs.json').read_text())
    require(binding['original_input_indices'] == [r['index'] for r in inputs['rows']], 'complete original-copy population retained')
    controls = []
    for field in ('source_sha256', 'history_sha256'):
        bad = copy.deepcopy(current)
        bad[field] = '0' * 64
        try:
            history(bad)
        except ValueError as error:
            controls.append({'control': field, 'status': 1, 'error': str(error), 'record': bad})
        else:
            raise ValueError('false-green history control')
    require(json.loads((BASE / 'controls.json').read_text()) == controls, 'actual source/suffix RED records')
    book_proof = json.loads((BASE / 'book-transform.json').read_text())
    book = get(book_proof['revision'], book_proof['path'])
    require(hashlib.sha256(book).hexdigest() == book_proof['before_sha256'], 'original book authority')
    for edit in book_proof['replacements']:
        before, after = edit['before'].encode(), edit['after'].encode()
        require(book.count(before) == 1, 'book transformation population')
        book = book.replace(before, after)
    require(hashlib.sha256(book).hexdigest() == book_proof['after_sha256'], 'complete book transformation')
    manifest = json.loads((BASE / 'manifest.json').read_text())
    require({p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}, 'complete continuity archive')
    for name, row in manifest.items():
        raw = (BASE / name).read_bytes()
        require({'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()} == row, 'continuity member identity')
    print('PASS exact predecessor/suffix/prior-manifest retrieval and every original live node; bounded split only.')


if __name__ == '__main__':
    check()
