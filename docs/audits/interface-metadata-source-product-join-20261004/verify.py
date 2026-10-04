"""Independent complete source/product/field/caller/consumer and owner join."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path
BASE=Path(__file__).parent
parser=argparse.ArgumentParser()
parser.add_argument('--omit-field',action='store_true')
parser.add_argument('--omit-product',action='store_true')
parser.add_argument('--private-authority',action='store_true')
args=parser.parse_args()
binding=json.loads((BASE/'binding.json').read_text())
for reader in (binding['historical_reader'],binding['assurance_reader']):
    subprocess.run(['python3','-B',reader],check=True)
if (BASE/'manifest.json').exists():
    manifest=json.loads((BASE/'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()}==set(manifest)|{'manifest.json'}
    for name,r in manifest.items():
        raw=(BASE/name).read_bytes();assert len(raw)==r['bytes'] and hashlib.sha256(raw).hexdigest()==r['sha256']
root='SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.2'
task=subprocess.check_output(['git','show',binding['revision']+':'+binding['task']],text=True)
def node(id):
    start=task.index('- ID: `'+id+'`');end=task.index('\n- ID:',start+1)
    return task[start:end]
for suffix in ('.3.1','.3.2','.3.3','.3.3.1','.3.3.2','.3.3.3'):
    n=node(root+suffix);assert 'Status: `done`' in n and 'Verification: `pending`' not in n
assert 'Status: `pending`' in node(root+'.5')
current=json.loads(Path('docs/audits/interface-metadata-copy-repair-20261004/ordinary.json').read_text())
original=json.loads(Path('docs/audits/interface-metadata-fields-20261004/ordinary.json').read_text())
fields=json.loads(Path('docs/audits/interface-metadata-fields-20261004/fields.json').read_text())
copy_join=json.loads(Path('docs/audits/interface-metadata-copy-join-20261004/join.json').read_text())
sources=json.loads(Path('docs/audits/interface-metadata-copy-repair-20261004/sources-after.json').read_text())
for name,body in sources.items():
    assert subprocess.check_output(['git','show',binding['source_revision']+':'+name],text=True)==body
rows=json.loads((BASE/'join.json').read_text())
def equal(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(equal(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(equal(x,y) for x,y in zip(a,b))
    return a==b
selected=rows['original_width_fields'][:-1] if args.omit_field else rows['original_width_fields']
assert equal(selected,fields['rows']) and len(selected)==94,'complete source-meaning original field membership'
assert equal(rows['current_private_source_fields'],copy_join['current_private_fields']) and len(rows['current_private_source_fields'])==62
assert rows['copies']==copy_join['copies'] and rows['cycle_copies']==copy_join['cycle_copies']
assert rows['consumers']==copy_join['consumers']
products=rows['accepted_products'][:-1] if args.omit_product else rows['accepted_products']
expected=[i for i,r in enumerate(original['api']) if r['accepted']]
assert [r['api'] for r in products]==expected and len(products)==59,'complete independently qualified product membership'
for row in products:
    index=row['api'];actual=current['api'][index];model=original['api'][index]
    assert row['kind']==actual['kind']==model['kind'] and equal(row['before'],actual['before'])
    value=current['copies'][1]['copy'] if args.private_authority and index==1 else row['result']
    assert equal(value,actual['result']) and equal(value,model['result']),'source-qualified numeric final product authority'
assert [r['api'] for r in rows['caller_causes']]==list(range(105))
for row,actual,previous in zip(rows['caller_causes'],current['api'],original['api']):
    assert row['kind']==actual['kind']==previous['kind'] and row['accepted']==actual['accepted']==previous['accepted']
    assert equal(row['before'],actual['before']) and equal(row['after'],actual['after']) and equal(row['before'],row['after'])
    assert row['primary']==actual['error'].splitlines()[:1]==previous['error'].splitlines()[:1]
    assert row['warnings']==actual['warnings']==previous['warnings']==[]
print('PASS complete source/historical-context/authored-field/current-copy/native-control/ordinary-product/caller-cause/consumer join. Exact completed owners bind all94 original fields/62 intentional private conversions/59 numeric products/105 callers/334 native consumers and preceding pinned full proof. Copy/read-only/product defects repaired; two contextual diagnostic defects remain separately owned before final T1983 outcome. No source/admission/native-class expansion or broader cold/HDL signoff.')
