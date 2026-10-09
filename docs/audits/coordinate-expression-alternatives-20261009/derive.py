"""Source-only conditional expression boundaries; never select an original trace."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

A = Path('docs/audits')
BASE = A / 'coordinate-expression-alternatives-20261009'
REVISION = 'a3efbe6489451f76cdb3fda343adb6aa556f2dc7'
RECIPES = A / 'coordinate-statement-recipes-20261009/recipes.json'
ADMISSION = A / 'coordinate-source-admission-20261008/proof.json'
PUBLIC = A / 'coordinate-original-mismatch-20261009'
FIXTURES = ('caller-fixture.pl','caller-pattern-shift.pl','caller-label-shift.pl',
            'guard-fixture.pl','guard-expression-shift.pl','guard-message-shift.pl',
            'guard-live-fixture.pl','guard-live-operand-shift.pl','guard-live-message-shift.pl')
READERS = (A / 'coordinate-source-admission-20261008/verify.py',
           A / 'coordinate-statement-recipe-checks-20261009/verify_recipes.py')
ROLE = 'Complete dated source-only conditional expression-boundary candidates and finite public caller/compiler qualification; no original coordinate selection or private/toolchain promotion.'


def need(ok, why):
    if not ok:
        raise ValueError(why)


def pin(raw):
    return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}


def identity(value):
    return pin(json.dumps(value,sort_keys=True).encode())


def fixed(path):
    root = Path.cwd().resolve(); full = root / path
    need(full.resolve() == full and full.is_file() and full.stat().st_dev == root.stat().st_dev,
         'plain same-volume expression source')
    for parent in full.parents:
        if parent == root:
            break
        need(not (parent / '.git').exists(), 'own expression source boundary')
    result = subprocess.run(['git','--no-replace-objects','show',REVISION+':'+str(path)],capture_output=True)
    need(result.returncode == 0 and not result.stderr and result.stdout == path.read_bytes(), 'whole fixed expression source')
    return result.stdout


def arguments(raw, name):
    """Finite admitted call syntax: balanced delimiters, strings and qr/ literals."""
    prefix = name.encode()+b'('
    need(raw.startswith(prefix), 'finite source call head')
    stack, spans, begin, index = [41], [], len(prefix), len(prefix)
    while index < len(raw):
        byte = raw[index]
        if raw[index:index+3] == b'qr/':
            index += 3
            while index < len(raw) and raw[index] != 47:
                index += 2 if raw[index] == 92 else 1
            need(index < len(raw), 'complete finite regexp literal')
            index += 1
            while index < len(raw) and chr(raw[index]).isalpha():
                index += 1
            continue
        if byte in (34,39):
            quote = byte; index += 1
            while index < len(raw) and raw[index] != quote:
                index += 2 if raw[index] == 92 else 1
            need(index < len(raw), 'complete finite string literal')
        elif byte in (40,91,123):
            stack.append({40:41,91:93,123:125}[byte])
        elif byte in (41,93,125):
            need(stack and stack.pop() == byte, 'balanced finite call delimiters')
            if not stack:
                spans.append((begin,index)); break
        elif byte == 44 and len(stack) == 1:
            spans.append((begin,index)); begin=index+1
        index += 1
    need(not stack and spans, 'complete finite outer call')
    trimmed = []
    for start,end in spans:
        while start < end and raw[start:start+1].isspace(): start += 1
        while end > start and raw[end-1:end].isspace(): end -= 1
        need(end > start, 'nonempty finite call argument')
        trimmed.append((start,end))
    return trimmed, index+1


def node(body, start, end, label, kind):
    raw = body[start:end]
    first, closing = body[:start].count(b'\n')+1, body[:end].count(b'\n')+1
    return {'label':label,'kind':kind,'offset_bytes':start,'text':raw.decode(), 'identity':pin(raw),
            'line':first if label == 'pattern_expression_first' else closing,
            'first_line':first,'closing_line':closing,'original_selection':None}


def candidates(recipes, units):
    rows = []
    for recipe in recipes['statements']:
        body = units[recipe['unit']]['body'].encode(); raw=recipe['text'].encode(); start=recipe['offset_bytes']
        need(pin(body) == recipe['source_identity'] and body[start:start+len(raw)] == raw
             and pin(raw) == recipe['identity'] and recipe['original_selection'] is None, 'whole original statement/source conservation')
        extensions=[]
        if raw.startswith(b'_require('):
            spans,_=arguments(raw,'_require'); need(len(spans)==2,'complete finite guard arity')
            lo,hi=spans[0]; extensions.append(node(body,start+lo,start+hi,'predicate_expression_closing','guard_predicate'))
        elif raw.startswith(b'refuses('):
            spans,_=arguments(raw,'refuses'); need(len(spans)==3,'complete finite helper arity')
            lo,hi=spans[1]
            need(raw[lo:hi].startswith((b'qr/',b'$')), 'finite helper pattern expression kind')
            extensions.append(node(body,start+lo,start+hi,'pattern_expression_first','helper_pattern'))
        alternatives = dict(recipe['line_alternatives'])
        alternatives.update({n['label']:n['line'] for n in extensions})
        groups = {}
        for label,value in sorted(alternatives.items()): groups.setdefault(value,[]).append(label)
        rows.append({'recipe_id':recipe['id'],'whole_recipe':identity(recipe),'extensions':extensions,
            'line_alternatives':alternatives,'equivalent_line_labels':[g for _,g in sorted(groups.items()) if len(g)>1],
            'filename_alternatives':recipe['filename_alternatives'],'coordinate_prediction':False,'original_selection':None})
    need(len({r['recipe_id'] for r in rows}) == len(rows),'whole unique source candidate domain')
    return rows


def public(path):
    body=fixed(path); text=body.decode(); outputs=[]
    for command in (['perl',str(path)],['perl','-MO=Concise,-exec',str(path)]):
        run=subprocess.run(command,capture_output=True,text=True)
        need(run.returncode==0,'complete finite public expression result')
        outputs.append({'command':command,'status':run.returncode,'stdout':run.stdout,'stderr':run.stderr})
    observed=json.loads(outputs[0]['stdout']); selected=[]
    markers=list(re.finditer(rb"\$case = '([^']+)';",body))
    for i,marker in enumerate(markers):
        stop=markers[i+1].start() if i+1<len(markers) else len(body)
        name='callsite' if path.name.startswith('caller-') else 'guard'
        begin=body.index(name.encode()+b'(',marker.end(),stop)
        spans,end=arguments(body[begin:stop],name)
        arg=spans[1] if name=='callsite' else spans[0]
        label='pattern_expression_first' if name=='callsite' else 'predicate_expression_closing'
        extension=node(body,begin+arg[0],begin+arg[1],label,'helper_pattern' if name=='callsite' else 'guard_predicate')
        values={'first':body[:begin].count(b'\n')+1,'closing':body[:begin+end].count(b'\n')+1,label:extension['line']}
        record=next(r for r in observed['observations'] if r['case']==marker[1].decode()
                    and r['kind']==('helper' if name=='callsite' else 'guard'))
        labels=sorted(k for k,v in values.items() if v==record['line'])
        need(labels and record['file']==str(path) and record['package']=='main','finite public source alternatives cover actual caller')
        selected.append({'case':marker[1].decode(),'call_offset_bytes':begin,'call_identity':pin(body[begin:begin+end]),
            'extension':extension,'line_alternatives':values,'reported':record,'matching_labels':labels})
    return {'path':str(path),'source':pin(body),'actual':outputs,'finite_public_selections':selected,
            'role':'Finite current public source/caller examples only; not an original coordinate or private-toolchain prediction.'}


def main():
    need(not (BASE/'alternatives.json').exists() and not (BASE/'seal.json').exists(),'superseding source producer never rewrites')
    recipe_raw,source_raw=fixed(RECIPES),fixed(ADMISSION)
    recipes=json.loads(recipe_raw); units=json.loads(source_raw)['inputs']['source']['units']
    # Derivation completes before any public caller measurement. No original
    # capture, raw inventory, class/frame coordinate product or mismatch row is read.
    rows=candidates(recipes,units)
    result={'revision':REVISION,'owner':(BASE/'scope.txt').read_text().strip(),'role':ROLE,
        'inputs':{str(RECIPES):pin(recipe_raw),str(ADMISSION):pin(source_raw)},
        'source_units':units,'original_recipes':recipes,'candidates':rows,
        'finite_public':[public(PUBLIC/name) for name in FIXTURES], 'actual_readers':[],
        'unresolved':recipes['unresolved'],
        'legs':{'rederive':'derive.py complete fixed original statements and literal expression spans; candidates precede public measurements.',
                'falsify':'verify.py independent original Git/source reconstruction, separate finite source boundary oracle, fresh public/compiler results and genuine node/source/line/scope/result controls.',
                'durability':'Complete old source/recipe bodies, exact new expression nodes, fixed source epoch, sealed programmes/products and actual results, normal Git commit.'}}
    for reader in READERS:
        command=['python3','-B',str(reader)]; run=subprocess.run(command,capture_output=True,text=True)
        need(run.returncode==0 and not run.stderr,'actual unchanged source-only prerequisite')
        result['actual_readers'].append({'command':command,'status':run.returncode,'stdout':run.stdout,'stderr':run.stderr,
                                       'programme':pin(fixed(reader))})
    need(fixed(RECIPES)==recipe_raw and fixed(ADMISSION)==source_raw,'whole source conservation after public/source readers')
    (BASE/'alternatives.json').write_text(json.dumps(result,sort_keys=True,indent=2)+'\n')
    print('PASS complete source-only expression alternatives and finite public qualification; no original selection.')


if __name__=='__main__':
    main()
