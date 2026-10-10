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
ADDITION = '''Complete remaining scalar and regex qualification now joins every original
source-value and profile-boundary obligation. A separate source traversal
reconstructs complete operands, schemas, ordered roles, known values, constructor
qualifications and phase allocations. Guard-derived scalar forms remain distinct
from declared logical fields; entire inherited inner operands retain their dated
evidence role.

Each original reference, receiver, private framework interval and eval boundary
keeps its explicit unmeasured meaning. Complete original records and public
boundary products retain every captured byte as evidence. Their tokens do not
supply a new source-constructor oracle. Original formatter settings, native
flags, encoding and identities remain unmeasured. The source do operation and
the diagnostic require marker keep separate roles throughout the join.

Every prerequisite executes again in its proper context. Source readers use
current fixed source inputs; the dated publication reader uses all inputs from
its exact committed epoch in a repository-local checkpoint. Its rejection of
later task metadata remains a rejection. The fresh checkpoint execution and
complete before/after byte conservation qualify the dated result separately.

Whole omitted, borrowed, reordered, wrong-role, schema, value, encoding, profile,
private-meaning and acceptance controls reject. Replay the complete qualification:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-value-profile-boundaries-20261010/verify.py
```

This completes only the remaining-value parent and its boundary child. Complete
source-value parent acceptance, source-generated original headers, the original
body join and observer publication retain their separate owners. Higher raw,
native/private and visual scopes remain open.

'''


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
    need(before[str(CHAPTER)].decode().count(ANCHOR)==1 and ADDITION not in before[str(CHAPTER)].decode(), 'unique value-profile guide source seam')
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
        need(current==before, 'publish only the owned sole value-profile book addition')
        CHAPTER.write_bytes(after[str(CHAPTER)])
        rows=[json.loads(line) for line in REGISTRY.read_bytes().splitlines()]
        authority=next(r for r in rows if r.get('surface_id')=='shipped_behavior')['reference_contract']
        a,b=aggregate(list(before.values())),aggregate(list(after.values()))
        authority['aggregate_change']=dict(authority_id='OBSERVER-VALUE-PROFILE-BOUNDARIES-20261010',
            owner=(BASE/'scope.txt').read_text().splitlines()[0],baseline=a,
            delta={key:b[key]-a[key] for key in a},
            rationale='Document complete remaining-value obligation and opaque-profile qualification while preserving whole inherited evidence and all original native/settings/private and higher header/raw boundaries.')
        REGISTRY.write_text(''.join(json.dumps(r,sort_keys=True)+'\n' for r in rows))
        save('book-publication.json',dict(revision=REVISION,addition=ADDITION,
            before={k:pin(v) for k,v in before.items()}, after={k:pin(v) for k,v in after.items()},
            authority=authority['aggregate_change']))
        print('PASS exact sole value-profile book addition and fresh aggregate authority; capacity ceilings unchanged.')
    else:
        need(current==after, 'entire current value-profile book publication and complete unchanged peers')
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
                 'whole unique rendered value-profile guide')
            save(args.native_output,dict(chapter=pin(raw),addition=pin(ADDITION.encode()),
                scope='Whole native guidance text and source custody only; visual book QA remains open.'))
        print('PASS complete current value-profile guide and source publication; visual QA remains separately owned.')


if __name__ == '__main__':
    main()
