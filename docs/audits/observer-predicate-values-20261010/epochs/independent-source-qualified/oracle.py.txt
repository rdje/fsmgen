"""Independent complete-domain reader with unmodified causal source and frame locals."""
import ast
import inspect
import json
import re
import subprocess
import sys
from functools import lru_cache
from pathlib import Path
from common import BASE, PRIOR, REVISION, ROLE, canonical, load, module, need, pin, same

CAUSE = Path('docs/audits/record-value-original-primary-20261005/cause_model.py')

EXPRESSIONS = {
 'keys.2':'!grep(!exists($value->{$_}), @$required)',
 'keys.3':'!grep(!$allowed{$_}, keys %$value)',
 'closed_type.2':'$spec->{signed} == 0',
 'reference_value.2':'_positive($value->{width}) && $value->{width} == $value->{type_spec}{width}',
 'values.4':'_role($root->{role})', 'values.8':'_binary($allow_whole)',
 'values.10':"$access ne 'write' || $root->{role} ne 'input'",
 'values.11':'$allow_whole || !_aggregate($spec)',
 'values.12':'$resolved->{ok}', 'values.13':'!_aggregate($resolved->{type_spec})',
 'values.15':'_whole_record($source) && _whole_record($target)',
 'values.16':"$target->{role} ne 'input'",
 'values.17':'!FSM::Composition::InterfacePortBuilder->declared_type_conflicts( $source->{type_spec}, $target->{type_spec})',
 'metadata_type.2':'!$active->{$address}',
 'metadata_type.5':'!exists($spec->{signed}) || _binary($spec->{signed})',
 'metadata_type.6':'!exists($spec->{state_model}) || _state_model($spec->{state_model})',
 'metadata_type.8':'keys(%$members) == @$order',
 'metadata_type.9':'_identifier($name) && !$seen{$name}++ && exists($members->{$name})',
 'metadata_type.12':'$width == $spec->{width}',
 'metadata_type.unsupported':'0',
 'context.output_field_write':"!($scope->{whole_output_writes_only} && $access eq 'write' && $value && $value->{role} eq 'output' && length($value->{path_text}) && _port_root($roots->{$name}))",
}


@lru_cache(maxsize=1)
def upstream():
    primary=module(Path('docs/audits/record-value-original-primary-20261005/verify.py'))
    products=primary['context']['source_models']()[3]
    interventions=primary['graph']['source_interventions']()[0]
    return products,interventions,primary['graph']['thaw']


def graph_matches(encoded,root):
    """Compare full values AND alias edges directly, without the producer encoder."""
    encountered={}
    def visit(node,value,path):
        if value is None or type(value) in (str,int): return type(node) is type(value) and node == value
        if type(value) not in (dict,list): return False
        if id(value) in encountered: return node == ['reference',encountered[id(value)]]
        encountered[id(value)]=path
        if type(node) is not list or len(node) != 2 or node[0] != ('hash' if type(value) is dict else 'array'): return False
        body=node[1]
        if type(body) is not type(value) or (set(body) != set(value) if type(value) is dict else len(body) != len(value)): return False
        return all(visit(body[k],v,path+'/'+str(k).replace('~','~0').replace('/','~1')) for k,v in (sorted(value.items()) if type(value) is dict else enumerate(value)))
    return visit(encoded,root,'')


def decode(graph):
    objects = {}
    def visit(node,path):
        if node is None or type(node) in (str,int):
            return node
        need(type(node) is list and len(node) == 2,'full source graph node')
        tag,body = node
        if tag == 'reference':
            need(body in objects,'source graph backward alias/cycle')
            return objects[body]
        need(tag in ('hash','array'),'typed source graph container')
        out = {} if tag == 'hash' else []
        objects[path] = out
        for key,value in (body.items() if tag == 'hash' else enumerate(body)):
            child = visit(value,path+'/'+str(key).replace('~','~0').replace('/','~1'))
            if tag == 'hash': out[key] = child
            else: out.append(child)
        return out
    return visit(graph,'')


def event(kind,arguments):
    ns = module(CAUSE)
    sites = {}
    for f in ast.parse(CAUSE.read_bytes()).body:
        if isinstance(f,ast.FunctionDef):
            calls = sorted((n for n in ast.walk(f) if isinstance(n,ast.Call)
                and isinstance(n.func,ast.Name) and n.func.id == 'must'),key=lambda n:(n.lineno,n.col_offset))
            for i,n in enumerate(calls,1): sites[f.name,n.lineno] = f.name+'.'+str(i)
    failures = []
    def check(condition,message):
        if condition: return
        caller = inspect.currentframe().f_back
        site = sites[caller.f_code.co_name,caller.f_lineno]
        local = caller.f_locals; facts = {}
        if site == 'metadata_type.9':
            name = local['name']
            facts = dict(name=name,identifier=type(name) is str and re.fullmatch(r'[A-Za-z_]\w*',name) is not None,
                previously_seen=name in local['seen'],member_exists=name in local['members'])
        elif site == 'reference_value.2':
            width = local['value']['width']
            facts = dict(width=width,resolved_width=local['value']['type_spec']['width'],
                positive=type(width) in (str,int) and re.fullmatch('[1-9][0-9]*',str(width)) is not None)
        failures.append(dict(site=site,message=message,facts=facts))
        raise ns['Primary'](message)
    ns['must'] = check
    def trace(frame,action,arg):
        if action == 'exception' and frame.f_code.co_name == 'metadata_type' and arg[0] is ns['Primary'] and str(arg[1]) == 'unsupported resolved type kind':
            failures.append(dict(site='metadata_type.unsupported',message=str(arg[1]),facts={}))
        return trace
    old = sys.gettrace()
    try:
        sys.settrace(trace)
        primary = ns['primary'](kind,arguments)
    finally:
        sys.settrace(old)
    # Recursive metadata frames may relay the same unsupported exception.
    if failures and all(x == failures[0] for x in failures): failures=failures[:1]
    need(len(failures) == 1 and primary is not None,'independent unique source refusal')
    return dict(primary=primary,**failures[0])


def verify(source,values):
    need(values['role'] == ROLE and source['role'].startswith('Whole qualified source graphs'),'complete unchanged scope')
    for path,record in source['sources'].items():
        raw = subprocess.check_output(['git','--no-replace-objects','show',REVISION+':'+path])
        need(record == dict(body=raw.decode(),identity=pin(raw)) and Path(path).read_bytes() == raw,'whole fixed own source contract')
    census = json.loads((PRIOR/'census.json').read_bytes())
    full = json.loads((PRIOR/'source-models.json').read_bytes())
    expected = [r for r in census['operands'] if r['schema'] == 'false_predicate' or r['input']['role'] == 'guard predicate']
    need(source['census_identity'] == pin((PRIOR/'census.json').read_bytes()) and source['source_model_identity'] == pin((PRIOR/'source-models.json').read_bytes()),'whole census input identities')
    need(len(source['operands']) == len(expected) == len(values['rows']),'complete failed-predicate membership')
    frames = {tuple(r['path']):r['input'] for r in census['frames']}
    cases = {}; zero = {'values.4','values.8','values.12','values.15','metadata_type.5','metadata_type.6','metadata_type.unsupported'}
    boolean = {'values.10','values.11','values.13','values.16','values.17','keys.2','keys.3','closed_type.2','metadata_type.2','metadata_type.8','metadata_type.12','context.output_field_write'}
    for entry in source['cases']:
        key = tuple(entry['key']); need(key not in cases,'unique complete source case')
        products,interventions,thaw=upstream(); mode,domain,index=key
        if key[1] == 'api':
            original=products['apis'][index]['whole_native']['before']
            intervened=mode != 'storable' and index in interventions
            own=interventions[index] if intervened else thaw(original)
            origin=dict(kind='qualified_source_intervention',index=index) if intervened else dict(kind='qualified_whole_source_graph',index=index,identity=pin(canonical(original)))
            need(same(entry['origin'],origin) and graph_matches(entry['input_graph'],own),'complete qualified supplied/default input and alias binding')
            need(same(entry['event'],event(entry['kind'],decode(entry['input_graph']))),'independent complete source branch facts')
        else:
            original=products['actors'][index]['whole_native']['before']
            need(same(entry['input_graph'],original) and entry['origin'] == dict(kind='qualified_parser_source_input',index=index,identity=pin(canonical(original))),'whole qualified parser input binding')
            need(entry['event']['site'] == 'context.output_field_write' and entry['event']['facts'] == {},'whole parser refusal source allocation')
        cases[key] = entry
    allocated = set()
    for index,raw in enumerate(expected):
        operand = source['operands'][index]; row = values['rows'][index]; path=raw['path']
        mode,case,phase = full['modes'][path[1]],full['modes'][path[1]]['cases'][path[3]],full['modes'][path[1]]['cases'][path[3]]['phases'][path[5]]
        key = (mode['mode'],case['domain'],case['index']); allocated.add(key)
        frame = frames[tuple(path[:-2])]; site=frame.get('call_site','context.output_field_write')
        need(cases[key]['kind'] == case['kind'],'whole source operation kind')
        need(operand['path'] == path and same(operand['input'],raw['input']) and same(operand['frame'],frame)
             and operand['key'] == list(key) and operand['phase'] == phase['phase'] and operand['site'] == site,'full schema/location/frame/input binding')
        need(cases[key]['event']['site'] == site and same(row['source_case'],cases[key]),'source case/frame allocation')
        need(all(same(row[k],v) for k,v in operand.items()),'complete operand retention')
        statement = operand['guard']['statement']; body = source['sources'][operand['guard']['path']]['body']
        need(body.count(statement) == 1 and row['source_expression'] in statement
             and ' '.join(row['source_expression'].split()) == EXPRESSIONS[site],'whole guard source expression')
        facts = cases[key]['event']['facts']
        if site in zero: value='numeric_zero'
        elif site in boolean: value='boolean_false'
        elif site == 'reference_value.2': value='boolean_false' if facts['positive'] else 'numeric_zero'
        elif site == 'metadata_type.9': value='boolean_false' if facts['identifier'] else 'numeric_zero'
        else: raise ValueError('unqualified complete source site '+site)
        need(row['value_class'] == value and type(row['numeric_value']) is int and row['numeric_value'] == 0
            and type(row['defined']) is bool and row['defined'] and row['string_value'] == ('0' if value == 'numeric_zero' else '')
            and row['current_public_fixture'] == value and row['original_native_scalar_flags'] == 'not measured','complete independently derived source value and original flag boundary')
    need(allocated == set(cases),'complete unique source case allocation')
    expected_helpers=set()
    for path,names in [('perl/FSM/Support/ISFRecordPortValues.pm',['_whole_record','_role','_positive','_binary']),('perl/FSM/Support/ISFInterfacePortMetadata.pm',['_identifier','_binary','_state_model'])]:
        for name in names:
            key=path+'::'+name; expected_helpers.add(key); text=values['helpers'][key]
            need(text.startswith('sub '+name+' {') and text.endswith('}') and source['sources'][path]['body'].count(text) == 1 and re.search(r'\?\s*1\s*:\s*0\s*;?\s*\}$',text),'whole own helper normalization contract')
    need(set(values['helpers']) == expected_helpers,'whole helper membership')
    body=source['sources']['perl/FSM/Package/AggregatePathSupport.pm']['body']
    contract=values['resolver']; need(body.count(contract['constructor']) == 1 and 'ok => 0,' in contract['constructor'],'literal zero own failure constructor')
    spans = [m.start() for m in re.finditer(r'->_failure\(',body)]
    need([r['start'] for r in contract['calls']] == spans,'complete own failure call membership')
    for call in contract['calls']:
        need(body[call['start']:call['start']+len(call['source'])] == call['source'],'whole own failure call bytes')
        keys=re.findall(r'(?:^|,)\s*([a-z_]+)\s*=>',call['source'])
        need(keys == call['keys'] and 'ok' not in keys and not re.search(r'(?:^|,)\s*[%$]',call['source']),'no dynamic failure detail override')
    need(values['current_profile'] == dict(MaxArgLen=64,MaxArgNums=8,RefArgFormatter=None)
        and values['original_observer_settings'] == 'not measured' and values['original_display_hypothesis'] == 'not selected by this source-value unit','complete current/original scope boundary')
    return dict(source=pin(canonical(source)),values=pin(canonical(values)),scope=ROLE)


if __name__ == '__main__':
    verify(load('source-inputs.json'),load('predicate-values-qualified.json'))
    print('PASS independent whole predicate source/value/domain reader; original observer flags/settings remain unmeasured.')
