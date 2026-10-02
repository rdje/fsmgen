import copy
import hashlib
import json
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True
BASE = Path('docs/audits/origin-helper-cause-repair-20261002')
BASELINE = '66f3d6a3c6f57e7dfde3ff70dcb472a1cb72b5ed'
CHANGED = {'t/2046-isf-library-document-origin-authority.t', 't/2048-isf-file-document-origin-authority.t'}

def encoded(value): return json.dumps(value, sort_keys=True, separators=(',', ':'))
def same(a, b): assert encoded(a) == encoded(b)
def blob(path): return subprocess.check_output(['git', 'show', BASELINE + ':' + str(path)])

def seal(path, prior=True):
    manifest = path / 'manifest.json'
    if prior: assert manifest.read_bytes() == blob(manifest)
    data = json.loads(manifest.read_text()); members = data.get('files', data.get('members'))
    assert set(members) == {str(p.relative_to(path)) for p in path.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    for name, row in members.items():
        raw = (path / name).read_bytes()
        same({'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}, row)

prior = Path('docs/audits/source-origin-constructor-causes-20261002'); seal(prior)
old_bindings = json.loads((prior / 'bindings.json').read_text())
runtime = json.loads((BASE / 'runtime.json').read_text())
assert runtime['baseline'] == BASELINE
same(runtime['before'], runtime['after'])
expected_runs = [[kind, band, 0 if band == 'current' else 1, 0 if band == 'current' else 1]
                 for kind in ('library', 'file') for band in ('current', 'full-stack', 'bypass')]
def statuses(value):
    same([[p['kind'], p['band'], p['status'], p['expected']] for p in value['runs']], expected_runs)
statuses(runtime)
bad = copy.deepcopy(runtime); bad['runs'][0]['status'] = False
try: statuses(bad)
except AssertionError: print('runtime numeric-status kind corruption rejects')
else: raise AssertionError('accepted false instead of numeric status')
paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', BASELINE, '--', 'bin', 'perl', 't']).decode().splitlines()
raw = subprocess.check_output(['git', 'cat-file', '--batch'], input=''.join(BASELINE + ':' + p + '\n' for p in paths).encode())
offset = 0
for path in paths:
    end = raw.index(b'\n', offset); header = raw[offset:end].split(); assert header[1] == b'blob'
    size = int(header[2]); offset = end + 1; source = raw[offset:offset + size]; offset += size + 1
    if path not in CHANGED: assert hashlib.sha256(source).hexdigest() == runtime['before'][path]
assert offset == len(raw)
for path in CHANGED:
    assert hashlib.sha256((BASE / 'instruments' / path).read_bytes()).hexdigest() == runtime['before'][path]
assert (BASE / 'instruments/t/lib/FSM/Test/DiagnosticCause.pm').read_bytes() == blob('t/lib/FSM/Test/DiagnosticCause.pm')
for path in (BASE / 'preload').glob('*.pm'):
    kind = 'library' if 'Library' in path.name else 'file'
    old_archive = 'library-origin-diagnostic-correction-20261002' if kind == 'library' else 'file-origin-diagnostic-correction-20261002'
    assert path.read_bytes() == blob(Path('docs/audits') / old_archive / 'red-lib' / path.name)

# Authenticate and reuse exact independently authored product/source oracle
# portions; historical runtime/test fingerprint gates are deliberately excluded.
lib_prior = Path('docs/audits/library-origin-diagnostic-correction-20261002'); seal(lib_prior)
file_prior = Path('docs/audits/file-origin-diagnostic-correction-20261002'); seal(file_prior)
for path in (Path('docs/audits/conditional-origin-documents-finalization-20261002'),
             Path('docs/audits/conditional-origin-library-20261002'),
             Path('docs/audits/conditional-origin-files-20261002'),
             Path('docs/audits/conditional-origin-atl-20261002')): seal(path)
lib_source = lib_prior / 'verify.py'; assert lib_source.read_bytes() == blob(lib_source)
lib = {}; exec(compile(lib_source.read_text().split('\nbands = {}', 1)[0], str(lib_source), 'exec'), lib)
file_source = file_prior / 'verify.py'; assert file_source.read_bytes() == blob(file_source)
file_scope = {}; exec(compile(file_source.read_text().split("\nfor band in ('current-bound'", 1)[0], str(file_source), 'exec'), file_scope)

# All current helper consumers emit numeric flags. Guard those metadata kinds
# separately from the independent whole actor/proof primitive-kind projection.
def flags(value):
    if isinstance(value, dict):
        for key, item in value.items():
            if key in ('accepted', 'matched'): assert type(item) is int and item in (0, 1)
            flags(item)
    elif isinstance(value, list):
        for item in value: flags(item)

def label_control(value, kind, weak=False):
    assert set(value) == {'source', 'label', 'error', 'expected', 'accepted', 'matched'}
    flags(value)
    assert value['source'] == '(not_actor)' and value['accepted'] == 0
    expected = kind + ' origin selected source bytes differ from authority'
    assert value['expected'] == expected and value['label'].endswith(expected + '.isf')
    assert not Path(value['label']).is_absolute() and '..' not in Path(value['label']).parts
    assert value['error'].split('\n')[0] == "Error: no (actor ...) root found in '" + value['label'] + "'"
    assert ' at perl/FSM/Adapter/ISF/Parser.pm line 118.' in value['error']
    assert value['matched'] == (1 if weak else 0)

bands = {}
for kind in ('library', 'file'):
    for band in ('current', 'full-stack', 'bypass'):
        values = {p.name: json.loads(p.read_text()) for p in (BASE / kind / band).glob('*.json')}
        flags(values)
        if kind == 'library':
            assert set(values) == lib['original_names'] | {'boundaries.json', 'diagnostic-echo.json', 'diagnostic-label.json'}
            lib['oracle']({name: values[name] for name in lib['original_names']}, red=band == 'bypass')
            lib['boundaries'](values['boundaries.json'], bypass=band == 'bypass')
            for name in lib['scope']['names']:
                for row in values[name]['controls']:
                    if band == 'bypass': assert row['diagnostic'] == ''
                    else:
                        cause = 'actor' if row['name'] in ('actor_identity', 'actor_kind') else 'proof'
                        assert row['diagnostic'].split('\n')[0] == 'library origin ' + cause + ' differs from authoritative document set'
            for row in values['finalization.json']['controls']:
                clause = 'coverage' if row['name'] == 'coverage' else 'target or identity'
                assert row['diagnostic'].split('\n')[0] == 'library origin final use ' + clause + ' differs'
        else:
            assert set(values) == file_scope['original_names'] | {'diagnostic-echo.json', 'diagnostic-label.json'}
            previous_band = 'bypass-red' if band == 'bypass' else 'current-bound'
            for name in file_scope['original_names']:
                same(values[name], json.loads((file_prior / previous_band / name).read_text()))
                if name not in ('precedence.json', 'same-source.json'):
                    file_scope['oracle'].verify_case(values[name], bypass=band == 'bypass')
            file_scope['reason'](values['precedence.json'], file_scope['precedence'])
            file_scope['reason'](values['same-source.json'], file_scope['local'])
        echo = values['diagnostic-echo.json']
        assert echo['error'].split('\n')[0] == kind + ' origin independent document set required'
        assert echo['expected'] in echo['error']
        assert echo['matched'] == (1 if band == 'full-stack' else 0)
        label_control(values['diagnostic-label.json'], kind, band == 'full-stack')
        bands[kind, band] = values
        print('complete independent products, exact causes, kinds and controls qualify:', kind, band, len(values))

payload = {}
for kind, path, start, stop in (
    ('library', 't/2046-isf-library-document-origin-authority.t', 'sub first_line', 'sub library_refusal_with_echo'),
    ('file', 't/2048-isf-file-document-origin-authority.t', 'sub diagnostic_line', 'sub file_refusal_with_echo')):
    source = (BASE / 'instruments' / path).read_text()
    payload[kind] = {'old': old_bindings['helpers'][kind], 'current': source[source.index(start):source.index(stop)],
                     'product': bands[kind, 'current']['diagnostic-label.json']}
results = json.loads(subprocess.check_output(['perl', '-I' + str(BASE / 'instruments/t/lib'), str(BASE / 'probe_helpers.pl')], input=encoded(payload).encode()))
same(results, {'library': {'old': 1, 'current': 0}, 'file': {'old': 1, 'current': 0}})
if '--old-first-line' in sys.argv:
    assert results['library']['old'] == 0, 'actual old first-line helper accepts the real quoted-label wrong cause'
print('actual exact old helper accepts label echo; complete current cause rejects: library/file')
for name in ('label', 'first_cause', 'acceptance', 'kind', 'shape'):
    bad = copy.deepcopy(bands['library', 'current']['diagnostic-label.json'])
    if name == 'label': bad['label'] = 'substituted.isf'
    elif name == 'first_cause': bad['error'] = 'wrong cause\n' + bad['error']
    elif name == 'acceptance': bad['matched'] = 1
    elif name == 'kind': bad['matched'] = False
    else: bad['extra'] = 'forged'
    try: label_control(bad, 'library')
    except AssertionError: print('shared label control corruption rejects:', name)
    else: raise AssertionError('accepted label control ' + name)
for kind in ('library', 'file'):
    bad = copy.deepcopy(bands[kind, 'current'])
    if kind == 'library':
        value = bad['identical_export_twins.json']
        for actor in (value['ordinary'], value['instrumented'], value['proof']['actors'][0]['actor']):
            actor['interface']['inputs'][0]['width'] = '1'
        check = lambda: lib['oracle']({name: bad[name] for name in lib['original_names']})
    else:
        name = next(name for name in file_scope['original_names'] if name not in ('precedence.json', 'same-source.json'))
        value = bad[name]
        for root in value['products'][0]['roots']:
            for field in ('actor', 'ordinary'): root[field]['interface']['inputs'][0]['width'] = '1'
            root['proof']['actors'][0]['actor']['interface']['inputs'][0]['width'] = '1'
        check = lambda: file_scope['oracle'].verify_case(value)
    try: check()
    except AssertionError: print('shared whole-product kind corruption rejects:', kind)
    else: raise AssertionError('accepted product kind ' + kind)
if (BASE / 'manifest.json').exists(): seal(BASE, False)
print('helper correction: full immutable sources/products/kinds, literal first causes, real caller/primary-label echo and genuine falsification qualify')
