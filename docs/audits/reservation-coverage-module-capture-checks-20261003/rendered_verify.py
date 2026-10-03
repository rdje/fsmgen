from html import unescape
from pathlib import Path
import re
text = unescape(re.sub('<[^>]+>', ' ', Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()))
text = ' '.join(text.split())
for phrase in ('actor-copy qualification', 'module capture', 'complete module originals and deeply isolated pure copies', 'generated, reusable and ATL field meanings'):
    assert phrase in text, phrase
assert Path('docs/audits/reservation-coverage-module-capture-20261003/scope.txt').is_file()
print('PASS rendered module-capture scope, retained actor result and open semantic/snapshot boundary; visual QA remains pending.')
