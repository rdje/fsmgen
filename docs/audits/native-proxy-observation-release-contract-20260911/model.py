"""Finite release-admission model; predicates are assumptions, never OS proof."""
from __future__ import annotations

import json
import re

ROLES = {'capture', 'helper', 'query'}
WORK_LIMIT = 17
SELECTION_BYTES = 4096
RECEIPT_BYTES = 4096


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':')).encode()


def flag(value):
    assert type(value) in (int, str) and value in (0, 1, '0', '1')
    return value in (1, '1')


def settled(selection, receipts, sealed, *, mutant=None):
    assert type(sealed) is bool
    assert sealed or mutant == 'ignore_selection_seal'
    assert type(selection) is list and 1 <= len(selection) <= WORK_LIMIT
    assert len(canonical(selection)) <= SELECTION_BYTES
    assert type(receipts) is list
    expected = {}
    for row in selection:
        assert set(row) == {'work_id', 'ownership_token', 'role'}
        assert type(row['work_id']) is str and re.fullmatch(r'[A-Za-z0-9_.:-]{1,64}', row['work_id'])
        assert type(row['ownership_token']) is str and re.fullmatch(r'[0-9a-f]{64}', row['ownership_token'])
        assert row['role'] in ROLES and row['work_id'] not in expected
        expected[row['work_id']] = row
    observed = set()
    for row in receipts:
        assert len(canonical(row)) <= RECEIPT_BYTES
        assert set(row) == {'work_id', 'ownership_token', 'role', 'outcome', 'cleanup'}
        work_id = row['work_id']
        assert work_id in expected and work_id not in observed
        observed.add(work_id)
        assert row['role'] == expected[work_id]['role']
        assert row['ownership_token'] == expected[work_id]['ownership_token'] or mutant == 'ignore_owner_token'
        assert row['outcome'] in ('completed', 'failed', 'cancelled')
        cleanup = row['cleanup']
        assert set(cleanup) == {'leader_started', 'leader_reaped', 'group_gone'}
        started, reaped, gone = [flag(cleanup[key]) for key in ('leader_started', 'leader_reaped', 'group_gone')]
        if mutant == 'ignore_helper_cleanup' and row['role'] == 'helper':
            continue
        assert gone or mutant == 'ignore_group_cleanup'
        assert not started or reaped or mutant == 'ignore_reaping'
    assert observed == set(expected) or mutant == 'accept_partial_roster'
    assert [row['work_id'] for row in receipts] == list(expected) or mutant == 'accept_partial_roster'


def release(state, *, mutant=None):
    """Return the conservative symbolic effect of one attempted release.

    The model never opens a file, authenticates a birth, launches work, or
    establishes that its supplied archive/hold predicates are actually true.
    """
    try:
        assert state['archive_bytes_match'] is True or mutant == 'ignore_archive_bytes'
        assert state['archive_identity_matches'] is True or mutant == 'ignore_archive_identity'
        assert state['exact_hold'] is True or mutant == 'ignore_hold_identity'
        settled(state['selection'], state['receipts'], state['selection_sealed'], mutant=mutant)
    except (AssertionError, KeyError, TypeError, ValueError):
        return dict(admitted=False, returned=False, hold_present=True,
                    other_hold_present=True, image_present=True,
                    outcomes=[row.get('outcome') for row in state['receipts']])
    return dict(admitted=True, returned=not state['failure_after_unlink'],
                hold_present=False, other_hold_present=True, image_present=True,
                outcomes=[row['outcome'] for row in state['receipts']])
