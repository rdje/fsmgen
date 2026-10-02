"""Whole saved products plus exact reason qualification; no production replay."""
import copy
import hashlib
import importlib.util
import io
import json
import subprocess
import sys
import tarfile
from pathlib import Path

BASE = Path(__file__).parent
PRIOR = Path('docs/audits/conditional-origin-files-20261002')


def authenticate(directory):
    manifest = json.loads((directory / 'manifest.json').read_text())
    members = manifest.get('members', manifest.get('files'))
    assert set(members) == {str(p.relative_to(directory)) for p in directory.rglob('*')
                            if p.is_file() and p.name != 'manifest.json'}
    for name, bound in members.items():
        raw = (directory / name).read_bytes()
        assert len(raw) == bound['bytes']
        assert hashlib.sha256(raw).hexdigest() == bound['sha256']


def same(left, right):
    assert json.dumps(left, sort_keys=True, separators=(',', ':')) == (
        json.dumps(right, sort_keys=True, separators=(',', ':')))


def reason(product, expected):
    assert [row['name'] for row in product['controls']] == list(expected)
    for row in product['controls']:
        assert row['accepted'] == 0
        if '--full-stack' in sys.argv:
            assert expected[row['name']] in row['diagnostic']
        else:
            assert row['diagnostic'].splitlines()[0] == expected[row['name']]


authenticate(PRIOR)
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('independent_file_products', PRIOR / 'verify.py')
oracle = importlib.util.module_from_spec(spec)
spec.loader.exec_module(oracle)
original_names = {p.name for p in (PRIOR / 'current-bound').glob('*.json')}
assert len(original_names) == 26
precedence = {
    'selected-byte-substitution': 'file origin selected source bytes differ from authority',
    'missing-selected-authority': 'file origin selected document authority missing',
    'root-byte-substitution': 'file origin root bytes differ from authority',
    'actual-file-mutation': 'file origin selected source bytes differ from authority',
    'unused-authority': 'library origin authoritative document membership differs',
    'deleted-selected-file': 'file origin selected document authority missing',
    'symlink-library': 'file origin selected file is missing or aliased'}
local = {name: 'file origin canonical relative identity required' for name in (
    'path-/absolute.isf', 'path-../escaped.isf', 'path-sources/../main.isf',
    'path-sources//main.isf', 'path-sources/./main.isf')}
local['symlink-root'] = 'file origin selected file is missing or aliased'
for band in ('current-bound', 'full-stack-red', 'bypass-red'):
    assert {p.name for p in (BASE / band).glob('*.json')} == original_names | {'diagnostic-echo.json'}
    for name in sorted(original_names):
        value = json.loads((BASE / band / name).read_text())
        previous_band = 'red-bound' if band == 'bypass-red' else 'current-bound'
        same(value, json.loads((PRIOR / previous_band / name).read_text()))
        if name not in ('precedence.json', 'same-source.json'):
            oracle.verify_case(value, bypass=(band == 'bypass-red'))
    reason(json.loads((BASE / band / 'precedence.json').read_text()), precedence)
    reason(json.loads((BASE / band / 'same-source.json').read_text()), local)
    echo = json.loads((BASE / band / 'diagnostic-echo.json').read_text())
    assert echo['error'].splitlines()[0] == 'file origin independent document set required'
    assert echo['expected'] in echo['error']
    assert echo['matched'] == (1 if band == 'full-stack-red' else 0)
    assert echo['controls'][0]['accepted'] == 0
    assert echo['controls'][0]['diagnostic'] == 'file origin independent document set required'

# Real saved wrong reason with an actual Carp caller echo. This tests the cold
# consumer itself, rather than inventing a diagnostic or weakening the producer.
wrong = json.loads((BASE / 'wrong-boundary.json').read_text())
assert wrong['error'].splitlines()[0] == 'file origin independent document set required'
assert wrong['expected'] in wrong['error']
sample = json.loads((BASE / 'current-bound' / 'precedence.json').read_text())
bad = copy.deepcopy(sample)
bad['controls'][0]['diagnostic'] = wrong['error']
try:
    reason(bad, precedence)
except AssertionError:
    pass
else:
    raise AssertionError('cold consumer accepted the actual wrong reason from a caller echo')
for label in ('membership', 'cause', 'accepted-kind'):
    bad = copy.deepcopy(sample)
    if label == 'membership':
        bad['controls'].pop()
    elif label == 'cause':
        bad['controls'][0]['diagnostic'] = 'unrelated failure'
    else:
        bad['controls'][0]['accepted'] = 1
    try:
        reason(bad, precedence)
    except AssertionError:
        pass
    else:
        raise AssertionError('shared corruption accepted: ' + label)

recipe = json.loads((BASE / 'recipe.json').read_text())
archive = subprocess.check_output(['git', 'archive', recipe['baseline'], 'bin', 'perl', 't/lib'])
with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
    baseline = {item.name: stream.extractfile(item).read() for item in stream.getmembers()
                if item.isfile() and item.name in recipe['unchanged_producers']}
assert Path('t/2048-isf-file-document-origin-authority.t').read_bytes() == (
    BASE / 'instruments' / 'test-final.t').read_bytes()
for name, bound in recipe['unchanged_producers'].items():
    raw = Path(name).read_bytes()
    assert raw == baseline[name]
    assert len(raw) == bound['bytes'] and hashlib.sha256(raw).hexdigest() == bound['sha256']
for name, bound in recipe['instruments'].items():
    raw = Path(name).read_bytes()
    assert len(raw) == bound['bytes'] and hashlib.sha256(raw).hexdigest() == bound['sha256']
for name, expected in (('current.txt', 'Result: PASS'), ('full-stack-red.txt', 'Result: FAIL'),
                       ('bypass-red.txt', 'Result: FAIL')):
    assert expected in (BASE / name).read_text()
print('PASS complete original products, independent original-source projection, exact boundary reasons, '
      'genuine wrong-cause echo and three shared corruptions; prior archive untouched')
