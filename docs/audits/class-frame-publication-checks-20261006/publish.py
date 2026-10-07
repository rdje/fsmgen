"""Publish the whole admitted fact/route/guide unit, restoring every byte on failure."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-20261006')
CHECKS = Path('docs/audits/class-frame-publication-checks-20261006')
ns = {'__name__':'atomic_class_frame_publication','__file__':str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(),str(BASE / 'verify.py'),'exec'),ns)
require,same,identity,load = (ns[k] for k in ('require','same','identity','load'))
require(not (BASE / 'publication.json').exists() and not (BASE / 'manifest.json').exists(),'atomic publication cannot overwrite evidence')
source = ns['source_model'](); require(same(source,load(BASE / 'source-model.json')),'whole admitted publication source before live mutation')
for name in ('preparation.json','fresh-replay.json'):
    actual = load(CHECKS / name); require(type(actual['status']) is int and actual['status'] == 0,'complete actual prerequisites before atomic publication')
original = ns['sources']()
require(ns['public']['cards']() == {p:r for p,r in original.items() if Path(p).parent == Path('docs/knowledge')},'complete original physical epoch before publication')
chapter,registry = ns['CHAPTER'],ns['REGISTRY']
paths = subprocess.check_output(['git','ls-tree','-r','--name-only',ns['REVISION'],'docs/book/src'],text=True).splitlines()
books = {p:ns['git'](p) for p in paths if Path(p).parent == chapter.parent and p.endswith('.md')}
require({str(p):p.read_bytes() for p in chapter.parent.glob('*.md')} == books,'whole original book epoch before atomic publication')
require(registry.read_bytes() == ns['git'](registry),'whole original collection/source/book authority before publication')
before,after = books[str(chapter)].decode(),ns['book']['transform'](books[str(chapter)].decode())
metrics = lambda blobs:dict(files=len(blobs),lines_total=sum(r.count(b'\n') for r in blobs.values()),bytes_total=sum(map(len,blobs.values())))
baseline,actual = metrics(books),metrics({**books,str(chapter):after.encode()})
lines = registry.read_text().splitlines()
prior = next(json.loads(s) for s in lines if json.loads(s).get('surface_id') == 'shipped_behavior')
authority = copy.deepcopy(prior)
authority['reference_contract']['aggregate_change'] = dict(authority_id='CLASS-FRAME-PUBLICATION-20261006-SHIPPED-BEHAVIOR',owner=ns['OWNER'],
    baseline=baseline,delta={k:actual[k]-baseline[k] for k in baseline},
    rationale='Publish complete qualified class/frame source facts and all current reader routes while preserving every retained meaning/question and distinct source/current/native/snapshot roles.')
updated_registry = '\n'.join(json.dumps(authority,sort_keys=True,separators=(',',':')) if json.loads(s).get('surface_id') == 'shipped_behavior' else s for s in lines) + '\n'
changed = {Path(p):text.encode() for p,text in source['cards'].items()}
changed.update({chapter:after.encode(),registry:updated_registry.encode()})
backup = {p:p.read_bytes() for p in changed}
generated = {p:p.read_bytes() for p in Path('knowledge-map/generated').rglob('*') if p.is_file()}
generated.update({Path('KNOWLEDGE_MAP.md'):Path('KNOWLEDGE_MAP.md').read_bytes()})
phases = []
try:
    for path,raw in changed.items():
        require(path.is_file() and not path.is_symlink() and path.stat().st_dev == Path.cwd().stat().st_dev,'regular same-volume owned publication destination')
        path.write_bytes(raw)
    command = ['knowledge-map/scripts/gen_knowledge_map.sh']; result = subprocess.run(command,capture_output=True)
    phases.append(dict(command=command,status=result.returncode,stdout=result.stdout.decode(),stderr=result.stderr.decode()))
    require(type(result.returncode) is int and result.returncode == 0,'actual complete current Knowledge Map regeneration')
    snapshot = ns['current_input'](); ns['check_current'](snapshot)
    require(ns['public']['cards']() == {**{p:r for p,r in original.items() if Path(p).parent == Path('docs/knowledge')},
        **{p:t.encode() for p,t in source['cards'].items()}},'whole exact published physical source bodies and non-target conservation')
    for role,receipt in snapshot['queries'].items():
        require(receipt['stdout'] == source['allocation']['rows'],'whole actual initial global current question allocation: ' + role)
    require(same(snapshot['census'],source['after']),'whole actual published physical capacity census')
    ns['save']('publication.json',dict(revision=ns['REVISION'],source=identity((BASE / 'source-model.json').read_bytes()),snapshot=snapshot,
        chapter=str(chapter),chapter_before=before,chapter_after=after,before_identity=identity(before.encode()),after_identity=identity(after.encode()),
        prior_whole_book={p:identity(raw) for p,raw in books.items()},baseline=baseline,actual=actual,authority_before=prior,authority_after=authority,
        changed_members={str(p):dict(before=identity(backup[p]),after=identity(raw)) for p,raw in changed.items()},
        role='One complete live fact/route/guide publication with actual direct/cache global ownership; all original raw/native captures remain retained.'))
except BaseException:
    for path,raw in backup.items(): path.write_bytes(raw)
    for path in Path('knowledge-map/generated').rglob('*'):
        if path.is_file() and path not in generated: path.unlink()
    for path,raw in generated.items(): path.write_bytes(raw)
    require(all(p.read_bytes() == raw for p,raw in {**backup,**generated}.items()),'whole exact publication failure restoration')
    raise
finally:
    output = CHECKS / 'publication-phases.json'; require(not output.exists(),'atomic phase records cannot overwrite')
    output.write_text(json.dumps(dict(phases=phases,role='Actual whole Knowledge Map regeneration; every failed mutation is restored exactly.'),sort_keys=True,indent=2) + '\n')
print('PASS complete atomic class/frame facts/routes/guide publication and actual full global direct/cache question conservation; collection authority unchanged.')
