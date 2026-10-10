"""Preserve every complete original parent, child and full-header successor contract."""
import re
import subprocess
from pathlib import Path
from common import BASE, REVISION, SCOPE, need

TASK = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')


def block(text, identifier):
    marker = '- ID: `'+identifier+'`\n'
    need(text.count(marker)==1, 'unique complete original task node')
    start=text.index(marker)
    end=text.find('\n- ID:', start+1)
    return text[start:end if end>=0 else len(text)]


def contract(text):
    return {field:re.search(r'^  '+field+r': `(.*)`$', text, re.M).group(1)
            for field in ('Goal', 'Acceptance', 'Children') if re.search(r'^  '+field+':', text, re.M)}


def derive(current=None):
    owner=(BASE/'scope.txt').read_text().splitlines()[0]
    parent=owner.rsplit('.',1)[0]
    remaining=parent+'.2'
    header=parent.rsplit('.',1)[0]
    identifiers=[owner,parent,parent+'.1',remaining,remaining+'.1',remaining+'.2',remaining+'.3',header,header+'.1',header+'.3']
    command=['git','--no-replace-objects','show',REVISION+':'+str(TASK)]
    result=subprocess.run(command,capture_output=True,text=True)
    need(result.returncode==0 and result.stderr=='', 'whole original task acceptance Git custody')
    originals={identifier:block(result.stdout,identifier) for identifier in identifiers}
    current=TASK.read_text() if current is None else current
    for identifier,original in originals.items():
        need(contract(block(current,identifier))==contract(original), 'complete unchanged task Goal/Acceptance/Children')
    for identifier in [parent+'.1',remaining,remaining+'.1',remaining+'.2',remaining+'.3',header+'.1']:
        need('\n  Status: `done`\n' in originals[identifier]
             and '\n  Status: `done`\n' in block(current,identifier), 'committed and current prerequisite child closure')
    need('\n  Status: `pending`\n' in originals[header+'.3'], 'full-header successor was separately pending at the qualified epoch')
    return dict(revision=REVISION, command=command, original_bodies=originals, scope=SCOPE)
