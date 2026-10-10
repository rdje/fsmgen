"""Independent fixed Git binary-object custody, separate from archive producer."""
import hashlib
import json
import subprocess
from pathlib import Path
from common import BASE, DISPLAY, READERS, REVISION, ROLE, load, need, pin, same


def git(*args):
    r = subprocess.run(['git','--no-replace-objects',*args], capture_output=True)
    need(type(r.returncode) is int and r.returncode == 0 and not r.stderr, 'actual independent fixed Git command')
    return r.stdout


def verify():
    saved = load('custody.json')
    selected = set(json.loads(git('show', REVISION + ':' + str(DISPLAY / 'prerequisites.json')))['custody']['roots'])
    selected.add(str(DISPLAY))
    roots = sorted(p for p in selected if not any(p.startswith(q + '/') for q in selected if p != q))
    need(saved['revision'] == REVISION and saved['roots'] == roots, 'entire fixed source/display prerequisite domain')
    tree = git('ls-tree','-rz','--full-tree',REVISION,'--',*roots)
    entries = {}
    for row in tree.split(b'\0'):
        if not row:
            continue
        header, path = row.split(b'\t',1)
        mode, kind, oid = header.decode().split()
        path = path.decode()
        need(kind == 'blob' and mode in ('100644','100755') and path not in entries,
             'unique regular independent fixed member')
        entries[path] = dict(mode=mode, oid=oid)
    need(set(saved['members']) == set(entries), 'complete fixed custody membership')
    child = subprocess.Popen(['git','--no-replace-objects','cat-file','--batch'],
                             stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    products = {}
    try:
        for path, entry in sorted(entries.items()):
            child.stdin.write((entry['oid'] + '\n').encode()); child.stdin.flush()
            header = child.stdout.readline().decode().strip().split()
            need(len(header) == 3 and header[:2] == [entry['oid'],'blob'], 'independent full Git blob header')
            size = int(header[2]); digest = hashlib.sha256()
            object_id = hashlib.sha1(('blob ' + str(size) + '\0').encode())
            file = Path(path); root = Path.cwd().resolve()
            need(file.is_file() and not file.is_symlink() and file.resolve() == root / file
                 and file.stat().st_dev == root.stat().st_dev
                 and ('100755' if file.stat().st_mode & 0o111 else '100644') == entry['mode'],
                 'own same-volume regular source member and mode')
            with file.open('rb') as current:
                remaining = size
                while remaining:
                    raw = child.stdout.read(min(remaining,1024*1024))
                    need(raw and current.read(len(raw)) == raw, 'entire fixed/current source bytes')
                    digest.update(raw); object_id.update(raw); remaining -= len(raw)
                need(not current.read(1), 'complete current source boundary')
            need(child.stdout.read(1) == b'\n' and object_id.hexdigest() == entry['oid'], 'whole independent Git object identity')
            products[path] = dict(**entry, identity=dict(bytes=size,sha256=digest.hexdigest()))
        child.stdin.close()
        need(child.stdout.read() == b'', 'entire independent binary stream')
        error = child.stderr.read(); status = child.wait()
        need(type(status) is int and status == 0 and not error, 'actual independent binary process success')
    finally:
        if child.poll() is None:
            child.kill(); child.wait()
    need(same(products, saved['members']), 'whole independent fixed custody products')
    for target in roots:
        p = Path(target)
        current = {str(q) for q in p.rglob('*') if q.is_file() or q.is_symlink()} if p.is_dir() else {target}
        expected = {q for q in entries if q == target or q.startswith(target + '/')}
        need(current == expected and expected, 'complete current prerequisite namespace')
    transport = saved['transport']
    need(transport == dict(command=['git','--no-replace-objects','-c','tar.umask=0022','--literal-pathspecs',
         'archive','--format=tar',REVISION,'--',*roots],status=0,stderr='') and type(transport['status']) is int,
         'whole actual archive producer receipt')
    receipts = {}
    for name,args in READERS.items():
        r = load('reader-' + name + '.json')
        need(set(r) == {'command','status','stdout','stderr','programme','role'}
             and r['command'] == ['python3','-B',*args] and type(r['status']) is int and r['status'] == 0
             and r['stderr'] == '' and r['stdout'].startswith('PASS ') and r['stdout'].endswith('\n')
             and r['programme'] == pin(Path(args[0]).read_bytes()) and r['role'] == ROLE,
             'complete genuine saved prerequisite execution: ' + name)
        receipts[name] = pin((BASE / ('reader-' + name + '.json')).read_bytes())
    return dict(revision=REVISION, tree=pin(tree), members=products, readers=receipts)
