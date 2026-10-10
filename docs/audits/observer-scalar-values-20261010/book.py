"""Exact scalar book publication, unchanged capacity and native rendered guidance."""
import argparse
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path
from common import BASE, REVISION, need, pin, save

CHAPTER = Path('docs/book/src/13k-isf-feature-support-matrix.md')
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
ANCHOR = 'The complete finite raw-address and numerical/source parent acceptance is now\nqualified.'
ADDITION = '''Non-predicate scalar operands now have their own complete source qualification.
The source producer and a separate direct traversal preserve every supplied or
default value, ordered role and operand schema. Entire inherited inner error
strings remain dated evidence; exercising those strings does not establish an
independent semantic source for their original native contents.

The current public fixtures construct each complete selected string from its
codepoints, each selected integer numerically, and each undefined value as
undef. Explicit argument-length profiles of 64 and 0 qualify bounded displays
and complete displays respectively. The separate checker compares complete
values, headers and trace bodies. A displayed prefix never replaces the full
source value, and original native scalar flags and formatter settings remain
unmeasured. Whole membership, role, schema, constructor, tail, profile and
scope controls reject their intended defects.

Replay the complete dated scalar qualification:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-scalar-values-20261010/verify.py
```

Regex construction, original receiver and referent identity, private framework
intervals, source do versus diagnostic require roles, complete original headers
and unchanged parent acceptance retain their separate owners. This scalar child
does not close the original observer or raw-stack contracts.

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
    need(before[str(CHAPTER)].decode().count(ANCHOR)==1 and ADDITION not in before[str(CHAPTER)].decode(), 'unique scalar guide source seam')
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
        need(current==before, 'publish only the owned sole scalar book addition')
        CHAPTER.write_bytes(after[str(CHAPTER)])
        rows=[json.loads(line) for line in REGISTRY.read_bytes().splitlines()]
        authority=next(r for r in rows if r.get('surface_id')=='shipped_behavior')['reference_contract']
        a,b=aggregate(list(before.values())),aggregate(list(after.values()))
        authority['aggregate_change']=dict(authority_id='OBSERVER-SCALAR-VALUES-20261010',
            owner=(BASE/'scope.txt').read_text().splitlines()[0],baseline=a,
            delta={key:b[key]-a[key] for key in a},
            rationale='Document complete non-predicate scalar source values and finite current public constructors while retaining inherited evidence and all original opaque and successor boundaries.')
        REGISTRY.write_text(''.join(json.dumps(r,sort_keys=True)+'\n' for r in rows))
        save('book-publication.json',dict(revision=REVISION,addition=ADDITION,
            before={k:pin(v) for k,v in before.items()}, after={k:pin(v) for k,v in after.items()},
            authority=authority['aggregate_change']))
        print('PASS exact sole scalar book addition and fresh aggregate authority; capacity ceilings unchanged.')
    else:
        need(current==after, 'entire current scalar book publication and complete unchanged peers')
        if args.native:
            class Text(HTMLParser):
                def __init__(self):
                    super().__init__();self.parts=[]
                def handle_data(self,data):
                    self.parts.append(data)
            raw=Path('docs/book/book/13k-isf-feature-support-matrix.html').read_bytes()
            reader=Text();reader.feed(raw.decode())
            expected=' '.join(line for line in ADDITION.splitlines() if not line.startswith('```'))
            need(' '.join(''.join(reader.parts).split()).count(' '.join(expected.split()))==1,
                 'whole unique rendered scalar guide')
            save(args.native_output,dict(chapter=pin(raw),addition=pin(ADDITION.encode()),
                scope='Whole native guidance text and source custody only; visual book QA remains open.'))
        print('PASS complete current scalar guide and source publication; visual QA remains separately owned.')


if __name__ == '__main__':
    main()
