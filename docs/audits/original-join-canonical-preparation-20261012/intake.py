"""Qualify complete original and publication source roles without ignored views."""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys

from capture import BASE, canonical, pin, save

_import_path = sys.path[:]
try:
    sys.path.insert(0, 'scripts')
    import book_source_references as plane
    import record_value_raw_fact as fact
    import record_value_observer_namespace_fact as namespace
finally:
    sys.path[:] = _import_path

PLAN = json.loads((BASE / 'plan.json').read_bytes())
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
OVERLAYS = {TASK: 'activation-task.gz', 'MEMORY.md': 'activation-memory.gz',
            'docs/TASK_TREE.md': 'activation-index.gz'}
SUCCESS = 'PASS complete original and original-join preparation source epochs, native custody and independent membership.\n'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def git(*args):
    result = subprocess.run(['git', '--no-replace-objects', '--literal-pathspecs', *args], capture_output=True)
    need(result.returncode == 0 and result.stderr == b'', 'complete own read-only fixed Git result')
    return result.stdout


def derive():
    fact.preparation()
    original = json.loads((fact.PREPARATION / 'source-v3.json').read_bytes())
    fact.source_census(original)
    prior = json.loads((Path(PLAN['association']) / 'source-roles.json').read_bytes())
    selected = set(prior['publication']['roots']) | {PLAN['association'], PLAN['admission'], PLAN['context'], PLAN['cause'], PLAN['consumer'], 'scripts/record_value_consumer_fact.py'} | {'docs/knowledge', 'docs/decisions', 'knowledge-map', 'KNOWLEDGE_MAP.md'}
    roots = sorted(name for name in selected if not any(name.startswith(other + '/') for other in selected if name != other))
    entries = {}
    for record in git('ls-tree', '-r', '-z', PLAN['revision'], '--', *roots).rstrip(b'\0').split(b'\0'):
        header, raw_name = record.split(b'\t', 1)
        mode, kind, oid = header.decode().split()
        name = raw_name.decode()
        plane.relative(name)
        need(kind == 'blob' and mode in ('100644', '100755') and name not in entries,
             'unique ordinary complete publication source member')
        old = original['members'].get(name)
        if old and old['oid'] == oid and old['mode'] == mode:
            entries[name] = old
        else:
            body = git('cat-file', 'blob', oid)
            entries[name] = dict(mode=mode, oid=oid, **pin(body))
    need(set(original['members']) <= set(entries), 'every complete original source member retains')
    changed = {name: dict(original=old, publication=entries[name]) for name, old in original['members'].items()
               if old != entries[name]}
    code = {name for name in changed if Path(name).suffix in ('.py', '.pl', '.pm', '.sh', '.js', '.t')}
    need(code <= {'scripts/check_record_value_publication.py', 't/python/test_record_value_current_publication.py'},
         'only explicit maintained publication instruments advance; original semantic programmes retain')
    source = dict(revision=PLAN['revision'], roots=roots, members=entries,
        directories=sorted({str(parent) for name in entries for parent in Path(name).parents if str(parent) != '.'}))
    fact.source_census(source)
    return dict(original=original, publication=source, changed=changed,
        condition='Original complete reader/source/native roles retain their fixed 2ca and earlier e428 conditions. Current canonical production is separately bound to the clean complete independent original association commit. No later original-programme currency or native/private recapture is inferred.')


def overlays(after=False):
    result = {name: gzip.decompress((BASE / snapshot).read_bytes()) for name, snapshot in OVERLAYS.items()}
    if after:
        publication = json.loads((BASE / 'publication.json').read_bytes())
        for name, roles in publication['snapshots'].items():
            body = gzip.decompress(Path(roles['after']['snapshot']).read_bytes())
            need(pin(body) == roles['after']['identity'], 'whole intended publication afterimage')
            result[name] = body
    return result


def live(roles, after=False):
    source = roles['publication']
    activation = overlays(after)
    expected = {name: {key: row[key] for key in ('bytes', 'sha256')} for name, row in source['members'].items()}
    expected.update({name: pin(body) for name, body in activation.items()})
    members = set()
    for root_name in sorted(set(source['roots']) | (set(activation) - set(source['members']))):
        root = Path(root_name)
        plane.local_parents(plane.ROOT / root / 'endpoint' if root.is_dir() else plane.ROOT / root)
        if root.is_dir():
            declared = {str(Path(name).relative_to(root)): row for name, row in expected.items()
                        if name.startswith(root_name + '/')}
            namespace.check_tree(root, declared)
            result = subprocess.run(['rg', '--files', '--hidden', '--no-ignore', '--', root_name], capture_output=True, text=True)
            need(result.returncode == 0 and result.stderr == '', 'actual independent complete source directory census')
            members.update(result.stdout.splitlines())
        else:
            need(root_name in expected, 'declared complete source file root')
            members.add(root_name)
    need(members == set(expected), 'whole independent fixed/current source file membership')
    for name in sorted(members):
        path = Path(name)
        info = path.lstat()
        need(stat.S_ISREG(info.st_mode) and info.st_dev == Path.cwd().stat().st_dev
             and bool(info.st_mode & 0o111) == (source['members'].get(name, {'mode': '100644'})['mode'] == '100755'),
             'ordinary same-volume complete current source mode')
        digest = hashlib.sha256()
        with path.open('rb') as stream:
            while chunk := stream.read(1048576):
                digest.update(chunk)
        after = path.stat()
        need((info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns) ==
             (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns)
             and dict(bytes=after.st_size, sha256=digest.hexdigest()) == expected[name],
             'whole fixed publication or declared activation source bytes')
    return dict(source=pin(canonical(source)), overlays={name: pin(body) for name, body in activation.items()},
                members=sorted(members), condition=roles['condition'])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--development', action='store_true')
    parser.add_argument('--before', action='store_true')
    parser.add_argument('--after', action='store_true')
    parser.add_argument('--published', action='store_true')
    parser.add_argument('--prefix', choices=('', 'v2-', 'v3-'), default='')
    args = parser.parse_args()
    prefix = args.prefix
    need(sum((args.development, args.before, args.after, args.published)) == 1, 'one explicit source census epoch')
    roles = derive()
    if args.development:
        save(prefix + 'source-proposal.json', dict(roles=roles, condition='Development-only fixed source declaration; formal current-source qualification is separate.'))
        print('PASS development-only complete fixed original-join preparation source declaration.')
        return
    need(json.loads((BASE / (prefix + 'source-proposal.json')).read_bytes())['roles'] == roles,
         'whole development/formal fixed source declaration correspondence')
    if args.before:
        save(prefix + 'source-roles.json', roles)
    else:
        need(json.loads((BASE / (prefix + 'source-roles.json')).read_bytes()) == roles, 'whole original/current source roles conserve')
    result = live(roles, args.published)
    if args.after:
        expected = json.loads((BASE / (prefix + 'source-before.json')).read_bytes())
        need(expected['source'] == result['source'] and expected['members'] == result['members'],
             'whole source and member domain retains across only explicit publication overlays')
    save(prefix + 'source-' + ('before' if args.before else 'published' if args.published else 'after') + '.json', result)
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
