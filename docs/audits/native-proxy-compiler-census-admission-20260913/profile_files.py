"""Independent complete-node census; compiler activity must have settled first."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import stat

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PLAN = json.loads((BASE / 'plan.json').read_bytes())
READER = BASE.parent / 'native-proxy-wrapper-compatibility-20260913/files.py'
spec = importlib.util.spec_from_file_location('qualified_wrapper_file_reader', READER)
qualified = importlib.util.module_from_spec(spec)
spec.loader.exec_module(qualified)


def stable(s):
    return (s.st_dev, s.st_ino, s.st_mode, s.st_nlink, s.st_uid,
            s.st_size, s.st_mtime_ns, s.st_ctime_ns)


def read_node(relative):
    if len(relative.encode('ascii')) > PLAN['evidence_limits']['root_relative_path_bytes']:
        raise ValueError('independent path evidence bound')
    path = ROOT / relative
    qualified.direct(path)
    before = path.lstat()
    if stat.S_ISLNK(before.st_mode):
        assert before.st_dev == ROOT.stat().st_dev and before.st_uid == os.getuid() and before.st_nlink == 1
        target = os.readlink(path)
        assert len(os.fsencode(target)) <= 4096 and stable(path.lstat()) == stable(before)
        return dict(kind='symlink', device=before.st_dev, inode=before.st_ino,
                    uid=before.st_uid, mode=stat.S_IMODE(before.st_mode), links=before.st_nlink,
                    target=target)
    # Reuse the already qualified no-follow, same-volume, stable descriptor
    # reader. Its extra boundary byte is evidence only, not retirement policy.
    node = qualified.node(relative)
    assert stable(path.lstat()) == stable(before)
    node['links'] = before.st_nlink
    if node['kind'] == 'file':
        assert node['links'] == 1
    return node


def walk(root, get_node=read_node, list_names=None):
    if root not in {case['workspace'] for case in PLAN['cases']}:
        raise ValueError('undeclared compiler-profile root')
    if list_names is None:
        list_names = lambda path: sorted(os.listdir(ROOT / path))
    nodes = {}
    total = 0

    def visit(path, depth):
        nonlocal total
        if depth > PLAN['evidence_limits']['depth'] or len(nodes) >= PLAN['evidence_limits']['nodes']:
            raise ValueError('independent census node/depth bound')
        node = get_node(path)
        nodes[path] = node
        if node['kind'] == 'file':
            if not 0 <= node['size_bytes'] <= PLAN['evidence_limits']['independent_file_bytes']:
                raise ValueError('independent census per-file bound')
            total += node['size_bytes']
            if total > PLAN['evidence_limits']['total_file_bytes']:
                raise ValueError('independent census byte bound')
        elif node['kind'] == 'directory':
            names = list_names(path)
            if names != sorted(set(names)) or len(names) > PLAN['evidence_limits']['nodes']:
                raise ValueError('independent census membership ambiguity')
            for name in names:
                if not re.fullmatch(r'[A-Za-z0-9_.-]+', name) or name in ('.', '..'):
                    raise ValueError('independent census member spelling')
                visit(path + '/' + name, depth + 1)
            if list_names(path) != names or get_node(path) != node:
                raise ValueError('independent directory changed during census')
        elif node['kind'] != 'symlink':
            raise ValueError('independent census node type')

    visit(root, 0)
    return nodes


def capture(root):
    before = walk(root)
    if walk(root) != before:
        raise ValueError('independent full workspace closure changed')
    return before


def compare_prototype(root, nodes, prototype, file_bytes):
    seen = set()
    total = 0
    for entry in prototype:
        path = entry['identity']['path']
        if path in seen or path not in nodes:
            raise ValueError('prototype duplicate or unknown node')
        seen.add(path)
        actual = nodes[path]
        if entry['kind'] != actual['kind']:
            raise ValueError('prototype node kind differs')
        identity = {key: actual[key] for key in ['device', 'inode', 'mode', 'uid']}
        if entry['identity'] != dict(path=path, **identity):
            raise ValueError('prototype node identity differs')
        if entry['kind'] == 'file':
            raw = entry['bytes'].encode('latin1')
            if len(raw) != actual['size_bytes'] or hashlib.sha256(raw).hexdigest() != actual['sha256']:
                raise ValueError('prototype complete file bytes differ')
            if actual['links'] != 1:
                raise ValueError('prototype file aliases are not private custody')
            total += len(raw)
        elif entry['kind'] == 'symlink':
            if entry['target'] != actual['target'] or actual['links'] != 1:
                raise ValueError('prototype link target or custody differs')
    if seen != set(nodes) or root not in seen or total != file_bytes:
        raise ValueError('prototype full membership or aggregate differs')
    return dict(nodes=len(nodes), file_bytes=total,
        depth=max(len(Path(path).relative_to(root).parts) for path in nodes),
        maximum_file_bytes=max((n['size_bytes'] for n in nodes.values() if n['kind'] == 'file'), default=0),
        files=sum(n['kind'] == 'file' for n in nodes.values()),
        directories=sum(n['kind'] == 'directory' for n in nodes.values()),
        symlinks=sum(n['kind'] == 'symlink' for n in nodes.values()))


def deletion_projection(nodes):
    # Directory link counts naturally change during removal of their known
    # children. Record each observed count; immutable custody still binds the
    # directory inode/mode/owner and its complete remaining membership.
    return {path: {k: v for k, v in node.items() if not (node['kind'] == 'directory' and k == 'links')}
            for path, node in nodes.items()}
