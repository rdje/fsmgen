"""Exact complete observer-current book publication, unchanged capacity and native rendered guidance."""
import argparse
import json
import subprocess
from html.parser import HTMLParser
from pathlib import Path
from common import BASE, REVISION, need, pin, save

CHAPTER = Path('docs/book/src/13k-isf-feature-support-matrix.md')
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
ANCHOR = 'Original address roles now have a separate complete finite qualification.\nEvery own visible reference number joins its simultaneous source and holder\ndomain. Explicit aliases agree; qualified distinctions differ. Active\n`main::call_api` retains the saved CODE handle through lexical `$operation`.\nCODE/CODE comparisons remain opaque. A consistent renaming can preserve the\nfinite relation, but still fails the separate original-byte association check.\n\nFor example, repeated occurrences of an explicit alias must retain one reference\nnumber within that source domain. Distinct qualified holders must retain distinct\nnumbers there. Equal-looking CODE displays, regex displays and hidden arguments\nprovide no missing referent, payload, flag or native identity. The finite join\ndoes not establish cross-call or cross-capture reuse, heap lifetime or cold cost.\n\nThe coordinate-era and preparation paragraphs retain their dated checkpoint\nroles. Current core, helper, parser and tooling cards now admit the reviewed\naddress proposal together. Exact beforeimages, every prior question and replay\ncommand remain retrievable under unchanged collection authority. The maintained\nreader authenticates the complete admitted preparation, source/holder/numerical\ninputs and actual independent results before and after current verification.\nAuthentication is not a fresh semantic reconstruction or original recapture.\n\nReplay the complete dated raw/source/numerical parent qualification separately:\n\n```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-parent-acceptance-20261010/verify.py\n```\n\nCurrent verification still derives every canonical source, direct and cached\nquestion allocation, physical capacity and copied source. Its native variant\nalso checks the rendered current guidance. The original private/provider/\nformatter, external/native/CODE/Regexp identity, cross-call/capture reuse, heap,\ncold and visual scopes remain separately owned. Full unchanged address-container\nacceptance now qualifies through fresh complete semantic readers and independent\nwhole original/proposed/current reconstruction. Only finite address nodes close;\nfull raw-stack joining is next. HIAL and full CI/push gates stay open.\n\n'
TRANSFORMS = {'This closes only the unchanged header-repair acceptance. Complete observer\npublication and parent acceptance are next under their separate owner; higher\nraw, consumer, alias, cold, native/private and visual scopes remain open.\n': 'The unchanged header-repair acceptance is complete. The current observer\npublication above closes its own finite parent; higher raw, consumer, alias,\ncold, native/private and visual scopes retain their separate owners.\n'}
ADDITION = 'Complete finite observer acceptance now joins every source expression and whole\nencoded header with its observer, callback, refusal, subtest or do-load role.\nThe completed source, class/frame, public grammar, scalar, regex, hidden-value\nand original-header children reexecute before this publication. Each original\nframe and full argument header retains its exact membership and order.\n\nFull literal, quote, escape, truncation and count-marker compatibility uses the\nqualified current grammar. Authored regex constructor alternatives remain\nexplicit. Whole reference tokens, receiver parameters and private framework/eval\nintervals conserve their original bytes without supplying native identity.\nOriginal provider, formatter settings, flags, encoding and native identities\nremain unmeasured. Source-selected meaning and encoded compatibility retain\nseparate evidence roles.\n\nFor example, a different proper prefix of an authored public subtest name can\npass a dated predecessor that checks only a prefix. It fails the complete token\ncontract here. Removing a required ellipsis, changing a quote or count marker,\nborrowing a frame, changing a role, omitting an argument or reordering a frame\nalso fails its distinct full contract. Complete original and altered products,\nactual outcomes and the independent lexical/source/allocation reader remain\navailable in the dated original-header qualification.\n\nThe canonical observer fact now admits this complete finite result through a\nnon-growing review. Every earlier meaning, question and probe retains its role;\nthe previous full-format uncertainty is refined only by the explicitly\nconditional grammar. The first growing drafts and their actual refusals remain\nretained. Genuine lost-meaning, lost-question, lost-probe, wrong-owner, wrong-root,\nnarrowed-scope and native-promotion proposals reject before any admission seal.\nThe review is an engineering judgment, not an automated language-equivalence\noracle.\n\nThe maintained current reader authenticates the complete admitted preparation,\nwhole original-header namespace and actual prerequisite receipts. It still\nchecks all current canonical sources, global direct and cached question\nownership, exact physical capacity, canonical source copies and rendered\nguidance. Authentication does not freshly reconstruct original executions.\nIts historical success stream remains compatible. Unrelated qualified canonical\nprogress remains permitted under the unchanged collection authority.\n\nReplay the complete dated publication independently of later current progress:\n\n```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-current-publication-20261011/verify.py\n```\n\nThe earlier observer and address paragraphs retain their checkpoint roles.\nOnly the unchanged finite observer parent and its completed children close here.\nComplete raw-stack joining is next. First-cause, consumer, alias, cold, permanent,\nhost-native, private and visual acceptance retain their own unchanged owners;\nHIAL and full CI/push gates remain open.\n\nThe first observer publication above is a retained checkpoint. Its complete\nsemantic products remain qualified, but its first saved reader counted only\nflat ordinary files. An actual unexpected nested file left that reader green.\nThe full first epoch, exact programme and actual result remain unchanged.\n\nThe maintained current reader now authenticates the complete original namespace\nwith a strict recursive graph and whole member bytes. Unexpected directories,\nnested files, symlinks, missing members and changed tails reject; Boolean byte\nsizes also reject. An independent recursive reader checks complete positive and\nhostile candidate archives. The full original semantic reader reexecutes after\nthe strict boundary qualifies. Mutable gate receipts retain their explicitly\nseparate role, while every required final actual result stays source-bound.\n\nUse the repaired complete dated reader for this stronger namespace guarantee:\n\n```bash\nscripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-publication-namespace-repair-20261011/verify.py\n```\n\nThe earlier dated reader remains replayable in its original flat-member role.\nThe repaired reader also authenticates its own complete namespace. This repair\nadds no native identity or original recapture, and changes no observer meaning,\nquestion, probe, collection allowance or separately owned raw/native/private/\nvisual acceptance. Complete raw-stack joining remains next.\n\n'

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
    need(before[str(CHAPTER)].decode().count(ANCHOR)==1 and ADDITION not in before[str(CHAPTER)].decode(), 'unique observer-current guide source seam')
    after=dict(before)
    changed=before[str(CHAPTER)].decode()
    for old,new in TRANSFORMS.items():
        need(changed.count(old)==1,'unique owned prior source-status wording')
        changed=changed.replace(old,new,1)
    after[str(CHAPTER)]=changed.replace(ANCHOR,ANCHOR+ADDITION,1).encode()
    return before,after


def prior_book():
    namespace={'__name__':'retained_observer_book'}
    path=Path('docs/audits/observer-current-publication-20261011/book_qualified.py')
    exec(compile(path.read_bytes(),str(path),'exec'),namespace)
    return namespace['source']()[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--publish',action='store_true')
    parser.add_argument('--native',action='store_true')
    parser.add_argument('--native-output',default='book-native.json',choices=['book-native.json','book-native-final.json'])
    args=parser.parse_args()
    before,after=source()
    current={str(p):p.read_bytes() for p in Path('docs/book/src').glob('*.md')}
    if args.publish:
        need(current==prior_book(), 'publish only the owned sole observer-current book addition')
        CHAPTER.write_bytes(after[str(CHAPTER)])
        rows=[json.loads(line) for line in REGISTRY.read_bytes().splitlines()]
        authority=next(r for r in rows if r.get('surface_id')=='shipped_behavior')['reference_contract']
        a,b=aggregate(list(before.values())),aggregate(list(after.values()))
        authority['aggregate_change']=dict(authority_id='OBSERVER-PUBLICATION-NAMESPACE-REPAIR-20261011',
            owner=(BASE/'scope.txt').read_text().splitlines()[0],baseline=a,
            delta={key:b[key]-a[key] for key in a},
            rationale='Document complete complete finite observer canonical and current-reader publication, full original acceptance, conditional grammar, non-growing review and every original unknown and separately owned raw/native/private boundary.')
        REGISTRY.write_text(''.join(json.dumps(r,sort_keys=True)+'\n' for r in rows))
        save('book-publication.json',dict(revision=REVISION,addition=ADDITION,
            before={k:pin(v) for k,v in before.items()}, after={k:pin(v) for k,v in after.items()},
            authority=authority['aggregate_change']))
        print('PASS exact sole observer-current book addition and fresh aggregate authority; capacity ceilings unchanged.')
    else:
        need(current==after, 'entire current observer-current book publication and complete unchanged peers')
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
                 'whole unique rendered observer-current guide')
            save(args.native_output,dict(chapter=pin(raw),addition=pin(ADDITION.encode()),
                scope='Whole native guidance text and source custody only; visual book QA remains open.'))
        print('PASS complete current observer-current guide and source publication; visual QA remains separately owned.')


if __name__ == '__main__':
    main()
