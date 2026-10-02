"""Source-derived exact JSON kinds; preserve the original numerical archive."""
import ast,copy,hashlib,json,runpy,subprocess,sys
from pathlib import Path
BASE=Path(__file__).parent
PRIOR=Path('docs/audits/current-diagnostic-lexical-inventory-20261002')
PRIOR_COMMIT='33af62fbdd4a408c3bb88c900f4293f6a35860fd'
manifest=(PRIOR/'manifest.json').read_bytes()
assert manifest==subprocess.check_output(['git','show',PRIOR_COMMIT+':'+str(PRIOR/'manifest.json')])
assert (PRIOR/'verify.py').read_bytes()==subprocess.check_output(['git','show',PRIOR_COMMIT+':'+str(PRIOR/'verify.py')])
# Actual immutable reader re-derives every source/offset/line through Git and rg,
# executes all original numerical controls, and authenticates every prior member.
original=runpy.run_path(str(PRIOR/'verify.py'))
source=ast.parse((PRIOR/'collect.py').read_text())
assignment=next(n for n in source.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='data' for t in n.targets))
scope_text=next(ast.literal_eval(v) for k,v in zip(assignment.value.keys,assignment.value.values) if ast.literal_eval(k)=='scope')
expected_inventory={
'baseline':json.loads((PRIOR/'recipe.json').read_text())['baseline'],
'roots':['t','perl','scripts','bin'],'patterns':original['patterns'],
'files':original['files'],'sites':original['expected'],'scope':scope_text}
expected_counts={'files':len(original['files']),'sites':len(original['expected']),'categories':original['rg_counts']}
def encoded(value):return json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=True,allow_nan=False)
expected_inventory_json=encoded(expected_inventory);expected_counts_json=encoded(expected_counts)
# The counterfactual invokes the exact old predicate and its actual count assertion,
# rather than a model of Python equality or a changed producer.
old_tree=ast.parse((PRIOR/'verify.py').read_text())
old_count_assert=next(n for n in old_tree.body if isinstance(n,ast.Assert) and isinstance(n.test,ast.Compare) and isinstance(n.test.left,ast.Name) and n.test.left.id=='counts')
old_count_code=compile(ast.Module(body=[old_count_assert],type_ignores=[]),str(PRIOR/'verify.py'),'exec')
def verify(candidate,counts):
    if '--old-comparison' in sys.argv:
        original['verify'](candidate)
        exec(old_count_code,dict(original,counts=counts))
    else:
        assert encoded(candidate)==expected_inventory_json, 'exact source-derived inventory/JSON kinds differ'
        assert encoded(counts)==expected_counts_json, 'exact source-derived counts/JSON kinds differ'
verify(original['data'],original['counts'])
line_one=next(i for i,row in enumerate(original['expected']) if row[3]==1)
for label in ('line_boolean','line_float','offset_float','file_bytes_float','file_count_float','category_count_float','unknown_root'):
    candidate=copy.deepcopy(original['data']);counts=copy.deepcopy(original['counts'])
    if label=='line_float':candidate['sites'][0][3]=float(candidate['sites'][0][3])
    elif label=='offset_float':candidate['sites'][0][2]=float(candidate['sites'][0][2])
    elif label=='file_bytes_float':
        name=next(iter(candidate['files']));candidate['files'][name]['bytes']=float(candidate['files'][name]['bytes'])
    elif label=='file_count_float':counts['files']=float(counts['files'])
    elif label=='category_count_float':counts['categories']['sub']=float(counts['categories']['sub'])
    elif label=='line_boolean':
        # JSON true is a different primitive kind from the actual line number 1.
        candidate['sites'][line_one][3]=True
    else:candidate['extra']='unrecognized'
    try:verify(candidate,counts)
    except AssertionError:pass
    else:raise AssertionError('shared JSON-kind/shape corruption accepted: '+label)
if (BASE/'manifest.json').exists():
    members=json.loads((BASE/'manifest.json').read_text())['files']
    assert set(members)=={str(p.relative_to(BASE)) for p in BASE.rglob('*') if p.is_file() and p.name!='manifest.json'}
    for name,bound in members.items():
        raw=(BASE/name).read_bytes();assert len(raw)==bound['bytes'] and hashlib.sha256(raw).hexdigest()==bound['sha256']
print('PASS complete immutable Git/rg census and every prior member; exact source-derived inventory/count JSON kinds, seven shared kind/numeric-form/shape controls; no semantic classification')
