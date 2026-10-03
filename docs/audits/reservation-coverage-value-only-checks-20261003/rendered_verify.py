from pathlib import Path
s=Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()
for phrase in ('Real value-only controls', 'successful or refused call', 'current test stays green in both cases', 'finite native-marker controls remain open'):
    assert phrase in s, phrase
assert Path('docs/audits/reservation-coverage-value-only-controls-20261003/scope.txt').is_file()
print('PASS rendered actual value-only kind counterexamples and finite plain/native successor boundary; visual QA remains pending.')
