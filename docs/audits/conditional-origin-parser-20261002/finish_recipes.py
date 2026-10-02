import hashlib
import json
from pathlib import Path
base = Path('docs/audits/conditional-origin-parser-20261002')
assert not (base / 'manifest.json').exists()
focused = ['t/2043-isf-conditional-origin-parser.t','t/2042-isf-procedure-cond-normalization.t',
    't/1390-isf-procedures.t','t/1396-isf-cond.t','t/1402-isf-bit-test.t','t/1404-isf-when-field.t',
    't/1406-isf-select.t','t/1407-isf-minmax.t']
docs = ['t/1305-isf-book-feature-matrix-audit.t','t/1414-docs-relative-paths-audit.t',
    't/1303-isf-public-live-book-paths-audit.t','t/1307-isf-loop-body-doc-truth-audit.t',
    't/1332-isf-atl-doc-status-audit.t','t/1376-isf-book-example-lowering-audit.t']
paths = focused + docs + ['t/lib/FSM/Test/ConditionalOriginParser.pm']
paths += [str(p) for p in sorted(Path('docs/book/src').glob('*.md'))]
paths += [str(p) for p in sorted(Path('docs/isf-spec').glob('*.md'))]
providers = {p: hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in paths}
recipes = {
    'guard': 'scripts/run_with_ram_guard.sh; unchanged 88% host and 4096 MiB descendant cutoffs',
    'baseline': '985e5e9707cd987a7b70a878f0c686ad36e191d6',
    'focused': {'argv': ['prove','-Iperl','-It/lib'] + focused, 'status': 0,
        'stdout': 'focused-corrected.tap', 'stderr': 'focused-corrected-guard.txt'},
    'docs': {'argv': ['prove','-Iperl'] + docs, 'status': 0,
        'stdout': 'docs-corrected.tap', 'stderr': 'docs-corrected-guard.txt'},
    'book': {'argv': ['mdbook','build','docs/book'], 'status': 0, 'receipt': 'book.txt',
        'destination': 'docs/book/book', 'scope': 'actual rendered text/links, no browser visual QA'},
    'initial_focused': {'argv': ['prove','-Iperl','-It/lib'] + focused[:4] +
        ['t/1406-isf-when-bit.t','t/1407-isf-when-field.t','t/1402-isf-minmax.t','t/1404-isf-select.t'],
        'status': 2, 'scope': 'incomplete nonexistent path failure', 'stdout': 'focused.tap','stderr':'focused-guard.txt'},
    'initial_docs': {'argv': ['prove','-Iperl','t/1305-isf-feature-matrix-consistency.t',
        't/1414-relative-paths-docs.t','t/1303-isf-book-chapter-alignment.t',
        't/1307-isf-book-reference-coverage.t','t/1332-isf-spec-coverage-links.t',
        't/1376-isf-book-examples-lowering.t'], 'status': 2, 'scope': 'incomplete nonexistent path failure',
        'stdout': 'docs.tap', 'stderr': 'docs-guard.txt'},
    'schema_failure': {'status': 1, 'stdout':'current-qualified.tap','stderr':'current-qualified-guard.txt',
        'producer':'probe-schema-kind.pm','test':'test-schema-kind.t'},
    'parameter_failure': {'status':1, 'stdout':'current-final.tap','stderr':'current-final-guard.txt',
        'producer':'probe-parameter-draft.pm','test':'test-parameter-draft.t'},
    'providers': providers,
}
(base / 'recipes.json').write_text(json.dumps(recipes, indent=2, sort_keys=True) + '\n')
(base / 'finish_recipes.py').write_bytes(Path(__file__).read_bytes())
print('PASS exact command/status/source-provider recipes and explicit failed-attempt scope retained')
