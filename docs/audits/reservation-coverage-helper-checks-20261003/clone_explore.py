import ast,json
from pathlib import Path
C=Path('docs/audits/reservation-coverage-helper-checks-20261003')
source=(C/'explore.py').read_text()
node=next(n for n in ast.parse(source).body if isinstance(n,ast.FunctionDef) and n.name=='diffs')
exec(ast.get_source_segment(source,node))
rows=json.loads(Path('docs/audits/reservation-coverage-helper-causes-20261003/initial-observations-unqualified.json').read_text())
changed=[]
for i,row in enumerate(rows['clones']):
    assert not diffs(row['before'],row['after']),('original changed',i)
    delta=diffs(row['before'],row['clone'])
    if delta:changed.append({'index':i,'line':row['line'],'differences':delta})
(C/'clone-differences-unqualified.json').write_text(json.dumps(changed,sort_keys=True,indent=2)+'\n')
print('Actual clone calls:',len(rows['clones']),'changed copies:',len(changed))
print('Changed copies by line:',{line:sum(row['line']==line for row in changed) for line in sorted({row['line'] for row in changed})})
print('First actual difference:',changed[0] if changed else None)
