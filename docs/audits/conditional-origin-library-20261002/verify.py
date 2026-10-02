import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

root = Path('docs/audits/conditional-origin-library-20261002')
baseline = 'e95955e704c452e41277e3c402ce832912d700f5'
ops = {'when', 'call', 'select', 'min', 'max', 'when-bit', 'unless-bit', 'when-field', 'unless-field', 'cond'}

def encoded(value): return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False)

# Independently parse the restricted complete authored fixture grammar. Source
# atoms remain literal strings; typed port/storage widths are checked separately.
def read_source(source):
    tokens = re.findall(r'\(|\)|[^\s()]+', source)
    position = 0
    def form():
        nonlocal position
        token = tokens[position]
        position += 1
        if token != '(': return token
        result = []
        while tokens[position] != ')': result.append(form())
        position += 1
        return result
    result = []
    while position < len(tokens): result.append(form())
    return result

def catalog(form):
    txs = [node for node in form[2:] if node[0] == 'transaction']
    procs = sorted([node for node in form[2:] if node[0] == 'proc'], key=lambda node: node[1])
    result = []
    for kind, forms in (('transaction', txs), ('procedure', procs)):
        for index, node in enumerate(forms):
            clauses = [clause for clause in node[2:] if clause[0] != 'params']
            for offset, clause in enumerate(clauses):
                if clause[0] not in ops: continue
                path = ['transactions', index, 'clauses', offset] if kind == 'transaction' else ['procs', node[1], 'body', offset]
                result.append({'owner': {'kind': kind, 'name': node[1]}, 'path': path,
                    'operation': clause[0], 'source_form': clause})
    return result

def normalized_body(family):
    set_data, set_other = ['set','seen','datain'], ['set','seen','other']
    sample = ['sample','other','as','captured']
    if family in ('select', 'proc_select', 'twin_authored'):
        return [['when','allow',set_data],['when',['!','allow'],set_other]]
    if family in ('min', 'max'):
        predicate = ['<=' if family == 'min' else '>=','datain','other']
        return [['when',predicate,set_data],['when',['!',predicate],set_other]]
    if family in ('when-bit', 'unless-bit', 'when-field', 'unless-field'):
        field = family.endswith('field')
        positive = family.startswith('when')
        predicate = ['==' if field == positive else '!=',
            ['&','datain',"3'd6" if field else "3'd2"],
            "3'd2" if field else "3'd0"]
        return [['when',predicate,sample]]
    if family == 'authored': return [['when','allow',['sample','datain','as','captured']]]
    if family == 'cond': return [['when','allow',['sample','datain','as','captured']],
        ['when',['!','allow'],['sample','other','as','saved']]]
    assert family == 'proc_cond'
    return [['cond',['allow',['sample','datain','as','captured']],['else',['sample','other','as','saved']]]]

def verify_products(products):
    families = ['select','min','max','when-bit','unless-bit','when-field','unless-field','cond','authored','proc_select','proc_cond']
    names = sorted([position + '_' + family + '.json' for family in families for position in ('first','later')]
        + ['reused_export.json','identical_export_twins.json'])
    assert sorted(products) == names and len(names) == 24
    for name in names:
        product = products[name]
        case, source, label = product['case'], product['source'], product['label']
        actor, proof = product['instrumented'], product['proof']
        assert encoded(actor) == encoded(product['ordinary']), name
        assert proof['source_label'] == label == case['name'] + '.isf'
        assert proof['source_sha256'] == hashlib.sha256(source.encode()).hexdigest()
        assert proof['actor_sha256'] == hashlib.sha256(encoded(actor).encode()).hexdigest()
        forms = read_source(source)
        parent = next(form for form in forms if form[0] == 'actor')
        libraries = [form for form in forms if form[0] == 'library']
        actors = [(None,parent)] + [(library[1],node) for library in libraries for node in library[2:] if node[0] == 'actor']
        assert len(proof['actors']) == len(actors) == 3 and proof['root_actor_id'] == 0
        expected_libraries = []
        for library in libraries:
            exports = next(node for node in library[2:] if node[0] == 'exports')
            mapping = {entry[1]: next(i for i, (lib, form) in enumerate(actors) if lib == library[1] and form[1] == entry[1]) for entry in exports[1:]}
            expected_libraries.append({'name': library[1], 'source_label': label, 'exports': mapping})
        assert encoded(proof['libraries']) == encoded(expected_libraries), name
        for i, (library, form) in enumerate(actors):
            record = proof['actors'][i]
            assert record['actor_id'] == i and record['source_label'] == label
            assert record['library'] == library and record['actor_name'] == form[1]
            assert encoded(record['ledger']['catalog']) == encoded(catalog(form)), (name,i)
            assert record['ledger']['source_sha256'] == proof['source_sha256']
            assert record['ledger']['actor_sha256'] == hashlib.sha256(encoded(record['actor']).encode()).hexdigest()
            inputs = record['actor']['interface']['inputs']
            assert [p['name'] for p in inputs] == ['start','allow','datain','other']
            assert encoded([p['width'] for p in inputs]) == '[1,1,"3","3"]'
            if i == 0:
                assert encoded(record['actor']) == encoded(actor)
                clauses = [['when','allow',['sample','datain','as','captured_parent']],['complete','parent_done']]
            else:
                family = 'twin_authored' if case.get('twins') and i == 2 else case['family']
                clauses = ([] if case['position'] == 'first' else [['on','start']]) + normalized_body(family) + [['complete','done']]
            assert encoded(record['actor']['transactions'][0]['clauses']) == encoded(clauses), (name,i)
            expected_nodes = [(offset,node) for offset,node in enumerate(clauses) if node[0] in ops]
            entries = record['ledger']['entries'] + record['ledger']['residuals']
            assert len(entries) == len(expected_nodes), (name,i)
            for branch_index, (entry, (offset,node)) in enumerate(zip(entries, expected_nodes)):
                assert entry['path'] == ['transactions',0,'clauses',offset]
                assert encoded(entry['target']) == encoded(node)
                original = record['ledger']['catalog'][entry['origin']['catalog_id']]
                expected_op = 'when' if i == 0 or (case.get('twins') and i == 2) or case['family'] == 'authored' else case['family'].replace('proc_', '')
                assert original['operation'] == expected_op
                procedure = bool(i and case['family'].startswith('proc_'))
                calls = [{'catalog_id':0,'procedure':'choose','context':"transaction 'main'"}] if procedure else []
                assert encoded(entry['origin']['calls']) == encoded(calls)
                assert entry['origin']['catalog_id'] == (1 if procedure else branch_index if expected_op == 'when' else 0)
                assert entry['origin']['branch_ordinal'] == (None if expected_op == 'when' or node[0] == 'cond' else branch_index)
        imports = next(node for node in parent[2:] if node[0] == 'imports')
        aliases = {node[3]: node[1] for node in imports[1:]}
        uses = [node for node in parent[2:] if node[0] == 'use']
        assert len(proof['uses']) == len(actor['library_uses']) == len(uses) == 2
        for i, use in enumerate(uses):
            alias, export = use[1].split('.')
            library = aliases[alias]
            expected_id = next(mapping['exports'][export] for mapping in expected_libraries if mapping['name'] == library)
            edge = proof['uses'][i]
            record = proof['actors'][expected_id]
            actual = actor['library_uses'][i]
            assert edge['actor_id'] == expected_id and edge['path'] == ['library_uses',i,'actor']
            assert edge['library'] == library and edge['export'] == export and edge['alias'] == alias
            assert edge['instance'] == actual['instance'] == use[3]
            assert edge['module'] == actual['module'] == 'library_top__' + use[3]
            assert edge['source_label'] == actual['library_source'] == label
            assert encoded(edge['target']) == encoded(record['actor']) == encoded(actual['actor'])
            assert encoded(edge['ledger']) == encoded(record['ledger'])
            assert encoded(edge['bindings']) == encoded(actual['bindings'])
            assert encoded(edge['parameter_overrides']) == encoded(actual['parameter_overrides']) == encoded([{'name':'WIDTH','value':str(i + 2)}])
        if case.get('twins'):
            assert encoded(proof['uses'][0]['target']) == encoded(proof['uses'][1]['target'])
            assert proof['uses'][0]['actor_id'] != proof['uses'][1]['actor_id']
        if case.get('reuse'): assert proof['uses'][0]['actor_id'] == proof['uses'][1]['actor_id']

products = {p.name: json.loads(p.read_text()) for p in (root / 'current-bound').glob('*.json')}
verify_products(products)
for corruption in ['shared_width_kind', 'shared_source_operation', 'wrong_export_id', 'shared_instance', 'shared_omission']:
    bad = copy.deepcopy(products)
    sample = bad['identical_export_twins.json']
    proof = sample['proof']
    if corruption == 'shared_width_kind':
        for actor in (sample['ordinary'],sample['instrumented'],proof['actors'][0]['actor']):
            actor['interface']['inputs'][0]['width'] = '1'
        proof['actor_sha256'] = hashlib.sha256(encoded(sample['instrumented']).encode()).hexdigest()
        proof['actors'][0]['ledger']['actor_sha256'] = proof['actor_sha256']
    elif corruption == 'shared_source_operation':
        for ledger in (proof['actors'][1]['ledger'],proof['uses'][0]['ledger']): ledger['catalog'][0]['operation'] = 'when'
    elif corruption == 'wrong_export_id': proof['uses'][0]['actor_id'] = 2
    elif corruption == 'shared_instance':
        proof['uses'][0]['instance'] = 'forged'
        sample['ordinary']['library_uses'][0]['instance'] = 'forged'
        sample['instrumented']['library_uses'][0]['instance'] = 'forged'
    else:
        for ledger in (proof['actors'][1]['ledger'],proof['uses'][0]['ledger']): ledger['entries'].pop()
    try: verify_products(bad)
    except AssertionError: pass
    else: raise AssertionError('shared corruption accepted: ' + corruption)

reds = list((root / 'red-bound').glob('*.json'))
assert len(reds) == 24
for path in reds:
    red = json.loads(path.read_text())
    assert red['source'] == products[path.name]['source'] and red['label'] == products[path.name]['label']
    assert encoded(red['ordinary']) == encoded(products[path.name]['ordinary']) and red['actor'] is None
    assert 'library origin selected export association missing' in red['diagnostic']
assert 'All tests successful.' in (root / 'current-bound.tap').read_text()
assert 'Files=1, Tests=27,' in (root / 'current-bound.tap').read_text()
assert 'actual changed target refuses before frozen proof publication' in (root / 'current-bound.tap').read_text()
assert 'Failed 1/1 subtests' in (root / 'red-late.txt').read_text()
assert 'All tests successful.' in (root / 'late-fixed.txt').read_text()
assert 'Failed 24/24 subtests' in (root / 'red-bound.tap').read_text()
normalization = json.loads((root / 'normalization.json').read_text())
for name in ('current-bound','red-bound'):
    recipe = json.loads((root / (name + '-recipe.json')).read_text())
    assert recipe['before'] == recipe['after'] and recipe['exit_status'] == recipe['expected_status'] == (0 if name == 'current-bound' else 1)
    for path, digest in recipe['before'].items():
        assert hashlib.sha256(Path(normalization.get(path,path)).read_bytes()).hexdigest() == digest
originals = json.loads((root / 'originals.json').read_text())
for path, entry in originals.items():
    raw = Path(path).read_bytes()
    assert hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest() == entry['git_blob']
    assert hashlib.sha256(raw).hexdigest() == entry['sha256']
assert not subprocess.check_output(['git','diff',baseline,'--','bin','perl'])
if (root / 'manifest.json').exists():
    files = {str(p.relative_to(root)): {'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
        for p in sorted(root.rglob('*')) if p.is_file() and p.name != 'manifest.json'}
    assert files == json.loads((root / 'manifest.json').read_text())['files']
print('PASS independent complete source catalogs/scopes/clone edges/normalized bodies/types, bound genuine missing-export RED, five shared corruptions and exact immutable originals; imported consumer trust remains closed')
