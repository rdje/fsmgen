"""Prepare full non-growing topic review; no current publication is implied."""
import gzip
import json
import subprocess
import textwrap
from pathlib import Path
from common import BASE, REVISION, SCOPE, canonical, need, pin, save

CARD='docs/knowledge/record-value-original-observer-helper-paths.md'
REGISTRY='doctrine/live_document_size/surfaces.jsonl'
QUESTION='what qualifies complete original observer argument headers?'


def git(path):
    actual=subprocess.run(['git','--no-replace-objects','show',REVISION+':'+path],capture_output=True)
    need(type(actual.returncode) is int and actual.returncode==0 and actual.stderr==b'', 'complete fixed publication beforeimage')
    return actual.stdout


def metrics(raw):
    return dict(bytes=len(raw),lines=raw.count(b'\n'),max_line_bytes=max(map(len,raw.splitlines())))


def paragraphs(raw):
    return raw.decode().split('---',2)[2].strip().split('\n\n')


def final_card():
    initial=(BASE/'after-card.md.txt').read_bytes()
    header=initial.decode().split('---',2)[1]
    body=paragraphs(initial)
    edits={'Complete encoded headers join full source expressions and overlapping frame aliases':
           'Complete headers join full source expressions and frame aliases',
           'Model/member/order/role/kind/family/operand':
           'Model/population/member/order/phase/role/kind/family/operand'}
    words=[' '.join(p.split()) for p in body]
    changed=[]
    for p in words:
        for old,new in edits.items(): p=p.replace(old,new)
        changed.append(p)
    before=(BASE/'before-card.md.txt').read_bytes(); chosen=None
    for width in range(128,metrics(before)['max_line_bytes']+1):
        wrapped=[textwrap.fill(p,width,break_long_words=False,break_on_hyphens=False) for p in changed]
        candidate=('---'+header+'---\n\n'+'\n\n'.join(wrapped)+'\n').encode()
        if all(metrics(candidate)[k]<=v for k,v in metrics(before).items()):
            chosen=(width,candidate,wrapped);break
    need(chosen is not None,'non-growing complete canonical review')
    width,raw,wrapped=chosen
    need(all(' '.join(p.split())==w for p,w in zip(wrapped,changed)),'whole paragraph lexical conservation')
    return raw,dict(before=metrics(before),after=metrics(raw),selected_width=width,
                    declared_edits=edits,whole_paragraph_words=changed)


def review(before,after):
    old=paragraphs(before);new=paragraphs(after)
    # Each whole old paragraph is retained with the complete replacement text.
    # This is a dated engineering review, not an automated language oracle.
    mapping=[([0], 'All API/parser/eval/wrapper/source roles, declared receiver, source graphs, supplied/default inputs, returned builders, parameterless callbacks, regex bodies/labels, both nested throw phases and contiguous source-first order retain. Full conditional grammar is added in replacement paragraph 4; original identity remains unknown.'),
             ([5], 'Core source/address/active-holder and own coordinate qualifications retain. All original private/provider/hook/class/native-address/framework/parser identities, external coordinates, consumer/alias/full-semantic/cold/candidate/permanent/hot/host-native/visual scopes remain unknown or open. Dated full-format uncertainty becomes the explicitly conditional current grammar in paragraph 4, never original settings.'),
             ([6], 'Related canonical replay/probe route retains exactly.'),
             ([], 'The organizational heading adds no independent proposition; complete own-subtest/do-load meanings retain in paragraphs 1 and 2.'),
             ([1], 'Every refusal, authored named body, saved delegate, name/body/extras, wrapper, callback argument and delegate-extra forwarding, empty authored extras/body/own callback and name/CODE kind retain; kind still supplies no callback identity.'),
             ([2], 'Original do-file spelling and error/return capture, diagnostic require distinction, public POD contract, dated current interface qualification and unknown original framework version retain.'),
             ([4,5], 'Dated public prefix/CODE-kind/body/delegate/entry/do-load order qualification remains its historical limited predicate. New complete token contract strictly strengthens it. Opaque receiver/private intervals and native unknowns retain. Every old wrong-name/kind/population/order control is included.'),
             ([3,4], 'All operation/helper/body/public/entry/load class/family/guard/phase/operand roles and original phases retain. Prior predicates still treat inherited operands as opaque without formatter/coordinate/address oracle; opaque own/public false-green versus full forwarding refusal retains. Whole model/member/population/order/phase/role/kind/family/operand/native-promotion controls retain.')]
    return [dict(original_index=i,whole_original=p,replacement_indices=indices,
                 whole_replacements=[new[n] for n in indices],judgment=judgment)
            for i,(p,(indices,judgment)) in enumerate(zip(old,mapping))]


def main():
    before=git(CARD); need(before==(BASE/'before-card.md.txt').read_bytes()==Path(CARD).read_bytes(),'whole fixed and still-current topic before publication')
    after,layout=final_card()
    (BASE/'published-card.md.txt').write_bytes(after)
    save('final-layout.json',layout)
    fixed={}
    for root in ('docs/knowledge','docs/decisions'):
        for path in sorted(Path(root).rglob('*.md')):
            need(not path.is_symlink(),'same-volume ordinary canonical source')
            fixed[str(path)]=path.read_text()
    need(fixed[CARD].encode()==before,'complete global topic beforeimage')
    (BASE/'before-canonical.json.gz').write_bytes(gzip.compress(canonical(fixed),mtime=0))
    (BASE/'before-registry.jsonl.txt').write_bytes(git(REGISTRY))
    save('review.json',dict(kind='explicit whole-proposition engineering review; no language oracle',
         rows=review(before,after),retained_probes=['scripts/run_with_ram_guard.sh -- python3 -B scripts/check_record_value_publication.py',
         'record-value-finite-copy-probe-reader'],new_scope=SCOPE))
    save('proposal.json',dict(schema='complete-observer-publication-v1',root='.',owner=(BASE/'scope.txt').read_text().splitlines()[0],
         revision=REVISION,scope=SCOPE,card=CARD,question=QUESTION,before=pin(before),after=pin(after),
         review=pin((BASE/'review.json').read_bytes()),layout=pin((BASE/'final-layout.json').read_bytes()),
         registry=pin(git(REGISTRY)),source_population=pin((BASE/'before-canonical.json.gz').read_bytes())))
    print('PASS complete fixed beforeimages and explicit non-growing topic review prepared; live card untouched.')


if __name__=='__main__': main()
