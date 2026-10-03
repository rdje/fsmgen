from html import unescape
from pathlib import Path
import re
text = unescape(re.sub('<[^>]+>', ' ', Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()))
text = ' '.join(text.split())
for phrase in ('reusable-field qualification', 'FIFO slot indexes, binding widths, selection guards', 'ATL fields, the complete propagation join', 'successful/refused snapshots remain open'):
    assert phrase in text, phrase
assert Path('docs/audits/reservation-coverage-reusable-module-fields-20261003/scope.txt').is_file()
print('PASS rendered reusable/storage field and propagation scope, open ATL/join/snapshot boundary and qualification link; visual QA remains pending.')
