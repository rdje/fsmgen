from pathlib import Path
s=Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()
for phrase in ('snapshot capture', 'module/allocation mutation seed', 'Their field meanings and real value-only', 'assertion controls remain open'):
    assert phrase in s, phrase
assert Path('docs/audits/reservation-coverage-snapshot-capture-20261003/scope.txt').is_file()
print('PASS rendered complete snapshot/seed capture and explicit open field/assertion boundary; visual QA remains pending.')
