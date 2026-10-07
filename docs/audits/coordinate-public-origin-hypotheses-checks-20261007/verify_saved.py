"""Independently rebuild source-only origin alternatives and complete POD bytes."""
import copy
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-origin-hypotheses-checks-20261007')
MODEL = Path('docs/audits/record-value-coordinate-public-origin-hypotheses-20261007')
SOURCE = Path('docs/audits/record-value-coordinate-public-hypotheses-20261007')
PROFILE = Path('docs/audits/record-value-public-framework-profile-20261006')
REVISION = '52e2769325318ba5e9f79ff84353e32b44d7b086'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())


def same(a,b):
    return json.dumps(a,sort_keys=True)==json.dumps(b,sort_keys=True)


def data(path):
    return json.loads(path.read_bytes())


def namespace(path):
    result={'__name__':'independent_origin_source'}
    exec(compile(path.read_bytes(),str(path),'exec'),result)
    return result


def check_alternative(row,sources):
    raw=sources[row['unit']].encode('utf-8')
    statement=row['source'];encoded=statement['text'].encode('utf-8');offset=statement['offset_bytes']
    need(type(offset) is int and raw[offset:offset+len(encoded)]==encoded
         and statement['identity']==pin(encoded),'whole independent binary origin source span')
    opening=raw[:offset].count(b'\n')+1;closing=raw[:offset+len(encoded)].count(b'\n')+1
    need(type(statement['first_line']) is int and type(statement['closing_line']) is int
         and statement['first_line']==opening and statement['closing_line']==closing
         and same(row['line_hypotheses'],dict(first=opening,closing=closing)),
         'complete independent byte/LF origin source alternatives')


def check_hypotheses(candidate,expected,sources):
    need(same(candidate,expected),'whole independently reconstructed origin statement allocation and unselected scope')
    for case in candidate['cases']:
        need(set(case['origins'])=={'trace','guard_error'},'both independent public origin streams')
        for row in case['origins'].values():
            need(row['selected'] is None and row['alternatives'],'pure-source origin alternatives remain unselected')
            for alternative in row['alternatives']:
                check_alternative(alternative,sources)


def actual(row,command,stdout):
    need(row['command']==['scripts/run_with_ram_guard.sh','--',*command]
         and type(row['status']) is int and row['status']==0 and row['stdout']==stdout,
         'whole actual source-origin command integer success and stdout')
    need(re.fullmatch(r'ram-guard: PID \d+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n',row['stderr']),
         'complete unchanged source-origin guard stderr')
    paths=[BASE/'run.py',Path('scripts/run_with_ram_guard.sh')]
    paths.extend(Path(arg) for arg in command if arg.startswith(('docs/','scripts/','t/')) and Path(arg).is_file())
    need(same(row['instruments'],{str(p):pin(p.read_bytes()) for p in paths}),'all complete actual origin producing instruments')


def main():
    producer=namespace(MODEL/'verify.py')
    paths=list(MODEL.iterdir())
    need(all(p.is_file() and not p.is_symlink() and p.stat().st_dev==Path.cwd().stat().st_dev for p in paths),
         'whole regular same-volume pure-source origin domain')
    members={p.name:pin(p.read_bytes()) for p in paths if p.name!='manifest.json'}
    need(same(members,data(MODEL/'manifest.json')),'complete immutable pure-source origin seal')
    raw=subprocess.check_output(['git','archive',REVISION,*map(str,producer['ROOTS'])])
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        committed={m.name:archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
    binding=data(MODEL/'binding.json')
    need(same({p:v for root in binding['members'].values() for p,v in root.items()},
              {p:pin(raw) for p,raw in committed.items()}) and all(Path(p).read_bytes()==raw for p,raw in committed.items()),
         'whole independently committed source/document/caller/actual custody')
    need(same(binding,producer['binding']()),'whole committed completed owner and source binding')
    inputs=data(MODEL/'inputs.json')
    fixed=json.loads(committed[str(SOURCE/'inputs.json')])
    need(same(inputs['source'],fixed['source']) and same(inputs['source_pins'],fixed['source_pins'])
         and same(inputs['hypotheses'],json.loads(committed[str(SOURCE/'hypotheses.json')]))
         and same(inputs['documents'],json.loads(committed[str(PROFILE/'public-profile.json')])),
         'complete independently fixed source/document input without native trace interpretation')
    expected=producer['derive'](inputs)
    # Independently reconstruct the complete per-role candidate name population
    # from source-declared calls, origin statements and boundary relationships.
    relationships={'block-eval':'block_eval','anonymous':'anonymous_delegate','do-load':'do_load',
                   'require-load':'require_load','module-call':'module_delegate'}
    need([r['role'] for r in expected['cases']]==[r['role'] for r in inputs['hypotheses']['calls']],
         'complete independent source-declared origin case order')
    for case in expected['cases']:
        for stream,own in [('trace','own-longmess_call'),('guard_error','own-confess_call')]:
            names=[own,'observer-call','own-outer-invocation']
            if case['role'] in relationships:
                names.append('own-boundary:'+relationships[case['role']])
            need([a['name'] for a in case['origins'][stream]['alternatives']]==names,
                 'complete independent own origin statement candidate allocation')
            declared_call = next(r for r in inputs['hypotheses']['calls'] if r['role']==case['role'])
            candidates = case['origins'][stream]['alternatives']
            origin_key = 'longmess_call' if stream=='trace' else 'confess_call'
            need(candidates[0]['unit']=='fixture.pl'
                 and same(candidates[0]['source'],inputs['hypotheses']['trace_origin_sources'][origin_key])
                 and candidates[0]['filename_hypotheses']==['fixture.pl']
                 and candidates[1]['unit']==declared_call['unit']
                 and same(candidates[1]['source'],declared_call['source'])
                 and candidates[1]['filename_hypotheses']==declared_call['filename_hypotheses'],
                 'independent exact origin/observer statement and filename role allocation')
            outer_names = {'single':'single','multiline':'multiline','postfix':'postfix',
                           'block-eval':'block_eval','anonymous':'anonymous','do-load':'load','require-load':'load'}
            primary = inputs['source']['fixture.pl']
            if case['role'] in outer_names:
                outer_text = 'CoordinatePublic::'+outer_names[case['role']]+'();'
            elif case['role']=='module-call':
                outer_text = 'CoordinateDependency::module_call();'
            else:
                start = primary.index("$subtest->('public coordinate callback', sub {")
                end = primary.index('\nprint JSON::PP',start)
                outer_text = primary[start:end]
            need(candidates[2]['unit']=='fixture.pl' and candidates[2]['source']['text']==outer_text
                 and candidates[2]['filename_hypotheses']==['fixture.pl'],
                 'independently authored complete outer invocation allocation')
            if case['role'] in relationships:
                boundary = inputs['hypotheses']['boundaries'][relationships[case['role']]]
                need(candidates[3]['unit']=='fixture.pl' and same(candidates[3]['source'],boundary['source'])
                     and candidates[3]['filename_hypotheses']==['fixture.pl'],
                     'independent exact own boundary role/source allocation')
    check_hypotheses(data(MODEL/'hypotheses.json'),expected,inputs['source'])
    need(same(producer['controls'](inputs,expected),data(MODEL/'controls.json')),'every genuine intended source/document origin control')
    actual(data(BASE/'seal.json'),['python3','-B',str(MODEL/'verify.py'),'--seal'],producer['SUCCESS'])
    prior=data(Path('docs/audits/coordinate-public-caller-selection-checks-20261007/saved-result.json'))['stdout']
    actual(data(BASE/'prerequisite.json'),['python3','-B','docs/audits/coordinate-public-caller-selection-checks-20261007/verify_saved.py'],prior)
    cases=[('lost-outer-statement',lambda c:c['cases'][0]['origins']['trace']['alternatives'].pop(), 'whole independently reconstructed origin statement allocation and unselected scope'),
           ('premature-selected-origin',lambda c:c['cases'][1]['origins']['guard_error'].update(selected='own-confess_call'), 'whole independently reconstructed origin statement allocation and unselected scope'),
           ('borrowed-configuration-scope',lambda c:c.update(configuration='Formatter states measured.'), 'whole independently reconstructed origin statement allocation and unselected scope')]
    refusals=[]
    for name,mutate,cause in cases:
        changed=copy.deepcopy(expected);mutate(changed)
        need(not same(changed,expected),'genuine independent source-origin product control')
        try:
            check_hypotheses(changed,expected,inputs['source'])
        except ValueError as error:
            need(str(error)==cause,'intended independent source-origin product refusal')
            refusals.append(dict(control=name,status=1,cause=cause))
        else:
            raise ValueError('false-green independent source-origin product control')
    need(same(members,{p.name:pin(p.read_bytes()) for p in MODEL.iterdir() if p.name!='manifest.json'}),
         'every whole pure-source origin member conserves')
    print(json.dumps(dict(members=len(members),cases=len(expected['cases']),controls=refusals,
                         scope=producer['ROLE']),sort_keys=True))


if __name__=='__main__':
    main()
