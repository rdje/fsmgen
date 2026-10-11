"""Retain the separate dated-role correction without changing the first epoch."""
import gzip
import json
from pathlib import Path

from capture import BASE, canonical, pin, save
from publish import REGISTRY, TASK, metrics, need


def main():
    publication = json.loads((BASE / 'publication.json').read_bytes())
    original = {name: gzip.decompress(Path(publication['snapshots'][name]['after']['snapshot']).read_bytes())
                for name in (TASK, REGISTRY)}
    updated = Path(TASK).read_bytes()
    marker = b'  Findings (saved role): '
    need(updated.count(marker) == 1, 'unique owned saved-role finding')
    finding = next(line for line in updated.splitlines(keepends=True) if line.startswith(marker))
    need(updated.replace(finding, b'', 1) == original[TASK], 'only saved-role task finding changes')
    tasks = {name: Path(name).read_bytes() for name in publication['task_names']}
    measured = metrics(tasks)
    rows = list(map(json.loads, original[REGISTRY].splitlines()))
    need(Path(REGISTRY).read_bytes() == original[REGISTRY], 'unchanged original publication registry')
    for row in rows:
        if row.get('surface_id') == 'task_evidence':
            for key, value in measured.items():
                need(value <= row['enforcement_ceilings'][key], 'unchanged corrected task ceiling')
                row['transition']['max_growth'][key] = max(0, value + row['transition']['ratchet_step'][key] - row['baseline'][key])
    after = {TASK: updated, REGISTRY: b''.join(canonical(row) for row in rows)}
    snapshots = {}
    need(not (BASE / 'publication-role-correction.json').exists(), 'fresh separate dated-role correction')
    for index, name in enumerate((TASK, REGISTRY)):
        snapshots[name] = {}
        for role, body in (('before', original[name]), ('after', after[name])):
            path = BASE / ('role-correction-' + role + '-' + str(index) + '.gz')
            need(not path.exists(), 'every role correction target preflights')
            snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
    for name, roles in snapshots.items():
        for role, entry in roles.items():
            Path(entry['snapshot']).write_bytes(gzip.compress((original if role == 'before' else after)[name], mtime=0))
    save('publication-role-correction.json', dict(owner=publication['owner'], snapshots=snapshots,
        finding=finding.decode(), task_metrics=measured,
        condition='The original dated publication remains whole; only explicit current qualification follows later source. Saved proof verification repeats no deletion.'))
    Path(REGISTRY).write_bytes(after[REGISTRY])
    print('PASS separate saved/current role correction; original dated publication and disposal authority retain.')


if __name__ == '__main__':
    main()
