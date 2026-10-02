import hashlib
import json
import subprocess
from pathlib import Path

root = Path(__file__).parent
final = json.loads((root / 'final-binding.json').read_text())
for name, digest in final['inputs'].items():
    assert hashlib.sha256(Path(name).read_bytes()).hexdigest() == digest
assert Path('perl/PathSearch.pm').read_bytes() == (root / 'after.pm').read_bytes()
assert Path('t/2049-pathsearch-module-origin.t').read_bytes() == (root / 'test-final.t').read_bytes()
baseline = json.loads((root / 'baseline.json').read_text())
original = subprocess.check_output(['git', 'show', baseline['head'] + ':perl/PathSearch.pm'])
assert original == (root / 'before/PathSearch.pm').read_bytes()
assert hashlib.sha256(original).hexdigest() == baseline['inputs']['perl/PathSearch.pm']
for name in ('perl/Global.pm', 'perl/HUtils.pm'):
    assert hashlib.sha256(Path(name).read_bytes()).hexdigest() == baseline['inputs'][name]
assert hashlib.sha256((root / 'before/test.t').read_bytes()).hexdigest() == baseline['test_sha256']
expected = {
    'tree_only': {'path': 'tree/data/tree_only.conf', 'bytes': 'tree bytes'},
    'cwd_only': {'path': 'cwd/cwd_only.conf', 'bytes': 'cwd bytes'},
    'extra_path': 'extra/extra_only.custom',
    'retained_extra_path': 'extra/extra_only.custom',
    'missing': None, 'missing_warning': 1,
}

def check(product, red):
    assert len(product['products']) == 4
    for i, item in enumerate(product['products']):
        assert item['style'] == ('relative' if i % 2 == 0 else 'absolute')
        if red and i % 2 == 0:
            assert item['success'] == 0 and item['product'] is None and item['stdout'] == ''
            assert item['stderr'] == 'fileparse(): need a valid pathname at modules/PathSearch.pm line 27.\n'
        else:
            assert item['success'] == 1 and item['stderr'] == '' and item['error'] == ''
            assert item['product'] == expected
            assert json.loads(item['stdout']) == expected
    assert product['products'][:2] == product['products'][2:]

for name, red in [('before', True), ('after', False), ('red-final', True), ('current-final', False)]:
    check(json.loads((root / (name + '.json')).read_text()), red)
assert 'Files=1, Tests=6' in (root / 'red-final.tap').read_text()
assert 'Failed: 2' in (root / 'red-final.tap').read_text()
assert 'Result: PASS' in (root / 'focused-final.tap').read_text()
assert (root / 'global-before.txt').read_text() == 'fileparse(): need a valid pathname at perl/Global.pm line 21.\n'
for key, value in [('success', 0), ('product', {**expected, 'extra_path': 'forged'})]:
    corrupted = json.loads((root / 'current-final.json').read_text())
    corrupted['products'][0][key] = value
    try:
        check(corrupted, False)
    except AssertionError:
        continue
    raise AssertionError('corrupted complete product accepted: ' + key)
print('PASS exact baseline binding, complete fresh-process products, real relative-load RED and hostile product refusals')
