from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,s):self.parts.append(s)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split())
for phrase in ('prepared-reservation diagnosis finds unrelated unsupported-reference causes','production collector rejects those inputs correctly','complete-cause test repair is the next owned step'):assert phrase in text,phrase
print('PASS rendered checked-reservation cause diagnosis; visual QA not performed.')
