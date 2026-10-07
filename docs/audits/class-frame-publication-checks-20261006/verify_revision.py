"""Qualify full execution preservation and genuine stronger global loss predicates."""
import ast
import copy
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-20261006')
CHECKS = Path('docs/audits/class-frame-publication-checks-20261006')


def module(path):
    ns = {'__name__':'qualify_publication_revision','__file__':str(path)}
    exec(compile(path.read_bytes(),str(path),'exec'),ns)
    return ns


def check():
    current,first = module(BASE / 'verify.py'),module(CHECKS / 'first-verify.py.txt')
    require,same,identity,load = (current[k] for k in ('require','same','identity','load'))
    allowed = {'current_input','check_current','replays','controls'}
    old,new = ast.parse((CHECKS / 'first-verify.py.txt').read_bytes()),ast.parse((BASE / 'verify.py').read_bytes())
    dump = lambda tree:[ast.dump(n,include_attributes=False) for n in tree.body if not(isinstance(n,ast.FunctionDef) and n.name in allowed)]
    require(dump(old) == dump(new),'whole unchanged prerequisite execution and source/semantic/model functions outside declared current revision')
    old_functions = {n.name:ast.dump(n,include_attributes=False) for n in old.body if isinstance(n,ast.FunctionDef)}
    new_functions = {n.name:ast.dump(n,include_attributes=False) for n in new.body if isinstance(n,ast.FunctionDef)}
    require(set(old_functions) == set(new_functions) and {k for k in old_functions if old_functions[k] != new_functions[k]} == allowed,
            'exact declared strengthened current predicate and retained caller revision domain')
    source = load(BASE / 'source-model.json'); rows = source['allocation']['rows']
    record = dict(cards=source['cards'],chapter=current['book']['transform'](current['git'](current['CHAPTER']).decode()),
        tooling_chapter=current['git'](current['TOOLING_CHAPTER']).decode(),census=source['after'],surface=source['surface'],source_budget=source['source_budget'],
        physical_members=source['after_members'],queries={role:dict(command=['knowledge-map/scripts/query_knowledge_map.sh','--all'] + (['--no-cache'] if role=='direct' else []),
            status=0,stdout=rows,stderr='') for role in ('direct','cached')})
    first['check_current']({k:v for k,v in record.items() if k != 'physical_members'}); current['check_current'](record)
    ids = {Path(p).stem for p in current['PATHS']}
    lost = next(line for line in rows.splitlines() if not ids.intersection(line.split('\t')[1].split(',')))
    controls = []
    for name,mutate,cause in (
        ('lost-non-target-question',lambda r:r['queries']['direct'].update(stdout=rows.replace(lost + '\n','',1)),'whole global current question identity path and occurrence allocation'),
        ('reduced-physical-population',lambda r:r['census'].update(files=r['census']['files']-1),'whole exact current physical population census'),
        ('lost-non-target-member',lambda r:r['physical_members'].pop(next(p for p in r['physical_members'] if p not in current['PATHS'])),'whole current physical member and non-target source conservation')):
        candidate = copy.deepcopy(record); mutate(candidate); require(not same(candidate,record),'genuine revised current loss vector: ' + name)
        first['check_current']({k:v for k,v in candidate.items() if k != 'physical_members'})
        try: current['check_current'](candidate)
        except ValueError as error:
            require(str(error) == cause,'intended stronger current refusal: ' + name + ': ' + str(error))
            controls.append(dict(control=name,old='accepted',new='refused',cause=cause))
        else: raise ValueError('false-green strengthened current loss: ' + name)
    prior = load(CHECKS / 'first-global-loss.json')
    require(prior['programme'] == identity((CHECKS / 'first-verify.py.txt').read_bytes()) and prior['removed_row'] == lost,
            'whole independently reproduced first global-loss programme and vector')
    return dict(before=identity((CHECKS / 'first-verify.py.txt').read_bytes()),after=identity((BASE / 'verify.py').read_bytes()),
        preserved_functions=sorted(set(old_functions)-allowed),changed_functions=sorted(allowed),controls=controls,
        role='Whole original preparation/replay caller retained; only stronger current population predicates, their controls and explicit historical caller identity differ. Constructed vectors are not actual query receipts.')


if __name__ == '__main__':
    proof = check(); ns = module(BASE / 'verify.py'); ns['save']('reader-revision.json',proof)
    print('PASS complete original execution/source/model functions preserve; genuine global question/physical population/member losses pass the first sketch and refuse the strengthened current predicate.')
