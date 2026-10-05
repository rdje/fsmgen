"""Read the scoped director direction; never authorize or execute a push."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/push-checkpoint-resolution-20261005')
REVISION = '3a744e8cf3b8e2f5866b9b3b636fa6db13e8302c'
DIRECTIVE = 'defer the push and continue PNT as you recommended it.'
INTERPRETATION = ('Defer the cadence push and resume independent PNT. Preserve the existing HIAL/full-CI '
                  'qualification gates and eventual exact-SHA hosted qualification. No full CI, push, '
                  'probes or host-security change is authorized by this direction.')


def require(ok, cause):
    if not ok:
        raise ValueError(cause)


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def check(direction, transform):
    require(direction['owner'] == 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.69.2'
            and direction['checkpoint_revision'] == REVISION, 'exact resolution owner/revision')
    require(direction['director_instruction'] == DIRECTIVE, 'verbatim director direction')
    require(direction['interpretation'] == INTERPRETATION, 'cadence deferral preserves qualification')
    manifest_path = 'docs/audits/push-checkpoint-preflight-20261005/manifest.json'
    raw = subprocess.check_output(['git', 'show', REVISION + ':' + manifest_path])
    require(identity(raw) == direction['preflight_manifest'], 'whole committed checkpoint seal')
    require(transform['revision'] == REVISION
            and transform['path'] == 'docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md',
            'book authority allocation')
    before = subprocess.check_output(['git', 'show', REVISION + ':' + transform['path']], text=True)
    require(before == transform['before'], 'whole committed book predecessor')
    after = before
    for old, new in transform['replacements']:
        require(after.count(old) == 1, 'unique exact book replacement')
        after = after.replace(old, new)
    require(after == transform['after'] and 'deferred the push' in after
            and 'in force; full CI and push have not run.' in after, 'complete directed book transformation')


def check_members(manifest):
    require({p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}, 'complete resolution seal membership')


def main():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    check_members(manifest)
    for name, expected in manifest.items():
        require(identity((BASE / name).read_bytes()) == expected, 'whole sealed member: ' + name)
    direction = json.loads((BASE / 'direction.json').read_text())
    transform = json.loads((BASE / 'book-transform.json').read_text())
    check(direction, transform)
    authority = json.loads((BASE / 'book-authority.json').read_text())
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION, 'docs/book/src'], text=True)
    rows = [subprocess.check_output(['git', 'show', REVISION + ':' + p])
            for p in paths.splitlines() if p.endswith('.md') and p.count('/') == 3]
    before = {'files': len(rows), 'bytes_total': sum(map(len, rows)), 'lines_total': sum(x.count(b'\n') for x in rows)}
    delta = {'files': 0, 'bytes_total': len(transform['after'].encode()) - len(transform['before'].encode()),
             'lines_total': transform['after'].count('\n') - transform['before'].count('\n')}
    require(authority == {'before': before, 'after': {k: before[k] + delta[k] for k in before}, 'delta': delta},
            'whole independently reconstructed book aggregate')
    controls = []
    for name, mutation, cause in [
        ('changed-director-text', lambda d, t: d.update(director_instruction='push now'), 'verbatim director direction'),
        ('fabricated-CI-authorization', lambda d, t: d.update(interpretation='Full CI is authorized.'), 'cadence deferral preserves qualification'),
        ('changed-book', lambda d, t: t.update(after=t['after'] + '\n'), 'complete directed book transformation'),
    ]:
        bad_direction, bad_transform = copy.deepcopy(direction), copy.deepcopy(transform)
        mutation(bad_direction, bad_transform)
        try:
            check(bad_direction, bad_transform)
        except ValueError as error:
            require(str(error) == cause, 'intended resolution control cause: ' + name)
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise ValueError('false-green resolution control: ' + name)
    bad_manifest = dict(manifest)
    del bad_manifest['direction.json']
    try:
        check_members(bad_manifest)
    except ValueError as error:
        require(str(error) == 'complete resolution seal membership', 'intended membership control cause')
        controls.append({'control': 'missing-member', 'status': 1, 'cause': str(error)})
    else:
        raise ValueError('false-green membership control')
    print(json.dumps({'status': 0, 'controls': controls, 'scope': 'Saved direct instruction and interpretation; no external authenticity, CI or push proof.'}, sort_keys=True))


if __name__ == '__main__':
    main()
