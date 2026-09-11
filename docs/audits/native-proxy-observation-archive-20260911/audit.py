"""Independent physical-footprint and retained-byte archive oracle."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
LOG=ROOT/'.artifacts/logs/native-proxy-observation-archive-20260911'
_spec=importlib.util.spec_from_file_location('archive_record_oracle',BASE.parent/'native-proxy-observation-archive-records-20260911/audit.py')
RECORD=importlib.util.module_from_spec(_spec);_spec.loader.exec_module(RECORD)


def canonical(value):
    return json.dumps(value,ensure_ascii=True,sort_keys=True,separators=(',',':'))


def wire(value):
    if isinstance(value,list): return [wire(x) for x in value]
    if isinstance(value,dict): return {('bytes_hex' if k=='bytes' else k):
        (v.encode('latin1').hex() if k=='bytes' else wire(v)) for k,v in value.items()}
    return value


def file_identity(path,node):
    assert node['kind']=='file' and node['links']==1
    raw=bytes.fromhex(node['bytes_hex'])
    assert len(raw)==node['size_bytes'] and hashlib.sha256(raw).hexdigest()==node['sha256']
    return dict(path=path,**{k:node[k] for k in ('device','inode','size_bytes','sha256')})


def target_inputs(context,physical):
    for source in context['acquired']['target_sources']:
        identity=source['identity']; path=identity['path']
        if path.startswith(context['store']['path']+'/'):
            node=physical['store'][path[len(context['store']['path'])+1:]]
        else:
            assert path.startswith(context['workspace']['path']+'/')
            node=physical['workspace'][path[len(context['workspace']['path'])+1:]]
        assert canonical(file_identity(path,node))==canonical(identity)
        assert node['bytes_hex']==source['bytes'].encode('latin1').hex()
    for kind in ('acquired','other_observation'):
        source=context[kind]['observation_reference']['source']; identity=source['identity']
        node=physical['store'][identity['path'][len(context['store']['path'])+1:]]
        assert file_identity(identity['path'],node)==identity
        assert node['bytes_hex']==source['bytes'].encode('latin1').hex()


def physical_receipt(context,operation):
    value=dict(case=context['store']['path'],request=context['request'],acquired=wire(context['acquired']))
    spec=RECORD.specification(value)
    evidence=operation['after']['evidence']; directory=evidence['retained-sources']
    assert directory['kind']=='directory' and directory['mode']==0o700
    expected_members={'','retained-sources'} | {'retained-sources/'+f['sha256']+'.source' for f in spec['files']}
    assert set(evidence)==expected_members
    assert evidence['']==operation['before']['evidence']['']
    assert directory['device']==context['evidence']['device'] and directory['uid']==evidence['']['uid']
    snapshots=[]
    for file in spec['files']:
        relative='retained-sources/'+file['sha256']+'.source'; node=evidence[relative]
        assert node['mode']==0o400 and node['uid']==directory['uid'] and node['device']==directory['device']
        assert node['bytes_hex']==file['bytes_hex']
        snapshots.append(dict(bytes_hex=node['bytes_hex'],identity=file_identity(file['path'],node)))
    value.update(directory=dict(path=spec['archive_directory'],device=directory['device'],inode=directory['inode']),snapshots=snapshots)
    expected=RECORD.from_snapshots(value)
    assert canonical(operation['result'])==canonical(expected)
    return spec,expected


def operation_checks(context,operation,returned,diagnostic):
    assert operation['returned']==int(returned)
    if returned: assert not operation['error']
    else:
        assert diagnostic in operation['error'] and operation.get('result') is None
        assert operation['after']['evidence']==operation['before']['evidence']
        assert operation['writes']==[]
    for kind in ('store','workspace','other_workspace'):
        assert operation['before'][kind]==operation['after'][kind]
    archive=context['evidence']['path']+'/retained-sources'
    assert all(path.startswith(archive+'/') for path in operation['reads']+operation['writes'])
    assert all(path in (context['evidence']['path'],archive) for path in operation['directories'])
    for descriptor in operation['descriptors']:
        assert descriptor['closed']==descriptor['cloexec']==1
        assert type(descriptor['descriptor']) is int and descriptor['descriptor']>=0
        assert descriptor['path'].startswith(archive+'/')
    if returned:
        spec,receipt=physical_receipt(context,operation)
        paths=[f['path'] for f in spec['files']]
        existing='retained-sources' in operation['before']['evidence']
        expected_reads=paths+paths if existing else [path for path in paths for _ in range(2)]+paths
        assert operation['reads']==expected_reads
        assert [x['path'] for x in operation['descriptors']]==expected_reads
        assert operation['writes']==([] if existing else paths)
        if existing: assert operation['before']['evidence']==operation['after']['evidence']
        assert len(receipt['source_bindings'])==5


def invalid_precondition(selection,row):
    operation=row['operation']; before=operation['before']['evidence']; change=selection['change']
    if selection['returned']: return
    spec=RECORD.specification(dict(case=row['context']['store']['path'],request=row['context']['request'],acquired=wire(row['context']['acquired'])))
    first='retained-sources/'+spec['files'][0]['sha256']+'.source'
    preparation=selection['prepare']
    if preparation in ('empty','partial','unknown'):
        members={p for p in before if p.startswith('retained-sources/')}
        expected={'retained-sources/'+f['sha256']+'.source' for f in spec['files']}
        assert members!=expected
    elif preparation in ('symlink','file'): assert before['retained-sources']['kind']==preparation
    elif change=='changed_bytes': assert before[first]['bytes_hex']!=spec['files'][0]['bytes_hex']
    elif change=='changed_mode': assert before[first]['mode']==0o600
    elif change=='hardlink': assert before[first]['links']==2
    elif change=='missing_file': assert first not in before
    elif change=='extra_file': assert 'retained-sources/unrelated' in before
    elif change=='wrong_directory_mode': assert before['retained-sources']['mode']==0o755
    elif change=='wrong_evidence_permissions': assert before['']['mode']==0o755
    elif change=='foreign_evidence_identity': assert row['request']['evidence_directory_identity']!=row['context']['evidence']
    else: assert change in ('missing_argument','extra_argument')


def verify(plan,report):
    assert report['success'] is True and report['forbidden_process_attempts']==0
    assert [r['name'] for r in report['cases']]==[s['name'] for s in plan['cases']]
    roots=[]; operations=0; returned=0; descriptors=0
    for selection,row in zip(plan['cases'],report['cases'],strict=True):
        context=row['context']; prior=row['prior_retirement']; after=row['after_retirement']
        for kind in ('store','workspace','other_workspace','evidence'):
            identity=context[kind];roots.append(dict(kind=kind,**identity))
            node=prior[kind][''];assert node['kind']=='directory' and node['mode']==0o700
            assert (node['device'],node['inode'])==(identity['device'],identity['inode'])
        target_inputs(context,prior)
        if selection['retired']:
            assert after['workspace']=={}
            retirement=row['retirement'];assert retirement['schema']=='fsmgen.inactive_runtime_retirement.v1'
            assert retirement['runtime_authorized']==0 and retirement['executable'] is None
            assert retirement['retired_workspace']==context['workspace']['path']
            global_path=context['runtime']['reference']['global']['identity']['path']
            assert retirement['released_reference']==global_path
            expected=copy.deepcopy(prior['store']);del expected[global_path[len(context['store']['path'])+1:]]
            assert after['store']==expected
            for kind in ('other_workspace','evidence'): assert prior[kind]==after[kind]
        else: assert prior==after and 'retirement' not in row
        assert canonical(row['input_before'])==canonical(row['input_after'])==canonical(context['acquired'])
        assert canonical(row['request'])==canonical(row['request_after'])
        assert row['diagnostic_matched']==1
        if selection['prepare']=='complete':
            preparation=row['preparation'];assert preparation['before']==after
            operation_checks(context,preparation,True,'');operations+=1;returned+=1;descriptors+=len(preparation['descriptors'])
        else: assert 'preparation' not in row
        invalid_precondition(selection,row)
        operation_checks(context,row['operation'],selection['returned'],selection['diagnostic'])
        operations+=1;returned+=selection['returned'];descriptors+=len(row['operation']['descriptors'])
        if row['name']=='stable archive reuse after retirement':
            assert row['preparation']['result']==row['operation']['result']
    assert roots==report['allocated'] and len({r['path'] for r in roots})==len(roots)
    return dict(cases=len(report['cases']),operations=operations,returned_operations=returned,observed_source_descriptors=descriptors,roots=len(roots))


def rejects(callback):
    try: callback()
    except (AssertionError,KeyError,ValueError,TypeError,IndexError): return True
    return False


def main():
    plan=json.loads((BASE/'plan.json').read_bytes())
    for pin in plan['inputs']:
        path=ROOT/pin['path'];raw=path.read_bytes()
        assert len(raw)==pin['size_bytes'] and hashlib.sha256(raw).hexdigest()==pin['sha256']
        assert raw==subprocess.check_output(['git','show',plan['source_revision']+':'+pin['path']],cwd=ROOT)
    for pin in json.loads((LOG/'preflight-pins.json').read_bytes()):
        raw=(ROOT/pin['path']).read_bytes()
        assert len(raw)==pin['size_bytes'] and hashlib.sha256(raw).hexdigest()==pin['sha256']
    report=json.loads((LOG/'qualification.json').read_bytes());counts=verify(plan,report)
    admission=[json.loads(line) for line in (LOG/'admission.jsonl').read_text().splitlines()]
    assert admission==report['allocated']
    for row in admission:
        path=ROOT/row['path'];assert not path.exists() and not path.is_symlink()
    assertions=len(plan['cases'])*5+sum(not s['returned'] for s in plan['cases'])+sum(s['prepare']=='complete' for s in plan['cases'])+1
    tap=(LOG/'qualify.tap').read_text()
    assert re.findall(r'^1\.\.([0-9]+)$',tap,re.M)==[str(assertions)]
    assert [int(x) for x in re.findall(r'^ok ([0-9]+) - ',tap,re.M)]==list(range(1,assertions+1))
    assert not re.search(r'^(?:not ok|Bail out!)',tap,re.M)
    assert (LOG/'qualify.exit').read_text().strip()=='0'
    def first_file(r):
        evidence=r['cases'][1]['operation']['after']['evidence']
        return next(n for n in evidence.values() if n['kind']=='file')
    changes=[
        ('missing case',lambda r:r['cases'].pop()),
        ('duplicate case',lambda r:r['cases'].append(copy.deepcopy(r['cases'][0]))),
        ('wrong archive bytes',lambda r:first_file(r).update(bytes_hex='00')),
        ('wrong archive inode',lambda r:first_file(r).update(inode=7)),
        ('wrong archive mode',lambda r:first_file(r).update(mode=0o600)),
        ('lost ordered binding',lambda r:r['cases'][1]['operation']['result']['source_bindings'].pop()),
        ('lost source identity',lambda r:r['cases'][1]['operation']['result']['source_bindings'][0]['source'].update(inode=7)),
        ('target reopen',lambda r:r['cases'][1]['operation']['reads'].append(r['cases'][1]['context']['workspace']['path']+'/rust-tool-resolution')),
        ('unclosed source',lambda r:r['cases'][1]['operation']['descriptors'][0].update(closed=0)),
        ('unsealed descriptor',lambda r:r['cases'][1]['operation']['descriptors'][0].update(cloexec=0)),
        ('lost other owner',lambda r:r['cases'][1]['operation']['after']['store'].pop('coordination.lock')),
        ('false retirement',lambda r:r['cases'][1]['after_retirement'].update(workspace=copy.deepcopy(r['cases'][1]['prior_retirement']['workspace']))),
        ('false rejected archive',lambda r:r['cases'][7]['operation'].update(returned=1)),
        ('missing allocation',lambda r:r['allocated'].pop()),
        ('process attempt',lambda r:r.update(forbidden_process_attempts=1)),
    ]
    for name,change in changes:
        altered=copy.deepcopy(report);change(altered)
        assert rejects(lambda:verify(plan,altered)),name
    output=dict(schema='fsmgen.inactive_observation_archive_audit.v1',success=True,**counts,
        tap_assertions=assertions,report_falsifiers=[name for name,_ in changes],
        predecessor_inputs_unchanged=len(plan['inputs']),prospective_inputs_unchanged=len(json.loads((LOG/'preflight-pins.json').read_bytes())),
        all_allocations_absent=True,limits=plan['limits'])
    (LOG/'audit.json').write_text(json.dumps(output,indent=2,sort_keys=True)+'\n')
    print(json.dumps(output,sort_keys=True))


if __name__=='__main__': main()
