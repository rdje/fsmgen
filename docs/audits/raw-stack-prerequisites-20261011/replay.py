"""Execute complete qualified readers, keeping historical and source roles explicit."""
import ast
import json
from pathlib import Path
from common import BASE, REVISION, SCOPE, canonical, load, need, pin, save
from run import execute


def read(path):
    return json.loads(Path(path).read_bytes())


def terminal(path):
    tree=ast.parse(Path(path).read_bytes())
    constants={target.id:node.value.value for node in tree.body if isinstance(node,ast.Assign)
               and isinstance(node.value,ast.Constant) and isinstance(node.value.value,str)
               for target in node.targets if isinstance(target,ast.Name)}
    if 'SUCCESS' in constants:return constants['SUCCESS']
    found=[node for node in ast.walk(tree) if isinstance(node,ast.Call)
           and isinstance(node.func,ast.Name) and node.func.id=='print' and node.args
           and isinstance(node.args[0],ast.Constant) and isinstance(node.args[0].value,str)
           and node.args[0].value.startswith('PASS ')]
    need(bool(found),'fixed reader terminal source literal')
    return max(found,key=lambda node:node.lineno).args[0].value+'\n'


def specifications():
    fixed=load('intake-qualified.json')['members'];result={}
    previous=Path('docs/audits/observer-current-publication-20261011')
    for name,entry in read(previous/'prerequisites.json')['readers'].items():
        path=previous/entry['receipt'];actual=read(path)
        need(str(path) in fixed and type(actual['status']) is int and actual['status']==0
             and actual['stderr']=='','complete fixed qualified observer reader receipt')
        result['observer-'+name]=dict(command=actual['command'],stdout=actual['stdout'],
            match='whole',context=entry['context'],authority=str(path))
        if name=='public-display':
            adapter=BASE/'display_checkpoint.py'
            result['observer-'+name].update(command=['python3','-B',str(adapter),'--replay'],
                stdout=actual['stdout']+terminal(adapter),
                context='fresh whole original display reader in complete same-volume dated source context with its exact original publication instrument; maintained current verification is separate',
                adapter=str(adapter))
    address=Path('docs/audits/address-current-closure-20261010/acceptance.json')
    for name,actual in read(address)['actual_readers'].items():
        command=actual['command']
        need(command[:2]==['scripts/run_with_ram_guard.sh','--'] and type(actual['status']) is int
             and actual['status']==0,'complete fixed qualified address reader receipt')
        result['address-'+name]=dict(command=command[2:],stdout=actual['stdout'],match='whole',
            context='dated publication snapshot' if name=='preparation' else 'complete unchanged source and original finite products',
            authority=str(address),guard='outer raw prerequisite RAM guard supervises every nested process')
    for name,folder in (
        ('primary','record-value-original-primary-20261005'),
        ('raw-inventory','record-value-original-raw-20261005'),
        ('source-helper','record-value-original-helper-join-20261005'),
        ('source-class','record-value-original-class-20261005'),
        ('source-api','record-value-original-api-paths-20261005'),
        ('class-admission','record-value-class-frame-admission-20261006'),
        ('class-dated-publication','record-value-class-frame-publication-20261006'),
        ('address-dated-closure','address-current-closure-20261010'),
        ('observer-dated-namespace-repair','observer-publication-namespace-repair-20261011'),
        ('recovered-coordinate-drafts','coordinate-public-route-checks-20261008')):
        path=Path('docs/audits')/folder/('pack_drafts.py' if name=='recovered-coordinate-drafts' else 'verify.py')
        need(str(path) in fixed,'fixed additional reader source authority')
        authority=path.with_name('contracts.py') if name=='address-dated-closure' else path
        need(str(authority) in fixed,'fixed additional reader terminal authority')
        result[name]=dict(command=['python3','-B',str(path)],stdout=terminal(authority),match='terminal',
            context='complete dated retained publication evidence; no later currency' if 'dated' in name else 'complete fixed source and original finite products',
            authority=str(authority))
    return result


def qualify(actual,spec):
    need(type(actual['status']) is int and actual['status']==0,'actual integer prerequisite success')
    need(actual['command']==spec['command'],'exact whole prerequisite command')
    need(actual['stderr']=='' and type(actual['stdout']) is str,'complete clean prerequisite streams')
    need((actual['stdout']==spec['stdout'] if spec['match']=='whole' else actual['stdout'].endswith(spec['stdout'])),
         'whole declared prerequisite stdout role')
    need(type(actual.get('programs')) is dict and bool(actual['programs']),'complete recorded prerequisite runner programme epoch')
    for path,programme in actual['programs'].items():
        need(Path(path).parent==BASE and pin(programme['body'].encode())==programme['identity'],
             'whole retained prerequisite runner programme bytes')


def main():
    results={}
    for name,spec in specifications().items():
        existing=[path for path in sorted(BASE.glob('actual-reader-'+name+'-*.json'))
                  if read(path)['command']==spec['command']]
        if existing:
            path=existing[-1];actual=read(path)
        else:
            actual=execute('reader-'+name,spec['command'])
            path=sorted(BASE.glob('actual-reader-'+name+'-*.json'))[-1]
        qualify(actual,spec)
        results[name]=dict(specification=spec,receipt=str(path),identity=pin(path.read_bytes()))
    product=dict(revision=REVISION,scope=SCOPE,readers=results)
    if (BASE/'readers.json').exists():need(load('readers.json')==product,'whole unchanged fresh prerequisite replay')
    else:save('readers.json',product)
    print('PASS complete fresh primary/source/context/inventory/class/API/public/parser/observer/header/coordinate/address readers with exact actual receipts and explicit dated roles.')


if __name__=='__main__':main()
