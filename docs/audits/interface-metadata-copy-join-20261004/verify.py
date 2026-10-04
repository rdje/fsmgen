"""Independent complete original/current copy/field/member semantic join."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path
BASE = Path(__file__).parent
parser = argparse.ArgumentParser()
parser.add_argument('--omit-copy', action='store_true')
parser.add_argument('--omit-field', action='store_true')
parser.add_argument('--private-authority', action='store_true')
args = parser.parse_args()
subprocess.run(['python3','-B','docs/audits/interface-metadata-copy-repair-20261004/verify.py'],check=True)
if (BASE/'manifest.json').exists():
    manifest=json.loads((BASE/'manifest.json').read_text())
    assert {p.name for p in BASE.iterdir()} == set(manifest)|{'manifest.json'}
    for name,r in manifest.items():
        raw=(BASE/name).read_bytes();assert len(raw)==r['bytes'] and hashlib.sha256(raw).hexdigest()==r['sha256']
inputs=json.loads((BASE/'inputs.json').read_text())
for name,expected in inputs.items():
    audit=Path('docs/audits',name)
    assert json.loads((audit/'manifest.json').read_text())==expected
    assert {p.name for p in audit.iterdir()}==set(expected)|{'manifest.json'}
    for name,r in expected.items():
        raw=(audit/name).read_bytes();assert len(raw)==r['bytes'] and hashlib.sha256(raw).hexdigest()==r['sha256']
old=json.loads(Path('docs/audits/interface-metadata-copy-controls-20261004/ordinary.json').read_text())
pure=json.loads(Path('docs/audits/interface-metadata-copy-controls-20261004/pure.json').read_text())
current=json.loads(Path('docs/audits/interface-metadata-copy-repair-20261004/ordinary.json').read_text())
fields=json.loads(Path('docs/audits/interface-metadata-fields-20261004/fields.json').read_text())
joined=json.loads((BASE/'join.json').read_text())
sources=json.loads(Path('docs/audits/interface-metadata-copy-repair-20261004/sources-after.json').read_text())
for name,body in sources.items():
    assert subprocess.check_output(['git','show','eabc0bb2d2edbdc9d6f54790746e484e1d228879:'+name],text=True)==body

def equal(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(equal(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(equal(x,y) for x,y in zip(a,b))
    return a==b

def changes(a,b,path=''):
    if type(a) is not type(b):return [(path,type(a).__name__,a,type(b).__name__,b)]
    if isinstance(a,list):
        assert len(a)==len(b)
        if len(a)==2 and a[0] in ('hash','array','reference'):
            tag,body=a;assert b[0]==tag
            if tag=='reference':assert body==b[1];return []
            if tag=='hash':
                assert body.keys()==b[1].keys()
                return [r for k in body for r in changes(body[k],b[1][k],path+'/'+k.replace('~','~0').replace('/','~1'))]
            assert len(body)==len(b[1])
            return [r for i,(x,y) in enumerate(zip(body,b[1])) for r in changes(x,y,path+'/'+str(i))]
        return [r for i,(x,y) in enumerate(zip(a,b)) for r in changes(x,y,path+'/'+str(i))]
    return [] if a==b else [(path,type(a).__name__,a,type(b).__name__,b)]

copy_rows=joined['copies'][:-1] if args.omit_copy else joined['copies']
assert [r['original'] for r in copy_rows]==list(range(145)), 'complete original copy correspondence'
assert joined['cycle_copies']==[i for i,r in enumerate(current['copies']) if r['kind']=='cycle']
used=set(); mapping={}
for row,original in zip(copy_rows,old['copies']):
    assert row['source_line']==original['caller'][2]
    if original['kind']=='test' and original['caller'][2] in (41,116):
        assert row['current'] is None and row['role']=='typed readonly snapshot replaces lossy baseline'
        continue
    index=row['current'];assert index not in used;used.add(index);mapping[row['original']]=index
    actual=current['copies'][index];reference=pure['copies'][row['original']]
    assert actual['kind']==original['kind'] and actual['api']==original['api']
    assert row['role']==('strong test fixture copy' if actual['kind']=='test' else 'private detached numeric validation copy')
    for key in ('before','after','copy'):assert equal(actual[key],reference[key])
    assert actual['original_reference_count']==actual['copy_reference_count'] and actual['shared_with_original']==0
    if actual['kind']=='test':assert equal(actual['before'],actual['copy'])
assert used|set(joined['cycle_copies'])==set(range(144)) and len(used)==143
assert len(joined['original_fields'])==94 and joined['original_fields']==fields['rows']
actual_fields=[]
for index,row in enumerate(current['copies']):
    for path,bk,bv,ak,av in changes(row['before'],row['copy']):
        assert row['kind']=='provider' and bk=='int' and ak=='str' and str(bv)==av and bv>0 and path.endswith('/width')
        actual_fields.append({'copy':index,'api':row['api'],'path':path,'before_kind':bk,'before_value':bv,'after_kind':ak,'after_value':av})
selected=joined['current_private_fields'][:-1] if args.omit_field else joined['current_private_fields']
assert sorted(selected,key=lambda r:(r['copy'],r['path']))==sorted(actual_fields,key=lambda r:(r['copy'],r['path'])), 'complete source-qualified current private fields'
assert len(actual_fields)==62 and len({r['copy'] for r in actual_fields})==26
retained=[]
for row in fields['rows']:
    if row['kind']!='provider':continue
    retained.append({'copy':mapping[row['copy']],'api':row['api'],'path':row['path'],'before_kind':row['original']['kind'],'before_value':row['original']['value'],'after_kind':row['copied']['kind'],'after_value':row['copied']['value']})
assert len(retained)==30 and all(r in actual_fields for r in retained)
extra=[r for r in actual_fields if r not in retained]
assert len(extra)==32 and {r['api'] for r in extra}=={94,95,96,98,99,100,101,102}
expected_leaves={
    '/inputs/0/type_spec/members/subtype/width':4,
    '/inputs/0/type_spec/members/payload/members/count/width':3,
    '/inputs/0/type_spec/members/payload/members/lanes/items/0/width':1,
    '/inputs/0/type_spec/members/payload/members/lanes/items/1/width':2,
}
for api in (94,95,96,98,99,100,101,102):
    assert {r['path']:r['before_value'] for r in extra if r['api']==api}==expected_leaves
    assert current['api'][api]['kind']=='capture' and not current['api'][api]['accepted']
# Every private added conversion has the exact original authored leaf value;
# source repair restores its primitive kind before the intentionally lossy
# private clone. Metadata products keep their independently qualified authority.
assert all(equal(a['result'],b['result']) for a,b in zip(current['api'],old['api']))
assert joined['api']==[{'original':i,'current':i,'role':r['kind'],'accepted':r['accepted'],'helper':r['helper']} for i,r in enumerate(old['api'])]
assert sum(r['accepted'] for r in joined['api'])==59
assert [r['current'] for r in joined['consumers']]==list(range(334))
for summary,actual in zip(joined['consumers'],current['consumers']):
    assert all(summary[k]==actual[k] for k in ('label','kind','helper')) and actual['passed']==1
assert sum(r['role']=='strong copy check' for r in joined['consumers'])==168
assert sum(r['role']=='qualified original consumer' for r in joined['consumers'])==166
for index in joined['cycle_copies']:
    r=current['copies'][index];assert equal(r['before'],r['after']) and equal(r['before'],r['copy'])
    assert r['original_reference_count']==r['copy_reference_count']==7 and r['shared_with_original']==0
if args.private_authority:
    assert equal(current['copies'][1]['copy'],current['api'][1]['result']), 'private spelling cannot replace numeric final product authority'
print('PASS complete original145/current144 copy correspondence, original94/current62 width source roles and all105 API/334 consumers join. All41 test copies retain kinds/sharing/isolation; original30 private widths plus32 restored source leaves intentionally stringify. Whole59 final products/caller graphs/primary causes, actual native cycle and repaired fault controls retain authority; no public admission/native-class expansion. Diagnostic defects remain separately owned.')
