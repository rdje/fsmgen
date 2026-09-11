"""Prospectively select genuine omitted archive closes and safe primary cuts."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '2ad652d308348e8ce82bb8e4e11a968c731a8ebe'
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-boundaries-20260911'


def build():
    original = json.loads((BOUNDARY / 'plan.json').read_bytes())
    paths = {pin['path'] for pin in original['inputs']}
    paths.update(str((BOUNDARY / name).relative_to(ROOT)) for name in
        ('plan.json', 'ArchiveTrace.pm', 'ArchiveFixture.pm', 'extraction.json',
         'audit.py', 'result/qualification.json', 'result/recovery-copies.json'))
    paths.update('docs/audits/' + component + '/audit.py' for component in
        ('native-proxy-observation-archive-fresh-calls-20260911',
         'native-proxy-observation-archive-partial-writes-20260911',
         'native-proxy-observation-archive-close-reports-20260911'))
    inputs = []
    for path in sorted(paths):
        raw = (ROOT / path).read_bytes()
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
        inputs.append(dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    profiles = [dict(name='ordinary', wrapper='ordinary', files=4),
                dict(name='equal_reference', wrapper='equal_reference', files=3)]
    cases = []
    for profile in profiles:
        for route in ('fresh', 'existing'):
            flow_name = profile['name'] + ':' + route
            flow = original['flows'][flow_name]
            closed = [row['event'][6:-6] for row in flow['events']
                      if row['event'].startswith('close:') and row['event'].endswith(':after')]
            retained = [f'source:{index}:{1 if route == "fresh" else 0}' for index in range(profile['files'])]
            def add(kind, suffix, omissions, primary=None):
                assert len(set(omissions)) == len(omissions) and set(omissions) <= set(closed)
                if primary:
                    assert any(row['event'] == primary and row['call_fault_eligible'] for row in flow['events'])
                cases.append(dict(name=flow_name + ':' + kind + (':' + suffix if suffix else ''),
                    profile=profile['name'], route=route, kind=kind, omissions=omissions[::-1], primary=primary))
            add('healthy', '', [])
            for label in closed:
                add('single', label, [label])
            add('all-group', '', closed)
            add('primary-retained', '', retained, 'receipt:before')
            if route == 'fresh':
                for index in range(profile['files']):
                    add('primary-payload', str(index), ['directory_handle:0', f'source:{index}:0', f'writer:{index}'] + retained[:index],
                        f'recheck:source:{index}:0:0:before')
            for index in range(profile['files']):
                label = f'source:{index}:{2 if route == "fresh" else 1}'
                add('primary-reread', str(index), ['directory_handle:0', label] + retained, f'recheck:{label}:0:before')
            add('primary-directory', '', ['directory_handle:0'], 'names:0:after')
    assert len({case['name'] for case in cases}) == len(cases)
    return dict(schema='fsmgen.inactive_archive_omitted_closes_plan.v1', source_revision=REVISION,
        owner='HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.3.2',
        inputs=inputs, profiles=profiles, cases=cases,
        contract='Omit the actual selected close and report success to the inert prototype. Retain actual handle aliases beyond the unchanged tracer return; observe every selected descriptor still open and native-bound before any recovery close. Require the unchanged closure oracle to reject. Explicitly close those same held handles, observe closure and preserve the pre-recovery verdict. Continue recovery for all owned aliases even after an observer error. Existing-route preparation remains fully observed and unmodified.',
        limits='Finite inert counterimplementations only. Actual omitted closes and subsequent observer recovery qualify detection, not correct prototype cleanup, operating-system close ambiguity or crash recovery. No compiler/native execution, original fixture matrix rerun or observation-hold release.')


if __name__ == '__main__':
    plan = build()
    (BASE / 'plan.json').write_text(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), unchanged_inputs=len(plan['inputs'])), sort_keys=True))
