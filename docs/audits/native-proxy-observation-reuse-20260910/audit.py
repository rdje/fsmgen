"""Independent stable observation-reuse receipts, footprints and custody oracle."""
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
LOG = ROOT / '.artifacts/logs/native-proxy-observation-reuse-20260910'
PLAN_SHA = '441e543fd94e59029d95b5fd8d44b7f2a9903aa04d697af5ae86df40ecf07c72'


def load(name: str, directory: str):
    spec = importlib.util.spec_from_file_location(name, BASE.parent/directory/'audit.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


FRESH = load('reuse_fresh_oracle', 'native-proxy-observation-acquisition-20260910')


def snapshot_bytes(snapshot: dict, raw: bytes) -> None:
    snapshot['bytes'] = raw.decode('latin1')
    snapshot['identity'].update(size_bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())


def receipt_inputs(row: dict) -> None:
    name = row['name']
    previous = copy.deepcopy(row['context']['previous'])
    request = copy.deepcopy(row['context']['request'])
    source = previous['target_sources'][0]
    if name == 'extra receipt field': previous['extra'] = 0
    elif name == 'runtime authority': previous['runtime_authorized'] = 1
    elif name == 'executable supplied': previous['executable'] = 'rustup'
    elif name == 'boolean lock inode': previous['lock']['inode'] = True
    elif name == 'foreign lock path': previous['lock']['path'] += 'Other'
    elif name == 'missing target source': previous['target_sources'].pop()
    elif name == 'extra source field': source['extra'] = 0
    elif name == 'oversized wrapper': source['bytes'] = 'W' * 65537
    elif name == 'source hash mismatch': source['identity']['sha256'] = '0' * 64
    elif name == 'source size mismatch': source['identity']['size_bytes'] += 1
    elif name == 'string source inode': source['identity']['inode'] = '7'
    elif name == 'foreign source path': source['identity']['path'] += 'Other'
    elif name == 'hold bytes mismatch': previous['observation_reference']['source']['bytes'] += ' '
    elif name == 'request target birth differs': request['target_birth']['pid'] += 1
    elif name == 'request evidence identity differs': request['evidence_directory_identity']['inode'] += 1
    elif name == 'request workspace identity differs': request['workspace_identity']['inode'] += 1
    elif name == 'private global bytes differ':
        selected = previous['target_sources'][1]
        snapshot_bytes(selected,selected['bytes'].encode('latin1')+b' ')
    elif name == 'source order differs': previous['target_sources'][3:5] = previous['target_sources'][3:5][::-1]
    assert row['request'] == request and row['previous'] == previous
    assert row['request_after'] == request and row['previous_after'] == previous
    # Python treats bool and int as equal: canonical bytes preserve the declared
    # JSON type checks in hostile inputs, including the string-valued inode.
    assert FRESH.canonical(row['previous']) == FRESH.canonical(previous)


def location(context: dict, path: str) -> tuple[str, str]:
    roots = [(kind,entry['path']) for kind,entry in context.items()
             if kind in ('store','workspace','other_workspace','evidence')]
    matches = [(kind,path[len(root)+1:]) for kind,root in roots if path.startswith(root+'/')]
    assert len(matches) == 1
    return matches[0]


def replace_identity(expected: dict, actual: dict, kind: str, path: str) -> None:
    old,new = expected[kind][path],actual[kind][path]
    FRESH.native(new)
    assert old['inode'] != new['inode']
    assert new == dict(old,inode=new['inode'])
    expected[kind][path] = new


def changed_footprint(context: dict, original: dict, actual: dict, name: str) -> None:
    expected = copy.deepcopy(original)
    previous = context['previous']
    hold = location(context,previous['observation_reference']['source']['identity']['path'])
    target = [location(context,source['identity']['path']) for source in previous['target_sources']]
    replacements = {
        'current hold replaced':hold, 'discard prior hold identity':hold, 'hold replaced before closure':hold,
        'current lock replaced':('store','coordination.lock'),
        'current wrapper replaced':target[0], 'discard prior target snapshots':target[0],
        'wrapper replaced before closure':target[0], 'current private reference replaced':target[1],
        'current global reference replaced':target[2], 'current canonical source replaced':target[3],
        'current evidence directory replaced':('evidence',''), 'evidence directory replaced before closure':('evidence',''),
        'current workspace directory replaced':('workspace',''), 'workspace directory replaced before closure':('workspace',''),
    }
    if name in replacements:
        replace_identity(expected,actual,*replacements[name])
    elif name in ('current hold absent','current runtime reference absent'):
        kind,path = hold if name == 'current hold absent' else target[2]
        expected[kind].pop(path)
    elif name == 'current wrapper bytes changed':
        kind,path = target[0]
        raw = FRESH.WRAPPER+b'changed'
        expected[kind][path].update(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
    elif name == 'current hold ownership changed':
        record = copy.deepcopy(previous['observation_reference']['record'])
        record['evidence_directory_identity']['inode'] += 1
        raw = FRESH.canonical(record)
        kind,path = hold
        expected[kind][path].update(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())
    elif name == 'reuse at combined capacity':
        for offset in range(1000,1125):
            record = FRESH.expected_observation(context,offset)
            path = 'references/'+record['reference_key']+'.json'
            node = actual['store'][path]
            FRESH.native(node)
            assert node['uid'] == os.getuid()
            assert node == dict(FRESH.file_fields(FRESH.canonical(record),0o400),
                device=node['device'],inode=node['inode'],uid=os.getuid())
            expected['store'][path] = node
    assert expected == actual,(name,'unexpected footprint change')


def validate(result: dict, plan: dict) -> None:
    assert result['schema'] == 'fsmgen.inactive_observation_reuse_qualification.v1' and result['success'] is True
    for name in ('forbidden_process_attempts','forbidden_publication_attempts'):
        assert type(result[name]) is int and result[name] == 0
    allocations = result['allocated']
    assert allocations == [json.loads(line) for line in (LOG/'admission.jsonl').read_text().splitlines()]
    paths = {row['path']:row for row in allocations}
    assert len(paths) == len(allocations) == 4 * (len(plan['cases'])+len(plan['late_cases'])+len(plan['mutants']))
    for path,entry in paths.items():
        prefix = {'store':'.artifacts/tmp/native-proxy-image-custody/cases/',
            'workspace':'.artifacts/tmp/process-supervisor-tests/',
            'evidence':'.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/'}[entry['kind']]
        assert re.fullmatch(re.escape(prefix)+r'fsmgen-[A-Za-z0-9_]+',path)
        FRESH.native(entry)
        assert not (ROOT/path).exists() and not (ROOT/path).is_symlink()
    assert [row['name'] for row in result['cases']] == [row['name'] for row in plan['cases']]
    assert [row['name'] for row in result['late_changes']] == plan['late_cases']
    assert [row['name'] for row in result['mutants']] == plan['mutants']
    used = []
    for row in [*result['cases'],*result['late_changes'],*result['mutants']]:
        context = row['context']
        for kind in ('store','workspace','other_workspace','evidence'):
            assert context[kind] == paths[context[kind]['path']]
            used.append(context[kind]['path'])
        FRESH.ACQUISITION.acquisition(context['runtime'],paths,FRESH.IMAGE)
        FRESH.ACQUISITION.acquisition(context['other_runtime'],paths,FRESH.IMAGE+b'other')
        assert context['request']['workspace_identity'] == FRESH.identity(context['workspace'])
        assert context['request']['evidence_directory_identity'] == FRESH.identity(context['evidence'])
        initial = dict(context=context,name='fresh acquisition',before=context['before_acquisition'],
            after=context['after_acquisition'],result=context['previous'],returned=1,error='')
        FRESH.check_before(initial)
        FRESH.check_success(initial)
        changed_footprint(context,context['after_acquisition'],row['before'],
            '' if row in result['late_changes'] else row['name'])
        allowed = {entry['identity']['path'] for entry in context['previous']['target_sources']}
        allowed.add(context['previous']['observation_reference']['source']['identity']['path'])
        for descriptor in row['descriptors']:
            assert type(descriptor['descriptor']) is int and descriptor['descriptor'] >= 0
            assert descriptor['closed'] == descriptor['cloexec'] == 1 and descriptor['path'] in allowed
        if row['returned'] == 1 or row in result['late_changes']:
            assert {entry['path'] for entry in row['descriptors']} == allowed
    assert len(used) == len(set(used)) and set(used) == set(paths)
    for row,planned in zip(result['cases'],plan['cases']):
        receipt_inputs(row)
        assert row['before'] == row['after'] and row['diagnostic_matched'] == 1
        if planned['kind'] == 'success':
            assert row['returned'] == 1 and row['error'] == ''
            assert FRESH.canonical(row['result']) == FRESH.canonical(row['context']['previous'])
        else:
            assert row['returned'] == 0 and planned['diagnostic'] in row['error']
    for row in result['late_changes']:
        assert row['returned'] == 0 and row['diagnostic_matched'] == 1
        assert row['before'] == row['before_injection'] and row['injected'] == row['after']
        changed_footprint(row['context'],row['before'],row['after'],row['name'])
    for row in result['mutants']:
        assert row['returned'] == 1 and row['error'] == '' and row['before'] == row['after']
        previous = row['context']['previous']
        actual = row['result']
        assert actual != previous
        expected = copy.deepcopy(previous)
        selected = expected['observation_reference']['source'] if row['name'] == 'discard prior hold identity' else expected['target_sources'][0]
        kind,path = location(row['context'],selected['identity']['path'])
        selected['identity']['inode'] = row['after'][kind][path]['inode']
        assert FRESH.canonical(actual) == FRESH.canonical(expected)


def regressions_and_recovery(result: dict) -> dict:
    FRESH.LOG = LOG/'fresh-regression'
    fresh = json.loads((FRESH.LOG/'qualification.json').read_bytes())
    FRESH.validate(fresh,json.loads((FRESH.BASE/'plan.json').read_bytes()))
    assert FRESH.RUNTIME.tap_count((FRESH.LOG/'qualify.tap').read_text()) == 59
    combined = load('reuse_combined_oracle','native-proxy-combined-census-20260910')
    combined.LOG = LOG/'combined-census-regression'
    census = json.loads((combined.LOG/'qualification.json').read_bytes())
    combined.validate(census,json.loads((combined.BASE/'plan.json').read_bytes()))
    assert FRESH.RUNTIME.tap_count((combined.LOG/'qualify.tap').read_text()) == 35
    assert FRESH.RUNTIME.tap_count((LOG/'representation.tap').read_text()) == 15
    paths = [row['path'] for data in (result,fresh,census) for row in data['allocated']]
    initial_runs = []
    for directory, diagnostic, digest in [
        ('initial-byte-representation-failure','expected bounded bytes\n',
         '9ec8c57db5a386dcb580d3d96e2cdd7498f0e4695f763c7a885c9361f194d7eb'),
        ('initial-numeric-representation-failure','expected nonnegative JSON integer\n',
         '68624866286e6caeba34e8ff9279b73fd491ba44d517b16d34c90bdd96d5f431'),
    ]:
        initial = LOG/directory
        failed = json.loads((initial/'qualification.json').read_bytes())
        assert failed['success'] is False and len(failed['cases']) == 1
        assert failed['late_changes'] == failed['mutants'] == []
        assert failed['forbidden_process_attempts'] == failed['forbidden_publication_attempts'] == 0
        ledger = [json.loads(line) for line in (initial/'admission.jsonl').read_text().splitlines()]
        assert failed['allocated'] == ledger and len(ledger) == 4
        assert sorted(entry['kind'] for entry in ledger) == ['evidence','store','workspace','workspace']
        for entry in ledger:
            prefix = {'store':'.artifacts/tmp/native-proxy-image-custody/cases/',
                'workspace':'.artifacts/tmp/process-supervisor-tests/',
                'evidence':'.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/'}[entry['kind']]
            assert re.fullmatch(re.escape(prefix)+r'fsmgen-[A-Za-z0-9_]+',entry['path'])
            FRESH.native(entry)
        paths.extend(row['path'] for row in ledger)
        row = failed['cases'][0]
        assert {row['context'][kind]['path'] for kind in ('store','workspace','other_workspace','evidence')} == {entry['path'] for entry in ledger}
        assert row['name'] == 'stable repeated reuse' and row['returned'] == 0 and row['error'] == diagnostic
        assert row['descriptors'] == [] and row['before'] == row['after']
        assert re.findall(r'^not ok (\d+) - ',(initial/'qualify.tap').read_text(),re.M) == ['2']
        assert 'Bail out!' in (initial/'qualify.tap').read_text()
        assert not re.search(r'^1\.\.',(initial/'qualify.tap').read_text(),re.M)
        source = (initial/'qualify.t.source').read_bytes()
        assert hashlib.sha256(source).hexdigest() == digest
        old_import = b'use Storable qw(dclone);' if 'numeric' in directory else b'use JSON::PP ();'
        new_import = b'use FixtureClone;' if 'numeric' in directory else b'use JSON::PP ();\nuse FixtureClone;'
        old_clone = b'sub clone { return dclone($_[0]); }' if 'numeric' in directory else b'sub clone { return $JSON->decode($JSON->encode($_[0])); }'
        repaired = source.replace(old_import,new_import).replace(old_clone,
            b'sub clone { return NativeProxyObservationFixtureClone::clone($_[0]); }')
        assert repaired == (BASE/'qualify.t').read_bytes()
        if 'numeric' in directory:
            for field in ('device','inode'):
                assert type(row['previous']['lock'][field]) is str
                assert type(row['before']['store']['coordination.lock'][field]) is int
                assert int(row['previous']['lock'][field]) == row['before']['store']['coordination.lock'][field]
        initial_runs.append(dict(directory=directory,success=False,allocations=len(ledger),
            diagnostic=diagnostic.strip(),no_source_admission_or_mutation=True))
    initial = LOG/'initial-byte-representation-failure'
    for path,name in [(FRESH.BASE/'ObservationAcquisition.pm','ObservationAcquisition.pm.source'),
                      (BASE.parent/'native-proxy-image-coordination-20260910/Coordination.pm','Coordination.pm.source')]:
        assert path.read_bytes() == (initial/name).read_bytes()
    diagnosis = json.loads((initial/'pure-diagnosis.json').read_bytes())
    assert diagnosis['pure_validation_after_octet_restoration'] == 1 and diagnosis['error'] == ''
    assert [row['character_flag'] for row in diagnosis['snapshots']] == [0,0,0,0,1,1]
    assert all(row['octets_recoverable'] == 1 and row['codepoints'] == row['octets_after_downgrade']
               for row in diagnosis['snapshots'])
    assert len(paths) == len(set(paths))
    assert all(not (ROOT/path).exists() and not (ROOT/path).is_symlink() for path in paths)
    return dict(fresh=dict(assertions=59,allocations=len(fresh['allocated'])),
        combined=dict(assertions=35,allocations=len(census['allocated'])),representation_assertions=15,
        initial_runs=initial_runs,prototype_unchanged_after_initial_failure=True,all_rosters_disjoint_and_absent=True)


def main() -> None:
    assert hashlib.sha256((BASE/'plan.json').read_bytes()).hexdigest() == PLAN_SHA
    plan = json.loads((BASE/'plan.json').read_bytes())
    result = json.loads((LOG/'qualification.json').read_bytes())
    validate(result,plan)
    count = FRESH.RUNTIME.tap_count((LOG/'qualify.tap').read_text())
    assert count == 2*(len(plan['cases'])+len(plan['late_cases'])+len(plan['mutants']))+1
    falsifiers = []
    for name,mutate in [
        ('hidden failure',lambda x:x.update(success=False)),
        ('prior hold identity replaced',lambda x:x['cases'][0]['result']['observation_reference']['source']['identity'].update(inode=1)),
        ('prior source identity replaced',lambda x:x['cases'][0]['result']['target_sources'][0]['identity'].update(inode=1)),
        ('authority flag type changed',lambda x:x['cases'][0]['result'].update(runtime_authorized=False)),
        ('lost capacity hold',lambda x:x['cases'][1]['after']['store'].pop('references')),
        ('lost descriptor closure',lambda x:x['cases'][0]['descriptors'][0].update(closed=0)),
        ('lost held descriptor roster',lambda x:x['cases'][0].update(descriptors=[])),
        ('lost rejection',lambda x:x['cases'].pop()),
        ('lost late change',lambda x:x['late_changes'].pop()),
        ('lost mutant',lambda x:x['mutants'].pop()),
        ('lost allocation',lambda x:x['allocated'].pop()),
        ('forbidden process',lambda x:x.update(forbidden_process_attempts=1)),
        ('forbidden publication',lambda x:x.update(forbidden_publication_attempts=1)),
    ]:
        changed = copy.deepcopy(result)
        mutate(changed)
        try:
            validate(changed,plan)
        except AssertionError:
            falsifiers.append(name)
        else:
            raise AssertionError('reuse oracle missed falsifier: '+name)
    report = dict(schema='fsmgen.inactive_observation_reuse_audit.v1',success=True,assertions=count,
        cases=len(plan['cases']),late_changes=len(plan['late_cases']),allocations=len(result['allocated']),
        mutants=plan['mutants'],falsifiers=falsifiers,regressions=regressions_and_recovery(result),limits=plan['limits'])
    (LOG/'audit.json').write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print(json.dumps(report,sort_keys=True))


if __name__ == '__main__':
    main()
