"""Exact dated inputs for SEM.83; all project data stays repository-local."""
import base64
import gzip
import hashlib
import json
import re
import stat
import subprocess
from pathlib import Path

BASE = Path('docs/audits/task-terminal-rollover-20261011')
SCRATCH = Path('.artifacts/task-terminal-rollover-20261011')
REVISION = '4e8c45a0a96f9e09aa6a7b5e1438ce3dafbd1980'
TREE = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER'
OWNER = TREE + '.83'
RAW = TREE + '.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2'
ROOTS = (TREE + '.49.2.2', TREE + '.60.4.3.2')
TASK = 'docs/tasks/' + TREE + '.md'
HISTORY = 'docs/tasks/history/' + TREE + '/acceptance-history.jsonl'
RETENTION = 'doctrine/live_document_size/version_retention_contracts.jsonl'
SURFACES = 'doctrine/live_document_size/surfaces.jsonl'
BOOK = 'docs/book/src/90-reference-map.md'
CARD = 'docs/knowledge/task-tree-sealed-segments-and-compact-terminals.md'
CHECKER = 'scripts/check_task_tree_integrity.pl'


def need(condition, message):
    if not condition:
        raise ValueError(message)


def canonical(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False) + '\n').encode()


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def git(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(result.returncode == 0 and result.stderr == b'', 'whole own Git retrieval')
    return result.stdout


def local(path, exists=True):
    root = Path.cwd().resolve()
    path = Path(path)
    need(not path.is_absolute() and '..' not in path.parts, 'repository-relative path')
    for part in (path, *path.parents):
        if part == Path('.'):
            break
        need(not part.is_symlink() and not (part / '.git').exists(), 'own ordinary repository boundary')
        if part.exists():
            need(part.stat().st_dev == root.stat().st_dev, 'same-volume project data')
    if exists:
        need(path.is_file() and stat.S_ISREG(path.lstat().st_mode), 'ordinary complete file')
    return path


def save(path, raw):
    path = local(path, exists=False)
    need(not path.exists(), 'retain first source/result bytes: ' + str(path))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(raw)


def frozen_sources(names):
    output = {}
    process = subprocess.Popen(['git', '--no-replace-objects', 'cat-file', '--batch'],
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        for name in sorted(names):
            need('\n' not in name and ':' not in name and not name.startswith('/'), 'safe Git member')
            process.stdin.write((REVISION + ':' + name + '\n').encode())
            process.stdin.flush()
            header = process.stdout.readline().split()
            need(len(header) == 3 and header[1] == b'blob', 'fixed complete ordinary source')
            raw = process.stdout.read(int(header[2]))
            need(len(raw) == int(header[2]) and process.stdout.read(1) == b'\n', 'whole Git member body')
            output[name] = raw
        process.stdin.close()
        need(process.stderr.read() == b'' and process.wait() == 0 and process.stdout.read(1) == b'',
             'complete fixed Git protocol')
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
    return output


def pack(sources):
    return gzip.compress(canonical({name: base64.b64encode(raw).decode()
                                   for name, raw in sorted(sources.items())}), mtime=0)


def unpack(raw):
    value = json.loads(gzip.decompress(raw))
    need(type(value) is dict and all(type(k) is str and type(v) is str for k, v in value.items()),
         'closed source snapshot shape')
    return {name: base64.b64decode(body, validate=True) for name, body in value.items()}


def nodes(raw):
    marker = b'## Task Tree\n'
    need(raw.count(marker) == 1, 'unique authoritative task section')
    start = raw.index(marker) + len(marker)
    end_match = re.search(rb'^## ', raw[start:], re.M)
    end = start + end_match.start() if end_match else len(raw)
    section = raw[start:end]
    matches = list(re.finditer(rb'^- ID: `([^`]+)`\n', section, re.M))
    need(matches and not section[:matches[0].start()].strip(), 'closed task graph prefix')
    result = {}
    for index, match in enumerate(matches):
        name = match[1].decode()
        need(name not in result, 'unique task node')
        finish = matches[index + 1].start() if index + 1 < len(matches) else len(section)
        result[name] = section[match.start():finish]
    return result


def field(block, key):
    values = re.findall(rb'^  ' + re.escape(key.encode()) + rb': `([^`\n]*)`\n', block, re.M)
    need(len(values) == 1, 'exact single task field: ' + key)
    return values[0].decode()


def selected(name, root):
    return name == root or name.startswith(root + '.')


def owner_census(sources):
    result = []

    def visit(value, path, pointer):
        if type(value) is dict:
            for key, item in value.items():
                part = pointer + '/' + key.replace('~', '~0').replace('/', '~1')
                if 'owner' in key and type(item) is str and re.fullmatch(r'[A-Z][A-Z0-9-]*(?:\.[1-9][0-9]*)*', item):
                    result.append(dict(path=path, pointer=part, key=key, owner=item))
                visit(item, path, part)
        elif type(value) is list:
            for index, item in enumerate(value):
                visit(item, path, pointer + '/' + str(index))

    for path, raw in sorted(sources.items()):
        if not path.startswith('doctrine/') or not path.endswith(('.json', '.jsonl')):
            continue
        values = [json.loads(line) for line in raw.splitlines()] if path.endswith('.jsonl') else json.loads(raw)
        visit(values, path, '')
    return sorted(result, key=lambda row: (row['path'], row['pointer'], row['owner']))


def eligible(graph, root, owners):
    subtree = {name: block for name, block in graph.items() if selected(name, root)}
    need(root in subtree and len(subtree) > 1, 'whole selected subtree exists')
    need(all(field(block, 'Status') in ('done', 'deferred', 'superseded') for block in subtree.values()),
         'selected subtree is terminal')
    need(all(b'  Terminal:' not in block for block in subtree.values()), 'flat original subtree only')
    need(not any(selected(row['owner'], root) for row in owners), 'live registry owner would be hidden')
    need(not selected(RAW, root) and not selected(root, RAW), 'raw acceptance forest stays live')
    return subtree


def terminal(root, source, count):
    goal = field(nodes(source)[root], 'Goal')
    return (f'- ID: `{root}`\n'
            '  Status: `done`\n'
            f'  Goal: `{goal}`\n'
            '  Terminal: `version_object`\n'
            f'  Revision: `{REVISION}`\n'
            f'  Retrieval path: `{TASK}`\n'
            f'  Retrieved SHA256: `{pin(source)["sha256"]}`\n'
            f'  Archived node count: `{count}`\n'
            '  Retention contract: `fsmgen_required_history`\n'
            '  Verification: `Exact full-source retrieval, independent complete subtree reconstruction and genuine native-checker controls are retained in docs/audits/task-terminal-rollover-20261011; every original contract byte remains retrievable.`\n'
            f'  Commit: `{OWNER}: retain exact completed task subtrees`\n\n').encode()


def compact(declared, original, owners):
    graph = nodes(declared)
    result = declared
    for root in ROOTS:
        subtree = eligible(graph, root, owners)
        for name, block in subtree.items():
            need(block == nodes(original)[name], 'all selected original node bytes unchanged')
            result = result.replace(block, terminal(root, original, len(subtree)) if name == root else b'', 1)
    return result


def metrics(sources):
    members = {}
    for name, raw in sorted(sources.items()):
        lines = raw.split(b'\n')
        widths = [len(line[:-1] if index < len(lines) - 1 and line.endswith(b'\r') else line)
                  for index, line in enumerate(lines)]
        members[name] = dict(**pin(raw), lines=raw.count(b'\n'), line_bytes=max(widths, default=0))
    return dict(members=members, metrics=dict(files=len(members),
        bytes_total=sum(row['bytes'] for row in members.values()),
        lines_total=sum(row['lines'] for row in members.values()),
        bytes_each=max(row['bytes'] for row in members.values()),
        lines_each=max(row['lines'] for row in members.values()),
        line_bytes_each=max(row['line_bytes'] for row in members.values())))
