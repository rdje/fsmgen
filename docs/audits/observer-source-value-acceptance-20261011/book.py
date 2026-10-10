"""Exact value-profile book publication, unchanged capacity and native rendered guidance."""
import argparse
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path
from common import BASE, REVISION, need, pin, save

CHAPTER = Path('docs/book/src/13k-isf-feature-support-matrix.md')
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
ANCHOR = 'The complete finite raw-address and numerical/source parent acceptance is now\nqualified.'
ADDITION = 'Complete source-value parent acceptance is now qualified. Independent direct\nsource traversal joins every original obligation to a complete value or phase,\nwith all schemas, member order, argument roles and inherited inner operands.\nWhole predicate, scalar and authored regex products conserve their qualified\nsource and evidence roles.\n\nEvery source-neutral public construction retains its complete selected plan,\ndriver and actual native receipt. The receipt must authenticate that exact\nplan and driver; an intervention plan cannot substitute for the main fixture\nplan. Current public profiles determine only their qualified construction\nalternatives. They supply no original formatter setting, native flag, encoding,\nidentity or private meaning.\n\nThe source do operation remains distinct from its diagnostic require marker.\nWhole original receiver/reference, private framework and eval evidence remains\nopaque. Source-first selection and each complete original parent and child\ncontract conserve. Fresh prerequisites execute in their qualified current-source\nor fixed committed-publication context, with complete results retained.\n\nReplay the complete source-value parent and genuine whole controls:\n\n```sh\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-source-value-acceptance-20261011/verify.py\n```\n\nThis closes the source-value parent only. Full source-generated original headers\nare the next separately owned step; original raw-header comparison, higher\nobserver/private/native and visual acceptance remain open.\n\n'


def git(*args):
    result = subprocess.run(['git','--no-replace-objects',*args],capture_output=True)
    need(result.returncode == 0 and not result.stderr,'whole fixed book authority')
    return result.stdout


def aggregate(rows):
    return dict(files=len(rows),lines_total=sum(r.count(b'\n') for r in rows),bytes_total=sum(map(len,rows)))


def source():
    names = sorted(name for name in git('ls-tree','-r','--name-only',REVISION,'--','docs/book/src').decode().splitlines()
                   if Path(name).parent == Path('docs/book/src') and name.endswith('.md'))
    before = {name:git('show',REVISION+':'+name) for name in names}
    need(before[str(CHAPTER)].decode().count(ANCHOR)==1 and ADDITION not in before[str(CHAPTER)].decode(), 'unique source-value parent guide source seam')
    after=dict(before)
    after[str(CHAPTER)]=before[str(CHAPTER)].decode().replace(ANCHOR,ADDITION+ANCHOR,1).encode()
    return before,after


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--publish',action='store_true')
    parser.add_argument('--native',action='store_true')
    parser.add_argument('--native-output',default='book-native.json',choices=['book-native.json','book-native-final.json'])
    args=parser.parse_args()
    before,after=source()
    current={str(p):p.read_bytes() for p in Path('docs/book/src').glob('*.md')}
    if args.publish:
        need(current==before, 'publish only the owned sole source-value parent book addition')
        CHAPTER.write_bytes(after[str(CHAPTER)])
        rows=[json.loads(line) for line in REGISTRY.read_bytes().splitlines()]
        authority=next(r for r in rows if r.get('surface_id')=='shipped_behavior')['reference_contract']
        a,b=aggregate(list(before.values())),aggregate(list(after.values()))
        authority['aggregate_change']=dict(authority_id='OBSERVER-SOURCE-VALUE-ACCEPTANCE-20261011',
            owner=(BASE/'scope.txt').read_text().splitlines()[0],baseline=a,
            delta={key:b[key]-a[key] for key in a},
            rationale='Document complete unchanged source-value parent acceptance, original obligation and whole public construction bindings while retaining inherited evidence and original native/settings/private and higher header/raw boundaries.')
        REGISTRY.write_text(''.join(json.dumps(r,sort_keys=True)+'\n' for r in rows))
        save('book-publication.json',dict(revision=REVISION,addition=ADDITION,
            before={k:pin(v) for k,v in before.items()}, after={k:pin(v) for k,v in after.items()},
            authority=authority['aggregate_change']))
        print('PASS exact sole source-value parent book addition and fresh aggregate authority; capacity ceilings unchanged.')
    else:
        need(current==after, 'entire current source-value parent book publication and complete unchanged peers')
        if args.native:
            class Text(HTMLParser):
                def __init__(self):
                    super().__init__();self.parts=[]
                def handle_data(self,data):
                    self.parts.append(data)
            raw=Path('docs/book/book/13k-isf-feature-support-matrix.html').read_bytes()
            reader=Text();reader.feed(raw.decode())
            rendered=ADDITION
            expected=' '.join(line for line in rendered.splitlines() if not line.startswith('```'))
            need(' '.join(''.join(reader.parts).split()).count(' '.join(expected.split()))==1,
                 'whole unique rendered source-value parent guide')
            save(args.native_output,dict(chapter=pin(raw),addition=pin(ADDITION.encode()),
                scope='Whole native guidance text and source custody only; visual book QA remains open.'))
        print('PASS complete current source-value parent guide and source publication; visual QA remains separately owned.')


if __name__ == '__main__':
    main()
