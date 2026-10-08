"""Retain the unchanged initial proposal and its expected growth refusal."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-route-checks-20261008')


def main():
    raw = (BASE / 'first-record_value_public_reference_fact.py.txt').read_bytes()
    model = {'__name__': 'unchanged_first_public_route_proposal'}
    exec(compile(raw, 'scripts/record_value_public_reference_fact.py', 'exec'), model)
    before = (BASE / 'tooling-before.md.txt').read_text()
    candidate = before
    for name, old, new in model['EDITS']:
        assert candidate.count(old) == 1
        candidate = candidate.replace(old, new, 1)
    candidate = candidate.replace('date: 2026-10-07\n', '  - "' + model['QUESTION'] + '"\ndate: 2026-10-08\n', 1) + model['BODY']
    row = dict(programme_sha256=hashlib.sha256(raw).hexdigest(), before=before, candidate=candidate,
               before_bytes=len(before.encode()), candidate_bytes=len(candidate.encode()),
               live_card_unchanged=Path('docs/knowledge/mdbook-build-destination-locality.md').read_text() == before)
    path = BASE / 'first-proposal.json'; assert not path.exists()
    path.write_text(json.dumps(row, sort_keys=True, indent=2) + '\n')
    model['extend'](before)
    raise ValueError('false-green first over-budget public route proposal')


if __name__ == '__main__':
    main()
