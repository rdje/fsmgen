"""Evaluate only the prospective symbolic contract and weakened model controls."""
from __future__ import annotations

import ast
import builtins
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name


def changed_sources(raw):
    changes = [
        ('erase unlink on failure', "success = not error", "success = not error\n    if error: effect['unlink_completed'] = 0"),
        ('close error becomes success', "success = not error", "success = not error or error.startswith('close:')"),
        ('erase earlier absence', "success = not error", "success = not error\n    if effect['last_reference_check'] and effect['last_reference_check']['state'] != 'absent': effect['reference_absence_verified'] = 0"),
        ('cleanup replaces primary', 'if not error and report_error: error = report_error', 'if report_error: error = report_error'),
    ]
    result = []
    for name, old, new in changes:
        assert raw.count(old) == 1
        result.append((name, raw.replace(old, new)))
    return result


def main():
    plan = json.loads((BASE / 'contract.json').read_bytes()); pins = json.loads((BASE / 'preflight-pins.json').read_bytes())
    for pin in plan['inputs'] + pins:
        raw = (ROOT / pin['path']).read_bytes()
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    source = (BASE / 'model.py').read_text(); ast.parse(source)
    models = []
    for name, text in [('original', source)] + changed_sources(source):
        namespace = {}; exec(compile(text, str((BASE / 'model.py').relative_to(ROOT)), 'exec'), namespace)
        models.append((name, namespace['evaluate']))
    LOG.mkdir(parents=True, exist_ok=True)
    assert LOG.stat().st_dev == ROOT.stat().st_dev and not LOG.is_symlink()
    result = dict(schema='fsmgen.inactive_release_interruption_model_qualification.v1', success=False, cases=[], mutants=[],
                  prospective_pins=pins, forbidden_lookup_or_process_attempts=0)
    def forbidden(*args, **kwargs):
        result['forbidden_lookup_or_process_attempts'] += 1
        raise AssertionError('symbolic model attempted filesystem or process access')
    saved = []
    for obj, name in [(builtins, 'open'), (os, 'open'), (os, 'stat'), (os, 'lstat'), (os, 'system'), (subprocess, 'Popen')]:
        saved.append((obj, name, getattr(obj, name))); setattr(obj, name, forbidden)
    try:
        for case in plan['cases']:
            initial = copy.deepcopy(case); output = models[0][1](case)
            assert case == initial
            result['cases'].append(dict(name=case['name'], input_unchanged=True, output=output))
        for name, model in models[1:]:
            witnesses = []
            for case, observed in zip(plan['cases'], result['cases'], strict=True):
                initial = copy.deepcopy(case); output = model(case); assert case == initial
                if output != observed['output']:
                    witnesses.append(dict(name=case['name'], output=output))
            assert witnesses; result['mutants'].append(dict(name=name, witnesses=witnesses))
    finally:
        for obj, name, value in saved: setattr(obj, name, value)
    assert result['forbidden_lookup_or_process_attempts'] == 0
    result['success'] = True
    with (LOG / 'qualification.json').open('x') as stream: stream.write(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(success=True, cases=len(result['cases']), mutants=len(result['mutants']), witnesses=sum(len(m['witnesses']) for m in result['mutants'])), sort_keys=True))


if __name__ == '__main__':
    main()
