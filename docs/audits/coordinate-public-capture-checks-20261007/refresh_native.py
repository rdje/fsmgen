"""Census every copied asset before refresh and verify the whole restored set."""
import argparse
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, 'scripts')
import book_source_references as plane

BASE = Path('docs/audits/coordinate-public-capture-checks-20261007')
OUTPUT = plane.ROOT / '.artifacts/coordinate-public-capture-book'


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def census():
    rows = []
    mismatches = []
    for route in plane.expected_rows():
        copied = plane.local_read(OUTPUT / route['asset'], plane.SOURCE_BYTES)
        canonical = plane.source_bytes(route['source'])
        rows.append(dict(route=route, copied=pin(copied), canonical=pin(canonical)))
        if copied != canonical:
            mismatches.append(dict(route=route, copied_source=copied.decode(), canonical_source=canonical.decode()))
    return dict(rows=rows, mismatches=mismatches)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--after', action='store_true')
    args = parser.parse_args()
    actual = census()
    if args.after:
        before = json.loads((BASE / 'native-copy-before.json').read_bytes())
        plane.require(actual['mismatches'] == [] and [r['route'] for r in actual['rows']] == [r['route'] for r in before['rows']],
                      'whole refreshed native member population and zero mismatch')
        plane.require([r['canonical'] for r in actual['rows']] == [r['canonical'] for r in before['rows']],
                      'every canonical source conserves through refresh')
        plane.check(plane.expected_rows(), str(OUTPUT.relative_to(plane.ROOT)))
        path = BASE / 'native-copy-after.json'
    else:
        failure = json.loads((BASE / 'current-native.json').read_bytes())
        plane.require(type(failure['status']) is int and failure['status'] == 1
                      and 'ValueError: fresh whole native copied source bytes\n' in failure['stderr'],
                      'complete retained actual native freshness failure')
        plane.require([r['route']['source'] for r in actual['mismatches']] == ['MEMORY.md','docs/TASK_TREE.md'],
                      'independent complete first mismatch allocation')
        path = BASE / 'native-copy-before.json'
    encoded = json.dumps(actual, sort_keys=True, indent=2) + '\n'
    if path.exists():
        plane.require(path.read_text() == encoded, 'whole retained native copied-source census')
    else:
        path.write_text(encoded)
    print(json.dumps({'phase':'after' if args.after else 'before', 'members':len(actual['rows']),
                      'mismatched_sources':[r['route']['source'] for r in actual['mismatches']]}, sort_keys=True))


if __name__ == '__main__':
    main()
