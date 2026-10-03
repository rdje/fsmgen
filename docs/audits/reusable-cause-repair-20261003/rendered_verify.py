from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,s):self.parts.append(s)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split())
for phrase in ('complete-cause repair now rejects real earlier unknown-child causes and primary echoes','library collision bypass fail; ordinary products are conserved','remaining test-copy repair precedes further cohort review'):assert phrase in text,phrase
print('PASS rendered reusable complete-cause repair; visual QA not performed.')
