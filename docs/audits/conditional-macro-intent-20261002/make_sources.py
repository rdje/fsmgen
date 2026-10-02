import json
from pathlib import Path
base=Path('docs/audits/conditional-macro-intent-20261002')
clauses={
 'select':'(select seen allow datain other)',
 'min':'(min seen datain other)', 'max':'(max seen datain other)',
 'when_bit':'(when-bit datain 1 (set seen other))',
 'unless_bit':'(unless-bit datain 1 (set seen other))',
 'when_field':'(when-field datain (bits 2 1) 1 (set seen other))',
 'unless_field':'(unless-field datain (bits 2 1) 1 (set seen other))',
 'cond':'(cond (allow (set seen datain)) (else (set seen other)))',
}
samples={
 'when_bit':'(when-bit datain 1 (sample other as captured))',
 'unless_bit':'(unless-bit datain 1 (sample other as captured))',
 'when_field':'(when-field datain (bits 2 1) 1 (sample other as captured))',
 'unless_field':'(unless-field datain (bits 2 1) 1 (sample other as captured))',
 'cond':'(cond (allow (sample datain as captured)) (else (sample other as saved)))',
}
interface='(interface (input request) (input allow) (input datain (width 3)) (input other (width 3)) (output seen (width 3)) (output done))'
cases=[]
def add(name,transaction_body,extra='',**metadata):
 source=f'(actor {name}\n  (clock clk) (reset (rst_n sync active_low))\n  {interface}\n  {extra}\n  (transaction main {transaction_body} (complete done)))\n'
 (base/'sources'/f'{name}.isf').write_text(source)
 cases.append(dict(name=name,**metadata))
for op,clause in clauses.items():
 for position,prefix in [('first',''),('later','(on request)')]:
  add(f'{position}_{op}',f'{prefix} {clause}',family=op,position=position,body='set')
for op,clause in samples.items():
 for position,prefix in [('first',''),('later','(on request)')]:
  add(f'{position}_{op}_sample',f'{prefix} {clause}',family=op,position=position,body='sample')
for op in ['select','when_bit','cond']:
 for position,prefix in [('first',''),('later','(on request)')]:
  add(f'{position}_proc_{op}',f'{prefix} (call choose datain other)',extra=f'(proc choose (params (v (width 3)) (alt (width 3))) {clauses[op].replace("datain","v").replace("other","alt")})',family=op,position=position,context='proc',body='set')
add('first_proc_when_sample','(call capture other)',extra='(proc capture (params (v (width 3))) (when allow (sample v as captured)))',family='authored_when',position='first',context='proc',body='sample')
add('first_when_sample','(when allow (sample other as captured))',family='authored_when',position='first',body='sample')
add('first_select_zero','(params (DELAY 0)) (wait DELAY) '+clauses['select'],family='select',position='first',context='zero',body='set')
add('first_bit_sample_zero','(wait 0) '+samples['when_bit'],family='when_bit',position='first',context='zero',body='sample')
add('initialized_select','(local temp (width 3) (init 1)) '+clauses['select'],family='select',position='later',context='init',body='set')
add('nested_select','(on request) (when allow '+clauses['select']+')',family='select',position='later',context='nested',body='set')
for name,body in [('domain_first_select',clauses['select']),('domain_later_select','(on request) '+clauses['select']),('domain_first_sample',samples['when_field'])]:
 domain_interface=interface
 for pin in ['request','allow','done']:
  domain_interface=domain_interface.replace(f' {pin})',f' {pin} (domain io))')
 for pin in ['datain','other','seen']:
  domain_interface=domain_interface.replace(f' {pin} (width 3))',f' {pin} (width 3) (domain io))')
 source=f'''(actor {name}
  (clock-domains
    (domain idle (clock idle_clk) :default)
    (domain io (clock clk) (reset (rst_n sync active_low))))
  {domain_interface}
  (transaction main (domain io) {body} (complete done)))
'''
 (base/'sources'/f'{name}.isf').write_text(source)
 cases.append(dict(name=name,context='domain',body='sample' if name.endswith('sample') else 'set',family='when_field' if name.endswith('sample') else 'select',position='later' if 'later' in name else 'first',module=name+'__domain_io'))
for position in ['first','later']:
 name=position+'_generated_select'
 prefix='' if position=='first' else '(on request)'
 source=f'''(actor {name}
  (clock clk) (reset (rst_n sync active_low))
  {interface}
  (transaction worker
    (ports (input payload (width 3)) (output result (width 3)))
    (params (MODE 1)) {prefix} (select result allow payload other) (complete done))
  (transaction main (on request)
    (do worker (params (MODE 1)) (bind (input payload datain) (output result seen)))
    (complete done)))
'''
 (base/'sources'/f'{name}.isf').write_text(source)
 cases.append(dict(name=name,context='generated',module='worker',family='select',position=position,body='set'))
(base/'cases.json').write_text(json.dumps(cases,indent=2,sort_keys=True)+'\n')
print('Created',len(cases),'complete actual sources')
