"""Watch the version-bound book units, not a future live-source census."""
import copy,json,re,subprocess
from pathlib import Path
B=Path('docs/audits/named-helper-membership-20261003')
revision='fe8c412afd02507cbdcdd4ca756ce5421af1aed7'
reader=subprocess.check_output(['git','show',revision+':docs/audits/refusal-oracle-census-20261002/verify.py']).decode()
namespace={'__file__':'docs/audits/refusal-oracle-census-20261002/verify.py'}
exec(reader.split('discovery = json.loads',1)[0],namespace)
old=json.loads(subprocess.check_output(['git','show',revision+':docs/audits/refusal-oracle-census-20261002/candidates.json']))
namespace['SOURCES']=namespace['baseline_sources'](old['baseline']);namespace['verify_discovery'](old)
sources=namespace['baseline_sources'](revision);selected={}
for path,raw in sources.items():
    first=raw.split(b'\n',1)[0]
    if Path(path).suffix in {'.t','.pm','.pl'} or (first.startswith(b'#!') and b'perl' in first):selected[path]=raw
named=0
for raw in selected.values():
    for line in raw.splitlines():
        m=re.match(rb'[ \t]*sub[ \t]+([A-Za-z_]\w*)\b',line)
        if m and m[1].decode().startswith(('refus','reject','fail','declin')):named+=1
spans=len(old['records']);flagged=[r for r in old['records'] if r['named_refusal_helper']];names=len({r['function'] for r in flagged})
# Spell the one recorded historical name count independently of its prose.
assert names==9
phrases=[f'The historical named discovery contains {spans} lexical spans, including {len(flagged)} named', 'span instances across nine distinct function names. Its original “24 prefixes”', 'At revision `fe8c412a`, the map', f'binds {len(selected):,} current Perl source files and {named} line-anchored named-definition tokens,']
text=Path('docs/book/src/13k-isf-feature-support-matrix.md').read_text()
def verify(value):
    for phrase in phrases:assert phrase in value,phrase
verify(text)
for label,old_text,new_text in [('span_count','244 lexical spans','245 lexical spans'),('span_name_unit','nine distinct function names','24 distinct function names'),('current_token_count','57 line-anchored','56 line-anchored'),('revision','fe8c412a','wrong_revision')]:
    bad=text.replace(old_text,new_text);assert bad!=text
    try:verify(bad)
    except AssertionError:print('book claim corruption rejects:',label)
    else:raise AssertionError('accepted '+label)
print('Git-bound historical/current capture quantities and book units agree; observations stay bound to fe8c412a, not future current sources.')
