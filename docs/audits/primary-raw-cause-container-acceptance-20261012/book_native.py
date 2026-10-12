"""Qualify the actual native chapter and the bounded container notice."""
from container_common import *

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/primary-raw-cause-parent-acceptance-20261011/complete.py'


def qualify(html):
    factory = public()
    prior = factory['historical']()
    factory['check_native'](html, prior)
    visible = prior['book']['Visible']()
    visible.feed(html)
    need(visible.codes.count(COMMAND) == 1, 'one exact recovered cause acceptance command')
    guide = (BASE / 'guide.txt').read_bytes()
    need(' '.join(guide.decode().split()) in ' '.join(''.join(visible.parts).split()),
         'whole native container notice and unchanged finite limits')
    return dict(command=COMMAND, notice=pin(guide), html=pin(html.encode()),
                condition='Actual native chapter and retained current factory scopes qualify; visual QA remains separate.')


if __name__ == '__main__':
    factory = public()
    path = Path('docs/book/book/13k-isf-feature-support-matrix.html')
    raw = factory['plane'].local_read(factory['ROOT'] / path, factory['plane'].SOURCE_BYTES * 4)
    result = qualify(raw.decode())
    path = BASE / 'native-chapter.html.gz'
    need(not path.exists(), 'retain first actual native chapter')
    path.write_bytes(gzip.compress(raw, mtime=0))
    save('book-native.json', result)
    print('PASS whole native cause-container guidance and unchanged finite source/native limits.')
