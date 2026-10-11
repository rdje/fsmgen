"""Replay strict namespace repair and complete unchanged observer publication."""
import argparse
import gzip
import json
import subprocess
import sys
import tarfile
import tempfile
from html.parser import HTMLParser
from pathlib import Path
import guard
import oracle
import book

BASE=Path('docs/audits/observer-publication-namespace-repair-20261011')
WORK=Path('.artifacts/observer-publication-namespace-repair-20261011')
SUCCESS='PASS complete strict original/current namespace repair, unchanged observer semantics and current/native/source epoch; all genuine whole graph and actual-result controls qualify. Higher raw/native/private/visual scopes retain their owners.\n'


def save(name,value):
    path=BASE/name;guard.require(not path.exists(),'retain complete first repair publication product')
    path.write_bytes(guard.encoded(value))


def read(name):return json.loads((BASE/name).read_bytes())


def unpack(path):return json.loads(gzip.decompress(path.read_bytes()))


def actual_original():
    expected=read('fresh-original-reader.json');command=['python3','-B',str(guard.ORIGINAL/'verify.py')]
    result=subprocess.run(command,capture_output=True,text=True)
    actual=dict(command=command,status=result.returncode,stdout=result.stdout,stderr=result.stderr)
    guard.require(type(result.returncode) is int and result.returncode==0 and actual==expected,'fresh complete unchanged original semantic reader')
    return actual


def controls():
    declared=guard.declaration();results=[];WORK.mkdir(parents=True,exist_ok=True)
    for row in read('controls.json'):
        if row['name']=='boolean-size':
            try:guard.check_tree(guard.ORIGINAL,row['whole_declaration'])
            except ValueError as error:guard.require(str(error)==row['cause'],'exact Boolean declaration refusal')
            else:raise ValueError('accepted Boolean namespace declaration')
            results.append(row);continue
        path=Path(row['complete_candidate'])
        guard.require(guard.identity(path.read_bytes())==row['identity'],'whole retained hostile candidate')
        with tempfile.TemporaryDirectory(dir=WORK) as temporary:
            root=Path(temporary)
            with tarfile.open(path,'r:gz') as archive:archive.extractall(root,filter='data')
            for reader,expected in zip((guard.check_tree,oracle.reconstruct),row['outcomes']):
                try:reader(root,declared)
                except ValueError as error:
                    guard.require(expected==dict(reader=reader.__module__+'.'+reader.__name__,status='rejected',cause=str(error)),
                                  'whole independent actual intended candidate refusal')
                else:raise ValueError('accepted hostile whole original namespace')
        results.append(row)
    with tempfile.TemporaryDirectory(dir=WORK) as temporary:
        root=Path(temporary)
        with tarfile.open(BASE/'first-sealed.tar.gz','r:gz') as archive:archive.extractall(root,filter='data')
        guard.check_tree(root,declared)
        guard.require(oracle.reconstruct(root,declared)==declared,'whole first sealed epoch retained unchanged')
    return results


def capture():
    sys.path.insert(0,'scripts');import check_record_value_publication as current
    sources=current.sources();prior=current.historical();record=current.current_input(prior,sources)
    current.check(record,sources,prior,current.authority(prior))
    copies=[]
    for row in current.plane.expected_rows():
        source=current.plane.source_bytes(row['source']);native=Path('docs/book/book',row['asset']).read_bytes()
        guard.require(source==native,'whole final current native copy')
        copies.append(dict(row=row,source=source.decode(),native=native.decode()))
    paths=['scripts/check_record_value_publication.py','scripts/record_value_observer_fact.py',
           'scripts/record_value_observer_namespace_fact.py','t/python/test_record_value_current_publication.py']
    snapshot=dict(canonical={p:r.decode() for p,r in sources.items()},record=record,copies=copies,
        guide=current.guide(prior),native_html=Path('docs/book/book/13k-isf-feature-support-matrix.html').read_text(),
        programmes={p:dict(identity=guard.identity(Path(p).read_bytes()),body=Path(p).read_text()) for p in paths},
        source_manifest=Path('docs/book/src/reference-source/routes.jsonl').read_text(),
        native_manifest=Path('docs/book/book/reference-source/routes.jsonl').read_text())
    path=BASE/'current-epoch.json.gz';guard.require(not path.exists(),'retain complete final repair epoch')
    path.write_bytes(gzip.compress(guard.encoded(snapshot),mtime=0))
    guard.require(sources==current.sources() and all(Path(r['row']['source']).read_text()==r['source'] for r in copies),
                  'complete canonical/native-source epoch conserved during capture')
    print('PASS complete final repair canonical/query/native/copy/programme epoch captured.')


def current_epoch():
    snapshot=unpack(BASE/'current-epoch.json.gz');old_sources=unpack(guard.ORIGINAL/'current-canonical.json.gz')
    old_record=unpack(guard.ORIGINAL/'current-input.json.gz');expected=dict(old_record)
    expected['chapter']=book.source()[1][str(book.CHAPTER)].decode()
    guard.require(snapshot['canonical']==old_sources and guard.encoded(snapshot['record'])==guard.encoded(expected),
                  'whole original/current canonical meanings/questions/capacity and exact repaired guide')
    for actual in snapshot['record']['queries'].values():
        guard.require(type(actual['status']) is int and actual['status']==0,'complete typed current query success')
    declared=(guard.ORIGINAL/'native-copies.json.gz')
    old_copies=unpack(declared)
    guard.require(snapshot['source_manifest']==snapshot['native_manifest']==old_copies['manifest'],
                  'whole unchanged source route authority and native delivery')
    rows=[json.loads(line) for line in snapshot['source_manifest'].splitlines()]
    guard.require([r['row'] for r in snapshot['copies']]==rows and all(r['source']==r['native'] for r in snapshot['copies']),
                  'complete whole current native copy graph and every original byte')
    for row in snapshot['copies']:
        if row['row']['source'] in old_sources:
            guard.require(row['source']==old_sources[row['row']['source']],'complete canonical fact and native copy binding')
    guard.require(snapshot['record']['chapter'].count(snapshot['guide'])==1 and snapshot['guide'].endswith((BASE/'guide.txt').read_text()),
                  'whole repaired current guidance and every unchanged scope')
    class Visible(HTMLParser):
        def __init__(self):super().__init__();self.parts=[]
        def handle_data(self,text):self.parts.append(text)
    parser=Visible();parser.feed(snapshot['native_html'])
    guide=snapshot['guide'].replace('```bash\n','').replace('```\n','').replace('`','')
    guard.require(' '.join(guide.split()) in ' '.join(''.join(parser.parts).split()),'complete final native repaired guidance')
    integration=read('integration.json');programmes=snapshot['programmes']
    guard.require(programmes['scripts/check_record_value_publication.py']['body']==integration['whole_after'] and
                  programmes['scripts/record_value_observer_namespace_fact.py']['body']==integration['helper'],
                  'whole exact maintained wrapper and strict helper integration')
    for row in programmes.values():guard.require(guard.identity(row['body'].encode())==row['identity'],'complete saved programme source epoch')
    return guard.identity((BASE/'current-epoch.json.gz').read_bytes())


def qualify(current=False):
    declared=guard.authenticate_original()
    guard.require(oracle.reconstruct(guard.ORIGINAL,declared)==declared,'independent full original namespace graph and bytes')
    semantic=read('semantic-proof.json')
    guard.require(semantic['whole_original']==declared and semantic['original_manifest']==guard.MANIFEST_IDENTITY,
                  'fixed complete original namespace and first proof authority')
    preparation=read('preparation-manifest.json')
    guard.require(all(guard.identity((BASE/name).read_bytes())==expected for name,expected in preparation.items()),
                  'every complete admitted preparation byte retained')
    exercised=controls();guard.require(guard.identity(guard.encoded(exercised))==semantic['controls'],'complete reexecuted independent whole controls')
    actual=actual_original()
    result=dict(original=declared,first_false_green=semantic['actual_false_green'],controls=semantic['controls'],
        fresh_original=actual,scope=(BASE/'scope.txt').read_text(),legs=semantic['legs'])
    if current:
        checks=read('checks.json')
        for name in ('current-publication','native-sources','source-index'):
            row=checks[name];old=json.loads((guard.ORIGINAL/'checks.json').read_bytes())[name]
            guard.require(type(row['status']) is int and row['status']==0 and row['command']==old['command'] and
                          row['stdout']==old['stdout'] and row['stderr']==old['stderr'],'complete final current/native/source actual result')
            guard.require(all(row['inputs'][p]==v['identity'] for p,v in unpack(BASE/'current-epoch.json.gz')['programmes'].items()),
                          'complete final declared direct and indirect source epoch')
        result['current']=current_epoch()
        result['actuals']={name:guard.identity(guard.encoded(checks[name])) for name in ('current-publication','native-sources','source-index')}
    return result


def members():
    result={}
    for path in BASE.rglob('*'):
        guard.require(not path.is_symlink() and path.is_file(),'declared repair namespace graph; no unexpected directories or symlinks')
        if path.name not in ('manifest.json','checks.json'):result[str(path.relative_to(BASE))]=guard.identity(path.read_bytes())
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--capture',action='store_true');parser.add_argument('--preflight',action='store_true');parser.add_argument('--seal',action='store_true');args=parser.parse_args()
    guard.require(sum((args.capture,args.preflight,args.seal))<=1,'distinct repair verification roles')
    if args.capture:capture();return
    if args.preflight:qualify();print('PASS complete strict namespace repair and unchanged observer acceptance before node closure.');return
    if args.seal:
        guard.require(not (BASE/'manifest.json').exists(),'first strict repair publication seal')
        save('proof.json',qualify(current=True));save('manifest.json',members())
    else:
        declared=read('manifest.json');declared['manifest.json']=guard.identity((BASE/'manifest.json').read_bytes());declared['checks.json']=None
        guard.check_tree(BASE,declared)
        guard.require(guard.encoded(qualify(current=True))==guard.encoded(read('proof.json')),'whole independently rederived complete repair publication')
    print(SUCCESS,end='')


if __name__=='__main__':main()
