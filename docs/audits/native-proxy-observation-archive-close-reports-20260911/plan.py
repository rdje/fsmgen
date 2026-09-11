"""Select actual-close/report-error and primary-error archive cases prospectively."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '7e1f2daa01c9ef5760954089c36ec6c778c25f17'
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-boundaries-20260911'


def build():
    original = json.loads((BOUNDARY / 'plan.json').read_bytes())
    paths = {pin['path'] for pin in original['inputs']}
    paths.update(str((BOUNDARY / name).relative_to(ROOT)) for name in
        ('plan.json', 'ArchiveTrace.pm', 'ArchiveFixture.pm', 'extraction.json',
         'audit.py', 'result/qualification.json', 'result/recovery-copies.json'))
    paths.update('docs/audits/' + component + '/audit.py' for component in
        ('native-proxy-observation-archive-fresh-calls-20260911',
         'native-proxy-observation-archive-partial-writes-20260911'))
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
            closed = [row['event'][len('close:'):-len(':after')]
                      for row in flow['events'] if row['event'].startswith('close:') and row['event'].endswith(':after')]
            retained_ordinal = 1 if route == 'fresh' else 0
            retained = [dict(label=f'source:{index}:{retained_ordinal}', errno='ENOSPC' if index % 2 == 0 else 'EIO')
                        for index in range(profile['files'])]
            def add(kind, suffix, reports, primary=None):
                assert len({row['label'] for row in reports}) == len(reports)
                assert all(row['label'] in closed for row in reports)
                if primary:
                    assert any(row['event'] == primary and row['call_fault_eligible'] for row in flow['events'])
                # Reverse declaration order: observed close order owns precedence.
                cases.append(dict(name=flow_name + ':' + kind + (':' + suffix if suffix else ''),
                    profile=profile['name'], route=route, kind=kind, reports=list(reversed(reports)), primary=primary))
            add('healthy', '', [])
            for label in closed:
                add('single', label, [dict(label=label, errno='EIO')])
            if route == 'fresh':
                for index in range(profile['files']):
                    pair = [dict(label=f'source:{index}:0', errno='EIO'), dict(label=f'writer:{index}', errno='ENOSPC')]
                    add('payload-pair', str(index), pair)
                    add('primary-payload', str(index), pair + retained[:index], f'recheck:source:{index}:0:0:before')
            add('retained-group', '', retained)
            add('primary-retained', '', retained, 'receipt:before')
            reread_ordinal = 2 if route == 'fresh' else 1
            for index in range(profile['files']):
                label = f'source:{index}:{reread_ordinal}'
                add('primary-reread', str(index), [dict(label=label, errno='EIO'), *retained], f'recheck:{label}:0:before')
    assert len({case['name'] for case in cases}) == len(cases)
    return dict(schema='fsmgen.inactive_archive_close_reports_plan.v1', source_revision=REVISION,
        owner='HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.3.1',
        inputs=inputs, profiles=profiles, cases=cases,
        contract='Run each actual owned close through the unchanged tracer before applying its selected false/EIO or false/ENOSPC report. Retain actual and reported results separately. Distinct grouped errors are declared in reverse order to challenge first-observed-error precedence. Selected safe primary call exceptions must survive every cleanup report. Existing-route preparations are fully observed with no report injection.',
        limits='Finite inert archive close-report qualification only. Every modeled error follows an actual close; this does not model operating-system close ambiguity or prove omitted-close detection. Genuine omission/recovery and the close-domain join remain separate children, followed by final archive applicability and native release. No compiler/native or original fixture matrix rerun.')


if __name__ == '__main__':
    plan = build()
    (BASE / 'plan.json').write_text(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), unchanged_inputs=len(plan['inputs'])), sort_keys=True))
