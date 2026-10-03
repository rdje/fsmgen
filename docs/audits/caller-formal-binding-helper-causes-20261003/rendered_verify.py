from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,s):self.parts.append(s)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split())
for phrase in ('caller-formal-binding helper still matches some unrelated binding-shape failures','complete-cause repair is the immediate next slice','binding-helper diagnosis'):assert phrase in text,phrase
print('PASS rendered binding-helper diagnosis; visual QA not performed.')
