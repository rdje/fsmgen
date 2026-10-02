"""Closed lexical populations only; no Perl parsing or cause signoff."""
import hashlib,json,re,subprocess
from pathlib import Path
BASE=Path(__file__).parent
ROOTS=['t','perl','scripts','bin']
PATTERNS={
'assertion':r'\b(?:like|unlike|is|is_deeply|cmp_ok|ok|isa_ok|can_ok|pass|fail|BAIL_OUT|throws_ok|dies_ok|lives_ok|exception|warnings_like|warning_like)\b',
'exception':r'\$@|\b(?:eval|confess|croak|die|try|catch|fatal)\b',
'diagnostic_word':r'\b(?:error\w*|diagnostic\w*|stderr|stdout|message|reason|code)\b',
'helper_name':r'\b(?:refus\w*|reject\w*|declin\w*|first_line|diagnostic_matches|diagnostic_line)\b',
'call_like':r'\b[A-Za-z_][A-Za-z_0-9]*[ \t]*\(',
'sub':r'\bsub\b'}
revision=subprocess.check_output(['git','rev-parse','HEAD']).decode().strip()
tracked=sorted(filter(None,subprocess.check_output(['git','ls-files','-z',*ROOTS]).decode().split('\0')))
files={}; sites=[]
for name in tracked:
    path=Path(name)
    if not path.is_file(): continue
    raw=path.read_bytes(); first=raw.split(b'\n',1)[0]
    if path.suffix not in ('.t','.pm','.pl') and not (first.startswith(b'#!') and b'perl' in first):continue
    files[name]={'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}
    for category,pattern in PATTERNS.items():
        for match in re.finditer(pattern.encode(),raw):
            sites.append([name,category,match.start(),raw[:match.start()].count(b'\n')+1,match.group().decode('ascii')])
sites.sort()
data={'baseline':revision,'roots':ROOTS,'patterns':PATTERNS,'files':files,'sites':sites,
'scope':'All declared ASCII lexical token/call-like populations in tracked Perl suffix/shebang files under four roots. Includes comments/strings/declarations, repeated/overlapping categories and non-diagnostic assertions. No parsed functions, dataflow, semantic classification, arbitrary dynamic dispatch, other languages or cold-reader completeness.'}
(BASE/'inventory.json').write_text(json.dumps(data,sort_keys=True,separators=(',',':'))+'\n')
counts={key:sum(row[1]==key for row in sites) for key in PATTERNS}
(BASE/'counts.json').write_text(json.dumps({'files':len(files),'sites':len(sites),'categories':counts},sort_keys=True,indent=2)+'\n')
print(json.dumps({'files':len(files),'sites':len(sites),'categories':counts},sort_keys=True))
