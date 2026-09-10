"""Independent, process-free reconstruction of the inactive custody result.

Run from the repository root after qualify.t. Its local cases have already
retired; the retained inode records are dated observations, not replay inputs.
"""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import re
import struct

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-image-custody-20260910'


def canonical(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, ensure_ascii=True,
                      separators=(',', ':')).encode('ascii')


def digest(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def vectors(value: dict) -> tuple[bytes, bytes, bytes]:
    c = bytes.fromhex(value['generated_c_hex'])
    image = bytes.fromhex(value['image_hex'])
    key = digest(b'fsmgen.rust_proxy_image.v1\0' + struct.pack('>Q', len(c)) + c
                 + struct.pack('>Q', len(image)) + image)
    assert value['key'] == key
    manifest = canonical(dict(schema='fsmgen.test.rust_proxy_image.v1', key=key,
        generated_c=dict(size_bytes=len(c), sha256=digest(c)),
        executable=dict(size_bytes=len(image), sha256=digest(image))))
    assert value['manifest'].encode('ascii') == manifest
    assert value['runtime_reference_key'] == digest(
        b'fsmgen.rust_proxy_reference.runtime.v1\0' + value['workspace'].encode('utf-8'))
    assert value['observation_reference_key'] == digest(
        b'fsmgen.rust_proxy_reference.observation.v1\0'
        + canonical([value['evidence_directory'], value['observer_birth'], value['target_birth']]))
    return c, image, manifest


def qualification(value: dict, expected: tuple[bytes, bytes, bytes]) -> None:
    assert value['success'] is True
    assert type(value['forbidden_process_attempts']) is int and value['forbidden_process_attempts'] == 0
    assert value['byte_guard_mutant_defeated'] == 1
    assert value['controls'] and all(
        row['rejected'] == 1 and row['expected_diagnostic'] == 1 for row in value['controls'])
    required = {'same-byte source inode replacement', 'same-byte directory inode replacement',
                'changed image bytes', 'changed C bytes', 'hard-linked image', 'symlink ancestry',
                'FIFO image', 'production root excluded', 'wrong native birth integer type'}
    assert required <= {row['name'] for row in value['controls']}
    cases = value['retired_cases']
    assert cases and len(cases) == len(set(cases))
    for case in cases:
        assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+', case)
        path = ROOT / case
        assert not path.exists() and not path.is_symlink()
    assert len(value['positive_snapshot']) == len(expected)
    for record, data, name in zip(value['positive_snapshot'], expected,
                                  ('rustup.c', 'rustup', 'image.json')):
        assert record['path'].startswith(cases[0] + '/images/')
        assert record['path'].endswith('/' + name)
        assert record['size_bytes'] == len(data) and record['sha256'] == digest(data)
        assert type(record['device']) is int and record['device'] == ROOT.stat().st_dev
        assert type(record['inode']) is int and record['inode'] > 0


def must_reject(label: str, callback) -> str:
    try:
        callback()
    except AssertionError:
        return label
    raise AssertionError(f'counterfactual unexpectedly accepted: {label}')


def main() -> None:
    contract = ROOT / 'docs/audits/native-proxy-canonical-contract-20260910/contract.json'
    assert digest(contract.read_bytes()) == 'f3f981398afae72540ab4ac0194b8380d4743c3d2146c1172a85365add053222'
    vector = json.loads((BASE / 'vectors.json').read_bytes())
    result = json.loads((LOG / 'qualification.json').read_bytes())
    expected = vectors(vector)
    qualification(result, expected)
    tap = (LOG / 'qualify.log').read_text()
    assert not re.search(r'^(?:not ok|Bail out!)', tap, re.M)
    plans = re.findall(r'^1\.\.([0-9]+)$', tap, re.M)
    assert len(plans) == 1
    plan = int(plans[0])
    assert [int(n) for n in re.findall(r'^ok ([0-9]+) - ', tap, re.M)] == list(range(1, plan + 1))
    falsifiers = []
    for field in ('key', 'runtime_reference_key', 'observation_reference_key'):
        changed = copy.deepcopy(vector)
        changed[field] = '0' * 64
        falsifiers.append(must_reject(field, lambda: vectors(changed)))
    for field, replacement in (('success', False), ('forbidden_process_attempts', 1),
                                ('controls', []), ('positive_snapshot', [])):
        changed = copy.deepcopy(result)
        changed[field] = replacement
        falsifiers.append(must_reject(field, lambda: qualification(changed, expected)))
    inputs = [BASE / name for name in ('ImageCustody.pm', 'qualify.t', 'vectors.json')]
    inputs += [LOG / 'qualification.json', LOG / 'qualify.log',
               ROOT / 't/lib/FSM/Test/RustProxyFixture.pm',
               ROOT / 'perl/FSM/Support/ProcessSupervisor.pm',
               ROOT / 'docs/audits/native-proxy-canonical-contract-20260910/contract.json']
    report = dict(schema='fsmgen.inactive_image_custody_audit.v1', success=True,
        tap_assertions=plan, rejected_controls=len(result['controls']),
        independently_absent_cases=len(result['retired_cases']), falsifiers=falsifiers,
        inputs=[dict(path=str(path.relative_to(ROOT)), size_bytes=path.stat().st_size,
                     sha256=digest(path.read_bytes())) for path in inputs],
        limits=['No publication, file-lock contention, references or maintenance implemented.',
                'No compiler, native fixture, original, collector or helper executed by the controls.',
                'Inode records describe retired inert cases; replay obtains new identities.',
                'The reused reader has second-resolution Perl stat checks; snapshots do not '
                'prove ongoing disk immutability against arbitrary noncooperating mutation.',
                'Product activation and historical startup repair remain unqualified.'])
    (LOG / 'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps({key: report[key] for key in ('success', 'tap_assertions', 'rejected_controls',
                                                   'independently_absent_cases', 'falsifiers')}, sort_keys=True))


if __name__ == '__main__':
    main()
