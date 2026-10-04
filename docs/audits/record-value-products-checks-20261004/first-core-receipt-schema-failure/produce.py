"""Produce complete original actor/value/core source product joins."""
import json
from pathlib import Path
from product_model import records
from source_roots import read, exact

BASE = Path('docs/audits/record-value-products-20261004')
native = read('runtime', 'ordinary.json')
data = records(native)
assert [row['index'] for row in data['apis']] == list(range(len(native['api'])))
assert [row['index'] for row in data['private']] == [i for i, row in enumerate(native['copies']) if row['kind'] != 'test']
for row in data['actors'] + data['apis']:
    assert exact(row['expected_product'], row['whole_native']['result'])
(BASE / 'products.json').write_text(json.dumps(data, sort_keys=True, indent=2) + '\n')
print('PASS all four original actor outcomes and 9283 value/core source product records, complete 680 own private clone/field links and parse allocation retained. Completed independent semantic child oracles remain required.')
