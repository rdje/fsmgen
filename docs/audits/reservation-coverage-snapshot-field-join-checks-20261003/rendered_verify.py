from pathlib import Path
s=Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()
for phrase in ('snapshot field join', 'reconciles every changed field and unchanged-copy control', 'Real value-only assertion and native-marker controls remain open'):
    assert phrase in s, phrase
assert Path('docs/audits/reservation-coverage-snapshot-field-join-20261003/scope.txt').is_file()
print('PASS rendered complete snapshot field join and open real assertion/native-marker boundary; visual QA remains pending.')
