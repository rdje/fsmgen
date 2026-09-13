"""Verify exact retirement of the superseded authoring draft without new limits."""
from __future__ import annotations

import argparse
import copy
import hashlib
import json

from support import BASE, ROOT, LOG, document, pin, write
import review_completion


def verify():
    record = document(BASE / 'draft-retirement.json')
    assert record['first_staged_exit'] == 1
    assert record['numeric_ceilings_changed'] is record['book_changed'] is record['fixture_sources_changed'] is False
    copies = {}
    for row in record['source_copies']:
        raw = (ROOT / row['copy']).read_bytes()
        assert len(raw) == row['size_bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
        copies[row['original']] = raw
    prefix = str(BASE.relative_to(ROOT)) + '/'
    old_pins = json.loads(copies[prefix + 'preflight-pins.json'])
    expected = copy.deepcopy(old_pins)
    matches = [row for row in expected if row['path'] == prefix + 'design.md']; assert len(matches) == 1
    matches[0]['path'] = prefix + 'design.md.source'
    assert expected == document(BASE / 'preflight-pins.json')
    assert not (BASE / 'design.md').exists() and not (BASE / 'design.md').is_symlink()
    old_completion = json.loads(copies[prefix + 'completion-pins.json'])
    expected_completion = copy.deepcopy(old_completion)
    matches = [row for row in expected_completion if row['path'] == prefix + 'preflight-pins.json']; assert len(matches) == 1
    matches[0].update(pin(BASE / 'preflight-pins.json'))
    assert expected_completion == document(BASE / 'completion-pins.json')
    outputs = {row['path'].rsplit('/', 1)[1]: review_completion.raw(row) for row in record['raw_outputs']}
    assert outputs['staged-doctrines.exit'] == b'1\n'
    assert b'tracked document is not covered by any surface: ' + (prefix + 'design.md').encode() in outputs['staged-doctrines.stderr']
    assert b'[task-acceptance] OK:' in outputs['staged-doctrines.stdout']
    saved = document(BASE / 'completion.json')
    current = review_completion.verify(saved['raw_captures'])
    assert current == {key: value for key, value in saved.items() if key != 'raw_captures'}
    return dict(schema='fsmgen.inactive_lifetime_authoring_retirement_review.v1',
        source_record=pin(BASE / 'draft-retirement.json'), original_draft=pin(BASE / 'design.md.source'),
        original_completion_unchanged=pin(BASE / 'completion.json'),
        exact_preflight_path_replacement=True, exact_derived_manifest_update=True,
        no_new_document_allowances=True, no_fixture_source_changes=True, no_fixture_execution=True)


def main():
    parser = argparse.ArgumentParser(); group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true'); group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    for row in document(BASE / 'retirement-pins.json'): assert pin(row['path']) == row
    result = verify()
    if args.retain: write(BASE / 'retirement-review.json', result)
    else: assert document(BASE / 'retirement-review.json') == result
    print('draft retirement: OK; exact source retained, live authorities unchanged, no allowance increase')


if __name__ == '__main__':
    main()
