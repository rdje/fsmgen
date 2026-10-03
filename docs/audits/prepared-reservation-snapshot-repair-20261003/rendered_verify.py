from pathlib import Path
from html import unescape
import re
text=unescape(re.sub('<[^>]+>',' ',Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()))
text=' '.join(text.split())
for wanted in ('snapshot repair','preserves those numeric source values in detached fixture copies',
               'kind-only mutation controls now fail the strengthened test',
               'preparation-membership bypass still fails','arbitrary unsupported referents remain unqualified'):
    assert wanted in text,wanted
print('PASS rendered snapshot repair and explicit native/cold boundaries; visual QA not performed.')
