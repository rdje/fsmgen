"""Remove only explicitly owned, fully authenticated duplicate Git-source copies."""
import contextlib
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys

from capture import BASE, canonical, pin, save
import census

sys.path.insert(0, 'scripts')
import book_source_references as plane
import record_value_raw_fact as fact
import record_value_observer_namespace_fact as namespace

PLAN = json.loads((BASE / 'plan.json').read_bytes())
PREFIX = '.artifacts/raw-canonical-preparation-20261011/'
ALLOWED = {PREFIX + name: source for name, source in (
    ('source-view', 'source.json'), ('source-view-v2', 'source-v2.json'),
    ('source-view-v3', 'source-v3.json'), ('source-view-v3-held-for-restoration', 'source-v3.json'))}


def need(value, message):
    if not value:
        raise ValueError(message)


def selected(row):
    need(type(row) is dict and set(row) == {'path', 'source'} and row['path'] in ALLOWED
         and row['source'] == ALLOWED[row['path']], 'only explicitly owned duplicate Git-source copy paths')
    return Path(row['path'])


def node(info):
    return {name: getattr(info, 'st_' + name) for name in ('dev', 'ino', 'mode', 'size', 'nlink', 'mtime_ns')}


def file_identity(path, expected):
    descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(descriptor, 'rb') as stream:
        before = os.fstat(stream.fileno())
        need(stat.S_ISREG(before.st_mode) and before.st_nlink == 1
             and before.st_dev == Path.cwd().stat().st_dev and before.st_size == expected['bytes'],
             'ordinary unshared bounded duplicate source body')
        digest, total = hashlib.sha256(), 0
        while chunk := stream.read(min(1048576, expected['bytes'] - total + 1)):
            digest.update(chunk)
            total += len(chunk)
            need(total <= expected['bytes'], 'exact bounded complete duplicate source body')
        after = os.fstat(stream.fileno())
    need(node(before) == node(after) == node(path.lstat()) and total == expected['bytes']
         and digest.hexdigest() == expected['sha256'], 'stable complete duplicate bytes and identity')
    return node(before)


def inspect(row, source):
    root = selected(row)
    plane.local_parents(plane.ROOT / root / 'endpoint')
    declared = {name: {key: entry[key] for key in ('bytes', 'sha256')} for name, entry in source['members'].items()}
    namespace.check_tree(root, declared)
    files, directories = {}, {}
    for directory, children, names in os.walk(root, followlinks=False):
        path = Path(directory)
        relative = str(path.relative_to(root))
        info = path.lstat()
        need(stat.S_ISDIR(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev
             and not os.path.lexists(path / '.git'), 'ordinary own duplicate source directory')
        directories[relative] = node(info)
        for name in names:
            item = path / name
            relative_name = str(item.relative_to(root))
            info = item.lstat()
            need(stat.S_ISREG(info.st_mode) and info.st_nlink == 1 and info.st_dev == Path.cwd().stat().st_dev
                 and bool(info.st_mode & 0o111) == (source['members'][relative_name]['mode'] == '100755'),
                 'ordinary unshared exact-mode duplicate source file')
            files[relative_name] = file_identity(item, source['members'][relative_name])
    need(set(files) == set(declared) and sorted(set(directories) - {'.'}) == source['directories'],
         'whole duplicate source file and directory population')
    command = ['rg', '--files', '--hidden', '--no-ignore', '--', str(root)]
    result = subprocess.run(command, capture_output=True, text=True)
    need(result.returncode == 0 and result.stderr == ''
         and sorted(result.stdout.splitlines()) == sorted(str(root / name) for name in files),
         'independent whole duplicate rg/os.walk population')
    need(subprocess.check_output(['git', 'ls-files', '-z', '--', str(root)]) == b'', 'no tracked copy member may be deleted')
    return dict(path=str(root), source=row['source'], source_identity=pin(canonical(source)),
                files=files, directories=directories, independent=dict(command=command,
                    status=result.returncode, stdout=result.stdout, stderr=result.stderr),
                disposition='delete', reason='Every byte/mode/member is an ordinary unshared duplicate of complete committed Git source. Original records and tested Git-only reconstruction remain available.')


@contextlib.contextmanager
def parent_fd(root_fd, relative, directories):
    descriptor = os.dup(root_fd)
    prefix = Path('.')
    try:
        for part in Path(relative).parts[:-1]:
            prefix /= part
            opened = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=descriptor)
            os.close(descriptor)
            descriptor = opened
            expected = directories[str(prefix)]
            actual = os.fstat(descriptor)
            need(actual.st_dev == expected['dev'] and actual.st_ino == expected['ino'], 'exact original duplicate directory descriptor')
            try:
                os.stat('.git', dir_fd=descriptor, follow_symlinks=False)
            except FileNotFoundError:
                pass
            else:
                raise ValueError('foreign Git boundary before removal')
        yield descriptor
    finally:
        os.close(descriptor)


def remove(authority):
    root = Path(authority['path'])
    plane.local_parents(plane.ROOT / root / 'endpoint')
    descriptor = os.open(root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        original = authority['directories']['.']
        now = os.fstat(descriptor)
        need(now.st_dev == original['dev'] and now.st_ino == original['ino'], 'exact owned duplicate root descriptor')
        for name, expected in sorted(authority['files'].items()):
            with parent_fd(descriptor, name, authority['directories']) as parent:
                actual = os.stat(Path(name).name, dir_fd=parent, follow_symlinks=False)
                need(node(actual) == expected, 'immediate complete duplicate file identity before removal')
                os.unlink(Path(name).name, dir_fd=parent)
        directories = sorted(set(authority['directories']) - {'.'}, key=lambda name: (-len(Path(name).parts), name))
        for name in directories:
            with parent_fd(descriptor, name, authority['directories']) as parent:
                actual = os.stat(Path(name).name, dir_fd=parent, follow_symlinks=False)
                expected = authority['directories'][name]
                need(stat.S_ISDIR(actual.st_mode) and actual.st_dev == expected['dev'] and actual.st_ino == expected['ino'],
                     'immediate original empty duplicate directory before removal')
                os.rmdir(Path(name).name, dir_fd=parent)
    finally:
        os.close(descriptor)
    actual = root.lstat()
    need(actual.st_dev == original['dev'] and actual.st_ino == original['ino'], 'exact empty owned duplicate root before removal')
    root.rmdir()
    need(not os.path.lexists(root), 'exact duplicate root residue absence')
    return dict(path=str(root), status=0, files=len(authority['files']),
                logical_bytes=sum(row['size'] for row in authority['files'].values()), residue=[])


def protected():
    result = {}
    for root in (Path('docs/book/book'), fact.PREPARATION, Path('docs/audits/raw-canonical-publication-20261011')):
        members = {}
        for path in sorted(root.rglob('*')):
            need(not path.is_symlink() and path.stat().st_dev == Path.cwd().stat().st_dev, 'ordinary same-volume protected tree')
            if path.is_file():
                members[str(path.relative_to(root))] = pin(path.read_bytes())
        result[str(root)] = members
    return result


def controls(source, row):
    results = []
    try:
        selected(dict(path='docs/book/book', source=row['source']))
    except ValueError as error:
        need(str(error) == 'only explicitly owned duplicate Git-source copy paths', 'intended protected path refusal')
        results.append(dict(name='protected book selection', cause=str(error)))
    else:
        raise ValueError('protected book admitted for deletion')
    declared = {name: {key: entry[key] for key in ('bytes', 'sha256')} for name, entry in source['members'].items()}
    counts = {}
    for name in declared:
        counts[str(Path(name).parent)] = counts.get(str(Path(name).parent), 0) + 1
    chosen = next(name for name in declared if counts[str(Path(name).parent)] > 1)
    for label, changed, cause in (
        ('omitted copy member', {name: value for name, value in declared.items() if name != chosen}, 'complete observer namespace member graph'),
        ('changed whole copy identity', dict(declared, **{chosen: dict(declared[chosen], sha256='0' * 64)}), 'whole observer namespace member bytes')):
        try:
            namespace.check_tree(selected(row), changed)
        except ValueError as error:
            need(str(error) == cause, 'intended complete copy authority refusal')
            results.append(dict(name=label, cause=str(error)))
        else:
            raise ValueError('changed copy authority accepted')
    return results


def main():
    need(not (BASE / 'cleanup-result.json').exists(), 'one fresh owned cleanup execution')
    prior = Path('docs/ARTIFACT_CLEANUP.md').read_text()
    now = datetime.now(timezone.utc)
    old = datetime.fromisoformat(prior.splitlines()[2].split(' — ', 1)[0])
    need((now - old).total_seconds() > 86400, 'daily cleanup is genuinely due')
    fact.preparation()
    need(len(PLAN['copies']) == len(ALLOWED)
         and {row['path']: row['source'] for row in PLAN['copies']} == ALLOWED, 'complete fixed duplicate copy selection')
    ordinary = census.census()
    preserve = protected()
    sources, authorities = {}, []
    for row in PLAN['copies']:
        source = json.loads((fact.PREPARATION / row['source']).read_bytes())
        if row['source'] not in sources:
            sources[row['source']] = fact.source_census(source)
        authorities.append(inspect(row, source))
    separating = controls(json.loads((fact.PREPARATION / PLAN['copies'][0]['source']).read_bytes()), PLAN['copies'][0])
    save('authority.json', dict(owner=PLAN['owner'], sources=sources, copies=authorities, controls=separating,
                              protected=preserve, condition=PLAN['condition']))
    # All candidate classifications and complete identities are durable before deletion starts.
    removed = []
    for index, authority in enumerate(authorities):
        result = remove(authority)
        save('removal-' + str(index) + '.json', result)
        removed.append(result)
    need(protected() == preserve, 'all original/native/current book protected bytes conserve')
    after = census.census()
    remaining = {row['path']: row for row in after['artifacts']}
    expected = {row['path']: row for row in ordinary['artifacts']
                if not any(row['path'].startswith(path + '/') for path in ALLOWED)}
    need(remaining == expected, 'all other censused artifact identities conserve')
    record = dict(owner=PLAN['owner'], revision=PLAN['revision'], utc=now.isoformat(), prior_record=prior,
                  before=ordinary, after=after, removed=removed, authority=pin((BASE / 'authority.json').read_bytes()),
                  protected=pin(canonical(preserve)), condition=PLAN['condition'])
    save('cleanup-result.json', record)
    Path('docs/ARTIFACT_CLEANUP.md').write_text('# Latest artifact cleanup\n\n' + now.isoformat()
        + ' — Removed four authenticated duplicate Git-source checkpoint trees; retained other censused artifacts, original/native/compiler evidence and the current book.\n')
    print('PASS due artifact cleanup: exact authenticated duplicate copies removed; original/native/compiler/book data retain.')


if __name__ == '__main__':
    main()
