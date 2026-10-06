"""Replace preliminary reader wording with the exact final scoped role guide."""
import json
from pathlib import Path

BASE=Path('docs/audits/record-value-public-boundary-publication-20261006')
CHECKS=Path('docs/audits/public-boundary-publication-checks-20261006')
ns={'__name__':'publication_guide_revision'}
exec(compile((BASE/'verify.py').read_bytes(),str(BASE/'verify.py'),'exec'),ns)
p=ns['load'](BASE/'publication.json'); chapter=Path(ns['CHAPTER']); registry=Path(ns['REGISTRY'])
assert 'snapshot' not in p and chapter.read_text()==p['chapter_after']
assert not (CHECKS/'initial-guide.md.txt').exists()
(CHECKS/'initial-guide.md.txt').write_bytes(chapter.read_bytes())
old_identity=ns['identity']((BASE/'publication.json').read_bytes())
p['chapter_after']=ns['transform_chapter'](p['chapter_before'])
book={p:raw for p,raw in ns['committed']('docs/book/src').items() if Path(p).parent==Path('docs/book/src') and p.endswith('.md')}
book[ns['CHAPTER']]=p['chapter_after'].encode()
p['book_after']=ns['pins'](book)
p['delta']={k:ns['metrics'](book)[k]-p['baseline'][k] for k in p['baseline']}
p['authority_after']['reference_contract']['aggregate_change']['delta']=p['delta']
lines=registry.read_text().splitlines();i=next(i for i,s in enumerate(lines) if json.loads(s).get('surface_id')=='shipped_behavior')
lines[i]=json.dumps(p['authority_after'],sort_keys=True,separators=(',',':'))
chapter.write_text(p['chapter_after']); registry.write_text('\n'.join(lines)+'\n')
(BASE/'publication.json').write_text(json.dumps(p,sort_keys=True,indent=2)+'\n')
(CHECKS/'guide-revision.json').write_text(json.dumps(dict(before_publication_identity=old_identity,
    preliminary_guide_identity=ns['identity']((CHECKS/'initial-guide.md.txt').read_bytes()),
    final_guide_identity=ns['identity'](chapter.read_bytes()),
    role='Preliminary unsealed producer wording corrected before current qualification; final actual seal is authoritative.',
    reason='Explicit superseded whole-card snapshot/current roles and immediately owned tooling companion repair.'),sort_keys=True,indent=2)+'\n')
print('PASS final scoped source/snapshot/current wording and exact aggregate authority.')
