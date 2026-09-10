"""Join the image-member baseline, repaired qualification and focused regressions."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import re
import stat

from audit import BASE, ROOT, LOG, equal, validate


def module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def tap_count(path: Path) -> int:
    text = path.read_text()
    assert not re.search(r'^(?:not ok|Bail out!)', text, re.M)
    plans = re.findall(r'^1\.\.(\d+)$', text, re.M)
    assert len(plans) == 1
    count = int(plans[0])
    assert [int(n) for n in re.findall(r'^ok (\d+) - ', text, re.M)] == list(range(1, count + 1))
    return count


def main() -> None:
    plan = json.loads((BASE/'plan.json').read_bytes())
    paths = []
    phases = {}
    for phase, expected in [('baseline', 9), ('qualification', 29)]:
        result = json.loads((LOG/(phase+'.json')).read_bytes())
        validate(result, plan, phase)
        assert tap_count(LOG/(phase+'.tap')) == expected
        paths.extend(row['path'] for row in result['allocated'])
        phases[phase] = dict(assertions=expected, allocations=len(result['allocated']),
                             qualified=result['qualified'])

    pins = json.loads((LOG/'baseline-pins.json').read_bytes())
    for index, pin in enumerate(pins):
        path = LOG/'ImageCustody.pm.baseline-source' if index == 0 else ROOT/pin['path']
        raw = path.read_bytes()
        assert len(raw) == pin['bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    before = (LOG/'ImageCustody.pm.baseline-source').read_text()
    after = (ROOT/pins[0]['path']).read_text()
    pattern = r'(?ms)^sub _members \{.*?(?=^sub )'
    assert len(re.findall(pattern, before)) == len(re.findall(pattern, after)) == 1
    assert before != after and re.sub(pattern, '', before) == re.sub(pattern, '', after)
    predecessor = json.loads((BASE.parent/'native-proxy-namespace-reader-20260911/review.json').read_bytes())
    unchanged = [pin for pin in predecessor['unchanged_inputs'] if pin['path'] != pins[0]['path']]
    for pin in unchanged:
        raw = (ROOT/pin['path']).read_bytes()
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']

    preflight = json.loads((LOG/'preflight-pins.json').read_bytes())
    for pin in preflight:
        raw = (ROOT/pin['path']).read_bytes()
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    custody = module('member_custody_oracle', BASE.parent/'native-proxy-image-custody-20260910/audit.py')
    vector = json.loads((custody.BASE/'vectors.json').read_bytes())
    expected_bytes = custody.vectors(vector)
    regressions = {}
    for short, directory, expected in [
        ('custody', 'native-proxy-image-custody-20260910', 81),
        ('publication', 'native-proxy-image-publication-20260910', 78),
        ('combined', 'native-proxy-combined-census-20260910', 35),
        ('snapshot', 'native-proxy-observation-snapshot-cuts-20260910', 345),
    ]:
        oracle = module('image_member_regression_'+short, BASE.parent/directory/'audit.py')
        oracle.LOG = LOG/(short+'-regression')
        execution = json.loads((oracle.LOG/'execution.json').read_bytes())
        assert execution['exit_code'] == 0
        result = json.loads((oracle.LOG/'qualification.json').read_bytes())
        if short == 'custody':
            oracle.qualification(result, expected_bytes)
            allocations = result['retired_cases']
        elif short == 'publication':
            oracle.validate(result, vector, expected_bytes)
            allocations = result['retired_cases']
        else:
            regression_plan = json.loads((oracle.BASE/'plan.json').read_bytes())
            if short == 'snapshot': equal(regression_plan, oracle.PLAN.build())
            oracle.validate(result, regression_plan)
            if short == 'snapshot':
                rows = [json.loads(line) for line in (oracle.LOG/'rows.jsonl').read_text().splitlines()]
                equal(rows, [dict(category=c, row=r) for c in ('cases', 'mutants') for r in result[c]])
                equal(json.loads((oracle.LOG/'progress.json').read_bytes()),
                      dict(schema='fsmgen.inactive_snapshot_cut_progress.v1', success=True,
                           allocations=len(result['allocated']), cases=len(result['cases']),
                           mutants=len(result['mutants']), forbidden_process_attempts=0))
            allocations = [row['path'] for row in result['allocated']]
        assert tap_count(oracle.LOG/'qualify.tap') == expected
        paths.extend(allocations)
        regressions[short] = dict(executed=True, assertions=expected, allocations=len(allocations))
    assert len(paths) == len(set(paths))
    assert all(not (ROOT/path).exists() and not (ROOT/path).is_symlink() for path in paths)

    restoration = json.loads((LOG/'regression-restoration.json').read_bytes())
    assert restoration['all_byte_exact'] is True and len(restoration['restored']) == 8
    assert len({row['path'] for row in restoration['restored']}) == 8
    for row in restoration['restored']:
        path = ROOT/row['path']
        raw = path.read_bytes()
        assert len(raw) == row['bytes'] and hashlib.sha256(raw).hexdigest() == row['sha256']
        assert stat.S_IMODE(path.stat().st_mode) == row['mode']
    report = dict(schema='fsmgen.inactive_image_member_closure.v1', success=True,
        phases=phases, regressions=regressions, total_roots=len(paths),
        all_rosters_disjoint_and_absent=True, restored_outputs=8,
        baseline_plan_harness_auditor_unchanged=True, only_members_function_changed=True,
        unchanged_predecessor_inputs=len(unchanged), prospective_inputs_unchanged=len(preflight),
        limits='Direct synchronous directory faults and focused inactive regressions. No ordinary lexical-cleanup leak, incomplete-image acceptance through the full reader, complete coordinator matrix, native execution or product activation is established.')
    (LOG/'closure.json').write_text(json.dumps(report, sort_keys=True, indent=2)+'\n')
    print(json.dumps(report, sort_keys=True))


if __name__ == '__main__':
    main()
