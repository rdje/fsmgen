"""Authenticate the supplementary index-membership proof and its live currency."""
import argparse
import copy
import hashlib
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/book-source-index-closure-20261005')
CHECKER = 'scripts/check_book_source_index.py'
REFUSAL = 'complete directory-wide Git source-plane membership'


def qualify(record):
    assert set(record) == {'scope', 'baseline', 'stage', 'original', 'complete', 'remove', 'restored'}
    for name in ('baseline', 'stage', 'original', 'complete', 'remove', 'restored'):
        outcome = record[name]
        assert type(outcome['status']) is int
        assert outcome['status'] == (1 if name == 'complete' else 0)
        assert type(outcome['stdout']) is str and type(outcome['stderr']) is str
    assert REFUSAL in record['complete']['stderr']
    assert 'complete indexed directory and checked source projection agree' in record['restored']['stdout']
    assert record['stage']['command'] == ['git', 'add', '--', 'docs/book/src/reference-source/owned-hidden-index-control.source.txt']
    assert record['remove']['command'] == ['git', 'rm', '--cached', '--', 'docs/book/src/reference-source/owned-hidden-index-control.source.txt']


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    pins = json.loads((BASE / 'manifest.json').read_text())
    expected = {str(p) for p in BASE.iterdir() if p.is_file() and p.name != 'manifest.json'} | {CHECKER}
    assert set(pins) == expected
    for path, pin in pins.items():
        raw = Path(path).read_bytes()
        assert type(pin['bytes']) is int
        assert pin == {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
    for name in ('proof.json', 'final-proof.json'):
        proof = json.loads((BASE / name).read_text())
        qualify(proof)
        for control in ('missing-member', 'Boolean-status', 'floating-status', 'unrelated-refusal', 'unfinished-restoration'):
            candidate = copy.deepcopy(proof)
            if control == 'missing-member':
                del candidate['stage']
            elif control == 'Boolean-status':
                candidate['complete']['status'] = True
            elif control == 'floating-status':
                candidate['complete']['status'] = 1.0
            elif control == 'unrelated-refusal':
                candidate['complete']['stderr'] = 'Different admission failure'
            else:
                candidate['restored']['status'] = 1
            try:
                qualify(candidate)
            except (AssertionError, KeyError):
                pass
            else:
                raise AssertionError('false green: ' + control)
    initial = json.loads((BASE / 'initial-result.json').read_text())
    assert type(initial['status']) is int and initial['status'] == 1
    assert 'AssertionError' in initial['stderr']
    command = [sys.executable, '-B', 'docs/audits/book-source-plane-20261005/verify.py']
    if args.current:
        command.append('--current')
        row = next(row for row in map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines())
                   if row.get('surface_id') == 'book_source_manifest')
        assert row['currency'] == {'contract_id': 'book_source_git_result', 'verifier': 'core:' + CHECKER}
        assert CHECKER in row['canonical_inputs']
        subprocess.run([sys.executable, '-B', CHECKER], check=True)
    subprocess.run(command, check=True)
    print('PASS sealed index-only extra refusal, restored index, kind/refusal controls and supplementary currency.')


if __name__ == '__main__':
    main()
