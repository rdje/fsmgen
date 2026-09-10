"""Independent, process-free reconstruction of inactive runtime record bytes."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-runtime-records-20260910'
SCHEMA = 'fsmgen.test.rust_proxy_image_reference.v1'
FIELDS = {'schema', 'reference_key', 'image_key', 'workspace', 'workspace_identity', 'selected_sources'}


def canonical(value: object) -> str:
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(',', ':'), allow_nan=False)


def key(workspace: str) -> str:
    return hashlib.sha256(b'fsmgen.rust_proxy_reference.runtime.v1\0' + workspace.encode('utf-8')).hexdigest()


def pairs(rows: list) -> dict:
    result = {}
    for name, value in rows:
        assert name not in result, 'duplicate member'
        result[name] = value
    return result


def validate(case: str, raw: str) -> dict:
    assert type(raw) is str and raw.isascii() and len(raw) <= 4096
    assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+', case)
    value = json.loads(raw, object_pairs_hook=pairs)
    assert type(value) is dict and set(value) == FIELDS
    assert value['schema'] == SCHEMA and canonical(value) == raw
    workspace = value['workspace']
    assert type(workspace) is str and re.fullmatch(r'\.artifacts/tmp/process-supervisor-tests/fsmgen-[A-Za-z0-9_]+', workspace)
    for name in ('image_key', 'reference_key'):
        assert type(value[name]) is str and re.fullmatch('[0-9a-f]{64}', value[name])
    assert value['reference_key'] == key(workspace)
    directory = value['workspace_identity']
    assert type(directory) is dict and set(directory) == {'path', 'device', 'inode'}
    assert directory['path'] == workspace
    assert all(type(directory[name]) is int and directory[name] >= 0 for name in ('device', 'inode'))
    sources = value['selected_sources']
    assert type(sources) is list and len(sources) == 2
    for source, name in zip(sources, ('rustup.c', 'rustup')):
        assert type(source) is dict and set(source) == {'path', 'device', 'inode', 'size_bytes', 'sha256'}
        assert source['path'] == f"{case}/images/{value['image_key']}/{name}"
        assert all(type(source[field]) is int and source[field] >= 0 for field in ('device', 'inode', 'size_bytes'))
        assert source['size_bytes'] <= 65536
        assert type(source['sha256']) is str and re.fullmatch('[0-9a-f]{64}', source['sha256'])
    return value


def build_vectors() -> dict:
    prior = json.loads((BASE.parent / 'native-proxy-image-custody-20260910/vectors.json').read_bytes())
    c, image = bytes.fromhex(prior['generated_c_hex']), bytes.fromhex(prior['image_hex'])
    image_key = hashlib.sha256(b'fsmgen.rust_proxy_image.v1\0' + len(c).to_bytes(8, 'big') + c
                              + len(image).to_bytes(8, 'big') + image).hexdigest()
    assert image_key == prior['key']
    case = '.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-Codec20260910'
    workspace = prior['workspace']
    record = dict(schema=SCHEMA, reference_key=key(workspace), image_key=image_key, workspace=workspace,
                  workspace_identity=dict(path=workspace, device=17, inode=101),
                  selected_sources=[dict(path=f'{case}/images/{image_key}/{name}', device=17,
                                         inode=inode, size_bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
                                    for name, inode, data in [('rustup.c', 102, c), ('rustup', 103, image)]])
    large = copy.deepcopy(record)
    large['selected_sources'][1]['inode'] = 9007199254740993
    boundary = copy.deepcopy(record)
    prefix = '.artifacts/tmp/process-supervisor-tests/fsmgen-'
    boundary['workspace'] = prefix + 'B'
    boundary['workspace_identity']['path'] = boundary['workspace']
    boundary['reference_key'] = key(boundary['workspace'])
    if (4096 - len(canonical(boundary))) % 2:
        boundary['workspace_identity']['inode'] = 1000
    count = (4096 - len(canonical(boundary))) // 2
    boundary['workspace'] += 'B' * count
    boundary['workspace_identity']['path'] = boundary['workspace']
    boundary['reference_key'] = key(boundary['workspace'])
    assert len(canonical(boundary)) == 4096
    vectors = [dict(name=name, record=value, raw=canonical(value)) for name, value in
               [('inert historical identities', record), ('integer above binary64 precision', large),
                ('exact record byte ceiling; syntax only', boundary)]]
    for vector in vectors:
        validate(case, vector['raw'])
    return dict(schema='fsmgen.inactive_runtime_record_vectors.v1', case=case, vectors=vectors,
                limits='Synthetic IDs and paths only; no filesystem object or runtime reference is created.')


def tap_count(raw: str) -> int:
    assert not re.search(r'^(?:not ok|Bail out!)', raw, re.M)
    plans = re.findall(r'^1\.\.([0-9]+)$', raw, re.M)
    assert len(plans) == 1
    total = int(plans[0])
    assert [int(n) for n in re.findall(r'^ok ([0-9]+) - ', raw, re.M)] == list(range(1, total + 1))
    return total


def validate_result(result: dict, vectors: dict) -> None:
    assert result['success'] is True and type(result['forbidden_process_attempts']) is int
    assert result['forbidden_process_attempts'] == 0 and result['filesystem_lookup_attempts'] == 0
    assert result['encoded'] == [entry['raw'] for entry in vectors['vectors']]
    for raw in result['encoded']:
        validate(vectors['case'], raw)
    rows = result['controls']
    assert rows and len(rows) == len({row['name'] for row in rows})
    assert all(row['rejected'] == 1 and row['expected_diagnostic'] == 1 for row in rows)
    assert {'extra root field', 'merged root fields', 'merged source fields padded',
            'duplicate root member', 'duplicate nested member', 'source order',
            'wrong reference key', 'source byte ceiling', 'record encode ceiling',
            'record decode ceiling', 'numeric string inode', 'boolean inode',
            'noncanonical fraction', 'noncanonical exponent', 'extra positional argument'} <= {row['name'] for row in rows}
    assert set(result['mutants']) == {'omitted field closure', 'omitted key derivation'}
    for name, mutant in result['mutants'].items():
        assert mutant['accepted_by_mutant'] == 1
        try:
            validate(vectors['case'], mutant['raw'])
        except AssertionError:
            pass
        else:
            raise AssertionError(f'independent oracle missed mutant: {name}')


def main() -> None:
    vectors = build_vectors()
    if sys.argv[1:] == ['--vectors']:
        (BASE / 'vectors.json').write_text(json.dumps(vectors, sort_keys=True, indent=2) + '\n')
        print('independent runtime vectors written')
        return
    assert not sys.argv[1:]
    assert json.loads((BASE / 'vectors.json').read_bytes()) == vectors
    contract = ROOT / 'docs/audits/native-proxy-canonical-contract-20260910/contract.json'
    assert hashlib.sha256(contract.read_bytes()).hexdigest() == 'f3f981398afae72540ab4ac0194b8380d4743c3d2146c1172a85365add053222'
    result = json.loads((LOG / 'qualification.json').read_bytes())
    validate_result(result, vectors)
    falsifiers = []
    for name, mutate in (
        ('hidden failure', lambda x: x.update(success=False)),
        ('lost type control', lambda x: x.update(controls=[row for row in x['controls'] if row['name'] != 'boolean inode'])),
        ('hidden acceptance', lambda x: x['controls'][0].update(rejected=0)),
        ('missing counterimplementation', lambda x: x.update(mutants={})),
        ('lookup despite pure codec', lambda x: x.update(filesystem_lookup_attempts=1)),
        ('changed encoded bytes', lambda x: x['encoded'].__setitem__(0, x['encoded'][0] + '\n')),
    ):
        altered = copy.deepcopy(result)
        mutate(altered)
        try:
            validate_result(altered, vectors)
        except AssertionError:
            falsifiers.append(name)
        else:
            raise AssertionError(f'counterfactual accepted: {name}')
    inputs = [BASE / name for name in ('RuntimeRecord.pm', 'qualify.t', 'vectors.json')]
    inputs += [LOG / name for name in ('qualification.json', 'qualify.tap')]
    report = dict(schema='fsmgen.inactive_runtime_record_audit.v1', success=True,
                  assertions=tap_count((LOG / 'qualify.tap').read_text()),
                  rejection_controls=len(result['controls']), mutants=sorted(result['mutants']),
                  falsifiers=falsifiers,
                  inputs=[dict(path=str(path.relative_to(ROOT)), size_bytes=path.stat().st_size,
                               sha256=hashlib.sha256(path.read_bytes()).hexdigest()) for path in inputs],
                  limits=['Record syntax and internal consistency only; synthetic paths and native IDs.',
                          'No runtime reference or fixture workspace is created; no process is launched.',
                          'Current filesystem custody, global filename, full image byte equality, reference '
                          'acquisition, retirement, observation lifetime and native behavior remain unqualified.'])
    (LOG / 'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps({name: report[name] for name in ('success', 'assertions', 'rejection_controls', 'mutants', 'falsifiers')}, sort_keys=True))


if __name__ == '__main__':
    main()
