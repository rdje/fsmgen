"""Independent audit of inert publication and unchanged coordination controls."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-image-publication-20260910'


def load_auditor(name: str, directory: str):
    spec = importlib.util.spec_from_file_location(name, BASE.parent / directory / 'audit.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def tap_count(path: Path) -> int:
    text = path.read_text()
    assert not re.search(r'^(?:not ok|Bail out!)', text, re.M)
    plans = re.findall(r'^1\.\.([0-9]+)$', text, re.M)
    assert len(plans) == 1
    total = int(plans[0])
    assert [int(n) for n in re.findall(r'^ok ([0-9]+) - ', text, re.M)] == list(range(1, total + 1))
    return total


def validate(result: dict, vector: dict, expected: tuple[bytes, bytes, bytes]) -> None:
    assert result['success'] is True
    assert type(result['forbidden_process_attempts']) is int and result['forbidden_process_attempts'] == 0
    assert result['sealed_source_mutant_defeated'] == 1
    rows = result['controls']
    required = {'modeled content-key collision', 'new image at capacity',
                'existing empty_directory', 'existing missing_manifest', 'existing writable_image',
                'existing changed_bytes', 'interruption before executable seal',
                'interruption after executable seal', 'same-byte sealed source replacement',
                'same-byte sealed directory replacement', 'direct internal publication bypass'}
    assert required <= {row['name'] for row in rows}
    assert len(rows) == len({row['name'] for row in rows})
    assert all(row['rejected'] == 1 and row['expected_diagnostic'] == 1 and row['returned_result'] == 0 for row in rows)
    cases = result['retired_cases']
    assert cases and len(cases) == len(set(cases))
    for name in cases:
        assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+', name)
        path = ROOT / name
        assert not path.exists() and not path.is_symlink()
    first, reuse = result['first'], result['reuse']
    assert type(first['created']) is int and first['created'] == 1
    assert type(reuse['created']) is int and reuse['created'] == 0
    for record in (first, reuse):
        assert record['runtime_authorized'] == 0 and record['executable'] is None
        assert record['image_key'] == vector['key']
        assert record['lock']['path'] == cases[0] + '/coordination.lock'
        assert len(record['sources']) == 3
        for source, name, data in zip(record['sources'], ('rustup.c', 'rustup', 'image.json'), expected):
            assert source['path'] == cases[0] + '/images/' + vector['key'] + '/' + name
            assert source['size_bytes'] == len(data)
            assert source['sha256'] == hashlib.sha256(data).hexdigest()
            assert type(source['inode']) is int and source['inode'] > 0
            assert type(source['device']) is int and source['device'] == ROOT.stat().st_dev
    assert first['lock'] == reuse['lock'] and first['sources'] == reuse['sources']


def main() -> None:
    contract = ROOT / 'docs/audits/native-proxy-canonical-contract-20260910/contract.json'
    assert hashlib.sha256(contract.read_bytes()).hexdigest() == 'f3f981398afae72540ab4ac0194b8380d4743c3d2146c1172a85365add053222'
    custody = load_auditor('custody_auditor', 'native-proxy-image-custody-20260910')
    coordination = load_auditor('coordination_auditor', 'native-proxy-image-coordination-20260910')
    vector = json.loads((BASE.parent / 'native-proxy-image-custody-20260910/vectors.json').read_bytes())
    expected = custody.vectors(vector)
    result = json.loads((LOG / 'qualification.json').read_bytes())
    regression = json.loads((LOG / 'coordination-regression.json').read_bytes())
    validate(result, vector, expected)
    coordination.validate(regression)
    assert not set(result['retired_cases']) & set(regression['retired_cases'])
    falsifiers = []
    for name, mutate in (
        ('hidden failure', lambda value: value.update(success=False)),
        ('runtime authorization', lambda value: value['first'].update(runtime_authorized=1)),
        ('runnable result', lambda value: value['reuse'].update(executable='rustup')),
        ('different reuse inode', lambda value: value['reuse']['sources'][0].update(inode=1)),
        ('changed source digest', lambda value: value['first']['sources'][0].update(sha256='0' * 64)),
        ('missing interruption controls', lambda value: value.update(controls=[])),
        ('omitted source mutant', lambda value: value.update(sealed_source_mutant_defeated=0)),
    ):
        changed = copy.deepcopy(result)
        mutate(changed)
        try:
            validate(changed, vector, expected)
        except AssertionError:
            falsifiers.append(name)
        else:
            raise AssertionError(f'counterfactual accepted: {name}')
    inputs = [BASE / 'Publication.pm', BASE / 'qualify.t',
              BASE.parent / 'native-proxy-image-coordination-20260910/Coordination.pm',
              BASE.parent / 'native-proxy-image-custody-20260910/ImageCustody.pm']
    inputs += [LOG / name for name in ('qualification.json', 'qualify.log',
                                       'coordination-regression.json', 'coordination-regression.tap')]
    report = dict(schema='fsmgen.inactive_image_publication_audit.v1', success=True,
        publication_assertions=tap_count(LOG / 'qualify.log'),
        coordination_assertions=tap_count(LOG / 'coordination-regression.tap'),
        rejection_controls=len(result['controls']), publication_cases=len(result['retired_cases']),
        coordination_cases=len(regression['retired_cases']), falsifiers=falsifiers,
        inputs=[dict(path=str(path.relative_to(ROOT)), size_bytes=path.stat().st_size,
                     sha256=hashlib.sha256(path.read_bytes()).hexdigest()) for path in inputs],
        limits=['All published bytes are inert vectors, never compiled or executed.',
                'Creation/reuse preserve observed canonical byte/inode custody without runtime authorization.',
                'No runtime/observation references, real contention, native behavior or maintenance qualified.',
                'Historical inode records describe retired cases; replay creates new ones.',
                'Cooperative locking and descriptor observations do not attest loaded code or ongoing '
                'immutability against arbitrary noncooperating programs.'])
    (LOG / 'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps({key: report[key] for key in ('success', 'publication_assertions', 'coordination_assertions',
        'rejection_controls', 'publication_cases', 'coordination_cases', 'falsifiers')}, sort_keys=True))


if __name__ == '__main__':
    main()
