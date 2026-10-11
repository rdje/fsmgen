"""Finite canonical preparation declarations, complete sources and typed custody."""
import gzip
import io
import json
from pathlib import Path
import re
import subprocess
import sys

from capture import BASE, pin, save

PLAN = json.loads((BASE / 'plan.json').read_bytes())
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
BOOK = 'docs/book/src/13k-isf-feature-support-matrix.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def canonical(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False) + '\n').encode()


def same(left, right):
    return canonical(left) == canonical(right)


def nodes(body):
    starts = list(re.finditer(rb'^- ID: `([^`]+)`\n', body, re.M))
    result = {row[1].decode(): body[row.start():starts[i + 1].start() if i + 1 < len(starts) else len(body)]
              for i, row in enumerate(starts)}
    need(len(result) == len(starts), 'unique complete canonical task graph')
    return result


def field(block, name):
    match = re.search(rb'^  ' + name.encode() + rb': `(.*)`$', block, re.M)
    return match[1].decode() if match else None


def git(*args):
    result = subprocess.run(['git', '--no-replace-objects', '--literal-pathspecs', *args], capture_output=True)
    need(result.returncode == 0 and result.stderr == b'', 'whole read-only fixed canonical Git protocol')
    return result.stdout


def fixed(names):
    names = list(names)
    request = b''.join((PLAN['revision'] + ':' + name + '\n').encode() for name in names)
    result = subprocess.run(['git', '--no-replace-objects', 'cat-file', '--batch'], input=request, capture_output=True)
    need(result.returncode == 0 and result.stderr == b'', 'complete fixed canonical source batch')
    stream, sources = io.BytesIO(result.stdout), {}
    for name in names:
        header = stream.readline().split()
        need(len(header) == 3 and header[1] == b'blob', 'whole declared canonical source header')
        body = stream.read(int(header[2]))
        need(len(body) == int(header[2]) and stream.read(1) == b'\n', 'whole canonical source body and EOF')
        sources[name] = body
    need(stream.read(1) == b'' and len(sources) == len(names), 'complete unique canonical source domain')
    return sources


def canonical_sources():
    names = git('ls-tree', '-r', '--name-only', PLAN['revision'], '--', 'docs/knowledge', 'docs/decisions').decode().splitlines()
    return fixed(name for name in names if name.endswith('.md'))


def metrics(sources):
    rows = [dict(bytes=len(body), lines=body.count(b'\n'), width=max(map(len, body.splitlines()), default=0)) for body in sources.values()]
    return dict(files=len(rows), bytes_total=sum(row['bytes'] for row in rows), lines_total=sum(row['lines'] for row in rows),
                bytes_each=max(row['bytes'] for row in rows), lines_each=max(row['lines'] for row in rows),
                line_bytes_each=max(row['width'] for row in rows))


def load_product(name):
    raw = gzip.decompress((BASE / name).read_bytes())
    value = json.loads(raw)
    need(raw == canonical(value), 'whole canonical compressed preparation product')
    return value


def save_product(name, value):
    path = BASE / name
    need(not path.exists(), 'retain first complete canonical preparation product')
    path.write_bytes(gzip.compress(canonical(value), mtime=0))

