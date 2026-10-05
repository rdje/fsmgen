"""Exercise static source symlinks through public mdBook build/serve and refresh."""
import hashlib
import json
import os
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE = Path('docs/audits/book-reference-selection-20261005')
ROOT = Path('docs/audits/book-reference-selection-20261005/prototype-visible')


def write(path, data):
    assert not path.exists(), 'retain first complete prototype capture'
    path.write_text(json.dumps(data, sort_keys=True, indent=2) + '\n')


def main():
    mode = sys.argv[1]
    assert mode in ('default', 'extra-watch')
    book = ROOT / mode; src = book / 'src'; src.mkdir(parents=True)
    inputs = book / 'canonical-input'; inputs.mkdir()
    config = '[book]\ntitle = "Bounded source reference probe"\nsrc = "src"\n[build]\ncreate-missing = false\n'
    if mode == 'extra-watch': config += 'extra-watch-dirs = ["canonical-input"]\n'
    (book / 'book.toml').write_text(config)
    (src / 'SUMMARY.md').write_text('# Summary\n\n- [Source references](index.md)\n')
    sources = ['docs/COMPOSITION_SCOPE.md', 'MEMORY.md', 'docs/audits/record-value-original-helper-join-20261005/scope.txt']
    selected = {}
    for source in sources:
        asset = src / ('references/' + source + '.source.txt'); asset.parent.mkdir(parents=True, exist_ok=True)
        relative = os.path.relpath(Path(source).resolve(), asset.parent.resolve()); asset.symlink_to(relative)
        raw = Path(source).read_bytes()
        selected[source] = {'asset': str(asset.relative_to(src)), 'link': relative, 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest(), 'text': raw.decode()}
    live_input = inputs / 'state.txt'; live_input.write_text('first canonical state\n')
    asset = src / 'references/state.source.txt'; asset.symlink_to(os.path.relpath(live_input.resolve(), asset.parent.resolve()))
    page = '# Source references\n\n' + ''.join('[' + p + '](' + row['asset'] + ')\n\n' for p, row in selected.items()) + '[Refresh control](references/state.source.txt)\n'
    (src / 'index.md').write_text(page)
    version = subprocess.run(['mdbook', '--version'], capture_output=True, text=True)
    build_command = ['mdbook', 'build', str(book)]
    build = subprocess.run(build_command, capture_output=True, text=True)
    record = {'mode': mode, 'version': {'status': version.returncode, 'stdout': version.stdout, 'stderr': version.stderr},
              'config': config, 'summary': (src / 'SUMMARY.md').read_text(), 'page': page, 'sources': selected,
              'build': {'command': build_command, 'status': build.returncode, 'stdout': build.stdout, 'stderr': build.stderr}, 'built_assets': {}}
    for source, row in selected.items():
        output = book / 'book' / row['asset']
        record['built_assets'][source] = {'exists': output.is_file(), 'text': output.read_text() if output.is_file() else None}
    with socket.socket() as reservation:
        reservation.bind(('127.0.0.1', 0)); port = reservation.getsockname()[1]
    command = ['mdbook', 'serve', str(book), '--hostname', '127.0.0.1', '--port', str(port)]
    log_path = book / 'server.log'; opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    def fetch(path):
        try: response = opener.open('http://127.0.0.1:' + str(port) + '/' + path, timeout=5)
        except urllib.error.HTTPError as error: response = error
        with response:
            return {'status': response.status, 'body': response.read().decode(), 'content_type': response.headers.get('Content-Type')}
    with log_path.open('wb') as log:
        server = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 30
            while True:
                assert server.poll() is None, 'native prototype server running'
                try: record['entry'] = fetch('index.html'); break
                except urllib.error.URLError:
                    assert time.monotonic() < deadline
                    time.sleep(0.1)
            record['served_assets'] = {source: fetch(row['asset']) for source, row in selected.items()}
            record['missing_control'] = fetch('references/genuine-missing.source.txt')
            record['refresh_before'] = fetch('references/state.source.txt')
            ready_deadline = time.monotonic() + 10
            while 'Watching for changes' not in log_path.read_text():
                assert server.poll() is None and time.monotonic() < ready_deadline
                time.sleep(0.1)
            time.sleep(2.5)
            record['ready_before_change'] = log_path.read_text()
            record['source_before_change'] = {'text': live_input.read_text(), 'mtime_ns': live_input.stat().st_mtime_ns}
            live_input.write_text('second canonical state\n')
            record['source_after_change'] = {'text': live_input.read_text(), 'mtime_ns': live_input.stat().st_mtime_ns}
            deadline = time.monotonic() + 12; refresh = []
            while True:
                result = fetch('references/state.source.txt'); refresh.append(result)
                if result['body'] == 'second canonical state\n' or time.monotonic() >= deadline: break
                time.sleep(0.25)
            record['refresh_after'] = result; record['refresh_observations'] = refresh
        finally:
            server.terminate()
            try: server.wait(timeout=5)
            except subprocess.TimeoutExpired: server.kill(); server.wait(timeout=5)
            record['server_status'] = server.returncode
    record['command'] = command; record['server_log'] = log_path.read_text()
    write(BASE / ('visible-' + mode + '-prototype.json'), record)
    assert server.poll() is not None
    import shutil
    assert book.parent == ROOT and book.name == mode
    shutil.rmtree(book)
    assert not book.exists()
    ROOT.rmdir()
    print(json.dumps({'mode': mode, 'build': build.returncode, 'source_assets': {p: r['status'] for p, r in record['served_assets'].items()}, 'refresh': record['refresh_after']['body'], 'missing': record['missing_control']['status']}, sort_keys=True))


if __name__ == '__main__':
    main()
