"""Independent source-binding traversal, original caller and public controls."""
import copy
import hashlib
import json
import re
import runpy
import subprocess
from pathlib import Path

A = Path('docs/audits')
BASE = A / 'coordinate-observer-caller-20261009'
REVISION = '41985a0f3e72dbfe3e4055c57f150206b29bba2f'
CLASS = A / 'record-value-class-frame-join-20261006'
PHASES = A / 'coordinate-refusal-phases-20261009/phases.json'
EXPRESSION = A / 'coordinate-expression-alternatives-20261009/alternatives.json'
READERS = (A / 'coordinate-original-intake-checks-20261009/verify_intake.py',
           A / 'coordinate-expression-alternative-checks-20261009/verify_alternatives.py')
ROLE = 'Dated complete recorded observer caller association; source operation selection precedes coordinate comparison. No original private formatter/toolchain/identity, external framework, address or alias promotion; complete original matching remains a successor.'


def require(ok, cause):
    if not ok:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def stamp(value):
    return pin(json.dumps(value, sort_keys=True).encode())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def original(path):
    root = Path.cwd().resolve(); full = root / path
    require(full.resolve() == full and full.is_file() and full.stat().st_dev == root.stat().st_dev,
            'independent plain same-volume observer input')
    for parent in full.parents:
        if parent == root:
            break
        require(not (parent/'.git').exists(), 'independent own observer repository boundary')
    run = subprocess.run(['git','--no-replace-objects','cat-file','blob',REVISION+':'+str(path)], capture_output=True)
    require(run.returncode == 0 and not run.stderr and run.stdout == full.read_bytes(), 'whole independent fixed observer source')
    return run.stdout


def declarations(models, phases, expressions):
    cases = {(m['mode'],c['domain'],c['index']):c for m in models['modes'] for c in m['cases']}
    recipes = {r['id']:r for r in expressions['original_recipes']['statements']}
    alternatives = {r['recipe_id']:r for r in expressions['candidates']}
    by_key = {}
    for refusal in phases['refusals']:
        key = refusal['mode'], refusal['domain'], refusal['index']
        case = cases[key]; number = len(case['phases'])-1
        require(case['phases'][number]['phase'] == number, 'independent final recorded source phase')
        operations = case['phases'][number]['own']['operations']
        selected = [(i,op) for i,op in enumerate(operations) if op['kind'] == case['kind']]
        require(len(selected) == 1, 'independent unique recorded source operation')
        index, operation = selected[0]
        matches = {}
        for binding in refusal['phases'][number]['active_path_inner_to_outer']:
            for link in binding['model_links']:
                if link[:3] == ['operations',index,'frames'] and link[3] in (2,3):
                    require(link[3] not in matches, 'independent unique delegate/wrapper binding')
                    matches[link[3]] = binding
        require(set(matches) == {2,3} and len(operation['frames']) == 4
                and all(b['role'] == 'observer' for b in matches.values()), 'independent complete observer source wrapper')
        wrapper, delegate = matches[3], matches[2]
        recipe = recipes[wrapper['caller']['recipe_id']]
        delegate_recipe = recipes[delegate['caller']['recipe_id']]
        text = delegate_recipe['text']
        name = 'parse' if case['kind']=='source' else 'call_api'
        argument = 'source' if case['kind']=='source' else case['kind']
        require(delegate_recipe['unit']=='observer'
                and re.match(r"return "+name+r"\('"+argument+r"',",text)
                and text.count('[caller]')==1, 'independent literal caller snapshot argument')
        unit = expressions['source_units'][recipe['unit']]
        require(recipe['unit'] in ('value','test'), 'independent finite caller package units')
        if recipe['unit']=='value':
            first = unit['body'].splitlines()[0]
            package = re.fullmatch(r'package ([A-Za-z_][A-Za-z0-9_:]*);',first)
            require(package is not None, 'independent original Value package declaration')
            package = package[1]
        else:
            require(not any(line.lstrip().startswith('package ') for line in unit['body'].splitlines()),
                    'independent original default-main caller source')
            package = 'main'
        by_key[key] = {'key':list(key),'kind':case['kind'],'phase':number,'operation_index':index,
            'operation':operation,'wrapper':wrapper,'delegate_recipe':delegate_recipe,
            'caller_recipe':recipe,'caller_package':package,'source_unit':unit,'alternatives':alternatives[recipe['id']]}
    require(set(by_key)==set(cases), 'independent whole source observer domain')
    return [by_key[(m['mode'],c['domain'],c['index'])] for m in models['modes'] for c in m['cases']]


def associations(raw, proofs, declared):
    records = {(m['mode'],d,r['index']):r for m in raw['inventories'] for d,v in m['domains'].items() for r in v['nonempty']}
    positions = {(m['mode'],c['domain'],c['index']):c for m in proofs['modes'] for c in m['cases']}
    require(set(records)==set(positions)=={tuple(d['key']) for d in declared}, 'independent whole original observer allocation')
    result=[]
    for source in declared:
        key=tuple(source['key']);record=records[key]
        phase=positions[key]['phases'][source['phase']]['complete_own_positions']
        links=[link for link in source['wrapper']['model_links'] if link[:3]==['operations',source['operation_index'],'frames']]
        require(len(links)==1 and links[0][3]==3, 'independent original wrapper source link')
        slot=phase['operations'][links[0][1]][links[0][3]]
        frames=[s for s in record['segments'] if s['kind']=='frame'];frame=frames[slot]
        require(record['context']['kind']==source['kind']
                and record['context']['caller']==[source['caller_package'],frame['path'],frame['line']],
                'independent complete original observer caller')
        alternatives=source['alternatives']
        labels=sorted(k for k,v in alternatives['line_alternatives'].items() if v==frame['line'])
        require(type(frame['line']) is int and frame['line']>0
                and frame['path'] in alternatives['filename_alternatives'] and labels,
                'independent original caller source alternatives')
        outer=phase['operations'][-1][3]
        result.append({'key':list(key),'declaration':stamp(source),'whole_original':stamp(record),
            'recorded_context':record['context'],'frame_index':slot,'whole_frame':stamp(frame),
            'matching_line_labels':labels,'outermost_frame_index':outer,
            'old_outer_main_assumption_matches':record['context']['caller']==['main',frames[outer]['path'],frames[outer]['line']]})
    return result


def public():
    baseline=(BASE/'caller.pl').read_bytes()
    variants = [('caller.pl',baseline),
        ('caller-inner-shift.pl',baseline.replace(b"    Observer::operation('capture', sub {return 1});\n\n",
                                                 b"\n    Observer::operation('capture', sub {return 1});\n",1)),
        ('caller-outer-shift.pl',baseline.replace(b"Observer::operation('scope',",b"\nObserver::operation('scope',",1))]
    results=[];observed=[]
    for name,expected_source in variants:
        path=BASE/name;source=path.read_bytes()
        require(source==expected_source, 'complete controlled public caller source transform')
        command=['perl',str(path)];run=subprocess.run(command,capture_output=True,text=True)
        require(type(run.returncode) is int and run.returncode==0 and run.stderr=='', 'actual complete independent public caller result')
        expected=[]
        for kind,package in (('scope','main'),('capture','Caller::Value')):
            marker=("Observer::operation('"+kind+"',").encode()
            require(source.count(marker)==1, 'unique public caller expression')
            expected.append({'kind':kind,'package':package,'file':str(path),'line':source[:source.index(marker)].count(b'\n')+1})
        actual=json.loads(run.stdout)
        require(same(actual,expected), 'independent public caller/package/line selection')
        observed.append(actual)
        results.append({'source':str(path),'identity':pin(source),'command':command,
                        'status':run.returncode,'stdout':run.stdout,'stderr':run.stderr})
    require(observed[1][0]['line']==observed[0][0]['line'] and observed[1][1]['line']==observed[0][1]['line']+1
            and observed[2][0]['line']==observed[0][0]['line']+1 and observed[2][1]['line']==observed[0][1]['line'],
            'distinct inner and outer public caller interventions')
    return results


def check(actual,expected):
    for key in expected:
        require(key in actual and same(actual[key],expected[key]), 'complete independent observer field: '+key)
    require(set(actual)==set(expected), 'closed complete observer product')


def failures(raw,phases,proofs,expressions):
    receipts=json.loads((BASE/'first-checks.json').read_bytes());results=[]
    for name,file,record,error_type,message in (
        ('lookup','first-match.py.txt','first-result.json',TypeError,'list indices must be integers or slices, not str'),
        ('outer-caller','second-match.py.txt','second-result.json',ValueError,'original observer caller snapshot joins outer operation caller')):
        source=(BASE/file).read_bytes();receipt=json.loads((BASE/record).read_bytes())
        key='matching' if name=='lookup' else 'matching-repaired'
        programme='docs/audits/coordinate-original-rematching-20261009/match.py'
        require(same(receipt,receipts[key]) and type(receipt['status']) is int and receipt['status']==1
                and receipt['command']==['scripts/run_with_ram_guard.sh','--','python3','-B',programme]
                and receipt['instruments'][programme]==pin(source) and receipt['stdout']==''
                and error_type.__name__+': '+message in receipt['stderr'], 'complete retained first matcher programme/result')
        try:
            runpy.run_path(str(BASE/file))['derive'](raw,phases,proofs,expressions)
        except error_type as error:
            require(str(error)==message, 'exact whole original first matcher failure reproduction')
        else:
            raise ValueError('first matcher failure unexpectedly accepted')
        results.append({'name':name,'programme':pin(source),'actual_result':pin((BASE/record).read_bytes()),'error':message})
    programme=(BASE/'first-derive.py.txt').read_bytes()
    receipt=json.loads((BASE/'first-source-result.json').read_bytes())
    path=str(BASE/'derive.py')
    require(type(receipt['status']) is int and receipt['status']==1
            and receipt['instruments'][path]==pin(programme)
            and 'ValueError: literal recorded wrapper caller argument' in receipt['stderr'],
            'complete first parser-wrapper assumption failure')
    models=json.loads(original(CLASS/'source-models.json'))
    try:runpy.run_path(str(BASE/'first-derive.py.txt'))['declare'](models,phases,expressions)
    except ValueError as error:
        require(str(error)=='literal recorded wrapper caller argument','actual first parser-wrapper assumption reproduction')
    else:raise ValueError('first parser-wrapper assumption unexpectedly accepted')
    results.append({'name':'parser-wrapper','programme':pin(programme),'actual_result':pin((BASE/'first-source-result.json').read_bytes()),
                    'error':'literal recorded wrapper caller argument'})
    return results


def main():
    paths=[CLASS/'raw-product.json',CLASS/'proofs.json',CLASS/'source-models.json',PHASES,EXPRESSION]
    bodies=[original(p) for p in paths];raw,proofs,models,phases,expressions=map(json.loads,bodies)
    declared=declarations(models,phases,expressions)
    joined=associations(raw,proofs,declared)
    without_snapshots=copy.deepcopy(models)
    for mode in without_snapshots['modes']:
        for case in mode['cases']:
            case['caller']=['borrowed-package','borrowed-file',-1]
    require(same(declarations(without_snapshots,phases,expressions),declared)
            and same(runpy.run_path(str(BASE/'derive.py'))['declare'](without_snapshots,phases,expressions),declared),
            'both source selectors ignore recorded caller coordinate values')
    actual_readers=[]
    for reader in READERS:
        command=['python3','-B',str(reader)];run=subprocess.run(command,capture_output=True,text=True)
        require(type(run.returncode) is int and run.returncode==0 and run.stderr=='', 'complete independent unchanged observer prerequisite')
        actual_readers.append({'command':command,'status':run.returncode,'stdout':run.stdout,
                               'stderr':run.stderr,'programme':pin(original(reader))})
    expected={'revision':REVISION,'owner':(BASE/'scope.txt').read_text().strip(),'role':ROLE,
        'inputs':{str(p):pin(b) for p,b in zip(paths,bodies,strict=True)},'original':raw,
        'declarations':declared,'associations':joined,'actual_readers':actual_readers,
        'finite_public':public(),'unresolved':phases['unresolved'],
        'legs':{'rederive':'derive.py complete fixed source operation and literal caller/package declarations before original-coordinate comparison; complete original context association and actual readers.',
                'falsify':'verify.py independent binding/operation traversal, complete original reconstruction, real public caller interventions and source/context/receipt controls; both first matcher failures reproduce.',
                'durability':'Whole original inventory, exact source declarations, fixed source epoch, both failed programmes/results, sealed association and public fixtures/readers, normal Git commit.'}}
    actual=json.loads((BASE/'association.json').read_bytes());check(actual,expected)
    first=failures(raw,phases,proofs,expressions)
    controls={}
    for name,mutate,field in (
        ('wrong-operation',lambda p:p['declarations'][0].update(operation_index=999),'declarations'),
        ('wrong-package',lambda p:next(r for r in p['declarations'] if r['caller_package']!='main').update(caller_package='main'),'declarations'),
        ('borrowed-source',lambda p:p['declarations'][0]['source_unit'].update(body='borrowed'),'declarations'),
        ('wrong-line',lambda p:p['associations'][0]['recorded_context']['caller'].__setitem__(2,1),'associations'),
        ('lost-context',lambda p:p['associations'].pop(),'associations'),
        ('lost-empty',lambda p:p['original']['inventories'][0]['domains']['api']['empty_string_members'].pop(),'original'),
        ('lost-private-owner',lambda p:p['unresolved'].pop('original_private_formatter_toolchain_identity'),'unresolved'),
        ('Boolean-native-status',lambda p:p['finite_public'][0].update(status=True),'finite_public'),
        ('borrowed-native-stdout',lambda p:p['finite_public'][0].update(stdout='[]\n'),'finite_public'),
        ('borrowed-reader-command',lambda p:p['actual_readers'][0]['command'].append('--foreign'),'actual_readers'),
        ('Boolean-reader-status',lambda p:p['actual_readers'][0].update(status=True),'actual_readers')):
        changed=copy.deepcopy(actual);mutate(changed);require(not same(changed,actual),'genuine observer control: '+name)
        try:check(changed,expected)
        except ValueError as error:
            require(str(error)=='complete independent observer field: '+field, 'intended observer control: '+name)
            controls[name]=str(error)
        else:raise ValueError('false-green observer control: '+name)
    require([original(p) for p in paths]==bodies,'whole original observer input conservation')
    print(json.dumps({'result':'PASS complete independent source-selected original observer callers and public controls',
        'declarations':stamp(declared),'associations':stamp(joined),'old_outer_main_mismatches':[r['key'] for r in joined if not r['old_outer_main_assumption_matches']],
        'source_independence':'both selectors conserve under complete recorded-caller replacement','first_failures':first,'actual_readers':actual_readers,'finite_public':expected['finite_public'],'controls':controls},sort_keys=True))


if __name__=='__main__':
    main()
