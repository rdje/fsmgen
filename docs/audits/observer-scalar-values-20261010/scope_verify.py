"""Preserve complete original scalar-child and ancestor acceptance contracts."""
import subprocess
from pathlib import Path
from common import BASE, REVISION, load, need, same, save

TASK = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')


def block(text, identifier):
    marker='- ID: `'+identifier+'`'
    need(text.count(marker)==1,'unique full scalar task authority')
    start=text.index(marker)
    end=text.find('\n- ID:',start+1)
    return text[start:end if end>=0 else None]


def contract(text):
    result={}
    for name in ('Goal','Acceptance','Children'):
        rows=[line for line in text.splitlines() if line.startswith('  '+name+':')]
        need(len(rows)==(1 if name!='Children' else int(bool(rows))),'whole unique task contract field')
        if rows:
            result[name]=rows[0]
    return result


def derive():
    owner=(BASE/'scope.txt').read_text().splitlines()[0]
    remaining=owner.rsplit('.',1)[0]
    values=remaining.rsplit('.',1)[0]
    headers=values.rsplit('.',1)[0]
    identifiers=[owner,remaining,values,headers,remaining+'.2',remaining+'.3']
    result=subprocess.run(['git','--no-replace-objects','show',REVISION+':'+str(TASK)],capture_output=True,text=True)
    need(result.returncode==0 and not result.stderr,'whole fixed scalar task source')
    current=TASK.read_text()
    bodies={identifier:block(result.stdout,identifier) for identifier in identifiers}
    for identifier,original in bodies.items():
        need(contract(block(current,identifier))==contract(original),'unchanged complete scalar-child and ancestor acceptance')
    return dict(revision=REVISION,task=str(TASK),original_bodies=bodies,
        scope='Whole unchanged source-value/header/remaining-scalar parent and child contracts only; scalar qualification closes no ancestor.')


if __name__ == '__main__':
    product=derive()
    if (BASE/'task-contracts.json').exists():
        need(same(product,load('task-contracts.json')),'whole immutable original task contracts')
    else:
        save('task-contracts.json',product)
    print('PASS complete unchanged scalar-child, ancestor and separately owned successor contracts.')
