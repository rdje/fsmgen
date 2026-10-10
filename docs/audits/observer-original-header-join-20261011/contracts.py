"""Preserve the full unchanged repair and every descendant contract."""
import re
import subprocess
from pathlib import Path
from common import BASE, REVISION, SCOPE, need

TASK=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')


def block(text,identifier):
    marker='- ID: `'+identifier+'`\n'
    need(text.count(marker)==1,'unique complete original observer repair task')
    start=text.index(marker);end=text.find('\n- ID:',start+1)
    return text[start:end if end>=0 else len(text)]


def fields(body):
    return {field:re.search(r'^  '+field+r': `(.*)`$',body,re.M).group(1)
            for field in ('Goal','Acceptance','Children') if re.search(r'^  '+field+':',body,re.M)}


def derive(current=None):
    owner=(BASE/'scope.txt').read_text().splitlines()[0];parent=owner.rsplit('.',1)[0];outer=parent.rsplit('.',1)[0]
    command=['git','--no-replace-objects','show',REVISION+':'+str(TASK)]
    actual=subprocess.run(command,capture_output=True,text=True)
    need(actual.returncode==0 and actual.stderr=='','whole fixed original observer repair task source')
    pending=[parent];originals={}
    while pending:
        identifier=pending.pop();body=block(actual.stdout,identifier);originals[identifier]=body
        pending.extend(re.findall(r'SEMANTIC-INTROSPECTION-MCP-FRONTIER[.0-9]*',fields(body).get('Children','')))
    for identifier in (outer,outer+'.1',outer+'.3'):
        originals[identifier]=block(actual.stdout,identifier)
    text=TASK.read_text() if current is None else current
    for identifier,body in originals.items():
        need(fields(block(text,identifier))==fields(body),'complete unchanged observer repair/descendant/publication acceptance')
        if '\n  Status: `done`\n' in body:
            need('\n  Status: `done`\n' in block(text,identifier),'every committed completed observer repair child stays done')
    need('\n  Status: `pending`\n' in originals[owner] and
         '\n  Status: `pending`\n' in originals[outer+'.3'],'original join and observer publication were separate pending owners')
    return dict(revision=REVISION,command=command,original_bodies=originals,scope=SCOPE)
