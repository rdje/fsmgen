from pathlib import Path
from html.parser import HTMLParser
class Text(HTMLParser):
    def __init__(self):super().__init__();self.values=[]
    def handle_data(self,data):self.values.append(data)
p=Text();p.feed(Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text());text=' '.join(' '.join(p.values).split())
assert 'preserves JSON primitive kinds (true cannot replace numeric 1)' in text
