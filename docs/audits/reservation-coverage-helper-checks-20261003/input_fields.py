import json
from pathlib import Path
rows=json.loads(Path('docs/audits/reservation-coverage-helper-causes-20261003/initial-observations-unqualified.json').read_text())
def restore(node,nodes=None,path=''):
    nodes={} if nodes is None else nodes
    if not isinstance(node,list):return node
    kind,value=node
    if kind=='reference':return nodes[value]
    out={} if kind=='hash' else [];nodes[path]=out
    if kind=='hash':
        for key in sorted(value):out[key]=restore(value[key],nodes,path+'/'+key.replace('~','~0').replace('/','~1'))
    else:
        out.extend(restore(child,nodes,path+'/'+str(i)) for i,child in enumerate(value))
    return out
for item in rows['consumers']:
    p,plan,modules=restore(rows['api'][item['api_index']]['before'])
    print(item['label'],json.dumps({'source_actor':p['actor']['actor_name'],
         'payload_physical':plan['formals']['main']['payload']['physical_name'],
         'prepared_worker':p['generated_child_products']['worker']['actor_name']},sort_keys=True))
