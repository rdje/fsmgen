"""Require the original header check RED and its narrow correction GREEN."""
import importlib.util
import json
from pathlib import Path
import copy

BASE = Path(__file__).resolve().parent


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


def main():
    old = module('first_syscall_audit', BASE / 'audit.py')
    new = module('corrected_syscall_audit', BASE / 'audit-corrected.py')
    plan = new.load(BASE / 'plan.json'); new.domain(plan); pins = new.authenticate(plan)
    support = module('syscall_header_support', BASE.with_name('native-proxy-observation-archive-release-ordinary-before-20260911') / 'audit.py')
    report = new.load(new.LOG / 'qualification.json')
    assert old.rejects(lambda: old.header(plan, report, pins, support))
    new.header(plan, report, pins, support)
    falsifiers = []
    for name, mutate in [('missing-process-counter', lambda r: r.pop('forbidden_process_attempts')),
                         ('invented-counter-alias', lambda r: r.update(forbidden_attempts=0)),
                         ('actual-process-attempt', lambda r: r.update(forbidden_process_attempts=1))]:
        bad = copy.deepcopy(report); mutate(bad)
        assert new.rejects(lambda: new.header(plan, bad, pins, support)), name
        falsifiers.append(name)
    expected = (BASE / 'audit.py').read_text().replace('forbidden_attempts', 'forbidden_process_attempts')
    expected = expected.replace('    return pins\n', "    correction = load(BASE / 'correction-pins.json')\n    assert correction == [prepare.pin(BASE / name) for name in ('audit-corrected.py', 'correction-preflight.py')]\n    return pins\n")
    assert (BASE / 'audit-corrected.py').read_text() == expected
    result = dict(success=True, original_header_rejects=True, corrected_header_accepts=True,
        unchanged_fixture=True, source_diff_exact=True, falsifiers=falsifiers)
    with (new.LOG / 'correction-preflight.json').open('x') as output:
        output.write(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
