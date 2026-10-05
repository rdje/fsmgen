"""Capture actual chapter-body clicks and every resolved local native response."""
import hashlib
import json
import socket
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/book-reference-publication-20261005')
WORK = Path('.artifacts/book-reference-publication/native')
CHAPTERS = ('13k-isf-feature-support-matrix', '90-reference-map')


class BodyLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_main = False
        self.links = []
        self.ids = set()

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        if tag == 'main':
            self.in_main = True
        if tag == 'a' and self.in_main and 'href' in attrs:
            self.links.append(attrs['href'])

    def handle_endtag(self, tag):
        if tag == 'main':
            self.in_main = False


def parse(body):
    parser = BodyLinks()
    parser.feed(body)
    return parser


def main():
    assert not WORK.exists() and not (BASE / 'native.json').exists()
    WORK.mkdir(parents=True)
    root = Path.cwd().resolve()
    destination = (WORK / 'book').resolve()
    assert destination.is_relative_to(root) and destination.parent.stat().st_dev == root.stat().st_dev
    rows = json.loads(Path('docs/audits/book-reference-selection-20261005/selected-routes.json').read_text())['routes']
    sources = {row['source']: Path(row['source']).read_bytes().decode('utf-8') for row in rows}
    build_command = ['mdbook', 'build', 'docs/book', '--dest-dir', str(destination)]
    build = subprocess.run(build_command, capture_output=True, text=True)
    record = {'source_boundary': sources, 'version': subprocess.check_output(['mdbook', '--version'], text=True),
              'build': {'status': build.returncode, 'stdout': build.stdout, 'stderr': build.stderr},
              'build_command': ['mdbook', 'build', 'docs/book', '--dest-dir', str(WORK / 'book')]}
    assert build.returncode == 0
    with socket.socket() as reservation:
        reservation.bind(('127.0.0.1', 0))
        port = reservation.getsockname()[1]
    origin = 'http://127.0.0.1:' + str(port)
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    def fetch(path):
        try:
            response = opener.open(origin + path, timeout=5)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            raw = response.read()
            return {'status': response.status, 'body': raw.decode('utf-8'), 'bytes': len(raw),
                    'sha256': hashlib.sha256(raw).hexdigest(), 'content_type': response.headers.get('Content-Type')}

    command = ['mdbook', 'serve', 'docs/book', '--dest-dir', str(destination),
               '--hostname', '127.0.0.1', '--port', str(port)]
    log_path = WORK / 'server.log'
    record['responses'] = {}
    record['anchors'] = []
    with log_path.open('wb') as log:
        server = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 30
            while True:
                assert server.poll() is None
                try:
                    fetch('/90-reference-map.html')
                    break
                except urllib.error.URLError:
                    assert time.monotonic() < deadline
                    time.sleep(0.1)
            for chapter in CHAPTERS:
                chapter_path = '/' + chapter + '.html'
                response = fetch(chapter_path)
                record['responses'][chapter_path] = response
                for href in parse(response['body']).links:
                    resolved = urllib.parse.urlsplit(urllib.parse.urljoin(origin + chapter_path, href))
                    assert resolved.netloc == urllib.parse.urlsplit(origin).netloc, 'admitted chapters retain local body links'
                    record['anchors'].append({'chapter': chapter, 'href': href, 'path': resolved.path,
                                              'fragment': urllib.parse.unquote(resolved.fragment)})
                    if resolved.path not in record['responses']:
                        record['responses'][resolved.path] = fetch(resolved.path)
            record['missing'] = fetch('/reference-source/genuine-missing.source.txt')
            record['manifest'] = fetch('/reference-source/routes.jsonl')
        finally:
            server.terminate()
            try:
                server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait(timeout=5)
            record['server_status'] = server.returncode
            record['server_log'] = log_path.read_text()
            record['serve_command'] = ['mdbook', 'serve', 'docs/book', '--dest-dir', str(WORK / 'book'),
                                       '--hostname', '127.0.0.1', '--port', str(port)]
            record['built_chapters'] = {chapter: (destination / (chapter + '.html')).read_bytes().decode('utf-8')
                                        for chapter in CHAPTERS}
            record['built_assets'] = {row['source']: (destination / row['asset']).read_bytes().decode('utf-8') for row in rows}
            (BASE / 'native.json').write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    assert all(Path(path).read_bytes().decode('utf-8') == body for path, body in sources.items()), 'stable complete source capture boundary'
    print('PASS captured full actual admitted chapter-body anchors and native source responses; own server stopped and result consumed.')


if __name__ == '__main__':
    main()
