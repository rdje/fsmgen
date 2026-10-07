"""Authenticate interrupted custody and restore only the exact temporary control."""
import hashlib
import json
import sys
from pathlib import Path

CHECKS = Path('docs/audits/class-frame-publication-checks-20261006')
BASE = Path('docs/audits/record-value-class-frame-publication-20261006')
CHAPTER = Path('docs/book/src/13k-isf-feature-support-matrix.md')


def identity(raw):
    return dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())


def check():
    record = json.loads((CHECKS / 'crash-recovery.json').read_text())
    assert record['revision'] == '50dd117496d4d226bff3cf2a5226caab45104416'
    assert record['owner'] == json.loads((BASE / 'binding.json').read_text())['owner']
    for source,pin in record['members'].items():
        raw = Path(pin['retained']).read_bytes()
        assert identity(raw) == {k:v for k,v in pin.items() if k != 'retained'},source
    before = (CHECKS / 'unrelated-book-before.md.txt').read_bytes()
    assert identity(before) == record['backup']
    assert before == json.loads((BASE / 'publication.json').read_text())['chapter_after'].encode()
    interrupted = (CHECKS / 'interrupted-book.md.txt').read_bytes()
    assert interrupted == before + record['progress'].encode()
    prefix = json.loads((CHECKS / 'crash-role-prefix.json').read_text())
    expected = ['new-default','new-current','retention-default','retention-old-epoch',
        'tooling-default','tooling-old-epoch','core-obligation-1','core-obligation-2',
        'core-obligation-3','core-obligation-4','original-locality-obligation']
    assert record['completed_roles'] == expected
    assert [r['name'] for r in prefix['records']] == expected
    assert all(type(r['status']) is int and r['status'] ==
        (1 if r['name'].endswith('old-epoch') else 0) for r in prefix['records'])
    assert record['missing_result'] == 'roles-result.json'
    return before,prefix


if __name__ == '__main__':
    assert sys.argv[1:] in ([],['--restore'])
    before,prefix = check()
    if sys.argv[1:] == ['--restore']:
        assert not (CHECKS / 'roles-result.json').exists()
        assert json.loads((CHECKS / 'roles.json').read_text()) == prefix
        assert CHAPTER.read_bytes() == (CHECKS / 'interrupted-book.md.txt').read_bytes()
        CHAPTER.write_bytes(before)
    assert CHAPTER.read_bytes() == before
    print('PASS exact interrupted prefix/controller/book custody and publication-byte restoration; missing process result remains unclaimed.')
