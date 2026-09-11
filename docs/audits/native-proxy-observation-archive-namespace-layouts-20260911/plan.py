"""Prospectively select actual archive namespace and pre-open symlink cases."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '68ac6ef03c1bce45cb422d4e1739dd4866b8a6b7'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.4.2.1'
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
    cases = []
    for profile in profiles:
        def add(kind, value=None, index=None):
            suffix = kind + (':' + str(value) if value is not None else '')
            suffix += ':' + str(index) if index is not None else ''
            cases.append(dict(name=profile['name'] + ':' + suffix, profile=profile['name'],
                              kind=kind, value=value, index=index))
        add('healthy')
        for count in (63, 64, 65):
            add('namespace', count)
        for kind in ('valid-symlink', 'dangling-symlink'):
            for index in (0, profile['files'] - 1):
                add(kind, index=index)
    return dict(schema='fsmgen.inactive_archive_namespace_layouts_plan.v1',
        source_revision=REVISION, owner=OWNER, profiles=profiles, cases=cases, inputs=inputs,
        contract='Every existing-route case has an observed healthy preparation after actual inert retirement. Unknown empty files make the actual namespace reach the selected cardinality. Symlink controls move one exact canonical file to an owned evidence sibling before installing a basename-only valid or dangling link. No original file is deleted or read through an alias. Observe exact original call prefixes and attempted source reads.',
        limits='Finite existing-archive namespace and pre-open source indirection only. The unchanged lower reader rejects symlinks before sysopen. This does not qualify descriptors rejected after low-level opening, post-admission replacement, native execution, asynchronous races or exact observation release. Those retain separate task owners.')


if __name__ == '__main__':
    plan = build()
    (BASE / 'plan.json').write_text(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), unchanged_inputs=len(plan['inputs'])), sort_keys=True))
