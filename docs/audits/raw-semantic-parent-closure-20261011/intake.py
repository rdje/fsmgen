"""Bind complete unchanged original source namespaces to committed Git bodies."""
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys

from capture import BASE, canonical, save

sys.path.insert(0, 'scripts')
import restore_record_value_gate_streams as recovery


def need(condition, message):
    if not condition:
        raise ValueError(message)


def derive():
    plan = json.loads((BASE / 'plan.json').read_bytes())
    original = json.loads(Path('docs/audits/raw-semantic-reader-completion-20261011/intake-before.json').read_bytes())
    selected = set(original['roots']) | {
        'docs/audits/raw-semantic-acceptance-20261011',
        'docs/audits/raw-semantic-reader-completion-20261011', plan['checkpoint'], plan['recovery']}
    roots = sorted(n for n in selected if not any(n.startswith(other + '/') for other in selected if n != other))
    result = subprocess.run(['git', '--no-replace-objects', '--literal-pathspecs', 'ls-tree',
                             '-r', '-z', plan['revision'], '--', *roots], capture_output=True)
    need(result.returncode == 0 and result.stderr == b'', 'complete own fixed Git source population')
    entries = {}
    for record in result.stdout.rstrip(b'\0').split(b'\0'):
        header, name = record.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        name = name.decode()
        need(mode in ('100644', '100755') and kind == 'blob' and name not in entries, 'ordinary unique original source member')
        entries[name] = dict(mode=mode, oid=oid)
    need(all(any(n == root or n.startswith(root + '/') for n in entries) for root in roots),
         'every original source root has complete fixed members')
    wanted_dirs = {str(p) for name in entries for p in Path(name).parents
                   if any(str(p) == root or str(p).startswith(root + '/') for root in roots if root not in entries)}
    files, directories = set(), set()
    for root in roots:
        if root in entries:
            recovery.local(recovery.relative(root))
            files.add(root)
            continue
        for directory, children, names in os.walk(recovery.local(recovery.relative(root)), followlinks=False):
            relative = Path(directory).relative_to(recovery.REPO)
            recovery.local(relative)
            directories.add(str(relative))
            for child in children:
                recovery.local(relative / child)
            for name in names:
                member = relative / name
                recovery.local(member)
                files.add(str(member))
    need(files == set(entries) and directories == wanted_dirs, 'whole unchanged source file and directory membership')
    process = subprocess.Popen(['git', '--no-replace-objects', 'cat-file', '--batch'],
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    members = {}
    try:
        for name, entry in sorted(entries.items()):
            path = recovery.local(recovery.relative(name))
            before = path.stat()
            need(stat.S_ISREG(before.st_mode) and bool(before.st_mode & 0o111) == (entry['mode'] == '100755'), 'whole original source mode')
            process.stdin.write(entry['oid'].encode() + b'\n')
            process.stdin.flush()
            header = process.stdout.readline().split()
            need(len(header) == 3 and header[0].decode() == entry['oid'] and header[1] == b'blob', 'complete staged Git blob header')
            remaining = int(header[2])
            digest = hashlib.sha256()
            with path.open('rb') as current:
                while remaining:
                    chunk = process.stdout.read(min(remaining, 1048576))
                    need(chunk and current.read(len(chunk)) == chunk, 'whole current source equals fixed Git bytes')
                    digest.update(chunk)
                    remaining -= len(chunk)
                need(current.read(1) == b'' and process.stdout.read(1) == b'\n', 'exact complete original source and Git EOF')
            after = path.stat()
            need((before.st_ino, before.st_dev, before.st_size, before.st_mtime_ns) ==
                 (after.st_ino, after.st_dev, after.st_size, after.st_mtime_ns), 'stable whole original source epoch')
            members[name] = dict(**entry, bytes=before.st_size, sha256=digest.hexdigest())
        process.stdin.close()
        need(process.stderr.read() == b'' and process.wait() == 0 and process.stdout.read(1) == b'', 'complete own Git batch terminal')
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
    return dict(revision=plan['revision'], roots=roots, members=members, directories=sorted(directories),
                condition='Complete committed original source/native/product/checkpoint/recovery namespaces; no ignored streams, original reader execution or native/private promotion.')


if __name__ == '__main__':
    need(sys.argv[1:] in (['--first'], ['--after']), 'one explicit current source binding role')
    result = derive()
    save('intake-' + sys.argv[1][2:] + '.json', result)
    print('PASS complete unchanged original source, mode, file/directory and committed evidence custody.')
