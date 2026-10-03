from html import unescape
from pathlib import Path
import re

text = unescape(re.sub('<[^>]+>', ' ', Path(
    'docs/book/book/13k-isf-feature-support-matrix.html').read_text()))
text = ' '.join(text.split())
for phrase in ('coverage cause diagnosis', 'an unrelated failure path',
               'The verifier rejects those inputs correctly', 'Complete source/module field qualification remains open'):
    assert phrase in text, phrase
print('PASS rendered coverage cause diagnosis, verifier/test distinction and explicit remaining qualification; visual QA not performed.')
