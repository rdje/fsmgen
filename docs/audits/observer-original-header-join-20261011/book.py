"""Exact complete original-header book publication, unchanged capacity and native rendered guidance."""
import argparse
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path
from common import BASE, REVISION, need, pin, save

CHAPTER = Path('docs/book/src/13k-isf-feature-support-matrix.md')
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
ANCHOR = 'The complete finite raw-address and numerical/source parent acceptance is now\nqualified.'
TRANSFORMS = {'This closes the unchanged source-header parent only. Original raw-header joining\nis next under its separate owner; observer/raw/native/private and visual\nacceptance retain their scopes.\n': 'The source-header qualification closes its own parent. The original raw-header\njoin is described below; full observer publication and higher raw/native/private\nand visual acceptance retain their separate owners.\n'}
ADDITION = 'Complete original own encoded headers now join their qualified source expressions.\nEvery core, operation wrapper, named helper, callback, subtest body, delegate and\nentry view retains its complete source role and original frame allocation.\nOverlapping views remain explicit aliases of the same captured frame. The public\nsubtest expression retains the full authored name and callback kind with its\nwhole opaque receiver interval.\n\nKnown argument values use the previously qualified explicit public grammar.\nWhole quotes, escapes, truncation suffixes, argument separators, hidden arguments\nand the remaining-argument marker qualify together. Full authored regex values\nretain all qualified constructor alternatives. Encoded compatibility does not\nmeasure the original formatter settings, flags, encoding or provider identity.\n\nEvery reference token and remaining private/framework interval retains its whole\noriginal bytes. Source-declared display classes and reference kinds qualify the\nvisible spelling; native class, referent contents and identity remain unmeasured.\nThe source do operator and diagnostic require marker keep their distinct roles.\nThe complete original raw, address, coordinate and source domains conserve.\n\nAn actual different proper subtest-name prefix still passes the deliberately\nlimited predecessor predicate and now fails the complete known-token contract.\nBorrowed, omitted, reordered, wrong-role, quote, truncation, count, whole-token,\nsource-profile and scope controls reject their intended contracts. Independent\nlexing and source rendering reconstruct every complete result. All complete\nprerequisites reexecute in their qualified current or dated contexts:\n\n```sh\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-original-header-join-20261011/verify.py\n```\n\nThis closes only the unchanged header-repair acceptance. Complete observer\npublication and parent acceptance are next under their separate owner; higher\nraw, consumer, alias, cold, native/private and visual scopes remain open.\n\n'


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
    need(before[str(CHAPTER)].decode().count(ANCHOR)==1 and ADDITION not in before[str(CHAPTER)].decode(), 'unique original-header guide source seam')
    after=dict(before)
    changed=before[str(CHAPTER)].decode()
    for old,new in TRANSFORMS.items():
        need(changed.count(old)==1,'unique owned prior source-status wording')
        changed=changed.replace(old,new,1)
    after[str(CHAPTER)]=changed.replace(ANCHOR,ADDITION+ANCHOR,1).encode()
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
        need(current==before, 'publish only the owned sole original-header book addition')
        CHAPTER.write_bytes(after[str(CHAPTER)])
        rows=[json.loads(line) for line in REGISTRY.read_bytes().splitlines()]
        authority=next(r for r in rows if r.get('surface_id')=='shipped_behavior')['reference_contract']
        a,b=aggregate(list(before.values())),aggregate(list(after.values()))
        authority['aggregate_change']=dict(authority_id='OBSERVER-ORIGINAL-HEADER-JOIN-20261011',
            owner=(BASE/'scope.txt').read_text().splitlines()[0],baseline=a,
            delta={key:b[key]-a[key] for key in a},
            rationale='Document complete original encoded header/source joins, full formatting controls and conserved opaque intervals while retaining every original unknown and separately owned observer/raw/native/private boundary.')
        REGISTRY.write_text(''.join(json.dumps(r,sort_keys=True)+'\n' for r in rows))
        save('book-publication.json',dict(revision=REVISION,addition=ADDITION,
            before={k:pin(v) for k,v in before.items()}, after={k:pin(v) for k,v in after.items()},
            authority=authority['aggregate_change']))
        print('PASS exact sole original-header book addition and fresh aggregate authority; capacity ceilings unchanged.')
    else:
        need(current==after, 'entire current original-header book publication and complete unchanged peers')
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
                 'whole unique rendered original-header guide')
            save(args.native_output,dict(chapter=pin(raw),addition=pin(ADDITION.encode()),
                scope='Whole native guidance text and source custody only; visual book QA remains open.'))
        print('PASS complete current original-header guide and source publication; visual QA remains separately owned.')


if __name__ == '__main__':
    main()
