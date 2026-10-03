from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,s):self.parts.append(s)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split())
for phrase in ('caller-formal-binding helper now compares complete declared causes','genuine validation bypass makes the repaired test fail','binding-helper repair'):assert phrase in text,phrase
print('PASS rendered binding-helper repair; visual QA not performed.')
