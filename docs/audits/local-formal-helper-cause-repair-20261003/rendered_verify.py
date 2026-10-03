from html.parser import HTMLParser
from pathlib import Path
class Text(HTMLParser):
    def __init__(self):super().__init__();self.parts=[]
    def handle_data(self,value):self.parts.append(value)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text())
text=' '.join(' '.join(p.parts).split()).replace(chr(0x2019),chr(39))
for phrase in ('complete declared first cause','Permanent real-producer controls',"object's class name",'complete-cause repair','actual source-authentication bypass','Broader helper and cold consumer qualification remains open'):
    assert phrase in text,phrase
print('PASS rendered formal helper repair text; visual QA not performed.')
