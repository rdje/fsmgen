"""Qualify the unchanged finite observer parent before closing any node."""
import copy
import gzip
import json
from common import BASE, REPAIR, SCOPE, canonical, load, need, pin, save, same
import model
import oracle


def derive(current=True):
    retained_task=gzip.decompress((BASE/'closed-task.md.gz').read_bytes()).decode() if not current else None
    contracts=model.contracts(current=retained_task)
    need(same(contracts,load('contracts.json')),'whole original observer parent and descendant forest')
    proposal=model.qualify(load('proposal.json'),(BASE/'before-card.md.txt').read_bytes(),
                           (BASE/'published-card.md.txt').read_bytes(),load('review.json'))
    need(same(oracle.source(),load('independent-source-proof.json')),'independent complete canonical review and every original question')
    need(same(oracle.prerequisites(),load('independent-prerequisite-proof.json')),'independent full fresh semantic prerequisite qualification')
    whole=json.loads((REPAIR/'proof.json').read_bytes());independent=json.loads((REPAIR/'independent-proof.json').read_bytes())
    need(same(whole['result'],independent),'complete independently reconstructed full source/public/load/opaque original header product')
    controls=model.hostile_controls(load('proposal.json'),(BASE/'before-card.md.txt').read_bytes(),
                                   (BASE/'published-card.md.txt').read_bytes(),load('review.json'))
    need(same(controls,load('first-admission-controls.json')),'genuine pre-seal full semantic proposal controls')
    expected=contracts;parent=model.OWNER.rsplit('.',1)[0]
    interventions=[]
    for name in ('narrowed-parent','lost-descendant'):
        candidate=copy.deepcopy(expected)
        if name=='narrowed-parent':
            candidate['original_bodies'][parent]=candidate['original_bodies'][parent].replace('Acceptance:', 'Borrowed:',1)
        else:
            removed=next(key for key in candidate['original_bodies'] if key not in (parent,model.OWNER))
            candidate['original_bodies'].pop(removed)
        need(not same(candidate,expected),'genuine complete parent acceptance intervention')
        try:
            need(same(candidate,expected),'whole unchanged observer parent and every descendant contract')
        except ValueError as error:
            interventions.append(dict(name=name,whole_candidate=candidate,status='rejected',cause=str(error)))
        else:raise ValueError('accepted hostile unchanged observer acceptance')
    checks=load('checks.json')
    stdout={
        'current-publication':'PASS current class/frame facts, complete current source/query allocation and unchanged capacity/source contracts.\n',
        'native-sources':'book-source-references: complete source/role/member/relative-endpoint/current-byte/ignore contracts hold\n',
        'source-index':'book-source-index: complete indexed directory and checked source projection agree\n'}
    for name,stream in stdout.items():
        actual=checks[name]
        need(type(actual['status']) is int and actual['status']==0 and actual['stdout']==stream and actual['stderr']=='',
             'complete actual final maintained/native/source result: '+name)
    focused=checks['focused'];python=checks['focused-python-qualified'];first=checks['focused-python']
    need(type(focused['status']) is int and focused['status']==0 and 'All tests successful.\nFiles=2, Tests=308,' in focused['stdout']
         and focused['stdout'].endswith('Result: PASS\n') and focused['stderr']=='','complete focused public/matrix result')
    need(type(python['status']) is int and python['status']==0 and python['stdout']=='' and
         python['stderr'].startswith('.'*17+'\n') and python['stderr'].endswith('\nOK\n'),'complete focused Python result')
    need(type(first['status']) is int and first['status']==1 and 'unique complete current and retained publication guidance' in first['stderr']
         and 'FAILED (failures=4, errors=2)' in first['stderr'],'complete actual first guide mismatch retained')
    repair=load('guide-repair.json')
    need(repair['whole_first_guide']==repair['whole_qualified_guide'].replace('original-header','observer-current'),
         'complete exact broad-label-replacement root cause')
    import book,book_qualified
    need(repair['whole_first_guide']==book.ADDITION and repair['whole_qualified_guide']==book_qualified.ADDITION==
         (BASE/'guide.txt').read_text(),'complete original/repaired programme and maintained guide equality')
    need((BASE/'first-book-source.md.txt').read_bytes()==book.source()[1][str(book.CHAPTER)] and
         (book_qualified.CHAPTER.read_bytes() if current else json.loads(gzip.decompress((BASE/'current-input.json.gz').read_bytes()))['chapter'].encode())==book_qualified.source()[1][str(book.CHAPTER)],'complete first/current source products conserve with exact correction')
    need(gzip.decompress((BASE/'first-native-chapter.html.gz').read_bytes()).count(b'and observer-current children reexecute')==1,
         'complete actual first native guide retained in its failed role')
    return dict(contracts=pin(canonical(contracts)),review=proposal,original_header_result=independent,
        first_admission=pin(canonical(controls)),fresh_prerequisites=pin((BASE/'prerequisites.json').read_bytes()),
        parent_controls=interventions,actual_checks={k:checks[k] for k in (*stdout,'focused','focused-python-qualified')},
        guide_repair=repair,scope=SCOPE,
        legs=dict(rederive='Fresh complete source/value/header/framework/helper/inventory semantic readers plus independent whole-source/argument/allocation and proposition/question reconstruction.',
                  falsify='Actual full known-token versus limited-prefix intervention, complete raw join controls, pre-seal semantic proposal controls and whole unchanged parent/child/actual-result refusals.',
                  durability='Fixed source Git epoch, complete prior/current products and programme epochs, all original contracts, immutable preparation and final saved reader; current currency remains separately replayable.'))


if __name__=='__main__':
    save('acceptance-proof.json',derive())
    print('PASS complete unchanged observer parent and all descendants, whole original encoded/source semantics, independent non-growing publication and genuine actual controls; only finite observer nodes may close.')
