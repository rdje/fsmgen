from html import unescape
from pathlib import Path
import re

text = unescape(re.sub('<[^>]+>', ' ', Path(
    'docs/book/book/13k-isf-feature-support-matrix.html').read_text()))
text = ' '.join(text.split())
for phrase in ('bounded coverage profile', 'change numeric scalars into strings',
               'Wrong-cause controls and complete source/module field qualification remain open'):
    assert phrase in text, phrase
print('PASS rendered bounded coverage profile and explicit qualification gaps; visual QA not performed.')
