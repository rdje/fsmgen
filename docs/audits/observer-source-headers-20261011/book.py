"""Exact complete source-header book publication, unchanged capacity and native rendered guidance."""
import argparse
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path
from common import BASE, REVISION, need, pin, save

CHAPTER = Path('docs/book/src/13k-isf-feature-support-matrix.md')
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
ANCHOR = 'The complete finite raw-address and numerical/source parent acceptance is now\nqualified.'
TRANSFORMS = {'This closes the source-value parent only. Full source-generated original headers\nare the next separately owned step; original raw-header comparison, higher\nobserver/private/native and visual acceptance remain open.\n': 'The source-value qualification closes its own parent. Complete source-header\nqualification is described below; original raw-header comparison and higher\nobserver/private/native and visual acceptance retain their separate owners.\n'}
ADDITION = 'Complete original own source headers now have qualified source expressions.\nA separate direct traversal reconstructs every frame, argument, schema, ordered\nrole, phase group and load boundary. Restoring those expressions and their full\noperand bindings reproduces every complete original source mode. Whole inherited\ninner operands keep their dated evidence role.\n\nEvery expression retains all source arguments. Current conditional forms apply\nthe qualified public fixture grammar and an explicit profile: MaxArgLen 64, MaxArgNums 8, MaxEvalLen 0 and an\nundefined RefArgFormatter. Visible and hidden arguments remain separately\nallocated. The complete scalar and regex construction alternatives remain\navailable, including bounded and unlimited cases.\n\nFully known conditional forms produce whole header text. For example, a source\nbody with no supplied arguments has this selected current form:\n\n```json\n{"source_function":"main::__ANON__","source_arguments":[],"conditional_profile":{"MaxArgLen":64,"MaxArgNums":8,"MaxEvalLen":0,"RefArgFormatter":null},"known_conditional_header":"main::__ANON__()"}\n```\n\nOriginal reference tokens, regex flags and historical settings remain typed\nunmeasured boundaries. Their expression nodes retain complete source values,\nroles and qualified current alternatives. An unresolved slot supplies no guessed\nencoded token or wildcard matcher. The source do operation and diagnostic require\nmarker retain their separate full roles. Private framework and eval meanings\nremain unmeasured.\n\nWhole source/header/member/order/role/format/schema/value/encoding/profile and\nnative-promotion controls reject. The complete public grammar and actual main\nfixture plan/driver bindings qualify separately. Every prerequisite reexecutes\nin its qualified current-source or dated-publication context. Replay the full\nsource-selected qualification before original raw-header comparison:\n\n```sh\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-source-headers-20261011/verify.py\n```\n\nThis closes the unchanged source-header parent only. Original raw-header joining\nis next under its separate owner; observer/raw/native/private and visual\nacceptance retain their scopes.\n\n'


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
    need(before[str(CHAPTER)].decode().count(ANCHOR)==1 and ADDITION not in before[str(CHAPTER)].decode(), 'unique source-header guide source seam')
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
        need(current==before, 'publish only the owned sole source-header book addition')
        CHAPTER.write_bytes(after[str(CHAPTER)])
        rows=[json.loads(line) for line in REGISTRY.read_bytes().splitlines()]
        authority=next(r for r in rows if r.get('surface_id')=='shipped_behavior')['reference_contract']
        a,b=aggregate(list(before.values())),aggregate(list(after.values()))
        authority['aggregate_change']=dict(authority_id='OBSERVER-SOURCE-HEADERS-20261011',
            owner=(BASE/'scope.txt').read_text().splitlines()[0],baseline=a,
            delta={key:b[key]-a[key] for key in a},
            rationale='Document complete source-header expressions, lossless source allocation and known conditional public display forms while retaining every original unknown and separately owned raw/native/private boundary.')
        REGISTRY.write_text(''.join(json.dumps(r,sort_keys=True)+'\n' for r in rows))
        save('book-publication.json',dict(revision=REVISION,addition=ADDITION,
            before={k:pin(v) for k,v in before.items()}, after={k:pin(v) for k,v in after.items()},
            authority=authority['aggregate_change']))
        print('PASS exact sole source-header book addition and fresh aggregate authority; capacity ceilings unchanged.')
    else:
        need(current==after, 'entire current source-header book publication and complete unchanged peers')
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
                 'whole unique rendered source-header guide')
            save(args.native_output,dict(chapter=pin(raw),addition=pin(ADDITION.encode()),
                scope='Whole native guidance text and source custody only; visual book QA remains open.'))
        print('PASS complete current source-header guide and source publication; visual QA remains separately owned.')


if __name__ == '__main__':
    main()
