import copy
import json
from pathlib import Path
namespace={}
source=Path('docs/audits/conditional-origin-atl-20261002/verify-first.py').read_text()
exec(compile(source.split("products = {p.name:json.loads")[0],'independent-oracle-prefix','exec'),namespace)
product=json.loads(Path('docs/audits/conditional-origin-atl-20261002/current-bound/later_unless-field.json').read_text())
actor,proof=namespace['expected_product'](namespace['originals']['later_unless-field.json'],product['label'],product['documents'])
bad_actor,bad_proof=copy.deepcopy(actor),copy.deepcopy(proof)
namespace['mutate']('scope',bad_actor,bad_proof)
actual=next(c for c in product['controls'] if c['name']=='scope')
def differences(left,right,path='proof'):
    if type(left) is not type(right):print(path,'type',type(left).__name__,type(right).__name__)
    elif isinstance(left,dict):
        assert set(left)==set(right)
        for key in left:differences(left[key],right[key],path+'/'+key)
    elif isinstance(left,list):
        assert len(left)==len(right)
        for i,(a,b) in enumerate(zip(left,right)):differences(a,b,path+'/'+str(i))
    elif left!=right:print(path,'actual=',left,'expected=',right)
differences(actual['proof'],bad_proof)
print('oracle alias:',proof['atl_resolutions'][0]['exports'] is proof['libraries'][1]['exports'])
print('opaque product alias:',product['proof']['atl_resolutions'][0]['exports'] is product['proof']['libraries'][1]['exports'])
