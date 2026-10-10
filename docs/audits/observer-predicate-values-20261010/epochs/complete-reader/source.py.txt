"""Derive complete predicate inputs and source branches without original display."""
import ast
import copy
import json
from pathlib import Path
from common import BASE, PRIOR, canonical, load, module, need, pin, same, save

CAUSE = Path('docs/audits/record-value-original-primary-20261005/cause_model.py')
VALUE = Path('perl/FSM/Support/ISFRecordPortValues.pm')
METADATA = Path('perl/FSM/Support/ISFInterfacePortMetadata.pm')
CONTEXT = Path('perl/FSM/Support/ISFRecordPortContexts.pm')
PATHS = Path('perl/FSM/Package/AggregatePathSupport.pm')


def freeze(value, seen=None, path=''):
    if value is None or type(value) in (str,int):
        return value
    need(type(value) in (dict,list), 'complete finite source graph type')
    seen = {} if seen is None else seen
    if id(value) in seen:
        return ['reference',seen[id(value)]]
    seen[id(value)] = path
    rows = sorted(value.items()) if type(value) is dict else enumerate(value)
    result = {} if type(value) is dict else []
    for key, child in rows:
        segment = str(key).replace('~','~0').replace('/','~1')
        item = freeze(child,seen,path+'/'+segment)
        if type(result) is dict:
            result[key] = item
        else:
            result.append(item)
    return ['hash' if type(value) is dict else 'array',result]


def event(kind, arguments):
    tree = ast.parse(CAUSE.read_bytes())
    for function in tree.body:
        if not isinstance(function,ast.FunctionDef):
            continue
        calls = sorted((n for n in ast.walk(function) if isinstance(n,ast.Call)
            and isinstance(n.func,ast.Name) and n.func.id == 'must'),key=lambda n:(n.lineno,n.col_offset))
        for i,call in enumerate(calls,1):
            call.keywords.extend([ast.keyword(arg='site',value=ast.Constant(function.name+'.'+str(i))),
                ast.keyword(arg='environment',value=ast.Call(func=ast.Name(id='locals',ctx=ast.Load()),args=[],keywords=[]))])
        if function.name == 'metadata_type':
            class Unsupported(ast.NodeTransformer):
                def visit_Raise(self,node):
                    need(isinstance(node.exc,ast.Call) and isinstance(node.exc.func,ast.Name)
                         and node.exc.func.id == 'Primary' and len(node.exc.args) == 1
                         and isinstance(node.exc.args[0],ast.Constant)
                         and node.exc.args[0].value == 'unsupported resolved type kind', 'closed unsupported metadata source raise')
                    return ast.copy_location(ast.Expr(ast.Call(func=ast.Name(id='must',ctx=ast.Load()),
                        args=[ast.Constant(False),node.exc.args[0]],keywords=[
                            ast.keyword(arg='site',value=ast.Constant('metadata_type.unsupported')),
                            ast.keyword(arg='environment',value=ast.Call(func=ast.Name(id='locals',ctx=ast.Load()),args=[],keywords=[]))])),node)
            Unsupported().visit(function)
    ns = {'__name__':'predicate_source_model'}
    exec(compile(ast.fix_missing_locations(tree),str(CAUSE),'exec'),ns)
    failures = []
    def predicate(condition,message,site,environment):
        if condition:
            return
        facts = {}
        if site == 'metadata_type.9':
            name = environment['name']
            facts = dict(name=name,identifier=ns['identifier'](name),
                previously_seen=name in environment['seen'],member_exists=name in environment['members'])
        if site == 'reference_value.2':
            value = environment['value']
            facts = dict(width=value['width'],resolved_width=value['type_spec']['width'],positive=ns['positive'](value['width']))
        failures.append(dict(site=site,message=message,facts=facts))
        raise ns['Primary'](message)
    ns['must'] = predicate
    primary = ns['primary'](kind,arguments)
    need(len(failures) == 1 and primary is not None, 'complete unique failed source predicate event')
    return dict(primary=primary,**failures[0])


def statements():
    value = module(Path('docs/audits/record-value-original-value-frames-20261005/frame_model.py'))
    metadata = module(Path('docs/audits/record-value-original-metadata-frames-20261005/frame_model.py'))
    result = {}
    for path, rows in ((VALUE,value['GUARDS']),(METADATA,metadata['GUARDS'])):
        text = path.read_text()
        for name,statement in rows.items():
            need(text.count(statement) == 1, 'whole exact own guard statement')
            result[name] = dict(path=str(path),statement=statement)
    text = CONTEXT.read_text()
    start = text.index('    _require(!($scope->{whole_output_writes_only}')
    end = text.index('\n    return $value;',start)
    result['context.output_field_write'] = dict(path=str(CONTEXT),statement=text[start:end].strip())
    return result


def derive():
    census = json.loads((PRIOR / 'census.json').read_bytes())
    source = json.loads((PRIOR / 'source-models.json').read_bytes())
    primary = module(Path('docs/audits/record-value-original-primary-20261005/verify.py'))
    _,_,_,products = primary['context']['source_models']()
    interventions,_,_ = primary['graph']['source_interventions']()
    frames = {tuple(r['path']):r['input'] for r in census['frames']}
    declarations = statements()
    cases, operands = {}, []
    for row in census['operands']:
        if row['schema'] != 'false_predicate' and row['input']['role'] != 'guard predicate':
            continue
        path = row['path']; m,c,p = path[1],path[3],path[5]
        mode = source['modes'][m]['mode']; case = source['modes'][m]['cases'][c]
        frame = frames[tuple(path[:-2])]
        key = (mode,case['domain'],case['index'])
        if key not in cases:
            if case['domain'] == 'api':
                index = case['index']; original = products['apis'][index]['whole_native']['before']
                arguments = copy.deepcopy(interventions[index]) if mode != 'storable' and index in interventions else primary['graph']['thaw'](original)
                encoded = freeze(arguments)
                observed = event(case['kind'],arguments)
                origin = dict(kind='qualified_source_intervention',index=index) if mode != 'storable' and index in interventions else dict(kind='qualified_whole_source_graph',index=index,identity=pin(canonical(original)))
            else:
                original = products['actors'][case['index']]['whole_native']['before']
                encoded = original
                observed = dict(site='context.output_field_write',message=frame['arguments'][1]['source_value'],facts={},
                    primary=case['exception']['primary'])
                origin = dict(kind='qualified_parser_source_input',index=case['index'],identity=pin(canonical(original)))
            cases[key] = dict(key=list(key),kind=case['kind'],input_graph=encoded,origin=origin,event=observed)
        observed = cases[key]['event']; site = frame.get('call_site','context.output_field_write')
        need(site == observed['site'] and site in declarations, 'whole qualified predicate case/guard allocation')
        operands.append(dict(path=path,key=list(key),phase=source['modes'][m]['cases'][c]['phases'][p]['phase'],
            input=row['input'],frame=frame,site=site,guard=declarations[site]))
    return dict(role='Whole qualified source graphs and failed guard/helper branches only; no original display input or native flag inference.',
        sources={str(path):dict(body=path.read_text(),identity=pin(path.read_bytes())) for path in (CAUSE,VALUE,METADATA,CONTEXT,PATHS)},
        cases=list(cases.values()),operands=operands,
        census_identity=pin((PRIOR / 'census.json').read_bytes()),source_model_identity=pin((PRIOR / 'source-models.json').read_bytes()))


def main():
    save('source-inputs.json',derive())
    print('PASS whole failed-predicate source inputs, guard expressions and branch facts derived before new public native observation.')


if __name__ == '__main__':
    main()
