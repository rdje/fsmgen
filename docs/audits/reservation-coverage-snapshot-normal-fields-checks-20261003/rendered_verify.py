from pathlib import Path
s=Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text()
for phrase in ('Ordinary snapshot fields', 'formal mutation-seed widths', 'producer-removal input fields and real value-only assertion controls remain open'):
    assert phrase in s, phrase
assert Path('docs/audits/reservation-coverage-snapshot-normal-fields-20261003/scope.txt').is_file()
print('PASS rendered ordinary snapshot/seed contracts and explicit rebuilt-input/assertion successors; visual QA remains pending.')
