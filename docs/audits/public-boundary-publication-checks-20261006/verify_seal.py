"""Independently consume the actual current publication result and whole seal."""
import copy
import json
import re
from pathlib import Path

BASE=Path('docs/audits/record-value-public-boundary-publication-20261006')
CHECKS=Path('docs/audits/public-boundary-publication-checks-20261006')
ns={'__name__':'independent_publication_result'}
exec(compile((BASE/'verify.py').read_bytes(),str(BASE/'verify.py'),'exec'),ns)
require,same,identity,load=(ns[k] for k in ('require','same','identity','load'))
COMMAND=['scripts/run_with_ram_guard.sh','--','python3','-B',str(BASE/'verify.py'),'--current',
         '--build','.artifacts/public-boundary-publication-book','--seal']


def members():
    return {Path(p).name:identity(raw) for p,raw in ns['whole'](BASE).items()}


def header(receipt):
    require(type(receipt['status']) is int and receipt['status']==0,'actual publication integer success')
    require(receipt['command']==COMMAND and receipt['stdout']==ns['CURRENT_SUCCESS'],'exact actual current publication command/result')
    require(re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n',receipt['stderr']) is not None,
            'actual current publication default-guard diagnostics')
    require(all(type(p['bytes']) is int and p['bytes']>=0 for p in receipt['whole_members'].values()),'actual publication member byte-count kinds')
    actual=members();require(same(receipt['whole_members'],actual),'whole actual publication result member pins')
    raw=load(CHECKS/'seal-command-final.json')
    require(same(receipt['actual_result_identity'],identity((CHECKS/'seal-command-final.json').read_bytes()))
            and same({k:receipt[k] for k in raw},raw),'whole raw actual publication result identity')
    require(set(raw['instruments'])=={str(CHECKS/'run.py'),'scripts/run_with_ram_guard.sh',str(BASE/'verify.py')}
            and all(same(pin,identity(Path(p).read_bytes())) for p,pin in raw['instruments'].items()),
            'whole invocation-time publication instrument identities')
    require(same(load(BASE/'manifest.json'),ns['members']()),'whole immutable current publication manifest')
    return actual


def roles():
    record=load(CHECKS/'live-roles.json')
    require(record['restored'] is True and same(record['programme_identity'],identity((CHECKS/'live_checks.py').read_bytes())),
            'whole actual live role programme/restoration identity')
    expected=(
        ('retention',['python3','-B',str(ns['RETENTION']/'verify.py'),'--live-unchanged'],1,'live card remains unchanged before publication'),
        ('superseded_snapshot',['python3','-B','docs/audits/record-value-own-boundary-publication-20261005/verify.py'],0,'PASS immutable own-boundary source publication'),
        ('superseded_current',['python3','-B','docs/audits/record-value-own-boundary-publication-20261005/verify.py','--current'],1,'whole current source/role/question/reader epoch'),
        ('progress',['python3','-B',str(BASE/'verify.py'),'--current'],0,ns['CURRENT_SUCCESS']),
    )
    for role,command,status,token in expected:
        result=record[role]
        require(type(result['status']) is int and result['status']==status and result['command']==command
                and token in result['stdout' if status==0 else 'stderr'],'actual scoped reader role: '+role)
    publication=load(BASE/'publication.json')
    require(record['source_before'][ns['CHAPTER']]==publication['chapter_after'],'whole unrelated progress source chapter')
    require(record['candidate_chapter']==record['source_before'][ns['CHAPTER']]+'\n<!-- Owned unrelated-progress qualification; restored before commit. -->\n',
            'whole actual unrelated chapter intervention')
    candidate=copy.deepcopy(publication['snapshot']);candidate['chapter']=record['candidate_chapter'];ns['check_current'](candidate)
    book={p:raw for p,raw in ns['committed']('docs/book/src').items() if Path(p).parent==Path('docs/book/src') and p.endswith('.md')}
    book[ns['CHAPTER']]=record['candidate_chapter'].encode()
    surface=next(json.loads(s) for s in record['candidate_registry'].splitlines() if json.loads(s).get('surface_id')=='shipped_behavior')
    change=surface['reference_contract']['aggregate_change']
    require(same(change['baseline'],publication['baseline']) and same(change['delta'],
        {k:ns['metrics'](book)[k]-publication['baseline'][k] for k in publication['baseline']}),
        'whole independently measured unrelated progress book authority')
    # Old predicates, not a borrowed root success, establish the exact epoch refusal.
    old=ns['module'](Path('docs/audits/record-value-own-boundary-publication-20261005/verify.py'))
    p=load(Path('docs/audits/record-value-own-boundary-publication-20261005/publication.json'))
    paths=(old['publisher'].CORE,old['publisher'].HELPER,old['publisher'].TOOLING)
    try:
        old['check_live'](p,{path:ns['expected_card']() if path==ns['CARD'] else ns['git'](path).decode() for path in paths},
                          {},publication['chapter_after'],'',{})
    except ValueError as error:
        require(str(error)=='whole current source/role/question/reader epoch','independent old current semantic refusal')
    else: raise ValueError('false-green superseded current semantic role')
    require(ns['expected_card']().encode()!=ns['git'](ns['CARD']),'independent retained live-unchanged refusal')


def check(receipt):
    before=header(receipt)
    ns['authenticate']()
    require(same(ns['source_proof'](),load(BASE/'source-proof.json')),'regenerated whole publication source/snapshot proof')
    snapshot=load(BASE/'publication.json')['snapshot'];ns['check_current'](snapshot)
    require(same(ns['controls'](snapshot),load(BASE/'controls.json')),'regenerated genuine current publication controls')
    require(same(ns['native_proof']((BASE/'native-input.html').read_text()),load(BASE/'native-proof.json')),
            'regenerated whole native guide snapshot and controls')
    roles()
    first=load(CHECKS/'publish.json')
    extras=sorted(p for p in ns['committed']('docs/decisions') if not p.endswith('.md'))
    require(type(first['status']) is int and first['status']==1 and 'complete clean decision source question population' in first['stderr']
        and extras==['docs/decisions/current/catalog.json','docs/decisions/history/0001-0050.json','docs/decisions/history/transition-originals.json']
        and 'decision_source = ns[\'committed\'](\'docs/decisions\')' in (CHECKS/'first-prepare.py.txt').read_text(),
        'whole retained first source-domain failure and exact fixed-source cause')
    require(same(before,header(receipt)),'every sealed publication byte conserved after independent consumption')
    failure=load(CHECKS/'current-diagnostic.json')
    require(type(failure['status']) is int and failure['status']==1 and "NameError: name '__file__' is not defined" in failure['stderr']
        and same(failure['instruments'][str(BASE/'verify.py')],identity((CHECKS/'first-module-verify.py.txt').read_bytes())),
        'whole actual first source-checker loader failure and invocation instrument')
    initial=ns['module'](CHECKS/'first-module-verify.py.txt')
    try: initial['module'](Path('scripts/book_source_references.py'))
    except NameError as error: require(str(error)=="name '__file__' is not defined",'independently reproduced source loader cause')
    else: raise ValueError('false-green first source checker loader')
    plane=ns['module'](Path('scripts/book_source_references.py'))
    require(plane['ROOT']==Path.cwd(),'source checker repository root survives module load')
    first_wrapper=load(CHECKS/'live-checks-command.json')
    require(first_wrapper['status']==1 and 'actual unrelated book progress current acceptance' in first_wrapper['stderr']
        and same(first_wrapper['instruments'][str(CHECKS/'live_checks.py')],identity((CHECKS/'first-live-checks.py.txt').read_bytes())),
        'whole retained initial wrapper failure and invocation instrument')
    # Its child streams were not retained. The standalone invocation above
    # supplies the diagnosed loader result; never invent the missing streams.
    stopped=load(CHECKS/'seal-command.json')
    require(type(stopped['status']) is int and stopped['status']==137 and stopped['command']==COMMAND
        and stopped['stdout']=='' and re.search(r'ram-guard: host memory [0-9]+\.[0-9]+% reached cutoff 88%\n',stopped['stderr'])
        and same(stopped['instruments'][str(BASE/'verify.py')],identity((BASE/'verify.py').read_bytes())),
        'whole retained stopped final seal and unchanged default host cutoff')
    stale=load(CHECKS/'seal-command-retry.json')
    require(type(stale['status']) is int and stale['status']==1 and stale['command']==COMMAND
        and 'fresh whole native copied source bytes' in stale['stderr']
        and same(stale['instruments'][str(BASE/'verify.py')],identity((BASE/'verify.py').read_bytes())),
        'actual stale current native copy refusal and invocation instrument')
    mismatch=load(CHECKS/'stale-native-proof.json')
    require([r['source'] for r in mismatch]==['MEMORY.md','docs/TASK_TREE.md'],'complete actual stale native copy census')
    for row in mismatch:
        a,b=(Path(row[role+'_path']).read_bytes() for role in ('copied','current'))
        require(a!=b and same(row['copied_identity'],identity(a)) and same(row['current_identity'],identity(b)),
            'whole actual stale/current native source identities')


def main():
    receipt=load(CHECKS/'sealed-replay.json');check(receipt);controls=[]
    def refuse(name,candidate,cause):
        try: header(candidate)
        except ValueError as error:
            require(str(error)==cause,'intended actual publication result refusal: '+name)
            controls.append(dict(control=name,status=1,cause=cause))
        else: raise ValueError('false-green actual publication result: '+name)
    for status in (True,0.0,1):
        refuse('status-'+repr(status),{**receipt,'status':status},'actual publication integer success')
    for count in (True,0.0):
        candidate=copy.deepcopy(receipt);next(iter(candidate['whole_members'].values()))['bytes']=count
        refuse('byte-count-'+repr(count),candidate,'actual publication member byte-count kinds')
    candidate=copy.deepcopy(receipt);candidate['whole_members'].pop(next(iter(candidate['whole_members'])))
    refuse('lost-whole-member',candidate,'whole actual publication result member pins')
    refuse('invented-guard-authority',{**receipt,'stderr':receipt['stderr'].replace('cutoff 88%','cutoff 99%')},
           'actual current publication default-guard diagnostics')
    borrowed=load(ns['RETAINED_RESULT']/'sealed-replay.json')
    require(type(borrowed['status']) is int and borrowed['status']==0,'genuine retained proposal-only success')
    refuse('borrowed-retention-snapshot-success',borrowed,'exact actual current publication command/result')
    refuse('borrowed-stopped-seal',load(CHECKS/'seal-command.json'),'actual publication integer success')
    print('PASS independently consumed actual current publication seal, whole regenerated source/control/native/role products and typed/member/borrowed-result refusals.')
    for row in controls: print(row['control']+': refused at '+row['cause'])


if __name__=='__main__': main()
