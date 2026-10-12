"""Develop exact whole parent publication without changing any live source."""
from acceptance_common import *
import intake
import publish

if __name__ == '__main__':
    names = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md')
    before = {name: Path(name).read_bytes() for name in names}
    need(all(before[name] == body for name, body in intake.overlays().items()), 'whole development activation metadata')
    after, measured = publish.transformation(before)
    first, final = nodes(before[TASK]), nodes(after[TASK])
    need(first.keys() == final.keys(), 'whole development task graph conservation')
    for name, original in first.items():
        if name in (PLAN['owner'], PLAN['parent']):
            need(all(field(original, key) == field(final[name], key) for key in ('Goal', 'Acceptance', 'Children'))
                 and field(final[name], 'Status') == 'done', 'whole unchanged development-only parent/acceptance proposal')
        else:
            need(original == final[name], 'every unrelated whole development task contract retains')
    for line in before[BOOK].splitlines():
        if any(c in b'0123456789' for c in line):
            need(after[BOOK].splitlines().count(line) == before[BOOK].splitlines().count(line),
                 'every original quantitative/encoding/command book line retains')
    need(all(Path(name).read_bytes() == body for name, body in before.items()), 'no live metadata/source publication in development')
    snapshots = {}
    for index, name in enumerate(names):
        snapshots[name] = {}
        for role, body in (('before', before[name]), ('after', after[name])):
            path = BASE / ('development-proposal-' + role + '-' + str(index) + '.gz')
            need(not path.exists(), 'fresh whole non-acceptance development proposal snapshot')
            path.write_bytes(gzip.compress(body, mtime=0))
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    save('development-publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, measured=measured,
        condition='Development-only complete source-equivalent publication proposal. No live source, formal parent acceptance or higher closure has changed.'))
    print('PASS development-only complete unchanged parent publication proposal; no live source or formal acceptance changed.')
