"""Select exact committed inputs for the cooperative-lifetime evidence join."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
SCOPE = json.loads((BASE / 'scope.json').read_bytes())


def read(path):
    return json.loads((ROOT / path).read_bytes())


def pin(path):
    body = (ROOT / path).read_bytes()
    return dict(path=path, size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())


def derive():
    empty, populated = SCOPE['empty_store_directory'], SCOPE['populated_directory']
    empty_sources = read(empty + '/inputs.json')
    populated_sources = read(populated + '/source-pins.json')
    empty_rows = empty_sources + read(empty + '/audit-pins.json')
    empty_rows += [pin(empty + '/' + name) for name in ('review.json', 'audit-pins.json')]
    populated_rows = list(populated_sources)
    populated_rows += [pin(populated + '/' + name) for name in (
        'audit.py', 'first-results.json', 'review.json', 'source-pins.json',
        'retention-first.json', 'retain.py', 'retain.py.first.source')]
    populated_rows += [row['copy'] for row in read(populated + '/first-results.json')['first_results']]
    selected, groups = {}, {}
    for name, rows in [('empty_store', empty_rows), ('populated', populated_rows)]:
        groups[name] = sorted({row['path'] for row in rows})
        for row in rows:
            if pin(row['path']) != row:
                raise ValueError('selected source/result no longer matches its preserved pin: ' + row['path'])
            if row['path'] in selected and selected[row['path']] != row:
                raise ValueError('selected evidence stacks disagree about shared source bytes')
            selected[row['path']] = row
    for row in selected.values():
        body = subprocess.check_output(['git', 'show', SCOPE['source_revision'] + ':' + row['path']], cwd=ROOT)
        if len(body) != row['size_bytes'] or hashlib.sha256(body).hexdigest() != row['sha256']:
            raise ValueError('join input is not the exact selected committed object: ' + row['path'])
    old = {row['path']: row for row in empty_sources}
    current = {row['path']: row for row in populated_sources}
    common = [old[path] for path in sorted(set(old) & set(current))]
    if any(row != current[row['path']] for row in common):
        raise ValueError('the two original admission closures differ on a shared input')
    required = {'docs/audits/native-proxy-image-coordination-20260910/Coordination.pm',
                'docs/audits/native-proxy-image-custody-20260910/ImageCustody.pm'}
    if not required <= {row['path'] for row in common}:
        raise ValueError('the shared coordination and custody APIs are not independently bound by both admissions')
    return dict(source_revision=SCOPE['source_revision'], groups=groups,
        common_original_inputs=common, pins=[selected[path] for path in sorted(selected)])


if __name__ == '__main__':
    value = derive()
    with (BASE / 'input-pins.json').open('x') as stream:
        json.dump(value, stream, sort_keys=True, indent=2)
        stream.write('\n')
    print(json.dumps(dict(selected_inputs=len(value['pins']),
        common_original_inputs=len(value['common_original_inputs'])), sort_keys=True))
