"""Finish one prose spacing correction while retaining the first publication."""
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/coordinate-original-matching-qualified-checks-20261009')
CHAPTER = Path('docs/book/src/90-reference-map.md')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')


def pin(raw):
    return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}


def main():
    destination=BASE/'book-final.json'
    if destination.exists():
        raise ValueError('final book publication never rewrites')
    product=json.loads((BASE/'book.json').read_bytes())
    raw=CHAPTER.read_bytes()
    old=b'this original guard call matches both source labels at line107,'
    new=b'this original guard call matches both source labels at line 107,'
    if pin(raw)!=product['after'] or raw.count(old)!=1:
        raise ValueError('exact complete first book publication')
    after=raw.replace(old,new,1)
    product['current_block']=product['current_block'].replace(old.decode(),new.decode(),1)
    product['after']=pin(after)
    product['book_after']['bytes_total']+=len(new)-len(old)
    records=list(map(json.loads,SURFACES.read_text().splitlines()))
    row=next(r for r in records if r.get('surface_id')=='shipped_behavior')
    change=row['reference_contract']['aggregate_change']
    if change['owner']!=product['owner'] or change['baseline']!=product['book_before']:
        raise ValueError('exact first book authority')
    change['delta']={key:product['book_after'][key]-product['book_before'][key] for key in product['book_before']}
    CHAPTER.write_bytes(after)
    SURFACES.write_text(''.join(json.dumps(r,sort_keys=True)+'\n' for r in records))
    destination.write_text(json.dumps(product,sort_keys=True,indent=2)+'\n')
    print('PASS exact prose spacing correction; complete first publication retained.')


if __name__=='__main__':
    main()
