#!/usr/bin/env python3
"""Independently join current module sources, coverage and native copied assets."""
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import sys
from urllib.parse import unquote, urlsplit

root = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == root
assert len(sys.argv) == 2, 'Usage: verify_delivery.py REPOSITORY_RELATIVE_BOOK_OUTPUT'
relative = Path(sys.argv[1])
assert not relative.is_absolute() and '..' not in relative.parts
built = root / relative
source = root / 'docs/book/src/perl-api'
coverage = json.loads((built / 'perl-api/coverage.json').read_bytes())
expected_sources = sorted(p.relative_to(root).as_posix() for p in (root / 'perl/FSM').rglob('*.pm'))
assert [r['source'] for r in coverage] == expected_sources
modules = {r['module'] for r in coverage}
entrypoints = json.loads((root / 'docs/pod-api-entrypoints.json').read_bytes())
assert {r['module'] for r in coverage if r['role'] == 'selected_entry_point'} == set(entrypoints)
assert all(r['pod'] for r in coverage if r['module'] in entrypoints)
manifest = json.loads((source / '.fsmgen-pod-reference.json').read_bytes())
for path, identity in manifest['inputs']['sources'].items():
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == identity
for path, identity in manifest['inputs']['tools'].items():
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == identity
source_files = {p.relative_to(source).as_posix(): p.read_bytes() for p in source.rglob('*') if p.is_file()}
copied = built / 'perl-api'
copied_files = {p.relative_to(copied).as_posix(): p.read_bytes() for p in copied.rglob('*') if p.is_file()}
assert source_files == copied_files, 'Native delivery membership/bytes differ'
assert set(source_files) == set(manifest['outputs']) | {'.fsmgen-pod-reference.json'}
for name, identity in manifest['outputs'].items():
    assert hashlib.sha256(copied_files[name]).hexdigest() == identity


class Page(HTMLParser):
    def __init__(self, raw):
        super().__init__(convert_charrefs=True)
        self.anchors, self.links = set(), []
        self.feed(raw.decode())

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.anchors.update(attrs[k] for k in ('id', 'name') if attrs.get(k))
        self.links.extend(attrs[k] for k in ('href', 'src') if attrs.get(k))


paths = [p for p in copied.rglob('*.html')]
guide = built / '11a-perl-api-reference.html'
paths += [guide, built / '11-extensions-and-embedding.html']
pages = {p.resolve(): Page(p.read_bytes()) for p in paths}
links = 0
for path in [p.resolve() for p in copied.rglob('*.html')] + [guide.resolve()]:
    for href in pages[path].links:
        url = urlsplit(href)
        if url.scheme or url.netloc:
            continue
        assert not url.path.startswith('/'), href
        target = (path.parent / unquote(url.path)).resolve() if url.path else path
        assert target.is_relative_to(built.resolve()) and target.is_file(), (path.name, href)
        if url.fragment and target in pages:
            assert unquote(url.fragment) in pages[target].anchors, (path.name, href)
        links += 1
assert 'perl-api/index.html' in pages[guide.resolve()].links
assert all((copied / (m.replace('::', '/') + '.html')).is_file() for m in modules)
print(json.dumps({'book_output': relative.as_posix(), 'module_sources': len(expected_sources),
                  'provided_pod': sum(r['pod'] for r in coverage),
                  'missing_pod': sum(not r['pod'] for r in coverage),
                  'selected_entrypoints': len(entrypoints), 'copied_members': len(copied_files),
                  'local_link_checks': links, 'source_and_native_bytes_equal': True}, indent=2))
