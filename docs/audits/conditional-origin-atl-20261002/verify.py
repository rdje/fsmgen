import ast
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

root = Path('docs/audits/conditional-origin-atl-20261002')
previous = Path('docs/audits/conditional-origin-library-20261002')
baseline = 'f392e33a491d7798193f72447cfb564f0152da4a'
def encoded(v): return json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=False)
def digest(v): return hashlib.sha256(v.encode()).hexdigest()
scope = {'json':json,'hashlib':hashlib,'re':re,'copy':copy,'digest':digest,
    'ops':{'when','call','select','min','max','when-bit','unless-bit','when-field','unless-field','cond'}}
for path in (previous / 'verify.py',Path('docs/audits/conditional-origin-documents-finalization-20261002/verify.py')):
    tree = ast.parse(path.read_text())
    functions = [node for node in tree.body if isinstance(node,ast.FunctionDef)]
    exec(compile(ast.Module(body=functions,type_ignores=[]),str(path),'exec'),scope)
originals = {p.name:json.loads(p.read_text()) for p in (previous / 'current-bound').glob('*.json')}
scope['originals'] = originals
source_form, read_source, expected_base = scope['source_form'],scope['read_source'],scope['expected_product']

def expected_product(original,label,documents,atl_only=False):
    forms = read_source(original['source'])
    parent = copy.deepcopy(next(form for form in forms if form[0] == 'actor'))
    base_documents = copy.deepcopy(documents)
    base_documents[label] = source_form(parent)
    actor, proof = expected_base(original,label,base_documents)
    if atl_only:
        parent = [node for node in parent if not isinstance(node,list) or node[0] != 'use']
        actor['uses'] = []; actor['library_uses'] = []
        proof['uses'] = []; proof['resolutions'] = []
    target = 'other_lib.worker' if original['case'].get('twins') else 'lib.worker'
    parent.append(['instance','first_node','of',target])
    assert documents[label] == source_form(parent), 'complete authored root and static declaration'
    alias, export = target.split('.')
    constructor = (2 if original['case'].get('twins') else 1) + (0 if atl_only else 2)
    if not atl_only:
        for i in (1,2):
            record = copy.deepcopy(proof['actors'][i]); record['actor_id'] = i + 2; proof['actors'].append(record)
        atl_libraries = copy.deepcopy(proof['libraries'])
        for library in atl_libraries: library['exports'] = {key:value+2 for key,value in library['exports'].items()}
        proof['libraries'] += atl_libraries
    else: atl_libraries = copy.deepcopy(proof['libraries'])
    library = next(x for x in atl_libraries if export in x['exports'] and x['exports'][export] == constructor)
    record = proof['actors'][constructor]
    module = 'library_top__first_node'
    declaration = {'name':'first_node','actor_type':target,'declaration':'actor','type_resolution':'library_actor_export',
        'library':library['name'],'alias':alias,'export':export,'module':module,'scheduled_fsm':module+'.fsm'}
    resolution = {'library':library['name'],'library_source':record['source_label'],'alias':alias,'export':export,
        'kind':'actor','instance':'first_node','module':module,'scheduled_fsm':module+'.fsm','actor':copy.deepcopy(record['actor'])}
    network = {key:[] for key in ('groups','event_waits','transaction_triggers','data_movements','association_schedules','group_schedules')}
    network.update(kind='static_declaration',instances=[declaration])
    actor['actor_network'] = network
    actor['_atl_actor_type_resolutions'] = {'first_node':resolution}
    proof['source_sha256'] = digest(documents[label])
    proof['actor_sha256'] = digest(encoded(actor))
    proof['actors'][0]['actor'] = copy.deepcopy(actor)
    proof['actors'][0]['ledger']['source_sha256'] = proof['source_sha256']
    proof['actors'][0]['ledger']['actor_sha256'] = proof['actor_sha256']
    proof['documents'] = [{'source_label':key,'source_sha256':digest(documents[key])} for key in sorted(documents)]
    imports = next(node for node in parent[2:] if node[0] == 'imports')
    proof['atl_resolutions'] = [{'alias':node[3],'library':node[1],
        'source_label':next(lib['source_label'] for lib in atl_libraries if lib['name'] == node[1]),
        'exports':next(lib['exports'] for lib in atl_libraries if lib['name'] == node[1])} for node in imports[1:]]
    proof['atl'] = [{'actor_id':constructor,'instance':'first_node','instance_ordinal':0,
        'path':['_atl_actor_type_resolutions','first_node','actor'],'declaration':copy.deepcopy(declaration),
        'resolution':copy.deepcopy(resolution),'ledger':copy.deepcopy(record['ledger'])}]
    # The contract and actual controls use opaque JSON values, which carry no
    # Python reference aliases between separate serialized export-map views.
    return json.loads(encoded(actor)), json.loads(encoded(proof))

control_names = ['actor_identity','actor_kind','document','producer_kind','producer_swap','source_operation',
    'type','instance','path','coverage','scope','target']
def mutate(name,actor,proof):
    if name == 'actor_identity': actor['actor_name'] = 'forged_actor'
    elif name == 'actor_kind': actor['interface']['inputs'][0]['width'] = '1'
    elif name == 'document': proof['atl'][0]['resolution']['library_source'] = 'forged.isf'
    elif name == 'producer_kind': proof['atl'][0]['actor_id'] = str(proof['atl'][0]['actor_id'])
    elif name == 'producer_swap': proof['atl'][0]['actor_id'] = 1
    elif name == 'source_operation': proof['atl'][0]['ledger']['catalog'][0]['operation'] = 'forged_operation'
    elif name == 'type': proof['atl'][0]['declaration']['actor_type'] = 'lib.forged'
    elif name == 'instance': proof['atl'][0]['declaration']['name'] = 'forged_instance'
    elif name == 'path': proof['atl'][0]['path'][1] = 'second_node'
    elif name == 'coverage': proof['atl'].pop()
    elif name == 'scope': proof['atl_resolutions'][0]['exports']['worker'] = 1
    elif name == 'target': proof['atl'][0]['resolution']['actor']['transactions'][0]['clauses'][0] = ['forged_target']
    else: raise AssertionError(name)

def verify_products(products,red=False):
    assert sorted(products) == sorted(list(originals) + ['atl-only.json','finalization.json'])
    for name, original in originals.items():
        p = products[name]
        assert encoded(p['case']) == encoded(original['case']) and p['baseline_source'] == original['source']
        assert not Path(p['label']).is_absolute() and '..' not in Path(p['label']).parts
        actor, proof = expected_product(original,p['label'],p['documents'])
        assert encoded(p['ordinary']) == encoded(actor) == encoded(p['instrumented']), name
        assert encoded(p['proof']) == encoded(proof), name
        assert [c['name'] for c in p['controls']] == control_names
        for control in p['controls']:
            bad_actor,bad_proof = copy.deepcopy(actor),copy.deepcopy(proof)
            mutate(control['name'],bad_actor,bad_proof)
            assert encoded(control['actor']) == encoded(bad_actor) and encoded(control['proof']) == encoded(bad_proof), (name,control['name'])
            assert encoded([bad_actor,bad_proof]) != encoded([actor,proof])
            assert type(control['accepted']) is int and control['accepted'] == (1 if red else 0)
            if red: assert control['diagnostic'] == ''
            else: assert 'differs from authoritative document set' in control['diagnostic']
    p = products['atl-only.json']; original = originals[p['case']['name']+'.json']
    actor, proof = expected_product(original,p['label'],p['documents'],atl_only=True)
    assert encoded(p['ordinary']) == encoded(p['instrumented']) == encoded(actor)
    assert encoded(p['proof']) == encoded(proof)
    p = products['finalization.json']; original = originals[p['case']['name']+'.json']
    actor, proof = expected_product(original,p['label'],p['documents'])
    assert [c['name'] for c in p['controls']] == ['target','declaration','coverage']
    for control in p['controls']:
        declined = copy.deepcopy(proof); del declined['atl']; del declined['atl_resolutions']
        changed = declined['actors'][0]['actor']
        if control['name'] == 'target': changed['_atl_actor_type_resolutions']['first_node']['actor']['transactions'][0]['clauses'][0][1] = 'forged_guard'
        elif control['name'] == 'declaration': changed['actor_network']['instances'][0]['name'] = 'forged_instance'
        else: del changed['_atl_actor_type_resolutions']['first_node']
        declined['actor_sha256'] = digest(encoded(changed))
        declined['actors'][0]['ledger']['actor_sha256'] = declined['actor_sha256']
        assert control['actor'] is None and encoded(control['declined_proof']) == encoded(declined)
        assert 'ATL origin final ' in control['diagnostic'] and 'differs' in control['diagnostic']

products = {p.name:json.loads(p.read_text()) for p in (root/'current-bound').glob('*.json')}
verify_products(products)
verify_products({p.name:json.loads(p.read_text()) for p in (root/'red-bound').glob('*.json')},red=True)
missing = {p.name:json.loads(p.read_text()) for p in (root/'missing-bound').glob('*.json')}
assert sorted(missing) == sorted(originals)
for name,p in missing.items():
    actor,proof = expected_product(originals[name],p['label'],p['documents'])
    assert encoded(p['ordinary']) == encoded(actor) and p['actor'] is None
    assert 'ATL origin exact selected export association missing' in p['diagnostic']
for corruption in ['shared_target','shared_kind','shared_declaration','wrong_constructor','shared_origin']:
    bad = copy.deepcopy(products); p = bad['identical_export_twins.json']
    if corruption == 'shared_target':
        for actor in (p['ordinary'],p['instrumented'],p['proof']['actors'][0]['actor']): actor['_atl_actor_type_resolutions']['first_node']['actor']['transactions'][0]['clauses'][0] = ['forged_target']
        p['proof']['atl'][0]['resolution']['actor']['transactions'][0]['clauses'][0] = ['forged_target']
    elif corruption == 'shared_kind':
        for actor in (p['ordinary'],p['instrumented'],p['proof']['actors'][0]['actor']): actor['interface']['inputs'][0]['width'] = '1'
    elif corruption == 'shared_declaration':
        for actor in (p['ordinary'],p['instrumented'],p['proof']['actors'][0]['actor']): actor['actor_network']['instances'][0]['actor_type'] = 'forged.Type'
        p['proof']['atl'][0]['declaration']['actor_type'] = 'forged.Type'
    elif corruption == 'wrong_constructor': p['proof']['atl'][0]['actor_id'] = 2
    else:
        for ledger in (p['proof']['atl'][0]['ledger'],p['proof']['actors'][4]['ledger']): ledger['catalog'][0]['operation'] = 'select'
    try: verify_products(bad)
    except AssertionError: pass
    else: raise AssertionError('independent shared corruption accepted: '+corruption)
normalization = json.loads((root/'normalization.json').read_text())
for name,status in [('current-bound',0),('red-bound',1),('missing-bound',1)]:
    recipe = json.loads((root/(name+'-recipe.json')).read_text())
    assert recipe['before'] == recipe['after'] and recipe['exit_status'] == recipe['expected_status'] == status
    for path,sha in recipe['before'].items(): assert hashlib.sha256(Path(normalization.get(path,path)).read_bytes()).hexdigest() == sha
assert 'All tests successful.' in (root/'current-bound.tap').read_text()
assert 'Files=1, Tests=28,' in (root/'current-bound.tap').read_text()
assert not (root/'current-bound-stderr.txt').read_text()
assert 'Failed 24/28 subtests' in (root/'red-bound.tap').read_text()
assert 'Failed 24/24 subtests' in (root/'missing-bound.tap').read_text()
for path,identity in json.loads((root/'originals.json').read_text()).items():
    raw = Path(path).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == identity['sha256']
    assert hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest() == identity['git_blob']
assert not subprocess.check_output(['git','diff',baseline,'--','bin','perl'])
if (root/'manifest.json').exists():
    actual = {str(p.relative_to(root)):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in root.rglob('*') if p.is_file() and p.name!='manifest.json'}
    assert actual == json.loads((root/'manifest.json').read_text())['files']
print('PASS independent complete authored source/document/actor/type/catalog/call/clone/phase scopes, exact ATL controls and declined products, genuine association/bypass RED, five shared corruptions and immutable originals; file-root/preparation/adoption remain closed')
