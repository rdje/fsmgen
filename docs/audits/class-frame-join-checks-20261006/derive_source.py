"""Retain the independent whole source model before original observation intake."""
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-join-20261006')


def module(path):
    ns = {'__name__': 'class_frame_source_derivation', '__file__': str(path)}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


initial = module(Path('docs/audits/class-frame-join-checks-20261006/initial-model.py.txt'))
classes = module(Path('docs/audits/record-value-original-class-20261005/verify.py'))
public = module(Path('docs/audits/record-value-public-boundary-join-20261006/verify.py'))
model = module(BASE / 'model.py')
expected = model['derive'](classes, public, classes['require'], classes['same'])
retained = json.loads((BASE / 'pre-original-models.json').read_bytes())
assert classes['same'](initial['derive'](classes, public, classes['require'], classes['same']), retained)
assert classes['same']({k:v for k,v in expected.items() if k != 'scope'}, {k:v for k,v in retained.items() if k != 'scope'})
destination = BASE / 'source-models.json'; assert not destination.exists()
destination.write_text(json.dumps(expected, sort_keys=True, indent=2) + '\n')
for mode in expected['modes']:
    signatures = sorted({(r['domain'], r['exception']['source_family'], tuple(p['family'] for p in r['phases'])) for r in mode['cases']})
    print(mode['mode'], 'complete source cases', len(mode['cases']), 'class/phase signatures', signatures)
print('PASS qualified source associations retained before new original intake; predecessor serialized operands are opaque evidence and the initial terminal has no invented receipt.')
