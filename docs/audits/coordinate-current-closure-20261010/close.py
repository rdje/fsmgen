"""Publish final coordinate closure only after the complete fresh semantic replay."""
import ast
import hashlib
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path('scripts').resolve()))
import record_value_coordinate_fact as coordinate

BASE = Path('docs/audits/coordinate-current-closure-20261010')
REVISION = '7efdbf512bfd865220fb13f83fbbded9b42cdcf0'
MODULE = 'scripts/record_value_coordinate_fact.py'
FEATURE = 'docs/book/src/13k-isf-feature-support-matrix.md'
REFERENCE = 'docs/book/src/90-reference-map.md'
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')
GUIDE_END = '''Whole current publication is independently qualified after a fresh complete
semantic replay. Exact source history, all questions, native guidance and
unchanged capacities conserve; broader private and downstream owners stay open.'''
REFERENCE_END = '''Whole current-coordinate publication is independently qualified after a fresh
complete original semantic replay. Exact prior/proposed/current sources, every
question and probe, whole book/native guidance and unchanged capacities join.
Only completed coordinate nodes close. Original private, framework, formatter,
toolchain, identity, address and alias meanings, visual QA, HIAL repair and full
CI/push retain their owners. Raw address roles are the next owned scope.

The dated whole-publication proof remains replayable independently of later
current source progress:

```sh
python3 -B docs/audits/coordinate-current-closure-20261010/verify.py
```

'''


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def git(*args):
    run = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(run.returncode == 0 and not run.stderr, 'whole original closure source')
    return run.stdout


def pin(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'), 'sha256': hashlib.sha256(raw).hexdigest()}


def literal(raw, name):
    values = [ast.literal_eval(node.value) for node in ast.parse(raw).body
              if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == name for t in node.targets)]
    need(len(values) == 1, 'unique complete coordinate guide literal')
    return values[0]


def replace(text, old, new):
    need(text.count(old) == 1, 'unique complete closure seam')
    return text.replace(old, new, 1)


def counts(rows):
    return {'files': len(rows), 'bytes_total': sum(len(raw) for raw in rows.values()),
            'lines_total': sum(raw.count(b'\n') for raw in rows.values())}


def main():
    need(not (BASE / 'publication.json').exists(), 'refuse to overwrite final closure publication')
    checks = json.loads((BASE / 'checks.json').read_bytes())
    actual = checks['original-semantic']
    qualified = json.loads(coordinate.local(coordinate.PRODUCT + '/qualification.json', 49265673))
    before = coordinate.authenticate()
    coordinate.check_actual(actual, qualified)
    need(Path('docs/audits/coordinate-original-hostile-checks-20261009/progress.json').read_bytes()
         == (BASE / 'original-progress-before.json').read_bytes(), 'fresh complete semantic progress returns to its exact terminal state')
    original_module = git('show', REVISION + ':' + MODULE).decode()
    need(Path(MODULE).read_text() == original_module, 'whole unchanged coordinate module before closure')
    old_guide, old_reference = (literal(original_module, name) for name in ('GUIDE', 'REFERENCE'))
    new_guide = replace(old_guide, 'Final whole-publication closure remains separately owned.', GUIDE_END)
    old_end = '''Final whole-publication closure is the next owned step; original private,
framework, formatter, toolchain, identity, address and alias meanings, visual QA,
HIAL repair and full CI/push retain their owners.

'''
    new_reference = replace(old_reference, old_end, REFERENCE_END)
    updated_module = replace(replace(original_module, old_guide, new_guide), old_reference, new_reference)
    ast.parse(updated_module)
    paths = sorted(p for p in git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                   if Path(p).parent == Path('docs/book/src') and p.endswith('.md'))
    need(paths == sorted(str(p) for p in Path('docs/book/src').glob('*.md')), 'whole original book population')
    originals = {p: git('show', REVISION + ':' + p) for p in paths}
    need(all(Path(p).read_bytes() == raw for p, raw in originals.items()), 'whole book source before closure')
    after = dict(originals)
    after[FEATURE] = replace(originals[FEATURE].decode(), old_guide, new_guide).encode()
    after[REFERENCE] = replace(originals[REFERENCE].decode(), old_reference, new_reference).encode()
    old_count, new_count = counts(originals), counts(after)
    rows = list(map(json.loads, SURFACES.read_text().splitlines()))
    for row in rows:
        if row.get('surface_id') == 'shipped_behavior':
            row['reference_contract']['aggregate_change'] = {
                'authority_id': 'COORDINATE-CURRENT-CLOSURE-20261010',
                'owner': (BASE / 'scope.txt').read_text().strip(), 'baseline': old_count,
                'delta': {key: new_count[key] - old_count[key] for key in old_count},
                'rationale': 'Close only fully qualified coordinate publication after fresh complete original semantic replay; preserve every current card, question, probe, locality rule and separate private/address/native owner.'}
    need(before == coordinate.authenticate(), 'whole original qualification conserves before final publication')
    (BASE / 'original-semantic.json').write_text(json.dumps(actual, sort_keys=True, indent=2) + '\n')
    Path(MODULE).write_text(updated_module)
    for path in (FEATURE, REFERENCE):
        Path(path).write_bytes(after[path])
    SURFACES.write_text(''.join(json.dumps(row, sort_keys=True) + '\n' for row in rows))
    product = {'revision': REVISION, 'owner': (BASE / 'scope.txt').read_text().strip(),
               'module': {'path': MODULE, 'before': pin(original_module.encode()), 'after': pin(updated_module.encode())},
               'chapters': {p: {'original': originals[p].decode(), 'current': after[p].decode(),
                                'before': pin(originals[p]), 'after': pin(after[p])} for p in (FEATURE, REFERENCE)},
               'book_before': old_count, 'book_after': new_count, 'original_qualification': before,
               'fresh_semantic': pin((BASE / 'original-semantic.json').read_bytes())}
    (BASE / 'publication.json').write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS final coordinate guide publication after fresh complete unchanged semantic reconstruction; separate owners preserved.')


if __name__ == '__main__':
    main()
