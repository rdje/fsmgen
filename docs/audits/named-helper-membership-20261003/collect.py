"""Byte/Git membership declaration; tokens are not parsed Perl functions or calls."""
import hashlib, json, re, subprocess
from pathlib import Path
B=Path(__file__).parent
H=Path('docs/audits/refusal-oracle-census-20261002/candidates.json')
L=Path('docs/audits/current-diagnostic-lexical-inventory-20261002/inventory.json')
def sources(revision):
    names=subprocess.check_output(['git','ls-tree','-r','--name-only',revision,'--','t','perl','scripts','bin']).decode().splitlines()
    pipe=subprocess.Popen(['git','cat-file','--batch'],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
    result={}
    try:
        for name in names:
            pipe.stdin.write((revision+':'+name+'\n').encode());pipe.stdin.flush()
            header=pipe.stdout.readline().split();assert len(header)==3 and header[1]==b'blob'
            result[name]=pipe.stdout.read(int(header[2]));assert pipe.stdout.read(1)==b'\n'
    finally:
        pipe.stdin.close();pipe.stdout.close();assert pipe.wait()==0
    return result

def collect():
    old=json.loads(H.read_text());lex=json.loads(L.read_text())
    revision=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()
    raw=sources(revision)
    selected={name:value for name,value in raw.items() if Path(name).suffix in {'.t','.pm','.pl'} or re.match(rb'#![^\n]*perl',value)}
    digest=lambda value:{'bytes':len(value),'sha256':hashlib.sha256(value).hexdigest()}
    tokens=[]
    for name,value in sorted(selected.items()):
        for m in re.finditer(rb'(?m)^[ \t]*sub[ \t]+((?:refus|reject|fail|declin)\w*)\b',value):
            tokens.append({'path':name,'function':m[1].decode(),'offset':m.start(),'line':value[:m.start()].count(b'\n')+1,'token':m[0].decode()})
    rows=[]
    for r in old['records']:
        name=r['path'];value=selected.get(name,b'')
        matches=[{'offset':m.start(),'line':value[:m.start()].count(b'\n')+1,'token':m[0].decode()} for m in re.finditer(rb'(?m)^[ \t]*sub[ \t]+'+r['function'].encode()+rb'\b',value)]
        rows.append({'path':name,'function':r['function'],'historical_line':r['line'],'historical_span_sha256':r['span_sha256'],'named_flag':r['named_refusal_helper'],'current_definition_matches':matches,'file_in_lexical_baseline':name in lex['files'],'source_state':'missing' if name not in selected else 'unchanged' if digest(value)==old['producers'][name] else 'changed'})
    names={r['path'] for r in rows}|{r['path'] for r in tokens}|{'t/2052-isf-local-formal-origin-authority.t'}
    identifiers=[]
    for row in tokens:
        value=selected[row['path']]
        identifiers.append({'path':row['path'],'function':row['function'],'occurrences':[{'offset':m.start(),'line':value[:m.start()].count(b'\n')+1} for m in re.finditer(rb'\b'+row['function'].encode()+rb'\b',value)]})
    for name,value in selected.items():assert Path(name).read_bytes()==value,name
    return {'baseline':revision,'historical_baseline':old['baseline'],'lexical_baseline':lex['baseline'],'units':{'historical_lexical_spans':len(rows),'historical_named_span_instances':sum(r['named_flag'] for r in rows),'historical_distinct_named_functions':sorted({r['function'] for r in rows if r['named_flag']})},'current_perl_files':{name:digest(value) for name,value in sorted(selected.items())},'current_named_definition_tokens':tokens,'current_identifier_tokens':identifiers,'historical_rows':rows,'added_files_since_lexical':sorted(set(selected)-set(lex['files'])),'removed_files_since_lexical':sorted(set(lex['files'])-set(selected)),'source_snapshots':{name:selected[name].decode('utf8','surrogateescape') for name in sorted(names)},'scope':'Line-anchored named-definition and same-file identifier tokens with exact whole sources/Git closure; not parsed functions, calls, framework/dynamic completeness or cause safety. Historical named flag counts span instances; distinct names are a separate unit. Current all-source lexical token inventory is not regenerated.'}
if __name__=='__main__':
    result=collect();(B/'membership.json').write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
    print(json.dumps({'units':result['units'],'current_perl_files':len(result['current_perl_files']),'current_named_tokens':len(result['current_named_definition_tokens']),'added':result['added_files_since_lexical'],'removed':result['removed_files_since_lexical']},sort_keys=True))
