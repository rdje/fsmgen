import hashlib
import json
import re
import subprocess
from pathlib import Path

root = Path(__file__).parent
baseline = json.loads((root/'baseline.json').read_text())
final = json.loads((root/'final-binding.json').read_text())
assert subprocess.check_output(['git','show',baseline['head']+':perl/HLinkSubst.pm']) == (root/'before/HLinkSubst.pm').read_bytes()
assert Path('perl/HLinkSubst.pm').read_bytes() == (root/'after.pm').read_bytes()
assert Path('t/2051-hlink-matcher-dispatch.t').read_bytes() == (root/'test.t').read_bytes()
for name,digest in final['inputs'].items():
    assert hashlib.sha256(Path(name).read_bytes()).hexdigest() == digest
    if name != 'perl/HLinkSubst.pm': assert digest == baseline['inputs'][name]
assert hashlib.sha256((root/'before/HLinkSubst.pm').read_bytes()).hexdigest() == baseline['inputs']['perl/HLinkSubst.pm']
original='57563dcaa48a3b80877823eb510f1e33d6742eac'
for file,path in [('history-hlink.txt','perl/HLinkSubst.pm'),('history-linkedre.txt','perl/LinkedRE.pm')]:
    assert (root/file).read_text() == original+' 2025-08-30 update\n'
    assert subprocess.check_output(['git','show',original+':'+path]) == subprocess.check_output(['git','show',baseline['head']+':'+path])
expected = [
 ('empty','',None), ('literal','literal_value',['literal_value']),
 ('spaces','plain words',['plain words']), ('reference','[ROOT]',[{'reference':'ROOT'}]),
 ('interleaved','pre[ROOT]/tail',['pre',{'reference':'ROOT'},'/tail']),
 ('adjacent','[A][B]',[{'reference':'A'},{'reference':'B'}]),
 ('nested_reference','[A[B]]',[{'reference':'A[B]'}]),
 ('braces','{a{b}}',['{a{b}}']),
 ('mixed','before{a}[B]after',['before','{a}',{'reference':'B'},'after']),
 ('escaped',r'\[literal\]',[r'\[literal\]']),
]
errors = [('dangling',']',1,'Dangling closing bracket'),
 ('unclosed_reference','[ROOT',2,'Unmatched closing bracket'),
 ('unclosed_brace','{body',2,'Unmatched closing brace')]
linked={'NAME':'literal_value','PATH':'literal_value/payload','nested':{'value':'literal_value'},'values':['left','literal_value']}

def good(view, value):
    assert view == {'success':1,'product':value,'stdout':json.dumps(value,separators=(',',':'),sort_keys=True),'stderr':'','error':''}

def check(data):
    products=data['products']; assert len(products)==14
    for (name,source,value),actual in zip(expected,products):
        assert actual['case']=={'name':name,'source':source,'expected':value}
        assert set(actual['views'])=={'grammar','static','warm'}
        for view in actual['views'].values(): good(view,value)
    for (name,source,status,message),actual in zip(errors,products[10:]):
        stdout='(HLinkSubst) -E- '+message+'\n'
        assert actual['case']=={'name':name,'source':source,'status':status,'stdout':stdout}
        for view in actual['views'].values():
            assert view['success']==0 and view['product'] is None and view['stderr']=='' and view['stdout']==stdout
            assert re.search('exited with value '+str(status)+'$',view['error'])
    assert products[-1]['case']=={'name':'linked'}
    good(products[-1]['views']['linked'],linked)

for name in ('after','focused'): check(json.loads((root/(name+'.json')).read_text()))
for name in ('before','red-final'):
    data=json.loads((root/(name+'.json')).read_text());assert len(data['products'])==14
    for i,(_,_,value) in enumerate(expected): good(data['products'][i]['views']['grammar'],value)
    # The exact source counterfactual retains actual factory and grammar code;
    # its own fresh literal dispatch fails while the independent grammar succeeds.
    broken=data['products'][1]['views']['static']
    assert broken['success']==0 and broken['product'] is None
    assert broken['stdout']=='(HLinkSubst) -E- Unmatched closing bracket\n'
    assert 'Failed: 13' in (root/(name+'.tap')).read_text()
configuration={'values':{'NAME':'late_configuration','PATH':'tree/payload','FX_TOP':'tree',
 'preload_list':{'link':'fixture_link','conf':'fixture_conf'},'fixture_link':{'LINK_VALUE':'fixed'},'fixture_conf':{'CONF_VALUE':'retained'}},
 'singleton':1,'retained_name':'late_configuration'}
actual=json.loads((root/'global-prerequisite.json').read_text())['products']
assert actual[:2]==actual[2:]
for i,view in enumerate(actual):
    if i%2==0:
        assert view['success']==0 and view['product'] is None
        assert view['stderr']=='fileparse(): need a valid pathname at modules/Global.pm line 21.\n'
    else:
        assert view['product']==configuration and view['success']==1 and view['stderr']=='' and view['error']==''
assert 'Failed: 2' in (root/'global-prerequisite.tap').read_text()
assert 'All tests successful' in (root/'focused.tap').read_text() and 'Files=5, Tests=55' in (root/'focused.tap').read_text()
for key,value in [('product',['forged']),('success',0),('stderr','forged')]:
    bad=json.loads((root/'after.json').read_text());bad['products'][1]['views']['static'][key]=value
    try: check(bad)
    except AssertionError: continue
    raise AssertionError('hostile complete matcher product accepted')
print('PASS exact original history/source binding, independent whole literals/grammar/error/control products, restored absolute Global values and hostile saved-product refusals')
