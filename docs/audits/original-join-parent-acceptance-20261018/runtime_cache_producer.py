"""Exercise the unchanged public cache producer in isolated same-volume fixtures."""
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess

import epoch_constraints as epoch
import execute
import prepare
import selected_postrun

ROOT = Path('.artifacts/original-join-cache-producer-20261018')
CACHE = Path('.artifacts/knowledge-map/query/questions.jsonl')
PREFIX = execute.AUDIT / 'runtime-cache-producer'
NAMES = ('runtime_cache_producer.py', 'epoch_constraints.py', 'execute.py', 'prepare.py',
         'selected_postrun.py', 'selected_checkout.py')
LABELS = ('cold', 'warm', 'no_cache_absent', 'no_cache_invalid', 'filtered', 'invalid_json',
          'schema_value', 'schema_kind', 'fingerprint', 'missing_row', 'extra_row', 'owner', 'source',
          'row_kind', 'unknown_field', 'mode', 'source_bytes', 'extra_member', 'traversal', 'symlink')


def projection():
    tree, members = epoch.tree(epoch.REVISION)
    names = sorted(name for name in members if name.startswith('knowledge-map/')
                   or name in ('KNOWLEDGE_MAP.md', '.knowledge_map.conf'))
    bodies = epoch.batch(epoch.REVISION, names)
    assert all(members[name]['mode'] in ('100644', '100755') for name in names)
    return tree, {name: members[name] for name in names}, bodies


def derive(bodies):
    rows, digest = [], hashlib.sha256()
    for name in sorted(bodies):
        if Path(name).parent != Path('knowledge-map/generated') or not name.endswith('.md'):
            continue
        body = bodies[name]
        digest.update(name.encode() + b'\0' + body + b'\0')
        for line in body.decode('utf-8').split('\n'):
            match = re.fullmatch(r'- q=(.*) · facts=(.*)', line)
            if match:
                question = json.loads(match[1])
                links = re.findall(r'\[([a-z0-9]+(?:-[a-z0-9]+)*)\]\(\.\./\.\./([^\)]+)\)', match[2])
                assert type(question) is str and links
                rows.append(dict(record_type='question', question=question,
                                 ids=[item[0] for item in links], sources=[item[1] for item in links]))
    rows.sort(key=lambda row: row['question'])
    header = dict(record_type='cache', schema_version=1, fingerprint=digest.hexdigest())
    return [header, *rows]


def wire(records):
    return b''.join((json.dumps(row, ensure_ascii=True, sort_keys=True, separators=(',', ':')) + '\n').encode()
                    for row in records)


def output(records, needle=''):
    return b''.join(('\t'.join((row['question'], ','.join(row['ids']), ','.join(row['sources']))) + '\n').encode()
                    for row in records[1:] if needle.lower() in row['question'].lower())


def snapshot(folder):
    folder = execute.safe(folder)
    files, directories = {}, []
    device = execute.ROOT.stat().st_dev
    for path in sorted(folder.rglob('*')):
        node = path.lstat()
        assert node.st_dev == device
        name = str(path.relative_to(folder))
        if stat.S_ISLNK(node.st_mode):
            files[name] = dict(kind='symlink', target=os.readlink(path))
        elif stat.S_ISDIR(node.st_mode):
            directories.append(name)
        else:
            assert stat.S_ISREG(node.st_mode)
            before = (node.st_dev, node.st_ino, node.st_size, node.st_mode, node.st_mtime_ns, node.st_ctime_ns)
            body = path.read_bytes()
            after = path.lstat()
            assert before == (after.st_dev, after.st_ino, after.st_size, after.st_mode, after.st_mtime_ns, after.st_ctime_ns)
            files[name] = dict(kind='file', mode=stat.S_IMODE(node.st_mode), uid=node.st_uid,
                               inode=node.st_ino, links=node.st_nlink, mtime_ns=node.st_mtime_ns,
                               ctime_ns=node.st_ctime_ns, **prepare.blob(body))
    return dict(files=files, directories=directories)


def protected_cache():
    path = execute.safe(CACHE)
    result = {'.': (dict(mode=stat.S_IMODE(path.stat().st_mode), inode=path.stat().st_ino,
                        mtime_ns=path.stat().st_mtime_ns, **prepare.blob(path.read_bytes()))
                    if path.exists() else None)}
    result[str(selected_postrun.checkout.FOLDER)] = selected_postrun.runtime_file()
    return result


def sources():
    return {name: prepare.blob(execute.read(execute.AUDIT / name)) for name in NAMES}


def run_case(label, members, bodies, seed):
    relative = ROOT / label
    folder = execute.safe(relative)
    folder.mkdir()
    for name, body in bodies.items():
        target = folder / name
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open('xb') as stream:
            stream.write(body)
        target.chmod(0o755 if members[name]['mode'] == '100755' else 0o644)
    active = dict(bodies)
    records = derive(bodies)
    cache = folder / CACHE
    if label not in ('cold', 'no_cache_absent', 'traversal', 'symlink'):
        cache.parent.mkdir(parents=True)
        with cache.open('xb') as stream:
            stream.write(seed)
    if label in ('invalid_json', 'no_cache_invalid'):
        cache.write_bytes(b'not-json\n')
    elif label in ('schema_value', 'schema_kind', 'fingerprint', 'missing_row', 'extra_row', 'owner', 'source', 'row_kind', 'unknown_field'):
        if label == 'schema_value': records[0]['schema_version'] = 2
        elif label == 'schema_kind': records[0]['schema_version'] = '1'
        elif label == 'fingerprint': records[0]['fingerprint'] = '0' * 64
        elif label == 'missing_row': records.pop()
        elif label == 'extra_row': records.append(records[-1].copy())
        elif label == 'owner': records[1]['ids'][0] = 'wrong-owner'
        elif label == 'source': records[1]['sources'][0] = 'docs/knowledge/wrong-source.md'
        elif label == 'row_kind': records[1]['ids'] = 'wrong-type'
        else: records[0]['unexpected'] = True
        cache.write_bytes(wire(records))
    elif label == 'mode':
        cache.chmod(0o777)
    elif label == 'source_bytes':
        name = next(name for name in sorted(bodies) if name.startswith('knowledge-map/generated/') and name.endswith('.md'))
        active[name] += b'\n'
        (folder / name).write_bytes(active[name])
    elif label == 'extra_member':
        name = 'knowledge-map/generated/zz-cache-control.md'
        active[name] = b'- q="__isolated cache member control__" \xc2\xb7 facts=[cache-control](../../docs/knowledge/cache-control.md)\n'
        (folder / name).write_bytes(active[name])
    elif label == 'symlink':
        (folder / 'protected').mkdir()
        (folder / 'link-cache').symlink_to('protected', target_is_directory=True)
    environment = {key: value for key, value in os.environ.items()
                   if not key.startswith(('KM_', 'GIT_'))}
    environment['GIT_CEILING_DIRECTORIES'] = str(execute.ROOT / '.artifacts')
    environment['TMPDIR'] = str(execute.ROOT / '.artifacts/tmp')
    settings = dict(git_search_ceiling='.artifacts', temporary_directory='.artifacts/tmp', inherited_KM_GIT_removed=True)
    if label in ('traversal', 'symlink'):
        settings['KM_QUERY_CACHE_DIR'] = '../escape' if label == 'traversal' else 'link-cache/query'
        environment['KM_QUERY_CACHE_DIR'] = settings['KM_QUERY_CACHE_DIR']
    # This read-only probe precedes every cache-producing command. Never let a
    # copied wrapper discover the primary repository through its ancestor path.
    probe = subprocess.run(['git', '-C', str(folder / 'knowledge-map/scripts'), 'rev-parse', '--show-toplevel'],
                           env=environment, capture_output=True)
    assert probe.returncode != 0 and probe.stdout == b'', 'private wrapper must fall back to its own cwd'
    args = ['--all'] if label != 'filtered' else ['MeMoRy']
    if label.startswith('no_cache'):
        args.append('--no-cache')
    command = ['knowledge-map/scripts/query_knowledge_map.sh', *args]
    before = snapshot(relative)
    native = subprocess.run([str(execute.ROOT / 'scripts/run_with_ram_guard.sh'), '--', *command],
                            cwd=folder, env=environment, capture_output=True)
    after = snapshot(relative)
    record = dict(label=label, working_directory=str(relative), command=command, resource_guard='scripts/run_with_ram_guard.sh',
                  environment=settings, root_probe=dict(status=probe.returncode, stdout=prepare.blob(probe.stdout), stderr=prepare.blob(probe.stderr)),
                  before=before, after=after, status=native.returncode, stdout=prepare.blob(native.stdout), stderr=prepare.blob(native.stderr),
                  derived_input=prepare.blob(wire(derive(active))), source_is_fixed=active == bodies)
    execute.save(Path(str(PREFIX) + '-' + label + '.json.gz'), record)
    if label in ('traversal', 'symlink'):
        assert native.returncode != 0 and native.stdout == b''
        assert b'unsafe KM_QUERY_CACHE_DIR ' in native.stderr
        assert before == after
    else:
        assert type(native.returncode) is int and native.returncode == 0
        assert native.stdout == output(derive(active), 'memory' if label == 'filtered' else '')
        assert b'ram-guard: terminating PID tree' not in native.stderr
    return record


if __name__ == '__main__':
    root = execute.safe(ROOT)
    assert not root.exists()
    raw_tree, members, bodies = projection()
    start = dict(revision=epoch.REVISION, tree=prepare.blob(raw_tree), members=members,
                 bodies={name: prepare.blob(body) for name, body in bodies.items()},
                 sources=sources(), tools=execute.tools(), primary=execute.git_state(), protected=protected_cache(),
                 scope='Actual unchanged public cache producer and full historical bundle/projection in private same-volume fixtures. '
                       'No semantic cohort, spent fixture/cache mutation, new checkout or runtime permission.')
    execute.save(Path(str(PREFIX) + '-started.json.gz'), start)
    root.mkdir()
    completed = []
    error = None
    try:
        cold = run_case('cold', members, bodies, None)
        seed = prepare.unblob(cold['after']['files'][str(CACHE)])
        # Independent source rows and the retained selected cache must agree
        # with the actual unchanged writer, including every canonical byte.
        assert seed == wire(derive(bodies))
        assert start['protected'][str(selected_postrun.checkout.FOLDER)] is not None
        assert seed == prepare.unblob(start['protected'][str(selected_postrun.checkout.FOLDER)])
        completed.append('cold')
        for label in LABELS[1:]:
            run_case(label, members, bodies, seed)
            completed.append(label)
    except BaseException as exception:
        error = dict(kind=type(exception).__name__, message=str(exception))
        raise
    finally:
        finish = dict(started=prepare.identity(execute.read(Path(str(PREFIX) + '-started.json.gz'))),
                      completed=completed, error=error, sources_after=execute.observe(sources),
                      tools_after=execute.observe(execute.tools), primary_after=execute.observe(execute.git_state),
                      protected_after=execute.observe(protected_cache))
        execute.save(Path(str(PREFIX) + '-actual.json.gz'), finish)
    assert finish['sources_after'] == dict(value=start['sources'], error=None)
    assert finish['tools_after'] == dict(value=start['tools'], error=None)
    assert finish['protected_after'] == dict(value=start['protected'], error=None)
    assert finish['primary_after']['error'] is None
    assert all(finish['primary_after']['value'][key] == start['primary'][key] for key in ('head', 'entries'))
    print('Complete unchanged public producer matrix retained; typed output admission and default runtime roles remain separate.')
