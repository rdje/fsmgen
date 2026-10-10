"""Replay complete first import, receiver-decoder and count-diagnostic failures."""
import gzip
import subprocess
from pathlib import Path
from common import BASE, CLASS, HEADERS, canonical, load, need, pin, read, same
import join_headers
import oracle


def first_program(receipt,name):
    actual=load(receipt);source=actual['programs'][str(BASE/name)]
    need(source['identity']==pin(source['body'].encode()) and type(actual['status']) is int and actual['status']!=0,
         'complete retained failed programme epoch and actual result')
    namespace={'__name__':'original_header_first_decoder','__file__':str(BASE/name)}
    exec(compile(source['body'],str(BASE/name),'exec'),namespace)
    return namespace,source['identity']


def replay():
    scratch=Path('.artifacts/observer-original-header-join-20261011/relocated-import')
    scratch.mkdir(parents=True,exist_ok=True)
    sources={str(BASE/'first-selection-source.py.txt'):(BASE/'first-selection-source.py.txt').read_bytes(),
             str(BASE/'common.py'):(BASE/'common.py').read_bytes()}
    for name,raw in sources.items():
        target=scratch/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(raw)
    # Compile the full saved source with its repository-relative filename into
    # the colliding module name. No current-root absolute diagnostic enters
    # the replay contract. A second actual cwd proves relocation conservation.
    code=('import sys, types; sys.path.insert(0,'+repr(str(BASE))+'); module=types.ModuleType("select"); '
          'exec(compile(open('+repr(str(BASE/'first-selection-source.py.txt'))+').read(),'+
          repr(str(BASE/'first-selection-source.py.txt'))+',"exec"),module.__dict__); '
          'sys.modules["select"]=module; import subprocess')
    command=['python3','-B','-c',code]
    actual=subprocess.run(command,capture_output=True,text=True)
    relocated=subprocess.run(command,cwd=scratch,capture_output=True,text=True)
    first=load('first-selection-import-refusal.json')
    need(type(first['status']) is int and first['status']==1 and 'module \'select\' has no attribute \'select\'' in first['output']
         and actual.returncode!=0 and 'module \'select\' has no attribute \'select\'' in actual.stderr,
         'actual first standard-library shadowing failure reproduces')
    need((relocated.returncode,relocated.stdout,relocated.stderr)==(actual.returncode,actual.stdout,actual.stderr),
         'complete actual relocation conservation of source-relative import replay')
    imports=dict(command=command,status=actual.returncode,stdout=actual.stdout,stderr=actual.stderr,
                 sources={name:pin(raw) for name,raw in sources.items()},relocated_cwd=str(scratch),
                 relocated_status=relocated.returncode,relocated_stdout=relocated.stdout,relocated_stderr=relocated.stderr)
    missing=load('actual-independent-header-reader-1.json')
    need(type(missing['status']) is int and missing['status']==1 and
         "ModuleNotFoundError: No module named 'common'" in missing['stderr'],
         'actual first command-only reader lacked the local module path')
    original=read(CLASS/'raw-product.json')['inventories'];product=read(HEADERS/'headers.json');selection=load('selected.json')
    records={(m['mode'],d,r['index']):r for m in original for d,v in m['domains'].items() for r in v['nonempty']}
    headers={h['id']:h for h in product['headers']}
    old,identity=first_program('actual-original-header-join-1.json','join_headers.py')
    failures=[]
    for allocation in selection['source_headers']:
        record=records[tuple(allocation['record'])]
        frame=[r for r in record['segments'] if r['kind']=='frame'][allocation['frame_position']]
        header=headers[allocation['header_id']]
        try:
            old['call'](frame['call'],header['expression']['function'],header['source_argument_ids'],product)
        except ValueError as error:
            need(str(error)=='whole source-qualified reference kind/token syntax','exact first reference-decoder cause')
            failures.append(dict(allocation=allocation,header=header,whole_original_frame=frame,whole_original_record=record,
                operands=[product['operands'][x] for x in header['source_argument_ids']],error=str(error)))
        join_headers.call(frame['call'],header['expression']['function'],header['source_argument_ids'],product)
        oracle.header(frame['call'],header['expression']['function'],header['source_argument_ids'],product)
    need(failures and same(failures,load('first-join-failures.json')),'every entire first reference failure reproduces and corrected complete headers pass')
    old_count,count_identity=first_program('actual-whole-header-controls-1.json','join_headers.py')
    changed=__import__('json').loads(gzip.decompress((BASE/'controls/candidate-lost-argument-count-marker.json.gz').read_bytes()))
    try:
        old_count['join'](changed['native'],selection,product)
    except ValueError as error:
        old_cause=str(error);need(old_cause=='whole source-qualified literal argument header','actual first count decoder misclassification reproduces')
    else:
        raise ValueError('first count decoder unexpectedly accepts lost marker')
    for method in (join_headers.join,oracle.reconstruct):
        try:
            method(changed['native'],selection,product)
        except ValueError as error:
            need(str(error)=='whole source-qualified argument-count marker','correct independent count refusals')
        else:
            raise ValueError('corrected decoder accepted lost count marker')
    return dict(import_shadow=imports,command_module_path_failure=pin(canonical(missing)),
                first_reference_programme=identity,whole_reference_failures=pin(canonical(failures)),
                first_count_programme=count_identity,first_count_cause=old_cause,
                result='All complete first local failures retained and reproduced; corrected whole products and independent controls pass.')
