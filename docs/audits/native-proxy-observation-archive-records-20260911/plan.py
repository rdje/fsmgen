"""Construct a prospective, pure archive-record domain from dated acquisitions."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '74ec076e29cadb651abfaf2e0051da45450e55c4'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.1'
ROLES = ['wrapper', 'private_reference', 'global_reference', 'c', 'image']


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True)


def wire(value):
    if isinstance(value, list): return [wire(x) for x in value]
    if isinstance(value, dict):
        return {('bytes_hex' if k == 'bytes' else k):
                (v.encode('latin1').hex() if k == 'bytes' else wire(v)) for k, v in value.items()}
    return value


def pin(path):
    raw = (ROOT/path).read_bytes()
    assert raw == subprocess.check_output(['git', 'show', REVISION+':'+path], cwd=ROOT)
    return dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def vector(name, case, request, acquisition):
    directory = dict(request['evidence_directory_identity'])
    directory.update(path=directory['path']+'/retained-sources', inode=900000001)
    sources, files, snapshots = [], [], []
    for role, source in zip(ROLES, acquisition['target_sources'], strict=True):
        identity = source['identity']
        path = directory['path']+'/'+identity['sha256']+'.source'
        sources.append(dict(role=role, destination=path, snapshot=copy.deepcopy(source)))
        if path not in [x['path'] for x in files]:
            files.append(dict(path=path, bytes=source['bytes'],
                              size_bytes=identity['size_bytes'], sha256=identity['sha256']))
            snapshots.append(dict(bytes=source['bytes'], identity=dict(
                path=path, device=directory['device'], inode=900000002+len(files),
                size_bytes=identity['size_bytes'], sha256=identity['sha256'])))
    common = dict(runtime_authorized=0, executable=None,
                  evidence_directory_identity=copy.deepcopy(request['evidence_directory_identity']),
                  observation_reference_key=acquisition['observation_reference']['record']['reference_key'])
    spec = dict(common, schema='fsmgen.inactive_observation_archive_specification.v1',
                archive_directory=directory['path'], sources=sources, files=files)
    identities = {x['identity']['path']:x['identity'] for x in snapshots}
    receipt = dict(common, schema='fsmgen.inactive_observation_archive.v1',
                   archive_directory_identity=directory, source_bindings=[
                       dict(role=x['role'], source=x['snapshot']['identity'], archive=identities[x['destination']])
                       for x in sources])
    return wire(dict(name=name, case=case, request=request, acquired=acquisition,
                     directory=directory, snapshots=snapshots, specification=spec,
                     receipt=receipt, raw=canonical(receipt)))


def build():
    inputs, vectors = [], []
    for kind, selected in [('acquisition', 'fresh acquisition'), ('reuse', 'stable repeated reuse')]:
        prefix = f'docs/audits/native-proxy-observation-{kind}-20260910/result/'
        receipt_path, manifest_path = prefix+'qualification.json', prefix+'recovery-copies.json'
        inputs.extend([pin(receipt_path), pin(manifest_path)])
        manifest = json.loads((ROOT/manifest_path).read_bytes())
        recorded = next(r for r in manifest['files'] if r['destination'] == receipt_path)
        actual = inputs[-2]
        assert all(recorded[k] == actual[k] for k in ('size_bytes','sha256'))
        report = json.loads((ROOT/receipt_path).read_bytes())
        assert report['success'] is True
        row = next(r for r in report['cases'] if r['name'] == selected)
        assert row['returned'] == 1 and not row['error']
        v = vector('historical '+kind, row['context']['store']['path'], row['request'], row['result'])
        v['historical_origin'] = dict(path=receipt_path, case_name=selected)
        vectors.append(v)
    base = vectors[0]
    # Construct only the independent wrapper snapshot. Embedded runtime and
    # observation records remain the actual historical input octets.
    for name, data in [('binary wrapper', bytes(range(256))), ('wrapper exact ceiling', b'x'*65536),
                       ('empty wrapper', b''), ('three equal sources', bytes.fromhex(base['acquired']['target_sources'][1]['bytes_hex']))]:
        acquisition = copy.deepcopy(base['acquired'])
        def unwire(value):
            if isinstance(value, list): return [unwire(x) for x in value]
            if isinstance(value, dict): return {('bytes' if k=='bytes_hex' else k):
                (bytes.fromhex(v).decode('latin1') if k=='bytes_hex' else unwire(v)) for k,v in value.items()}
            return value
        acquisition = unwire(acquisition)
        acquisition['target_sources'][0]['bytes'] = data.decode('latin1')
        acquisition['target_sources'][0]['identity'].update(size_bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
        v = vector('constructed '+name, base['case'], base['request'], acquisition)
        v['construction'] = 'Only original wrapper bytes/size/hash differ from historical acquisition; archive native IDs are synthetic.'
        vectors.append(v)

    controls = []
    def control(name, op='validate', path=None, value=None, action='set', **kw):
        steps = [] if path is None else [dict(action=action, path=path, value=value)]
        controls.append(dict(name=name, operation=op, vector=0, steps=steps, **kw))
    # Every closed output record layer rejects absent and extra fields.
    for path, fields in [(['receipt'], base['receipt']),
                         (['receipt','evidence_directory_identity'], base['receipt']['evidence_directory_identity']),
                         (['receipt','archive_directory_identity'], base['directory']),
                         (['receipt','source_bindings',0], base['receipt']['source_bindings'][0]),
                         (['receipt','source_bindings',0,'source'], base['receipt']['source_bindings'][0]['source']),
                         (['receipt','source_bindings',0,'archive'], base['receipt']['source_bindings'][0]['archive'])]:
        prefix = '.'.join(map(str,path))
        for key in fields: control(prefix+' missing '+key, path=path+[key], action='delete')
        control(prefix+' extra field', path=path+['extra'], value=1)
    for value in (1, True, '0', None, [], {}):
        control('authority '+canonical(value), path=['receipt','runtime_authorized'], value=value)
    for value in ('native', 0, False):
        control('executable '+canonical(value), path=['receipt','executable'], value=value)
    control('wrong schema', path=['receipt','schema'], value='foreign')
    control('foreign hold key', path=['receipt','observation_reference_key'], value='f'*64)
    control('foreign evidence', path=['receipt','evidence_directory_identity','inode'], value=23)
    control('foreign archive path', path=['receipt','archive_directory_identity','path'], value='.artifacts/foreign')
    control('foreign archive device', path=['receipt','archive_directory_identity','device'], value=23)
    control('archive directory aliases evidence', path=['receipt','archive_directory_identity','inode'], value=base['request']['evidence_directory_identity']['inode'])
    for key in ('device','inode','size_bytes'):
        for value in (-1, 1.5, True, '1', None, []):
            control(f'archive {key} type '+canonical(value), path=['receipt','source_bindings',0,'archive',key], value=value)
    for value in ('F'*64, 'a'*63, None):
        control('archive digest '+canonical(value), path=['receipt','source_bindings',0,'archive','sha256'], value=value)
    for index in range(5):
        control(f'changed original identity {index}', path=['receipt','source_bindings',index,'source','inode'], value=23)
        control(f'changed role {index}', path=['receipt','source_bindings',index,'role'], value='foreign')
        control(f'changed content path {index}', path=['receipt','source_bindings',index,'archive','path'], value='.artifacts/foreign.source')
        control(f'changed content length {index}', path=['receipt','source_bindings',index,'archive','size_bytes'], value=65537)
        control(f'changed content hash {index}', path=['receipt','source_bindings',index,'archive','sha256'], value='f'*64)
    control('shared path inconsistent native identity', path=['receipt','source_bindings',2,'archive','inode'], value=800000001)
    for label, inode in [('parent',base['request']['evidence_directory_identity']['inode']), ('directory',900000001), ('other file',900000004)]:
        control('native identity aliases '+label, path=['receipt','source_bindings',0,'archive','inode'], value=inode)
    for action in ('pop','reverse','duplicate'):
        control('binding list '+action, path=['receipt','source_bindings'], action=action)
        control('snapshot list '+action, op='receipt', path=['snapshots'], action=action)
    for path,value in [(['snapshots',0,'bytes_hex'],'00'), (['snapshots',0,'identity','size_bytes'],23),
                       (['snapshots',0,'identity','sha256'],'f'*64), (['snapshots',0,'identity','device'],23),
                       (['snapshots',0,'identity','path'],'.artifacts/foreign'), (['snapshots',0,'extra'],1),
                       (['directory','extra'],1), (['directory','path'],'.artifacts/foreign')]:
        control('snapshot '+'.'.join(map(str,path)), op='receipt', path=path, value=value)
    altered = copy.deepcopy(base['snapshots'][0]); altered['bytes_hex']='00'
    altered['identity'].update(size_bytes=1, sha256=hashlib.sha256(b'\0').hexdigest())
    control('self consistent changed archive content', op='receipt', path=['snapshots',0], value=altered)
    for path,value in [(['acquired','runtime_authorized'],1), (['acquired','lock','device'],23),
                       (['request','evidence_directory_identity','inode'],23),
                       (['acquired','target_sources',0,'identity','device'],23),
                       (['acquired','target_sources',0,'bytes_hex'],'00'),
                       (['acquired','target_sources'],[]), (['acquired','extra'],1)]:
        control('original '+'.'.join(map(str,path)), op='specification', path=path, value=value)
    oversized = copy.deepcopy(base['acquired']['target_sources'][0]); data=b'x'*65537
    oversized.update(bytes_hex=data.hex()); oversized['identity'].update(size_bytes=len(data),sha256=hashlib.sha256(data).hexdigest())
    control('original wrapper exceeds ceiling', op='specification', path=['acquired','target_sources',0],value=oversized)
    raw=base['raw']
    for name,value in [('whitespace',raw+'\n'), ('duplicate field','{"schema":"foreign",'+raw[1:]),
                       ('noncanonical number',raw.replace('"runtime_authorized":0','"runtime_authorized":0.0')),
                       ('deep nesting','['*10+'0'+']'*10), ('oversized',' '*65537), ('malformed','{'),
                       ('array',[]), ('null',None), ('non ASCII','é')]:
        control('decode '+name, op='decode', path=['raw'], value=value)
    for op in ('specification','receipt','validate','encode','decode'):
        control(op+' missing argument',op=op, argument_change='drop')
        control(op+' extra argument',op=op, argument_change='append')
    control('decode character scalar',op='decode',upgrade=['raw'])
    control('original character octets',op='specification',upgrade=['acquired','target_sources',0,'bytes'])
    control('archive character octets',op='receipt',upgrade=['snapshots',0,'bytes'])
    mutants = [dict(name='omitted original identity', control='changed original identity 0', helper='_matches_original'),
               dict(name='omitted shared identity', control='shared path inconsistent native identity',helper='_same_shared_identity'),
               dict(name='omitted source content binding',control='self consistent changed archive content',helper='_matches_source')]
    assert len({x['name'] for x in controls}) == len(controls)
    inventory=json.loads((ROOT/'docs/audits/native-proxy-observation-acquisition-join-20260911/result/source-inventory.json').read_bytes())
    paths=inventory['declared_perl_sources']+['docs/audits/native-proxy-observation-release-contract-20260911/contract.json',
        'docs/audits/native-proxy-observation-acquisition-join-20260911/result/source-inventory.json']
    inputs.extend(pin(path) for path in paths)
    return dict(schema='fsmgen.inactive_archive_record_plan.v1',owner=OWNER,source_revision=REVISION,
        inputs=inputs,vectors=vectors,controls=controls,mutants=mutants,
        limits='Pure data with synthetic archive native IDs. Historical acquisitions are authenticated but their target files are never reopened. No archival, descriptor/permission proof, hold release, process execution, native authority or receipt transport. The selected 65536-byte canonical ASCII receipt ceiling is structural only.')


if __name__ == '__main__':
    result=build()
    (BASE/'plan.json').write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
    print(json.dumps(dict(vectors=len(result['vectors']),controls=len(result['controls']),mutants=len(result['mutants']),inputs=len(result['inputs']))))
