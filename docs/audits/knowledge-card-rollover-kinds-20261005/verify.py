"""Supersede private value-only comparisons with Git-bound discrete capture kinds."""
import copy
import hashlib
import json
import subprocess
import sys
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/knowledge-card-rollover-kinds-20261005')
SELECT = Path('docs/audits/knowledge-card-rollover-selection-20261005')
PRIOR = Path('docs/audits/knowledge-card-rollover-20261005')


def same(left, right):
    if type(left) is not type(right):
        return False
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(same(left[key], right[key]) for key in left)
    if isinstance(left, list):
        return len(left) == len(right) and all(same(a, b) for a, b in zip(left, right))
    return left == right


def discrete(value, field='$', counts=None):
    counts = counts if counts is not None else {}
    kind = type(value).__name__; counts[kind] = counts.get(kind, 0) + 1
    if type(value) not in (dict, list, str, int, type(None)):
        raise ValueError('recorded discrete metadata kind at ' + field + ': ' + kind)
    if isinstance(value, dict):
        for key, child in value.items():
            if type(key) is not str:
                raise ValueError('recorded string metadata key at ' + field)
            discrete(child, field + '/' + key, counts)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            discrete(child, field + '/' + str(index), counts)
    return counts


def pins_check(pins, blobs):
    if set(pins) != set(blobs):
        raise ValueError('complete original audit membership')
    for path, raw in blobs.items():
        actual = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
        if not same(pins[path], actual):
            raise ValueError('whole Git-bound original audit: ' + path)


def main():
    pinset = json.loads((BASE / 'original-pins.json').read_text())
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', pinset['revision'], '--', *pinset['roots']], text=True).splitlines()
    assert paths == list(pinset['pins']), 'complete independently enumerated immutable source boundary'
    blobs = {p: subprocess.check_output(['git', 'show', pinset['revision'] + ':' + p]) for p in paths}
    pins_check(pinset['pins'], blobs)
    actual_blobs = {p: Path(p).read_bytes() for p in paths}
    pins_check(pinset['pins'], actual_blobs)
    records = {}
    for path, raw in blobs.items():
        if path.endswith('.json'):
            record = json.loads(raw); discrete(record, path); records[path] = record
    # Independently regenerate the original bounded metadata census.
    census = {}; census_paths = []
    for path, record in records.items():
        if Path(path).parent in (SELECT, PRIOR):
            census_paths.append(path); discrete(record, path, census)
    expected_census = {'roots': [str(SELECT), str(PRIOR)], 'primitive_counts': census, 'boolean_or_float_metadata': []}
    assert same(json.loads((BASE / 'source-kind-census.json').read_text()), expected_census), 'whole original recorded primitive census'
    first = json.loads((BASE / 'first-private-probe.json').read_text())
    writer = json.loads((BASE / 'private-probe-writer-transform.json').read_text())
    initial_wrapper = (BASE / 'first-private-probe-source-reconstruction.txt').read_text()
    assert initial_wrapper.count(writer['old']) == 1 and (BASE / 'probe.py').read_text() == initial_wrapper.replace(writer['old'], writer['new']), 'exact declared reconstruction and non-overwriting writer-guard change'
    assert first['baseline'] == 'accepted' and [r['primitive'] for r in first['controls']] == ['bool', 'float']
    assert all(same(r['result'], {'accepted': True}) for r in first['controls']), 'actual old private kind collision retained'
    assert type(first['controls'][0]['value']) is bool and first['controls'][0]['value'] is True
    assert type(first['controls'][1]['value']) is float and first['controls'][1]['value'] == 1.0
    subprocess.run([sys.executable, '-B', str(BASE / 'probe.py')], check=True, stdout=subprocess.DEVNULL)
    public = json.loads((BASE / 'public-probe.json').read_text())
    assert [r['case'] for r in public] == ['integer', 'boolean', 'integral-float']
    assert same([r['result']['status'] for r in public], [0, 1, 0]), 'actual public Boolean refusal and admitted integral numeric form'
    native_input = records[str(PRIOR / 'native-archive-controls.json')][0]
    for row, value in zip(public, (1, True, 1.0)):
        expected_descriptors = copy.deepcopy(native_input['descriptors']); expected_descriptors[1]['schema_version'] = value
        assert same(row['value'], value) and same(row['descriptors'], expected_descriptors) and same(row['surface'], native_input['surface']), 'complete actual typed public control inputs'
    assert 'must contain scalar values' in public[1]['result']['stderr']
    controls = []
    families = [
        (str(PRIOR / 'descriptors.json'), [0, 'schema_version']),
        (str(SELECT / 'proofs.json'), ['remaining_after_selection', 'files']),
        (str(PRIOR / 'book-authority.json'), ['delta', 'files']),
        ('docs/audits/knowledge-card-rollover-checks-20261005/focused.json', ['status']),
    ]
    for path, route in families:
        original = records[path]; leaf = original
        for key in route:
            leaf = leaf[key]
        assert type(leaf) is int and leaf in (0, 1), 'real equivalent-value collision field'
        for kind, replacement in [('Boolean', bool(leaf)), ('float', float(leaf))]:
            changed = copy.deepcopy(original); parent = changed
            for key in route[:-1]:
                parent = parent[key]
            parent[route[-1]] = replacement
            assert original == changed and not same(original, changed), 'actual value-only equality collision and separating typed comparison'
            try:
                discrete(changed, path)
            except ValueError as error:
                controls.append({'source': path, 'route': route, 'kind': kind, 'refusal': str(error)})
            else:
                raise AssertionError('false-green discrete capture kind: ' + path)
    selected = str(PRIOR / 'verify.py')
    changed = dict(actual_blobs); raw = changed[selected]; changed[selected] = bytes([raw[0] ^ 1]) + raw[1:]
    try:
        pins_check(pinset['pins'], changed)
    except ValueError as error:
        controls.append({'source': selected, 'kind': 'changed programme byte', 'refusal': str(error)})
    else:
        raise AssertionError('false-green original programme identity')
    subprocess.run([sys.executable, '-B', str(PRIOR / 'verify.py')], check=True)
    transform = json.loads((BASE / 'current-transform.json').read_text())
    for path, row in transform['cards'].items():
        assert subprocess.check_output(['git', 'show', pinset['revision'] + ':' + path]) == row['before'].encode(), 'whole actual committed source card'
        assert row['before'].count(transform['old']) == 1 and row['after'] == row['before'].replace(transform['old'], transform['new']), 'only current reverify route changes'
        if '--current' in sys.argv:
            assert Path(path).read_text() == row['after'], 'current qualified card reader route'
    book = json.loads((BASE / 'book-authority.json').read_text())
    assert subprocess.check_output(['git', 'show', pinset['revision'] + ':docs/book/src/90-reference-map.md']) == book['chapter_before'].encode()
    assert book['chapter_after'] == book['chapter_before'].replace('`CLAIM_VERIFICATION.md` defines what earns an actionable quantitative claim:', book['block'] + '`CLAIM_VERIFICATION.md` defines what earns an actionable quantitative claim:')
    def aggregate(raws):
        return {'files': len(raws), 'lines_total': sum(raw.count(b'\n') for raw in raws), 'bytes_total': sum(map(len, raws))}
    original_book = {p: subprocess.check_output(['git', 'show', pinset['revision'] + ':' + p]) for p in book['paths']}
    projected = dict(original_book); projected['docs/book/src/90-reference-map.md'] = book['chapter_after'].encode()
    assert same(book['before'], aggregate(list(original_book.values()))) and same(book['after'], aggregate(list(projected.values())))
    assert same(book['delta'], {k: book['after'][k] - book['before'][k] for k in book['before']})
    original_surfaces = subprocess.check_output(['git', 'show', pinset['revision'] + ':doctrine/live_document_size/surfaces.jsonl'], text=True)
    assert original_surfaces == book['surface_before']
    before_rows = list(map(json.loads, original_surfaces.splitlines())); after_rows = list(map(json.loads, book['surface_after'].splitlines()))
    change = next(r for r in before_rows if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    actual_change = next(r for r in after_rows if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    assert same(actual_change['baseline'], book['before']) and same(actual_change['delta'], book['delta']) and actual_change['owner'] == 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.74'
    change.update(actual_change); assert same(before_rows, after_rows), 'only fresh book publication authority changes'
    if '--current' in sys.argv:
        assert book['block'] in Path('docs/book/src/90-reference-map.md').read_text(), 'current public metadata-kind distinction remains'
        current_rows = list(map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()))
        assert same(next(r for r in current_rows if r.get('surface_id') == 'knowledge_cards'), next(r for r in after_rows if r.get('surface_id') == 'knowledge_cards')), 'owned card allowance/ceiling authority remains unchanged'
    rendered = json.loads((BASE / 'rendered.json').read_text())
    rendered_raw = (BASE / 'rendered.html.txt').read_bytes()
    assert type(rendered['rendered_bytes']) is int and len(rendered_raw) == rendered['rendered_bytes'] and hashlib.sha256(rendered_raw).hexdigest() == rendered['rendered_sha256']
    assert rendered['whole_block_match'] is True and rendered['source_block'] == book['block']
    class Text(HTMLParser):
        def __init__(self):
            super().__init__(); self.parts = []
        def handle_data(self, value):
            self.parts.append(value)
    for raw in [rendered_raw] + ([Path('docs/book/book/90-reference-map.html').read_bytes()] if '--current' in sys.argv else []):
        reader = Text(); reader.feed(raw.decode())
        assert ' '.join(book['block'].split()) in ' '.join(''.join(reader.parts).split()), 'complete captured/current native-rendered kind distinction'
    proof = {'original_revision': pinset['revision'], 'census': census, 'census_paths': census_paths, 'controls': controls,
             'scope': 'Private discrete capture kinds and complete original Git-bound identities; published values remain correct. Public integral float stays valid; exact recorded producer forms are a different boundary.'}
    out = BASE / 'proofs.json'
    if out.exists():
        assert same(json.loads(out.read_text()), proof), 'whole independently regenerated kind proof'
    else:
        out.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    manifest = BASE / 'manifest.json'
    if manifest.exists():
        for path, record in json.loads(manifest.read_text()).items():
            raw = Path(path).read_bytes()
            assert same(record, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}), 'sealed superseding kind qualification'
    print('PASS Git-bound original source/programme/proof/receipt seals, exact discrete recorded kinds and genuine schema/headroom/delta/status controls; public Boolean refuses and integral numeric form remains valid.')


if __name__ == '__main__':
    main()
