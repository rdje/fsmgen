"""Independent fresh-observation custody, byte and allocation oracle."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-observation-acquisition-20260910'
PLAN_SHA = 'b2a2b1ec2d83f8a3260bd9d1e288af240b0965f71b8c0497d9dc55032870d2a2'
WRAPPER = b'#!/usr/bin/perl\n# inert observation wrapper; never executed\n'


def load(name: str, directory: str):
    spec = importlib.util.spec_from_file_location(name, BASE.parent / directory / 'audit.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


ACQUISITION = load('observation_runtime_acquisition', 'native-proxy-runtime-acquisition-20260910')
OBSERVATION = load('observation_record_codec', 'native-proxy-observation-records-20260910')
RUNTIME = load('observation_runtime_record', 'native-proxy-runtime-records-20260910')
VECTOR = json.loads((BASE.parent / 'native-proxy-image-custody-20260910/vectors.json').read_bytes())
C, IMAGE = (bytes.fromhex(VECTOR[name]) for name in ('generated_c_hex', 'image_hex'))


def canonical(value: object) -> bytes:
    return json.dumps(value,sort_keys=True,ensure_ascii=True,separators=(',',':'),allow_nan=False).encode('ascii')


def identity(value: dict) -> dict:
    return {key: value[key] for key in ('path','device','inode')}


def native(value: dict) -> None:
    assert type(value['device']) is int and value['device'] == ROOT.stat().st_dev
    assert type(value['inode']) is int and value['inode'] > 0


def node_for(footprint: dict, context: dict, path: str) -> dict:
    matches = [(kind,path.removeprefix(context[kind]['path'] + '/'))
               for kind in ('store','workspace','other_workspace','evidence')
               if path.startswith(context[kind]['path'] + '/')]
    assert len(matches) == 1
    kind, relative = matches[0]
    return footprint[kind][relative]


def observed_source(value: dict, path: str, raw: bytes, mode: int, footprint: dict, context: dict) -> None:
    assert set(value) == {'bytes','identity'} and value['bytes'].encode('latin1') == raw
    source = value['identity']
    assert set(source) == {'path','device','inode','size_bytes','sha256'} and source['path'] == path
    native(source)
    assert type(source['size_bytes']) is int and source['size_bytes'] == len(raw)
    assert source['sha256'] == hashlib.sha256(raw).hexdigest()
    node = node_for(footprint,context,path)
    assert node['kind'] == 'file' and node['mode'] == mode and node['links'] == 1
    assert all(node[key] == source[key] for key in ('device','inode','sha256'))
    assert node['bytes'] == len(raw)


def expected_observation(context: dict, offset: int = 0) -> dict:
    request = copy.deepcopy(context['request'])
    request['target_birth']['pid'] += offset
    record = dict(schema=OBSERVATION.SCHEMA, image_key=context['runtime']['image']['key'],
        evidence_directory=context['evidence']['path'], evidence_directory_identity=identity(context['evidence']),
        observer_birth=request['observer_birth'], target_birth=request['target_birth'],
        selected_sources=context['runtime']['reference']['record']['selected_sources'])
    record['reference_key'] = OBSERVATION.key(record)
    OBSERVATION.validate(context['store']['path'],canonical(record).decode('ascii'))
    return record


def file_fields(raw: bytes, mode: int, links: int = 1, source: dict | None = None) -> dict:
    result = dict(kind='file',mode=mode,links=links,bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
    if source is not None:
        result.update(device=source['device'],inode=source['inode'])
    return result


def check_before(row: dict) -> None:
    context, footprint, name = (row[key] for key in ('context','before','name'))
    expected = {kind: {'': dict(kind='directory',mode=0o700,**{k:context[kind][k] for k in ('device','inode')})}
                for kind in ('store','workspace','other_workspace','evidence')}
    expected['store'].update({'images':dict(kind='directory',mode=0o700),
        'references':dict(kind='directory',mode=0o700),
        'coordination.lock':file_fields(b'',0o600,source=context['runtime']['lock'])})
    for kind, runtime in [('workspace',context['runtime']),('other_workspace',context['other_runtime'])]:
        key = runtime['image']['key']
        expected['store'][f'images/{key}'] = dict(kind='directory',mode=0o700)
        for snapshot, filename, mode in zip(runtime['image']['snapshots'],('rustup.c','rustup','image.json'),(0o400,0o500,0o400)):
            expected['store'][f'images/{key}/{filename}'] = file_fields(snapshot['bytes'].encode('latin1'),mode,source=snapshot['identity'])
        global_source, private = (runtime['reference'][key] for key in ('global','private'))
        reference = runtime['reference']['record']
        global_bytes, private_bytes = canonical(reference),canonical(reference)
        if kind == 'workspace' and name in ('mismatched private/global runtime bytes','stale canonical runtime source identity','foreign runtime workspace'):
            altered = copy.deepcopy(reference)
            if name == 'mismatched private/global runtime bytes':
                altered['workspace_identity']['inode'] += 1
                private_bytes = canonical(altered)
            elif name == 'stale canonical runtime source identity':
                altered['selected_sources'][0]['inode'] += 1
                global_bytes = private_bytes = canonical(altered)
            else:
                altered['workspace_identity']['path'] += 'Other'
                global_bytes = canonical(altered)
        expected['store']['references/' + reference['reference_key'] + '.json'] = file_fields(global_bytes,0o400,source=global_source['identity'])
        expected[kind]['rust-tools'] = dict(kind='directory',mode=0o700)
        expected[kind]['rust-tools/image-reference.json'] = file_fields(private_bytes,0o400,source=private['identity'])
        wrapper = b'W' * (65536 if name == 'wrapper exact byte ceiling' else 65537) if kind == 'workspace' and name in (
            'wrapper exact byte ceiling','wrapper byte excess') else WRAPPER
        expected[kind]['rust-tool-resolution'] = file_fields(wrapper,0o700)
    if name == 'missing existing lock':
        expected['store'].pop('coordination.lock')
    if name in ('missing existing namespace','missing runtime reference'):
        expected['store'].pop('references/' + context['runtime']['reference']['record']['reference_key'] + '.json')
        if name == 'missing existing namespace':
            expected['store'].pop('references/' + context['other_runtime']['reference']['record']['reference_key'] + '.json')
            expected['store'].pop('references')
    if name in ('reference capacity before publication','existing observation hold'):
        offsets = range(1000,1126) if name == 'reference capacity before publication' else (0,)
        for offset in offsets:
            value = expected_observation(context,offset)
            expected['store'][f"references/{value['reference_key']}.json"] = file_fields(canonical(value),0o400)
    if name == 'wrapper symlink':
        expected['workspace']['rust-tool-resolution'] = dict(kind='symlink',target='rust-tools/image-reference.json')
    elif name == 'wrapper hardlink':
        expected['workspace']['rust-tool-resolution']['links'] = 2
        expected['workspace']['wrapper-alias'] = file_fields(WRAPPER,0o700,2)
        assert footprint['workspace']['rust-tool-resolution']['inode'] == footprint['workspace']['wrapper-alias']['inode']
    elif name == 'wrapper wrong mode':
        expected['workspace']['rust-tool-resolution']['mode'] = 0o600
    assert set(footprint) == set(expected)
    for kind, nodes in expected.items():
        assert set(footprint[kind]) == set(nodes)
        for path, wanted in nodes.items():
            actual = footprint[kind][path]
            native(actual)
            assert actual['uid'] == os.getuid()
            assert all(actual[key] == value for key,value in wanted.items()),(name,kind,path)


def check_success(row: dict) -> None:
    context, result, after = (row[key] for key in ('context','result','after'))
    assert row['returned'] == 1 and row['error'] == ''
    assert set(result) == {'schema','runtime_authorized','executable','lock','observation_reference','target_sources'}
    assert result['schema'] == 'fsmgen.inactive_observation_acquisition.v1'
    assert type(result['runtime_authorized']) is int and result['runtime_authorized'] == 0 and result['executable'] is None
    assert result['lock'] == context['runtime']['lock']
    record = expected_observation(context)
    hold = result['observation_reference']
    assert set(hold) == {'record','source'} and hold['record'] == record
    path = context['store']['path'] + '/references/' + record['reference_key'] + '.json'
    observed_source(hold['source'],path,canonical(record),0o400,after,context)
    assert all(after['evidence'][''][key] == record['evidence_directory_identity'][key] for key in ('device','inode'))
    runtime = context['runtime']
    wrapper = b'W' * 65536 if row['name'] == 'wrapper exact byte ceiling' else WRAPPER
    selected = [(context['workspace']['path']+'/rust-tool-resolution',wrapper,0o700),
        (runtime['reference']['private']['identity']['path'],canonical(runtime['reference']['record']),0o400),
        (runtime['reference']['global']['identity']['path'],canonical(runtime['reference']['record']),0o400),
        (runtime['image']['snapshots'][0]['identity']['path'],C,0o400),
        (runtime['image']['snapshots'][1]['identity']['path'],IMAGE,0o500)]
    assert len(result['target_sources']) == len(selected)
    for source,(path,raw,mode) in zip(result['target_sources'],selected):
        observed_source(source,path,raw,mode,after,context)
    expected = copy.deepcopy(row['before'])
    expected['store']['references/'+record['reference_key']+'.json'] = after['store']['references/'+record['reference_key']+'.json']
    assert expected == after


def check_late(row: dict, planned: dict) -> None:
    context, before, injected, name = (row[key] for key in ('context','before','injected','name'))
    assert row['returned'] == 0 and row['diagnostic_matched'] == 1 and injected == row['after']
    expected = copy.deepcopy(before)
    if planned['hold_expected']:
        value = expected_observation(context)
        path = 'references/' + value['reference_key'] + '.json'
        original = row['before_injection']['store'][path]
        assert all(original[key] == value for key,value in file_fields(canonical(value),0o400).items())
        expected['store'][path] = original
        assert expected == row['before_injection']
    selected = {
        'source directory replacement': ('workspace','rust-tools'),
        'source replacement during admission': ('workspace','rust-tool-resolution'),
        'source bytes changed before return': ('workspace','rust-tool-resolution'),
        'late evidence directory replacement': ('evidence',''),
        'late workspace directory replacement': ('workspace',''),
        'sealed observation replacement': ('store','references/'+expected_observation(context)['reference_key']+'.json'),
    }[name]
    kind,path = selected
    old,new = expected[kind][path],injected[kind][path]
    if name == 'source bytes changed before return':
        assert new == dict(old,bytes=len(WRAPPER+b'changed'),sha256=hashlib.sha256(WRAPPER+b'changed').hexdigest())
    else:
        native(new)
        assert old['inode'] != new['inode'] and new == dict(old,inode=new['inode'])
    expected[kind][path] = new
    assert expected == injected


def validate(result: dict, plan: dict) -> None:
    assert result['schema'] == 'fsmgen.inactive_observation_acquisition_qualification.v1' and result['success'] is True
    assert type(result['forbidden_process_attempts']) is int and result['forbidden_process_attempts'] == 0
    allocations = result['allocated']
    assert allocations == [json.loads(line) for line in (LOG/'admission.jsonl').read_text().splitlines()]
    paths = {row['path']:row for row in allocations}
    assert len(paths) == len(allocations) == 4 * (len(plan['cases'])+len(plan['late_cases'])+len(plan['mutants']))
    for path,entry in paths.items():
        assert entry['kind'] in ('store','workspace','evidence')
        prefix = {'store':'.artifacts/tmp/native-proxy-image-custody/cases/',
            'workspace':'.artifacts/tmp/process-supervisor-tests/',
            'evidence':'.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/'}[entry['kind']]
        assert re.fullmatch(re.escape(prefix)+r'fsmgen-[A-Za-z0-9_]+',path)
        native(entry)
        assert not (ROOT/path).exists() and not (ROOT/path).is_symlink()
    assert [r['name'] for r in result['cases']] == [r['name'] for r in plan['cases']]
    assert [r['name'] for r in result['late_changes']] == [r['name'] for r in plan['late_cases']]
    assert [r['name'] for r in result['mutants']] == plan['mutants']
    rows = [*result['cases'],*result['late_changes'],*result['mutants']]
    used = []
    for row in rows:
        context = row['context']
        for kind in ('store','workspace','other_workspace','evidence'):
            assert context[kind] == paths[context[kind]['path']]
            used.append(context[kind]['path'])
        ACQUISITION.acquisition(context['runtime'],paths,IMAGE)
        ACQUISITION.acquisition(context['other_runtime'],paths,IMAGE+b'other')
        assert context['request']['workspace_identity'] == identity(context['workspace'])
        assert context['request']['evidence_directory_identity'] == identity(context['evidence'])
        check_before(row)
        for descriptor in row['descriptors']:
            assert type(descriptor['descriptor']) is int and descriptor['descriptor'] >= 0
            assert descriptor['closed'] == descriptor['cloexec'] == 1
            assert descriptor['path'].startswith((context['workspace']['path']+'/',context['store']['path']+'/'))
    assert len(used) == len(set(used)) and set(used) == set(paths)
    for row,planned in zip(result['cases'],plan['cases']):
        assert row['request'] == row['request_after']
        assert row['diagnostic_matched'] == 1
        if planned['kind'] == 'success':
            assert len(row['descriptors']) >= 5
            check_success(row)
        else:
            assert row['returned'] == 0 and row['before'] == row['after'] and planned['diagnostic'] in row['error']
    for row,planned in zip(result['late_changes'],plan['late_cases']):
        assert row['descriptors']
        check_late(row,planned)
    for row in result['mutants']:
        assert row['returned'] == 1
        try:
            check_success(row)
        except AssertionError:
            pass
        else:
            raise AssertionError('independent oracle missed custody mutant: '+row['name'])


def regressions(result: dict) -> dict:
    combined = load('observation_combined_regression', 'native-proxy-combined-census-20260910')
    combined.LOG = LOG / 'combined-census-regression'
    combined_result = json.loads((combined.LOG/'qualification.json').read_bytes())
    combined.validate(combined_result,json.loads((combined.BASE/'plan.json').read_bytes()))
    assert RUNTIME.tap_count((combined.LOG/'qualify.tap').read_text()) == 35

    acquired = LOG / 'runtime-acquisition-regression'
    acquisition_result = json.loads((acquired/'qualification.json').read_bytes())
    ACQUISITION.validate(acquisition_result)
    assert acquisition_result['allocated'] == [json.loads(line) for line in (acquired/'admission.jsonl').read_text().splitlines()]
    assert RUNTIME.tap_count((acquired/'qualify.tap').read_text()) == 79

    initial = LOG / 'initial-runtime-acquisition-regression'
    failed = json.loads((initial/'qualification.json').read_bytes())
    assert failed['success'] is False
    assert failed['allocated'] == [json.loads(line) for line in (initial/'admission.jsonl').read_text().splitlines()]
    ACQUISITION.allocations(failed)
    bad = [row for row in failed['controls'] if row['expected_diagnostic'] != 1]
    assert bad == [dict(name='admission malformed_global',rejected=1,expected_diagnostic=0,returned_result=0)]
    assert re.findall(r'^not ok \d+ - (.*)$',(initial/'qualify.tap').read_text(),re.M) == ['admission malformed_global']
    assert 'invalid reference JSON' in (initial/'qualify.stderr').read_text()
    original_source = (initial/'qualify.t.source').read_bytes()
    assert hashlib.sha256(original_source).hexdigest() == '9aff78c5e58d63c2bdce64587beb73127bc070e9127d5f45826f8e546cb2343a'
    old = b'malformed_global => qr/invalid runtime JSON/'
    new = b'malformed_global => qr/invalid reference JSON/'
    assert original_source.count(old) == 1
    assert (ACQUISITION.BASE/'qualify.t').read_bytes() == original_source.replace(old,new)
    # The failed result remains false and byte-exact. This analysis-only
    # projection isolates its diagnostic mismatch; it is not a passing run.
    projected = copy.deepcopy(failed)
    projected['success'] = True
    next(row for row in projected['controls'] if row['name'] == bad[0]['name'])['expected_diagnostic'] = 1
    ACQUISITION.validate(projected)
    paths = [row['path'] for data in (result,combined_result,acquisition_result,failed) for row in data['allocated']]
    assert len(paths) == len(set(paths))
    assert all(not (ROOT/path).exists() and not (ROOT/path).is_symlink() for path in paths)
    return dict(combined_census=dict(assertions=35,allocations=len(combined_result['allocated'])),
        runtime_acquisition=dict(assertions=79,allocations=len(acquisition_result['allocated'])),
        initial_runtime_acquisition=dict(success=False,allocations=len(failed['allocated']),
            sole_failure='stale malformed_global diagnostic expectation',other_semantics_checked_on_explicit_projection=True),
        all_rosters_disjoint_and_absent=True)


def main() -> None:
    assert hashlib.sha256((BASE/'plan.json').read_bytes()).hexdigest() == PLAN_SHA
    plan = json.loads((BASE/'plan.json').read_bytes())
    result = json.loads((LOG/'qualification.json').read_bytes())
    validate(result,plan)
    assertions = RUNTIME.tap_count((LOG/'qualify.tap').read_text())
    assert assertions == (len(plan['cases'])+len(plan['late_cases'])+len(plan['mutants']))*2+1
    falsifiers = []
    for name,mutate in [
        ('hidden failure',lambda x:x.update(success=False)),
        ('lost source',lambda x:x['cases'][0]['result']['target_sources'].pop()),
        ('source identity substituted',lambda x:x['cases'][0]['result']['target_sources'][0]['identity'].update(inode=1)),
        ('evidence identity substituted',lambda x:x['cases'][0]['result']['observation_reference']['record']['evidence_directory_identity'].update(inode=1)),
        ('runtime authority',lambda x:x['cases'][0]['result'].update(runtime_authorized=1)),
        ('lost descriptor closure',lambda x:x['cases'][0]['descriptors'][0].update(closed=0)),
        ('lost rejection',lambda x:x['cases'].pop()),
        ('lost late hold',lambda x:x['late_changes'][2]['after']['store'].pop('references')),
        ('lost mutant',lambda x:x['mutants'].pop()),
        ('lost allocation',lambda x:x['allocated'].pop()),
        ('forbidden process',lambda x:x.update(forbidden_process_attempts=1)),
    ]:
        altered = copy.deepcopy(result)
        mutate(altered)
        try:
            validate(altered,plan)
        except AssertionError:
            falsifiers.append(name)
        else:
            raise AssertionError('counterfactual accepted: '+name)
    report = dict(schema='fsmgen.inactive_observation_acquisition_audit.v1',success=True,
        assertions=assertions,allocations=len(result['allocated']),cases=len(plan['cases']),late_changes=len(plan['late_cases']),
        mutants=plan['mutants'],falsifiers=falsifiers,regressions=regressions(result),limits=plan['limits'])
    (LOG/'audit.json').write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print(json.dumps(report,sort_keys=True))


if __name__ == '__main__':
    main()
