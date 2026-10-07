"""Independently rederive complete published source/card/book/global authority."""
import copy
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-20261006')
CHECKS = Path('docs/audits/class-frame-publication-checks-20261006')
ns = {'__name__':'independent_whole_publication','__file__':str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(),str(BASE / 'verify.py'),'exec'),ns)
require,same,identity,load = (ns[k] for k in ('require','same','identity','load'))


def check(record):
    source = ns['source_model'](); require(same(source,load(BASE / 'source-model.json')),'whole independently regenerated original/current card and global population model')
    require(record['revision'] == ns['REVISION'] and record['source'] == identity((BASE / 'source-model.json').read_bytes()),'exact complete publication source epoch')
    ns['check_current'](record['snapshot'])
    require(same(record['snapshot']['physical_members'],source['after_members']) and same(record['snapshot']['census'],source['after']),
            'whole independent published physical source and capacity population')
    require(all(r['stdout'] == source['allocation']['rows'] for r in record['snapshot']['queries'].values()),'whole independently derived initial global query identity path and occurrence allocation')
    paths = ns['subprocess'].check_output(['git','ls-tree','-r','--name-only',ns['REVISION'],'docs/book/src'],text=True).splitlines()
    chapter = ns['CHAPTER']; books = {p:ns['git'](p) for p in paths if Path(p).parent == chapter.parent and p.endswith('.md')}
    before,after = books[str(chapter)].decode(),ns['book']['transform'](books[str(chapter)].decode())
    require(record['chapter'] == str(chapter) and record['chapter_before'] == before and record['chapter_after'] == after,'whole independent exact retained/current guide transformation')
    require(same(record['prior_whole_book'],{p:identity(r) for p,r in books.items()}),'whole original physical book population')
    metric = lambda blobs:dict(files=len(blobs),lines_total=sum(r.count(b'\n') for r in blobs.values()),bytes_total=sum(map(len,blobs.values())))
    baseline,actual = metric(books),metric({**books,str(chapter):after.encode()})
    require(same(record['baseline'],baseline) and same(record['actual'],actual),'whole independently rederived publication book aggregate')
    prior = next(json.loads(s) for s in ns['git'](ns['REGISTRY']).decode().splitlines() if json.loads(s).get('surface_id') == 'shipped_behavior')
    authority = copy.deepcopy(prior)
    authority['reference_contract']['aggregate_change'] = dict(authority_id='CLASS-FRAME-PUBLICATION-20261006-SHIPPED-BEHAVIOR',owner=ns['OWNER'],
        baseline=baseline,delta={k:actual[k]-baseline[k] for k in baseline},
        rationale='Publish complete qualified class/frame source facts and all current reader routes while preserving every retained meaning/question and distinct source/current/native/snapshot roles.')
    require(same(record['authority_before'],prior) and same(record['authority_after'],authority),'exact measured publication authority without ceiling widening')
    require(record['before_identity'] == identity(before.encode()) and record['after_identity'] == identity(after.encode()),'whole independent publication source identities')
    require(record['role'] == 'One complete live fact/route/guide publication with actual direct/cache global ownership; all original raw/native captures remain retained.',
            'exact actual publication versus original native scope')
    return dict(source=identity((BASE / 'source-model.json').read_bytes()),physical=source['after_members'],global_allocation=source['allocation'],
        book_baseline=baseline,book_actual=actual,authority=authority,
        scope='Full source/semantic/metadata/body/global and book derivation, never aggregate or hash substitution for the retained proposition models.')


def main():
    record = load(BASE / 'publication.json'); derived = check(record)
    require(ns['public']['cards']() == {**{p:r for p,r in ns['sources']().items() if Path(p).parent == Path('docs/knowledge')},
        **{p:t.encode() for p,t in ns['model']['cards']().items()}},'whole actual current physical source and non-target conservation')
    current = {str(p):p.read_bytes() for p in ns['CHAPTER'].parent.glob('*.md')}
    require({p:identity(raw) for p,raw in current.items()} == {**record['prior_whole_book'],record['chapter']:record['after_identity']},'whole current book changes only declared class/frame guidance')
    authority = next(json.loads(s) for s in ns['REGISTRY'].read_text().splitlines() if json.loads(s).get('surface_id') == 'shipped_behavior')
    require(same(authority,record['authority_after']),'whole current exact measured publication book authority')
    controls = []
    for name,mutate,cause in (
        ('lost-source-card',lambda r:r['snapshot']['cards'].pop(ns['CORE']),'complete current class/frame retained facts qualifiers questions identity and all routes'),
        ('lost-physical-member',lambda r:r['snapshot']['physical_members'].pop(next(iter(r['snapshot']['physical_members']))),'whole current physical member and non-target source conservation'),
        ('lost-book-member',lambda r:r['prior_whole_book'].pop(next(iter(r['prior_whole_book']))),'whole original physical book population'),
        ('invented-book-total',lambda r:r['actual'].update(bytes_total=0),'whole independently rederived publication book aggregate'),
        ('native-scope-promotion',lambda r:r.update(role='Original native raw classes recaptured.'),'exact actual publication versus original native scope'),
        ('widened-book-ceiling',lambda r:r['authority_after']['enforcement_ceilings'].update(bytes_total=99999999),'exact measured publication authority without ceiling widening')):
        changed = copy.deepcopy(record); mutate(changed); require(not same(changed,record),'genuine independent publication intervention: ' + name)
        try: check(changed)
        except ValueError as error:
            require(str(error) == cause,'intended independent publication refusal: ' + name + ': ' + str(error)); controls.append(dict(control=name,status=1,cause=cause))
        else: raise ValueError('false-green independent publication: ' + name)
    output = CHECKS / 'publication-proof.json'; value = dict(proof=derived,controls=controls)
    if output.exists(): require(same(load(output),value),'whole saved independent complete publication proof')
    else: output.write_text(json.dumps(value,sort_keys=True,indent=2) + '\n')
    print('PASS independent complete class/frame source/card/global/book population and measured authority; genuine source/member/scope/aggregate/ceiling losses refuse.')


if __name__ == '__main__': main()
