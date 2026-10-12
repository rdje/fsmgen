"""Check complete meaning-parent guidance in the actual rendered chapter."""
from acceptance_common import *

COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/consumer-meaning-parent-acceptance-20261012/verify.py'


def qualify(html):
    public = original_public()
    prior = public['historical']()
    public['check_native'](html, prior)
    visible = prior['book']['Visible']()
    visible.feed(html)
    need(visible.codes.count(COMMAND) == 1, 'native distinct complete meaning-parent replay')
    notice = (BASE / 'guide.txt').read_text().replace('```bash\n', '').replace('```\n', '').replace('`', '')
    need(' '.join(notice.split()) in ' '.join(''.join(visible.parts).split()),
         'native whole meaning-parent dated checkpoints and original limits')
    return dict(command=COMMAND, html=pin(html.encode()), notice=pin((BASE / 'guide.txt').read_bytes()),
                condition='Complete actual native guidance and every retained current factory scope; visual QA remains separately owned.')


if __name__ == '__main__':
    public = original_public()
    path = Path('docs/book/book/13k-isf-feature-support-matrix.html')
    raw = public['plane'].local_read(public['ROOT'] / path, public['plane'].SOURCE_BYTES * 4)
    result = qualify(raw.decode())
    output = BASE / 'native-chapter.html.gz'
    need(not output.exists(), 'fresh whole native meaning-parent chapter product')
    output.write_bytes(gzip.compress(raw, mtime=0))
    save('book-native.json', result)
    print('PASS whole native meaning-parent scope guidance and dated original scope.')
