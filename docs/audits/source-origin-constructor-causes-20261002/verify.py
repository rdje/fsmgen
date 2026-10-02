import copy
import hashlib
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/source-origin-constructor-causes-20261002')
BASELINE = 'e640b157515b21cbf297836c306f43e6e4614353'

def exact(left, right):
    assert json.dumps(left, sort_keys=True, separators=(',', ':')) == json.dumps(
        right, sort_keys=True, separators=(',', ':'))

def blob(path):
    return subprocess.check_output(['git', 'show', BASELINE + ':' + path])

bound = json.loads((BASE / 'bindings.json').read_text())
assert bound['baseline'] == BASELINE
assert len(bound['sources']) == 6 and len(bound['statements']) == 7
for path, row in bound['sources'].items():
    raw = blob(path)
    assert raw == row['source'].encode()
    assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
for site, statement in bound['statements'].items():
    path, line = site.rsplit(':', 1)
    actual = '\n'.join(bound['sources'][path]['source'].splitlines()[int(line) - 1:])
    assert actual.lstrip().startswith(statement)
for name, path, start, stop in (
    ('library', 't/2046-isf-library-document-origin-authority.t', 'sub first_line', 'sub library_refusal_with_echo'),
    ('file', 't/2048-isf-file-document-origin-authority.t', 'sub diagnostic_line', 'sub file_refusal_with_echo'),
):
    source = blob(path).decode()
    assert bound['helpers'][name] == source[source.index(start):source.index(stop)]

runtime = json.loads((BASE / 'runtime.json').read_text())
assert runtime['head'] == BASELINE and type(runtime['status']) is int and runtime['status'] == 12
exact(runtime['before'], runtime['after'])
paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', BASELINE,
                                 '--', 'bin', 'perl', 't']).decode().splitlines()
assert set(runtime['before']) == set(paths) | {str(BASE / name) for name in ('probe.pl', 'bindings.json', 'run.py')}
# One immutable Git object batch; each whole source digest is independently reconciled.
raw = subprocess.check_output(['git', 'cat-file', '--batch'], input=''.join(
    BASELINE + ':' + path + '\n' for path in paths).encode())
offset = 0
for path in paths:
    end = raw.index(b'\n', offset)
    header = raw[offset:end].split()
    assert header[1] == b'blob'
    size = int(header[2]); offset = end + 1
    source = raw[offset:offset + size]; offset += size + 1
    assert hashlib.sha256(source).hexdigest() == runtime['before'][path]
assert offset == len(raw)
for name in ('probe.pl', 'bindings.json', 'run.py'):
    assert hashlib.sha256((BASE / name).read_bytes()).hexdigest() == runtime['before'][str(BASE / name)]

causes = json.loads((BASE / 'cause-contracts.json').read_text())
# Declared leading-cause contracts are independent of the test's substring predicate.
assert set(causes) == {'local_import', 'same_external', 'same_package', 'same_ATL',
                      'local_library', 'same_absolute', 'same_escape', 'library_ATL',
                      'ATL_external', 'ATL_package', 'formal_residual'}
parser = blob('perl/FSM/Adapter/ISF/Parser.pm').decode().splitlines()
assert "Error: no (actor ...) root found in '$source_label'" in parser[117]
data = json.loads((BASE / 'products.json').read_text())

def verify(products):
    assert set(products) == {'products', 'helpers'}
    assert len(products['products']) == 44 and len(products['helpers']) == 2
    roster = set()
    for row in products['products']:
        assert set(row) == {'id', 'site', 'band', 'kind', 'source', 'label', 'accepted',
                            'error', 'first_line', 'matched', 'first_line_matched', 'literal'}
        for field in ('accepted', 'matched', 'first_line_matched'):
            assert type(row[field]) is int and row[field] in (0, 1)
        identity = (row['id'], row['band']); assert identity not in roster; roster.add(identity)
        assert row['id'] in causes and row['site'] in bound['statements']
        assert row['accepted'] == 0
        assert row['first_line'] == row['error'].split('\n')[0]
        if row['band'] == 'positive':
            assert row['first_line'] == causes[row['id']]
            assert row['matched'] == row['first_line_matched'] == 1
        else:
            assert row['band'] in ('wrong_source_echo', 'wrong_source_plain', 'wrong_label_echo')
            label = row['literal'] + '.isf' if row['band'] == 'wrong_label_echo' else 'wrong.isf'
            source = '; ' + row['literal'] + '\n(not_actor)' if row['band'] == 'wrong_source_echo' else '(not_actor)'
            assert row['label'] == label and row['source'] == source
            assert row['first_line'] == "Error: no (actor ...) root found in '" + label + "'"
            assert ' at perl/FSM/Adapter/ISF/Parser.pm line 118.' in row['error']
            full_match = 0 if row['band'] == 'wrong_source_plain' or (
                row['band'] == 'wrong_source_echo' and row['id'] == 'local_import') else 1
            assert row['matched'] == full_match
            assert row['first_line_matched'] == (1 if row['band'] == 'wrong_label_echo' else 0)
            observed_cause_acceptance = row['first_line_matched'] if '--trust-substring' in sys.argv else (
                1 if row['first_line'] == causes[row['id']] else 0)
            assert observed_cause_acceptance == 0, identity
    assert roster == {(name, band) for name in causes for band in
                      ('positive', 'wrong_source_echo', 'wrong_source_plain', 'wrong_label_echo')}
    assert {row['site'] for row in products['products']} == set(bound['statements'])
    assert {row['kind'] for row in products['helpers']} == {'file', 'library'}
    for row in products['helpers']:
        assert set(row) == {'kind', 'label', 'source', 'accepted', 'error', 'first_line', 'matched', 'literal'}
        assert type(row['matched']) is int and row['matched'] == 1
        assert type(row['accepted']) is int and row['accepted'] == 0
        assert row['source'] == '(not_actor)' and row['literal'] == 'selected source bytes differ from authority'
        label = row['literal'] + '.isf'
        if row['kind'] == 'file': label = str(BASE / 'file-workspace' / label)
        assert row['label'] == label
        assert row['first_line'] == row['error'].split('\n')[0] == "Error: no (actor ...) root found in '" + label + "'"
        assert ' at perl/FSM/Adapter/ISF/Parser.pm line 118.' in row['error']
    assert (BASE / 'file-workspace' / 'selected source bytes differ from authority.isf').read_bytes() == b'(not_actor)'

verify(data)
for name in ('wrong_cause', 'acceptance', 'label', 'primitive_kind', 'omission', 'helper'):
    bad = copy.deepcopy(data)
    if name == 'wrong_cause': bad['products'][0]['first_line'] = 'wrong cause'
    elif name == 'acceptance': bad['products'][0]['accepted'] = 1
    elif name == 'label': bad['products'][1]['label'] = 'substituted.isf'
    elif name == 'primitive_kind': bad['products'][0]['matched'] = True
    elif name == 'omission': bad['products'].pop()
    else: bad['helpers'][0]['matched'] = 0
    try: verify(bad)
    except AssertionError: print('shared corruption rejects:', name)
    else: raise AssertionError('accepted corruption ' + name)
if (BASE / 'manifest.json').exists():
    seal = json.loads((BASE / 'manifest.json').read_text())
    paths = {str(path.relative_to(BASE)) for path in BASE.rglob('*') if path.is_file() and path.name != 'manifest.json'}
    assert paths == set(seal['files'])
    for name, row in seal['files'].items():
        raw = (BASE / name).read_bytes()
        exact({'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, row)
print('constructor causes: Git/whole bytes, 7 sites/11 contexts/4 bands, additional 2 helpers, exact cause contracts and 6 shared controls qualify')
