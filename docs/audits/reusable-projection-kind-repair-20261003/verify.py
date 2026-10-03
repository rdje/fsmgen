"""Independent complete source delta, finite kinds and whole conservation."""
import copy, hashlib, json, re, subprocess, sys
from pathlib import Path
B=Path(__file__).parent
OLD=Path('docs/audits/reusable-cause-repair-20261003')
REV='48b2380d79e44de815587c093a88ede6a244d34d'
TEST='t/1947-isf-formal-reusable-products.t'
def load(name):return json.loads((B/name).read_text())
def same(a,b):
 assert json.dumps(a,sort_keys=True,separators=(',',':'))==json.dumps(b,sort_keys=True,separators=(',',':')),'value/kind/field mismatch'
def source(path):return subprocess.check_output(['git','show',REV+':'+path]).decode()
binding=load('bindings.json')
assert set(binding)=={'baseline','metadata','sources'} and binding['baseline']==REV
paths=subprocess.check_output(['git','ls-tree','-r','--name-only',REV,'--','bin','perl','t','scripts','isf']).decode().splitlines()
assert set(binding['metadata'])==set(paths)
for path,row in binding['metadata'].items():
 raw=Path(path).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
unchanged=[p for p in paths if p!=TEST]
hashes=subprocess.check_output(['git','hash-object','--stdin-paths'],input=('\n'.join(unchanged)+'\n').encode()).decode().splitlines()
gitrows=subprocess.check_output(['git','ls-tree','-r',REV,'--','bin','perl','t','scripts','isf']).decode().splitlines()
wanted={r.split('\t',1)[1]:r.split()[2] for r in gitrows}
for p,h in zip(unchanged,hashes):assert h==wanted[p]
for p,body in binding['sources'].items():assert body==Path(p).read_text()
before=source(TEST)
copyfn="""sub source_value_copy {
    my ($value) = @_;
    return {map {$_ => source_value_copy($value->{$_})} keys %$value}
        if ref($value) eq 'HASH';
    return [map {source_value_copy($_)} @$value] if ref($value) eq 'ARRAY';
    die 'unexpected source reference' if ref($value);
    return $value;
}
"""
expected=before.replace('use Storable qw(dclone);','use Storable qw(dclone);\nuse JSON::PP;')
expected=expected.replace('my $work = tempdir(CLEANUP => 1);','my $work = tempdir(CLEANUP => 1);\nmy $json = JSON::PP->new->canonical;')
expected=expected.replace('sub parse {',copyfn+'sub parse {',1)
expected=expected.replace('my $a = dclone($p->{actor});','my $a = source_value_copy($p->{actor});')
replacements=[
 ('my $before = dclone($actor);','my $before = $json->encode($actor);'),
 ('is_deeply($r, actual_products($l->build_module($actor), $p->{generated_children}),','is($json->encode($r), $json->encode(actual_products($l->build_module($actor), $p->{generated_children})), '),
 ('is_deeply(actual_products($l->build_module($physical), $p->{generated_children}), $r,','is($json->encode(actual_products($l->build_module($physical), $p->{generated_children})), $json->encode($r),'),
 ('is_deeply($l->prepare_formal_source($physical)->{reusable_child_products}, $r,','is($json->encode($l->prepare_formal_source($physical)->{reusable_child_products}), $json->encode($r),'),
 ('is_deeply($p->{actor}, $before,','is($json->encode($p->{actor}), $before,'),
 ('is_deeply($actor, $before,','is($json->encode($actor), $before,'),
 ('my $prior = dclone($p->{actor});','my $prior = $json->encode($p->{actor});'),
 ('is_deeply($p->{actor}, $prior,','is($json->encode($p->{actor}), $prior,'),
 ('my $before = dclone($p->{generated_child_products});','my $before = $json->encode($p->{generated_child_products});'),
 ('is_deeply($p->{generated_child_products}, $before,','is($json->encode($p->{generated_child_products}), $before,'),
 ('is_deeply(actual_products($l->build_module($physical), $q->{generated_children}), $q->{reusable_child_products},','is($json->encode(actual_products($l->build_module($physical), $q->{generated_children})), $json->encode($q->{reusable_child_products}),'),
]
for old,new in replacements:
 assert old in expected;expected=expected.replace(old,new.rstrip() if old.startswith('is_deeply($r,') else new)
expected=expected.replace('my $physical = project($p);\n    is(','''my $physical = project($p);
    is($json->encode([map {$physical->{$_}} qw(library_uses actor_network _atl_actor_type_resolutions)]),
        $json->encode([map {$p->{actor}{$_}} qw(library_uses actor_network _atl_actor_type_resolutions)]),
        "$label projection preserves complete reusable source metadata and kinds");
    is(''',1)
assert expected==binding['sources'][TEST]
mixed=re.search(r"my \$mixed = <<'ISF';\n(.*?)\nISF",before,re.S)[1]+'\n'
width_source=mixed.replace('(transaction worker','(storage (var payload (width 8))) (transaction worker')
exec(compile((B/'models.py').read_text(),str(B/'models.py'),'exec'))
prior=load('before-products.json');current=load('products.json')
verify_products(prior);verify_products(current,True)
same(prior,json.loads((OLD/'products.json').read_text()))
# Authored FIFO depth and data width root the selected primitive kinds.
fifo_source=source('isf/common/fifo.isf')
assert '(bank data (width 8) (depth 4))' in fifo_source
assert '(DATA_WIDTH 8)' in source('isf/fifo_library_use.isf')
def actor_kinds(actor):
 bank=actor['library_uses'][0]['actor']['storage'][3]
 same([bank['name'],bank['depth'],bank['width']],['data',4,8])
 same([s['index'] for s in bank['signals']],list(range(4)))
 same([actor['library_uses'][0]['bindings'][i]['width'] for i in (3,7)],[8,8])
def product_kinds(product):
 child=product['children']['fifo_library_use__u_fifo']
 same([s['index'] for s in child['declared_storage'][3]['signals']],list(range(4)))
 for pointer,block in (('wr_ptr',28),('rd_ptr',29)):
  assigns=child['dt_blocks'][block]['assignments']
  same([a['bank_index'] for a in assigns],list(range(4)))
  same([a['guard']['expr_ast'][2] for a in assigns],list(range(4)))
  offset=68 if pointer=='wr_ptr' else 72
  provenance=child['assignment_provenance'][offset:offset+4]
  same([a['condition_terms']['eq:'+pointer] for a in provenance],list(range(4)))
  same([a['activation']['assignment_guard']['expr_ast'][2] for a in provenance],list(range(4)))
 same([product['library_uses'][0]['bindings'][i]['width'] for i in (3,7)],[8,8])
def verify_conservation(data):
 verify_products(data,True)
 for row,old in zip(data['rows'],prior['rows']):
  if row['id']!='fifo_library_use':
   expected=copy.deepcopy(old)
   widths={'atl_resolved_child_pin_ingress_vector_multi_pipeline':[8,4],
    'atl_resolved_child_pin_egress_vector_multi_pipeline':[8,4],
    'atl_two_child_vector_data_pipeline':[8]}.get(row['id'])
   if widths:
    signals=['reader_payload','writer_payload'] if row['id']=='atl_two_child_vector_data_pipeline' else ['worker_payload','worker_sideband' if 'ingress' in row['id'] else 'worker_status']
    for path in (('physical','actor_network'),('physical_module','actor_network'),('reprepared','actor','actor_network')):
     target=expected
     for key in path:target=target[key]
     for index,width in enumerate(widths):target['data_movements'][index]['width']=width
    port_widths=[8,8] if len(widths)==1 else widths
    for index,(signal,width) in enumerate(zip(signals,port_widths)):
     expected['physical_module']['ports'][6+index]['width']=width
     expected['physical_module']['signal_widths'][signal]=width
     for field in ('parent_activation_products','parent_wiring_products'):
      expected['reprepared'][field]['ports'][6+index]['width']=width
    same([m['width'] for m in row['original']['actor_network']['data_movements']],widths)
   same(row,expected);continue
  for key in ('id','source','actor','original','input_equal','prepared_actor_equal','prepared','module'):
   same(row[key],old[key])
  actor_kinds(row['original']);actor_kinds(row['physical']);actor_kinds(row['reprepared']['actor'])
  r=row['prepared']['reusable_child_products'];product_kinds(r)
  same(products_of(row['physical_module'],{}),r)
  same(row['reprepared']['reusable_child_products'],r)
  product_kinds(products_of(row['physical_module'],{}))
  expected_actor=copy.deepcopy(old['physical'])
  for index in range(4):expected_actor['library_uses'][0]['actor']['storage'][3]['signals'][index]['index']=index
  for index in (3,7):expected_actor['library_uses'][0]['bindings'][index]['width']=8
  same(row['physical'],expected_actor)
  expected_module=copy.deepcopy(old['physical_module']);expected_module.update(r)
  same(row['physical_module'],expected_module)
  expected_prepared=copy.deepcopy(old['reprepared']);expected_prepared['actor']=expected_actor;expected_prepared['reusable_child_products']=r
  same(row['reprepared'],expected_prepared)
verify_conservation(current)
clones=load('clone-inputs.json')
assert set(clones)=={'rows'} and len(clones['rows'])==9
for row,product in zip(clones['rows'],current['rows']):
 assert set(row)=={'id','source','original','current','prior','after'}
 same([row[k] for k in ('id','source','original')],[product['id'],product['source'],product['original']])
 same(row['current'],row['original']);same(row['after'],row['original'])
 expected=copy.deepcopy(row['original'])
 if row['id']=='fifo_library_use':
  for index in range(4):expected['library_uses'][0]['actor']['storage'][3]['signals'][index]['index']=str(index)
  for index in (3,7):expected['library_uses'][0]['bindings'][index]['width']='8'
 if row['id'] in ('atl_resolved_child_pin_ingress_vector_multi_pipeline','atl_resolved_child_pin_egress_vector_multi_pipeline','atl_two_child_vector_data_pipeline'):
  for movement in expected['actor_network']['data_movements']:movement['width']=str(movement['width'])
 same(row['prior'],expected)
if '--trust-prior-kinds' in sys.argv:verify_conservation(prior)
for label in ('source','actor-kind','product-kind','movement-kind','origin','schema','member'):
 bad=copy.deepcopy(current)
 if label=='source':bad['rows'][0]['source']='(not_actor)'
 elif label=='actor-kind':bad['rows'][0]['physical']['library_uses'][0]['actor']['storage'][3]['signals'][0]['index']='0'
 elif label=='product-kind':bad['rows'][0]['physical_module']['children']['fifo_library_use__u_fifo']['dt_blocks'][28]['assignments'][0]['bank_index']='0'
 elif label=='movement-kind':bad['rows'][2]['physical']['actor_network']['data_movements'][0]['width']='8'
 elif label=='origin':bad['rows'][0]['prepared']['reusable_child_products']['children']['fifo_library_use__u_fifo']['library_origin']['instance']='wrong'
 elif label=='schema':bad['rows'][0]['unknown']=1
 else:bad['rows'].pop()
 try:verify_conservation(bad)
 except AssertionError:print('whole corruption rejects:',label)
 else:raise AssertionError('accepted '+label)
assert (B/'current.status').read_text()=='0\n' and 'Files=2, Tests=102' in (B/'current.txt').read_text()
assert (B/'prior-red.status').read_text()=='1\n' and 'failed 6 tests of 95' in (B/'prior-red.txt').read_text() and 'failed 1 test of 3' in (B/'prior-red.txt').read_text()
assert (B/'ordinary.status').read_text()==(B/'before-ordinary.status').read_text()==(B/'clone-inputs.status').read_text()=='0\n'
assert (B/'source-history.txt').read_text().startswith('9f9fc38802f0cc516077628756fc171a15e9e22b ')
assert (B/'original-T1947.t').read_bytes()==subprocess.check_output(['git','show','9f9fc38802f0cc516077628756fc171a15e9e22b:'+TEST])
if (B/'manifest.json').exists():
 members=load('manifest.json')['members']
 assert set(members)=={str(p.relative_to(B)) for p in B.rglob('*') if p.is_file() and p.name!='manifest.json'}
 for name,row in members.items():
  raw=(B/name).read_bytes();same(row,{'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
print('PASS complete projection source/kinds/conservation and real prior failure; wider child internals remain cold-owned.')
