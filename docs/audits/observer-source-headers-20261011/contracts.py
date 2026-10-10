"""Whole original source-header parent, completed children and raw-join successor."""
import re
import subprocess
from pathlib import Path
from common import BASE, REVISION, SCOPE, need

TASK=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')


def block(text,identifier):
    marker='- ID: `'+identifier+'`\n'
    need(text.count(marker)==1,'unique complete original source-header task')
    start=text.index(marker);end=text.find('\n- ID:',start+1)
    return text[start:end if end>=0 else len(text)]


def contract(text):
    return {field:re.search(r'^  '+field+r': `(.*)`$',text,re.M).group(1)
            for field in ('Goal','Acceptance','Children') if re.search(r'^  '+field+':',text,re.M)}


def derive(current=None):
    owner=(BASE/'scope.txt').read_text().splitlines()[0];parent=owner.rsplit('.',1)[0];outer=parent.rsplit('.',1)[0]
    values=parent+'.2'
    identifiers=[owner,parent,parent+'.1',values,values+'.1',values+'.2',values+'.3',outer,outer+'.1',outer+'.3']
    command=['git','--no-replace-objects','show',REVISION+':'+str(TASK)]
    actual=subprocess.run(command,capture_output=True,text=True)
    need(actual.returncode==0 and actual.stderr=='','whole fixed original source-header parent acceptance')
    originals={identifier:block(actual.stdout,identifier) for identifier in identifiers}
    text=TASK.read_text() if current is None else current
    for identifier,original in originals.items():
        need(contract(block(text,identifier))==contract(original),'complete unchanged source-header/child/raw-join acceptance and topology')
    for identifier in (parent+'.1',values,values+'.1',values+'.2',values+'.3',outer+'.1'):
        need('\n  Status: `done`\n' in originals[identifier] and '\n  Status: `done`\n' in block(text,identifier),
             'committed and current completed source-header prerequisite child')
    need('\n  Status: `pending`\n' in originals[outer+'.3'],'original raw-join successor was separately pending at the selected epoch')
    return dict(revision=REVISION,command=command,original_bodies=originals,scope=SCOPE)
