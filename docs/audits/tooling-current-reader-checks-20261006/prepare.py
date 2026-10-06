"""Publish only the exact non-growing tooling route and scoped reader guide."""
import argparse
import copy
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-tooling-current-reader-20261006')
ns = {'__name__': 'tooling_preparation', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
require, same, identity = (ns[k] for k in ('require', 'same', 'identity'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--finish', action='store_true')
    args = parser.parse_args()
    public = ns['module'](ns['PUBLIC'] / 'verify.py')
    if args.finish:
        publication = ns['load'](BASE / 'publication.json')
        require('snapshot' not in publication, 'fresh initial snapshot capture')
        record = ns['current_input'](); ns['check_current'](record)
        require(same(ns['pins'](public['cards']()), publication['after_members']), 'whole initial physical member conservation')
        publication['snapshot'] = record
        (BASE / 'publication.json').write_text(json.dumps(publication, sort_keys=True, indent=2) + '\n')
        print('PASS complete initial source/current snapshot and actual global query conservation.')
        return
    require(not (BASE / 'binding.json').exists(), 'fresh tooling preparation')
    before = {p: raw for p, raw in ns['committed']('docs/knowledge').items()
              if Path(p).parent == Path('docs/knowledge') and p.endswith('.md')}
    require(public['cards']() == before, 'whole clean source card population')
    book = {p: raw for p, raw in ns['committed']('docs/book/src').items()
            if Path(p).parent == Path('docs/book/src') and p.endswith('.md')}
    require({str(p): p.read_bytes() for p in Path('docs/book/src').glob('*.md')} == book, 'whole clean source book population')
    programmes = ['knowledge-map/scripts/query_knowledge_map.sh', 'knowledge-map/scripts/knowledge_map.pl',
        'knowledge-map/scripts/knowledge_map.conf', 'scripts/book_source_references.py', 'scripts/check_book_source_index.py',
        'docs/audits/knowledge-card-rollover-20261005/verify.py']
    ns['save']('binding.json', dict(revision=ns['REVISION'], owner=ns['OWNER'],
        archives={str(p): ns['pins'](ns['committed'](p)) for p in (ns['PUBLIC'], ns['PUBLIC_CHECKS'])},
        programmes={p: identity(ns['git'](p)) for p in programmes}))
    ns['authenticate']()
    after = {**before, ns['TOOLING']: ns['transform_card'](before[ns['TOOLING']].decode()).encode()}
    chapter_before = book[ns['CHAPTER']].decode(); chapter_after = ns['transform_chapter'](chapter_before)
    keys = ('files', 'lines_total', 'bytes_total')
    baseline = {k: public['metrics'](book)[k] for k in keys}
    updated_book = {**book, ns['CHAPTER']: chapter_after.encode()}
    delta = {k: public['metrics'](updated_book)[k] - baseline[k] for k in keys}
    registry = Path(ns['REGISTRY']); lines = registry.read_text().splitlines()
    i = next(i for i, s in enumerate(lines) if json.loads(s).get('surface_id') == 'shipped_behavior')
    authority_before = json.loads(lines[i]); authority_after = copy.deepcopy(authority_before)
    require(same(authority_before, next(json.loads(s) for s in ns['git'](ns['REGISTRY']).decode().splitlines()
            if json.loads(s).get('surface_id') == 'shipped_behavior')), 'whole original book authority')
    authority_after['reference_contract']['aggregate_change'] = dict(
        authority_id='TOOLING-CURRENT-READER-20261006-SHIPPED-BEHAVIOR', owner=ns['OWNER'], baseline=baseline, delta=delta,
        rationale='Repair the current tooling route and distinguish the retained observer checkpoint from the complete current reader.')
    ns['save']('publication.json', dict(before_members=ns['pins'](before), after_members=ns['pins'](after),
        chapter_before=chapter_before, chapter_after=chapter_after, baseline=baseline, delta=delta,
        authority_before=authority_before, authority_after=authority_after))
    Path(ns['TOOLING']).write_bytes(after[ns['TOOLING']]); Path(ns['CHAPTER']).write_text(chapter_after)
    lines[i] = json.dumps(authority_after, sort_keys=True, separators=(',', ':'))
    registry.write_text('\n'.join(lines) + '\n')
    print('PASS tooling date/route and scoped guide published; all original body/questions and authority retain.')


if __name__ == '__main__':
    main()
