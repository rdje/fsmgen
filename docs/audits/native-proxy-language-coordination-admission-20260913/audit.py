"""Reconstruct prospective coordination admission without workers or permits."""

import argparse
import ast
import hashlib
import importlib.machinery
import importlib.util
import json
from pathlib import Path
import re
import subprocess

from contract import BASE, ROOT, OWNER, EXECUTION_OWNER, BOUNDS, cases
from local_files import pin, read_bytes
from toolchain import resolve


def read(path):
    return json.loads(path.read_bytes())


def encoded_pin(body, path):
    return dict(path=path, size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())


def first_source(row):
    current = ROOT / row['path']
    candidates = [current] + list((BASE / 'first-source').glob(current.name + '*.source'))
    for candidate in candidates:
        body = candidate.read_bytes()
        if encoded_pin(body, row['path']) == row:
            return candidate.relative_to(ROOT).as_posix()
    raise ValueError('original source epoch is not recoverable: ' + row['path'])


def task_layout(plan):
    layout = read(BASE / 'task-layout.json')
    source = subprocess.check_output(['git', 'show', plan['source_revision'] + ':' + layout['source_path']], cwd=ROOT)
    assert len(source) == layout['source_bytes'] and source.count(b'\n') == layout['source_lines']
    assert hashlib.sha256(source).hexdigest() == layout['source_sha256']
    text = source.decode()
    for replacement in layout['replacements']:
        assert text.count(replacement['old']) == 1
        text = text.replace(replacement['old'], replacement['new'], 1)
    nonempty = [line for line in text.splitlines() if line]
    before = text.count('\n')
    text = re.sub(r'\n{3,}', '\n\n', text)
    text, removed = re.subn(r'\n\n(?=- ID: `)', '\n', text, count=24)
    assert removed == 24 and before - text.count('\n') == layout['removed_blank_lines']
    assert [line for line in text.splitlines() if line] == nonempty
    assert text.count('\n') == layout['activation_lines']
    assert hashlib.sha256(text.encode()).hexdigest() == layout['activation_sha256']
    return dict(activation_lines=layout['activation_lines'], nonempty_line_order_preserved=True,
                first_preflight_preserved=layout['first_preflight'])


def verify():
    import qualify_data
    import qualify_runtime_data
    import qualify_identity
    import qualify_permit

    for row in read(BASE / 'audit-pins.json'):
        assert pin(row['path']) == row
    plan = read(BASE / 'plan.json')
    assert plan['owner'] == OWNER and plan['execution_owner'] == EXECUTION_OWNER
    assert plan['cases'] == cases() and plan['bounds'] == BOUNDS
    assert len(plan['inputs']) == 10 and len(plan['runtime_pins']) == 21
    for row in plan['inputs']:
        assert pin(row['path']) == row
        assert subprocess.check_output(['git', 'show', plan['source_revision'] + ':' + row['path']], cwd=ROOT) == (ROOT / row['path']).read_bytes()
    for row in plan['runtime_pins']:
        assert pin(row['path']) == row
    assert len(plan['prospective_objects']) == len(set(plan['prospective_objects'])) == 14
    assert len(plan['prospective_outputs']) == len(set(plan['prospective_outputs'])) == 42
    resolve(plan)
    repaired = read(BASE / 'identity-repair.json')
    original = read(BASE / 'first-source/plan.json.source')
    identity_plan = read(BASE / 'first-source/plan.json.identity-plan.source')
    assert repaired['original_plan'] == pin(repaired['original_plan']['path'])
    assert encoded_pin((BASE / 'first-source/plan.json.identity-plan.source').read_bytes(),
                       repaired['corrected_plan']['path']) == repaired['corrected_plan']
    expected_identity = json.loads(json.dumps(original))
    expected_identity['toolchains'] = identity_plan['toolchains']
    expected_identity['runtime_pins'] = identity_plan['runtime_pins']
    expected_identity['interpreter_identity_scope'] = identity_plan['interpreter_identity_scope']
    assert expected_identity == identity_plan
    finalized = read(BASE / 'source-finalization.json')
    assert pin(finalized['original_plan']['path']) == finalized['original_plan']
    assert pin(finalized['current_plan']['path']) == finalized['current_plan']
    expected_final = json.loads(json.dumps(identity_plan))
    expected_final['runtime_pins'] = plan['runtime_pins']
    assert expected_final == plan
    assert finalized['added_runtime_sources'] == [plan['runtime_pins'][-1]]
    assert plan['runtime_pins'][-1]['path'].endswith('/image_receipts.py')

    epochs = {}
    for name in ('first-source-pins.json', 'data-source-pins.json', 'source-check-pins.json',
                 'identity-source-pins.json', 'final-source-check-pins.json'):
        epochs[name] = [dict(**row, recoverable_from=first_source(row)) for row in read(BASE / name)]
    for row in read(BASE / 'final-source-check-pins.json'):
        assert pin(row['path']) == row
    first_runtime = BASE / 'first-source/runtime.py.source'
    assert first_runtime.is_file()
    # Readiness and termination must keep separate executable/ownership checks.
    tree = ast.parse((BASE / 'runtime.py').read_bytes())
    worker = next(node for node in tree.body if isinstance(node, ast.ClassDef) and node.name == 'Worker')
    methods = {node.name: node for node in worker.body if isinstance(node, ast.FunctionDef)}
    called = lambda node: [item.func.attr for item in ast.walk(node)
                           if isinstance(item, ast.Call) and isinstance(item.func, ast.Attribute)]
    assert 'owned_identity' in called(methods['launch']) and 'native_identity' not in called(methods['launch'])
    assert 'native_identity' in called(methods['observe']) and 'owned_identity' in called(methods['signal'])
    assert 'native_identity' not in called(methods['signal'])
    popen = [node for node in ast.walk(methods['launch']) if isinstance(node, ast.Call)
             and isinstance(node.func, ast.Attribute) and node.func.attr == 'Popen']
    assert len(popen) == 1
    options = {kw.arg: ast.literal_eval(kw.value) for kw in popen[0].keywords if kw.arg in ('start_new_session', 'close_fds')}
    assert options == dict(start_new_session=True, close_fds=True)

    data = qualify_data.qualify(read(BASE / 'synthetic-carrier.json'))
    assert data == read(BASE / 'data-review-final.json')
    runtime_data = qualify_runtime_data.qualify()
    assert runtime_data == read(BASE / 'runtime-data-review.json')
    identity = qualify_identity.qualify()
    assert identity == read(BASE / 'identity-review.json')
    permit = qualify_permit.qualify()
    assert permit == read(BASE / 'permit-state-review.json')
    outputs = read(BASE / 'source-check-outputs.json')
    values = {}
    for row in outputs:
        body = bytes.fromhex(row['bytes_hex'])
        assert encoded_pin(body, row['path']) == {key: row[key] for key in ('path', 'size_bytes', 'sha256')}
        values[Path(row['path']).name] = body
    stages = ('python-syntax', 'perl-worker-syntax', 'perl-probe-syntax', 'data', 'data-final',
              'runtime-data', 'prepare', 'identity-finalization', 'identity-review', 'permit-states',
              'runtime-final', 'data-saved', 'python-final')
    assert len(values) == len(outputs) == len(stages) * 3
    for stage in stages:
        assert values[stage + '.exit'] == b'0\n'
    assert json.loads(values['prepare.stdout']) == dict(actual_worker_execution=False, prospective_cases=12, runtime_inputs=20, source_inputs=10)
    assert json.loads(values['identity-review.stdout'])['controls'] == len(identity['rejected_controls']) == 12
    assert json.loads(values['permit-states.stdout'])['rejected_states'] == len(permit['rejected_states']) == 16
    return dict(schema='fsmgen.language_coordination_admission_review.v1', owner=OWNER,
                source_revision=plan['source_revision'], current_runtime_inputs=len(plan['runtime_pins']),
                selected_source_inputs=len(plan['inputs']), prospective_cases=len(plan['cases']),
                prospective_workers=20, prospective_exec_probes=4, prospective_objects=14,
                source_epochs=epochs, task_activation=task_layout(plan),
                event_reader_controls=len(data['rejected_controls']), supervisor_state_checks=len(runtime_data['checks']),
                identity_controls=len(identity['rejected_controls']), permit_state_controls=len(permit['rejected_states']),
                source_outputs=outputs, native_image_repair=identity,
                actual_worker_execution=False, actual_permit_issued=False,
                native_proxy_startup_cause_established=False,
                missing_legs=plan['missing_legs'], scope=plan['scope'])


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    result = verify()
    if args.retain:
        with (BASE / 'review.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        assert result == read(BASE / 'review.json')
    print(json.dumps(dict(prospective_cases=12, event_controls=20, identity_controls=12,
                          permit_controls=16, actual_worker_execution=False), sort_keys=True))


if __name__ == '__main__':
    main()
