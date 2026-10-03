from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,s):self.parts.append(s)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split())
for phrase in ('projection-copy repair uses a scalar-preserving source copy and first-touch JSON snapshots','checks now distinguish strings from numbers','cause and test-copy repairs are complete'):assert phrase in text,phrase
print('PASS rendered private projection scalar-kind repair; visual QA not performed.')
