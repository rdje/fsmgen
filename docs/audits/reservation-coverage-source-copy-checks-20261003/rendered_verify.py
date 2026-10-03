from html import unescape
from pathlib import Path
import re
text = unescape(re.sub('<[^>]+>', ' ', Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()))
text = ' '.join(text.split())
for phrase in ('actor-copy qualification', 'binds changed FIFO bank indexes/binding widths', 'complete ordinary lowering results, emitted carriers', 'Internal module propagation and successful/refused snapshots remain open'):
    assert phrase in text, phrase
assert Path('docs/audits/reservation-coverage-source-copies-20261003/scope.txt').is_file()
print('PASS rendered actor-copy result, source-field scope, remaining module/snapshot boundary and source link; visual QA remains pending.')
