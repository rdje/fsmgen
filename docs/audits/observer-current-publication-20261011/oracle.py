"""Separate whole source/question/metadata and actual prerequisite reconstruction."""
import ast
import copy
import gzip
import json
import re
import subprocess
from pathlib import Path
from common import BASE, REPAIR, DIAGNOSIS, REVISION, SCOPE, canonical, load, need, pin, save

CARD='docs/knowledge/record-value-original-observer-helper-paths.md'
QUESTION='what qualifies complete original observer argument headers?'


def git(path):
    result=subprocess.run(['git','--no-replace-objects','show',REVISION+':'+str(path)],capture_output=True)
    need(type(result.returncode) is int and result.returncode==0 and result.stderr==b'','independent complete committed source')
    return result.stdout


def metadata(text):
    lines=text.splitlines()
    if not lines or lines[0]!='---': return None
    stop=lines.index('---',1);header=lines[1:stop]
    ids=[line[4:].strip().strip('"') for line in header if line.startswith('id: ')]
    answers=[];active=False
    for line in header:
        if line.startswith('answers:'):
            rest=line[8:].strip();active=not rest
            if rest: answers.extend(json.loads(rest))
        elif active and line.startswith(' '):
            need(re.fullmatch(r' +\- +.*',line) is not None,'independent answer grammar')
            answers.append(line.strip()[2:].strip('"'))
        elif not line.startswith(' '): active=False
    if not answers:return None
    need(len(ids)==1,'one canonical fact identity')
    return ids[0],answers


def allocation(sources):
    entries={};facts=occurrences=0
    for path,text in sources.items():
        info=metadata(text)
        if info is None:continue
        identifier,answers=info;facts+=1;occurrences+=len(answers)
        for question in answers:entries.setdefault(question,[]).append((identifier,path))
    rows=''.join(question+'\t'+','.join(x[0] for x in sorted(owners))+'\t'+','.join(x[1] for x in sorted(owners))+'\n'
                 for question,owners in sorted(entries.items()))
    return dict(facts=facts,unique_questions=len(entries),answer_occurrences=occurrences,rows=rows)


def actual(record,command,expected_stdout):
    need(type(record) is dict and set(record)=={'command','status','stdout','stderr','programs'},'closed complete fresh semantic receipt')
    need(type(record['status']) is int and record['status']==0,'fresh actual integer success')
    need(record['command']==command and record['stdout']==expected_stdout and record['stderr']=='','whole actual semantic command and streams')
    need(type(record['programs']) is dict and bool(record['programs']),'whole actual programme epoch')
    for path,row in record['programs'].items():
        need(set(row)=={'identity','body'} and pin(row['body'].encode())==row['identity'],'full actual programme bytes')


def prerequisites():
    qualified=load('prerequisites.json');original=json.loads(git(REPAIR/'prerequisites.json'))
    need(qualified['revision']==REVISION and qualified['scope']==SCOPE,'independent complete current prerequisite epoch')
    expected=dict(original['readers'])
    for name,row in qualified['readers'].items():
        receipt=load(row['receipt']);command=receipt['command']
        if name in expected:
            old=json.loads(git(REPAIR/expected[name]['receipt']))
            need(command==old['command'],'unchanged complete prerequisite reader')
            stdout=old['stdout']
        elif name=='complete-original-header-repair':
            old=json.loads(git(REPAIR/'actual-complete-repair-reader-1.json'))
            need(command==old['command'],'complete original-header repair reader')
            stdout=old['stdout']
        elif name=='observer-diagnosis':
            tree=ast.parse(git(DIAGNOSIS/'verify.py'))
            stdout=next(ast.literal_eval(node.value) for node in tree.body if isinstance(node,ast.Assign)
                        and any(isinstance(target,ast.Name) and target.id=='SUCCESS' for target in node.targets))
            need(command==['python3','-B',str(DIAGNOSIS/'verify.py')],'complete observer diagnosis reader')
        else:raise ValueError('unexpected prerequisite reader')
        actual(receipt,command,stdout)
        context='complete fixed committed inputs' if 'dated-' in name else 'current fixed source inputs'
        need(row==dict(context=context,receipt='actual-prerequisite-'+name+'-1.json',identity=pin(canonical(receipt))), 'whole typed current/datable semantic result binding')
    need(set(qualified['readers'])==set(expected)|{'complete-original-header-repair','observer-diagnosis'},'complete original and added prerequisite population')
    for path,row in qualified['fixed'].items():
        raw=git(path)
        need(Path(path).read_bytes()==raw and row==dict(command=['git','--no-replace-objects','show',REVISION+':'+path],status=0,identity=pin(raw)), 'independent whole original/current input binding')
    controls=[];sample=load(next(iter(qualified['readers'].values()))['receipt'])
    for name,field,value,cause in [('boolean-status','status',True,'fresh actual integer success'),
        ('float-status','status',0.0,'fresh actual integer success'),('failed-status','status',1,'fresh actual integer success'),
        ('borrowed-stream','stdout',sample['stdout']+'extra\n','whole actual semantic command and streams'),
        ('hidden-stderr','stderr','warning\n','whole actual semantic command and streams')]:
        candidate=copy.deepcopy(sample);candidate[field]=value
        need(canonical(candidate)!=canonical(sample),'actual receipt intervention')
        try:actual(candidate,sample['command'],sample['stdout'])
        except ValueError as error:
            need(str(error)==cause,'intended complete actual refusal')
            controls.append(dict(name=name,whole_candidate=candidate,status='rejected',cause=str(error)))
        else:raise ValueError('accepted hostile actual receipt')
    return dict(prerequisites=pin(canonical(qualified)),controls=controls,scope=SCOPE)


def source():
    before=json.loads(gzip.decompress((BASE/'before-canonical.json.gz').read_bytes()))
    need(all(git(path).decode()==text for path,text in before.items()),'whole original canonical population compared to fixed Git')
    after=dict(before);after[CARD]=(BASE/'published-card.md.txt').read_text()
    old=metadata(before[CARD]);new=metadata(after[CARD])
    need(new==(old[0],old[1]+[QUESTION]),'independent exact topic and ordered old/new question ownership')
    a=allocation(before);b=allocation(after)
    old_rows={line.split('\t')[0]:line for line in a['rows'].splitlines()};new_rows={line.split('\t')[0]:line for line in b['rows'].splitlines()}
    need(QUESTION not in old_rows and all(new_rows.get(q)==row for q,row in old_rows.items()),'every prior global question and owner conserves')
    need(set(new_rows)==set(old_rows)|{QUESTION} and b['facts']==a['facts'],'only declared question added; physical canonical facts unchanged')
    review=load('review.json');old_body=before[CARD].split('---',2)[2].strip().split('\n\n');new_body=after[CARD].split('---',2)[2].strip().split('\n\n')
    need([r['whole_original'] for r in review['rows']]==old_body,'every whole original proposition reviewed')
    need(all(r['original_index']==i and r['whole_replacements']==[new_body[n] for n in r['replacement_indices']] and bool(r['judgment'])
             for i,r in enumerate(review['rows'])),'independent complete reviewed replacements and qualifiers')
    need(review['retained_probes']==['scripts/run_with_ram_guard.sh -- python3 -B scripts/check_record_value_publication.py',
         'record-value-finite-copy-probe-reader'] and review['new_scope']==SCOPE,'independent probe and uncertainty scope conservation')
    for name,text in [('before',before[CARD]),('after',after[CARD])]:
        need(text.count('reverify: scripts/run_with_ram_guard.sh -- python3 -B scripts/check_record_value_publication.py')==1 and
             text.count('[[record-value-finite-copy-probe-reader]]')==1,'whole original probe roles retain in '+name)
    # Whole word forms retain the exact reviewed conditional grammar and unknowns.
    normalized=' '.join(after[CARD].split())
    for phrase in ['Qualified current literal/quote/escape/truncation/count grammar','authored regex constructor alternatives stay explicit',
       'private intervals conserve whole original bytes without native identity','Original provider/hooks/classes/native addresses',
       'formatter settings/flags/encoding remain unmeasured','Consumer/alias/full-semantic/cold/candidate-parent/permanent/hot/host-native repairs and visual QA remain open']:
        need(phrase in normalized,'independent complete known/unknown meaning: '+phrase)
    return dict(before_allocation=a,after_allocation=b,before_topic=pin(before[CARD].encode()),after_topic=pin(after[CARD].encode()),
         review=pin(canonical(review)),scope=SCOPE)


def main():
    save('independent-source-proof.json',source())
    save('independent-prerequisite-proof.json',prerequisites())
    print('PASS independent whole canonical source, all prior questions/probes, complete reviewed uncertainty and actual prerequisite reconstruction.')


if __name__=='__main__':main()
