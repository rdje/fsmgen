#!/usr/bin/env python3
"""Verify retained review inputs and coverage, without adopting policy."""
import argparse
import copy
import difflib
import hashlib
import json
from pathlib import Path
import re
import subprocess

if not __debug__:
    raise SystemExit("Review assertions must be enabled; do not use optimized Python.")

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def verify(record, snapshot, patch):
    assert record['schema'] == 'fsmgen.claim_template_review.v1'
    assert record['local_path'] == 'CLAIM_VERIFICATION.md'
    revision = record['local_revision']
    assert re.fullmatch(r'[0-9a-f]{40}', revision)
    local = subprocess.check_output(
        ['git', 'show', f"{revision}:CLAIM_VERIFICATION.md"], cwd=ROOT)
    neutral = local[local.index(b'# Claim Verification'):]
    assert hashlib.sha256(neutral).hexdigest() == record['local_neutral_sha256']
    assert hashlib.sha256(snapshot).hexdigest() == record['selected_sha256']
    old, new = neutral.decode().splitlines(True), snapshot.decode().splitlines(True)
    expected = ''.join(difflib.unified_diff(
        old, new, fromfile='local-neutral-body', tofile='selected-template'))
    assert patch == expected, 'saved diff changed'
    # Enumerate the actual saved diff headers independently of its manifest.
    headers = re.findall(r'^@@ -(\d+),(\d+) \+(\d+),(\d+) @@', patch, re.M)
    hunks = [dict(id=f'H{i}', old_lines=[int(a), int(a) + int(b) - 1],
                  new_lines=[int(c), int(c) + int(d) - 1])
             for i, (a, b, c, d) in enumerate(headers, 1)]
    assert hunks and hunks == record['hunks'], 'hunk census differs'
    identities = {hunk['id'] for hunk in hunks}
    covered, rows = set(), set()
    for disposition in record['dispositions']:
        assert disposition['id'] not in rows, 'duplicate disposition'
        rows.add(disposition['id'])
        assert disposition['selection'] in ('accept', 'adapt', 'reject_literal_wording')
        assert isinstance(disposition['rationale'], str) and disposition['rationale'].strip()
        references = disposition['hunks']
        assert references and len(references) == len(set(references))
        assert set(references) <= identities, 'unknown hunk'
        covered.update(references)
    assert covered == identities, 'unreviewed changed hunk'
    assert record['local_policy_changed'] is False
    assert record['checker_changed'] is False
    return len(hunks), len(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-selected', action='store_true',
                        help='also compare the caller-authorized sibling template read-only')
    parser.add_argument('--qualify', action='store_true', help='reject corrupted review controls')
    args = parser.parse_args()
    record = json.loads((HERE / 'review.json').read_text())
    snapshot = (HERE / 'template.txt').read_bytes()
    patch = (HERE / 'template.diff').read_text()
    hunks, rows = verify(record, snapshot, patch)
    if args.verify_selected:
        selected = ROOT.parent / 'pgen' / 'docs' / 'CLAIM_VERIFICATION.md'
        assert selected.stat().st_dev == ROOT.stat().st_dev, 'selected input volume changed'
        assert selected.read_bytes() == snapshot, 'selected template has changed'
        print('selected caller-authorized same-volume input matches; read-only')
    if args.qualify:
        mutations = []
        bad = copy.deepcopy(record)
        bad['dispositions'] = bad['dispositions'][1:]
        mutations.append(('unreviewed domain-free changes', bad, snapshot, patch))
        bad = copy.deepcopy(record)
        bad['hunks'].pop()
        mutations.append(('omitted diff hunk', bad, snapshot, patch))
        bad = copy.deepcopy(record)
        bad['dispositions'][0]['hunks'].append('H999')
        mutations.append(('invented hunk', bad, snapshot, patch))
        bad = copy.deepcopy(record)
        bad['local_policy_changed'] = True
        mutations.append(('false adoption', bad, snapshot, patch))
        mutations.append(('altered source', record, snapshot + b'\n', patch))
        mutations.append(('altered diff', record, snapshot, patch + '\n'))
        for name, changed, source, diff in mutations:
            try:
                verify(changed, source, diff)
            except AssertionError:
                continue
            raise AssertionError(f'corrupted control accepted: {name}')
        print(f'corrupted review controls rejected: {len(mutations)}')
    print(f'retained review verified: {hunks} changed hunks, {rows} dispositions; no policy adoption asserted')


if __name__ == '__main__':
    main()
