"""Audit the reproduced delimiter collision and its inert regression repair."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs/native-proxy-image-fieldsets-20260910'
FIELDS = ['pid', 'ppid', 'ruid', 'start_sec', 'start_usec', 'uid']


def load(name: str, directory: str):
    spec = importlib.util.spec_from_file_location(name, BASE.parent / directory / 'audit.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def tap(path: Path) -> tuple[int, int]:
    text = path.read_text()
    assert not re.search(r'^Bail out!', text, re.M)
    plans = re.findall(r'^1\.\.([0-9]+)$', text, re.M)
    assert len(plans) == 1
    total = int(plans[0])
    rows = re.findall(r'^(not ok|ok) ([0-9]+) - ', text, re.M)
    assert [int(number) for _, number in rows] == list(range(1, total + 1))
    return total, sum(status == 'not ok' for status, _ in rows)


def validate(red: dict, green: dict) -> None:
    assert red['success'] is False and green['success'] is True
    assert red['forbidden_process_attempts'] == green['forbidden_process_attempts'] == 0
    before = {row['name']: row for row in red['controls']}
    after = {row['name']: row for row in green['controls']}
    assert [row['name'] for row in red['controls']] == [row['name'] for row in green['controls']]
    labels = ['combined native birth fields: ' + '+'.join(FIELDS[start:start + width])
              for width in range(2, len(FIELDS) + 1) for start in range(len(FIELDS) - width + 1)]
    for name in labels:
        assert before[name]['expected_diagnostic'] == 0
        assert after[name]['rejected'] == after[name]['expected_diagnostic'] == 1
    assert before['combined native birth fields: ppid+ruid']['rejected'] == 0
    assert before['combined image member names']['rejected'] == 0
    # The complete old entry reader already rejected its missing required files.
    assert before['combined-member image cannot be admitted']['rejected'] == 1
    assert after['combined image member names']['rejected'] == 1
    assert after['combined native fields padded to expected count']['rejected'] == 1
    assert all(row['rejected'] == row['expected_diagnostic'] == 1 for row in green['controls'])
    for name in red['retired_cases'] + green['retired_cases']:
        assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+', name)
        assert not (ROOT / name).exists() and not (ROOT / name).is_symlink()
    assert not set(red['retired_cases']) & set(green['retired_cases'])


def main() -> None:
    custody = load('fieldset_custody_auditor', 'native-proxy-image-custody-20260910')
    publication = load('fieldset_publication_auditor', 'native-proxy-image-publication-20260910')
    vector = json.loads((BASE.parent / 'native-proxy-image-custody-20260910/vectors.json').read_bytes())
    expected = custody.vectors(vector)
    red = json.loads((LOG / 'red.json').read_bytes())
    green = json.loads((LOG / 'green.json').read_bytes())
    regression = json.loads((LOG / 'publication-regression.json').read_bytes())
    validate(red, green)
    custody.qualification(green, expected)
    publication.validate(regression, vector, expected)
    assert not set(regression['retired_cases']) & set(red['retired_cases'] + green['retired_cases'])
    malformed = dict(pid=101, start_sec=1234, start_usec=5678, uid=501)
    malformed['ppid,ruid'] = 501
    assert ','.join(sorted(malformed)) == ','.join(FIELDS) and set(malformed) != set(FIELDS)
    raw = json.dumps(['.artifacts/logs/inert-codec-probe', malformed, malformed],
                     sort_keys=True, ensure_ascii=True, separators=(',', ':')).encode('ascii')
    key = hashlib.sha256(b'fsmgen.rust_proxy_reference.observation.v1\0' + raw).hexdigest()
    assert key == 'bce38da7b4f92bb84394428d6b47903d547d27a1ab46184f31afcf1cbdbbd3a0'
    falsifiers = []
    for label, change in (
        ('hidden original failure', lambda a, b: a.update(success=True)),
        ('hidden repaired failure', lambda a, b: b.update(success=False)),
        ('claimed old rejection', lambda a, b: next(row for row in a['controls']
            if row['name'] == 'combined native birth fields: ppid+ruid').update(rejected=1)),
        ('missing merged-field controls', lambda a, b: b.update(controls=b['controls'][:1])),
    ):
        a, b = copy.deepcopy(red), copy.deepcopy(green)
        change(a, b)
        try:
            validate(a, b)
        except AssertionError:
            falsifiers.append(label)
        else:
            raise AssertionError(f'counterfactual accepted: {label}')
    red_tap, green_tap = tap(LOG / 'red.tap'), tap(LOG / 'green.tap')
    assert red_tap[0] == green_tap[0] and red_tap[1] == 16 and green_tap[1] == 0
    regression_tap = tap(LOG / 'publication-regression.tap')
    assert regression_tap[1] == 0
    paths = [LOG / name for name in ('before-source.pm', 'red.json', 'red.tap', 'green.json', 'green.tap',
                                      'publication-regression.json', 'publication-regression.tap')]
    paths += [BASE.parent / 'native-proxy-image-custody-20260910' / name for name in ('ImageCustody.pm', 'qualify.t')]
    report = dict(schema='fsmgen.inactive_fieldset_repair_audit.v1', success=True,
        red_assertions=red_tap[0], red_failed_assertions=red_tap[1], green_assertions=green_tap[0],
        unexpected_old_acceptances=sum(row['rejected'] == 0 for row in red['controls']),
        green_rejection_controls=len(green['controls']), publication_assertions=regression_tap[0],
        retired_cases={name: len(value['retired_cases']) for name, value in
                       (('red', red), ('green', green), ('publication', regression))},
        reproduced_bad_key=key, falsifiers=falsifiers,
        inputs=[dict(path=str(path.relative_to(ROOT)), size_bytes=path.stat().st_size,
                     sha256=hashlib.sha256(path.read_bytes()).hexdigest()) for path in paths],
        limits=['The malformed birth was accepted by an inactive key codec; no runtime reference was written.',
                'Old member-list validation was ambiguous, but complete image admission rejected missing files.',
                'The repair qualifies record shape and custody controls, not runtime ownership or native execution.'])
    (LOG / 'audit.json').write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps({key: report[key] for key in ('success', 'red_failed_assertions', 'green_assertions',
        'unexpected_old_acceptances', 'green_rejection_controls', 'publication_assertions', 'retired_cases')}, sort_keys=True))


if __name__ == '__main__':
    main()
