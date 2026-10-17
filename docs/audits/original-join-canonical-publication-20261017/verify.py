"""Verify exact current admission and recover a sealed publication without replay promotion."""
import argparse
import base64
import contextlib
import gzip
import hashlib
import importlib.abc
import importlib.util
import io
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == ROOT, 'invoke from the programme-derived repository root'
from run import COMMANDS,project_modules

BASE = Path('docs/audits/original-join-canonical-publication-20261017')
PLAN = json.loads((BASE/'plan.json').read_bytes())
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
SUCCESS = 'PASS complete non-growing original join canonical publication; original parent and full-alias acceptance remain separate.\n'


def encoded(value):
    return (json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=True,allow_nan=False)+'\n').encode()


def identity(body):
    return dict(bytes=len(body),sha256=hashlib.sha256(body).hexdigest())


def load(name):
    body = (BASE/name).read_bytes()
    raw=gzip.decompress(body) if name.endswith('.gz') else body
    value=json.loads(raw)
    if name.endswith(('proof.json.gz','manifest.json.gz')):
        assert raw==encoded(value), 'canonical complete saved proof or manifest'
    return value


def fixed(names):
    names = sorted(names)
    command = ['git', '--no-replace-objects', 'cat-file', '--batch']
    request = ''.join(PLAN['revision']+':'+name+'\n' for name in names).encode()
    result = subprocess.run(command, input=request, capture_output=True)
    assert result.returncode == 0 and not result.stderr
    stream, bodies = io.BytesIO(result.stdout), {}
    for name in names:
        header=stream.readline().split()
        assert len(header)==3 and header[1]==b'blob'
        body=stream.read(int(header[2]));assert stream.read(1)==b'\n'
        assert len(body)==int(header[2]);bodies[name]=body
    assert not stream.read(1)
    return bodies


def nodes(body):
    starts=list(re.finditer(rb'^- ID: `([^`]+)`\n', body, re.M))
    result={row[1].decode():body[row.start():starts[i+1].start() if i+1<len(starts) else len(body)]
            for i,row in enumerate(starts)}
    assert len(result)==len(starts)
    return result


def field(block,name):
    match=re.search(rb'^  '+name.encode()+rb': `(.*)`$',block,re.M)
    return match[1].decode() if match else None


def contracts(task_body=None):
    original=nodes(fixed([TASK])[TASK]);current=nodes(Path(TASK).read_bytes() if task_body is None else task_body)
    assert current.keys()==original.keys()
    for name,block in original.items():
        if name==PLAN['owner']:
            assert all(field(block,key)==field(current[name],key) for key in ('Goal','Acceptance'))
            assert field(current[name],'Status') in ('active','done')
        else:
            assert block==current[name], 'unrelated original task block changed: '+name
    assert all(field(current[PLAN[key]],'Status')=='active' for key in ('family','join','parent'))
    assert field(current[PLAN['acceptance']],'Status')==field(current[PLAN['full_alias']],'Status')=='pending'
    return {name:block.decode() for name,block in original.items()
            if name==PLAN['family'] or name.startswith(PLAN['family']+'.') or name==PLAN['full_alias']}


def gate(label,expected):
    row=load(label+'-actual.json.gz')
    started=load(label+'-started.json.gz')
    assert set(row)==set(started)|{'status','sources_after','source_conserved','git_after','git_conserved',
        'raw_index_conserved','git_entries_and_revision_conserved','git_comparison_mode','streams'}
    assert all(row[key]==value for key,value in started.items())
    assert row['command']==['scripts/run_with_ram_guard.sh','--',*COMMANDS[label]]
    assert type(row['status']) is int and row['status']==expected
    assert type(row['expected_status']) is int and row['expected_status']==expected
    assert all(type(row[key]) is bool and row[key] for key in (
        'source_conserved','git_conserved','git_entries_and_revision_conserved'))
    assert row['sources_before']==row['sources_after']
    ref=row['sources_before'];body=Path(ref['path']).read_bytes()
    assert hashlib.sha256(body).hexdigest()==ref['sha256']
    sources=json.loads(gzip.decompress(body));assert type(ref['files']) is int and len(sources)==ref['files']
    for name,entry in sources.items():
        raw=base64.b64decode(entry['body_base64']);assert len(raw)==entry['bytes']
        assert hashlib.sha256(raw).hexdigest()==entry['sha256']
    for stream in row['streams'].values():
        raw=base64.b64decode(stream['body_base64']);assert len(raw)==stream['bytes']
        assert hashlib.sha256(raw).hexdigest()==stream['sha256']
    return dict(native_status=row['status'],record=identity((BASE/(label+'-actual.json.gz')).read_bytes()),
                source=ref,command=row['command'])


def core(*, factory=None, snapshot=None, aliases=None, record=None):
    if factory is None:
        sys.path.insert(0,'scripts')
        import check_record_value_publication as factory
    public=factory
    fact=public.original_join_fact
    declaration=load('module-closure-v2.json')
    assert encoded(project_modules(snapshot,declaration))==encoded(declaration)
    candidate=fact.admission();admitted=fact.authenticate()
    canonical=public.sources() if snapshot is None else {
        name:body for name,body in snapshot.items()
        if name.startswith(('docs/knowledge/','docs/decisions/')) and name.endswith('.md')}
    original=fixed(canonical)
    assert canonical.keys()==original.keys()
    assert canonical[fact.CARD]==fact.published(candidate).encode()
    assert all(body==original[name] for name,body in canonical.items() if name!=fact.CARD)
    legacy=json.loads((fact.PREPARATION/'integration-contract.json').read_bytes())['retained_dependencies']
    legacy_bodies=fixed(legacy)
    assert all(identity(body)==legacy[name] and (Path(name).read_bytes() if snapshot is None else snapshot[name])==body
               for name,body in legacy_bodies.items())
    review=load('publication-review.json.gz')
    assert base64.b64decode(review['before']['body_base64'])==original[fact.CARD]
    assert base64.b64decode(review['after']['body_base64'])==canonical[fact.CARD]
    book=review['book'];book_before=base64.b64decode(review['book_before']['body_base64'])
    book_after=base64.b64decode(review['book_after']['body_base64'])
    assert fixed([book])[book]==book_before and (Path(book).read_bytes() if snapshot is None else snapshot[book])==book_after
    assert book_before.count(review['guide_before'].encode())==1
    assert book_before.replace(review['guide_before'].encode(),fact.GUIDE.encode())==book_after
    assert len(book_after)<=len(book_before)
    prior=public.historical()
    record=public.current_input(prior,canonical) if record is None else record
    public.check(record,canonical,prior,public.authority(prior))
    assert all(value['status']==0 for value in record['queries'].values())
    assert record['queries']['direct']['stdout']==record['queries']['cached']['stdout']
    if snapshot is None:
        assert public.sources()==canonical
    else:
        output='.artifacts/original-join-canonical-publication-20261017/book/'
        public.check_native(snapshot[output+'13k-isf-feature-support-matrix.html'].decode(),prior)
        public.check_tooling_native(snapshot[output+'90-reference-map.html'].decode(),prior)
        rows=public.plane.expected_rows()
        assert snapshot[public.plane.MANIFEST]==public.plane.encode(rows)
        assert snapshot[output+'reference-source/routes.jsonl']==snapshot[public.plane.MANIFEST]
        expected_aliases={}
        for row,asset,target in public.plane.endpoints(rows):
            name=str(asset.relative_to(ROOT));expected_aliases[name]=target
            assert snapshot[name]==snapshot[row['source']]
        assert aliases==expected_aliases
        for row in rows:
            assert snapshot[output+row['asset']]==snapshot[row['source']]
    return dict(owner=PLAN['owner'],revision=PLAN['revision'],preparation_revision=PLAN['preparation_revision'],
                module_closure=declaration,first_seal=first_catalogue(),
                admission=admitted,contracts=contracts(None if snapshot is None else snapshot[TASK]),canonical={name:identity(body) for name,body in canonical.items()},
                current=record,book=identity(book_after),legacy_helpers={name:identity(body) for name,body in legacy_bodies.items()},
                gates={label:gate(label,status) for label,status in [('before-corrected',1),('focused',0),('history',0)]},
                scope=PLAN['condition'],legs=dict(rederive='Exact committed proposal, independent retained paragraph review and complete predecessor/current canonical, parent-contract, route and capacity correspondence.',
                falsify='Genuine predecessor native refusal; changed borrowed, omitted, malformed-kind, scope/capacity and native-promotion candidates reach intended independent test refusals. First setup failures remain failed with explicit custody gaps.',
                durability='Whole fixed preparation namespace/source/native/control/failure/repair authentication, permanent publication tests, complete source/native receipt epochs and saved current publication recovery. No fresh original execution or parent closure.'))


def save(name,data):
    with (BASE/name).open('xb') as stream:
        stream.write(gzip.compress(encoded(data),mtime=0))


def snapshot():
    ref=load('native-v2-actual.json.gz')['sources_before']
    body=Path(ref['path']).read_bytes()
    assert hashlib.sha256(body).hexdigest()==ref['sha256']
    entries=json.loads(gzip.decompress(body))
    assert type(ref['files']) is int and len(entries)==ref['files']
    bodies,aliases={},{}
    for name,entry in entries.items():
        raw=base64.b64decode(entry['body_base64'])
        assert encoded(identity(raw))==encoded({key:entry[key] for key in ('bytes','sha256')})
        bodies[name]=raw
        if 'symlink_target' in entry:
            aliases[name]=entry['symlink_target']
    return bodies,aliases


@contextlib.contextmanager
def frozen_factory(bodies):
    """Load only captured project modules and read their captured current inputs."""
    declaration=json.loads(bodies[str(BASE/'module-closure-v2.json')])
    assert encoded(project_modules(bodies,declaration))==encoded(declaration)
    programmes={Path(name).stem:(name,bodies[name]) for name in declaration['modules']}
    known={Path(name).stem for name in declaration['available_modules']}
    class Loader(importlib.abc.MetaPathFinder,importlib.abc.Loader):
        def find_spec(self,fullname,path=None,target=None):
            if fullname in programmes:
                return importlib.util.spec_from_loader(fullname,self)
            if fullname in known:
                raise ModuleNotFoundError('uncaptured project module: '+fullname)
            return None
        def create_module(self,spec):
            return None
        def exec_module(self,module):
            name,body=programmes[module.__name__]
            module.__file__=name
            exec(compile(body,name,'exec'),module.__dict__)
    previous={name:sys.modules[name] for name in known if name in sys.modules}
    finder=Loader()
    try:
        for name in known:
            sys.modules.pop(name,None)
        sys.meta_path.insert(0,finder)
        factory=__import__('check_record_value_publication')
        original_read=factory.plane.local_read
        def read(path,maximum):
            relative=str(path.relative_to(ROOT))
            if relative in bodies:
                raw=bodies[relative]
                assert len(raw)<=maximum
                return raw
            return original_read(path,maximum)
        factory.plane.local_read=read
        yield factory
    finally:
        sys.meta_path.remove(finder)
        for name in known:
            sys.modules.pop(name,None)
        sys.modules.update(previous)


EXCLUDED={'v2-manifest.json.gz'}|{label+suffix for label in ('seal-v2','saved-v2','recovery-controls-v2')
    for suffix in ('-started.json.gz','-actual.json.gz')}


def catalogue():
    result={}
    for path in sorted(BASE.iterdir()):
        assert path.is_file() and not path.is_symlink() and path.stat().st_dev==ROOT.stat().st_dev
        if path.name not in EXCLUDED:
            result[path.name]=dict(identity(path.read_bytes()),mode=path.stat().st_mode&0o777)
    return result


def first_catalogue():
    original=load('manifest.json.gz');overlays={name:'retained-v1-'+name+'.txt' for name in ('run.py','verify.py')}
    for name,entry in original.items():
        path=BASE/overlays.get(name,name)
        assert encoded(dict(identity(path.read_bytes()),mode=path.stat().st_mode&0o777))==encoded(entry)
    failed={}
    for label in ('saved','recovery-controls'):
        row=load(label+'-actual.json.gz')
        assert type(row['status']) is int and row['status']==1 and row['expected_status']==0
        assert row['source_conserved'] and row['git_conserved']
        assert b"No module named 'decision_catalog'" in base64.b64decode(row['streams']['stderr']['body_base64'])
        failed[label]=identity((BASE/(label+'-actual.json.gz')).read_bytes())
    return dict(manifest=identity((BASE/'manifest.json.gz').read_bytes()),proof=identity((BASE/'proof.json.gz').read_bytes()),
                overlays=overlays,failed_recovery=failed,
                boundary='Exact first sealed logical namespace reconstructed with two retained programme overlays. First seal0 and recovery1/control1 remain distinct; decision_catalog had no measured first native source before-image. The v2 closure is fresh evidence.')


def delivery(result):
    result['delivery']={label:gate(label,0) for label in (
        'admission-v2','book-v2','native-v2','inventory-v2','staged-v2')}
    return result


def recover(proof,bodies,aliases):
    with frozen_factory(bodies) as factory:
        result=delivery(core(factory=factory,snapshot=bodies,aliases=aliases,record=proof['current']))
    assert encoded(result)==encoded(proof), 'whole frozen original-join publication recovery'
    return result


def recovery_controls(proof,bodies,aliases):
    from unittest import mock
    import copy
    task=bodies[TASK];key=PLAN['acceptance'];start=task.index(('- ID: `'+key+'`').encode())
    end=task.find(b'\n- ID:',start+1);end=len(task) if end<0 else end
    block=task[start:end]
    assert b'  Status: `pending`' in block
    future=task[:start]+block.replace(b'  Status: `pending`',b'  Status: `active`',1)+task[end:]
    read=Path.read_bytes
    with mock.patch.object(Path,'read_bytes',lambda path:future if path==Path(TASK) else read(path)):
        recover(proof,bodies,aliases)
    changed=dict(bodies);changed[TASK]=future
    try:
        recover(proof,changed,aliases)
    except AssertionError as error:
        assert 'unrelated original task block changed' in str(error)
    else:
        raise AssertionError('borrowed saved task status accepted')
    changed=copy.deepcopy(proof);changed['current']['queries']['direct']['status']=False
    try:
        recover(changed,bodies,aliases)
    except ValueError as error:
        assert str(error)=='actual current query integer success'
    else:
        raise AssertionError('false saved native-query kind accepted')
    changed=dict(bodies);name='docs/knowledge/record-value-finite-copy-probe-reader.md'
    changed[name]=changed[name].replace(b'never passed flags',b'passed flags supply truth')
    assert changed[name]!=bodies[name]
    try:
        recover(proof,changed,aliases)
    except AssertionError:
        pass
    else:
        raise AssertionError('promoted saved canonical meaning accepted')
    changed=dict(bodies);name=str(BASE/'module-closure-v2.json')
    declaration=json.loads(changed[name]);first=next(iter(declaration['modules'].values()))
    first['bytes']=float(first['bytes']);changed[name]=encoded(declaration)
    try:
        recover(proof,changed,aliases)
    except AssertionError:
        pass
    else:
        raise AssertionError('false saved module identity kind accepted')
    changed=dict(bodies);declaration=json.loads(changed[name])
    declaration['modules'].pop('scripts/decision_catalog.py')
    declaration['edges'].pop('scripts/decision_catalog.py')
    changed[name]=encoded(declaration)
    try:
        recover(proof,changed,aliases)
    except AssertionError:
        pass
    else:
        raise AssertionError('omitted saved project dependency accepted')
    print('PASS frozen recovery tolerates later live task progress and refuses borrowed saved status, omitted dependencies, false module/query kinds and promoted meanings.')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    roles=parser.add_mutually_exclusive_group()
    roles.add_argument('--core',action='store_true')
    roles.add_argument('--seal',action='store_true')
    roles.add_argument('--current',action='store_true')
    roles.add_argument('--recovery-controls',action='store_true')
    args=parser.parse_args()
    if args.core:
        core()
        print('PASS exact current original-join canonical admission; delivery remains separately required.')
    elif args.seal:
        save('v2-proof.json.gz',delivery(core()))
        save('v2-manifest.json.gz',catalogue())
        print(SUCCESS,end='')
    else:
        assert encoded(load('v2-manifest.json.gz'))==encoded(catalogue()), 'whole frozen publication catalogue'
        proof=load('v2-proof.json.gz');bodies,aliases=snapshot()
        if args.recovery_controls:
            recovery_controls(proof,bodies,aliases)
        elif args.current:
            assert encoded(delivery(core()))==encoded(proof)
            print(SUCCESS,end='')
        else:
            recover(proof,bodies,aliases)
            print(SUCCESS,end='')
