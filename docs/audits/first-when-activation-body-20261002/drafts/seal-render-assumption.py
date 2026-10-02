"""Collect this owned, unsealed evidence once; never replay an HDL input."""
import hashlib
import json
import os
import shutil
import subprocess
import sys
from html.parser import HTMLParser
from pathlib import Path

BASE = Path(__file__).resolve().parent
SCRATCH = Path('.artifacts/first-when-activation')
BASELINE = '43dcfae199ca7d93a88fe047f886fdcc6522c2ec'
ROOT = str(Path('.').resolve()) + '/'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + '\n')


def tree(revision, roots):
    raw = subprocess.check_output(['git', 'ls-tree', '-r', '-z', revision, '--'] + roots)
    entries = {}
    for record in raw.split(b'\0'):
        if not record:
            continue
        meta, path = record.split(b'\t')
        mode, kind, identity = meta.decode().split(' ')
        assert kind == 'blob', 'source census cannot cross a submodule boundary'
        entries[path.decode()] = dict(mode=mode, blob=identity)
    return raw, entries


def read_blobs(entries):
    names = list(entries)
    raw = subprocess.check_output(['git', 'cat-file', '--batch'],
        input=''.join(entries[name]['blob'] + '\n' for name in names).encode())
    offset, result = 0, {}
    for name in names:
        end = raw.index(b'\n', offset)
        identity, kind, size = raw[offset:end].decode().split(' ')
        assert identity == entries[name]['blob'] and kind == 'blob'
        size = int(size)
        result[name] = raw[end + 1:end + 1 + size]
        offset = end + 2 + size
    assert offset == len(raw)
    return result


def current_bytes(path):
    p = Path(path)
    return os.readlink(p).encode() if p.is_symlink() else p.read_bytes()


class Render(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts, self.links, self.code, self.in_code = [], [], [], False

    def handle_data(self, data):
        self.parts.append(data)
        if self.in_code:
            self.code.append(data)

    def handle_starttag(self, tag, attrs):
        if tag == 'code':
            self.in_code = True
        if tag == 'a':
            self.links += [value for key, value in attrs if key == 'href']

    def handle_endtag(self, tag):
        if tag == 'code':
            self.in_code = False


def collect():
    assert not (BASE / 'manifest.json').exists(), 'sealed archive is immutable'
    assert (SCRATCH / 'test-final-complete.t').read_bytes() == Path('t/2040-isf-first-when-activation-body.t').read_bytes()
    assert (SCRATCH / 'LoweringIR-final.pm').read_bytes() == Path('perl/FSM/Scheduler/ISF/LoweringIR.pm').read_bytes()
    hashes = {}
    for source in sorted(p for p in SCRATCH.rglob('*') if p.is_file()):
        # The host-wide process survey is not a project evidence product and
        # may contain unrelated command lines. Keep it ignored, never publish it.
        if source.name == 'processes.txt':
            continue
        assert not source.is_symlink()
        relative = source.relative_to(SCRATCH)
        destination = BASE / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        original = source.read_bytes()
        retained = original.replace(ROOT.encode(), b'')
        destination.write_bytes(retained)
        hashes[str(relative)] = dict(original_sha256=sha(original), retained_sha256=sha(retained),
            normalization='exact runtime repository prefix only')
    write_json(BASE / 'normalization.json', hashes)
    raw, entries = tree(BASELINE, ['bin', 'perl'])
    blobs = read_blobs(entries)
    additions = subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard', '-z', '--', 'bin', 'perl'])
    assert not additions, 'this slice adds no production file'
    members = {path: dict(before_sha256=sha(blobs[path]), after_sha256=sha(current_bytes(path)),
        before_bytes=len(blobs[path]), after_bytes=len(current_bytes(path)), **entries[path]) for path in entries}
    changed = sorted(path for path, value in members.items() if value['before_sha256'] != value['after_sha256'])
    assert changed == ['perl/FSM/Scheduler/ISF/LoweringIR.pm']
    write_json(BASE / 'production-inventory.json', dict(baseline=BASELINE, changed_existing=changed, added=[], members=members))
    (BASE / 'production-inventory.zlist').write_bytes(raw)
    (BASE / 'LoweringIR-baseline.pm').write_bytes(blobs[changed[0]])
    old = json.loads(Path('docs/audits/record-output-owner-read-preparation-20261002/immutable-parents.json').read_text())
    roots = old['roots'] + ['docs/audits/record-output-owner-read-preparation-20261002']
    raw, entries = tree(BASELINE, roots)
    blobs = read_blobs(entries)
    members = {}
    for path, entry in entries.items():
        now = current_bytes(path)
        assert now == blobs[path], path + ' immutable predecessor changed'
        members[path] = dict(bytes=len(now), sha256=sha(now), **entry)
    write_json(BASE / 'immutable-parents.json', dict(baseline=BASELINE, roots=roots, members=members))
    (BASE / 'immutable-parents.zlist').write_bytes(raw)
    renders = {}
    for chapter in ['13b-transactions', '13e-data-manipulation', '13i-downstream-integration', '13j-type-enum-aggregate']:
        html = Path('docs/book/book/' + chapter + '.html')
        parser = Render()
        parser.feed(html.read_text())
        text = ' '.join(' '.join(parser.parts).split())
        if chapter == '13b-transactions':
            assert "when activation body supports only '(sample port as name)' clauses" in text
            assert '(actor when_activation_samples' in ''.join(parser.code)
            assert '(actor when_branch_actions' in ''.join(parser.code)
            evidence = '../../../docs/audits/first-when-activation-body-20261002/scope.txt'
            assert evidence in parser.links and (html.parent / evidence).resolve() == (BASE / 'scope.txt').resolve()
        elif chapter == '13e-data-manipulation':
            assert 'A first select currently expands to an entry when' in text
        else:
            assert 'first-' in text and 'macro' in text
        (BASE / (chapter + '.html')).write_bytes(html.read_bytes())
        renders[chapter] = dict(sha256=sha(html.read_bytes()), visual_browser_qa=False)
    wrapper = Path('docs/book/src/13i-downstream-integration.md').read_text()
    includes = [line.split('/')[3].split('}')[0] for line in wrapper.splitlines() if line.startswith('{{#include')]
    assert includes == ['10-downstream-readiness-source.md', '11-downstream-actor-transactions.md',
        '12-downstream-rules-artifacts-reports.md', '13-downstream-diagnostics-conformance.md']
    write_json(BASE / 'render.json', dict(chapters=renders, canonical_includes=includes))
    print('PASS collected full products/receipts, exact producers, rendered text/code/links and immutable predecessors')


def seal():
    assert not (BASE / 'manifest.json').exists(), 'sealed archive is immutable'
    entries = {str(p.relative_to(BASE)): dict(bytes=p.stat().st_size, sha256=sha(p.read_bytes()))
        for p in BASE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    write_json(BASE / 'manifest.json', dict(baseline=BASELINE,
        owner='SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.3', entries=entries))
    print('PASS sealed exact member census; this archive is now immutable')


if __name__ == '__main__':
    {'collect': collect, 'seal': seal}[sys.argv[1]]()
