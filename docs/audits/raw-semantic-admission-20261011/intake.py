"""Stream every complete fixed Git member and independently check directory closure."""
import os
import stat
import subprocess
from pathlib import Path
from common import *


def fixed_json(path):
    return json.loads(git('show', REVISION + ':' + str(path)))


def roots():
    selected = set(fixed_json(PRIOR / 'intake-qualified.json')['roots'])
    selected.update(str(path) for path in (PRIOR,
        Path('docs/audits/raw-stack-prerequisite-gate-repair-20261011'),
        Path('docs/audits/task-terminal-rollover-20261011')))
    selected.add('docs/audits/coordinate-public-route-checks-20261008/drafts.tar.gz')
    return sorted(path for path in selected if not any(path.startswith(other + '/') for other in selected if path != other))


def entries(selected):
    raw = git('--literal-pathspecs', 'ls-tree', '-r', '-z', REVISION, '--', *selected)
    result = {}
    for record in raw.rstrip(b'\0').split(b'\0'):
        head, name = record.split(b'\t', 1)
        mode, kind, oid = head.decode().split()
        path = name.decode()
        need(mode in ('100644', '100755') and kind == 'blob' and path not in result,
             'whole ordinary fixed source population')
        result[path] = dict(mode=mode, oid=oid)
    need(all(any(name == root or name.startswith(root + '/') for name in result) for root in selected),
         'every declared source root has complete fixed members')
    return result


def directory_population(selected, population):
    directories = {str(parent) for name in population for parent in Path(name).parents
                   if any(str(parent) == root or str(parent).startswith(root + '/') for root in selected if root not in population)}
    return directories


def graph(selected, population):
    wanted = directory_population(selected, population)
    seen_files, seen_dirs = set(), set()
    for name in selected:
        if name in population:
            local(name)
            seen_files.add(name)
            continue
        local(name, exists=False)
        for directory, children, files in os.walk(name, followlinks=False):
            path = Path(directory)
            local(path, exists=False)
            need(stat.S_ISDIR(path.lstat().st_mode), 'ordinary source directory')
            seen_dirs.add(str(path))
            for child in children:
                local(path / child, exists=False)
            for child in files:
                member = path / child
                local(member)
                seen_files.add(str(member))
    need(seen_dirs == wanted, 'whole source directory population including empty-directory refusal')
    need(seen_files == set(population), 'whole source file population')
    return sorted(seen_dirs)


def derive():
    selected = roots()
    population = entries(selected)
    directories = graph(selected, population)
    process = subprocess.Popen(['git', '--no-replace-objects', 'cat-file', '--batch'],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    members = {}
    try:
        for name, entry in sorted(population.items()):
            path = local(name)
            before = path.stat()
            need(bool(before.st_mode & 0o111) == (entry['mode'] == '100755'), 'complete source executable mode')
            process.stdin.write(entry['oid'].encode() + b'\n')
            process.stdin.flush()
            header = process.stdout.readline().split()
            need(len(header) == 3 and header[0].decode() == entry['oid'] and header[1] == b'blob'
                 and int(header[2]) == before.st_size, 'whole fixed/current source object header')
            remaining = before.st_size
            digest = hashlib.sha256()
            with path.open('rb') as stream:
                while remaining:
                    chunk = process.stdout.read(min(1048576, remaining))
                    need(chunk and stream.read(len(chunk)) == chunk, 'whole fixed/current source bytes')
                    digest.update(chunk)
                    remaining -= len(chunk)
                need(stream.read(1) == b'' and process.stdout.read(1) == b'\n', 'complete own source boundary')
            after = path.stat()
            need((before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) ==
                 (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns), 'source member epoch conserved')
            members[name] = dict(**entry, bytes=before.st_size, sha256=digest.hexdigest())
        process.stdin.close()
        need(process.stderr.read() == b'' and process.wait() == 0 and process.stdout.read(1) == b'',
             'whole fixed Git source stream')
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
    need(graph(selected, population) == directories, 'whole source topology epoch conserved')
    task = git('show', REVISION + ':' + TASK)
    return dict(revision=REVISION, owner=OWNER, scope=SCOPE, roots=selected, directories=directories,
        members=members, original_task=dict(identity=pin(task), body=task.decode()),
        retention_contract='fsmgen_required_history',
        recovery='Retrieve complete full-revision Git objects under the repository required-history retention contract; never regenerate native captures.')


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--after', action='store_true')
    args = parser.parse_args()
    result = derive()
    save('intake-after.json' if args.after else 'intake-before.json', result)
    if args.after:
        need(result == load('intake-before.json'), 'whole input source/native/product epoch conserved across every reader')
    print('PASS complete fixed/current raw-semantic input source/native/product graph and whole binary Git custody; no semantic or native promotion.')
