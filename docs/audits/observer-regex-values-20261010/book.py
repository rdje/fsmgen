"""Exact regex book publication, unchanged capacity and native rendered guidance."""
import argparse
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path
from common import BASE, REVISION, need, pin, save

CHAPTER = Path('docs/book/src/13k-isf-feature-support-matrix.md')
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
ANCHOR = 'The complete finite raw-address and numerical/source parent acceptance is now\nqualified.'
ADDITION = '''Authored refusal regexes now have a separate complete source qualification.
The producer reads each whole literal from its original statement or supplied
helper declaration, preserving the entire pattern, absent authored modifiers
and ASCII source characters. A separate parser and source traversal reconstruct
all helper, case, phase, operand and role allocations.

Current public fixtures compile each complete pattern as a literal, from a byte
string, and from an explicitly upgraded string. The selected byte and upgraded
constructions preserve the same characters while producing distinct public
modifiers and displays. Bounded and unlimited argument-length profiles qualify
whole values, exact headers and complete trace bodies. These are dated current
construction results; original native regex encoding, Regexp identity and
formatter settings remain unmeasured. The public [regex inspection contract](https://perldoc.perl.org/5.34.0/re#regexp_pattern($ref))
explains the pattern and modifiers returned by the fixture's public API.

Whole source, pattern, modifier, encoding, membership, role, schema, profile
and native-promotion controls reject their intended defects. The first source
parser's omitted hyphen remains with its complete failed program and result.
Replay the complete dated qualification:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-regex-values-20261010/verify.py
```

Original reference/provider identities, private framework intervals, historical
settings, complete original headers and unchanged parent acceptance retain
their separate owners. This regex child closes no observer or raw-stack parent.

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
    need(before[str(CHAPTER)].decode().count(ANCHOR)==1 and ADDITION not in before[str(CHAPTER)].decode(), 'unique regex guide source seam')
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
        need(current==before, 'publish only the owned sole regex book addition')
        CHAPTER.write_bytes(after[str(CHAPTER)])
        rows=[json.loads(line) for line in REGISTRY.read_bytes().splitlines()]
        authority=next(r for r in rows if r.get('surface_id')=='shipped_behavior')['reference_contract']
        a,b=aggregate(list(before.values())),aggregate(list(after.values()))
        authority['aggregate_change']=dict(authority_id='OBSERVER-REGEX-VALUES-20261010',
            owner=(BASE/'scope.txt').read_text().splitlines()[0],baseline=a,
            delta={key:b[key]-a[key] for key in a},
            rationale='Document whole authored regex literals, source allocation and finite current public constructions while retaining original native identity/settings and every ancestor boundary.')
        REGISTRY.write_text(''.join(json.dumps(r,sort_keys=True)+'\n' for r in rows))
        save('book-publication.json',dict(revision=REVISION,addition=ADDITION,
            before={k:pin(v) for k,v in before.items()}, after={k:pin(v) for k,v in after.items()},
            authority=authority['aggregate_change']))
        print('PASS exact sole regex book addition and fresh aggregate authority; capacity ceilings unchanged.')
    else:
        need(current==after, 'entire current regex book publication and complete unchanged peers')
        if args.native:
            class Text(HTMLParser):
                def __init__(self):
                    super().__init__();self.parts=[]
                def handle_data(self,data):
                    self.parts.append(data)
            raw=Path('docs/book/book/13k-isf-feature-support-matrix.html').read_bytes()
            reader=Text();reader.feed(raw.decode())
            rendered=ADDITION.replace('[regex inspection contract](https://perldoc.perl.org/5.34.0/re#regexp_pattern($ref))',
                                      'regex inspection contract')
            # The configured Markdown renderer applies smart punctuation to
            # these two prose possessives. Keep the actual HTML text intact.
            rendered=rendered.replace("fixture's",'fixture’s').replace("parser's",'parser’s')
            expected=' '.join(line for line in rendered.splitlines() if not line.startswith('```'))
            need(' '.join(''.join(reader.parts).split()).count(' '.join(expected.split()))==1,
                 'whole unique rendered regex guide')
            save(args.native_output,dict(chapter=pin(raw),addition=pin(ADDITION.encode()),
                scope='Whole native guidance text and source custody only; visual book QA remains open.'))
        print('PASS complete current regex guide and source publication; visual QA remains separately owned.')


if __name__ == '__main__':
    main()
