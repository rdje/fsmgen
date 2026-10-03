from pathlib import Path
from html import unescape
import re
text=unescape(re.sub('<[^>]+>',' ',Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()))
text=' '.join(text.split())
for wanted in ('snapshot diagnosis','existing test clones change generated child assignment numbers to strings',
               'value-only assertions miss a deliberately injected kind-only input mutation',
               'actual collector preserves its complete inputs','repair is owned by .12.2.2'):
    assert wanted in text,wanted
print('PASS rendered snapshot diagnosis, actual collector conservation and owned repair boundaries; visual QA not performed.')
