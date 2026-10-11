"""Census the complete fixed source with exact owned recovery metadata overlays."""
import hashlib
import json
from pathlib import Path
import stat
import subprocess
from parent_common import *
import intake
import recover

plane = intake.plane
namespace = intake.namespace


def live(roles):
    source = roles['publication']
    activation = recover.overlays()
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


if __name__ == '__main__':
    roles = intake.derive()
    need(same(roles, json.loads((BASE / 'source-roles.json').read_bytes())), 'whole original fixed source roles through recovery')
    result = live(roles)
    save('source-recovered.json', result)
    print('PASS complete recovered current source epoch and exact owned metadata overlays.')
