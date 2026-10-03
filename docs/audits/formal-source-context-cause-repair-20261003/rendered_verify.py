from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,s):self.parts.append(s)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split())
for phrase in ('formal source-context helper now compares complete first causes','earlier static-parameter restriction has a separate exact refusal','source-context repair','wider internal product semantics remain under cold review'):assert phrase in text,phrase
print('PASS rendered source-context complete-cause repair; visual QA not performed.')
