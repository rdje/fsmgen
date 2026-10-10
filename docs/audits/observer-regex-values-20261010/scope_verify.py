"""Authenticate the original child, ancestors and separately owned successor."""
import subprocess
from pathlib import Path
from common import BASE, REVISION, load, module, need, same, save

TASK=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
prior=module(Path('docs/audits/observer-scalar-values-20261010/scope_verify.py'))


def derive():
    owner=(BASE/'scope.txt').read_text().splitlines()[0]
    remaining=owner.rsplit('.',1)[0]
    values=remaining.rsplit('.',1)[0]
    identifiers=[owner,remaining,values,values.rsplit('.',1)[0],remaining+'.1',remaining+'.3']
    command=['git','--no-replace-objects','show',REVISION+':'+str(TASK)]
    result=subprocess.run(command,capture_output=True,text=True)
    need(result.returncode==0 and not result.stderr,'whole original regex task source')
    bodies={identifier:prior['block'](result.stdout,identifier) for identifier in identifiers}
    current=TASK.read_text()
    for identifier,body in bodies.items():
        need(prior['contract'](prior['block'](current,identifier))==prior['contract'](body),
             'unchanged complete regex/remaining/value/header acceptance')
    return dict(revision=REVISION,task=str(TASK),original_bodies=bodies,
        scope='Only the regex child can close; original and ancestor acceptance and opaque boundaries retain.')


if __name__=='__main__':
    result=derive()
    if (BASE/'task-contracts.json').exists():
        need(same(result,load('task-contracts.json')),'whole immutable regex task contracts')
    else:
        save('task-contracts.json',result)
    print('PASS unchanged whole regex-child and ancestor/sibling contracts.')
