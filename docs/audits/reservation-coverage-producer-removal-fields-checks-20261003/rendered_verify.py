from pathlib import Path
s=Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()
for phrase in ('producer-removal fields', 'widths, assignment ordinals, declaration membership', 'completion constants stay strings', 'value-only assertion controls remain open'):
    assert phrase in s, phrase
assert Path('docs/audits/reservation-coverage-producer-removal-fields-20261003/scope.txt').is_file()
print('PASS rendered rebuilt-input field contracts and open complete join/real assertion boundary; visual QA remains pending.')
