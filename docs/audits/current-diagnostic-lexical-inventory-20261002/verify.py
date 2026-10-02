"""Immutable Git selection plus independent rg byte-offset census."""
import bisect,copy,hashlib,json,re,subprocess,sys
from pathlib import Path
BASE=Path(__file__).parent
data=json.loads((BASE/'inventory.json').read_text())
patterns={
'assertion':r'\b(?:like|unlike|is|is_deeply|cmp_ok|ok|isa_ok|can_ok|pass|fail|BAIL_OUT|throws_ok|dies_ok|lives_ok|exception|warnings_like|warning_like)\b',
'exception':r'\$@|\b(?:eval|confess|croak|die|try|catch|fatal)\b',
'diagnostic_word':r'\b(?:error\w*|diagnostic\w*|stderr|stdout|message|reason|code)\b',
'helper_name':r'\b(?:refus\w*|reject\w*|declin\w*|first_line|diagnostic_matches|diagnostic_line)\b',
'call_like':r'\b[A-Za-z_][A-Za-z_0-9]*[ \t]*\(',
'sub':r'\bsub\b'}
assert data['roots']==['t','perl','scripts','bin'] and data['patterns']==patterns
entries=subprocess.check_output(['git','ls-tree','-r','-z',data['baseline'],'--',*data['roots']]).split(b'\0')
process=subprocess.Popen(['git','cat-file','--batch'],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
sources={}
try:
    for entry in filter(None,entries):
        header,name=entry.split(b'\t',1); mode,kind,sha=header.split()
        assert kind==b'blob' and mode!=b'160000'
        process.stdin.write(sha+b'\n'); process.stdin.flush()
        fields=process.stdout.readline().split(); assert fields[1]==b'blob'
        raw=process.stdout.read(int(fields[2])); assert process.stdout.read(1)==b'\n'
        name=name.decode(); first=raw.partition(b'\n')[0]
        if Path(name).suffix in {'.t','.pm','.pl'} or (first.startswith(b'#!') and b'perl' in first):sources[name]=raw
finally:
    process.stdin.close(); process.stdout.close(); assert process.wait()==0
names=sorted(sources); starts=[]; chunks=[]; offset=0; line_offsets={}
for name in names:
    raw=sources[name]; starts.append(offset); chunks.append(raw+b'\n'); offset+=len(raw)+1
    line_offsets[name]=[m.start() for m in re.finditer(b'\n',raw)]
corpus=b''.join(chunks); expected=[]; rg_counts={}
for category,pattern in patterns.items():
    if category=='exception' and '--drop-exception' in sys.argv:continue
    result=subprocess.run(['rg','--json','--no-unicode','--text',pattern,'-'],input=corpus,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    assert result.returncode in (0,1) and result.stderr==b''
    count=0
    for line in result.stdout.splitlines():
        record=json.loads(line)
        if record['type']!='match':continue
        row=record['data']
        for match in row['submatches']:
            absolute=row['absolute_offset']+match['start']; index=bisect.bisect_right(starts,absolute)-1
            name=names[index]; local=absolute-starts[index]; raw=sources[name]
            assert 0<=local<local+match['end']-match['start']<=len(raw), 'cross-document match'
            token=raw[local:local+match['end']-match['start']].decode('ascii')
            assert match['match']=={'text':token}
            expected.append([name,category,local,bisect.bisect_left(line_offsets[name],local)+1,token]); count+=1
    rg_counts[category]=count
expected.sort()
files={name:{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()} for name,raw in sorted(sources.items())}
def verify(candidate):
    assert candidate['files']==files, 'closed original byte/Git membership'
    assert candidate['patterns']==patterns, 'closed lexical population declarations'
    assert candidate['sites']==expected, 'independent rg lexical population differs'
verify(data)
for label in ('file','digest','site','line','category'):
    bad=copy.deepcopy(data)
    if label=='file':bad['files'].pop(next(iter(bad['files'])))
    elif label=='digest':bad['files'][next(iter(bad['files']))]['sha256']='wrong'
    elif label=='site':bad['sites'].pop()
    elif label=='line':bad['sites'][0][3]+=1
    else:bad['sites'][0][1]='unknown'
    try:verify(bad)
    except AssertionError:pass
    else:raise AssertionError('shared inventory corruption accepted: '+label)
counts=json.loads((BASE/'counts.json').read_text())
assert counts=={'files':len(files),'sites':len(expected),'categories':rg_counts}
if (BASE/'manifest.json').exists():
    members=json.loads((BASE/'manifest.json').read_text())['files']
    assert set(members)=={str(p.relative_to(BASE)) for p in BASE.rglob('*') if p.is_file() and p.name!='manifest.json'}
    for name,bound in members.items():
        raw=(BASE/name).read_bytes(); assert len(raw)==bound['bytes'] and hashlib.sha256(raw).hexdigest()==bound['sha256']
print('PASS immutable complete Git/source membership, independent ASCII rg token/offset/line census, five shared corruptions and exact derived counts; no semantic classification')
