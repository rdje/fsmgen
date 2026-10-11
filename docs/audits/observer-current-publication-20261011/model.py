"""Independent first-admission authority for complete observer publication."""
import copy
import gzip
import json
import re
import subprocess
from pathlib import Path
from common import BASE, REPAIR, REVISION, SCOPE, canonical, inputs, load, need, pin, save, same
import prepare

CARD=prepare.CARD
OWNER='SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.5.3'
BEFORE={'bytes':4272,'sha256':'9ff5e9d8edd6953233271bc0659b74429f52921f33d652e2f19e910691c338b0'}
AFTER={'bytes':4267,'sha256':'84ce9b85468778f4335125034692b6d443627e74650b4e83f0bd560f5fdee758'}
REVIEW={'bytes':10567,'sha256':'9ed555955fb6db8a4cb6c1c9c6953cc5c8e0d179ceec1ee4338d3751e20e63ab'}
TASK=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')


def frontmatter(raw):
    text=raw.decode();head=text.split('---',2)[1]
    questions=re.findall(r'^  - "(.*)"$',head,re.M)
    return head,questions


def qualify(candidate, before, after, review):
    need(type(candidate) is dict and set(candidate)=={'schema','root','owner','revision','scope','card','question','before','after','review','layout','registry','source_population'},'closed complete observer proposal schema')
    need(candidate['root']=='.' and candidate['card']==CARD,'fixed repository-relative observer source authority')
    need(candidate['schema']=='complete-observer-publication-v1' and candidate['owner']==OWNER and candidate['revision']==REVISION,'fixed unchanged observer publication owner and epoch')
    need(candidate['scope']==SCOPE,'complete finite scope and all unchanged native/private/open successors')
    need(type(before) is bytes and pin(before)==BEFORE==candidate['before']==pin(prepare.git(CARD)),'whole fixed original observer topic')
    need(type(after) is bytes and pin(after)==AFTER==candidate['after'],'whole reviewed target meanings and native uncertainty')
    need(type(review) is dict and pin(canonical(review))==REVIEW==candidate['review'],'whole explicit proposition review')
    need(candidate['question']==prepare.QUESTION,'fixed one broad complete-header question')
    original,old_questions=frontmatter(before);proposed,new_questions=frontmatter(after)
    need(new_questions==old_questions+[prepare.QUESTION],'all original ordered questions and one declared new question')
    # Removing only the declared date, new answer and evidence addition restores
    # the complete original metadata, including every prior replay route.
    restored=proposed.replace('  - "'+prepare.QUESTION+'"\n','',1).replace('date: 2026-10-11\n','date: 2026-10-10\n',1)
    restored=restored.replace('  docs/audits/observer-original-header-join-20261011/proof.json;\n','',1)
    need(restored==original,'whole original metadata evidence and replay routes')
    need(review['rows']==prepare.review(before,after) and review['new_scope']==SCOPE,'every original proposition mapped to complete reviewed text')
    need(all(prepare.metrics(after)[k]<=v for k,v in prepare.metrics(before).items()),'unchanged non-growing card dimensions')
    regenerated,layout=prepare.final_card()
    need(regenerated==after and layout==load('final-layout.json') and pin(canonical(layout))==candidate['layout'],'complete reproducible non-growing layout')
    registry=(BASE/'before-registry.jsonl.txt').read_bytes()
    need(registry==prepare.git(prepare.REGISTRY) and pin(registry)==candidate['registry'],'whole fixed unchanged collection authority')
    compressed=(BASE/'before-canonical.json.gz').read_bytes()
    need(pin(compressed)==candidate['source_population'],'whole retained original canonical population')
    sources=json.loads(gzip.decompress(compressed))
    need(sources[CARD].encode()==before,'whole topic in complete retained source population')
    return dict(before=prepare.metrics(before),after=prepare.metrics(after),scope=SCOPE)


def block(text,identifier):
    marker='- ID: `'+identifier+'`\n';need(text.count(marker)==1,'unique complete observer owner')
    start=text.index(marker);end=text.find('\n- ID:',start+1)
    return text[start:end if end>=0 else len(text)]


def fields(body):
    return {key:re.search(r'^  '+key+r': `(.*)`$',body,re.M).group(1)
            for key in ('Goal','Acceptance','Children') if re.search(r'^  '+key+':',body,re.M)}


def contracts(current=None):
    original=prepare.git(str(TASK)).decode();parent=OWNER.rsplit('.',1)[0];pending=[parent];rows={}
    while pending:
        identifier=pending.pop();body=block(original,identifier);rows[identifier]=body
        pending.extend(re.findall(r'SEMANTIC-INTROSPECTION-MCP-FRONTIER[.0-9]*',fields(body).get('Children','')))
    text=TASK.read_text() if current is None else current
    for identifier,old in rows.items():
        actual=block(text,identifier)
        need(fields(actual)==fields(old),'whole unchanged observer parent and every descendant contract')
        if identifier not in (OWNER,parent):
            need('\n  Status: `done`\n' in actual,'every prerequisite observer descendant complete before publication')
    return dict(revision=REVISION,original_bodies=rows,scope=SCOPE)


def hostile_controls(proposal,before,after,review):
    cases=[]
    def check(name,candidate,b=before,a=after,r=review,cause=None):
        need(not same(candidate,proposal) or b!=before or a!=after or not same(r,review),'genuine first-admission intervention')
        try: qualify(candidate,b,a,r)
        except ValueError as error:
            need(str(error)==cause,'intended independent first-admission refusal: '+name)
            cases.append(dict(name=name,proposal=candidate,before=b.decode(),after=a.decode(),review=r,cause=str(error),status='rejected'))
        else: raise ValueError('accepted hostile first-admission observer publication: '+name)
    for name,key,value,cause in [
        ('foreign-root','root','..','fixed repository-relative observer source authority'),
        ('foreign-card','card','docs/knowledge/borrowed.md','fixed repository-relative observer source authority'),
        ('borrowed-owner','owner',OWNER+'.1','fixed unchanged observer publication owner and epoch'),
        ('narrowed-scope','scope','full native acceptance','complete finite scope and all unchanged native/private/open successors'),
        ('lost-new-question','question','borrowed?','fixed one broad complete-header question')]:
        candidate=copy.deepcopy(proposal);candidate[key]=value;check(name,candidate,cause=cause)
    for name,old,new in [
        ('native-promotion','native identity unmeasured','native identity qualified'),
        ('lost-old-meaning','forwards callback arguments to the body','forwards no arguments to the body'),
        ('lost-old-question','  - "what qualifies original named helper inputs defaults and active paths?"\n',''),
        ('lost-replay','scripts/check_record_value_publication.py','scripts/borrowed.py'),
        ('prefix-only','Complete headers join full source expressions','Prefix headers join selected source expressions')]:
        need(after.count(old.encode())==1,'genuine known complete meaning intervention')
        altered=after.replace(old.encode(),new.encode(),1);candidate=copy.deepcopy(proposal);candidate['after']=pin(altered)
        check(name,candidate,a=altered,cause='whole reviewed target meanings and native uncertainty')
    candidate=copy.deepcopy(proposal);altered=copy.deepcopy(review);altered['rows'].pop();candidate['review']=pin(canonical(altered))
    check('lost-whole-review',candidate,r=altered,cause='whole explicit proposition review')
    return cases


def main():
    proposal=load('proposal.json');before=(BASE/'before-card.md.txt').read_bytes();after=(BASE/'published-card.md.txt').read_bytes();review=load('review.json')
    need(not (BASE/'admission-manifest.json').exists(),'genuine first admission precedes any seal')
    result=qualify(proposal,before,after,review)
    task=contracts();save('contracts.json',task)
    controls=hostile_controls(proposal,before,after,review);save('first-admission-controls.json',controls)
    draft_results=[]
    for draft,receipt in [('first-growing-draft.md.txt','first-draft-refusal.json'),('second-draft.md.txt','second-draft-refusal.json'),('third-draft.md.txt','third-draft-refusal.json')]:
        raw=(BASE/draft).read_bytes();actual=load(receipt)
        need(type(actual['status']) is int and actual['status']==1 and 'AssertionError' in actual['output'],'complete actual refused growing draft')
        need(any(prepare.metrics(raw)[k]>v for k,v in prepare.metrics(before).items()),'actual draft violates unchanged dimensions')
        draft_results.append(dict(draft=draft,dimensions=prepare.metrics(raw),receipt=actual))
    save('model-proof.json',dict(result=result,contracts=pin(canonical(task)),controls=pin(canonical(controls)),
         first_admission_without_prior_seal=True,whole_originals_and_draft_refusals=draft_results))
    print('PASS complete unchanged observer acceptance, explicit non-growing proposition/metadata review and genuine pre-seal hostile proposals; no current publication claimed.')


if __name__=='__main__': main()
