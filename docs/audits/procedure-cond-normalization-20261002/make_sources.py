import json
from pathlib import Path

base=Path('docs/audits/procedure-cond-normalization-20261002')
(base/'sources').mkdir(parents=True,exist_ok=True)
iface='(interface (input request) (input allow) (input datain (width 3)) (input other (width 3)) (output seen (width 3)) (output done))'
definition=['cond', ['c', ['set','dst','v']], ['else', ['set','dst','alt']]]
ordinary=['when','allow',['set','seen','datain']]
otherwise=['when',['!','allow'],['set','seen','other']]
on=['on','request']; complete=['complete','done']
proc='(proc choose (params (c (width 1)) (v (width 3)) (alt (width 3)) (out dst (width 3))) (cond (c (set dst v)) (else (set dst alt))))'
cases=[]
def add(name,body,clauses=None,decl=proc,original=definition,extra='',**opts):
    source=f'(actor {name}\n  {iface}\n  {decl}\n  {extra}\n  (transaction main {body}))\n'
    (base/'sources'/f'{name}.isf').write_text(source)
    case=dict(name=name,definition=[original],**opts)
    if clauses is not None: case['clauses']=clauses
    cases.append(case)
call='(call choose allow datain other seen)'
add('basic',f'(on request) {call} (complete done)',[on,ordinary,otherwise,complete])
add('expression','(on request) (call choose (== datain other) (+ datain 1) (^ other 1) seen) (complete done)',
    [on,['when',['==','datain','other'],['set','seen',['+','datain','1']]],
     ['when',['!',['==','datain','other']],['set','seen',['^','other','1']]],complete])
priority=['cond',['c',['set','seen','1']],['d',['set','seen','2']],['else',['set','seen','3']]]
add('priority','(on request) (call choose allow request) (complete done)',
    [on,['when','allow',['set','seen','1']],['when',['&',['!','allow'],'request'],['set','seen','2']],
     ['when',['&',['!','allow'],['!','request']],['set','seen','3']],complete],
    decl='(proc choose (params (c (width 1)) (d (width 1))) (cond (c (set seen 1)) (d (set seen 2)) (else (set seen 3))))',original=priority)
add('no_else','(on request) (call choose allow) (complete done)',[on,['when','allow',['set','seen','datain']],complete],
    decl='(proc choose (params (c (width 1))) (cond (c (set seen datain))))',original=['cond',['c',['set','seen','datain']]])
add('else_only','(on request) (call choose) (complete done)',[on,['when',1,['set','seen','datain']],complete],
    decl='(proc choose (params) (cond (else (set seen datain))))',original=['cond',['else',['set','seen','datain']]])
nested=['cond',['c',['cond',['d',['set','seen','datain']],['else',['set','seen','other']]]],['else',['set','seen','0']]]
add('nested_cond','(on request) (call choose allow request) (complete done)',
    [on,['when','allow',['when','request',['set','seen','datain']],['when',['!','request'],['set','seen','other']]],
     ['when',['!','allow'],['set','seen','0']],complete],
    decl='(proc choose (params (c (width 1)) (d (width 1))) (cond (c (cond (d (set seen datain)) (else (set seen other)))) (else (set seen 0))))',original=nested)
for name,kw,head in [('outer_when','when','request'),('outer_while','while','request'),('outer_until','until','request'),('outer_repeat','repeat','2')]:
    options = {'lower_reason': "unsupported '(when ...)' clause in repeat body"} if kw == 'repeat' else {}
    add(name,f'(on request) ({kw} {head} {call}) (complete done)',[on,[kw,head,ordinary,otherwise],complete],**options)
add('repeat_control','(on request) (repeat 2 (cond (allow (set seen datain)) (else (set seen other)))) (complete done)',
    [on,['repeat','2',ordinary,otherwise],complete],lower_reason="unsupported '(when ...)' clause in repeat body")
add('outer_switch',f'(on request) (switch allow (0 {call}) (1 (set seen 0))) (complete done)',
    [on,['switch','allow',['0',ordinary,otherwise],['1',['set','seen','0']]],complete])
nested_proc='(proc choose (params (c (width 1)) (v (width 3)) (alt (width 3)) (out dst (width 3))) (cond (c (call assign v dst)) (else (call assign alt dst)))) (proc assign (params (v (width 3)) (out dst (width 3))) (set dst v))'
add('nested_call',f'(on request) {call} (complete done)',[on,ordinary,otherwise,complete],decl=nested_proc,
    original=['cond',['c',['call','assign','v','dst']],['else',['call','assign','alt','dst']]])
add('multiple_calls',f'(on request) {call} (call choose request other datain seen) (complete done)',
    [on,ordinary,otherwise,['when','request',['set','seen','other']],['when',['!','request'],['set','seen','datain']],complete])
add('direct_formal',f'(ports (input allow) (input datain (width 3)) (output seen (width 3))) (on request) {call} (complete done)',
    [on,ordinary,otherwise,complete])
add('generated',f'(params (MODE 1)) (ports (input value (width 3)) (output result (width 3))) (on request) (call choose allow value other result) (complete done)',
    [['params',['MODE','1']],on,['when','allow',['set','result','value']],['when',['!','allow'],['set','result','other']],complete],
    extra='(transaction parent (on request) (do main (params (MODE 1)) (bind (input value datain) (output result seen))) (complete done))')
add('domain',f'(domain io) (on request) {call} (complete done)',[on,ordinary,otherwise,complete],
    extra='(clock-domains (domain idle (clock idle_clk) :default) (domain io (clock clk) (reset (rst_n sync active_low))))')
p=base/'sources/domain.isf'
s=p.read_text()
for pin in ['request','allow','done']: s=s.replace(f' {pin})',f' {pin} (domain io))',1)
for pin in ['datain','other','seen']: s=s.replace(f' {pin} (width 3))',f' {pin} (width 3) (domain io))',1)
p.write_text(s)
add('first_actions',f'{call} (complete done)',[ordinary,otherwise,complete],
    lower_reason="when activation body supports only '(sample port as name)' clauses")
sample_proc='(proc choose (params (c (width 1))) (cond (c (sample datain as captured)) (else (sample other as saved))))'
add('first_samples','(call choose allow) (complete done)',
    [['when','allow',['sample','datain','as','captured']],['when',['!','allow'],['sample','other','as','saved']],complete],
    decl=sample_proc,original=['cond',['c',['sample','datain','as','captured']],['else',['sample','other','as','saved']]],entry_kind='entry')
add('authored_entry','(call choose allow) (complete done)',[['when','allow',['sample','datain','as','captured']],complete],
    decl='(proc choose (params (c (width 1))) (when c (sample datain as captured)))',original=['when','c',['sample','datain','as','captured']],entry_kind='entry')
add('unused_bad_cond','(on request) (set seen datain) (complete done)',[on,['set','seen','datain'],complete],
    decl='(proc choose (params) (cond (else (set seen datain)) (allow (set seen other))))',
    original=['cond',['else',['set','seen','datain']],['allow',['set','seen','other']]])
for name,form,reason in [('empty_body','(cond (c))','has an empty body'),
    ('else_order','(cond (else (set seen 0)) (c (set seen 1)))',"'else' must be the last branch"),
    ('non_list','(cond c)','branch must be a')]:
    add(name,'(on request) (call choose allow) (complete done)',decl=f'(proc choose (params (c (width 1))) {form})',parse_reason=reason)
add('direct_recursion','(on request) (call choose allow) (complete done)',
    decl='(proc choose (params (c (width 1))) (cond (c (call choose c))))',parse_reason='recursive procedure call')
add('mutual_recursion','(on request) (call choose allow) (complete done)',
    decl='(proc choose (params (c (width 1))) (cond (c (call other_proc c)))) (proc other_proc (params (c (width 1))) (call choose c))',parse_reason='recursive procedure call')
(base/'cases.json').write_text(json.dumps(cases,indent=2,sort_keys=True)+'\n')
print('Wrote',len(cases),'complete original source/independent normalized-clause cases')
