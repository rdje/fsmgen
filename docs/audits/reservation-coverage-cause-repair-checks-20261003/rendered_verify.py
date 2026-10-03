from html import unescape
from pathlib import Path
import re

text = unescape(re.sub('<[^>]+>', ' ', Path(
    'docs/book/book/13k-isf-feature-support-matrix.html').read_text()))
text = ' '.join(text.split())
for phrase in ('coverage cause repair', 'compares independently declared complete causes',
               'the actual declaration guard bypass fails', 'Copy-field and wider constructor qualification remains separate'):
    assert phrase in text, phrase
print('PASS rendered coverage cause repair and real controls with explicit remaining copy/cold boundaries; visual QA not performed.')
