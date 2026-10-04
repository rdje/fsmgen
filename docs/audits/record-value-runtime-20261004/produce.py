"""Derive the dated complete native profile; semantic assurance stays open."""
import hashlib
import json
from collections import Counter
from pathlib import Path

BASE = Path(__file__).parent
data = json.loads((BASE / 'ordinary.json').read_text())

def changes(left, right, path=''):
    if type(left) is not type(right):
        return [{'path': path, 'before': left, 'after': right,
            'before_kind': type(left).__name__, 'after_kind': type(right).__name__}]
    if isinstance(left, dict):
        assert set(left) == set(right), path
        return [r for key in sorted(left) for r in changes(left[key], right[key], path + '/' + key)]
    if isinstance(left, list):
        assert len(left) == len(right), path
        return [r for i, (a, b) in enumerate(zip(left, right)) for r in changes(a, b, path + '/' + str(i))]
    return [] if left == right else [{'path': path, 'before': left, 'after': right,
        'before_kind': type(left).__name__, 'after_kind': type(right).__name__}]

profile = {'counts': {key: len(data[key]) for key in ('api', 'copies', 'helpers', 'consumers', 'parses', 'warnings')},
    'api_kinds': dict(Counter(r['kind'] for r in data['api'])),
    'copy_kinds': dict(Counter(r['kind'] for r in data['copies'])),
    'consumer_kinds': dict(Counter(r['kind'] for r in data['consumers'])),
    'api_argument_changes': [{'index': i, 'kind': r['kind'], 'caller': r['caller'],
        'changes': changes(r['before'], r['after'])} for i, r in enumerate(data['api'])
        if changes(r['before'], r['after'])],
    'copy_changes': [{'index': i, 'kind': r['kind'], 'caller': r['caller'],
        'changes': changes(r['before'], r['copy'])} for i, r in enumerate(data['copies'])
        if changes(r['before'], r['copy'])],
    'host': data['host'],
    'inputs': {name: {'bytes': (BASE / name).stat().st_size,
        'sha256': hashlib.sha256((BASE / name).read_bytes()).hexdigest()}
        for name in ('ordinary.json', 'observe.pl', 'binding.json')},
}
(BASE / 'profile.json').write_text(json.dumps(profile, sort_keys=True, indent=2) + '\n')
print('PASS complete native observation population/typed deltas derived; observed causes '
    'and graph differences are not promoted to independently intended semantics or copy assurance.')
