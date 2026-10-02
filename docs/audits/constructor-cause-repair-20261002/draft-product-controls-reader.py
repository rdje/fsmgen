import ast
import copy
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/constructor-cause-repair-20261002')
BASELINE = 'd05f9e79510b69f9e6106d025974f7c639a9ad82'
PRIOR = Path('docs/audits/source-origin-constructor-causes-20261002')
CHANGED = {'t/2044-isf-conditional-origin-source-authority.t',
           't/2045-isf-same-source-library-origins.t',
           't/2047-isf-atl-document-origin-authority.t',
           't/2052-isf-local-formal-origin-authority.t'}
NEW = {'t/2053-isf-constructor-diagnostic-causes.t', 't/lib/FSM/Test/DiagnosticCause.pm'}

def encoded(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False)

def same(actual, expected):
    assert encoded(actual) == encoded(expected)

def blob(path):
    return subprocess.check_output(['git', 'show', BASELINE + ':' + str(path)])

def sealed(path, baseline=False):
    seal_path = path / 'manifest.json'
    if baseline: assert seal_path.read_bytes() == blob(seal_path)
    seal = json.loads(seal_path.read_text())
    members = seal.get('files', seal.get('members'))
    assert isinstance(members, dict)
    if not baseline:
        assert set(members) == {str(p.relative_to(path)) for p in path.rglob('*')
                               if p.is_file() and p.name != 'manifest.json'}
    for name, row in members.items():
        raw = (path / name).read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']

sealed(PRIOR, True)
contracts = json.loads((PRIOR / 'cause-contracts.json').read_text())
positives = {p['id']: p for p in json.loads((PRIOR / 'products.json').read_text())['products']
             if p['band'] == 'positive'}
runtime = json.loads((BASE / 'runtime.json').read_text())
assert runtime['baseline'] == BASELINE
same(runtime['before'], runtime['after'])
assert [(p['band'], p['status'], p['expected']) for p in runtime['runs']] == [
    ('current', 0, 0), ('substring', 1, 1), ('family', 0, 0), ('old-consumer', 12, 12)]
paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', BASELINE,
                                 '--', 'bin', 'perl', 't']).decode().splitlines()
# Authenticate all unchanged whole source bytes in one immutable Git object batch.
raw = subprocess.check_output(['git', 'cat-file', '--batch'], input=''.join(
    BASELINE + ':' + path + '\n' for path in paths).encode())
offset = 0
for path in paths:
    end = raw.index(b'\n', offset); header = raw[offset:end].split(); assert header[1] == b'blob'
    size = int(header[2]); offset = end + 1
    source = raw[offset:offset + size]; offset += size + 1
    if path not in CHANGED: assert hashlib.sha256(source).hexdigest() == runtime['before'][path]
assert offset == len(raw)
for path in CHANGED | NEW:
    snapshot = BASE / 'instruments' / path
    assert hashlib.sha256(snapshot.read_bytes()).hexdigest() == runtime['before'][path]
# Exact old consumer definitions are preserved, only repository-local capture coordinates change.
assert (BASE / 'bindings.json').read_bytes() == (PRIOR / 'bindings.json').read_bytes()
assert (BASE / 'old-consumer.pl').read_text() == (PRIOR / 'probe.pl').read_text().replace(str(PRIOR), str(BASE))

current = json.loads((BASE / 'current/causes.json').read_text())
substring = json.loads((BASE / 'substring/causes.json').read_text())

def causes(values, weak=False):
    assert len(values) == 44
    seen = set()
    for row in values:
        assert set(row) == {'id', 'band', 'kind', 'source', 'label', 'expected', 'accepted', 'matched', 'error'}
        identity = (row['id'], row['band']); assert identity not in seen; seen.add(identity)
        original = positives[row['id']]; expected = contracts[row['id']]
        assert row['expected'] == expected and row['kind'] == original['kind']
        assert type(row['accepted']) is int and row['accepted'] == 0
        assert type(row['matched']) is int
        if row['band'] == 'positive':
            assert row['source'] == original['source'] and row['label'] == original['label']
            assert row['error'].split('\n')[0] == expected and row['matched'] == 1
        else:
            assert row['band'] in ('wrong_source_echo', 'wrong_source_plain', 'wrong_label_echo')
            source = '; ' + expected + '\n(not_actor)' if row['band'] == 'wrong_source_echo' else '(not_actor)'
            label = expected + '.isf' if row['band'] == 'wrong_label_echo' else 'wrong.isf'
            assert row['source'] == source and row['label'] == label
            assert row['error'].split('\n')[0] == "Error: no (actor ...) root found in '" + label + "'"
            assert ' at perl/FSM/Adapter/ISF/Parser.pm line 118.' in row['error']
            if weak:
                assert row['matched'] == (1 if expected in row['error'] else 0)
            else: assert row['matched'] == 0
    assert seen == {(name, band) for name in contracts for band in
                    ('positive', 'wrong_source_echo', 'wrong_source_plain', 'wrong_label_echo')}

causes(current)
causes(substring, True)
for a, b in zip(current, substring):
    for key in ('id', 'band', 'kind', 'source', 'label', 'expected', 'accepted'):
        same(a[key], b[key])
    assert a['error'].split('\n')[0] == b['error'].split('\n')[0]
# Replay the actual archived Perl predicate over the actual full captured producer errors.
perl = r'''use JSON::PP; use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);
my $j=JSON::PP->new->canonical; my $rows=$j->decode(do {local $/;<STDIN>});
print $j->encode([map {diagnostic_cause_matches($_->{error},$_->{expected})} @$rows]);'''
actual = json.loads(subprocess.check_output(['perl', '-I' + str(BASE / 'instruments/t/lib'),
                                            '-e', perl], input=encoded(current).encode()))
same(actual, [row['matched'] for row in current])
old = json.loads((BASE / 'products.json').read_text())['products']
assert len(old) == 44
if '--old-consumer' in sys.argv:
    label_echo = next(row for row in old if row['band'] == 'wrong_label_echo')
    assert label_echo['matched'] == 0, 'exact prior current assertion accepts actual wrong label cause'
for name in ('source', 'cause', 'acceptance', 'primitive_kind', 'missing_context'):
    bad = copy.deepcopy(current)
    if name == 'source': bad[0]['source'] += '\n'
    elif name == 'cause': bad[1]['error'] = 'wrong cause\n' + bad[1]['error']
    elif name == 'acceptance': bad[1]['matched'] = 1
    elif name == 'primitive_kind': bad[0]['matched'] = True
    else: bad.pop()
    try: causes(bad)
    except AssertionError: print('shared cause corruption rejects:', name)
    else: raise AssertionError('accepted corruption ' + name)

# Reuse exact immutable independently authored source-oracle functions. These
# are product checks only; historical runtime/admission gates are not executed.
for source_archive, cohort in (
    ('conditional-origin-authority-20261002', 'authority'),
    ('conditional-origin-library-20261002', 'same-source'),
    ('conditional-origin-atl-20261002', 'ATL'),
):
    path = Path('docs/audits') / source_archive
    sealed(path, True)
    source_path = path / 'verify.py'; assert source_path.read_bytes() == blob(source_path)
    prefix = source_path.read_text().split('\nproducts = ', 1)[0]
    scope = {}; exec(compile(prefix, str(source_path), 'exec'), scope)
    products = {p.name: json.loads(p.read_text()) for p in (BASE / cohort).glob('*.json')}
    scope['verify_products'](products)
    bad = copy.deepcopy(products)
    chosen = next(iter(bad.values()))
    if cohort == 'authority':
        for field in ('actor', 'reconstructed_actor'):
            chosen[field]['interface']['inputs'][0]['width'] = '1'
    else:
        for field in ('ordinary', 'instrumented'):
            chosen[field]['interface']['inputs'][0]['width'] = '1'
        chosen['proof']['actors'][0]['actor']['interface']['inputs'][0]['width'] = '1'
    try: scope['verify_products'](bad)
    except AssertionError: print('shared whole-product kind corruption rejects:', cohort)
    else: raise AssertionError('accepted whole-product kind ' + cohort)
    print('independent complete products/kinds qualify:', cohort, len(products))
for dependency in ('conditional-origin-documents-finalization-20261002/verify.py',):
    path = Path('docs/audits') / dependency; assert path.read_bytes() == blob(path)
formal_path = Path('docs/audits/local-formal-diagnostic-correction-20261002')
sealed(formal_path, True)
source = formal_path / 'verify.py'; assert source.read_bytes() == blob(source)
scope = {'copy': copy, 'hashlib': hashlib, 'json': json, 'Path': Path, 'sys': sys}
tree = ast.parse(source.read_text())
functions = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name != 'verify']
exec(compile(ast.Module(body=functions, type_ignores=[]), str(source), 'exec'), scope)
new_formal = {p.name: json.loads(p.read_text()) for p in (BASE / 'formal').glob('*.json')}
old_formal = {p.name: json.loads(p.read_text()) for p in (formal_path / 'current-bound').glob('*.json')}
assert set(new_formal) == set(old_formal) and len(new_formal) == 26
for name, value in new_formal.items():
    previous = old_formal[name]
    assert set(value) == set(previous)
    for field in value:
        if field in ('error', 'canonical_error', 'observed_error'):
            assert value[field].split('\n')[0] == previous[field].split('\n')[0]
        elif field == 'controls':
            for current_control, previous_control in zip(value[field], previous[field]):
                assert set(current_control) == set(previous_control)
                for key in current_control:
                    if key == 'error': assert current_control[key].split('\n')[0] == previous_control[key].split('\n')[0]
                    else: same(current_control[key], previous_control[key])
            assert len(value[field]) == len(previous[field])
        else: same(value[field], previous[field])
    if 'literal_operations' in value: scope['product'](value)
bad = copy.deepcopy(new_formal['select.json'])
bad['context']['actor']['interface']['inputs'][0]['width'] = '1'
try: same(bad['context'], old_formal['select.json']['context'])
except AssertionError: print('whole local-formal kind corruption rejects')
else: raise AssertionError('accepted local-formal kind')
print('independent complete local-formal products/kinds and declared first causes qualify: 26')
if (BASE / 'manifest.json').exists(): sealed(BASE)
print('constructor repair: exact archived current predicate/real producer causes, complete source oracles and shared controls qualify')
