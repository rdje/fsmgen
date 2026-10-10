"""Whole current guide/source conservation after pointer-only publication repair."""
from html.parser import HTMLParser
from pathlib import Path
from verify import BASE, CORE, canonical, need, pin, read


if __name__=='__main__':
    report=read(CORE/'book-publication.json')
    sources={str(p):pin(p.read_bytes()) for p in Path('docs/book/src').glob('*.md')}
    need(sources==report['after'],'complete unchanged final book source set and bytes')
    class Text(HTMLParser):
        def __init__(self):
            super().__init__();self.parts=[]
        def handle_data(self,data):
            self.parts.append(data)
    chapter=Path('docs/book/book/13k-isf-feature-support-matrix.html').read_bytes()
    text=Text();text.feed(chapter.decode())
    expected=' '.join(line for line in report['addition'].splitlines() if not line.startswith('```'))
    need(' '.join(''.join(text.parts).split()).count(' '.join(expected.split()))==1,
         'whole unique final native source-value parent guide')
    proof=dict(sources=sources,chapter=pin(chapter),addition=pin(report['addition'].encode()),
        scope='Final current native guide/source conservation only; visual QA and higher original scopes remain open.')
    if (BASE/'native-proof.json').exists():
        need(read(BASE/'native-proof.json')==proof,'whole immutable final native repair proof')
    else:
        (BASE/'native-proof.json').write_bytes(canonical(proof))
    print('PASS whole final native source-value guide and every unchanged book source after resume-pointer compaction.')
