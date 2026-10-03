from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
    def __init__(self):super().__init__();self.parts=[]
    def handle_data(self,value):self.parts.append(value)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split())
for phrase in ('24 named span instances across nine distinct function names','2,542 current Perl source files and 57 line-anchored named-definition tokens','local-formal helper delegates its diagnostic predicate','bounded membership record'):assert phrase in text,phrase
print('Completed rendered-text membership/unit checks; browser visual QA unavailable.')
