"""Complete source/field/product and raw native observation relationship join."""
import json
from pathlib import Path
from source_roots import read, digest, exact

BASE = Path('docs/audits/record-value-semantics-20261004')
native = read('runtime', 'ordinary.json')
products = read('products', 'products.json')
fields = read('copy-fields', 'fields.json')['rows']
field_join = read('field-join', 'join.json')['copies']
source = json.loads((BASE / 'binding.json').read_text())['sources']['t/1986-isf-record-port-value-gates.t']['body'].splitlines()
helpers = []
for index, row in enumerate(native['helpers']):
    spans = {name: list(range(row[key + '_start'], row[key + '_end']))
        for name, key in (('api', 'api'), ('consumers', 'consumer'), ('parses', 'parse'))}
    helpers.append({'index': index, 'whole_native': row,
        'source_line': source[row['caller'][2] - 1], 'spans': spans,
        'copies': [i for i, copy in enumerate(native['copies']) if copy['helper'] == index]})
consumers = [{'index': index, 'whole_native': row, 'source_line': source[row['caller'][2] - 1],
    'helper_model': digest(helpers[row['helper']]) if row['helper'] is not None else None}
    for index, row in enumerate(native['consumers'])]
copies = []
private = {row['index']: row for row in products['private']}
for index, row in enumerate(native['copies']):
    copies.append({'index': index, 'whole_native': row, 'whole_field': fields[index],
        'completed_field_join': field_join[index], 'private_product': private.get(index),
        'helper_model': digest(helpers[row['helper']]) if row['helper'] is not None else None,
        'parse_product': digest(products['actors'][row['parse']]) if row['parse'] is not None else None})
assert len(copies) == 697 and len(helpers) == 43 and len(consumers) == 125
assert all(exact(row['whole_native'], native['api'][row['index']]) for row in products['apis'])
models = {'authored': read('fields', 'authored-models.json'), 'source': read('copy-fields', 'source-models.json')}
result = {'source_models': models, 'products': products, 'copies': copies, 'helpers': helpers, 'consumers': consumers,
    'qualified_joint_native': digest(read('clones', 'ordinary-reexecuted.json')),
    'qualified_referents': read('clones', 'referents.json'), 'native_host': native['host'], 'native_warnings': native['warnings']}
(BASE / 'semantics.json').write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
print('PASS whole source/field/product/native/observation relationship join retained: 697 copies, 9283 APIs, four parsers, 43 helpers and 125 consumer observations. Complete child semantic and native joint oracles remain required; legacy pass flags and helper patterns do not qualify strong consumer or intended cause assurance.')
