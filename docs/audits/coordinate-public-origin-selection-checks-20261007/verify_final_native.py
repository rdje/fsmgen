"""Check whole final copied-source freshness and conserve the dated native guide."""
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0,'scripts')
import book_source_references as plane

BASE = Path('docs/audits/coordinate-public-origin-selection-checks-20261007')
OUTPUT = '.artifacts/coordinate-public-origin-selection-book'


def pin(raw):
    return dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())


def main():
    actual = json.loads((BASE/'book-final.json').read_bytes())
    plane.require(actual['command'] == ['scripts/run_with_ram_guard.sh','--','mdbook','build','docs/book','--dest-dir',OUTPUT]
                  and type(actual['status']) is int and actual['status'] == 0,
                  'complete final same-volume book build and integer success')
    rows = plane.expected_rows()
    plane.check(rows,OUTPUT)
    plane.check_index(rows)
    inputs = []
    for row in rows:
        original = plane.source_bytes(row['source'])
        copied = plane.local_read(plane.ROOT/OUTPUT/row['asset'],plane.SOURCE_BYTES)
        plane.require(original == copied,'every final copied source matches its whole canonical bytes')
        inputs.append(dict(route=row,canonical=pin(original),copied=pin(copied)))
    chapter = Path(OUTPUT)/'13k-isf-feature-support-matrix.html'
    plane.require(chapter.read_bytes() == (BASE/'book-input.html').read_bytes()
                  and Path('docs/book/src/13k-isf-feature-support-matrix.md').read_bytes() == (BASE/'book-source.md.txt').read_bytes(),
                  'complete qualified dated guide/source conserve through final refresh')
    proof = dict(actual=actual,rows=inputs,native=pin(chapter.read_bytes()),
                 scope='Complete final copied-source freshness and unchanged scoped guide only; visual QA and unrestricted future currency remain unqualified.')
    path = BASE/'final-native-proof.json'
    raw = json.dumps(proof,sort_keys=True,indent=2)+'\n'
    if path.exists():
        plane.require(path.read_text() == raw,'whole retained final native source proof')
    else:
        path.write_text(raw)
    print('PASS complete final copied-source currency and conserved dated finite public origin selection guide.')


if __name__ == '__main__':
    main()
