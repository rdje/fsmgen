from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,s):self.parts.append(s)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split())
for phrase in ('resource helper and adjacent preparation assertion now compare complete','resource cause repair','resource-validation bypass that makes the repaired test fail','Reusable/reservation and remaining named/framework cohorts stay open'):assert phrase in text,phrase
print('PASS rendered resource cause repair; visual QA not performed.')
