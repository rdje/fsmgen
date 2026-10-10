"""Declare the exact owned book delta without changing a capacity limit."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-publication-preparation-20261010')
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def counts(sources):
    return {'files': len(sources), 'lines_total': sum(raw.count(b'\n') for raw in sources.values()),
            'bytes_total': sum(len(raw) for raw in sources.values())}


def main():
    revision = 'a6c92162dd8d0cd7ec718423b9756c2f5a2d4193'
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision, '--', 'docs/book/src'], text=True)
    paths = sorted(p for p in paths.splitlines() if Path(p).parent == Path('docs/book/src') and p.endswith('.md'))
    if paths != sorted(str(p) for p in Path('docs/book/src').glob('*.md')):
        raise ValueError('whole unchanged book member population')
    original = {p: subprocess.check_output(['git', 'show', revision + ':' + p]) for p in paths}
    current = {p: Path(p).read_bytes() for p in paths}
    chapter = 'docs/book/src/13k-isf-feature-support-matrix.md'
    addition = (BASE / 'book-addition.md.txt').read_bytes()
    expected = dict(original)
    marker = b'Raw-coordinate qualification first admits the complete predecessor source and\n'
    if original[chapter].count(marker) != 1:
        raise ValueError('unique original chapter source insertion')
    expected[chapter] = original[chapter]
    replacements = json.loads((BASE / 'book-replacements.json').read_bytes())
    for before, after in replacements:
        if expected[chapter].count(before.encode()) != 1:
            raise ValueError('unique exact owned book status replacement')
        expected[chapter] = expected[chapter].replace(before.encode(), after.encode())
    expected[chapter] = expected[chapter].replace(marker, addition + marker)
    if current != expected:
        raise ValueError('whole book conservation except exact publication preparation addition')
    raw = REGISTRY.read_bytes()
    retained = BASE / 'before-book-authority.jsonl.txt'
    if retained.exists():
        raise ValueError('retain initial rejected registry; do not overwrite')
    retained.write_bytes(raw)
    rows = list(map(json.loads, raw.splitlines()))
    before, after = counts(original), counts(current)
    for row in rows:
        if row.get('surface_id') == 'shipped_behavior':
            row['reference_contract']['aggregate_change'] = {
                'authority_id': 'ADDRESS-PUBLICATION-PREPARATION-20261010',
                'owner': (BASE / 'scope.txt').read_text().strip(), 'baseline': before,
                'delta': {k: after[k] - before[k] for k in before},
                'rationale': 'Document complete retained non-growing prospective address publication and its original-source/actual-result qualification; atomic canonical publication remains next.'}
    updated = ''.join(json.dumps(r, sort_keys=True) + '\n' for r in rows).encode()
    prior = list(map(json.loads, raw.splitlines()))
    for a, b in zip(prior, rows, strict=True):
        if a.get('surface_id') == 'shipped_behavior':
            a['reference_contract']['aggregate_change'] = b['reference_contract']['aggregate_change']
        if a != b:
            raise ValueError('only owned aggregate declaration changes; all capacity limits conserve')
    REGISTRY.write_bytes(updated)
    proof = {'revision': revision, 'before': before, 'after': after,
             'whole_book': {p: {'before': pin(original[p]), 'after': pin(current[p])} for p in paths},
             'registry_before': pin(raw), 'registry_after': pin(updated),
             'scope': 'Exact complete owned original publication preparation addition and aggregate declaration only; no capacity limit or Knowledge Map authority changes.'}
    (BASE / 'book-authority.json').write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS complete book membership/source conservation and exact owned aggregate delta; all limits unchanged.')


if __name__ == '__main__':
    main()
