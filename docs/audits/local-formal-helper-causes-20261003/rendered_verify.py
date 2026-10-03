from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
    def __init__(self):super().__init__();self.parts=[]
    def handle_data(self,value):self.parts.append(value)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.parts).split()).replace(chr(0x2019),chr(39))
for phrase in ['unrelated parser errors quoting a source label', "JSON encoding errors quoting an object's class name", 'real-producer diagnosis', 'immediate complete-cause repair before imported qualification']:assert phrase in text,phrase
print('Completed rendered-text formal helper diagnosis checks; visual QA not performed.')
