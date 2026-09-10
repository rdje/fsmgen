"""Independently audit retained inert coordination results; create no process."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-image-coordination-20260910'


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def validate(result: dict) -> None:
    assert result['success'] is True
    assert type(result['forbidden_process_attempts']) is int and result['forbidden_process_attempts'] == 0
    assert result['mutants_defeated'] == ['lock_guard', 'no_repair_guard']
    required = {'wrong lock mode', 'nonempty lock', 'hard-linked lock', 'symlink lock',
                'directory lock', 'FIFO lock', 'image over capacity', 'reference over capacity',
                'modeled busy_deadline', 'modeled other_error', 'modeled late_success',
                'census lock_replace', 'census directory_replace', 'census directory_remove'}
    rows = result['controls']
    assert required <= {row['name'] for row in rows}
    assert len(rows) == len({row['name'] for row in rows})
    assert all(row['rejected'] == 1 and row['expected_diagnostic'] == 1 for row in rows)
    cases = result['retired_cases']
    assert cases and len(set(cases)) == len(cases)
    for name in cases:
        assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+', name)
        path = ROOT / name
        assert not path.exists() and not path.is_symlink()
    positive = result['positive']
    assert positive['schema'] == 'fsmgen.inactive_image_namespace.v1'
    assert positive['completeness'] == 'structure_only; contents_and_reference_semantics_unqualified'
    assert positive['images'] == [] and positive['references'] == []
    lock = positive['lock']
    assert lock['path'] == cases[0] + '/coordination.lock'
    assert type(lock['inode']) is int and lock['inode'] > 0
    assert type(lock['device']) is int and lock['device'] == ROOT.stat().st_dev


def main() -> None:
    contract = ROOT / 'docs/audits/native-proxy-canonical-contract-20260910/contract.json'
    assert digest(contract.read_bytes()) == 'f3f981398afae72540ab4ac0194b8380d4743c3d2146c1172a85365add053222'
    result = json.loads((LOG / 'qualification.json').read_bytes())
    validate(result)
    tap = (LOG / 'qualify.log').read_text()
    assert not re.search(r'^(?:not ok|Bail out!)', tap, re.M)
    plans = re.findall(r'^1\.\.([0-9]+)$', tap, re.M)
    assert len(plans) == 1
    total = int(plans[0])
    assert [int(n) for n in re.findall(r'^ok ([0-9]+) - ', tap, re.M)] == list(range(1, total + 1))
    falsifiers = []
    for name, mutate in (
        ('hidden failed result', lambda value: value.update(success=False)),
        ('hidden process attempt', lambda value: value.update(forbidden_process_attempts=1)),
        ('omitted countermodel', lambda value: value.update(mutants_defeated=[])),
        ('omitted rejection controls', lambda value: value.update(controls=[])),
        ('false completeness', lambda value: value['positive'].update(completeness='complete')),
        ('wrong lock path', lambda value: value['positive']['lock'].update(path='.artifacts/cache/other')),
    ):
        changed = copy.deepcopy(result)
        mutate(changed)
        try:
            validate(changed)
        except AssertionError:
            falsifiers.append(name)
        else:
            raise AssertionError(f'counterfactual accepted: {name}')
    inputs = [BASE / 'Coordination.pm', BASE / 'qualify.t', contract,
              BASE.parent / 'native-proxy-image-custody-20260910/ImageCustody.pm',
              LOG / 'qualification.json', LOG / 'qualify.log']
    report = dict(schema='fsmgen.inactive_image_coordination_audit.v1', success=True,
        tap_assertions=total, rejection_controls=len(result['controls']),
        independently_absent_cases=len(result['retired_cases']), falsifiers=falsifiers,
        inputs=[dict(path=str(path.relative_to(ROOT)), size_bytes=path.stat().st_size,
                     sha256=digest(path.read_bytes())) for path in inputs],
        limits=['Single-process lock identity, flags and descriptor closure were observed.',
                'Busy, nonbusy error and monotonic-deadline outcomes were modeled; '
                'actual cross-process contention and inheritance are separately owned.',
                'Counts include incomplete objects; this census establishes no image or reference completeness.',
                'No publication, runtime/observation lifetime, maintenance, native execution or product activation.'])
    (LOG / 'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps({key: report[key] for key in ('success', 'tap_assertions', 'rejection_controls',
                                                   'independently_absent_cases', 'falsifiers')}, sort_keys=True))


if __name__ == '__main__':
    main()
