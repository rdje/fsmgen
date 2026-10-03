from html import unescape
from pathlib import Path
import re
text = unescape(re.sub('<[^>]+>', ' ', Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()))
text = ' '.join(text.split())
for phrase in ('ATL-field qualification', 'copied fan-in source RHS', 'endpoint widths through child ports, top links and prepared wiring', 'module/propagation join and successful/refused snapshots remain open'):
    assert phrase in text, phrase
assert Path('docs/audits/reservation-coverage-atl-module-fields-20261003/scope.txt').is_file()
print('PASS rendered ATL numeric/endpoint field result, open join/snapshot boundary and qualification link; visual QA remains pending.')
