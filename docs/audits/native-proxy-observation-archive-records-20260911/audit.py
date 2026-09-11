"""Reconstruct archive expectations without importing the Perl implementation."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT/'.artifacts/logs/native-proxy-observation-archive-records-20260911'
ROLES = ('wrapper','private_reference','global_reference','c','image')


def canonical(value):
    return json.dumps(value,ensure_ascii=True,sort_keys=True,separators=(',',':'))


def closed(value, fields):
    assert type(value) is dict and set(value) == set(fields.split())


def integer(value):
    assert type(value) is int and value >= 0


def identity(value):
    closed(value,'path device inode size_bytes sha256')
    assert type(value['path']) is str
    for key in ('device','inode','size_bytes'): integer(value[key])
    assert value['size_bytes'] <= 65536
    assert type(value['sha256']) is str and re.fullmatch('[0-9a-f]{64}',value['sha256'])


def snapshot(value):
    closed(value,'bytes_hex identity')
    identity(value['identity'])
    raw=bytes.fromhex(value['bytes_hex'])
    assert len(raw)==value['identity']['size_bytes']
    assert hashlib.sha256(raw).hexdigest()==value['identity']['sha256']
    return raw


def specification(value):
    acquired=value['acquired']; request=value['request']
    closed(acquired,'schema runtime_authorized executable lock observation_reference target_sources')
    assert acquired['schema']=='fsmgen.inactive_observation_acquisition.v1'
    assert type(acquired['runtime_authorized']) is int and acquired['runtime_authorized']==0
    assert acquired['executable'] is None
    evidence=request['evidence_directory_identity']
    hold=acquired['observation_reference']
    assert hold['record']['evidence_directory_identity']==evidence
    assert hold['record']['observer_birth']==request['observer_birth']
    assert hold['record']['target_birth']==request['target_birth']
    assert acquired['lock']['path']==value['case']+'/coordination.lock'
    assert acquired['lock']['device']==evidence['device']==request['workspace_identity']['device']
    assert len(acquired['target_sources'])==5
    assert hold['source']['identity']['device']==evidence['device']
    assert snapshot(hold['source']).decode('ascii')==canonical(hold['record'])
    sources=acquired['target_sources']
    for row in sources:
        snapshot(row)
        assert row['identity']['device']==evidence['device']
    assert sources[0]['identity']['path']==request['workspace_identity']['path']+'/rust-tool-resolution'
    assert sources[1]['bytes_hex']==sources[2]['bytes_hex']
    runtime=json.loads(bytes.fromhex(sources[1]['bytes_hex']))
    assert runtime['workspace_identity']==request['workspace_identity']
    assert [x['identity'] for x in sources[3:]]==runtime['selected_sources']==hold['record']['selected_sources']
    directory=evidence['path']+'/retained-sources'
    # Partition by actual bytes, then check hash-name agreement. This oracle
    # does not trust the producer's filenames, grouping, counts or order.
    groups={}
    for index,source in enumerate(sources):
        raw=bytes.fromhex(source['bytes_hex'])
        groups.setdefault(raw,[]).append(index)
    files=[]
    destinations={}
    for raw,indices in sorted(groups.items(),key=lambda item:min(item[1])):
        digest=hashlib.sha256(raw).hexdigest(); path=directory+'/'+digest+'.source'
        assert path not in destinations.values()
        for index in indices: destinations[index]=path
        files.append(dict(path=path,bytes_hex=raw.hex(),size_bytes=len(raw),sha256=digest))
    return dict(schema='fsmgen.inactive_observation_archive_specification.v1',runtime_authorized=0,executable=None,
        evidence_directory_identity=copy.deepcopy(evidence),archive_directory=directory,
        observation_reference_key=hold['record']['reference_key'],files=files,
        sources=[dict(role=role,destination=destinations[index],snapshot=copy.deepcopy(sources[index]))
                 for index,role in enumerate(ROLES)])


def validate(value,receipt):
    spec=specification(value)
    closed(receipt,'schema runtime_authorized executable evidence_directory_identity archive_directory_identity observation_reference_key source_bindings')
    assert receipt['schema']=='fsmgen.inactive_observation_archive.v1'
    integer(receipt['runtime_authorized']); assert receipt['runtime_authorized']==0
    assert receipt['executable'] is None
    assert receipt['evidence_directory_identity']==spec['evidence_directory_identity']
    assert canonical(receipt['evidence_directory_identity'])==canonical(spec['evidence_directory_identity'])
    assert receipt['observation_reference_key']==spec['observation_reference_key']
    directory=receipt['archive_directory_identity']
    closed(directory,'path device inode'); integer(directory['device']); integer(directory['inode'])
    assert directory['path']==spec['archive_directory']
    assert directory['device']==spec['evidence_directory_identity']['device']
    assert directory['inode']!=spec['evidence_directory_identity']['inode']
    native={(directory['device'],directory['inode']):directory['path'],
            (spec['evidence_directory_identity']['device'],spec['evidence_directory_identity']['inode']):spec['evidence_directory_identity']['path']}
    shared={}
    bindings=receipt['source_bindings']
    assert type(bindings) is list and len(bindings)==5
    for binding,source in zip(bindings,spec['sources'],strict=True):
        closed(binding,'role source archive')
        assert binding['role']==source['role']
        identity(binding['source']); identity(binding['archive'])
        assert canonical(binding['source'])==canonical(source['snapshot']['identity'])
        archive=binding['archive']
        assert archive['path']==source['destination'] and archive['device']==directory['device']
        assert archive['size_bytes']==source['snapshot']['identity']['size_bytes']
        assert archive['sha256']==source['snapshot']['identity']['sha256']
        key=(archive['device'],archive['inode'])
        assert key not in native or native[key]==archive['path']
        native[key]=archive['path']
        assert archive['path'] not in shared or canonical(shared[archive['path']])==canonical(archive)
        shared[archive['path']]=archive
    assert len(canonical(receipt).encode('ascii'))<=65536


def from_snapshots(value):
    spec=specification(value)
    closed(value['directory'],'path device inode')
    assert len(value['snapshots'])==len(spec['files'])
    by_path={}
    for actual,expected in zip(value['snapshots'],spec['files'],strict=True):
        assert snapshot(actual)==bytes.fromhex(expected['bytes_hex'])
        assert actual['identity']['path']==expected['path']
        by_path[expected['path']]=actual['identity']
    receipt={k:copy.deepcopy(spec[k]) for k in ('runtime_authorized','executable','evidence_directory_identity','observation_reference_key')}
    receipt.update(schema='fsmgen.inactive_observation_archive.v1',archive_directory_identity=copy.deepcopy(value['directory']),
        source_bindings=[dict(role=s['role'],source=copy.deepcopy(s['snapshot']['identity']),
                            archive=copy.deepcopy(by_path[s['destination']])) for s in spec['sources']])
    validate(value,receipt)
    return receipt


def changed(plan,control):
    value=copy.deepcopy(plan['vectors'][control['vector']])
    for step in control['steps']:
        parent=value
        for key in step['path'][:-1]: parent=parent[key]
        key=step['path'][-1]; action=step['action']
        if action=='set': parent[key]=copy.deepcopy(step['value'])
        elif action=='delete': del parent[key]
        elif action=='pop': parent[key].pop()
        elif action=='reverse': parent[key].reverse()
        elif action=='duplicate': parent[key].append(copy.deepcopy(parent[key][0]))
        else: raise AssertionError(action)
    return value


def rejects(callback):
    try: callback()
    except (AssertionError,ValueError,TypeError,KeyError,UnicodeError,IndexError): return True
    return False


def strip_flags(value):
    if isinstance(value,list): return [strip_flags(x) for x in value]
    if isinstance(value,dict):
        if 'bytes_hex' in value: assert value['bytes_utf8']==0
        return {k:strip_flags(v) for k,v in value.items() if k!='bytes_utf8'}
    return value


def verify(plan,report):
    assert report['success'] is True
    assert report['filesystem_lookup_attempts']==report['forbidden_process_attempts']==0
    assert [x['name'] for x in report['vectors']]==[x['name'] for x in plan['vectors']]
    for vector,row in zip(plan['vectors'],report['vectors'],strict=True):
        expected_spec=specification(vector); expected_receipt=from_snapshots(vector)
        assert canonical(vector['specification'])==canonical(expected_spec)
        assert canonical(vector['receipt'])==canonical(expected_receipt)
        assert strip_flags(row['specification'])==expected_spec
        assert canonical(row['receipt'])==canonical(expected_receipt)
        assert row['raw']==vector['raw']==canonical(expected_receipt)
        assert canonical(row['decoded'])==canonical(expected_receipt)
        assert row['inputs_unchanged']==1
    assert [x['name'] for x in report['controls']]==[x['name'] for x in plan['controls']]
    for control,row in zip(plan['controls'],report['controls'],strict=True):
        assert row['rejected']==row['inputs_unchanged']==1 and type(row['error']) is str and row['error']
        value=changed(plan,control); operation=control['operation']
        if 'argument_change' in control or 'upgrade' in control: continue
        if operation in ('validate','encode'): callback=lambda:validate(value,value['receipt'])
        elif operation=='specification': callback=lambda:specification(value)
        elif operation=='receipt': callback=lambda:from_snapshots(value)
        elif operation=='decode':
            def callback():
                raw=value['raw']; assert type(raw) is str and raw.isascii() and len(raw)<=65536
                decoded=json.loads(raw); validate(value,decoded); assert raw==canonical(decoded)
        else: raise AssertionError(operation)
        assert rejects(callback), control['name']
    assert [x['name'] for x in report['mutants']]==[x['name'] for x in plan['mutants']]
    for mutant,row in zip(plan['mutants'],report['mutants'],strict=True):
        control=next(x for x in plan['controls'] if x['name']==mutant['control'])
        value=changed(plan,control)
        assert row['accepted']==1 and not row['error']
        assert rejects(lambda:validate(value,row['invalid_receipt'])), mutant['name']


def main():
    plan=json.loads((BASE/'plan.json').read_bytes())
    for row in plan['inputs']:
        path=ROOT/row['path']; raw=path.read_bytes()
        assert len(raw)==row['size_bytes'] and hashlib.sha256(raw).hexdigest()==row['sha256']
        assert raw==subprocess.check_output(['git','show',plan['source_revision']+':'+row['path']],cwd=ROOT)
        assert path.stat().st_dev==ROOT.stat().st_dev
        while path!=ROOT:
            assert not path.is_symlink(); path=path.parent
    for row in json.loads((LOG/'preflight-pins.json').read_bytes()):
        raw=(ROOT/row['path']).read_bytes()
        assert len(raw)==row['size_bytes'] and hashlib.sha256(raw).hexdigest()==row['sha256']
    # Bind actual inputs to the authenticated historical case, including raw
    # latin-1 snapshot octets. Constructed wrappers are separately labeled.
    for vector in plan['vectors'][:2]:
        origin=vector['historical_origin']; old=json.loads((ROOT/origin['path']).read_bytes())
        row=next(x for x in old['cases'] if x['name']==origin['case_name'])
        assert row['returned']==1 and not row['error']
        assert row['request']==vector['request'] and row['context']['store']['path']==vector['case']
        def restore(value):
            if isinstance(value,list): return [restore(x) for x in value]
            if isinstance(value,dict): return {('bytes' if k=='bytes_hex' else k):
                (bytes.fromhex(v).decode('latin1') if k=='bytes_hex' else restore(v)) for k,v in value.items()}
            return value
        assert restore(vector['acquired'])==row['result']
    report=json.loads((LOG/'qualification.json').read_bytes()); verify(plan,report)
    tap=(LOG/'qualify.tap').read_text()
    assertions=len(plan['vectors'])*5+len(plan['controls'])+len(plan['mutants'])+2
    assert re.search(r'^1..'+str(assertions)+r'$',tap,re.M)
    assert len(re.findall(r'^ok [0-9]+ ',tap,re.M))==assertions and not re.search(r'^(not ok|Bail out!)',tap,re.M)
    assert (LOG/'qualify.exit').read_text().strip()=='0'
    changes=[
        ('wrong canonical bytes',lambda r:r['vectors'][0].update(raw='{}')),
        ('lost original identity',lambda r:r['vectors'][0]['receipt']['source_bindings'][0]['source'].update(inode=7)),
        ('lost binary source',lambda r:r['vectors'][2]['specification']['sources'][0]['snapshot'].update(bytes_hex='')),
        ('lost byte representation flag',lambda r:r['vectors'][2]['specification']['sources'][0]['snapshot'].pop('bytes_utf8')),
        ('character representation',lambda r:r['vectors'][2]['specification']['sources'][0]['snapshot'].update(bytes_utf8=1)),
        ('missing positive',lambda r:r['vectors'].pop()),
        ('missing rejection',lambda r:r['controls'].pop()),
        ('duplicate rejection',lambda r:r['controls'].append(copy.deepcopy(r['controls'][0]))),
        ('accepted invalid record',lambda r:r['controls'][0].update(rejected=0)),
        ('input mutated',lambda r:r['vectors'][0].update(inputs_unchanged=0)),
        ('filesystem lookup',lambda r:r.update(filesystem_lookup_attempts=1)),
        ('process attempt',lambda r:r.update(forbidden_process_attempts=1)),
        ('missing mutant',lambda r:r['mutants'].pop()),
        ('ineffective mutant',lambda r:r['mutants'][0].update(accepted=0)),
        ('mutant valid receipt',lambda r:r['mutants'][0].update(invalid_receipt=copy.deepcopy(plan['vectors'][0]['receipt']))),
    ]
    for name,change in changes:
        altered=copy.deepcopy(report); change(altered)
        assert rejects(lambda:verify(plan,altered)), name
    output=dict(schema='fsmgen.inactive_archive_record_audit.v1',success=True,
        historical_inputs=2,positive_vectors=len(plan['vectors']),rejected_controls=len(plan['controls']),
        helper_mutants=len(plan['mutants']),tap_assertions=assertions,record_falsifiers=[x[0] for x in changes],
        predecessor_inputs_unchanged=len(plan['inputs']),prospective_inputs_unchanged=len(json.loads((LOG/'preflight-pins.json').read_bytes())),
        unique_files_by_vector={x['name']:len(specification(x)['files']) for x in plan['vectors']},
        limits=plan['limits'])
    (LOG/'audit.json').write_text(json.dumps(output,indent=2,sort_keys=True)+'\n')
    print(json.dumps(output,sort_keys=True))


if __name__=='__main__': main()
