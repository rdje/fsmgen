"""Capture every served body link in the two encountered chapters."""
import hashlib
import http.server
import json
import re
import subprocess
import threading
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/book-reference-classification-20261005')
REVISION = '5215d451f1db24c8d50fe644d00e91ab2b7e0d6a'
CHAPTERS = ['90-reference-map', '13k-isf-feature-support-matrix']


class Anchors(HTMLParser):
    def __init__(self):
        super().__init__(); self.main = False; self.links = []; self.ids = []

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == 'main': self.main = True
        if self.main:
            if 'id' in values: self.ids.append(values['id'])
            if tag == 'a' and 'href' in values:
                self.links.append({'href': values['href'], 'line': self.getpos()[0]})

    def handle_endtag(self, tag):
        if tag == 'main': self.main = False


def write(path, value):
    assert not path.exists(), 'preserve first complete capture'
    path.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')


def source_links(path, text):
    rows = []
    for match in re.finditer(r'\[[^\]\n]+\]\(([^)\s]+)\)', text):
        value = match[1]
        rendered = re.sub(r'\.md(?=$|[?#])', '.html', value)
        target = urllib.parse.urlsplit(value)
        canonical = None
        if not target.scheme and target.path:
            canonical = str(Path(path).parent.joinpath(urllib.parse.unquote(target.path)))
            canonical = __import__('posixpath').normpath(canonical)
        rows.append({'source': path, 'line': text[:match.start()].count('\n')+1,
                     'href': value, 'rendered_href': rendered, 'canonical': canonical})
    return rows


def main():
    paths = ['docs/book/src/' + chapter + '.md' for chapter in CHAPTERS]
    paths += ['docs/book/src/SUMMARY.md', 'docs/book/book.toml', 'knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md']
    sources = {}
    for path in paths:
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        assert Path(path).read_bytes() == raw
        sources[path] = raw.decode()
    provenance = [row for path, body in sources.items() if path.endswith('.md') and not path.endswith('SUMMARY.md') for row in source_links(path, body)]
    canonical = {}
    for row in provenance:
        path = row['canonical']
        if path and not path.startswith('docs/book/src/') and Path(path).is_file():
            raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
            current = Path(path).read_bytes()
            assert current == raw or path in ('MEMORY.md', 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'), 'only owning task/resume activation differs from committed canonical capture'
            canonical[path] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest(), 'text': raw.decode(),
                               'working_bytes': len(current), 'working_sha256': hashlib.sha256(current).hexdigest(),
                               'scope': 'Complete canonical bytes at the named committed boundary; working presence/identity observed separately.'}
    write(BASE / 'source.json', {'revision': REVISION, 'sources': sources, 'provenance': provenance, 'canonical': canonical})
    logs = []
    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory='docs/book/book', **kwargs)
        def log_message(self, format, *args):
            logs.append(format % args)
    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    thread = threading.Thread(target=server.serve_forever); thread.start()
    origin = 'http://127.0.0.1:' + str(server.server_port)
    def fetch(url):
        try:
            response = urllib.request.urlopen(url, timeout=10)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            raw = response.read()
            return {'path': urllib.parse.urlsplit(url).path, 'status': response.status,
                    'content_type': response.headers.get('Content-Type'), 'bytes': len(raw),
                    'sha256': hashlib.sha256(raw).hexdigest(), 'body': raw.decode()}
    record = {'origin': 'loopback ephemeral port; absolute host/port are invocation-only', 'chapters': {}, 'responses': {}}
    try:
        for chapter in CHAPTERS:
            entry = fetch(origin + '/' + chapter + '.html')
            assert entry['status'] == 200
            parser = Anchors(); parser.feed(entry['body'])
            links = []
            for link in parser.links:
                parsed = urllib.parse.urlsplit(link['href'])
                if parsed.scheme or parsed.netloc:
                    link['kind'] = 'remote-or-non-http'; links.append(link); continue
                resolved = urllib.parse.urlsplit(urllib.parse.urljoin(origin + entry['path'], link['href']))
                link['resolved_path'] = resolved.path; link['fragment'] = resolved.fragment
                associated = [r for r in provenance if r['rendered_href'] == link['href'] and (r['source'] == 'docs/book/src/' + chapter + '.md' or (chapter == '90-reference-map' and r['source'] == 'knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md'))]
                link['provenance'] = associated
                if associated and any(r['canonical'] and not r['canonical'].startswith('docs/book/src/') for r in associated):
                    link['kind'] = 'outside-book-canonical-reference'
                elif link['href'].startswith('#'):
                    link['kind'] = 'native-anchor'
                elif associated:
                    link['kind'] = 'native-chapter-reference'
                else:
                    link['kind'] = 'unattributed-local'
                if resolved.path not in record['responses']:
                    record['responses'][resolved.path] = fetch(origin + resolved.path)
                links.append(link)
            record['chapters'][chapter] = {'entry': entry, 'ids': parser.ids, 'links': links}
        record['missing_control'] = fetch(origin + '/genuine-missing-reference-20261005.html')
    finally:
        server.shutdown(); server.server_close(); thread.join(timeout=10)
        record['server_stopped'] = not thread.is_alive(); record['server_log'] = logs
        write(BASE / 'served.json', record)
    assert record['server_stopped']


if __name__ == '__main__':
    main()
