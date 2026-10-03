from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,s):self.parts.append(s)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split())
for phrase in ('complete-cause repair now rejects those unrelated causes','membership bypass fail','snapshot strengthening is the next owned step'):assert phrase in text,phrase
print('PASS rendered checked-reservation complete-cause repair; visual QA not performed.')
