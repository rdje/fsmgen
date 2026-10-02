import hashlib,json,subprocess
from pathlib import Path
from html.parser import HTMLParser
base=Path('docs/audits/current-diagnostic-lexical-kinds-20261002')
class Text(HTMLParser):
    def __init__(self):super().__init__();self.values=[]
    def handle_data(self,data):self.values.append(data)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.values).split())
assert 'preserves JSON primitive kinds ( true cannot replace numeric 1 )' in text
assert 'source discovery alone does not qualify their causes' in text
(base/'rendered.txt').write_text(text+'\n')
(base/'recipe.json').write_text(json.dumps({'baseline':subprocess.check_output(['git','rev-parse','HEAD']).decode().strip(),
'owner':'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.2.3.3',
'original_archive_commit':'33af62fbdd4a408c3bb88c900f4293f6a35860fd',
'commands':[['scripts/run_with_ram_guard.sh','--','python3',str(base/'verify.py')],['scripts/run_with_ram_guard.sh','--','python3',str(base/'verify.py'),'--old-comparison'],['mdbook','build','docs/book']],
'expected_statuses':[0,1,0],
'draft_scope':'Numeric-first source/positive/numeric-form RED retained; final Boolean-first RED falsifies primitive-kind weakness.'},sort_keys=True,indent=2)+'\n')
assert not (base/'manifest.json').exists()
files={str(p.relative_to(base)):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in base.rglob('*') if p.is_file()}
(base/'manifest.json').write_text(json.dumps({'files':files},sort_keys=True,indent=2)+'\n')
print('PASS completed rendered book scope and exclusive whole-member seal')
