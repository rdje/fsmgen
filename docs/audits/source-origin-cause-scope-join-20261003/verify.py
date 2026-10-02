"""Independent bounded historical/current source join; not all consumer signoff."""
import copy,hashlib,json,re,subprocess,sys
from pathlib import Path
B=Path(__file__).resolve().parent.relative_to(Path.cwd().resolve())
record=json.loads((B/'join.json').read_text());revision=record['baseline']
enc=lambda x:json.dumps(x,sort_keys=True,separators=(',',':'),ensure_ascii=False)
def blob(path):return subprocess.check_output(['git','show',revision+':'+str(path)])
def seal(path,prior=True):
    manifest=path/'manifest.json'
    if prior:assert manifest.read_bytes()==blob(manifest)
    m=json.loads(manifest.read_text());members=m.get('files',m.get('members'));assert isinstance(members,dict)
    assert set(members)=={str(p.relative_to(path)) for p in path.rglob('*') if p.is_file() and p.name!='manifest.json'}
    for name,row in members.items():
        raw=(path/name).read_bytes();assert enc(row)==enc({'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
if (B/'manifest.json').exists():seal(B,False)
parent_names=('source-origin-refusal-review-20261002','source-origin-constructor-causes-20261002','constructor-cause-repair-20261002','origin-helper-cause-repair-20261002','validator-finalizer-cause-repair-20261003')
for name in parent_names:seal(Path('docs/audits')/name)
oldpath=Path('docs/audits/source-origin-refusal-review-20261002/inventory.json');assert oldpath.read_bytes()==blob(oldpath);old=json.loads(oldpath.read_text())
ctorpath=Path('docs/audits/source-origin-constructor-causes-20261002/bindings.json');assert ctorpath.read_bytes()==blob(ctorpath);constructors=json.loads(ctorpath.read_text())['statements']
newpath=Path('docs/audits/validator-finalizer-cause-repair-20261003/changes.json');assert newpath.read_bytes()==blob(newpath);validators=json.loads(newpath.read_text())
assert not set(constructors)&set(validators['old']) and len(constructors)==7 and len(validators['old'])==10
expected=[]
for site in sorted(set(constructors)|set(validators['old'])):
    path,line=site.rsplit(':',1);source=blob(path).decode();historical=next(r for r in old['sites'] if r['path']==path and r['line']==int(line));text=old['sources'][path]['source'];prior=text[historical['offset']:text.index(';',historical['offset'])+1]
    if site in constructors:
        assert prior==constructors[site]
        snapshot=Path('docs/audits/constructor-cause-repair-20261002/instruments')/path;assert snapshot.read_bytes()==blob(snapshot)
        description=re.search(r"'([^'\n]*)'\s*\);\s*$",prior)[1]
        candidates=[m.group() for m in re.finditer(r'\bok\(diagnostic_cause_matches\b[\s\S]*?;',snapshot.read_text()) if description in m.group()];assert len(candidates)==1;current=candidates[0];family='constructor';archive='constructor-cause-repair-20261002'
    else:
        assert prior==validators['old'][site];current=validators['new'][site];family='validator_finalizer';archive='validator-finalizer-cause-repair-20261003'
    assert source.count(current)==1 and prior not in source
    offset=source.index(current)
    expected.append({'site':site,'family':family,'historical_offset':historical['offset'],'historical_statement':prior,'current_statement':current,'current_offset':offset,'current_line':source[:offset].count('\n')+1,'proof_archive':archive})
expected_record={'baseline':revision,'rows':expected,'sources':{path:blob(path).decode() for path in old['sources']},'historical_lexical_sites':old['sites'],'scope':'Historical17 raw assertions only; other family helpers/structured/trace sites and additional current controls remain explicitly separate; no whole-repository current semantic signoff.'}
def join(candidate):assert enc(candidate)==enc(expected_record)
join(record)
if '--historical-as-current' in sys.argv:
    bad=copy.deepcopy(record);bad['rows'][0]['current_statement']=bad['rows'][0]['historical_statement'];join(bad)
for name in ('omission','line_kind','old_statement','archive','extra_row_field'):
    bad=copy.deepcopy(record)
    if name=='omission':bad['rows'].pop()
    elif name=='line_kind':bad['rows'][0]['current_line']=True
    elif name=='old_statement':bad['rows'][0]['current_statement']=bad['rows'][0]['historical_statement']
    elif name=='archive':bad['rows'][0]['proof_archive']='wrong-parent'
    else:bad['rows'][0]['unknown']=1
    try:join(bad)
    except AssertionError:print('shared source join corruption rejects:',name)
    else:raise AssertionError('accepted '+name)
# Explicit extra membership: existing repaired library/file helpers and newer
# permanent constructor/validator tests. No parsed-call/current-all-source claim.
for path in ('t/2046-isf-library-document-origin-authority.t','t/2048-isf-file-document-origin-authority.t'):
    source=record['sources'][path];assert 'return diagnostic_cause_matches($error, $expected);' in source
for path in ('t/2053-isf-constructor-diagnostic-causes.t','t/2054-isf-validator-finalizer-diagnostic-causes.t','t/lib/FSM/Test/DiagnosticCause.pm'):
    assert Path(path).read_bytes()==blob(path)
assert 'my $subject=$ENV{FSMGEN_FORMAL_DIAGNOSTIC_FULL_STACK} ? $error : first_line($error);' in record['sources']['t/2052-isf-local-formal-origin-authority.t']
# Cold parent commands are read-only archived-product checks, not current
# compiler/native execution or universal runtime evidence.
for name in ('constructor-cause-repair-20261002','origin-helper-cause-repair-20261002','validator-finalizer-cause-repair-20261003'):
    path=Path('docs/audits')/name/'verify.py';assert path.read_bytes()==blob(path)
    result=subprocess.run(['python3',str(path)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    assert result.returncode==0,result.stdout.decode()
    print('sealed current proof replay passes:',name)
print('historical17 raw/current exact causes joined; other family/current/cold consumers remain owned, with scoped additional helper/test membership')
