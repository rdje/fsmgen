"""Select ordinary existing helper-call cuts from the committed unique domain."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'ca3cd1940f035ece55144ab86f7f08cd9832bd52'
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-boundaries-20260911'


def build():
    domain = json.loads((BOUNDARY / 'plan.json').read_bytes())
    paths = {r['path'] for r in domain['inputs']}
    paths.update(str((BOUNDARY / name).relative_to(ROOT)) for name in (
        'plan.json', 'ArchiveTrace.pm', 'ArchiveFixture.pm', 'extraction.json',
        'audit.py', 'result/qualification.json', 'result/recovery-copies.json'))
    paths.add('docs/audits/native-proxy-observation-archive-fresh-calls-20260911/audit.py')
    inputs = []
    for path in sorted(paths):
        raw = (ROOT / path).read_bytes()
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
        inputs.append(dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    cases = [dict(name='ordinary:existing:' + e['event'], selector=e['event'])
             for e in domain['flows']['ordinary:existing']['events'] if e['call_fault_eligible']]
    assert len({c['name'] for c in cases}) == len(cases)
    return dict(schema='fsmgen.inactive_archive_existing_calls_plan.v1',
        source_revision=REVISION, inputs=inputs, cases=cases,
        owner='HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.2.2',
        profile=dict(name='ordinary', wrapper='ordinary', files=4), route='existing',
        preparation_events=[e['event'] for e in domain['flows']['ordinary:fresh']['events']],
        injection='One exception immediately after recording the selected eligible event. Every case first observes complete fresh preparation without fault injection. The original tracer and prototype remain byte-identical. No ownership-transfer or cleanup event can throw.',
        limits='Only the selected ordinary existing helper-call cuts are executed. Equal-reference routes, partial syswrite progress, modeled close reports, omitted-close implementations, bounds/layout and final applicability join remain owned siblings. No original target reopen, compiler/native execution, archive release, crash or arbitrary-writer atomicity claim.')


if __name__ == '__main__':
    plan = build()
    (BASE / 'plan.json').write_text(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), unchanged_inputs=len(plan['inputs']))))
