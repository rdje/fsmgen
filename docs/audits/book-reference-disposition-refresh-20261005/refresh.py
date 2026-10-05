"""Refresh only the identity of the unchanged decision-navigation numeral."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/book-reference-disposition-refresh-20261005')
PATH = 'docs/book/src/90-reference-map.md'
REGISTRY = Path('doctrine/claim_verification/dispositions.jsonl')
OLD_ID = 'published-c655990b63be614622a437dd'


def candidate_id(line):
    normalized = ' '.join(line.split())
    return 'published-' + hashlib.sha256('\0'.join((PATH, normalized, '1')).encode()).hexdigest()[:24]


def main():
    target = BASE / 'refresh.json'
    assert not target.exists()
    publication = json.loads(Path('docs/audits/book-reference-publication-20261005/source-boundary.json').read_text())
    before = next(line for line in publication['before'][PATH].splitlines() if line.startswith('0102]('))
    after = next(line for line in publication['after'][PATH].splitlines() if line.startswith('0102]('))
    assert Path(PATH).read_text().splitlines().count(after) == 1
    assert candidate_id(before) == OLD_ID
    raw = REGISTRY.read_bytes()
    (BASE / 'registry-before.jsonl').write_bytes(raw)
    lines = raw.decode().splitlines()
    old = next(json.loads(line) for line in lines if json.loads(line).get('candidate_id') == OLD_ID)
    assert old['disposition'] == 'reviewed_incidental' and old['reason_code'] == 'identifier_or_navigation'
    new = dict(old, candidate_id=candidate_id(after))
    assert new['candidate_id'] != OLD_ID
    changed = [json.dumps(new, sort_keys=True, separators=(',', ':')) if json.loads(line).get('candidate_id') == OLD_ID else line for line in lines]
    updated = ('\n'.join(changed) + '\n').encode()
    REGISTRY.write_bytes(updated)
    (BASE / 'registry-after.jsonl').write_bytes(updated)
    target.write_text(json.dumps({'path': PATH, 'before_line': before, 'after_line': after, 'old': old, 'new': new,
                                  'review': 'Decision 0102 and its rationale are unchanged. Only its link destination becomes the native-safe raw source view. The numeral still identifies a decision/navigation reference and asserts no empirical measurement.'}, sort_keys=True, indent=2) + '\n')
    print('PASS exactly one navigation identity refreshed; original reviewed meaning and every other disposition preserved.')


if __name__ == '__main__':
    main()
