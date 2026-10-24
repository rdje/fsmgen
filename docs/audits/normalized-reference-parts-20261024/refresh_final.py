#!/usr/bin/env python3
"""Bind the saved/current role correction without regenerating plan data."""
import gzip
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def main():
    source = BASE / 'partition-contract.json.gz'
    target = BASE / 'partition-contract-final-qualified.json.gz'
    if target.exists():
        raise SystemExit('Refusing to overwrite final instrument refresh')
    packet = json.loads(gzip.decompress(source.read_bytes()))
    path = BASE.relative_to(ROOT).as_posix() + '/verify.py'
    raw = (ROOT / path).read_bytes()
    packet['instruments'][path] = {'text': raw.decode(), 'sha256': sha(raw)}
    packet['qualification_refresh'] = {
        'source_packet': source.relative_to(ROOT).as_posix(), 'source_sha256': sha(source.read_bytes()),
        'instrument': {'path': Path(__file__).relative_to(ROOT).as_posix(),
                       'text': Path(__file__).read_text(), 'sha256': sha(Path(__file__).read_bytes())}}
    target.write_bytes(gzip.compress((json.dumps(packet, sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Final verifier role refresh only; completed plan data and prior packets conserved.')


if __name__ == '__main__':
    main()
