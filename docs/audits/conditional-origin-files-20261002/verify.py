"""Verify saved complete file-origin products without replaying a parser/runtime."""
import copy
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path

ROOT = Path('docs/audits/conditional-origin-files-20261002')
PRIOR = Path('docs/audits/conditional-origin-atl-20261002')


def encoded(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()


def digest(value):
    return hashlib.sha256(encoded(value)).hexdigest()


def same(actual, expected, message):
    assert encoded(actual) == encoded(expected), message


def project(value, identities):
    if isinstance(value, list):
        return [project(item, identities) for item in value]
    if isinstance(value, dict):
        return {key: identities[item] if key in ('source_label', 'library_source') else project(item, identities)
                for key, item in value.items()}
    return value


def expected(original, identities, documents):
    actor = project(original['ordinary'], identities)
    proof = project(original['proof'], identities)
    proof['source_sha256'] = hashlib.sha256(documents[proof['source_label']].encode()).hexdigest()
    proof['documents'] = [{'source_label': name, 'source_sha256': hashlib.sha256(source.encode()).hexdigest()}
                          for name, source in sorted(documents.items())]
    for record in proof['actors']:
        record['ledger']['source_sha256'] = hashlib.sha256(documents[record['source_label']].encode()).hexdigest()
        record['ledger']['actor_sha256'] = digest(record['actor'])
    for edge in proof['uses']:
        edge['ledger']['source_sha256'] = hashlib.sha256(documents[edge['source_label']].encode()).hexdigest()
        edge['ledger']['actor_sha256'] = digest(edge['target'])
    for edge in proof['atl']:
        edge['ledger']['source_sha256'] = hashlib.sha256(documents[edge['resolution']['library_source']].encode()).hexdigest()
        edge['ledger']['actor_sha256'] = digest(edge['resolution']['actor'])
    proof['actor_sha256'] = digest(actor)
    return actor, proof


def controls(actor, proof, submitted, bypass):
    names = ['identity', 'document_digest', 'producer_swap', 'source_operation', 'target', 'coverage', 'scalar_kind']
    assert [item['name'] for item in submitted] == names
    for item in submitted:
        a, p = copy.deepcopy(actor), copy.deepcopy(proof)
        name = item['name']
        if name == 'identity':
            p['atl'][0]['resolution']['library_source'] = 'sources/forged.isf'
        elif name == 'document_digest':
            p['documents'][0]['source_sha256'] = '0' * 64
        elif name == 'producer_swap':
            p['atl'][0]['actor_id'] = 1
        elif name == 'source_operation':
            p['uses'][0]['ledger']['catalog'][0]['operation'] = 'forged'
        elif name == 'target':
            a['library_uses'][0]['actor']['actor_name'] = 'forged'
        elif name == 'coverage':
            p['documents'].pop()
        elif name == 'scalar_kind':
            p['atl'][0]['actor_id'] = str(p['atl'][0]['actor_id'])
        same([item['actor'], item['proof']], [a, p], 'exact complete submitted mutation ' + name)
        assert item['accepted'] == (1 if bypass else 0)
        assert (not item['diagnostic']) if bypass else ('differs from authoritative document set' in item['diagnostic'])


def verify_case(product, bypass=False):
    original = json.loads(Path(product['predecessor']).read_text())
    same(product['case'], original['case'], 'immutable case identity')
    assert [item['layout'] for item in product['products']] == ['adjacent', 'search', 'dotted']
    for layout in product['products']:
        identities = {}
        documents = {}
        for old, source in original['documents'].items():
            if old == original['label']:
                new = 'sources/main.isf'
            else:
                new = ('sources/' if layout['layout'] == 'adjacent' else 'libraries/') + Path(old).name
                if layout['layout'] == 'dotted':
                    new = new.replace('common.choice.isf', 'common/choice.isf')
            identities[old] = new
            documents[new] = source
        same(layout['documents'], documents, 'every original source byte and portable identity')
        a, p = expected(original, identities, documents)
        assert len(layout['roots']) == 2
        same(layout['roots'][0], layout['roots'][1], 'every complete moved-root product and refusal')
        for root in layout['roots']:
            same([root['actor'], root['proof']], [a, p], 'whole independent actor/proof/kind oracle')
            same(root['ordinary'], a, 'whole canonical ordinary actor oracle')
            selections = [{'identity': identities[edge['library_source']],
                           'absolute': 1 if layout['layout'] == 'adjacent' else 0}
                          for edge in original['ordinary']['library_uses']]
            same(root['selected'], selections, 'actual selected runtime coordinate kind and identity')
            controls(a, p, root['controls'], bypass)


def verify_auxiliary():
    sources = sorted(p for p in (PRIOR / 'current-bound').glob('*.json')
                     if p.name not in ('atl-only.json', 'finalization.json'))
    original = json.loads(sources[0].read_text())
    for band in ('current-bound', 'red-bound'):
        precedence = json.loads((ROOT / band / 'precedence.json').read_text())
        identities = {old: 'sources/main.isf' if old == original['label'] else 'sources/' + Path(old).name
                      for old in original['documents']}
        docs = {identities[old]: source for old, source in original['documents'].items()}
        same(precedence['documents'], docs, 'complete initial adjacent authority')
        same(precedence['proof'], expected(original, identities, docs)[1], 'whole adjacent selection proof')
        decoys = {}
        for name, source in docs.items():
            if name == 'sources/main.isf':
                continue
            base = Path(name).name
            decoys['libraries/' + base] = source + '\n '
            decoys['other/' + base] = source + '\n  '
            decoys[base] = source + '\n   '
            if base == 'common.choice.isf':
                decoys['sources/common/choice.isf'] = source + '\n    '
        same(precedence['decoys'], decoys, 'complete explicit competing actual files')
        selected = sorted(name for name in docs if name != 'sources/main.isf')[0]
        for key, prefix in [('fallback', 'libraries/'), ('last', 'other/'), ('cwd', '')]:
            new_docs = dict(docs)
            del new_docs[selected]
            name = prefix + Path(selected).name
            new_docs[name] = decoys[name]
            new_ids = {old: name if new == selected else new for old, new in identities.items()}
            same(precedence[key + '_documents'], new_docs, 'complete ' + key + ' authority')
            same(precedence[key + '_proof'], expected(original, new_ids, new_docs)[1], 'whole ' + key + ' selection proof')
        names = ['selected-byte-substitution', 'missing-selected-authority', 'root-byte-substitution',
                 'actual-file-mutation', 'unused-authority', 'deleted-selected-file', 'symlink-library']
        assert [item['name'] for item in precedence['controls']] == names
        assert all(item['accepted'] == 0 and item['diagnostic'] for item in precedence['controls'])
        local = json.loads((ROOT / band / 'same-source.json').read_text())
        local_original = json.loads(Path(local['predecessor']).read_text())
        assert local_original['proof']['uses'][0]['ledger']['catalog'][0]['operation'] == 'select'
        source = '\n'.join([local_original['documents'][local_original['label']]] +
                           [v for k, v in sorted(local_original['documents'].items()) if k != local_original['label']])
        same(local['documents'], {'sources/main.isf': source}, 'exact combined original source bytes')
        a, p = expected(local_original, {old: 'sources/main.isf' for old in local_original['documents']}, local['documents'])
        same([local['actor'], local['proof']], [a, p], 'complete actual repeated same-source original association')
        same(local['decoys'], {'libraries/' + Path(name).name: value + '\n '
                              for name, value in local_original['documents'].items() if name != local_original['label']}, 'same-source shadows')
        assert len(local['controls']) == 6 and all(item['accepted'] == 0 and item['diagnostic'] for item in local['controls'])
    current = json.loads((ROOT / 'form-bound/product.json').read_text())
    red = json.loads((ROOT / 'form-red-bound/product.json').read_text())
    same(current['documents'], red['documents'], 'identical whole actual counterfactual sources')
    same(current['proof']['uses'][0]['ledger'], current['proof']['atl'][0]['ledger'], 'retained original intent')
    assert current['proof']['uses'][0]['ledger']['catalog'][0]['operation'] == 'select'
    assert red['actor'] is None and red['proof'] is None
    assert 'actual selected form differs from authority' in red['diagnostic']
    calls = json.loads((ROOT / 'form-diagnostic.json').read_text())
    assert len(calls) == 2 and calls[1]['before'] == calls[0]['after']
    changed = copy.deepcopy(calls[0]['before'])
    changed[3][5][1][2][1] = 3
    changed[4][5][1][2][1] = 3
    same(changed, calls[0]['after'], 'exact two source width-token scalar coercions')


def verify_bindings():
    baseline = json.loads((ROOT / 'current-bound-recipe.json').read_text())['baseline']
    archive = subprocess.check_output(['git', 'archive', baseline, 'bin', 'perl'])
    with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
        authority = {item.name: hashlib.sha256(stream.extractfile(item).read()).hexdigest()
                     for item in stream.getmembers() if item.isfile()}
    for name, status in [('current-bound', 0), ('red-bound', 1), ('form-bound', 0), ('form-red-bound', 1)]:
        recipe = json.loads((ROOT / (name + '-recipe.json')).read_text())
        assert recipe['before'] == recipe['after'] and recipe['baseline'] == baseline
        assert recipe['exit_status'] == recipe['expected_status'] == status
        for path, identity in recipe['before'].items():
            if path.startswith(('bin/', 'perl/')):
                assert authority[path] == identity
            else:
                assert hashlib.sha256(Path(path).read_bytes()).hexdigest() == identity, path
        tap = (ROOT / (name + '.tap')).read_text()
        if status == 0:
            assert 'All tests successful.' in tap and 'Result: PASS' in tap
        else:
            assert 'Result: FAIL' in tap
        if status == 0:
            assert not (ROOT / (name + '-stderr.txt')).read_text()
    assert (ROOT / 'authority-final.pm').read_bytes() == Path('t/lib/FSM/Test/FileDocumentOriginAuthority.pm').read_bytes()
    assert (ROOT / 'test-final.t').read_bytes() == Path('t/2048-isf-file-document-origin-authority.t').read_bytes()
    assert set(authority) == {p for p in json.loads((ROOT / 'current-bound-recipe.json').read_text())['before']
                              if p.startswith(('bin/', 'perl/'))}


def main():
    verify_bindings()
    manifest = json.loads((PRIOR / 'manifest.json').read_text())['files']
    assert set(manifest) == {str(p.relative_to(PRIOR)) for p in PRIOR.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    for name, item in manifest.items():
        value = (PRIOR / name).read_bytes()
        assert len(value) == item['bytes'] and hashlib.sha256(value).hexdigest() == item['sha256']
    sources = sorted(p for p in (ROOT / 'current-bound').glob('*.json') if p.name not in ('precedence.json', 'same-source.json'))
    expected_names = {p.name for p in (PRIOR / 'current-bound').glob('*.json') if p.name not in ('atl-only.json', 'finalization.json')}
    assert {p.name for p in sources} == expected_names
    assert {p.name for p in (ROOT / 'red-bound').glob('*.json')} == expected_names | {'precedence.json', 'same-source.json'}
    for path in sources:
        value = json.loads(path.read_text())
        verify_case(value)
        verify_case(json.loads((ROOT / 'red-bound' / path.name).read_text()), bypass=True)
    verify_auxiliary()
    sample = json.loads(sources[0].read_text())
    for name in ['document', 'origin', 'scalar-kind', 'move', 'ordinary']:
        bad = copy.deepcopy(sample)
        r = bad['products'][0]['roots'][0]
        if name == 'document':
            bad['products'][0]['documents']['sources/main.isf'] += ' '
        elif name == 'origin':
            r['proof']['atl'][0]['ledger']['catalog'][0]['operation'] = 'forged_shared_origin'
        elif name == 'scalar-kind':
            r['proof']['atl'][0]['actor_id'] = str(r['proof']['atl'][0]['actor_id'])
        elif name == 'move':
            bad['products'][0]['roots'][1]['selected'][0]['identity'] = 'forged.isf'
        elif name == 'ordinary':
            r['ordinary']['actor_name'] = 'forged'
        try:
            verify_case(bad)
        except AssertionError:
            pass
        else:
            raise AssertionError('independent verifier accepted shared corruption ' + name)
    print('PASS complete immutable source/actor/proof/kind/selection/control and moved-root reconstruction; five shared corruptions refuse')


if __name__ == '__main__':
    main()
