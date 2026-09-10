"""Independent explicit handoff closure and conservative payload-state oracle."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT/'.artifacts/logs/native-proxy-descriptor-handoff-20260910'
PLAN_SHA = '27026f60feac3848d0d163b740be833af20529809cf1defd13a81b868ff2a022'
VECTOR = json.loads((BASE.parent/'native-proxy-image-custody-20260910/vectors.json').read_bytes())
SOURCE = bytes.fromhex(VECTOR['generated_c_hex'])
PAYLOAD = b'inert observation payload\0\xff\n'


def native(value: dict) -> None:
    assert type(value['device']) is int and value['device'] == ROOT.stat().st_dev
    assert type(value['inode']) is int and value['inode'] > 0


def regular(node: dict, raw: bytes) -> None:
    assert set(node) == {'kind','device','inode','mode','links','uid','size_bytes','sha256','bytes'}
    native(node)
    assert node['kind'] == 'file' and node['mode'] == 0o400 and node['links'] == 1 and node['uid'] == os.getuid()
    assert node['bytes'].encode('latin1') == raw and type(node['size_bytes']) is int and node['size_bytes'] == len(raw)
    assert node['sha256'] == hashlib.sha256(raw).hexdigest()


def file_identity(node: dict) -> dict:
    return {key:node[key] for key in ('device','inode','mode','links','uid','size_bytes')}


def check_row(row: dict, spec: dict, phase: str, mutant: bool = False) -> None:
    assert row['operation'] == spec['operation'] and row['fault'] == spec['name'] and row['allocation_absent'] == 1
    allocation = row['allocation']; native(allocation)
    before,after = row['before'],row['after']
    assert set(before) == {'','source'}
    root = before['']
    assert set(root) == {'kind','device','inode','mode','uid'}
    assert root == dict(kind='directory',mode=0o700,uid=os.getuid(),device=allocation['device'],inode=allocation['inode'])
    regular(before['source'],SOURCE)
    assert before['source'] == after['source'] and root == after['']
    success = spec['diagnostic'] == ''
    if success:
        assert row['returned'] == 1 and row['error'] == ''
    else:
        assert row['returned'] == 0 and spec['diagnostic'] in row['error'] and 'result' not in row
    if spec['operation'] == 'source':
        assert before == after
        expected_roles = ['reader']
        if success:
            assert row['result'] == dict(bytes=SOURCE.decode('latin1'),path=allocation['path']+'/source',**file_identity(before['source']))
    else:
        assert set(after) == {'','source','payload'}
        raw = {'empty':b'','prefix':PAYLOAD[:8],'complete':PAYLOAD}[spec['writer_state']]
        regular(after['payload'],raw)
        expected_roles = ['writer','reader'] if spec['writer_state'] == 'complete' else ['writer']
        if success: assert row['result'] == file_identity(after['payload'])
    handles = row['handles']
    assert [entry['role'] for entry in handles] == expected_roles
    assert len({entry['descriptor'] for entry in handles}) == len(handles)
    expected_open = 1 if phase == 'baseline' or mutant or (success and spec['operation'] == 'source') else 0
    if not mutant: assert row['expected_open_handles'] == expected_open
    assert sum(entry['closed_before_recovery'] == 0 for entry in handles) == expected_open
    for entry in handles:
        assert type(entry['descriptor']) is int and entry['descriptor'] >= 0
        selected = 'source' if spec['operation'] == 'source' else 'payload'
        assert entry['path'] == allocation['path']+'/'+selected
        identity = entry['identity']; native(identity)
        expected_identity = file_identity(after[selected])
        if entry['role'] == 'writer': expected_identity['size_bytes'] = 0
        assert identity == expected_identity
        assert entry['closed_after_recovery'] == 1
        if entry['closed_before_recovery'] == 0:
            assert entry['current_identity'] == file_identity(after[selected])
            assert entry['recovery_close_ok'] == 1
            if success: assert entry['open_cloexec'] == 1
        else:
            assert entry['recovery_close_ok'] is None
            assert 'current_identity' not in entry and 'open_cloexec' not in entry


def validate(result: dict, plan: dict, phase: str) -> None:
    assert result['schema'] == 'fsmgen.inactive_descriptor_handoff_qualification.v1'
    assert result['phase'] == phase and result['completed'] is True
    assert result['success'] is (phase == 'qualification')
    assert type(result['forbidden_process_attempts']) is int and result['forbidden_process_attempts'] == 0
    selected = {row['name']:row for row in plan['cases']}
    names = [row['name'] for row in plan['baseline']] if phase == 'baseline' else list(selected)
    assert [row['name'] for row in result['cases']] == names
    assert [row['name'] for row in result['mutants']] == ([] if phase == 'baseline' else plan['mutants'])
    allocations = result['allocated']
    assert allocations == [json.loads(line) for line in (LOG/(phase+'-admission.jsonl')).read_text().splitlines()]
    assert len(allocations) == len(names)+len(result['mutants'])
    assert len({row['path'] for row in allocations}) == len(allocations)
    for row in allocations:
        assert set(row) == {'path','device','inode'}; native(row)
        assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+',row['path'])
        assert not (ROOT/row['path']).exists() and not (ROOT/row['path']).is_symlink()
    assert [row['allocation'] for row in [*result['cases'],*result['mutants']]] == allocations
    for row in result['cases']: check_row(row,selected[row['name']],phase)
    for row in result['mutants']:
        spec = selected['source_mode' if row['name'] == 'omit source failure close' else 'writer_byte_mode']
        check_row(row,spec,phase,True)


def tap_count(raw: str) -> int:
    assert not re.search(r'^(?:not ok|Bail out!)',raw,re.M)
    plans = re.findall(r'^1\.\.(\d+)$',raw,re.M); assert len(plans) == 1
    count = int(plans[0]); assert re.findall(r'^ok (\d+) - ',raw,re.M) == [str(n) for n in range(1,count+1)]
    return count


def closure(result: dict, plan: dict) -> dict:
    baseline = json.loads((LOG/'baseline.json').read_bytes())
    validate(baseline,plan,'baseline')
    assert tap_count((LOG/'baseline.tap').read_text()) == 5
    for name,digest in [('ImageCustody.pm.baseline-source','7f9db38e47140fedd39a80d7a6fbf1ee111f56f290a463729b516b08aae90d4f'),
                        ('Publication.pm.baseline-source','dc50ca598632572616d7da65fa6f1b417a20e7207dafa5fe03fd5d887382fab6')]:
        assert hashlib.sha256((LOG/name).read_bytes()).hexdigest() == digest
    modules = {}
    for name,directory in [('custody','native-proxy-image-custody-20260910'),
                           ('publication','native-proxy-image-publication-20260910'),
                           ('observation','native-proxy-observation-reuse-20260910')]:
        spec = importlib.util.spec_from_file_location('handoff_'+name,BASE.parent/directory/'audit.py')
        module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        module.LOG = LOG/(name+'-regression'); modules[name] = module
    expected = modules['custody'].vectors(VECTOR)
    paths = [row['path'] for data in (baseline,result) for row in data['allocated']]
    reports = {}
    for name,module in modules.items():
        value = json.loads((module.LOG/'qualification.json').read_bytes())
        if name == 'custody': module.qualification(value,expected)
        elif name == 'publication': module.validate(value,VECTOR,expected)
        else: module.validate(value,json.loads((module.BASE/'plan.json').read_bytes()))
        count = tap_count((module.LOG/'qualify.tap').read_text())
        assert count == dict(custody=81,publication=78,observation=81)[name]
        retired = value['retired_cases'] if name != 'observation' else [row['path'] for row in value['allocated']]
        paths.extend(retired); reports[name] = dict(assertions=count,retired_paths=len(retired))
    assert len(paths) == len(set(paths))
    assert all(not (ROOT/path).exists() and not (ROOT/path).is_symlink() for path in paths)
    return dict(baseline_assertions=5,baseline_qualified=False,baseline_source_pins_verified=True,
        regressions=reports,all_rosters_disjoint_and_absent=True)


def main() -> None:
    assert len(sys.argv) == 2 and sys.argv[1] in ('--baseline','--qualification')
    phase = sys.argv[1][2:]
    assert hashlib.sha256((BASE/'plan.json').read_bytes()).hexdigest() == PLAN_SHA
    plan = json.loads((BASE/'plan.json').read_bytes())
    result = json.loads((LOG/(phase+'.json')).read_bytes())
    validate(result,plan,phase)
    count = tap_count((LOG/(phase+'.tap')).read_text())
    assert count == 2*(len(result['cases'])+len(result['mutants']))+1
    falsifiers = []
    changes = [
        ('phase success relabeled',lambda x:x.update(success=phase=='baseline')),
        ('lost allocation',lambda x:x['allocated'].pop()),
        ('lost disposition',lambda x:x['cases'][0]['handles'].clear()),
        ('lost recovery',lambda x:x['cases'][0]['handles'][0].update(closed_after_recovery=0)),
        ('source bytes changed',lambda x:x['cases'][0]['after']['source'].update(bytes='changed')),
        ('forbidden process',lambda x:x.update(forbidden_process_attempts=1)),
    ]
    if phase == 'qualification':
        changes.extend([
            ('failed source still open',lambda x:x['cases'][1]['handles'][0].update(closed_before_recovery=0)),
            ('writer prefix concealed',lambda x:x['cases'][11]['after']['payload'].update(bytes=PAYLOAD.decode('latin1'))),
            ('lost close mutant',lambda x:x['mutants'].pop()),
        ])
    for name,mutate in changes:
        changed = copy.deepcopy(result); mutate(changed)
        try: validate(changed,plan,phase)
        except AssertionError: falsifiers.append(name)
        else: raise AssertionError('handoff oracle missed falsifier: '+name)
    report = dict(schema='fsmgen.inactive_descriptor_handoff_audit.v1',phase=phase,
        qualified=phase=='qualification',expected_baseline_gaps_confirmed=phase=='baseline',
        assertions=count,allocations=len(result['allocated']),falsifiers=falsifiers,limits=plan['limits'])
    if phase == 'qualification': report['closure'] = closure(result,plan)
    (LOG/(phase+'-audit.json')).write_text(json.dumps(report,sort_keys=True,indent=2)+'\n')
    print(json.dumps(report,sort_keys=True))


if __name__ == '__main__': main()
