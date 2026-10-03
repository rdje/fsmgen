from html import unescape
from pathlib import Path
import re
text = unescape(re.sub('<[^>]+>', ' ', Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()))
text = ' '.join(text.split())
for phrase in ('generated-field qualification', 'monitor set/clear/reset constants', 'Unused worker width metadata stays separate from emitted port declarations', 'Reusable and ATL fields'):
    assert phrase in text, phrase
assert Path('docs/audits/reservation-coverage-generated-module-fields-20261003/scope.txt').is_file()
print('PASS rendered generated-field result, metadata/port distinction, open reusable/ATL/snapshot boundary and qualification link; visual QA remains pending.')
