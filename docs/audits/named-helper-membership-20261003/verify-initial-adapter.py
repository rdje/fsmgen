"""Independent line/byte membership and unit checks, with closed JSON kinds."""
import copy,hashlib,json,re,subprocess,sys
from pathlib import Path
B=Path(__file__).parent
REVISION='fe8c412afd02507cbdcdd4ca756ce5421af1aed7'
enc=lambda value:json.dumps(value,sort_keys=True,separators=(',',':'))
def blob(path):return subprocess.check_output(['git','show',REVISION+':'+str(path)])
def seal(path,committed=True):
    p=path/'manifest.json'
    if committed:assert p.read_bytes()==blob(p)
    m=json.loads(p.read_text());members=m.get('files',m.get('members'))
    assert set(members)=={str(p.relative_to(path)) for p in path.rglob('*') if p.is_file() and p.name!='manifest.json'}
    for name,row in members.items():
        raw=(path/name).read_bytes();assert enc(row)==enc({'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
for name in ('refusal-oracle-census-20261002','current-diagnostic-lexical-inventory-20261002'):seal(Path('docs/audits')/name)
if (B/'manifest.json').exists():seal(B,False)
hpath=Path('docs/audits/refusal-oracle-census-20261002/candidates.json')
lpath=Path('docs/audits/current-diagnostic-lexical-inventory-20261002/inventory.json')
for p in (hpath,lpath):assert p.read_bytes()==blob(p)
historical=json.loads(hpath.read_text());lexical=json.loads(lpath.read_text())
# Reuse the immutable, separately qualified historical reader, not the current
# producer. It independently reads lines and re-derives original byte spans.
reader=blob('docs/audits/refusal-oracle-census-20261002/verify.py').decode()
namespace={};exec(reader.split('discovery = json.loads',1)[0],namespace)
old_sources=namespace['baseline_sources'](historical['baseline'])
namespace['SOURCES']=old_sources;namespace['verify_discovery'](historical)
assert all(type(r['named_refusal_helper']) is bool for r in historical['records'])
source=namespace['baseline_sources'](REVISION)
selected={}
for name,raw in source.items():
    first=raw.split(b'\n',1)[0]
    if Path(name).suffix in {'.t','.pm','.pl'} or (first.startswith(b'#!') and b'perl' in first):selected[name]=raw
# Current discovery is re-derived line by line; historical lexical boundaries
# are deliberately NOT upgraded into Perl AST/function/caller semantics.
definitions={};tokens=[]
for name,raw in sorted(selected.items()):
    definitions[name]=[];offset=0
    for number,line in enumerate(raw.splitlines(keepends=True),1):
        m=re.match(rb'[ \t]*sub[ \t]+([A-Za-z_]\w*)\b',line)
        if m:
            function=m[1].decode();entry={'offset':offset,'line':number,'token':m[0].decode()}
            definitions[name].append((function,entry))
            if function.startswith(('refus','reject','fail','declin')):tokens.append({'path':name,'function':function,**entry})
        offset+=len(line)
rows=[]
for r in historical['records']:
    name=r['path'];raw=selected.get(name)
    state='missing' if raw is None else 'unchanged' if raw==old_sources[name] else 'changed'
    rows.append({'path':name,'function':r['function'],'historical_line':r['line'],'historical_span_sha256':hashlib.sha256(r['span'].encode('utf8','surrogateescape')).hexdigest(),'named_flag':r['function'].startswith(('refus','reject','fail','declin')),'current_definition_matches':[entry for function,entry in definitions.get(name,[]) if function==r['function']],'file_in_lexical_baseline':name in lexical['files'],'source_state':state})
identifiers=[]
word=lambda n:65<=n<=90 or 97<=n<=122 or 48<=n<=57 or n==95
for r in tokens:
    raw=selected[r['path']];needle=r['function'].encode();positions=[];start=0
    while True:
        pos=raw.find(needle,start)
        if pos<0:break
        start=pos+len(needle)
        if (pos==0 or not word(raw[pos-1])) and (start==len(raw) or not word(raw[start])):positions.append({'offset':pos,'line':raw[:pos].count(b'\n')+1})
    identifiers.append({'path':r['path'],'function':r['function'],'occurrences':positions})
names={r['path'] for r in rows}|{r['path'] for r in tokens}|{'t/2052-isf-local-formal-origin-authority.t'}
expected={'baseline':REVISION,'historical_baseline':historical['baseline'],'lexical_baseline':lexical['baseline'],'units':{'historical_lexical_spans':len(rows),'historical_named_span_instances':len([r for r in rows if r['named_flag']]),'historical_distinct_named_functions':sorted({r['function'] for r in rows if r['named_flag']})},'current_perl_files':{name:{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()} for name,raw in selected.items()},'current_named_definition_tokens':tokens,'current_identifier_tokens':identifiers,'historical_rows':rows,'added_files_since_lexical':sorted(set(selected)-set(lexical['files'])),'removed_files_since_lexical':sorted(set(lexical['files'])-set(selected)),'source_snapshots':{name:selected[name].decode('utf8','surrogateescape') for name in names},'scope':'Line-anchored named-definition and same-file identifier tokens with exact whole sources/Git closure; not parsed functions, calls, framework/dynamic completeness or cause safety. Historical named flag counts span instances; distinct names are a separate unit. Current all-source lexical token inventory is not regenerated.'}
record=json.loads((B/'membership.json').read_text())
def verify(candidate):assert enc(candidate)==enc(expected),'exact membership/unit/kind mismatch'
verify(record)
for name,raw in selected.items():assert Path(name).read_bytes()==raw,name
if '--span-as-name-count' in sys.argv:
    # Actual old conflation: span instances were labelled as distinct prefixes.
    assert record['units']['historical_named_span_instances']==len(record['units']['historical_distinct_named_functions']),'old span/name unit conflation rejects'
for label in ('span_unit','flag_kind','line_kind','source_omission','definition_omission','identifier_offset','unknown_field'):
    bad=copy.deepcopy(record)
    if label=='span_unit':bad['units']['historical_named_span_instances']=len(bad['units']['historical_distinct_named_functions'])
    elif label=='flag_kind':bad['historical_rows'][0]['named_flag']=0
    elif label=='line_kind':bad['current_named_definition_tokens'][0]['line']=float(bad['current_named_definition_tokens'][0]['line'])
    elif label=='source_omission':bad['source_snapshots'].pop(next(iter(bad['source_snapshots'])))
    elif label=='definition_omission':bad['current_named_definition_tokens'].pop()
    elif label=='identifier_offset':bad['current_identifier_tokens'][0]['occurrences'][0]['offset']+=1
    else:bad['unknown']=1
    try:verify(bad)
    except AssertionError:print('shared membership corruption rejects:',label)
    else:raise AssertionError('accepted '+label)
print(json.dumps({'historical_spans':len(rows),'named_span_instances':expected['units']['historical_named_span_instances'],'distinct_function_names':len(expected['units']['historical_distinct_named_functions']),'current_perl_files':len(selected),'current_definition_tokens':len(tokens),'historical_unique_locators':sum(len(r['current_definition_matches'])==1 for r in rows),'scope':'declaration only; runtime/framework/dynamic/current-all-source semantic review remains open'},sort_keys=True))
