"""Independently reconstruct all source-recipe interventions and actual results."""
import copy
import json
import runpy
import subprocess
from pathlib import Path

A=Path('docs/audits');BASE=A/'coordinate-original-hostile-20261009'
CHECKS=A/'coordinate-original-hostile-checks-20261009'
REVISION='32c5f718528c9ca38b72ef0333e26703663674ab'
CLASS=A/'record-value-class-frame-join-20261006';MATCHING=A/'coordinate-original-matching-qualified-20261009'
READER=A/'coordinate-original-matching-qualified-checks-20261009/verify_matching.py'
oracle=runpy.run_path(str(BASE/'oracle.py'))
need,stamp=oracle['require'],oracle['stamp']


def fixed(path):
    root=Path.cwd().resolve();full=root/path
    need(full.resolve()==full and full.is_file() and full.stat().st_dev==root.stat().st_dev,'independent plain same-volume hostile input')
    for parent in full.parents:
        if parent==root:
            break
        need(not (parent/'.git').exists(),'independent own hostile input boundary')
    run=subprocess.run(['git','--no-replace-objects','cat-file','blob',REVISION+':'+str(path)],capture_output=True)
    need(run.returncode==0 and not run.stderr and run.stdout==full.read_bytes(),'complete independent fixed hostile input')
    return run.stdout


def same(a,b):
    return json.dumps(a,sort_keys=True)==json.dumps(b,sort_keys=True)


def check(actual,expected):
    need(set(actual)==set(expected),'closed complete hostile product')
    for key in expected:
        need(same(actual[key],expected[key]),'complete independent hostile field: '+key)


def reconstruct(raw,models,proofs,matched):
    points,bindings=oracle['points'](raw,matched,proofs);pairs=oracle['forwarding'](raw,proofs)
    selected={}
    for point in points:
        selected.setdefault((point['key'][0],point['selection']['recipe_id']),point)
    predecessor=runpy.run_path(str(CLASS/'verify.py'))
    nested=predecessor['public']['context']['nested_records'](models['frame_model']['own'])
    baseline=predecessor['check'](models,models,raw['inventories'],raw['inventories'],nested)
    coordinate=runpy.run_path(str(MATCHING/'verify.py'))['reconstruct']
    derive=runpy.run_path(str(MATCHING/'match.py'))['derive']
    candidates=matched['expression_alternatives']['candidates'];used={s['id'] for s in matched['source_phases']['statements']}
    controls=[]
    for ordinal,point in enumerate(selected.values()):
        selection=point['selection'];file=selection['reported_filename'];recipe=selection['recipe_id']
        borrowed=sorted((r for r in candidates if r['recipe_id'] in used and file not in r['filename_alternatives']),key=lambda r:r['recipe_id'])[0]
        lines={v for r in candidates if file in r['filename_alternatives'] for v in r['line_alternatives'].values()}
        bad_line=next((line for line in sorted(lines) if line not in selection['all_line_alternatives'].values()),
                      max(selection['all_line_alternatives'].values())+1)
        for field,value in [('line',bad_line),('path',borrowed['filename_alternatives'][0]),('source',borrowed['recipe_id'])]:
            if field=='source':
                candidate=raw;affected=[]
                source=oracle['borrow_source'](matched['source_phases'],point,value,bindings)
            else:
                candidate,affected=oracle['construct'](raw,point,field,value,pairs);source=matched['source_phases']
            prior=predecessor['check'](models,models,candidate['inventories'],candidate['inventories'],nested)
            observer=oracle['observer_epoch'](matched['observer_qualification'],candidate)
            failures={}
            for name,procedure in [('derive',derive),('reconstruct',coordinate)]:
                try:procedure(candidate,source,prior,matched['expression_alternatives'],observer)
                except ValueError as error:
                    cause=str(error)
                    expected='declared own caller coordinate: '+(value if field=='source' else recipe) if name=='derive' else (
                        'independent declared caller line' if field=='line' else 'independent declared caller filename')
                    need(cause==expected,'independent intended semantic coordinate refusal: '+cause)
                    failures[name]=cause
                else:raise ValueError('independent false-green coordinate intervention')
            controls.append({'point':point,'field':field,'value':value,'affected':affected,
                'whole_intervention_original':stamp(candidate),'whole_intervention_source':stamp(source),
                'complete_predecessor_result':stamp(prior),'refusals':failures})
        (CHECKS/'progress.json').write_text(json.dumps({'stage':'independent-controls','completed_representatives':ordinal+1,
            'total_representatives':len(selected),'completed_controls':len(controls)},sort_keys=True)+'\n')
    for pair in pairs:
        require_pair=[pair['child'],pair['parent']]
        need(all(any(control['field']==field and control['affected']==sorted(require_pair)
                     for control in controls) for field in ('line','path')),
             'every nested pair has coherent line and filename interventions')
    original_keys=set(oracle['records'](raw))
    for field in ('line','path'):
        affected={tuple(key) for control in controls if control['field']==field for key in control['affected']}
        need(affected==original_keys,'every whole original nonempty record receives coordinate interventions')
    return {'points':points,'forwarding':pairs,'representatives':list(selected.values()),
            'baseline_predecessor':stamp(baseline),'controls':controls}


def main():
    paths=[CLASS/'raw-product.json',CLASS/'source-models.json',CLASS/'proofs.json',MATCHING/'matching.json',
           MATCHING/'match.py',MATCHING/'verify.py',MATCHING/'seal.json',CLASS/'verify.py']
    bodies=[fixed(p) for p in paths];raw,models,proofs,matched=map(json.loads,bodies[:4])
    command=['python3','-B',str(READER)];run=subprocess.run(command,capture_output=True,text=True)
    need(type(run.returncode) is int and run.returncode==0 and not run.stderr,'complete independent actual original/source/matching replay')
    actual={'command':command,'status':run.returncode,'stdout':run.stdout,'stderr':run.stderr,'programme':stamp(fixed(READER))}
    old=json.loads(fixed(A/'coordinate-original-matching-qualified-checks-20261009/checks.json'))['published']['stdout']
    need(actual['stdout']==old,'whole fresh independent matching and nested actual results conserve')
    original_custody=json.loads(fixed(A/'coordinate-original-intake-20261009/admission.json'))['custody']
    for name,row in original_custody['members'].items():
        need(stamp(Path(name).read_bytes())==row['identity'],'complete independent original custody conservation')
    expected={'revision':REVISION,'owner':(BASE/'scope.txt').read_text().strip(),
        'role':'Dated complete original own-coordinate hostile qualification; finite source-recipe interventions preserve predecessor class/frame/argument meanings. Original private/framework/toolchain/identity, address and alias meanings remain unmeasured.',
        'inputs':{str(p):stamp(b) for p,b in zip(paths,bodies,strict=True)},'original':raw,'source_models':models,'matching':matched,
        **reconstruct(raw,models,proofs,matched),'actual_matching_reader':actual,'original_custody':stamp(original_custody),
        'legs':{'rederive':'qualify.py complete matched-point allocation and every observed used source recipe/mode with genuine line/file/source interventions and actual complete matching/prerequisite replay.',
                'falsify':'verify.py separate source-link point reconstruction and byte-offset mutation construction, complete unchanged predecessor semantic predicates, both sealed coordinate procedures and typed/whole-result controls.',
                'durability':'Complete fixed original/source/matching corpus, full point/representative/forwarding/control results and first prototype failure, immutable sealed programmes/product and published reader; normal Git commit.'}}
    product=json.loads((BASE/'qualification.json').read_bytes());check(product,expected)
    for name,row in original_custody['members'].items():
        need(stamp(Path(name).read_bytes())==row['identity'],'complete independent post-intervention original custody conservation')
    first=runpy.run_path(str(BASE/'first-mutations.py.txt'))
    try:first['forwarding'](models,raw)
    except ValueError as error:need(str(error)=='unique finite forwarding pairs','exact first duplicate-allocation failure reproduction')
    else:raise ValueError('first duplicate forwarding programme unexpectedly accepted')
    failure=json.loads((BASE/'first-probe-result.json').read_bytes())
    need(type(failure['status']) is int and failure['status']==1
         and failure['instruments'][str(BASE/'probe.py')]==stamp((BASE/'first-probe.py.txt').read_bytes())
         and 'ValueError: unique finite forwarding pairs' in failure['stderr'],'exact first actual probe programme/result retained')
    first_qualification=runpy.run_path(str(BASE/'first-qualification.py.txt'))
    facade=next(p for p in expected['points'] if p['selection']['recipe_id']=='facade-parse')
    try:first_qualification['semantic_controls'](raw,models,matched,[facade])
    except ValueError as error:need(str(error)=='min() iterable argument is empty','exact first exhausted line-control failure reproduction')
    else:raise ValueError('first exhausted line-control programme unexpectedly accepted')
    failed_qualification=json.loads((BASE/'first-qualification-result.json').read_bytes())
    need(type(failed_qualification['status']) is int and failed_qualification['status']==1
         and failed_qualification['instruments'][str(BASE/'qualify.py')]==stamp((BASE/'first-qualification.py.txt').read_bytes())
         and 'ValueError: min() iterable argument is empty' in failed_qualification['stderr'],
         'whole first qualification programme/result retain')
    interrupted=json.loads((BASE/'ram-stopped-result.json').read_bytes())
    partial=list(map(json.loads,(BASE/'ram-stopped-controls.jsonl').read_text().splitlines()))
    progress=json.loads((BASE/'ram-stopped-progress.json').read_bytes())
    need(type(interrupted['status']) is int and interrupted['status']==137
         and 'host memory 89.1% reached cutoff 88%' in interrupted['stderr']
         and interrupted['instruments'][str(BASE/'qualify.py')]==stamp((BASE/'qualify.py').read_bytes())
         and progress['completed_controls']<=len(partial)<progress['completed_controls']+3
         and same(partial,expected['controls'][:len(partial)])
         and same(json.loads((BASE/'ram-stopped-matching-replay.json').read_bytes()),expected['actual_matching_reader']),
         'whole RAM-stopped actual prefix and unchanged instrument/cutoff retain')
    controls={}
    for name,field,mutate in [
        ('lost-point','points',lambda p:p['points'].pop()),
        ('lost-source-recipe','representatives',lambda p:p['representatives'].pop()),
        ('borrowed-intervention','controls',lambda p:p['controls'][0].update(whole_intervention_original=p['controls'][1]['whole_intervention_original'])),
        ('false-green-prior','controls',lambda p:p['controls'][0].update(complete_predecessor_result={})),
        ('lost-forwarded-pair','forwarding',lambda p:p['forwarding'].pop()),
        ('lost-empty','original',lambda p:p['original']['inventories'][0]['domains']['api']['empty_string_members'].pop()),
        ('Boolean-reader-status','actual_matching_reader',lambda p:p['actual_matching_reader'].update(status=True)),
        ('borrowed-reader-command','actual_matching_reader',lambda p:p['actual_matching_reader']['command'].append('--foreign')),
        ('borrowed-reader-stdout','actual_matching_reader',lambda p:p['actual_matching_reader'].update(stdout='PASS\n'))]:
        changed=copy.deepcopy(product);mutate(changed);need(not same(changed,product),'genuine whole hostile control: '+name)
        try:check(changed,expected)
        except ValueError as error:
            need(str(error)=='complete independent hostile field: '+field,'intended whole hostile control: '+name)
            controls[name]=str(error)
        else:raise ValueError('false-green whole hostile product: '+name)
    need([fixed(p) for p in paths]==bodies,'whole independent hostile source conservation')
    (CHECKS/'progress.json').write_text(json.dumps({'stage':'independent-complete','controls':len(expected['controls'])},sort_keys=True)+'\n')
    print(json.dumps({'result':'PASS complete independent original-coordinate hostile qualification and predecessor preservation',
        'whole_qualification':stamp(expected),'actual_matching_reader':actual,
        'coverage':{'points':len(expected['points']),'source_recipe_modes':len(expected['representatives']),
                    'semantic_controls':len(expected['controls']),'forwarding_pairs':len(expected['forwarding']),
                    'intervened_records':len(oracle['records'](raw))},'controls':controls},sort_keys=True))


if __name__=='__main__':
    main()
