from html import unescape
from pathlib import Path
import re
text = unescape(re.sub('<[^>]+>', ' ', Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()))
text = ' '.join(text.split())
for phrase in ('module join', 'reconciles every captured module field and actor-only preparation difference', 'Successful/refused snapshots and mutation seeds remain open'):
    assert phrase in text, phrase
assert Path('docs/audits/reservation-coverage-module-join-20261003/scope.txt').is_file()
print('PASS rendered complete module/propagation join, open snapshot/seed boundary and qualification link; visual QA remains pending.')
