"""Requalify complete source products and first causes without production replay."""
import copy
import hashlib
import json
import subprocess
import sys
from pathlib import Path

BASE = Path(__file__).parent
PRIOR = Path('docs/audits/conditional-origin-documents-finalization-20261002')


def authenticate(directory):
    members = json.loads((directory / 'manifest.json').read_text())['files']
    assert set(members) == {str(p.relative_to(directory)) for p in directory.rglob('*')
                            if p.is_file() and p.name != 'manifest.json'}
    for name, bound in members.items():
        raw = (directory / name).read_bytes()
        assert len(raw) == bound['bytes'] and hashlib.sha256(raw).hexdigest() == bound['sha256']


authenticate(PRIOR)
authenticate(Path('docs/audits/conditional-origin-library-20261002'))
# Execute only immutable independent source-reader/catalog/product definitions
# and their saved-source bootstrap; exclude historical live binding/run checks.
source = (PRIOR / 'verify.py').read_text()
scope = {}
exec(compile(source[:source.index('\nproducts =')], str(PRIOR / 'verify.py'), 'exec'), scope)
oracle = scope['verify_products']
original_names = set(scope['names']) | {'aliases.json', 'precedence.json', 'source-twin.json', 'finalization.json'}
expected = {
    'actual constructor positive': 'library origin independent document set required',
    'independently supplied wrong complete bytes': 'library origin selected source bytes differ from authority',
    'actual selected document missing': 'library origin selected document authority missing',
    'unused supplied document is not accepted as a graph member': 'library origin authoritative document membership differs',
    'absent independent source authority': 'library origin independent document set required',
    'absolute persisted search root': 'library origin repository-relative document identity required',
    'escaping persisted search root': 'library origin repository-relative document identity required',
    'actual producer form mutation cannot forge a selected document': 'library origin actual selected form differs from authority',
    'package remains closed': 'library origin package source authority is not qualified',
    'ATL remains closed': 'library origin ATL source authority is not qualified',
    'matching embedded digest does not replace original authority': 'library origin proof differs from authoritative document set'}


def boundaries(rows, bypass=False):
    assert [row['name'] for row in rows] == list(expected)
    for row in rows:
        flag = 1 if bypass and row['name'] == list(expected)[-1] else 0
        assert type(row['accepted']) is int and row['accepted'] == flag
        if flag:
            assert row['error'] == ''
        else:
            subject = row['error'] if '--full-stack' in sys.argv else row['error'].splitlines()[0]
            if '--full-stack' in sys.argv:
                assert expected[row['name']] in subject
            else:
                assert expected[row['name']] == subject


bands = {}
for band in ('current-bound', 'full-stack-red', 'bypass-red'):
    values = {p.name: json.loads(p.read_text()) for p in (BASE / band).glob('*.json')}
    assert set(values) == original_names | {'boundaries.json', 'diagnostic-echo.json'}
    normal = {name: values[name] for name in original_names}
    oracle(normal, red=(band == 'bypass-red'))
    for name in scope['names']:
        for row in values[name]['controls']:
            if band == 'bypass-red':
                assert row['diagnostic'] == ''
            else:
                cause = 'actor' if row['name'] in ('actor_identity', 'actor_kind') else 'proof'
                assert row['diagnostic'].splitlines()[0] == (
                    'library origin ' + cause + ' differs from authoritative document set')
    for row in values['finalization.json']['controls']:
        clause = 'coverage' if row['name'] == 'coverage' else 'target or identity'
        assert row['diagnostic'].splitlines()[0] == 'library origin final use ' + clause + ' differs'
    boundaries(values['boundaries.json'], bypass=(band == 'bypass-red'))
    echo = values['diagnostic-echo.json']
    assert echo['error'].splitlines()[0] == 'library origin independent document set required'
    assert echo['expected'] in echo['error']
    assert type(echo['matched']) is int and echo['matched'] == (1 if band == 'full-stack-red' else 0)
    recipe = json.loads((BASE / (band + '-recipe.json')).read_text())
    assert recipe['before'] == recipe['after'] and recipe['status'] == recipe['expected'] == (0 if band == 'current-bound' else 1)
    for name, sha in recipe['before'].items():
        assert hashlib.sha256(Path(name).read_bytes()).hexdigest() == sha
        if name.startswith(('bin/', 'perl/', 't/lib/')):
            assert hashlib.sha256(subprocess.check_output([
                'git', 'show', recipe['baseline'] + ':' + name])).hexdigest() == sha
    bands[band] = values

wrong = json.loads((BASE / 'wrong-boundary.json').read_text())
assert wrong['error'].splitlines()[0] == 'library origin independent document set required'
assert wrong['expected'] in wrong['error']
bad = copy.deepcopy(bands['current-bound']['boundaries.json'])
bad[1]['error'] = wrong['error']
try:
    boundaries(bad)
except AssertionError:
    pass
else:
    raise AssertionError('actual wrong first cause was accepted from a caller echo')
for label in ('missing', 'cause', 'kind'):
    bad = copy.deepcopy(bands['current-bound']['boundaries.json'])
    if label == 'missing':
        bad.pop()
    elif label == 'cause':
        bad[1]['error'] = 'unrelated failure'
    else:
        bad[1]['accepted'] = False
    try:
        boundaries(bad)
    except AssertionError:
        pass
    else:
        raise AssertionError('shared boundary corruption accepted: ' + label)
for corruption in ['shared_width_kind','shared_actor_omission','shared_source_operation','shared_instance','wrong_constructor']:
    bad = copy.deepcopy({name:bands['current-bound'][name] for name in original_names}); sample = bad['identical_export_twins.json']
    if corruption == 'shared_width_kind':
        for actor in (sample['ordinary'],sample['instrumented'],sample['proof']['actors'][0]['actor']): actor['interface']['inputs'][0]['width'] = '1'
    elif corruption == 'shared_actor_omission':
        for actor in (sample['ordinary'],sample['instrumented'],sample['proof']['actors'][0]['actor']): actor['transactions'][0]['clauses'].pop()
    elif corruption == 'shared_source_operation':
        for ledger in (sample['proof']['actors'][1]['ledger'],sample['proof']['uses'][0]['ledger']): ledger['catalog'][0]['operation'] = 'when'
    elif corruption == 'shared_instance':
        for actor in (sample['ordinary'],sample['instrumented'],sample['proof']['actors'][0]['actor']): actor['library_uses'][0]['instance'] = 'forged'
        sample['proof']['uses'][0]['instance'] = 'forged'
    else: bad['aliases.json']['proof']['uses'][0]['actor_id'] = 3
    try: oracle(bad)
    except AssertionError: pass
    else: raise AssertionError('independent shared corruption accepted: ' + corruption)

print('PASS complete independent source/actor/proof/kind/alias/finalizer products, exact first causes, '
      'actual wrong-reason caller echo and three boundary/five whole-product shared corruptions; original archives intact')
