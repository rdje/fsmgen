"""Capture the complete advertised helper reader through public native serve."""
import json
import socket
import subprocess
import time
import urllib.error
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/record-value-current-helper-reader-20261005')
WORK = Path('.artifacts/record-value-current-helper-reader/native-delivery')


def main():
    assert not WORK.exists(); WORK.mkdir(parents=True)
    root = Path.cwd().resolve(); destination = (WORK / 'book').resolve()
    assert destination.is_relative_to(root) and destination.parent.stat().st_dev == root.stat().st_dev
    command = ['mdbook', 'serve', 'docs/book', '--dest-dir', str(destination), '--hostname', '127.0.0.1']
    with socket.socket() as reservation:
        reservation.bind(('127.0.0.1', 0)); port = reservation.getsockname()[1]
    command += ['--port', str(port)]
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    def fetch(path):
        try: response = opener.open('http://127.0.0.1:'+str(port)+'/'+path, timeout=5)
        except urllib.error.HTTPError as error: response = error
        with response: return {'status': response.status, 'body': response.read().decode()}
    log_path = WORK / 'server.log'; record = {'destination': str(destination.relative_to(root)), 'command': [str(WORK / 'book') if v == str(destination) else v for v in command]}
    with log_path.open('wb') as log:
        server = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic()+30
            while True:
                assert server.poll() is None
                try: record['chapter'] = fetch('13k-isf-feature-support-matrix.html'); break
                except urllib.error.URLError:
                    assert time.monotonic() < deadline; time.sleep(0.1)
            record['missing'] = fetch('genuine-missing-helper-reader.html')
        finally:
            server.terminate()
            try: server.wait(timeout=5)
            except subprocess.TimeoutExpired: server.kill(); server.wait(timeout=5)
    record['server_status'] = server.returncode; record['server_log'] = log_path.read_text()
    record['built_chapter'] = (destination / '13k-isf-feature-support-matrix.html').read_text()
    class MainText(HTMLParser):
        def __init__(self): super().__init__(); self.inside = False; self.parts = []
        def handle_starttag(self, tag, attrs):
            if tag == 'main': self.inside = True
        def handle_endtag(self, tag):
            if tag == 'main': self.inside = False
        def handle_data(self, data):
            if self.inside: self.parts.append(data)
    parser = MainText(); parser.feed(record['chapter']['body'])
    record['main_text'] = ''.join(parser.parts)
    target = BASE / 'native-delivery.json'; assert not target.exists()
    target.write_text(json.dumps(record, sort_keys=True, indent=2)+'\n')
    assert record['chapter']['status'] == 200 and record['missing']['status'] == 404 and server.poll() is not None
    transform = json.loads((BASE / 'transform.json').read_text())
    expected = ' '.join(transform['reader_section'].replace('```sh', '').replace('```', '').split())
    assert expected in ' '.join(record['main_text'].split()), 'complete advertised helper section in actual native main'
    assert record['built_chapter'] == record['chapter']['body']
    print('PASS whole scoped helper reader source meaning and command are served natively; missing404 and consumed server control hold.')


if __name__ == '__main__':
    main()
