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
SCRATCH = Path('.artifacts/procedure-cond-normalization')
BASELINE = '518d99d288b6b1cf4fd2f8f38518d684d37740a6'
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
    assert (SCRATCH / 'boundary-test-final.t').read_bytes() == Path('t/2042-isf-procedure-cond-normalization.t').read_bytes()
    assert Path('t/2041-isf-conditional-macro-intent-qualification.t').read_bytes() == subprocess.check_output(['git','show',BASELINE+':t/2041-isf-conditional-macro-intent-qualification.t'])
    hashes = {}
    for source in sorted(p for p in SCRATCH.rglob('*') if p.is_file()):
        assert not source.is_symlink()
        relative = source.relative_to(SCRATCH)
        target = BASE / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        original = source.read_bytes()
        retained = original.replace(ROOT.encode(), b'')
        target.write_bytes(retained)
        hashes[str(relative)] = dict(original_sha256=sha(original), retained_sha256=sha(retained), normalization='exact runtime repository prefix only')
    write_json(BASE / 'normalization.json', hashes)
    raw, entries = tree(BASELINE, ['bin', 'perl'])
    blobs = read_blobs(entries)
    assert not subprocess.check_output(['git','ls-files','--others','--exclude-standard','-z','--','bin','perl'])
    members = {}
    for path, entry in entries.items():
        now = current_bytes(path)
        assert now == blobs[path], path + ' production restoration incomplete'
        members[path] = dict(bytes=len(now), sha256=sha(now), **entry)
    write_json(BASE / 'production-inventory.json', dict(baseline=BASELINE, changed_existing=[], added=[], members=members))
    (BASE / 'production-inventory.zlist').write_bytes(raw)
    old = json.loads(Path('docs/audits/conditional-macro-intent-20261002/immutable-parents.json').read_text())
    roots = old['roots'] + ['docs/audits/conditional-macro-intent-20261002']
    raw, entries = tree(BASELINE, roots)
    blobs = read_blobs(entries)
    members = {}
    for path, entry in entries.items():
        now = current_bytes(path)
        assert now == blobs[path], path + ' immutable predecessor changed'
        members[path] = dict(bytes=len(now), sha256=sha(now), **entry)
    write_json(BASE / 'immutable-parents.json', dict(baseline=BASELINE, roots=roots, members=members))
    (BASE / 'immutable-parents.zlist').write_bytes(raw)
    for source in Path('docs/audits/conditional-macro-intent-20261002/sources').glob('*.isf'):
        target = BASE / 'macro-sources' / source.name
        target.parent.mkdir(exist_ok=True)
        target.write_bytes(source.read_bytes())
    renders = {}
    markers = {
        '13b-transactions': "when activation body supports only '(sample port as name)' clauses",
        '13d-control-flow': 'A normalization candidate would newly admit',
        '13i-downstream-integration': 'the committed parser is restored',
        '13l-procedures': 'explicit source-intent prerequisite must qualify',
        '13k-isf-feature-support-matrix': 'source intent .5.2 must precede safe normalization',
    }
    for chapter, marker in markers.items():
        html = Path('docs/book/book/' + chapter + '.html')
        parser = Render()
        parser.feed(html.read_text())
        text = ' '.join(' '.join(parser.parts).split())
        assert marker in text, chapter + ' missing maintained text'
        if chapter == '13l-procedures':
            evidence = '../../../docs/audits/procedure-cond-normalization-20261002/scope.txt'
            assert evidence in parser.links and (html.parent/evidence).resolve() == (BASE/'scope.txt').resolve()
            assert '(actor acc_demo' in ''.join(parser.code)
        (BASE/(chapter+'.html')).write_bytes(html.read_bytes())
        renders[chapter] = dict(sha256=sha(html.read_bytes()), visual_browser_qa=False)
    wrapper = Path('docs/book/src/13i-downstream-integration.md').read_text()
    includes = [line.split('/')[3].split('}')[0] for line in wrapper.splitlines() if line.startswith('{{#include')]
    assert includes == ['10-downstream-readiness-source.md','11-downstream-actor-transactions.md','12-downstream-rules-artifacts-reports.md','13-downstream-diagnostics-conformance.md']
    write_json(BASE/'render.json', dict(chapters=renders, canonical_includes=includes))
    print('PASS complete terminal evidence, restored production, immutable predecessors and rendered text/code/links')


def seal():
    assert not (BASE/'manifest.json').exists(), 'sealed archive is immutable'
    entries = {str(p.relative_to(BASE)): dict(bytes=p.stat().st_size, sha256=sha(p.read_bytes())) for p in BASE.rglob('*') if p.is_file() and p.name!='manifest.json'}
    write_json(BASE/'manifest.json', dict(baseline=BASELINE, owner='SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.4.1', entries=entries))
    print('PASS sealed exact member census; archive now immutable')


if __name__=='__main__':
    {'collect':collect,'seal':seal}[sys.argv[1]]()
