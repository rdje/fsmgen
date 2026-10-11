"""Replay complete dated observer publication; current currency has its own route."""
import argparse
import gzip
import json
import sys
from html.parser import HTMLParser
from pathlib import Path
from common import BASE, REPAIR, REVISION, SCOPE, canonical, load, need, pin, save, same
import acceptance
import book_qualified as book
import model
import oracle

CARDS={
    'docs/knowledge/isf-record-output-source-contexts.md',
    'docs/knowledge/mdbook-build-destination-locality.md',
    'docs/knowledge/record-value-finite-copy-probe-reader.md',
    model.CARD,
}
SUCCESS='PASS complete dated observer publication and unchanged finite parent; whole canonical/probe/query/native/source/actual evidence and genuine controls qualify. Current currency requires the maintained reader; higher raw/native/private/visual scopes retain their owners.\n'


def compressed(name,value):
    path=BASE/name;need(not path.exists(),'retain complete first publication epoch: '+name)
    path.write_bytes(gzip.compress(canonical(value),mtime=0))


def unpack(name):
    return json.loads(gzip.decompress((BASE/name).read_bytes()))


def metrics(values):
    values=list(values)
    return dict(files=len(values),lines_total=sum(v.count(b'\n') for v in values),bytes_total=sum(map(len,values)),
        lines_each=max(v.count(b'\n') for v in values),bytes_each=max(map(len,values)),
        line_bytes_each=max(len(line.rstrip(b'\r')) for v in values for line in v.split(b'\n')))


def members():
    return {p.name:pin(p.read_bytes()) for p in sorted(BASE.iterdir()) if p.is_file() and p.name not in ('manifest.json','checks.json')}


def capture():
    sys.path.insert(0,'scripts')
    import check_record_value_publication as current
    canonical_sources=current.sources();prior=current.historical();record=current.current_input(prior,canonical_sources)
    current.check(record,canonical_sources,prior,current.authority(prior))
    compressed('current-canonical.json.gz',{p:raw.decode() for p,raw in canonical_sources.items()})
    compressed('current-input.json.gz',record)
    (BASE/'current-guide.md.txt').write_text(current.guide(prior))
    task=model.TASK.read_bytes();(BASE/'closed-task.md.gz').write_bytes(gzip.compress(task,mtime=0))
    for identifier in (model.OWNER,model.OWNER.rsplit('.',1)[0]):
        need('\n  Status: `done`\n' in model.block(task.decode(),identifier),'fully qualified finite observer nodes close before final capture')
    raw=Path('docs/book/book/13k-isf-feature-support-matrix.html').read_bytes()
    (BASE/'current-native.html.gz').write_bytes(gzip.compress(raw,mtime=0))
    copied=[]
    for row in current.plane.expected_rows():
        original=current.plane.source_bytes(row['source'])
        delivered=Path('docs/book/book',row['asset']).read_bytes()
        need(original==delivered,'whole fresh final native copied source')
        copied.append(dict(row=row,original=original.decode(),delivered=delivered.decode()))
    compressed('native-copies.json.gz',dict(rows=copied,
        manifest=Path('docs/book/src/reference-source/routes.jsonl').read_text(),
        delivered_manifest=Path('docs/book/book/reference-source/routes.jsonl').read_text()))
    paths=['scripts/check_record_value_publication.py','scripts/record_value_observer_fact.py',
           't/python/test_record_value_current_publication.py']
    save('current-programmes.json',{p:dict(identity=pin(Path(p).read_bytes()),body=Path(p).read_text()) for p in paths})
    need(canonical_sources==current.sources(),'whole canonical publication epoch conserved through capture')
    need(all(Path(r['row']['source']).read_text()==r['original'] for r in copied),'whole copied-source input epoch conserved through capture')
    print('PASS complete closed-task/current canonical/query/native/copy/programme epoch captured without native recapture.')


def current_snapshot():
    sources=unpack('current-canonical.json.gz');record=unpack('current-input.json.gz')
    before=json.loads(gzip.decompress((BASE/'before-canonical.json.gz').read_bytes()))
    proposed=dict(before);proposed[model.CARD]=(BASE/'published-card.md.txt').read_text()
    need(sources==proposed,'complete original/current canonical population and sole reviewed observer delta')
    need(type(record) is dict and set(record)=={'cards','chapter','tooling_chapter','queries','census','surface','source_members','source_budget'},'closed complete saved current publication')
    expected_cards={p:sources[p] for p in CARDS}
    need(record['cards']==expected_cards and all(sources[p]==oracle.git(p).decode() for p in CARDS-{model.CARD}),
         'whole unchanged predecessor cards and sole reviewed target')
    _,expected_book=book.source()
    need(record['chapter'].encode()==expected_book[str(book.CHAPTER)] and
         record['tooling_chapter'].encode()==expected_book['docs/book/src/90-reference-map.md'],'whole exact current source guide and every book peer')
    allocation=oracle.allocation(sources)
    need(type(record['queries']) is dict and set(record['queries'])=={'direct','cached'},'complete direct/cached actual roles')
    for role,actual in record['queries'].items():
        need(type(actual) is dict and set(actual)=={'command','status','stdout','stderr'} and
             type(actual['status']) is int and actual['status']==0,'closed typed actual full current query')
        command=['knowledge-map/scripts/query_knowledge_map.sh','--all']+(['--no-cache'] if role=='direct' else [])
        need(actual['command']==command and actual['stderr']=='' and actual['stdout']==allocation['rows'],'whole independent current global query allocation and ownership')
    need(record['source_members']=={p:pin(t.encode()) for p,t in sources.items()},'whole complete current canonical source identities')
    physical={p:t.encode() for p,t in sources.items() if Path(p).parent==Path('docs/knowledge')}
    need(record['census']==metrics(physical.values()),'complete independent physical card census')
    registry=[json.loads(line) for line in (BASE/'before-registry.jsonl.txt').read_bytes().splitlines()]
    need(record['surface']==next(r for r in registry if r.get('surface_id')=='knowledge_cards') and
         record['source_budget']==next(r for r in registry if r.get('surface_id')=='book_source_manifest'),
         'every whole Knowledge Map collection/source authority and ceiling unchanged')
    copies=unpack('native-copies.json.gz');declared=oracle.git('docs/book/src/reference-source/routes.jsonl').decode()
    need(copies['manifest']==copies['delivered_manifest']==declared,'complete original and delivered source-route manifest')
    rows=[json.loads(line) for line in declared.splitlines()]
    need([r['row'] for r in copies['rows']]==rows and all(r['original']==r['delivered'] for r in copies['rows']),
         'every whole original/native copied source and exact membership/order')
    for copied in copies['rows']:
        path=copied['row']['source']
        if path in sources:need(copied['original']==sources[path],'complete canonical fact/source copy binding')
    guide=(BASE/'current-guide.md.txt').read_text()
    need(record['chapter'].count(guide)==1 and guide.endswith((BASE/'guide.txt').read_text()),'whole exact native/current guide and unchanged scopes')
    class Visible(HTMLParser):
        def __init__(self):super().__init__();self.parts=[]
        def handle_data(self,text):self.parts.append(text)
    native=gzip.decompress((BASE/'current-native.html.gz').read_bytes()).decode();parser=Visible();parser.feed(native)
    expected=' '.join(guide.replace('```bash\n','').replace('```\n','').replace('`','').split())
    need(expected in ' '.join(''.join(parser.parts).split()),'whole final native rendered guide')
    programmes=load('current-programmes.json');integration=load('wrapper-integration.json')
    need(programmes['scripts/check_record_value_publication.py']['body']==integration['whole_after'] and
         pin(integration['whole_after'].encode())==integration['after'],'complete retained before/after maintained wrapper extension')
    for path,row in programmes.items():need(pin(row['body'].encode())==row['identity'],'whole saved production/test source epoch')
    template=(BASE/'observer_fact.py.txt').read_text().replace("'__ADMISSION__'",repr(pin((BASE/'admission-manifest.json').read_bytes())),1)
    generated=template.replace("'__GUIDE__'","'''"+(BASE/'guide.txt').read_text()+"'''",1)
    need(programmes['scripts/record_value_observer_fact.py']['body']==generated,'complete reviewed generated maintained observer helper')
    need(programmes['t/python/test_record_value_current_publication.py']['body']==(BASE/'focused-test-source.py.txt').read_text(),
         'complete saved focused test source and declared indirect epoch')
    return dict(canonical=pin((BASE/'current-canonical.json.gz').read_bytes()),record=pin((BASE/'current-input.json.gz').read_bytes()),
                allocation=pin(allocation['rows'].encode()),census=record['census'],scope=SCOPE)


def qualify():
    need(same(acceptance.derive(current=False),load('acceptance-proof.json')),'whole independently reconstructed unchanged finite parent acceptance')
    proposal=model.qualify(load('proposal.json'),(BASE/'before-card.md.txt').read_bytes(),
                           (BASE/'published-card.md.txt').read_bytes(),load('review.json'))
    admission=load('admission-manifest.json')
    need(all(pin((BASE/name).read_bytes())==expected for name,expected in admission.items()),'complete admitted preparation including retained first candidate programme')
    snapshot=current_snapshot()
    frozen=load('current-programmes.json')['scripts/record_value_observer_fact.py']['body']
    namespace={'__name__':'sealed_observer_authentication','__file__':'scripts/record_value_observer_fact.py'}
    sys.path.insert(0,'scripts')
    exec(compile(frozen,'scripts/record_value_observer_fact.py','exec'),namespace)
    original_custody=namespace['authenticate']()
    checks=load('checks.json')
    for role in ('current-publication-final','native-sources-final','source-index-final'):
        actual=checks[role];previous=checks[role.removesuffix('-final')]
        need(type(actual['status']) is int and actual['status']==0 and actual['command']==previous['command'] and
             actual['stdout']==previous['stdout'] and actual['stderr']==previous['stderr'],'complete final actual current/native/source result')
        expected=load('current-programmes.json')
        need(all(actual['inputs'][p]==row['identity'] for p,row in expected.items()),'whole final actual direct and indirect programme epoch')
    task=gzip.decompress((BASE/'closed-task.md.gz').read_bytes()).decode()
    need(same(model.contracts(current=task),load('contracts.json')),'whole final closed task and every original contract')
    for identifier in (model.OWNER,model.OWNER.rsplit('.',1)[0]):
        need('\n  Status: `done`\n' in model.block(task,identifier),'only fully qualified observer nodes close')
    return dict(acceptance=pin((BASE/'acceptance-proof.json').read_bytes()),proposal=proposal,current=snapshot,original_custody=original_custody,
        final_checks={k:pin(canonical(checks[k])) for k in ('current-publication-final','native-sources-final','source-index-final')},
        scope=SCOPE,legs=load('acceptance-proof.json')['legs'])


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--capture',action='store_true');parser.add_argument('--seal',action='store_true');args=parser.parse_args()
    need(not(args.capture and args.seal),'distinct capture and immutable reader roles')
    if args.capture:capture();return
    if args.seal:
        need(not (BASE/'manifest.json').exists(),'first final observer publication seal')
        save('proof.json',qualify());save('manifest.json',members())
    else:
        need(load('manifest.json')==members(),'whole immutable final observer publication namespace')
        need(same(load('proof.json'),qualify()),'whole independently rederived saved observer publication proof')
    print(SUCCESS,end='')


if __name__=='__main__':main()
