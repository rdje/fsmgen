#!/usr/bin/env python3
"""Apply only the independently qualified three-document semantic partition."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    path = BASE / 'partition-contract-final-qualified.json.gz'
    packet = json.loads(gzip.decompress(path.read_bytes()))
    expected = {'docs/book/src/11-extensions-and-embedding.md',
                'docs/book/src/11a-perl-api-reference.md', 'docs/book/src/SUMMARY.md'}
    if set(packet['candidate_documents']) != expected or set(packet['inputs']) != expected:
        raise SystemExit('Refusing an unexpected migration population')
    for name, saved in packet['inputs'].items():
        target = ROOT / name
        if target.is_symlink() or target.read_bytes() != saved['text'].encode():
            raise SystemExit('Refusing changed original source: ' + name)
    if args.write:
        for name, text in packet['candidate_documents'].items():
            (ROOT / name).write_text(text)
    print(json.dumps({'applied': args.write, 'contract_sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'documents': {name: hashlib.sha256(text.encode()).hexdigest()
                      for name, text in packet['candidate_documents'].items()},
        'scope': 'Exact qualified source move only; current-source/native adapter qualification follows.'}, sort_keys=True))


if __name__ == '__main__':
    main()
