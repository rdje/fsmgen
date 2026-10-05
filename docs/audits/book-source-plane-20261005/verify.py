"""Authenticate the source-plane transition and scope current source admission."""
import argparse
import copy
import hashlib
import importlib.util
import json
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/book-source-plane-20261005')
SELECTION = Path('docs/audits/book-reference-selection-20261005')
TOPIC = 'docs/knowledge/mdbook-build-destination-locality.md'


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec); spec.loader.exec_module(result)
    return result


def exact(a,b):
    return json.dumps(a,sort_keys=True,allow_nan=False) == json.dumps(b,sort_keys=True,allow_nan=False)


def qualify_native(record, sources, routes):
    expected = {r['source']:r['asset'] for r in routes}
    assert exact(record['version']['status'],0) and record['version']['stdout'].strip() == 'mdbook v0.5.4'
    assert exact(record['build']['status'],0) and exact(record['entry']['status'],200)
    assert record['advertised_targets'] == expected and set(record['sources']) == set(expected), 'complete actual native advertised source population'
    assert set(record['served_assets']) == set(expected) and set(record['built_assets']) == set(expected)
    for source, body in sources.items():
        row = record['sources'][source]; raw = body.encode()
        assert row['asset'] == expected[source] and row['text'] == body
        assert exact(row['bytes'],len(raw)) and row['sha256'] == hashlib.sha256(raw).hexdigest()
        assert record['built_assets'][source] == {'exists':True,'text':body}
        served = record['served_assets'][source]
        assert exact(served['status'],200) and served['body'] == body and served['content_type'] == 'text/plain'
    assert exact(record['missing_control']['status'],404) and exact(record['server_status'],-15), 'genuine missing and consumed terminated server'
    assert 'Watching for changes' in record['ready_before_change']
    assert type(record['source_before_change']['mtime_ns']) is int and type(record['source_after_change']['mtime_ns']) is int
    assert record['source_after_change']['mtime_ns'] > record['source_before_change']['mtime_ns']
    assert record['refresh_before']['body'] == 'first canonical state\n' and record['refresh_after']['body'] == 'second canonical state\n', 'actual outside-book visible source refresh'
    assert exact(record['refresh_before']['status'],200) and exact(record['refresh_after']['status'],200)


def qualify_production(record, routes):
    sources={r['source'] for r in routes}
    assert set(record['source_boundary'])==set(record['source_assets'])==set(record['built_assets'])==sources, 'complete production canonical population'
    assert exact(record['build']['status'],0) and exact(record['reference_chapter']['status'],200)
    assert record['reference_chapter']['body']==record['built_reference_chapter'], 'complete production native reader parity'
    for source,body in record['source_boundary'].items():
        raw=body.encode();asset=record['source_assets'][source]
        assert exact(asset['status'],200) and asset['body']==body and record['built_assets'][source]==body, 'complete production native source bytes'
        assert exact(asset['bytes'],len(raw)) and asset['sha256']==hashlib.sha256(raw).hexdigest()
    assert exact(record['missing']['status'],404) and exact(record['server_status'],-15), 'production missing and consumed-server controls'
    expected=b'\n'.join(json.dumps(r,sort_keys=True,separators=(',',':')).encode() for r in routes)+b'\n'
    assert exact(record['manifest']['status'],200) and record['manifest']['body'].encode()==expected, 'complete production manifest'


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current',action='store_true'); args=parser.parse_args()
    plane=module('book_source_plane',Path('scripts/book_source_references.py')); routes=plane.expected_rows()
    boundary=json.loads((BASE/'source-boundary.json').read_text())
    for p,body in boundary['committed_sources'].items():
        assert subprocess.check_output(['git','show',boundary['revision']+':'+p]).decode() == body
    assert boundary['local_source_differences'] == [p for p in boundary['captured_sources'] if boundary['captured_sources'][p] != boundary['committed_sources'][p]]
    native=json.loads((BASE/'links-default-prototype.json').read_text()); qualify_native(native,boundary['captured_sources'],routes)
    controls=[]
    for name in ('lost-member','wrong-whole-source','wrong-advertised-target','Boolean-HTTP','float-source-bytes','unfinished-server','stale-refresh'):
        value=copy.deepcopy(native); source=routes[0]['source']
        if name=='lost-member': del value['served_assets'][source]
        elif name=='wrong-whole-source': value['served_assets'][source]['body']+='wrong source\n'
        elif name=='wrong-advertised-target': value['advertised_targets'][source]='reference-source/wrong.source.txt'
        elif name=='Boolean-HTTP': value['served_assets'][source]['status']=True
        elif name=='float-source-bytes': value['sources'][source]['bytes']=float(value['sources'][source]['bytes'])
        elif name=='unfinished-server': value['server_status']=None
        else: value['refresh_after']=value['refresh_before']
        try: qualify_native(value,boundary['captured_sources'],routes)
        except AssertionError as error: controls.append({'control':name,'refusal':str(error)})
        else: raise AssertionError('false-green native source plane: '+name)
    before=(BASE/'tooling-topic-before.txt').read_text(); after=(BASE/'tooling-topic-after.txt').read_text()
    metadata=module('book_source_metadata',Path('docs/audits/knowledge-card-rollover-20261005/verify.py'))
    old_meta,new_meta=metadata.metadata(before.encode()),metadata.metadata(after.encode())
    assert old_meta[0] == new_meta[0] and new_meta[1][:len(old_meta[1])] == old_meta[1], 'complete original tooling ID/questions preserved'
    assert before.split('\n---\n',1)[1] in after, 'whole original destination-locality meaning preserved'
    assert 'verify-book-output-locality.py && scripts/run_with_ram_guard.sh' in after, 'original locality replay remains required'
    authority=json.loads((BASE/'book-authority.json').read_text())
    blobs={p:subprocess.check_output(['git','show',authority['revision']+':'+p]) for p in authority['paths']}
    def metrics(values): return {'files':len(values),'lines_total':sum(v.count(b'\n') for v in values.values()),'bytes_total':sum(map(len,values.values()))}
    assert exact(metrics(blobs),authority['before'])
    chapter='docs/book/src/90-reference-map.md'
    assert blobs[chapter].decode() == (BASE/'chapter-before.txt').read_text()
    assert (BASE/'chapter-after.txt').read_text() == (BASE/'chapter-before.txt').read_text().replace('## What Still Lives Outside The Book\n',authority['block']+'## What Still Lives Outside The Book\n')
    blobs[chapter]=(BASE/'chapter-after.txt').read_bytes(); assert exact(metrics(blobs),authority['after'])
    assert exact(authority['delta'],{k:authority['after'][k]-authority['before'][k] for k in authority['before']})
    if args.current:
        assert Path(TOPIC).read_text() == after, 'whole current tooling role/question/source/reader contract'
        body=Path(chapter).read_text(); permanent=authority['block'].split('\nThe asset plane is available;',1)[0]
        assert body.count(permanent) == 1, 'unique current permanent raw source/build roles'
        plane.check(routes)
        actual={}
        for kind,options in (('direct',['--all','--no-cache']),('cached',['--all'])):
            r=subprocess.run(['knowledge-map/scripts/query_knowledge_map.sh',*options],capture_output=True,text=True)
            assert r.returncode == 0
            actual[kind]='\n'.join(sorted(row for row in r.stdout.splitlines() if old_meta[0] in row.split('\t')[1].split(',')))+'\n'
        expected=metadata.allocation({TOPIC:after.encode()})['rows']; assert actual['direct']==actual['cached']==expected
        version=subprocess.check_output(['mdbook','--version'],text=True); assert version.strip()=='mdbook v0.5.4'
        declaration=next(r for r in map(json.loads,Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()) if r.get('surface_id')=='book_source_manifest')
        budget={'files':1,'lines_each':plane.ROW_LIMIT,'bytes_each':plane.MANIFEST_BYTES,'line_bytes_each':plane.ROW_BYTES,'lines_total':plane.ROW_LIMIT,'bytes_total':plane.MANIFEST_BYTES}
        assert exact(declaration['health_targets'],budget) and exact(declaration['enforcement_ceilings'],budget)
        assert declaration['verifier']=='core:scripts/book_source_references.py' and declaration['targets']==[plane.MANIFEST]
    for command in ([sys.executable,'-B',str(SELECTION/'verify.py')],
                    [sys.executable,'-B','docs/audits/record-value-current-helper-reader-20261005/verify.py','--current']):
        r=subprocess.run(command,capture_output=True,text=True); assert r.returncode==0, r.stderr[-2000:]
    control_proof=json.loads((BASE/'plane-control-proofs.json').read_text())
    required={'lost-member','wrong-source-role','wrong-source','wrong-endpoint','extra-member','absolute-source','escaping-source','Boolean-source','colliding-address','foreign-repository-parent','symlink-output-parent-before-write','ignored-source','stale-native-copy'}
    assert {r['control'] for r in control_proof['controls']}==required
    if (BASE/'raw-line-proofs.json').exists():
        raw_lines=json.loads((BASE/'raw-line-proofs.json').read_text())['cases']
        assert exact(raw_lines['original-CR-split-false-green']['status'],1) and exact(raw_lines['bare-EOF-CR-overflow']['status'],1) and exact(raw_lines['invalid-UTF8']['status'],1)
        assert all(exact(raw_lines[name]['status'],0) for name in ('exact-EOF-boundary','exact-LF-boundary','exact-CRLF-boundary'))
    if (BASE/'portability-proofs.json').exists():
        portable=json.loads((BASE/'portability-proofs.json').read_text())
        assert portable['same_volume'] is True and exact(portable['before'],portable['after'])
    production_controls=[]
    if (BASE/'production-native.json').exists():
        production=json.loads((BASE/'production-native.json').read_text());qualify_production(production,routes)
        for name in ('lost-production-member','wrong-production-source','wrong-production-reader','Boolean-production-status','unfinished-production-server'):
            candidate=copy.deepcopy(production);source=routes[0]['source']
            if name=='lost-production-member':del candidate['source_assets'][source]
            elif name=='wrong-production-source':candidate['source_assets'][source]['body']+='wrong source\n'
            elif name=='wrong-production-reader':candidate['built_reference_chapter']+='stale reader\n'
            elif name=='Boolean-production-status':candidate['source_assets'][source]['status']=True
            else:candidate['server_status']=None
            try:qualify_production(candidate,routes)
            except AssertionError as error:production_controls.append({'control':name,'refusal':str(error)})
            else:raise AssertionError('false-green production native source: '+name)
    proof={'native_controls':controls,'current_scope':'Exact admitted selection/current endpoints/bytes/ignore policy and tooling question/reader role; historical build and aggregate evidence retain their capture boundary.'}
    target=BASE/'proofs.json'
    if target.exists(): assert exact(json.loads(target.read_text()),proof)
    else: target.write_text(json.dumps(proof,sort_keys=True,indent=2)+'\n')
    if production_controls:
        target=BASE/'production-proofs.json'
        if target.exists():assert exact(json.loads(target.read_text()),production_controls)
        else:target.write_text(json.dumps(production_controls,sort_keys=True,indent=2)+'\n')
    seal=BASE/'manifest.json'
    if seal.exists():
        for p,pin in json.loads(seal.read_text()).items():
            raw=Path(p).read_bytes(); assert exact(pin,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
        assert exact(json.loads((BASE/'final-plane-control-proofs.json').read_text())['controls'],control_proof['controls'])
        assert exact(json.loads((BASE/'final-raw-line-proofs.json').read_text())['cases'],json.loads((BASE/'raw-line-proofs.json').read_text())['cases'])
        index=json.loads((BASE/'index-proofs.json').read_text())
        assert set(index['actual_path_population'])=={plane.MANIFEST}|{'docs/book/src/'+r['asset'] for r in routes}
        assert {r['control'] for r in index['controls']}=={'missing-index-member','wrong-index-mode','wrong-index-endpoint','conflicted-index','wrong-index-producer'}
    print('PASS complete native source population/refresh, genuine plane/native controls, original locality meaning and scoped current source roles.')


if __name__=='__main__': main()
