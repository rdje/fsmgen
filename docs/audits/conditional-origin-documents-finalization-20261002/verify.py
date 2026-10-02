import ast
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

root = Path('docs/audits/conditional-origin-documents-finalization-20261002')
previous = Path('docs/audits/conditional-origin-library-20261002')
baseline = 'de856cd10c74bc2114076a1d7913e7ca151ec11d'
def encoded(value): return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False)
def digest(value): return hashlib.sha256(value.encode()).hexdigest()

# Reuse only the immutable independent source reader/catalog/body oracle. Its
# complete prior cohort is rechecked as data, never replayed through a compiler.
tree = ast.parse((previous / 'verify.py').read_text())
scope = {'json':json, 'hashlib':hashlib, 're':re,
    'ops':{'when','call','select','min','max','when-bit','unless-bit','when-field','unless-field','cond'}}
functions = [node for node in tree.body if isinstance(node, ast.FunctionDef)]
exec(compile(ast.Module(body=functions,type_ignores=[]), str(previous / 'verify.py'), 'exec'), scope)
read_source = scope['read_source']
catalog = scope['catalog']
originals = {p.name:json.loads(p.read_text()) for p in (previous / 'current-bound').glob('*.json')}
scope['verify_products'](originals)
def source_form(form): return '(' + ' '.join(source_form(v) if isinstance(v,list) else v for v in form) + ')'

def expected_product(original, label, documents, same_source=False):
    forms = read_source(original['source'])
    parent = next(v for v in forms if v[0] == 'actor')
    libraries = [v for v in forms if v[0] == 'library']
    directory = label.rsplit('/',1)[0]
    labels = {lib[1]:label if same_source else directory + '/' + lib[1] + '.isf' for lib in libraries}
    expected_documents = {label:original['source'] if same_source else source_form(parent)}
    if not same_source: expected_documents.update({labels[lib[1]]:source_form(lib) for lib in libraries})
    assert encoded(documents) == encoded(expected_documents), 'complete original source form/byte partition'
    actor = copy.deepcopy(original['ordinary'])
    for use in actor['library_uses']: use['library_source'] = labels[use['library']]
    proof = copy.deepcopy(original['proof'])
    proof['source_label'] = label
    proof['source_sha256'] = digest(documents[label])
    proof['actor_sha256'] = digest(encoded(actor))
    for record in proof['actors']:
        record['source_label'] = labels[record['library']] if record['library'] else label
        if record['actor_id'] == 0: record['actor'] = copy.deepcopy(actor)
        record['ledger']['source_sha256'] = digest(documents[record['source_label']])
        record['ledger']['actor_sha256'] = digest(encoded(record['actor']))
    for library in proof['libraries']: library['source_label'] = labels[library['name']]
    for edge in proof['uses']:
        edge['source_label'] = labels[edge['library']]
        edge['ledger'] = copy.deepcopy(proof['actors'][edge['actor_id']]['ledger'])
    proof['documents'] = [{'source_label':key,'source_sha256':digest(documents[key])} for key in sorted(documents)]
    imports = next(v for v in parent[2:] if v[0] == 'imports')
    proof['resolutions'] = [{'library':v[1], 'alias':v[3], 'source_label':labels[v[1]],
        'exports':next(x['exports'] for x in proof['libraries'] if x['name'] == v[1])} for v in imports[1:]]
    return actor, proof

control_names = ['actor_identity','actor_kind','schema_kind','document_hash','producer_kind','source_operation',
    'alias','export','instance','path','coverage','target']
def mutation(name, actor, proof):
    if name == 'actor_identity': actor['actor_name'] = 'forged_actor'
    elif name == 'actor_kind': actor['interface']['inputs'][0]['width'] = '1'
    elif name == 'schema_kind': proof['schema_version'] = '1'
    elif name == 'document_hash': proof['documents'][0]['source_sha256'] = 'forged_digest'
    elif name == 'producer_kind': proof['uses'][0]['actor_id'] = str(proof['uses'][0]['actor_id'])
    elif name == 'source_operation': proof['uses'][0]['ledger']['catalog'][0]['operation'] = 'forged_operation'
    elif name == 'alias': proof['uses'][0]['alias'] = 'forged_alias'
    elif name == 'export': proof['uses'][0]['export'] = 'forged_export'
    elif name == 'instance': proof['uses'][0]['instance'] = 'forged_instance'
    elif name == 'path': proof['uses'][0]['path'][1] = 1
    elif name == 'coverage': proof['actors'].pop()
    elif name == 'target': proof['uses'][0]['target']['transactions'][0]['clauses'][0] = ['forged_target']
    else: raise AssertionError(name)

names = sorted(originals)
def verify_products(products, red=False):
    assert sorted(products) == sorted(names + ['aliases.json','precedence.json','source-twin.json','finalization.json'])
    for name in names:
        p, old = products[name], originals[name]
        assert encoded(p['case']) == encoded(old['case']) and p['baseline_source'] == old['source']
        assert not Path(p['label']).is_absolute() and '..' not in Path(p['label']).parts
        assert p['label'] == p['search_roots'][0] + '/authority-root.isf'
        actor, proof = expected_product(old,p['label'],p['documents'])
        assert encoded(p['ordinary']) == encoded(actor) == encoded(p['instrumented']), name
        assert encoded(p['proof']) == encoded(proof), name
        assert [c['name'] for c in p['controls']] == control_names
        for c in p['controls']:
            bad_actor, bad_proof = copy.deepcopy(actor), copy.deepcopy(proof)
            mutation(c['name'],bad_actor,bad_proof)
            assert encoded(c['actor']) == encoded(bad_actor) and encoded(c['proof']) == encoded(bad_proof), (name,c['name'])
            assert encoded([actor,proof]) != encoded([bad_actor,bad_proof])
            assert type(c['accepted']) is int and c['accepted'] == (1 if red else 0)
            if red: assert c['diagnostic'] == ''
            else: assert 'differs from authoritative document set' in c['diagnostic']
    p = products['precedence.json']
    old = originals[p['case']['name'] + '.json']
    actor, proof = expected_product(old,p['label'],p['documents'],same_source=True)
    assert encoded([p['actor'],p['proof']]) == encoded([actor,proof])
    p = products['aliases.json']
    old = originals['reused_export.json']
    docs = copy.deepcopy(p['documents'])
    docs[p['label']] = docs[p['label']].replace('(imports (library common.choice as lib) (library common.choice as again))',
        '(imports (library common.choice as lib))').replace('(use again.worker as second','(use lib.worker as second')
    actor, proof = expected_product(old,p['label'],docs)
    actor['imports'].append({'alias':'again','kind':'library','library':'common.choice'})
    actor['uses'][1]['target'] = 'again.worker'
    actor['library_uses'][1]['alias'] = 'again'
    proof['actor_sha256'] = digest(encoded(actor))
    proof['source_sha256'] = digest(p['documents'][p['label']])
    proof['actors'][0]['actor'] = copy.deepcopy(actor)
    proof['actors'][0]['ledger']['source_sha256'] = proof['source_sha256']
    proof['actors'][0]['ledger']['actor_sha256'] = proof['actor_sha256']
    for i in (1,2):
        record = copy.deepcopy(proof['actors'][i]); record['actor_id'] = i + 2; proof['actors'].append(record)
    library = copy.deepcopy(proof['libraries'][0]); library['exports'] = {'mirror':4,'worker':3}; proof['libraries'].append(library)
    resolution = copy.deepcopy(proof['resolutions'][0]); resolution.update(alias='again',exports={'mirror':4,'worker':3}); proof['resolutions'].append(resolution)
    proof['uses'][1].update(actor_id=3,alias='again')
    proof['documents'] = [{'source_label':k,'source_sha256':digest(p['documents'][k])} for k in sorted(p['documents'])]
    assert encoded(p['actor']) == encoded(p['ordinary']) == encoded(actor)
    assert encoded(p['proof']) == encoded(proof), 'complete exact repeated alias constructors'
    p = products['source-twin.json']
    actor, proof = expected_product(originals['identical_export_twins.json'],p['label'],p['documents'])
    assert encoded([p['actor'],p['proof']]) == encoded([actor,proof])
    other_documents = copy.deepcopy(p['documents'])
    selected = next(k for k in other_documents if k.endswith('/common.choice.isf'))
    other_documents[selected] = other_documents[selected].replace('(select seen allow datain other)',
        '(when allow (set seen datain)) (when (! allow) (set seen other))')
    assert encoded(other_documents) == encoded(p['other_documents']) and other_documents != p['documents']
    other_proof = copy.deepcopy(proof)
    ledger = other_proof['actors'][1]['ledger']
    ledger['source_sha256'] = digest(other_documents[selected])
    form = next(v for v in read_source(other_documents[selected])[0][2:] if v[0] == 'actor')
    ledger['catalog'] = catalog(form)
    for i, entry in enumerate(ledger['entries']): entry['origin'].update(catalog_id=i,branch_ordinal=None)
    other_proof['uses'][0]['ledger'] = copy.deepcopy(ledger)
    other_proof['documents'] = [{'source_label':k,'source_sha256':digest(other_documents[k])} for k in sorted(other_documents)]
    assert encoded(p['other_actor']) == encoded(actor) and encoded(p['other_proof']) == encoded(other_proof)

    p = products['finalization.json']
    old = originals[p['case']['name'] + '.json']
    actor, proof = expected_product(old,p['label'],p['documents'])
    assert [c['name'] for c in p['controls']] == ['target','instance','coverage','parameter_kind']
    for control in p['controls']:
        declined = copy.deepcopy(proof)
        del declined['documents']; del declined['resolutions']
        changed = declined['actors'][0]['actor']
        if control['name'] == 'target': changed['library_uses'][0]['actor']['transactions'][0]['clauses'][0][1] = 'forged_guard'
        elif control['name'] == 'instance': changed['library_uses'][0]['instance'] = 'forged_instance'
        elif control['name'] == 'coverage': changed['library_uses'].pop()
        else: changed['library_uses'][0]['parameter_overrides'][0]['value'] = 2
        declined['actor_sha256'] = digest(encoded(changed))
        declined['actors'][0]['ledger']['actor_sha256'] = declined['actor_sha256']
        assert control['actor'] is None and encoded(control['declined_proof']) == encoded(declined), control['name']
        expected_message = 'library origin final use coverage differs' if control['name'] == 'coverage' else 'library origin final use target or identity differs'
        assert expected_message in control['diagnostic']


products = {p.name:json.loads(p.read_text()) for p in (root / 'current-bound').glob('*.json')}
verify_products(products)
reds = {p.name:json.loads(p.read_text()) for p in (root / 'red-bound').glob('*.json')}
verify_products(reds,red=True)
for corruption in ['shared_width_kind','shared_actor_omission','shared_source_operation','shared_instance','wrong_constructor']:
    bad = copy.deepcopy(products); sample = bad['identical_export_twins.json']
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
    try: verify_products(bad)
    except AssertionError: pass
    else: raise AssertionError('independent shared corruption accepted: ' + corruption)

normalization = json.loads((root / 'normalization.json').read_text())
for name, status in [('current-bound',0),('red-bound',1)]:
    recipe = json.loads((root / (name + '-recipe.json')).read_text())
    assert recipe['before'] == recipe['after'] and recipe['exit_status'] == recipe['expected_status'] == status
    for path, sha in recipe['before'].items(): assert hashlib.sha256(Path(normalization.get(path,path)).read_bytes()).hexdigest() == sha
current = (root / 'current-bound.tap').read_text()
assert 'All tests successful.' in current and 'Files=1, Tests=30,' in current
assert 'Failed 25/30 subtests' in (root / 'red-bound.tap').read_text()
assert not (root / 'current-bound-stderr.txt').read_text()
assert not subprocess.check_output(['git','diff',baseline,'--','bin','perl'])
for path, identity in json.loads((root / 'originals.json').read_text()).items():
    raw = Path(path).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == identity['sha256']
    assert hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == identity['git_blob']
initial = Path('docs/audits/conditional-origin-documents-20261002')
initial_files = {str(p.relative_to(initial)):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in initial.rglob('*') if p.is_file() and p.name != 'manifest.json'}
assert initial_files == json.loads((initial / 'manifest.json').read_text())['files']
assert (root / 'authority-before.pm').read_bytes() == (initial / 'authority-final.pm').read_bytes()
assert 'Failed 1/1 subtests' in (root / 'late-clone-red.txt').read_text()
assert 'All tests successful.' in (root / 'late-clone-fixed.txt').read_text()

if (root / 'manifest.json').exists():
    actual = {str(p.relative_to(root)):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
        for p in root.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    assert actual == json.loads((root / 'manifest.json').read_text())['files']
print('PASS independent complete source partition/document coverage/actors/types/origins/alias constructors, exact mutation/consistent-digest twins/declined finalizer products, genuine late-target and bypass RED, five shared corruptions and immutable originals; ATL/preparation/adoption remain closed')
