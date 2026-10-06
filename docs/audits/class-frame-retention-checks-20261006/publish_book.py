"""Publish only the reviewed retention guide and its whole measured book authority."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-retention-20261006')
ns = {'__name__':'retention_source_publication','__file__':str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(),str(BASE / 'verify.py'),'exec'),ns)
require,same,identity,load = (ns[k] for k in ('require','same','identity','load'))
chapter = Path('docs/book/src/13k-isf-feature-support-matrix.md')
registry = Path('doctrine/live_document_size/surfaces.jsonl')
original = lambda p:subprocess.check_output(['git','show',ns['REVISION'] + ':' + str(p)])
paths = subprocess.check_output(['git','ls-tree','-r','--name-only',ns['REVISION'],'docs/book/src'],text=True).splitlines()
books = {p:original(p) for p in paths if Path(p).parent == chapter.parent and p.endswith('.md')}
require({str(p):p.read_bytes() for p in chapter.parent.glob('*.md')} == books,'whole unchanged prior physical book before retention guide')
require(registry.read_bytes() == original(registry),'whole unchanged prior collection and book authority before retention guide')
replay = load(ns['CHECKS'] / 'fresh-replay.json')
require(type(replay['status']) is int and replay['status'] == 0 and replay['stdout'] == ns['SUCCESS'],'actual full retention admission complete before source guide mutation')
before = books[str(chapter)].decode(); after = ns['module'](BASE / 'book.py')['transform'](before)
metrics = lambda blobs:dict(files=len(blobs),lines_total=sum(r.count(b'\n') for r in blobs.values()),bytes_total=sum(map(len,blobs.values())))
baseline,actual = metrics(books),metrics({**books,str(chapter):after.encode()})
lines = registry.read_text().splitlines()
prior = next(json.loads(line) for line in lines if json.loads(line).get('surface_id') == 'shipped_behavior')
row = copy.deepcopy(prior)
row['reference_contract']['aggregate_change'] = dict(authority_id='CLASS-FRAME-RETENTION-20261006-SHIPPED-BEHAVIOR',owner=ns['OWNER'],
    baseline=baseline,delta={k:actual[k]-baseline[k] for k in baseline},
    rationale='Publish complete reviewed semantic retention and frozen proposal/native/actual reader roles; live fact mutation and atomic current publication remain pending.')
ns['save']('book-change.json',dict(chapter=str(chapter),before=before,after=after,before_identity=identity(before.encode()),after_identity=identity(after.encode()),
    prior_whole_book={p:identity(raw) for p,raw in books.items()},baseline=baseline,actual=actual,authority_before=prior,authority_after=row))
chapter.write_text(after)
registry.write_text('\n'.join(json.dumps(row,sort_keys=True,separators=(',',':')) if json.loads(line).get('surface_id') == 'shipped_behavior' else line for line in lines) + '\n')
print('Published only the complete retention guide and independently measurable whole book aggregate; live cards and reader routes remain unchanged.')
