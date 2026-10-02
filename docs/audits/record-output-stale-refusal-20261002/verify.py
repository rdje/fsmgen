"""Cold source-boundary qualification; no parser, lowerer or HDL execution."""
import copy
import hashlib
import io
import json
import subprocess
import sys
import tarfile
from pathlib import Path

BASE = Path(__file__).parent


def same(left, right):
    assert json.dumps(left, sort_keys=True, separators=(',', ':')) == (
        json.dumps(right, sort_keys=True, separators=(',', ':')))


def products(rows):
    assert [r['name'] for r in rows] == ['whole-output', 'output-field', 'input-list']
    for row, direction, datatype, clause in zip(rows, ('output', 'output', 'input'),
                                              ('frame', 'frame', 'lanes'),
                                              ('(complete done)', '(set value.flag 1)', '(complete done)')):
        assert row['source'] == (
            '(actor refused (types (type frame (record (flag bit))) (type lanes (list bit bit)))'
            + f' (interface ({direction} value (type {datatype})) (output done))'
            + f' (transaction main {clause}))')
        assert type(row['accepted']) is int
    assert rows[0]['accepted'] == (0 if '--stale-expectation' in sys.argv else 1)
    assert rows[0]['error'] == ''
    same(rows[0]['actor']['interface_port_metadata'], [
        {'name': 'value', 'direction': 'output', 'width': 1, 'type': 'frame', 'type_kind': 'record',
         'fields': [{'path': 'flag', 'width': 1, 'msb': 0, 'lsb': 0, 'signed': 0}]},
        {'name': 'done', 'direction': 'output', 'width': 1}])
    for row, expected in zip(rows[1:], (
        "Invalid ISF record context: transaction 'main' set target record output field writes are not yet admitted; "
        "target 'value.flag' requires output-field writer qualification",
        "Error: actor 'refused' interface port 'value' references aggregate type 'lanes'; this ISF slice accepts "
        "aggregate type aliases only on actor-owned storage variables and packed record actor ports")):
        assert row['accepted'] == 0 and row['actor'] is None
        assert row['error'].splitlines()[0] == expected


rows = json.loads((BASE / 'products.json').read_text())
products(rows)
for label in ('source', 'layout', 'acceptance', 'cause'):
    bad = copy.deepcopy(rows)
    if label == 'source':
        bad[1]['source'] = rows[0]['source']
    elif label == 'layout':
        bad[0]['actor']['interface_port_metadata'][0]['fields'][0]['width'] = 2
    elif label == 'acceptance':
        bad[1]['accepted'] = 1
    else:
        bad[1]['error'] = rows[2]['error']
    try:
        products(bad)
    except AssertionError:
        pass
    else:
        raise AssertionError('corruption accepted: ' + label)

recipe = json.loads((BASE / 'recipe.json').read_text())
original = subprocess.check_output(['git', 'show', recipe['baseline'] + ':t/1986-isf-record-port-value-gates.t'])
assert original == (BASE / 'stale-test.t').read_bytes()
current = Path('t/1986-isf-record-port-value-gates.t').read_bytes()
assert current == (BASE / 'current-test.t').read_bytes()
marker = b"subtest 'deferred output and list-root source carriers remain closed'"
assert original[:original.index(marker)] == current[:current.index(
    b"subtest 'output member writes and list-root source carriers remain closed'")]
archive = subprocess.check_output(['git', 'archive', recipe['baseline'], 'bin', 'perl'])
with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
    producers = {item.name: stream.extractfile(item).read() for item in stream.getmembers() if item.isfile()}
assert set(producers) == set(recipe['producers'])
for name, raw in producers.items():
    assert raw == Path(name).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == recipe['producers'][name]
assert 'Result: FAIL' in (BASE / 'stale-red.txt').read_text()
assert 'Failed: 1' in (BASE / 'stale-red.txt').read_text()
assert 'All tests successful' in (BASE / 'focused.txt').read_text()
print('PASS actual whole-output admission, literal complete interface layout, first-line closed boundaries, '
      'four corruptions, exact stale/current test scope and unchanged production')
