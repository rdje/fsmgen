"""Reproduce the complete admitted route population through public mdbook serve."""
import json
import socket
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE = Path('docs/audits/book-reference-classification-20261005')


def main():
    exported = json.loads((BASE / 'served.json').read_text())
    with socket.socket() as reservation:
        reservation.bind(('127.0.0.1', 0)); port = reservation.getsockname()[1]
    command = ['mdbook', 'serve', 'docs/book', '--hostname', '127.0.0.1', '--port', str(port), '--dest-dir', '.artifacts/book-reference-classification/native-book']
    log_path = Path('.artifacts/book-reference-classification/native-server.log')
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    origin = 'http://127.0.0.1:' + str(port)
    def fetch(path):
        try:
            response = opener.open(origin + path, timeout=10)
        except urllib.error.HTTPError as error:
            response = error
        with response:
            return {'path': path, 'status': response.status, 'body': response.read().decode(), 'content_type': response.headers.get('Content-Type')}
    record = {'command': command, 'responses': {}}
    with log_path.open('wb') as log:
        server = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 45
            while True:
                assert server.poll() is None, 'public native server remains running during startup'
                try:
                    fetch('/90-reference-map.html'); break
                except urllib.error.URLError:
                    assert time.monotonic() < deadline, 'native startup deadline'
                    time.sleep(0.1)
            for path in sorted(exported['responses']):
                record['responses'][path] = fetch(path)
            record['missing_control'] = fetch(exported['missing_control']['path'])
        finally:
            server.terminate()
            try:
                server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill(); server.wait(timeout=5)
            record['server_status'] = server.returncode
    record['server_log'] = log_path.read_text()
    path = BASE / 'native-served.json'
    assert not path.exists(), 'retain complete first native capture'
    path.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    assert server.poll() is not None
    assert record['missing_control']['status'] == 404
    assert all(row['status'] == exported['responses'][path]['status'] for path, row in record['responses'].items()), 'complete native/export status agreement'
    print('PASS complete actual native/export route status agreement; native server outcome consumed.')


if __name__ == '__main__':
    main()
