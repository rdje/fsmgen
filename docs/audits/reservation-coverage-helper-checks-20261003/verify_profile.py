import ast,hashlib,json,subprocess
from pathlib import Path
B=Path('docs/audits/reservation-coverage-helper-causes-20261003')
C=Path('docs/audits/reservation-coverage-helper-checks-20261003')
manifest=json.loads((B/'manifest.json').read_text())
assert {path.name for path in B.iterdir() if path.is_file()}==set(manifest)|{'manifest.json'}
for name,record in manifest.items():
    raw=(B/name).read_bytes()
    assert len(raw)==record['bytes'] and hashlib.sha256(raw).hexdigest()==record['sha256'],name
assert not subprocess.check_output(['git','ls-files','--others','--exclude-standard','--','bin','perl','t','scripts','isf'])
source=(C/'explore.py').read_text()
function=next(node for node in ast.parse(source).body if isinstance(node,ast.FunctionDef) and node.name=='diffs')
exec(ast.get_source_segment(source,function))
contracts=ast.parse((B/'contracts.py').read_text())
expected=ast.literal_eval(next(node.value for node in contracts.body if isinstance(node,ast.Assign)))
assert expected==json.loads((B/'declared-causes.json').read_text())
bindings=json.loads((B/'bindings.json').read_text())
rev=bindings['baseline'];assert rev=='f0e2ddc90aa78b6ce2f1c0097f47bb2fa3f5956a'
members={}
for entry in subprocess.check_output(['git','ls-tree','-r','-z',rev,'--','bin','perl','t','scripts','isf']).split(b'\0'):
    if not entry:continue
    header,name=entry.split(b'\t',1);members[name.decode()]=header.decode().split()[2]
assert set(members)==set(bindings['metadata'])
for name,record in bindings['metadata'].items():
    raw=Path(name).read_bytes()
    assert len(raw)==record['bytes'] and hashlib.sha256(raw).hexdigest()==record['sha256'],name
    assert hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()==members[name]==record['blob'],name
for name,record in bindings['sources'].items():assert record==Path(name).read_text(),name
rows=json.loads((B/'initial-observations-unqualified.json').read_text())
assert len(rows['api'])==23 and len(rows['consumers'])==13 and len(rows['clones'])==62
assert sum(row['accepted'] for row in rows['api'])==10
for i,row in enumerate(rows['api']):assert not diffs(row['before'],row['after']),('actual caller difference',i)
assert {row['label'].removesuffix(' diagnosed') for row in rows['consumers']}==set(expected)
assert [row['api_index'] for row in rows['consumers']]==list(range(3,16))
for row in rows['consumers']:
    index=row['api_index'];assert not rows['api'][index]['accepted']
    assert row['error'].split('\n')[0]==expected[row['label'].removesuffix(' diagnosed')]
changes=[]
for i,row in enumerate(rows['clones']):
    assert not diffs(row['before'],row['after']),('actual clone original difference',i)
    delta=diffs(row['before'],row['clone'])
    if delta:changes.append({'index':i,'line':row['line'],'differences':delta})
assert len(changes)==41
assert {line:sum(row['line']==line for row in changes) for line in {row['line'] for row in changes}}=={29:2,50:9,55:6,94:13,114:11}
assert json.loads(json.dumps(changes))==json.loads((C/'clone-differences-unqualified.json').read_text())
assert (B/'initial-observed-unqualified.status').read_text().strip()=='0'
assert 'Files=1, Tests=5,' in (B/'initial-observed-unqualified.txt').read_text()
# Sample identity/count/preservation falsifiers only: behavioral wrong-cause and
# complete clone-field semantic legs remain explicitly owned by .4.2/.4.3.
corrupt=json.loads(json.dumps(rows));corrupt['api'].pop()
assert len(corrupt['api'])!=23
corrupt=json.loads(json.dumps(rows['api'][0]['after']))
corrupt[1][0][1]['actor'][1]['actor_name']='forged_profile_actor'
try:
    diffs(rows['api'][0]['before'],corrupt)
except AssertionError as error:
    assert str(error)=='/1/0/1/actor/1/actor_name'
else:
    raise AssertionError('caller value corruption escaped the profile reader')
print('PASS bounded source/profile counts, actual original/API kind preservation and source-declared genuine causes; sample omission/caller corruption reject.')
print('UNQUALIFIED: wrong-cause behavior and whole clone-field/projection/result/carrier semantics; .4.2/.4.3 own these missing legs, P2 .2.3.13 owns repair after qualification.')
