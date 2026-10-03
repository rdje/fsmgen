import ast,json
from pathlib import Path
B=Path('docs/audits/reservation-coverage-helper-causes-20261003')
tree=ast.parse((B/'contracts.py').read_text())
expected_causes=ast.literal_eval(next(node.value for node in tree.body if isinstance(node,ast.Assign)))
rows=json.loads((B/'initial-observations-unqualified.json').read_text())
assert len(rows['consumers'])==len(expected_causes)
for row in rows['consumers']:
    label=row['label'].removesuffix(' diagnosed')
    expected=expected_causes[label]
    actual=row['error'].split('\n')[0]
    assert actual==expected,('source-declared cause differs',label,expected,actual)
(B/'declared-causes.json').write_text(json.dumps(expected_causes,sort_keys=True,indent=2)+'\n')
print('PASS complete source-declared cause table against actual native primaries; declarations are not derived from errors.')
