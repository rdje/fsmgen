#!/usr/bin/env python3
"""Reproduce HTML triage candidates; this is not browser or visual signoff."""
import argparse
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def sha(data):
    return hashlib.sha256(data).hexdigest()


class Prose(HTMLParser):
    def __init__(self):
        super().__init__()
        self.main = False
        self.excluded = 0
        self.active = []
        self.nodes = []
        self.counts = {'p': 0, 'li': 0}
        self.heading = ''

    def handle_starttag(self, tag, attrs):
        if tag == 'main':
            self.main = True
        if not self.main:
            return
        if tag in ('p', 'li', 'ul', 'ol', 'div', 'blockquote', 'br', 'pre', 'table'):
            for node in self.active:
                node['chunks'].append(' ')
        if tag in ('pre', 'table', 'script', 'style'):
            self.excluded += 1
        if re.fullmatch(r'h[1-6]', tag):
            self.heading = dict(attrs).get('id', '')
        if tag in self.counts:
            parent = next((n for n in reversed(self.active) if n['tag'] == 'li'), None)
            if parent:
                parent['paragraphs' if tag == 'p' else 'nested_items'] += 1
            node = dict(tag=tag, index=self.counts[tag], heading=self.heading,
                        paragraphs=0, nested_items=0, chunks=[])
            self.counts[tag] += 1
            self.active.append(node)
            self.nodes.append(node)

    def handle_endtag(self, tag):
        if not self.main:
            return
        if tag in ('p', 'li', 'ul', 'ol', 'div', 'blockquote', 'pre', 'table'):
            for node in self.active:
                node['chunks'].append(' ')
        if tag in self.counts:
            if not self.active or self.active[-1]['tag'] != tag:
                raise ValueError(f'unbalanced target element: {tag}')
            self.active.pop()
        if tag in ('pre', 'table', 'script', 'style'):
            self.excluded -= 1
        if tag == 'main':
            if self.active or self.excluded:
                raise ValueError('unfinished main content')
            self.main = False

    def handle_data(self, data):
        if not self.main or self.excluded:
            return
        # Nearest member only: a parent list item does not inherit nested items.
        for tag in self.counts:
            node = next((n for n in reversed(self.active) if n['tag'] == tag), None)
            if node:
                node['chunks'].append(data)

    def rows(self):
        result = []
        for node in self.nodes:
            # Joining without spaces preserves adjacent inline spans as rendered text.
            value = ' '.join(''.join(node['chunks']).split())
            if value:
                result.append(dict(selector='main '+node['tag'], index=node['index'],
                                   heading=node['heading'], words=len(value.split()),
                                   characters=len(value), text_sha256=sha(value.encode()),
                                   excerpt=value[:240], paragraphs=node['paragraphs'],
                                   nested_items=node['nested_items']))
        return result


def chapters():
    summary = ROOT / 'docs/book/src/SUMMARY.md'
    names = re.findall(r'\]\(([^)#]+\.md)(?:#[^)]*)?\)', summary.read_text())
    if not names or len(names) != len(set(names)):
        raise ValueError('empty or duplicate chapter inventory')
    if any(not re.fullmatch(r'[\w.-]+\.md', n) for n in names):
        raise ValueError('chapter layout changed; review the census before extending it')
    return names


def input_bytes(names):
    pending = [ROOT / 'docs/book/book.toml', ROOT / 'docs/book/src/SUMMARY.md']
    pending += [ROOT / 'docs/book/src' / name for name in names]
    inputs = {}
    while pending:
        path = pending.pop().resolve()
        relative = path.relative_to(ROOT).as_posix()
        if relative in inputs:
            continue
        data = path.read_bytes()
        inputs[relative] = data
        for include in re.findall(rb'\{\{#include\s+([^\s}]+)\s*\}\}', data):
            # This captured book uses whole-file includes; anchors need new review.
            if b':' in include:
                raise ValueError('include selector changed')
            pending.append(path.parent / include.decode())
    return inputs


def derive(build, revision):
    names = chapters()
    inputs = input_bytes(names)
    for path, data in inputs.items():
        saved = subprocess.check_output(['git', 'show', revision+':'+path], cwd=ROOT)
        if data != saved:
            raise ValueError('source differs from capture revision: '+path)
    rows, rendered = [], {}
    for name in names:
        filename = str(Path(name).with_suffix('.html'))
        data = (build / filename).read_bytes()
        rendered[filename] = sha(data)
        parser = Prose()
        parser.feed(data.decode())
        parser.close()
        rows += [dict(chapter=name, **row) for row in parser.rows()]
    selected = {}

    def choose(population, count, reason):
        for row in sorted(population, key=lambda r: (-r['words'], r['chapter'], r['index']))[:count]:
            key = (row['chapter'], row['selector'], row['index'])
            if key not in selected:
                selected[key] = dict(row, reasons=[])
            selected[key]['reasons'].append(reason)

    for tag in ('p', 'li'):
        choose([r for r in rows if r['selector'] == 'main '+tag], 8, 'longest '+tag)
    for name in ('12-cookbook.md', '14-feature-backlog.md'):
        for tag in ('p', 'li'):
            choose([r for r in rows if r['chapter'] == name and r['selector'] == 'main '+tag],
                   3, 'required chapter '+tag)
        choose([r for r in rows if r['chapter'] == name and r['selector'] == 'main li'
                and r['paragraphs'] > 1], 2, 'list-contained paragraph sample')
    return dict(schema='fsmgen.mdbook_spacing_triage.v1', source_revision=revision,
                instrument_sha256=sha(Path(__file__).read_bytes()),
                mdbook_version=subprocess.check_output(['mdbook', '--version'], text=True).strip(),
                input_sha256={p: sha(b) for p, b in sorted(inputs.items())},
                rendered_sha256=rendered, chapter_count=len(names),
                population={tag: sum(r['selector'] == 'main '+tag for r in rows) for tag in ('p', 'li')},
                candidates=list(selected.values()),
                limits='HTML text triage only. Paragraph and list-item populations overlap. Text inside pre/table/script/style is excluded; inline code remains. Word count is whitespace-token count, not rendered height or a defect classification. No browser DOM, viewport, theme, computed CSS or visual signoff exists.',
                tool_dependency='Installed mdbook is a read-only external toolchain dependency; all generated output is repository-local.')


def qualify():
    p = Prose()
    p.feed('<p>outside</p><main><h2 id="sample">Sample</h2><ul><li><p>one <code>two</code></p>'
           '<p>three</p><ul><li>child</li></ul><pre>excluded code</pre></li></ul>'
           '<table><tr><td><p>excluded table</p></td></tr></table></main>')
    rows = p.rows()
    expected = [('main li', 0, 3, 2, 1), ('main p', 0, 2, 0, 0),
                ('main p', 1, 1, 0, 0), ('main li', 1, 1, 0, 0)]
    actual = [(r['selector'], r['index'], r['words'], r['paragraphs'], r['nested_items']) for r in rows]
    if actual != expected:
        raise ValueError(('parser fixture differs', actual))
    bad = Prose()
    try:
        bad.feed('<main><li><p>broken</li></main>')
    except ValueError:
        pass
    else:
        raise ValueError('malformed fixture unexpectedly accepted')
    print('parser control: exact hand-labeled scopes agree; malformed nesting rejected')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', required=True, type=Path)
    parser.add_argument('--capture', action='store_true')
    parser.add_argument('--qualify', action='store_true')
    args = parser.parse_args()
    build = args.build.resolve()
    build.relative_to(ROOT)
    if build.stat().st_dev != ROOT.stat().st_dev:
        raise ValueError('build is off-volume')
    if args.qualify:
        qualify()
    path = HERE / 'candidates.json'
    previous = None if args.capture else json.loads(path.read_text())
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True, cwd=ROOT).strip() if args.capture else previous['source_revision']
    record = derive(build, revision)
    if args.capture:
        path.write_text(json.dumps(record, indent=2, sort_keys=True)+'\n')
    elif record != previous:
        raise ValueError('census differs from the saved capture')
    print(f"HTML triage: {record['chapter_count']} chapters, {record['population']}, {len(record['candidates'])} distinct candidates; no visual signoff")


if __name__ == '__main__':
    main()
