"""Prospectively select identity replacements after archive source admission."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'cb070ba4b28151f6089aae2555846f6a154296e5'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.4.2.2'
CLOSE = BASE.parent / 'native-proxy-observation-archive-close-reports-20260911'


def build():
    prior = json.loads((CLOSE / 'plan.json').read_bytes())
    paths = {row['path'] for row in prior['inputs']}
    paths.update(str((CLOSE / name).relative_to(ROOT)) for name in ('plan.json', 'audit.py'))
    inputs = []
    for path in sorted(paths):
        raw = (ROOT / path).read_bytes()
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
        inputs.append(dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    profiles = [dict(name='ordinary', wrapper='ordinary', files=4),
                dict(name='equal_reference', wrapper='equal_reference', files=3)]
    original = json.loads((BASE.parent / 'native-proxy-observation-archive-boundaries-20260911/plan.json').read_bytes())
    cases = []
    for profile in profiles:
        def add(kind, index=None):
            selector = None if kind == 'healthy' else f'recheck:source:{index}:0:0:before' if kind == 'file' else f"directory_closure:{profile['files'] + 1}:before"
            if selector:
                assert any(row['event'] == selector and row['call_fault_eligible'] for row in original['flows'][profile['name'] + ':existing']['events'])
            cases.append(dict(name=profile['name'] + ':' + kind + (f':{index}' if index is not None else ''),
                              profile=profile['name'], kind=kind, index=index, selector=selector))
        add('healthy')
        add('file', 0)
        add('file', profile['files'] - 1)
        add('directory')
    return dict(schema='fsmgen.inactive_archive_replacements_plan.v1',
        source_revision=REVISION, owner=OWNER, profiles=profiles, cases=cases, inputs=inputs,
        contract='Every existing-route case has an observed healthy preparation after actual inert retirement. At the selected owned recheck or final directory closure, retain the original file or whole archive at a separate owned evidence name and create identical replacement bytes under the canonical name. Observe actual open and named native identities before and after mutation. Preserve original handles through the unchanged tracer cleanup verdict.',
        limits='Finite synchronous replacement after source admission only. This does not qualify asynchronous races, lower-reader failed-handoff custody, native execution or exact observation release. Bytes remain identical, so the independent oracle must distinguish original and replacement native identities rather than accepting content equality alone.')



if __name__ == '__main__':
    plan = build()
    (BASE / 'plan.json').write_text(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), unchanged_inputs=len(plan['inputs'])), sort_keys=True))
