#!/usr/bin/env python3
"""Verify the initial warning-only failure without rerunning any native fixture."""
import contextlib
import copy
import importlib.util
import io
import json
from pathlib import Path

root = Path(__file__).resolve().parents[3]
initial = root / 'docs/audits/record-input-observer-20261001/verify.py'
spec = importlib.util.spec_from_file_location('initial_record_observer', initial)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
original = module.validate
warning = ('sort (...) interpreted as function at '
           'docs/audits/record-input-observer-20261001/RecordInputAdmission.pm line 18.\n')
seen = []

def warning_only(rows, cases, postcheck):
    normalized = copy.deepcopy(rows)
    for row in normalized:
        stderr = row['result']['stderr']
        assert stderr.startswith(warning) and stderr.count(warning) == 1
        row['result']['stderr'] = stderr[len(warning):]
    # Remove only the independently identified exact warning. All stage,
    # native-context, admission-gap, errno and cleanup checks remain original.
    original(normalized, cases, postcheck)
    seen.append(True)

rows = module.read_json(initial.parent / 'evidence/results.json')
assert all(row['result']['stderr'].startswith(warning) for row in rows)
module.validate = warning_only
with contextlib.redirect_stdout(io.StringIO()):
    module.main()
assert seen
print(json.dumps({'initial_warning_exactly_identified': True,
                  'all_original_saved_checks_pass_after_only_exact_warning_removal': True,
                  'original_hostile_saved_controls_still_reject': True,
                  'initial_observer_not_qualified': True,
                  'no_native_fixture_rerun': True}, sort_keys=True))
