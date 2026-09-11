"""Pin healthy source/profile selection and derive occurrence-count equations."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '49c15609fb5b4645c51d63babe1370b4aceeb44c'
RELEASE = 'docs/audits/native-proxy-observation-archive-release-20260911'
CONTRACT = 'docs/audits/native-proxy-release-interruption-contract-20260911'


def counts(files, references, after_images):
    images = 10 + 2 * after_images
    reference_rows = 3 * references - 1
    groups = {
        'NativeProxyObservationRelease': dict(_prepare=1, _archive_closure=4, _coordinator_request=1,
            _current_image=1, _retain_live_sources=2, _admit_locked=1, _unlink_exact=1, _assert_absent=2, _release_locked=1, _finish_locked=1),
        'NativeProxyImageCoordination': dict(_names=22, _structure=2, _census=3, _lock_identity=3),
        'NativeProxyImageCustody': dict(_directory=35 + 8 * images, _members=2 * images,
            _recheck_source=18 * files + 12 + 4 * reference_rows + 5 * images,
            read_entry=images, _source=5 * files + 6 + 3 * reference_rows + 5 * images),
        'NativeProxyObservationArchive': dict(_limits=1, _members=9, _directory_closure=8, _source_closure=4, _receipt=4),
        'NativeProxyReferenceCensus': dict(_image=images, _inspect_locked=3, _closure=3,
            _matches_image=reference_rows, _decode_record=reference_rows, _filename_key=reference_rows),
        'NativeProxyPrivateWorkspace': dict(_absent=2),
    }
    return {package + '::' + symbol: value for package, values in groups.items() for symbol, value in values.items()}


def build():
    contract = json.loads((ROOT / CONTRACT / 'contract.json').read_bytes())
    prior = json.loads((ROOT / RELEASE / 'plan.json').read_bytes())
    saved = json.loads((ROOT / RELEASE / 'result/qualification.json').read_bytes())
    profiles = []
    for ident, name, files, references, after_images in [
        (contract['profiles'][0], 'healthy:ordinary', 4, 3, 2),
        (contract['profiles'][1], 'healthy:equal_reference', 3, 3, 2),
        (contract['profiles'][2], 'healthy:runtime-still-active', 4, 4, 2),
        (contract['profiles'][3], 'healthy:last-observation', 4, 2, 1),
    ]:
        selection = next(row for row in prior['cases'] if row['name'] == name)
        original = next(row for row in saved['cases'] if row['name'] == name)
        expected = counts(files, references, after_images)
        assert expected['NativeProxyImageCustody::_source'] == len(original['operation']['source_requests'])
        assert 22 + 2 * (10 + 2 * after_images) == sum(h['kind'] == 'directory' for h in original['operation']['handles'])
        profiles.append(dict(id=ident, selection=selection, archive_files=files, before_references=references,
                             after_referenced_images=after_images, expected_calls=expected,
                             original_case=name, original_sources=len(original['operation']['source_requests'])))
    paths = {pin['path'] for pin in contract['inputs']}
    paths.update(CONTRACT + '/' + name for name in ['contract.json', 'prepare.py', 'model.py', 'qualify.py', 'audit.py',
        'preflight-pins.json', 'corrected-auditor-pin.json', 'result/qualification.json', 'result/audit.json'])
    inputs = []
    for path in sorted(paths):
        raw = (ROOT / path).read_bytes(); assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
        inputs.append(dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    return dict(schema='fsmgen.inactive_release_boundary_plan.v1', source_revision=REVISION,
                owner=contract['owner'].rsplit('.', 1)[0] + '.2', component=BASE.name, inputs=inputs, profiles=profiles,
                source_boundaries=contract['source_boundaries'],
                sealed_continuations={
                    'NativeProxyObservationRelease::_coordinator_request': ['NativeProxyImageCustody::_directory'],
                    'NativeProxyReferenceCensus::_inspect_locked': ['NativeProxyObservationRelease::_admit_locked', 'NativeProxyObservationRelease::_release_locked', 'NativeProxyObservationRelease::_finish_locked'],
                    'NativeProxyObservationRelease::_admit_locked': ['NativeProxyImageCoordination::_census'],
                    'NativeProxyObservationRelease::_release_locked': ['NativeProxyImageCoordination::_census'],
                    'NativeProxyObservationRelease::_finish_locked': ['NativeProxyImageCoordination::_structure'],
                    'NativeProxyObservationRelease::_unlink_exact': ['NativeProxyObservationRelease::_assert_absent']},
                continuation_contract='Caller-sealed wrappers use tail goto. Their completed frames are observed only at the next selected caller continuation, with original source bridges checked independently. Each completion event aliases that following before-call boundary for future fault selection; it is not a second physical fault point. A source-return event is ownership observation only and is not fault eligible.',
                scope='Only the declared healthy profile/symbol basis and direct caller-admission controls. Counts derive from complete reference/image/archive loops and original saved physical traces; exact ordered actual occurrences become the committed fault-domain input after independent verification. New fixed helper wrappers preserve original caller admission and scalar/list/void call context. No original qualifier or native/compiler/helper/collector, interruption matrix, close omission or arbitrary-writer claim.')


if __name__ == '__main__':
    plan = build()
    with (BASE / 'plan.json').open('x') as stream: stream.write(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(profiles=len(plan['profiles']), inputs=len(plan['inputs']), selected_symbols=len(plan['profiles'][0]['expected_calls']),
                         planned_calls=[sum(p['expected_calls'].values()) for p in plan['profiles']]), sort_keys=True))
