"""Independently join consumer outcomes to the retained healthy call forest."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PREVIOUS = BASE.with_name('native-proxy-release-readback-selection-20260911')
REVISION = '5cb6a683c65b2bdb992b8447e14f23205f492722'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.3.10.2.1'


def load(path):
    return json.loads(path.read_bytes())


def same(actual, expected):
    assert json.dumps(actual, sort_keys=True) == json.dumps(expected, sort_keys=True)


def pin(path):
    raw = path.read_bytes()
    assert path.stat().st_dev == ROOT.stat().st_dev
    for ancestor in [path, *path.parents]:
        if ancestor == ROOT:
            break
        assert not ancestor.is_symlink()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw),
                sha256=hashlib.sha256(raw).hexdigest())


def authenticate(result, previous):
    expected = {p['path'] for p in previous['inputs']}
    expected.update(str(p.relative_to(ROOT)) for p in PREVIOUS.rglob('*') if p.is_file())
    assert [p['path'] for p in result['inputs']] == sorted(expected)
    pins = load(BASE / 'preflight-pins.json')
    assert [p['path'] for p in pins] == [str((BASE / n).relative_to(ROOT))
        for n in ('source-review.json', 'prepare.py', 'audit.py', 'applicability.json')]
    for record in pins + result['inputs']:
        path = ROOT / record['path']
        same(record, pin(path))
        if record in result['inputs']:
            assert path.read_bytes() == subprocess.check_output(['git', 'show', REVISION + ':' + record['path']], cwd=ROOT)
    source_review = load(BASE / 'source-review.json')
    for source in source_review['sources']:
        raw = (ROOT / source['path']).read_bytes()
        assert hashlib.sha256(raw).hexdigest() == source['file_sha256']
        body = source['body'].encode()
        assert raw.count(body) == 1 and hashlib.sha256(body).hexdigest() == source['body_sha256']
    census = source_review['sources'][0]['body']
    assert 'sub _census {' in census and '{bytes}' not in census
    assert 'return {images => $images, references => $references};' in census
    assert 'NativeProxyImageCustody::_recheck_source($source)' in census
    assert 'close($source->{handle})' in census
    assert '{bytes}' not in source_review['sources'][2]['body']
    return pins


def domain(result, previous, healthy):
    assert set(result) == {'schema', 'owner', 'source_revision', 'inputs', 'original_plan',
        'supersedes', 'profiles', 'total_proposed_cases', 'expected_successes', 'expected_rejections',
        'unchanged', 'physical_boundary', 'execution_qualified', 'runtime_authorized'}
    assert result['schema'] == 'fsmgen.release_readback_consumer_applicability.v1'
    assert result['owner'] == OWNER and result['source_revision'] == REVISION
    assert result['original_plan'] == str((PREVIOUS / 'plan.json').relative_to(ROOT))
    same(result['supersedes'], dict(path=str((PREVIOUS / 'contract.md').relative_to(ROOT)),
        clause='Reader and source return; the original consumer must reject altered content',
        replacement='A body-XOR control at the structure-only census returns successfully; content-sensitive consumers retain their expected rejection. Actual execution is still required.'))
    assert result['execution_qualified'] is False and result['runtime_authorized'] is False
    assert result['unchanged'] == 'All source occurrences, four read controls, short-read/healthy controls and syscall-report selections remain exactly as originally pinned.'
    assert result['physical_boundary'] == 'Only one reported read buffer changes. Original named bytes and metadata remain unchanged; accepted structural reads permit the complete healthy release effect.'
    assert len(result['profiles']) == len(previous['profiles']) == len(healthy['cases']) == 4
    accepted_counts = []
    for index, (profile, original, row) in enumerate(zip(result['profiles'], previous['profiles'], healthy['cases'])):
        calls = row['operation']['boundary_calls']
        # Build the structural descendant set from the saved call forest,
        # independently of the original selector's recorded source parent.
        structural = set()
        for call in calls:
            if call['name'] == 'NativeProxyImageCoordination::_census' or call['parent'] in structural:
                structural.add(call['id'])
        sources = [c for c in calls if c['name'] == 'NativeProxyImageCustody::_source']
        assert len(sources) == len(original['sources'])
        expected_bodies = []
        for call, source in zip(sources, original['sources']):
            assert source['baseline']['call_id'] == call['id']
            assert source['baseline']['parent'] == calls[call['parent']]['name']
            success = call['id'] in structural
            expected_bodies.append(dict(symbol=call['name'], occurrence=call['occurrence'],
                expected_success=success,
                effect_basis='healthy_completion' if success else 'before_selected_source',
                consumer='structure_only' if success else 'content_sensitive'))
        successes = sum(b['expected_success'] for b in expected_bodies)
        failures = sum(not b['expected_success'] for b in expected_bodies)
        same(profile, dict(id=row['profile_id'], execution_owner=OWNER[:-1] + '2' if index == 0 else original['owner'],
            body_xor=expected_bodies, expected_body_successes=successes, expected_body_rejections=failures,
            expected_source_case_successes=successes + 2,
            expected_source_case_rejections=3 * len(sources) + failures,
            source_case_count=original['proposed_cases']))
        accepted_counts.append(successes)
    source_total = sum(p['source_case_count'] for p in result['profiles'])
    successes = sum(accepted_counts) + 2 * len(result['profiles']) + len(previous['syscall_healthy_profiles'])
    total = source_total + len(previous['syscall_reports']) + len(previous['syscall_healthy_profiles'])
    same([result['expected_successes'], result['expected_rejections'], result['total_proposed_cases']],
         [successes, total - successes, total])
    return accepted_counts


def falsify(result, previous, healthy):
    changes = [
        ('missing profile', lambda r: r['profiles'].pop()),
        ('duplicate profile', lambda r: r['profiles'].__setitem__(1, copy.deepcopy(r['profiles'][0]))),
        ('missing body case', lambda r: r['profiles'][0]['body_xor'].pop()),
        ('wrong occurrence', lambda r: r['profiles'][0]['body_xor'][0].__setitem__('occurrence', 1)),
        ('wrong execution owner', lambda r: r['profiles'][0].__setitem__('execution_owner', previous['profiles'][0]['owner'])),
        ('invented content acceptance', lambda r: r['profiles'][0]['body_xor'][0].__setitem__('expected_success', True)),
        ('wrong effect basis', lambda r: r['profiles'][0]['body_xor'][0].__setitem__('effect_basis', 'healthy_completion')),
        ('wrong total', lambda r: r.__setitem__('total_proposed_cases', 1)),
        ('invented execution', lambda r: r.__setitem__('execution_qualified', True)),
        ('invented authority', lambda r: r.__setitem__('runtime_authorized', True)),
        ('missing supersession', lambda r: r['supersedes'].clear()),
        ('integer outcome', lambda r: r['profiles'][0]['body_xor'][0].__setitem__('expected_success', 0)),
    ]
    for index, profile in enumerate(result['profiles']):
        occurrence = next(i for i, c in enumerate(profile['body_xor']) if c['expected_success'])
        changes.append(('restored blanket rejection:' + profile['id'],
            lambda r, i=index, n=occurrence: r['profiles'][i]['body_xor'][n].__setitem__('expected_success', False)))
    for name, mutate in changes:
        changed = copy.deepcopy(result)
        mutate(changed)
        try:
            domain(changed, previous, healthy)
        except (AssertionError, KeyError, TypeError, ValueError, IndexError):
            continue
        raise AssertionError('accepted corrupted applicability: ' + name)
    return [name for name, _ in changes]


def main():
    assert not sys.argv[1:], 'read-only audit accepts no execution option'
    result = load(BASE / 'applicability.json')
    previous = load(PREVIOUS / 'plan.json')
    pins = authenticate(result, previous)
    healthy = load(ROOT / previous['healthy_input'])
    counts = domain(result, previous, healthy)
    rejected = falsify(result, previous, healthy)
    roots = [r['path'] for r in healthy['allocated']]
    assert len(roots) == len(set(roots)) == 16
    assert all(not (ROOT / p).exists() and not (ROOT / p).is_symlink() for p in roots)
    print(json.dumps(dict(schema='fsmgen.release_readback_applicability_audit.v1', success=True,
        inputs=len(result['inputs']), prospective_pins=len(pins), structural_body_successes=counts,
        content_body_rejections=sum(len(p['body_xor']) for p in result['profiles']) - sum(counts),
        expected_successes=result['expected_successes'], expected_rejections=result['expected_rejections'],
        proposed_cases=result['total_proposed_cases'], rejected_controls=rejected,
        previous_roots_absent=len(roots), executed_fixtures=0, execution_qualified=False,
        runtime_authorized=False), sort_keys=True))


if __name__ == '__main__':
    main()
