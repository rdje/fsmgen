"""Capture complete native production assets without closing pending book clicks."""
import hashlib
import importlib.util
import json
import socket
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE=Path('docs/audits/book-source-plane-20261005')
WORK=Path('.artifacts/book-source-plane/production-native')


def main():
    spec=importlib.util.spec_from_file_location('production_source_plane','scripts/book_source_references.py')
    plane=importlib.util.module_from_spec(spec);spec.loader.exec_module(plane)
    rows=plane.expected_rows();plane.check(rows)
    assert not WORK.exists();WORK.mkdir(parents=True)
    root=Path.cwd().resolve();destination=(WORK/'book').resolve()
    assert destination.is_relative_to(root) and destination.parent.stat().st_dev==root.stat().st_dev
    sources={r['source']:Path(r['source']).read_text() for r in rows}
    build_command=['mdbook','build','docs/book','--dest-dir',str(destination)]
    build=subprocess.run(build_command,capture_output=True,text=True)
    record={'source_boundary':sources,'build':{'command':[str(WORK/'book') if p==str(destination) else p for p in build_command], 'status':build.returncode,'stdout':build.stdout,'stderr':build.stderr}}
    plane.check(rows,str(destination.relative_to(root)))
    with socket.socket() as reservation:
        reservation.bind(('127.0.0.1',0));port=reservation.getsockname()[1]
    command=['mdbook','serve','docs/book','--dest-dir',str(destination),'--hostname','127.0.0.1','--port',str(port)]
    opener=urllib.request.build_opener(urllib.request.ProxyHandler({}))
    def fetch(path):
        try:response=opener.open('http://127.0.0.1:'+str(port)+'/'+path,timeout=5)
        except urllib.error.HTTPError as error:response=error
        with response:
            raw=response.read();return {'status':response.status,'body':raw.decode(),'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'content_type':response.headers.get('Content-Type')}
    log_path=WORK/'server.log'
    with log_path.open('wb') as log:
        server=subprocess.Popen(command,stdout=log,stderr=subprocess.STDOUT)
        try:
            deadline=time.monotonic()+30
            while True:
                assert server.poll() is None
                try:record['reference_chapter']=fetch('90-reference-map.html');break
                except urllib.error.URLError:
                    assert time.monotonic()<deadline;time.sleep(0.1)
            record['source_assets']={r['source']:fetch(r['asset']) for r in rows}
            record['manifest']=fetch('reference-source/routes.jsonl')
            record['missing']=fetch('reference-source/genuine-missing.source.txt')
        finally:
            server.terminate()
            try:server.wait(timeout=5)
            except subprocess.TimeoutExpired:server.kill();server.wait(timeout=5)
    record['server_status']=server.returncode;record['server_log']=log_path.read_text()
    record['command']=[str(WORK/'book') if p==str(destination) else p for p in command]
    record['built_assets']={r['source']:(destination/r['asset']).read_text() for r in rows}
    record['built_reference_chapter']=(destination/'90-reference-map.html').read_text()
    target=BASE/'production-native.json';assert not target.exists()
    target.write_text(json.dumps(record,sort_keys=True,indent=2)+'\n')
    assert build.returncode==0 and record['reference_chapter']['status']==200 and record['missing']['status']==404 and server.poll() is not None
    assert all(record['source_assets'][p]['status']==200 and record['source_assets'][p]['body']==body and record['built_assets'][p]==body for p,body in sources.items())
    assert all(Path(p).read_text()==body for p,body in sources.items()), 'source boundary stable through capture'
    print('PASS complete production native source assets match current canonical bytes; missing404, consumed server and pending click-publication boundary retained.')


if __name__=='__main__':main()
