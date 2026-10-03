from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
 def __init__(self):super().__init__();self.parts=[]
 def handle_data(self,s):self.parts.append(s)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split())
for phrase in ('current cohort handoff','Names do not establish actual refusal-consumer roles or native applicability','reservation helpers are next'):assert phrase in text,phrase
print('PASS rendered pending cohort handoff; visual QA not performed.')
