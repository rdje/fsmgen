import hashlib
import json
import subprocess
from pathlib import Path

root = Path(__file__).parent
baseline = json.loads((root / 'baseline.json').read_text())
assert subprocess.check_output(['git','show',baseline['head']+':perl/Global.pm']) == (root/'before/Global.pm').read_bytes()
assert hashlib.sha256((root/'first-draft/test.t').read_bytes()).hexdigest() == baseline['inputs']['t/2050-global-module-origin.t']
binding = json.loads((root/'diagnostic.json').read_text())
for path, digest in binding['inputs'].items():
    assert hashlib.sha256(Path(path).read_bytes()).hexdigest() == digest
caller = binding['results']['caller-index']
assert caller['status'] == 0 and caller['stderr'] == ''
assert json.loads(caller['stdout']) == {'caller_index':2,'result':{'index':None,'match':'literal_value','match_hash':{},'match_list':['literal_value']}}
for name in ('literal','configuration'):
    actual = binding['results'][name]
    assert actual['status'] == 2 and actual['stderr'] == ''
    assert actual['stdout'] == '(HLinkSubst) -E- Unmatched closing bracket\n'
whole = json.loads((root/'before-complete.json').read_text())
expected_bad = {'retained_name':'','singleton':1,'values':{'':None,'FX_TOP':'cwd','NAME':'','PATH':'cwd','preload_list':{'conf':'','link':''}}}
for i, item in enumerate(whole['products']):
    if i % 2 == 0:
        assert item['success'] == 0 and item['product'] is None
        assert item['stderr'] == 'fileparse(): need a valid pathname at modules/Global.pm line 21.\n'
    else:
        assert item['success'] == 1 and item['stderr'] == '' and item['error'] == ''
        assert item['product'] == expected_bad and json.loads(item['stdout']) == expected_bad
assert whole['products'][:2] == whole['products'][2:]
assert 'Failed: 5' in (root/'before.tap').read_text()
assert 'Failed: 5' in (root/'before-corrected.tap').read_text()
assert 'Failed: 4' in (root/'before-complete.tap').read_text()
print('PASS exact original source/instrument binding, complete defective controls and independent package-index diagnostic; no repair qualified')
