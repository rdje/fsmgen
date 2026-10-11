"""Replay complete dated prerequisite and predecessor acceptance from retained bytes."""
import argparse
import copy
import gzip
import json
import stat
from html.parser import HTMLParser
from pathlib import Path
import book
import display_checkpoint as display
import intake
import predecessors
import replay
from common import BASE, CLASS, OBSERVER, OWNER, RAW, REVISION, SCOPE, canonical, load, need, pin, save

SUCCESS='PASS complete dated raw prerequisite and unchanged observer/class-frame predecessor acceptance; full source/native/product custody, fresh actual readers, genuine association/archive/receipt controls and current/book evidence qualify. Aggregate raw semantics and original native/private identities remain open.\n'


def members():
    root=Path.cwd().resolve();result={}
    need(BASE.resolve()==root/BASE and not (BASE/'.git').exists(),'own complete raw prerequisite namespace root')
    for path in sorted(BASE.rglob('*')):
        mode=path.lstat().st_mode
        need(stat.S_ISREG(mode) and path.resolve()==root/path and path.stat().st_dev==root.stat().st_dev,
             'complete flat regular raw prerequisite member graph without hidden directories')
        if path.name not in ('manifest.json','checks.json'):
            result[str(path.relative_to(BASE))]=dict(**pin(path.read_bytes()),executable=bool(mode&0o111))
    return result


def actual_readers():
    product=load('readers.json');specs=replay.specifications()
    need(set(product['readers'])==set(specs) and product['revision']==REVISION and product['scope']==SCOPE,
         'complete fresh prerequisite reader population and original scope')
    for name,spec in specs.items():
        entry=product['readers'][name];path=Path(entry['receipt'])
        need(path.parent==BASE and entry['specification']==spec and pin(path.read_bytes())==entry['identity'],
             'complete actual prerequisite receipt and authority')
        replay.qualify(json.loads(path.read_bytes()),spec)
    first=next(iter(specs));entry=product['readers'][first];original=json.loads(Path(entry['receipt']).read_bytes())
    results=[]
    for name,mutate,cause in (
        ('Boolean-status',lambda x:x.update(status=True),'actual integer prerequisite success'),
        ('nonzero-status',lambda x:x.update(status=1),'actual integer prerequisite success'),
        ('borrowed-command',lambda x:x.update(command=['python3','-B','borrowed-reader.py']),'exact whole prerequisite command'),
        ('short-success-stream',lambda x:x.update(stdout='PASS\n'),'whole declared prerequisite stdout role')):
        candidate=copy.deepcopy(original);mutate(candidate);need(candidate!=original,'genuine prerequisite actual-result intervention')
        try:replay.qualify(candidate,specs[first])
        except ValueError as error:
            need(str(error)==cause,'intended actual prerequisite result refusal')
            results.append(dict(name=name,candidate=pin(canonical(candidate)),status=1,cause=cause))
        else:raise ValueError('false-green actual prerequisite result')
    return dict(readers=pin(canonical(product)),actual_result_controls=results)


def archived_recovery_controls():
    product=load('recovery-controls.json');wanted=intake.recovery()
    need(product['fixed_catalog']==wanted and product['original']==wanted['archive'],'whole recovered archive/control source custody')
    results=product['actual_results']
    need([row['name'] for row in results]==['complete','missing','changed-tail'],'whole required-archive actual control population')
    for row in results:
        need(type(row['status']) is int,'actual archive control integer status')
        if row['name']=='complete':
            need(row['status']==0 and row['stderr']=='' and row['stdout']==str(pin(canonical(wanted)))+'\n',
                 'complete real archive positive result')
        else:
            need(row['status']!=0 and row['stdout']=='' and row['cause'] in row['stderr'],
                 'complete real archive missing/changed refusal')
    diagnosis=load('intake-member-diagnosis.json')
    need(diagnosis==dict(missing=[],extra=[intake.RECOVERY]),'whole original Git durability gap diagnosis')
    initial=load('actual-intake-1.json')
    need(type(initial['status']) is int and initial['status']!=0 and initial['stdout']==''
         and 'complete current and fixed raw prerequisite member graph' in initial['stderr'],
         'original actual complete intake failure retained')
    return pin(canonical(product))


def dated_display():
    expected,_=display.expected();actual=load('display-checkpoint.json')
    need(actual['members']==actual['before']==actual['after']==expected
         and actual['fixed_revision']==REVISION and actual['original_instrument_revision']==display.ORIGINAL
         and actual['command']==['python3','-B',str(display.DISPLAY/'verify.py')]
         and actual['cwd']==str(display.ROOT) and type(actual['status']) is int and actual['status']==0
         and actual['stderr']=='' and actual['stdout']==replay.terminal(display.DISPLAY/'verify.py'),
         'whole actual complete historical display reader and original instrument epoch')
    failed=load('actual-reader-observer-public-display-1.json')
    need(type(failed['status']) is int and failed['status']!=0 and failed['stdout']==''
         and 'every direct instrument belongs to a retained exact source epoch' in failed['stderr'],
         'complete original historical/current display boundary refusal retained')
    command=['python3','-B',str(BASE/'display_checkpoint.py'),'--replay']
    import subprocess
    result=subprocess.run(command,capture_output=True,text=True)
    need(type(result.returncode) is int and result.returncode==0 and result.stderr==''
         and result.stdout==actual['stdout']+display.SUCCESS,'fresh whole unchanged dated display execution without namespace mutation')
    return dict(actual=pin(canonical(actual)),fresh_command=command,status=result.returncode,
                stdout=result.stdout,stderr=result.stderr,scope='Whole original direct instrument context only; no current/native currency is inferred.')


def locality():
    product=load('locality-controls-qualified.json');before,after=product['actual']
    need([before['name'],after['name']]==['before','after'] and
         all(type(row['status']) is int and row['status']==1 and pin(row['programme'].encode())==row['programme_identity']
             for row in (before,after)), 'complete actual typed locality control and whole programme epochs')
    need(before['programme'].encode()==(BASE/'display-checkpoint-before-locality.py.txt').read_bytes()
         and after['programme'].encode()==(BASE/'display_checkpoint.py').read_bytes(),
         'original and final corrected checkpoint programmes are exactly the tested sources')
    need(set(before['observed_members'])=={'checkpoint/README.md'} and after['observed_members']=={}
         and before['cause']=='own same-volume dated display checkpoint graph'
         and after['cause']=='plain own dated checkpoint path before any write',
         'actual old alias write and corrected refusal before any member creation')
    return pin(canonical(product))


def input_directories():
    import subprocess
    import intake_directory_controls as controls
    product=load('intake-directory-controls.json')
    need(product['original_programme']==pin((BASE/'intake-before-directory-graph.py.txt').read_bytes())
         and product['corrected_programme']==pin((BASE/'intake.py').read_bytes()),
         'exact original and final tested input-directory programme epochs')
    diagnosis=load('intake-directory-diagnosis.json')
    need(all(product[key]==value for key,value in diagnosis.items()),
         'complete original actual input-directory false green retained')
    command=['python3','-B',str(BASE/'intake_directory_controls.py'),'--replay']
    result=subprocess.run(command,capture_output=True,text=True)
    need(type(result.returncode) is int and result.returncode==0 and result.stderr==''
         and result.stdout==controls.SUCCESS,'fresh complete actual input-directory control replay')
    return dict(command=command,status=result.returncode,stdout=result.stdout,stderr=result.stderr,
                product=pin(canonical(product)))


def publication():
    before,after=book.source();saved=load('book-publication-qualified.json')
    need(saved==dict(revision=REVISION,before={k:pin(v) for k,v in before.items()},
                    after={k:pin(v) for k,v in after.items()},authority=book.authority(before,after),addition=book.ADDITION),
         'entire original/proposed book and unchanged peer authority')
    raw=gzip.decompress((BASE/'book-native-final.html.gz').read_bytes());native=load('book-native-final.json')
    need(pin(raw)==native['chapter'] and native['addition']==pin(book.ADDITION.encode()),'whole retained original native guide bytes')
    class Text(HTMLParser):
        def __init__(self):super().__init__();self.parts=[]
        def handle_data(self,value):self.parts.append(value)
    reader=Text();reader.feed(raw.decode())
    need(book.ADDITION.count("today's")==1,'independent sole native book apostrophe seam')
    phrase=' '.join(line for line in book.ADDITION.replace("today's",'today’s',1).splitlines() if not line.startswith('```'))
    need(' '.join(''.join(reader.parts).split()).count(' '.join(phrase.split()))==1,'whole native prerequisite guide independently reconstructs')
    task=gzip.decompress((BASE/'qualified-task.md.gz').read_bytes()).decode()
    predecessors.qualify_contracts(load('predecessors.json')['contracts'],task)
    nodes=predecessors.blocks(task)
    need(all('  Status: `done`\n' in nodes[key] for key in (CLASS,OBSERVER,OWNER))
         and all('  Status: `active`\n' in nodes[key] for key in (RAW,RAW+'.5'))
         and '  Status: `pending`\n' in nodes[RAW+'.5.2'], 'only qualified finite predecessors close before raw semantics')
    old=[json.loads(line) for line in intake.git('show',REVISION+':'+str(book.REGISTRY)).splitlines()]
    current=[json.loads(line) for line in (BASE/'qualified-registry.txt').read_bytes().splitlines()]
    need(len(old)==len(current),'complete original and qualified capacity authority population')
    for previous,qualified in zip(old,current,strict=True):
        wanted=copy.deepcopy(previous)
        if previous.get('surface_id')=='shipped_behavior':wanted['reference_contract']['aggregate_change']=book.authority(before,after)
        if previous.get('surface_id')=='task_evidence':
            actual_lines=max(len(task.splitlines()),previous['baseline']['lines_each'])
            wanted['transition']['max_growth']['lines_each']=max(previous['transition']['max_growth']['lines_each'],
                actual_lines-previous['baseline']['lines_each']+previous['transition']['ratchet_step']['lines_each'])
        need(qualified==wanted,'whole unchanged capacity/ceilings/Knowledge Map authority except exact owned book/task allowance')
    return dict(book=pin(canonical(saved)),native=pin(raw),task=pin(task.encode()),registry=pin((BASE/'qualified-registry.txt').read_bytes()))


def checks(final=True):
    saved=load('checks.json');required={'focused-corrected','current-tests','book-build-terminal','current-native-final','root-history','source-copies-final','source-index'}
    if final:required.add('claims-final')
    need(required<=set(saved),'complete current/focused/book/native/source/claim gate population')
    for name in required:
        row=saved[name]
        need(type(row['status']) is int and row['status']==0 and type(row['stdout']) is str and type(row['stderr']) is str,
             'actual complete typed successful prerequisite gate')
        if 'inputs_after' in row:
            need(row['epoch_conserved'] is True and row['inputs_after']==row['inputs'],
                 'complete actual final gate source epoch conserved')
        if 'programmes' in row:
            own={path:identity for path,identity in row['inputs'].items() if Path(path).parent==BASE}
            need(set(row['programmes'])==set(own)
                 and all(pin(entry['body'].encode())==entry['identity']==own[path]
                         for path,entry in row['programmes'].items()),
                 'whole retained direct gate programme source bodies')
    need('programmes' in saved['book-build-terminal'],
         'final book build has complete programme-body durability')
    need('All tests successful.' in saved['focused-corrected']['stdout'] and '\nOK\n' in saved['current-tests']['stderr'],
         'whole actual focused test success')
    need(saved['current-native-final']['command']==['python3','-B','scripts/check_record_value_publication.py','--build','docs/book/book']
         and saved['current-native-final']['stdout']=='PASS current class/frame facts, complete current source/query allocation and unchanged capacity/source contracts.\n',
         'complete current/native publication actual command and result')
    # These are command outcomes at their recorded programme/input epoch,
    # never an assertion that old native captures were executed again.
    return {name:pin(canonical(saved[name])) for name in sorted(required)}


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--seal',action='store_true');args=parser.parse_args()
    if (BASE/'manifest.json').exists():need(canonical(load('manifest.json'))==canonical(members()),'entire strict immutable raw prerequisite namespace')
    complete=intake.derive();need(canonical(complete)==canonical(load('intake-qualified.json')),'whole complete fixed/current raw prerequisite intake and explicit recovered payload')
    first=load('intake.json')
    need(first['recovery']==complete['recovery'] and first['task']==complete['task']
         and all(complete['members'].get(path)==entry for path,entry in first['members'].items()),
         'entire earlier selected intake retains inside qualified complete direct-instrument domain')
    predecessors.main()
    import subprocess
    control_command=['python3','-B',str(BASE/'namespace_controls.py'),'--replay']
    control=subprocess.run(control_command,capture_output=True,text=True)
    need(type(control.returncode) is int and control.returncode==0 and control.stderr==''
         and control.stdout=='PASS complete actual positive and hidden-directory/nested-file/symlink/missing/changed-tail/typed-kind namespace refusals with independent whole candidate census.\n',
         'fresh complete actual strict namespace hostile control replay')
    proof=dict(revision=REVISION,owner=OWNER,scope=SCOPE,predecessors=pin((BASE/'predecessors.json').read_bytes()),
               actual_readers=actual_readers(),archive_controls=archived_recovery_controls(),dated_display=dated_display(),publication=publication(),checks=checks(),
               namespace_controls=dict(command=control_command,status=control.returncode,stdout=control.stdout,stderr=control.stderr,
                                       product=pin((BASE/'namespace-controls.json').read_bytes())),
               locality_controls=locality(),input_directory_controls=input_directories())
    if (BASE/'proof.json').exists():need(canonical(load('proof.json'))==canonical(proof),'whole complete dated raw prerequisite proof')
    else:save('proof.json',proof)
    if args.seal:need(not (BASE/'manifest.json').exists(),'raw prerequisite seal append once');save('manifest.json',members())
    print(SUCCESS,end='')


if __name__=='__main__':main()
