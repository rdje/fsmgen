"""Whole unchanged remaining-value parent/children and higher successor contracts."""
import subprocess
from pathlib import Path
from common import BASE,REGEX,REVISION,load,module,need,same,save

TASK=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
helpers=module(Path('docs/audits/observer-scalar-values-20261010/scope_verify.py'))


def derive():
    owner=(BASE/'scope.txt').read_text().splitlines()[0]
    remaining=owner.rsplit('.',1)[0]
    values=remaining.rsplit('.',1)[0]
    identifiers=[owner,remaining,remaining+'.1',remaining+'.2',values,values+'.1',values+'.3',values.rsplit('.',1)[0]]
    result=subprocess.run(['git','--no-replace-objects','show',REVISION+':'+str(TASK)],capture_output=True,text=True)
    need(result.returncode==0 and result.stderr=='','whole original remaining-value acceptance source')
    originals={identifier:helpers['block'](result.stdout,identifier) for identifier in identifiers}
    current=TASK.read_text()
    for identifier,original in originals.items():
        need(helpers['contract'](helpers['block'](current,identifier))==helpers['contract'](original),
             'whole unchanged remaining-value/child/higher acceptance and topology')
    for identifier in (remaining+'.1',remaining+'.2',values+'.1'):
        need('\n  Status: `done`\n' in helpers['block'](current,identifier),
             'complete committed scalar/regex/predicate child status')
    return dict(revision=REVISION,task=str(TASK),original_bodies=originals,
        scope='Only the remaining-value parent and this boundary child can close; higher source-value/full-header/observer/raw successors retain their complete original acceptance.')


if __name__=='__main__':
    product=derive()
    if (BASE/'task-contracts.json').exists():
        need(same(product,load('task-contracts.json')),'whole immutable remaining-value and higher contracts')
    else:
        save('task-contracts.json',product)
    print('PASS whole unchanged remaining-value parent, all child and higher successor contracts.')
