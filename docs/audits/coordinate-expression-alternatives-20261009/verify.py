"""Independent original source reconstruction and finite expression-boundary oracle."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

A=Path('docs/audits')
BASE=A/'coordinate-expression-alternatives-20261009'
REVISION='a3efbe6489451f76cdb3fda343adb6aa556f2dc7'
RECIPES=A/'coordinate-statement-recipes-20261009/recipes.json'
ADMISSION=A/'coordinate-source-admission-20261008/proof.json'
PUBLIC=A/'coordinate-original-mismatch-20261009'
FIXTURES=('caller-fixture.pl','caller-pattern-shift.pl','caller-label-shift.pl',
          'guard-fixture.pl','guard-expression-shift.pl','guard-message-shift.pl',
          'guard-live-fixture.pl','guard-live-operand-shift.pl','guard-live-message-shift.pl')
READERS=(A/'coordinate-source-admission-20261008/verify.py',A/'coordinate-statement-recipe-checks-20261009/verify_recipes.py')


def need(ok,why):
    if not ok:
        raise ValueError(why)


def pin(raw):
    return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}


def stamp(value):
    return pin(json.dumps(value,sort_keys=True).encode())


def same(a,b):
    return json.dumps(a,sort_keys=True)==json.dumps(b,sort_keys=True)


def git(path,revision=REVISION):
    run=subprocess.run(['git','--no-replace-objects','cat-file','blob',revision+':'+str(path)],capture_output=True)
    need(run.returncode==0 and not run.stderr,'whole independent expression Git source')
    return run.stdout


def fixed(path):
    full=Path.cwd().resolve()/path;root=Path.cwd().resolve()
    need(full.resolve()==full and full.is_file() and full.stat().st_dev==root.stat().st_dev,'independent plain same-volume expression input')
    for parent in full.parents:
        if parent==root:break
        need(not (parent/'.git').exists(),'independent own expression input boundary')
    raw=git(path);need(raw==path.read_bytes(),'whole unchanged fixed expression input');return raw


def boundary(raw,name):
    """Separate finite oracle: declared message and callback/pattern syntax."""
    if name in ('_require','guard'):
        separators=list(re.finditer(rb",\s*(?=['\"])",raw))
        need(len(separators)==1,'unique finite guard/message boundary')
        start=len(name)+1;end=separators[0].start()
        while raw[start:start+1].isspace():start+=1
        while raw[end-1:end].isspace():end-=1
        return start,end,'predicate_expression_closing','guard_predicate'
    pattern=(rb'\},\s*(?=qr/|\$)' if name=='refuses' else rb',\s*(?=qr/)')
    separators=list(re.finditer(pattern,raw));need(len(separators)==1,'unique finite helper/pattern boundary')
    start=separators[0].end()
    if raw[start:start+3]==b'qr/':
        token=re.match(rb'qr/(?:\\.|[^/])*/[a-z]*',raw[start:]);need(token is not None,'whole finite pattern literal');end=start+token.end()
    else:
        need(raw[start:start+1]==b'$','finite dynamic helper pattern');end=raw.index(b',',start)
        while raw[end-1:end].isspace():end-=1
    return start,end,'pattern_expression_first','helper_pattern'


def emit(body,start,end,label,kind):
    first=len(body[:start].split(b'\n'));closing=len(body[:end].split(b'\n'));raw=body[start:end]
    return {'label':label,'kind':kind,'offset_bytes':start,'text':raw.decode(),'identity':pin(raw),
            'line':first if kind=='helper_pattern' else closing,'first_line':first,'closing_line':closing,'original_selection':None}


def source_rows(recipes,units):
    result=[]
    for recipe in recipes['statements']:
        body=units[recipe['unit']]['body'].encode();start=recipe['offset_bytes'];raw=recipe['text'].encode()
        need(body[start:start+len(raw)]==raw and pin(raw)==recipe['identity'] and pin(body)==recipe['source_identity'],
             'whole independently reconstructed statement bytes')
        nodes=[]
        if raw.startswith((b'_require(',b'refuses(')):
            name=raw.partition(b'(')[0].decode();lo,hi,label,kind=boundary(raw,name)
            nodes=[emit(body,start+lo,start+hi,label,kind)]
        lines=dict(recipe['line_alternatives']);lines.update({n['label']:n['line'] for n in nodes})
        values=sorted(set(lines.values()))
        groups=[sorted(k for k in lines if lines[k]==v) for v in values]
        result.append({'recipe_id':recipe['id'],'whole_recipe':stamp(recipe),'extensions':nodes,
            'line_alternatives':lines,'equivalent_line_labels':[g for g in groups if len(g)>1],
            'filename_alternatives':recipe['filename_alternatives'],'coordinate_prediction':False,'original_selection':None})
    need(len({r['recipe_id'] for r in result})==len(result),'whole independent candidate domain')
    return result


def public(path):
    body=fixed(path);actual=[]
    for command in (['perl',str(path)],['perl','-MO=Concise,-exec',str(path)]):
        run=subprocess.run(command,capture_output=True,text=True)
        need(run.returncode==0,'complete independently regenerated public expression result')
        actual.append({'command':command,'status':run.returncode,'stdout':run.stdout,'stderr':run.stderr})
    native=json.loads(actual[0]['stdout']);selections=[]
    markers=list(re.finditer(rb"\$case = '([^']+)';",body))
    for i,marker in enumerate(markers):
        stop=markers[i+1].start() if i+1<len(markers) else len(body)
        name='callsite' if path.name.startswith('caller-') else 'guard'
        start=body.index(name.encode()+b'(',marker.end(),stop)
        end=body.rindex(b');',start,stop)+1
        raw=body[start:end];lo,hi,label,kind=boundary(raw,name)
        extension=emit(body,start+lo,start+hi,label,kind)
        values={'first':len(body[:start].split(b'\n')),'closing':len(body[:end].split(b'\n')),label:extension['line']}
        records=[r for r in native['observations'] if r['case']==marker[1].decode() and r['kind']==('helper' if name=='callsite' else 'guard')]
        need(len(records)==1 and records[0]['file']==str(path) and records[0]['package']=='main','whole finite public caller allocation')
        record=records[0];labels=sorted(k for k in values if values[k]==record['line'])
        need(labels and re.search(r'nextstate\(main \d+ '+re.escape(path.name)+':'+str(record['line'])+r'\)',actual[1]['stdout']),
             'source-derived public alternatives and compiler state agree')
        selections.append({'case':marker[1].decode(),'call_offset_bytes':start,'call_identity':pin(raw),'extension':extension,
                           'line_alternatives':values,'reported':record,'matching_labels':labels})
    need(actual[0]['stderr']=='' and actual[1]['stderr']==str(path)+' syntax OK\n','whole actual public expression streams')
    return {'path':str(path),'source':pin(body),'actual':actual,'finite_public_selections':selections,
            'role':'Finite current public source/caller examples only; not an original coordinate or private-toolchain prediction.'}


def check(actual,expected):
    for field in expected:
        need(field in actual and same(actual[field],expected[field]),'complete independent expression field: '+field)
    need(set(actual)==set(expected),'closed complete expression product')


def main():
    recipe_raw,source_raw=fixed(RECIPES),fixed(ADMISSION)
    recipes=json.loads(recipe_raw);source=json.loads(source_raw)['inputs']['source'];units=source['units']
    for name,row in units.items():
        if name=='observer':
            transform=source['transform'];body=git(transform['source_path'],source['source_authority']['capture_revision'])
            need(body==transform['before'].encode(),'complete independent observer beforeimage')
            for old,new in transform['replacements']:
                need(body.count(old.encode())==1,'unique original observer transform');body=body.replace(old.encode(),new.encode())
            need(body==transform['after'].encode(),'complete independent observer generation')
        else:
            body=git(row['path'],source['source_authority']['original_revision'])
        need(body==row['body'].encode() and pin(body)==row['identity'],'whole independent original source unit')
    rows=source_rows(recipes,units)
    expected={'revision':REVISION,'owner':(BASE/'scope.txt').read_text().strip(),
        'role':'Complete dated source-only conditional expression-boundary candidates and finite public caller/compiler qualification; no original coordinate selection or private/toolchain promotion.',
        'inputs':{str(RECIPES):pin(recipe_raw),str(ADMISSION):pin(source_raw)},'source_units':units,'original_recipes':recipes,
        'candidates':rows,'finite_public':[public(PUBLIC/name) for name in FIXTURES],'actual_readers':[],'unresolved':recipes['unresolved'],
        'legs':{'rederive':'derive.py complete fixed original statements and literal expression spans; candidates precede public measurements.',
                'falsify':'verify.py independent original Git/source reconstruction, separate finite source boundary oracle, fresh public/compiler results and genuine node/source/line/scope/result controls.',
                'durability':'Complete old source/recipe bodies, exact new expression nodes, fixed source epoch, sealed programmes/products and actual results, normal Git commit.'}}
    for reader in READERS:
        command=['python3','-B',str(reader)];run=subprocess.run(command,capture_output=True,text=True)
        need(run.returncode==0 and not run.stderr,'complete independently regenerated source-only reader')
        expected['actual_readers'].append({'command':command,'status':run.returncode,'stdout':run.stdout,'stderr':run.stderr,'programme':pin(fixed(reader))})
    actual=json.loads((BASE/'alternatives.json').read_bytes());check(actual,expected)
    controls={}
    def extension(p):return next(r['extensions'][0] for r in p['candidates'] if r['extensions'])
    for name,mutate,field in (
        ('wrong-node',lambda p:extension(p).update(offset_bytes=0),'candidates'),
        ('wrong-expression-line',lambda p:extension(p).update(line=1),'candidates'),
        ('wrong-argument-role',lambda p:extension(p).update(kind='message_expression'),'candidates'),
        ('lost-recipe',lambda p:p['candidates'].pop(),'candidates'),
        ('original-promotion',lambda p:p['candidates'][0].update(original_selection=True),'candidates'),
        ('borrowed-source',lambda p:p['source_units']['value'].update(body=p['source_units']['context']['body']),'source_units'),
        ('lost-old-label',lambda p:p['original_recipes']['statements'][0]['line_alternatives'].pop('first'),'original_recipes'),
        ('false-green-status',lambda p:p['actual_readers'][0].update(status=True),'actual_readers'),
        ('borrowed-public-command',lambda p:p['finite_public'][0]['actual'][0]['command'].append('--foreign'),'finite_public'),
        ('borrowed-public-stdout',lambda p:p['finite_public'][0]['actual'][0].update(stdout='PASS\n'),'finite_public'),
        ('lost-private-owner',lambda p:p['unresolved'].pop('original_private_formatter_toolchain_identity'),'unresolved')):
        bad=copy.deepcopy(actual);mutate(bad);need(not same(bad,actual),'genuine expression control: '+name)
        try:check(bad,expected)
        except ValueError as error:
            need(str(error)=='complete independent expression field: '+field,'intended expression control');controls[name]=str(error)
        else:raise ValueError('false-green expression control: '+name)
    need(fixed(RECIPES)==recipe_raw and fixed(ADMISSION)==source_raw,'whole expression source conservation')
    print(json.dumps({'result':'PASS complete independent source-only expression alternatives and finite public/compiler controls',
        'candidates':stamp(rows),'whole_original_recipes':pin(recipe_raw),'controls':controls,
        'actual_readers':expected['actual_readers'],'scope':'Every original selection remains empty; conditional candidates do not predict all toolchains or formatting.'},sort_keys=True))


if __name__=='__main__':
    main()
