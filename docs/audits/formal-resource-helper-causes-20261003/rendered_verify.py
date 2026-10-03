from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,s):self.parts.append(s)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split())
for phrase in ('resource helper and adjacent preparation assertion still match wanted codes','Resource diagnosis','keep expectations out of active eval-source frames'):assert phrase in text,phrase
print('PASS rendered resource cause diagnosis; visual QA not performed.')
