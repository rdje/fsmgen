from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,s):self.parts.append(s)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split())
for phrase in ('reusable-product diagnosis','private ATL output-width check numerically inspects caller-owned widths','Whole constructor and child-internal semantic qualification remains open'):assert phrase in text,phrase
print('PASS rendered reusable diagnosis and owned kind defects; visual QA not performed.')
