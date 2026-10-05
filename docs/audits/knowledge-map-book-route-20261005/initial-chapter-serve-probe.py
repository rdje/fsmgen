"""Exercise actual served book references; retain responses and stop the server."""
import hashlib
import json
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/knowledge-map-book-route-20261005')


class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.href = None; self.text = []; self.links = []

    def handle_starttag(self, tag, attrs):
        if tag == 'a':
            self.href = dict(attrs).get('href'); self.text = []

    def handle_data(self, text):
        if self.href is not None:
            self.text.append(text)

    def handle_endtag(self, tag):
        if tag == 'a' and self.href is not None:
            self.links.append((self.href, ''.join(self.text))); self.href = None


def request(opener, url):
    try:
        with opener.open(url, timeout=3) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as error:
        return error.code, error.read()


def main():
    phase = sys.argv[1]
    assert phase in ('before', 'after'), 'explicit fixed probe phase'
    with socket.socket() as reservation:
        reservation.bind(('127.0.0.1', 0)); port = reservation.getsockname()[1]
    command = ['mdbook', 'serve', 'docs/book', '--hostname', '127.0.0.1', '--port', str(port), '--dest-dir', '.artifacts/knowledge-map-book-route/export']
    log_path = Path('.artifacts/knowledge-map-book-route') / (phase + '-server.log')
    log_path.parent.mkdir(parents=True, exist_ok=True)
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    base = 'http://127.0.0.1:' + str(port) + '/'
    with log_path.open('wb') as log:
        server = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 45
            while True:
                assert server.poll() is None, 'public book server remains running during startup'
                try:
                    entry_status, entry = request(opener, base + '90-reference-map.html')
                    break
                except urllib.error.URLError:
                    assert time.monotonic() < deadline, 'public book server startup deadline'
                    time.sleep(0.2)
            parser = Links(); parser.feed(entry.decode())
            links = [href for href, text in parser.links if text == 'the Knowledge Map architecture']
            assert len(links) == 1, 'actual unique rendered architecture link'
            target_url = urllib.parse.urljoin(base + '90-reference-map.html', links[0])
            target_status, target = request(opener, target_url)
            missing_status, missing = request(opener, base + 'nonexistent-knowledge-map-route.html')
            record = {'phase': phase, 'command': command, 'entry': {'path': '90-reference-map.html', 'status': entry_status, 'body': entry.decode()},
                      'link': links[0], 'target': {'path': urllib.parse.urlparse(target_url).path, 'status': target_status, 'body': target.decode()},
                      'missing_control': {'path': 'nonexistent-knowledge-map-route.html', 'status': missing_status, 'body': missing.decode()}}
        finally:
            server.terminate()
            try:
                server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill(); server.wait(timeout=5)
    assert server.poll() is not None, 'own public server fully consumed'
    record['server_status'] = server.returncode
    record['server_log'] = log_path.read_text()
    record['source_identity'] = {str(p): {'bytes': len(p.read_bytes()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in (
        Path('docs/book/src/90-reference-map.md'), Path('docs/book/src/SUMMARY.md'), Path('docs/book/book.toml'), Path('knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md'))}
    (BASE / (phase + '-serve.json')).write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    assert entry_status == 200 and missing_status == 404, 'public entry and genuine missing-path control'
    assert target_status == (404 if phase == 'before' else 200), 'actual introduced/fixed target route'
    print('PASS actual public ' + phase + ' route: entry200, target' + str(target_status) + ', missing404; own server stopped.')


if __name__ == '__main__':
    main()
