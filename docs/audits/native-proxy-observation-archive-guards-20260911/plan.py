"""Declare bounded pure guard cases without fabricating a public archive input."""
import hashlib
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '94e66c8c68017e49ea7bf59017fe67d4a53e5c2c'
ORIGINAL = 'docs/audits/native-proxy-observation-archive-20260911'


def build():
    previous = json.loads((ROOT / ORIGINAL / 'plan.json').read_bytes())
    paths = {pin['path'] for pin in previous['inputs']} | {ORIGINAL + '/plan.json', ORIGINAL + '/ObservationArchive.pm'}
    inputs = []
    for path in sorted(paths):
        raw = (ROOT / path).read_bytes()
        assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + path], cwd=ROOT)
        inputs.append(dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    def raw(size, pattern='x'): return dict(kind='raw', size=size, pattern=pattern)
    cases = []
    def add(name, values, error=''):
        cases.append(dict(name=name, values=values, returned=not bool(error), error=error))
    count_error = 'archive unique-file capacity exceeded\n'; byte_error = 'expected bounded bytes\n'
    add('empty structural list', [])
    add('one empty payload', [raw(0)])
    add('one binary payload', [raw(256, 'binary')])
    for count in [63, 64, 65]:
        add(f'count {count} empty payloads', [raw(0) for _ in range(count)], count_error if count > 64 else '')
    add('aggregate one below ceiling', [raw(65536) for _ in range(63)] + [raw(65535)])
    add('aggregate exact ceiling', [raw(65536) for _ in range(64)])
    add('aggregate excess via count', [raw(65536) for _ in range(65)], count_error)
    add('aggregate excess via payload', [raw(65536) for _ in range(63)] + [raw(65537)], byte_error)
    add('count precedes invalid byte form', [dict(kind='undefined') for _ in range(65)], count_error)
    for kind in ['undefined', 'reference', 'utf8', 'oversized']:
        for index in [0, 31, 63]:
            values = [raw(0) for _ in range(64)]
            values[index] = raw(65537) if kind == 'oversized' else dict(kind=kind)
            add(f'{kind} payload at {index}', values, byte_error)
    assert len({case['name'] for case in cases}) == len(cases)
    return dict(schema='fsmgen.inactive_archive_guards_plan.v1', source_revision=REVISION,
        owner='HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.4.1',
        inputs=inputs, cases=cases, limits=dict(files=64, file_bytes=65536, aggregate_bytes=4194304),
        domain='Call the unchanged private _limits helper with ordinary finite raw Perl values. The structural empty list and enlarged file lists are not public archive specifications. Preserve value types/UTF8 flags and record every actual byte-validator call and exact first error. No archive/target filesystem helper or process may execute.',
        reachability='For ordinary finite byte values, the earlier count and per-file guards imply the aggregate cap. An excess therefore fails an earlier guard. The public archive specification is smaller: five ordered source roles include an equal private/global reference pair, with reference bytes bounded separately. Prove these implications from pinned sources without weakening guards or claiming an aggregate-excess branch hit.',
        nonclaims='No filesystem archive, namespace/replacement, ownership/release, native execution, operating-system failure or asynchronous crash qualification. Structural helper admission is not public archive admission.')


if __name__ == '__main__':
    plan = build()
    (BASE / 'plan.json').write_text(json.dumps(plan, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(cases=len(plan['cases']), inputs=len(plan['inputs'])), sort_keys=True))
