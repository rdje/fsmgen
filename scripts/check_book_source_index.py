#!/usr/bin/env python3
"""Conserve complete directory-wide Git membership for native source assets."""
import importlib.util
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def check():
    spec = importlib.util.spec_from_file_location(
        'book_source_projection', ROOT / 'scripts/book_source_references.py')
    plane = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(plane)
    rows = plane.expected_rows()
    plane.check(rows)
    plane.check_index(rows)
    raw = subprocess.check_output([
        'git', '-C', str(ROOT), 'ls-files', '--stage', '-z', '--', plane.PLANE])
    expected = {plane.MANIFEST} | {'docs/book/src/' + row['asset'] for row in rows}
    actual = set()
    for entry in raw.split(b'\0'):
        if not entry:
            continue
        metadata, path = entry.decode().split('\t', 1)
        plane.require(metadata.split()[-1] == '0' and path not in actual,
                      'conflict-free complete indexed source directory')
        actual.add(path)
    plane.require(actual == expected, 'complete directory-wide Git source-plane membership')
    print('book-source-index: complete indexed directory and checked source projection agree')


if __name__ == '__main__':
    check()
