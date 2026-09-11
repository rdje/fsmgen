"""Prepare corrected consumer outcomes without executing an old producer."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PREVIOUS = BASE.with_name('native-proxy-release-readback-selection-20260911')
REVISION = '5cb6a683c65b2bdb992b8447e14f23205f492722'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.3.10.2.1'
STRUCTURAL = 'NativeProxyImageCoordination::_census'


def load(path):
    return json.loads(path.read_bytes())


def pin(path):
    raw = path.read_bytes()
    assert path.stat().st_dev == ROOT.stat().st_dev
    for ancestor in [path, *path.parents]:
        if ancestor == ROOT:
            break
        assert not ancestor.is_symlink()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(raw),
                sha256=hashlib.sha256(raw).hexdigest())


def main():
    assert not (BASE / 'applicability.json').exists(), 'preserve prepared outcomes'
    previous = load(PREVIOUS / 'plan.json')
    paths = {p['path'] for p in previous['inputs']}
    paths.update(str(p.relative_to(ROOT)) for p in PREVIOUS.rglob('*') if p.is_file())
    inputs = []
    for name in sorted(paths):
        path = ROOT / name
        assert path.read_bytes() == subprocess.check_output(['git', 'show', REVISION + ':' + name], cwd=ROOT)
        inputs.append(pin(path))
    profiles = []
    for index, profile in enumerate(previous['profiles']):
        bodies = []
        for source in profile['sources']:
            accepts = source['baseline']['parent'] == STRUCTURAL
            bodies.append(dict(symbol=source['symbol'], occurrence=source['occurrence'],
                expected_success=accepts,
                effect_basis='healthy_completion' if accepts else 'before_selected_source',
                consumer='structure_only' if accepts else 'content_sensitive'))
        accepted = sum(b['expected_success'] for b in bodies)
        profiles.append(dict(id=profile['id'], execution_owner=OWNER[:-1] + '2' if index == 0 else profile['owner'],
            body_xor=bodies, expected_body_successes=accepted,
            expected_body_rejections=len(bodies) - accepted,
            expected_source_case_successes=accepted + 2,
            expected_source_case_rejections=len(bodies) * 4 - accepted,
            source_case_count=profile['proposed_cases']))
    result = dict(schema='fsmgen.release_readback_consumer_applicability.v1', owner=OWNER,
        source_revision=REVISION, inputs=inputs, original_plan=str((PREVIOUS / 'plan.json').relative_to(ROOT)),
        supersedes=dict(path=str((PREVIOUS / 'contract.md').relative_to(ROOT)),
            clause='Reader and source return; the original consumer must reject altered content',
            replacement='A body-XOR control at the structure-only census returns successfully; content-sensitive consumers retain their expected rejection. Actual execution is still required.'),
        profiles=profiles, total_proposed_cases=sum(p['source_case_count'] for p in profiles) + 24,
        expected_successes=sum(p['expected_source_case_successes'] for p in profiles) + 4,
        expected_rejections=sum(p['expected_source_case_rejections'] for p in profiles) + 20,
        unchanged='All source occurrences, four read controls, short-read/healthy controls and syscall-report selections remain exactly as originally pinned.',
        physical_boundary='Only one reported read buffer changes. Original named bytes and metadata remain unchanged; accepted structural reads permit the complete healthy release effect.',
        execution_qualified=False, runtime_authorized=False)
    with (BASE / 'applicability.json').open('x') as output:
        output.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, inputs=len(inputs),
        body_successes=[p['expected_body_successes'] for p in profiles],
        proposed_cases=result['total_proposed_cases'], expected_successes=result['expected_successes'],
        expected_rejections=result['expected_rejections'], executed_fixtures=0), sort_keys=True))


if __name__ == '__main__':
    main()
