"""Complete required archive Git custody; no semantic or original native promotion."""
import hashlib
import gzip
import json
import stat
import subprocess
from pathlib import Path

BASE = Path('docs/audits/raw-semantic-archive-durability-20261011')
PRIOR = Path('docs/audits/raw-semantic-association-product-20261011')
REVISION = '8bdb1878533486e5e1887720d6ca671cdef0dc3c'
TREE = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER'
RAW = TREE + '.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2'
OWNER = RAW + '.5.2.2.1.1'
TASK = 'docs/tasks/' + TREE + '.md'
SCOPE = ('Complete required recovery-archive Git custody repair only. Exact source/native/product/programme bytes '
         'and all original Goal/Acceptance clauses conserve. Independent full semantic reconstruction remains .5.2.2.2; '
         'native/private/identity/cause/consumer/alias/cold/permanent/visual/HIAL/full-CI/push scopes remain open.')


def need(condition, message):
    if not condition:
        raise ValueError(message)


def canonical(value):
    return (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False) + '\n').encode()


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def local(path, exists=True):
    path = Path(path)
    root = Path.cwd().resolve()
    need(not path.is_absolute() and not {'..', '.git'}.intersection(path.parts), 'own relative admission path')
    for part in (path, *path.parents):
        if part == Path('.'):
            break
        need(not part.is_symlink() and not (part / '.git').exists(), 'plain own admission boundary before writes')
        if part.exists():
            need(part.stat().st_dev == root.stat().st_dev, 'same-volume admission data')
    if exists:
        need(path.is_file() and stat.S_ISREG(path.lstat().st_mode), 'complete ordinary admission member')
    return path


def save(name, value):
    path = local(BASE / name, exists=False)
    need(not path.exists(), 'retain complete first admission source/result: ' + name)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(canonical(value))


def load(name):
    raw = local(BASE / name).read_bytes()
    value = json.loads(raw)
    need(raw == canonical(value), 'whole canonical admission record')
    return value


def save_product(name, value):
    path = local(BASE / name, exists=False)
    need(not path.exists(), 'retain complete first compressed candidate: ' + name)
    path.write_bytes(gzip.compress(canonical(value), mtime=0))


def product(name):
    raw = gzip.decompress(local(BASE / name).read_bytes())
    value = json.loads(raw)
    need(raw == canonical(value), 'whole canonical decompressed candidate')
    return value


def git(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(type(result.returncode) is int and result.returncode == 0 and result.stderr == b'', 'complete own Git protocol')
    return result.stdout


def identity(path):
    path = local(path)
    before = path.stat()
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        while chunk := stream.read(1048576):
            digest.update(chunk)
    after = path.stat()
    need((before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) ==
         (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns), 'whole admission file epoch conserved')
    return dict(bytes=before.st_size, sha256=digest.hexdigest(), executable=bool(before.st_mode & 0o111))


def programs():
    return {str(path): dict(body=(raw := local(path).read_bytes()).decode(), identity=pin(raw))
            for path in sorted(BASE.iterdir()) if path.suffix in ('.py', '.pl')}


def fixed_sources(names):
    process = subprocess.Popen(['git', '--no-replace-objects', 'cat-file', '--batch'],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    result = {}
    try:
        for name in sorted(names):
            need('\n' not in name and ':' not in name and not name.startswith('/'), 'safe complete Git source member')
            process.stdin.write((REVISION + ':' + name + '\n').encode())
            process.stdin.flush()
            header = process.stdout.readline().split()
            need(len(header) == 3 and header[1] == b'blob', 'complete fixed source blob')
            raw = process.stdout.read(int(header[2]))
            need(len(raw) == int(header[2]) and process.stdout.read(1) == b'\n', 'whole source blob body')
            result[name] = raw
        process.stdin.close()
        need(process.stderr.read() == b'' and process.wait() == 0 and process.stdout.read(1) == b'', 'whole Git source protocol')
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
    return result


def metrics(sources):
    rows = {}
    for name, raw in sources.items():
        lines = raw.split(b'\n')
        widths = [len(line[:-1] if index < len(lines)-1 and line.endswith(b'\r') else line)
                  for index, line in enumerate(lines)]
        rows[name] = dict(**pin(raw), lines=raw.count(b'\n'), line_bytes=max(widths, default=0))
    return dict(members=rows, metrics=dict(files=len(rows), bytes_total=sum(r['bytes'] for r in rows.values()),
        lines_total=sum(r['lines'] for r in rows.values()), bytes_each=max(r['bytes'] for r in rows.values()),
        lines_each=max(r['lines'] for r in rows.values()), line_bytes_each=max(r['line_bytes'] for r in rows.values())))
