"""Independent saved-source/product verification; no compiler or source replay."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parent
PRIOR = Path('docs/audits/conditional-macro-intent-20261002')
BASELINE = '985e5e9707cd987a7b70a878f0c686ad36e191d6'
OPS = {'when', 'select', 'min', 'max', 'cond', 'when-bit', 'unless-bit', 'when-field', 'unless-field'}
EXTRAS = {'let_select', 'for_select', 'while_field', 'repeat_bit', 'switch_cond',
          'nested_calls', 'reused_calls', 'nested_cond', 'twin_macro', 'twin_authored', 'first_samples'}
GUARDS = {
    'let_select': ['allow', ['!', 'allow']], 'for_select': ['allow', ['!', 'allow']],
    'while_field': [['==', ['&', 'datain', "3'd6"], "3'd2"]],
    'repeat_bit': [['==', ['&', 'datain', "3'd2"], "3'd0"]],
    'switch_cond': ['allow', ['!', 'allow']], 'nested_calls': ['allow', ['!', 'allow']],
    'reused_calls': ['allow', 'start'],
    'nested_cond': ['allow', 'start', ['!', 'start'], ['!', 'allow']],
    'twin_macro': ['allow', ['!', 'allow']], 'twin_authored': ['allow', ['!', 'allow']],
}

def encoded(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def same(a, b, message):
    assert encoded(a) == encoded(b), message

def source_tree(source):
    # This finite source reader does no expansion, substitution, type resolution
    # or scheduling. It reconstructs original input lists independently of Perl.
    tokens = re.findall(r'"(?:\\.|[^"\\])*"|;[^\n]*|[()]|[^\s();]+', source)
    tokens = [t for t in tokens if not t.startswith(';')]
    stack, roots = [], []
    for token in tokens:
        if token == '(':
            node = []
            (stack[-1] if stack else roots).append(node)
            stack.append(node)
        elif token == ')':
            assert stack, 'source closing delimiter'
            stack.pop()
        else:
            assert stack, 'source atom outside list'
            stack[-1].append(json.loads(token) if token.startswith('"') else token)
    assert not stack and len(roots) == 1 and roots[0][0] == 'actor'
    actor = roots[0]
    transactions, procs = [], {}
    for form in actor[2:]:
        if not isinstance(form, list) or not form:
            continue
        if form[0] == 'transaction':
            transactions.append({'name': form[1], 'clauses': [n for n in form[2:]
                if not (isinstance(n, list) and n and n[0] in {'ports', 'domain'})]})
        elif form[0] == 'proc':
            procs[form[1]] = {'body': [n for n in form[2:]
                if not (isinstance(n, list) and n and n[0] == 'params')]}
    return {'transactions': transactions, 'procs': procs}

def arrays(value, path):
    # Enumerate the entire finite input/product tree, rather than reusing the
    # observer's body-context walker or reference registry.
    if isinstance(value, list):
        if value and isinstance(value[0], str) and value[0] in OPS | {'call'}:
            yield path, value
        for i, child in enumerate(value):
            yield from arrays(child, path + [i])

def catalog_from_source(source):
    original = source_tree(source)
    result = []
    for i, tx in enumerate(original['transactions']):
        for path, node in arrays(tx['clauses'], ['transactions', i, 'clauses']):
            result.append({'owner': {'kind': 'transaction', 'name': tx['name']},
                'path': path, 'operation': node[0], 'source_form': node})
    for name in sorted(original['procs']):
        for path, node in arrays(original['procs'][name]['body'], ['procs', name, 'body']):
            result.append({'owner': {'kind': 'procedure', 'name': name},
                'path': path, 'operation': node[0], 'source_form': node})
    return result

def product(name, data):
    actor, ledger = data['instrumented'], data['ledger']
    same(actor, data['ordinary'], name + ' whole actor parity/kinds')
    assert type(ledger['schema_version']) is int and ledger['schema_version'] == 1
    assert ledger['actor_sha256'] == sha(encoded(actor)), name + ' actor fingerprint'
    assert ledger['source_sha256'] == sha(data['source'].encode()), name + ' complete source fingerprint'
    same(ledger['catalog'], catalog_from_source(data['source']), name + ' original source catalog')
    wanted = []
    for i, tx in enumerate(actor['transactions']):
        wanted += [(path, node) for path, node in arrays(tx['clauses'], ['transactions', i, 'clauses'])
                   if node[0] in OPS]
    found = []
    for group in ['entries', 'residuals']:
        for entry in ledger[group]:
            assert set(entry) == {'path', 'target', 'origin'}, name + ' closed entry fields'
            found.append((entry['path'], entry['target']))
            origin = entry['origin']
            assert set(origin) == {'catalog_id', 'branch_ordinal', 'calls'}
            assert type(origin['catalog_id']) is int
            record = ledger['catalog'][origin['catalog_id']]
            op = record['operation']
            assert op in OPS
            assert (entry['target'][0] == 'when') == (group == 'entries')
            ordinal = origin['branch_ordinal']
            if group == 'residuals':
                assert entry['target'][0] == op and ordinal is None
            elif op == 'when':
                assert ordinal is None
            else:
                limit = len(record['source_form']) - 1 if op == 'cond' else 2 if op in {'select', 'min', 'max'} else 1
                assert type(ordinal) is int and 0 <= ordinal < limit
            for frame in origin['calls']:
                assert set(frame) == {'catalog_id', 'procedure', 'context'}
                assert type(frame['catalog_id']) is int
                call = ledger['catalog'][frame['catalog_id']]
                assert call['operation'] == 'call' and call['source_form'][1] == frame['procedure']
    same(sorted(found, key=lambda x: encoded(x[0])), sorted(wanted, key=lambda x: encoded(x[0])), name + ' full path/target coverage')
    if (PRIOR / 'current' / (name + '.json')).exists():
        old = json.loads((PRIOR / 'current' / (name + '.json')).read_text())
        assert data['source'] == old['source']
        same(actor, old['actor'], name + ' immutable actual predecessor actor/kinds')
    elif name in GUARDS:
        same([e['target'][1] for e in ledger['entries']], GUARDS[name], name + ' independent authored guards')
    if name in EXTRAS - {'first_samples'}:
        # These declared scalar-width fixtures deliberately retain the public
        # parser's string declaration and numeric finalized metadata separately.
        inputs = {p['name']: p for p in actor['interface']['inputs']}
        assert type(inputs['datain']['width']) is str and inputs['datain']['width'] == '3'
        meta = {p['name']: p for p in actor['interface_port_metadata']}
        assert type(meta['datain']['width']) is int and meta['datain']['width'] == 3
    if name == 'nested_calls':
        same([f['procedure'] for f in ledger['entries'][0]['origin']['calls']], ['outer','inner'], 'ordered literal call chain')
        same([f['context'] for f in ledger['entries'][0]['origin']['calls']],
             ["transaction 'main'", "transaction 'main' -> proc 'outer'"], 'ordered literal call context')
    if name == 'reused_calls':
        ids = [e['origin']['calls'][0]['catalog_id'] for e in ledger['entries']]
        assert len(set(ids)) == 2, 'distinct real source call sites'
    if name == 'first_samples':
        assert not ledger['entries'] and len(ledger['residuals']) == 1
        assert ledger['catalog'][ledger['residuals'][0]['origin']['catalog_id']]['operation'] == 'cond'

def census():
    data = json.loads((BASE / 'production.json').read_text())
    assert data['baseline'] == BASELINE
    current = subprocess.check_output(['git','ls-tree','-r','-z',BASELINE,'--','bin','perl'])
    assert current == (BASE / 'production.zlist').read_bytes()
    assert not subprocess.check_output(['git','ls-files','--others','--exclude-standard','-z','--','bin','perl'])
    for path, record in data['members'].items():
        p = Path(path)
        raw = p.readlink().as_posix().encode() if p.is_symlink() else p.read_bytes()
        assert len(raw) == record['bytes'] and sha(raw) == record['sha256'], path
    parents = json.loads((BASE / 'immutable-parents.json').read_text())
    for path, record in parents['members'].items():
        raw = Path(path).read_bytes()
        assert len(raw) == record['bytes'] and sha(raw) == record['sha256'], path

def main():
    for run, status, summary in [('current-bound', 0, 'Files=1, Tests=54'), ('no-carry-bound', 1, 'Files=1, Tests=43')]:
        recipe = json.loads((BASE / (run + '-recipe.json')).read_text())
        assert recipe['before'] == recipe['after'] and recipe['status'] == status
        assert summary in (BASE / recipe['stdout']).read_text()
        assert ('Result: PASS' if status == 0 else 'Result: FAIL') in (BASE / recipe['stdout']).read_text()
        for path, digest in recipe['before'].items():
            if path == '.artifacts/conditional-origin/run_qualified.py':
                raw = (BASE / 'run_qualified.py').read_bytes()
            elif path == '.artifacts/conditional-origin/red_no_carry.t':
                raw = (BASE / 'red_no_carry.t').read_bytes()
            else:
                raw = Path(path).read_bytes()
            assert sha(raw) == digest, path + ' bound input/producer identity'
    cases = json.loads((PRIOR / 'cases.json').read_text())
    families = ['select','min','max','when_bit','unless_bit','when_field','unless_field','cond']
    expected = {p + '_' + f for f in families for p in ['first','later']}
    expected |= {p + '_' + f + '_sample' for f in families[3:] for p in ['first','later']}
    expected |= {p + '_proc_' + f for f in ['select','when_bit','cond'] for p in ['first','later']}
    expected |= {'first_proc_when_sample','first_when_sample','first_select_zero','first_bit_sample_zero',
        'initialized_select','nested_select','domain_first_select','domain_later_select','domain_first_sample',
        'first_generated_select','later_generated_select'}
    assert {c['name'] for c in cases} == expected and len(cases) == 43
    inputs = {p.stem: json.loads(p.read_text()) for p in (BASE / 'current-corrected').glob('*.json')}
    assert set(inputs) == expected | EXTRAS
    for name, data in inputs.items():
        product(name, data)
    same(inputs['twin_macro']['ordinary'], inputs['twin_authored']['ordinary'], 'complete normalized twin equivalence')
    assert {r['operation'] for r in inputs['twin_macro']['ledger']['catalog']} == {'select'}
    assert {r['operation'] for r in inputs['twin_authored']['ledger']['catalog']} == {'when'}
    for name in expected:
        bad = json.loads((BASE / 'no-carry' / (name + '.json')).read_text())
        assert bad['instrumented'] is None and bad['ledger'] is None
        assert 'conditional origin' in bad['error']
        assert bad['source'] == inputs[name]['source']
        same(bad['ordinary'], inputs[name]['ordinary'], name + ' counterfactual unchanged parser input')
    rejects = []
    for mutation in ['omission','forged_catalog','shared_target','shared_width_kind','schema_kind']:
        bad = copy.deepcopy(inputs['first_select'])
        if mutation == 'omission':
            bad['ledger']['entries'].pop()
        elif mutation == 'forged_catalog':
            bad['ledger']['catalog'][0]['owner']['name'] = 'forged'
        elif mutation == 'shared_target':
            for key in ['ordinary','instrumented']:
                bad[key]['transactions'][0]['clauses'][0][1] = 'start'
            bad['ledger']['entries'][0]['target'][1] = 'start'
            bad['ledger']['actor_sha256'] = sha(encoded(bad['instrumented']))
        elif mutation == 'shared_width_kind':
            for key in ['ordinary','instrumented']:
                next(p for p in bad[key]['interface']['inputs'] if p['name']=='datain')['width'] = 3
            bad['ledger']['actor_sha256'] = sha(encoded(bad['instrumented']))
        else:
            bad['ledger']['schema_version'] = '1'
        try:
            product('first_select', bad)
        except AssertionError:
            rejects.append(mutation)
        else:
            raise AssertionError('independent hostile control admitted ' + mutation)
    census()
    if (BASE / 'manifest.json').exists():
        manifest = json.loads((BASE / 'manifest.json').read_text())
        paths = {str(p.relative_to(BASE)) for p in BASE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
        assert paths == set(manifest['members'])
        for path, record in manifest['members'].items():
            raw = (BASE / path).read_bytes()
            assert len(raw) == record['bytes'] and sha(raw) == record['sha256'], path
    print('PASS complete fixed 54-source parser origin membership, original source catalogs, full actors/kinds and actual path/target coverage')
    print('PASS identical normalized twins retain distinct authored intent; exact nested/reused calls and unexpanded first sample cond remain explicit')
    print('PASS genuine no-carry RED, unchanged production/immutable predecessors and independent hostile controls: ' + ', '.join(rejects))

if __name__ == '__main__':
    main()
