"""Qualify the selector adapter while retaining the first auditor's rejection."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
PIN_NAMES = ['plan.json', 'preflight-pins.json', 'audit.py', 'audit-corrected.py', 'correction-preflight.py']
MAIN_NAMES = ['prepare.py', 'prepare-pins.json', 'plan.json', 'audit.py', 'preflight-pins.json',
              'audit-corrected.py', 'correction-preflight.py', 'correction-pins.json',
              'result/correction/preflight.json', 'result/correction/preflight.stdout',
              'result/correction/preflight.stderr', 'result/correction/preflight.exit',
              'result/correction/recovery.json']
NAMES = ['preflight.json', 'preflight.stdout', 'preflight.stderr', 'preflight.exit']


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


def load(path):
    return json.loads(path.read_bytes())


def evaluate():
    prepare = module('close_adapter_prepare', BASE / 'prepare.py')
    pins = load(BASE / 'correction-pins.json')
    assert pins == [prepare.pin(BASE / n) for n in PIN_NAMES]
    first = module('close_adapter_first_auditor', BASE / 'audit.py')
    corrected = module('close_adapter_corrected_auditor', BASE / 'audit-corrected.py')
    core = module('close_adapter_original_rows', BASE.parent / prepare.SINGLES[0] / 'audit.py')
    model = module('close_adapter_original_selector', BASE.parent / prepare.SINGLE_SELECTION / 'model.py')
    original_source = (BASE / 'audit.py').read_text()
    corrected_source = (BASE / 'audit-corrected.py').read_text()
    start, end = corrected_source.index('def single_selectors('), corrected_source.index('def main():')
    normalized = corrected_source[:start] + corrected_source[end:]
    normalized = normalized.replace('        core.SELECT.domain(single, single_selectors(core, calls, row, contracts), original)',
                                    '        core.SELECT.domain(single, bindings, original)', 1)
    normalized = normalized.replace("    correction = module('close_join_selector_adapter_proof', BASE / 'correction-preflight.py')\n    correction.verify_saved()\n    pins = load(BASE / 'corrected-preflight-pins.json')\n    assert pins == [prepare.pin(BASE / n) for n in correction.MAIN_NAMES]",
        "    pins = load(BASE / 'preflight-pins.json')\n    assert pins == [prepare.pin(BASE / n) for n in ('prepare.py', 'prepare-pins.json', 'plan.json', 'audit.py')]", 1)
    assert normalized == original_source
    selected = load(BASE.parent / prepare.SINGLE_SELECTION / 'plan.json')
    boundary = load(core.PREPARE.BOUNDARY / 'plan.json')
    saved = load(core.PREPARE.BOUNDARY / 'result/qualification.json')
    contracts = core.SELECT.source_contracts(prepare)
    comparisons, controls = [], []
    for profile, original, row in zip(selected['profiles'], boundary['profiles'], saved['cases'], strict=True):
        spec, _ = core.OLD.setup(row)
        calls = core.FLOW.derive(row['context'], row['operation']['before'], spec)
        bindings = core.SELECT.ownership(calls, row['context'])
        assert first.rejects(lambda: core.SELECT.domain(profile, bindings, original))
        selectors = corrected.single_selectors(core, calls, row, contracts)
        assert selectors == model.select(row)
        core.SELECT.domain(profile, selectors, original)
        comparisons.append(dict(profile=profile['id'], selectors=len(selectors), source_bindings=len(bindings),
            first_auditor_rejects=True, corrected_adapter_accepts=True,
            selector_sha256=first.signature(selectors), binding_fields=sorted(bindings[0]),
            archived_fields=sorted(selectors[0])))
        for name, mutate in (
            ('wrong-open-event', lambda values: values[0].update(baseline_open_event=-1)),
            ('wrong-close-scope', lambda values: values[0].update(baseline_close_scope='foreign')),
            ('missing-selector', lambda values: values.pop()),
            ('wrong-open-call', lambda values: values[0].update(baseline_open_call_id=-1)),
        ):
            changed = copy.deepcopy(selectors); mutate(changed)
            assert first.rejects(lambda: core.SELECT.domain(profile, changed, original))
            controls.append(profile['id'] + ':' + name)
    return dict(schema='fsmgen.release_close_join_selector_adapter.v1', success=True,
        prospective_pins=pins, comparisons=comparisons, falsifiers=controls, exact_source_delta=True,
        source_revision=prepare.REVISION, fixture_replays=0,
        scope='Reconstruct archived selector records from original source ownership and event positions; '
              'independent event-stack selection agrees. Original failed auditor and output remain retained.')


def summary(value):
    return dict(success=True, profiles=len(value['comparisons']), selectors=sum(r['selectors'] for r in value['comparisons']),
        first_rejections=sum(r['first_auditor_rejects'] for r in value['comparisons']),
        corrected_acceptances=sum(r['corrected_adapter_accepts'] for r in value['comparisons']),
        falsifiers=len(value['falsifiers']), exact_source_delta=value['exact_source_delta'], fixture_replays=0)


def verify_saved():
    prepare = module('close_adapter_saved_prepare', BASE / 'prepare.py')
    output = BASE / 'result/correction'
    records = load(output / 'recovery.json')
    assert [(r['source'], r['destination']) for r in records] == [
        (str((LOG / ('correction-' + n)).relative_to(ROOT)), str((output / n).relative_to(ROOT))) for n in NAMES]
    for record in records:
        actual = prepare.pin(ROOT / record['destination'])
        assert {k: record[k] for k in ('size_bytes', 'sha256')} == {k: actual[k] for k in ('size_bytes', 'sha256')}
    assert (output / 'preflight.exit').read_bytes() == b'0\n' and (output / 'preflight.stderr').read_bytes() == b''
    value = evaluate()
    assert load(output / 'preflight.json') == value and load(output / 'preflight.stdout') == summary(value)
    return value


if __name__ == '__main__':
    prepare = module('close_adapter_admission_prepare', BASE / 'prepare.py')
    assert prepare.build() == load(BASE / 'plan.json')
    result = evaluate()
    with (LOG / 'correction-preflight.json').open('x') as stream:
        stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps(summary(result), sort_keys=True))
