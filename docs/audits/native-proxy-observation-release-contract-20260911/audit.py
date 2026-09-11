"""Independently rederive sources and falsify the finite release selection."""
from __future__ import annotations

import ast
import copy
import hashlib
import itertools
import json
from pathlib import Path
import subprocess
import types

import model

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT/'.artifacts/logs/native-proxy-observation-release-contract-20260911'


def constants(path, names):
    tree = ast.parse(path.read_bytes())
    found = {}

    def number(node):
        if isinstance(node, ast.Constant) and type(node.value) is int:
            return node.value
        assert isinstance(node, ast.BinOp) and isinstance(node.op, ast.Mult)
        return number(node.left)*number(node.right)

    for node in tree.body:
        if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
            name = node.targets[0].id
            if name in names:
                assert name not in found
                found[name] = number(node.value)
    assert set(found) == set(names)
    return found


def borrowed_helper_source_example(path):
    tree = ast.parse(path.read_bytes())
    observe = next(node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name == 'observe')
    assignments = [node for node in ast.walk(observe) if isinstance(node, ast.Assign)
                   and any(isinstance(target, ast.Name) and target.id == 'helper_settled' for target in node.targets)]
    assert len(assignments) == 1
    expression = ast.Expression(body=assignments[0].value)

    def forbidden():
        raise AssertionError('borrowed-helper branch unexpectedly queries shutdown')

    # Evaluate only the actual assignment expression with inert stand-ins.
    # Never import the observer or call a native/process/filesystem method.
    value = eval(compile(expression, str(path.relative_to(ROOT)), 'eval'), {'__builtins__':{}},
                 dict(stop_session=False, session=types.SimpleNamespace(submitted=True, stopped=forbidden),
                      capture={'retained_result':True}))
    assert value is True
    events = [node for node in ast.walk(observe) if isinstance(node, ast.Call)
              and isinstance(node.func, ast.Attribute) and node.func.attr == 'record'
              and node.args and isinstance(node.args[0], ast.Constant) and node.args[0].value == 'settled']
    assert len(events) == 1
    fields = {item.arg:item.value for item in events[0].keywords}
    evaluate = lambda node:eval(compile(ast.Expression(body=node), str(path.relative_to(ROOT)), 'eval'),
                              {'__builtins__':{}}, {'stop_session':False})
    assert evaluate(fields['helper_stopped']) is False
    assert evaluate(fields['helper_shutdown_owner']) == 'caller'
    evidence = next(node for node in tree.body if isinstance(node, ast.ClassDef) and node.name == 'Evidence')
    retention = next(node for node in evidence.body if isinstance(node, ast.FunctionDef) and node.name == 'retain_sources')
    calls = [node for node in ast.walk(retention) if isinstance(node, ast.Call)
             and isinstance(node.func, ast.Name) and node.func.id == 'read_local_file']
    assert len(calls) == 1 and ast.unparse(calls[0].args[0]) == "self.root / record['path']"
    return dict(source=str(path.relative_to(ROOT)), settled_assignment_line=assignments[0].lineno,
                settled_event_line=events[0].lineno, archive_reopen_line=calls[0].lineno,
                borrowed_helper_branch_settled=True, helper_stopped=False,
                helper_shutdown_owner='caller', native_or_product_execution=False)


SELECTION = [dict(work_id='capture', ownership_token='a'*64, role='capture'),
             dict(work_id='helper', ownership_token='b'*64, role='helper')]
OWNER_STATES = {
    'missing':None,
    'running':('completed', 1, 0, 0),
    'unreaped':('failed', 1, 0, 1),
    'group_survives':('cancelled', 1, 1, 0),
    'success':('completed', 1, 1, 1),
    'failed':('failed', 1, 1, 1),
    'cancelled':('cancelled', 1, 1, 1),
    'never_started':('cancelled', 0, 0, 1),
}
# The oracle uses the declared state domain, not the implementation predicate.
SETTLED_STATES = {'success', 'failed', 'cancelled', 'never_started'}


def receipts(tags):
    rows = []
    for selected, tag in zip(SELECTION, tags):
        values = OWNER_STATES[tag]
        if values is None:
            continue
        outcome, started, reaped, gone = values
        rows.append(dict(selected, outcome=outcome,
                         cleanup=dict(leader_started=started, leader_reaped=reaped, group_gone=gone)))
    return rows


def main():
    contract = json.loads((BASE/'contract.json').read_bytes())
    assert contract['status'] == 'prospective_before_implementation'
    for pin in contract['inputs']:
        path = ROOT/pin['path']; raw = path.read_bytes()
        assert not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
        assert raw == subprocess.check_output(['git', 'show', contract['source_revision']+':'+pin['path']], cwd=ROOT)
    canonical = json.loads((BASE.parent/'native-proxy-canonical-contract-20260910/contract.json').read_bytes())
    inherited = contract['inherited_bounds']
    for name in ('source_bytes_each', 'reference_bytes_each', 'coordination_wait_seconds', 'coordination_poll_seconds'):
        assert inherited[name] == canonical['bounds'][name]
    observer = ROOT/'scripts/observe_fixture_startup.py'
    archive_limits = constants(observer, {'MAX_SOURCE_FILES', 'MAX_SOURCE_BYTES'})
    assert inherited['archive_unique_files'] == archive_limits['MAX_SOURCE_FILES']
    assert inherited['archive_total_bytes'] == archive_limits['MAX_SOURCE_BYTES']
    request_limit = constants(ROOT/'scripts/fixture_kernel_sampler.py', {'MAX_REQUESTS'})['MAX_REQUESTS']
    selected = contract['selected_inert_bounds']
    assert selected['work_entries'] == model.WORK_LIMIT == request_limit+1
    assert selected['selection_bytes'] == model.SELECTION_BYTES
    assert selected['receipt_bytes_each'] == model.RECEIPT_BYTES
    assert selected['work_id_bytes'] == 64
    source_example = borrowed_helper_source_example(observer)

    fields = ['archive_bytes_match', 'archive_identity_matches', 'selection_sealed',
              'exact_hold', 'private_present', 'failure_after_unlink']
    count = admitted_count = returned_count = 0
    examples = {}
    mutants = ['ignore_archive_bytes', 'ignore_archive_identity', 'ignore_selection_seal',
               'ignore_hold_identity', 'ignore_helper_cleanup', 'ignore_group_cleanup',
               'ignore_reaping', 'accept_partial_roster']
    witnesses = {}
    for tags in itertools.product(OWNER_STATES, repeat=2):
        for flags in itertools.product((False, True), repeat=len(fields)):
            state = dict(zip(fields, flags), selection=SELECTION, receipts=receipts(tags))
            wanted = all(flags[:4]) and all(tag in SETTLED_STATES for tag in tags)
            result = model.release(state)
            assert result['admitted'] is wanted
            assert result['returned'] is (wanted and not state['failure_after_unlink'])
            assert result['hold_present'] is (not wanted)
            assert result['other_hold_present'] is True and result['image_present'] is True
            assert result['outcomes'] == [OWNER_STATES[tag][0] for tag in tags if OWNER_STATES[tag] is not None]
            count += 1; admitted_count += wanted; returned_count += result['returned']
            for mutant in mutants:
                if mutant not in witnesses and not wanted and model.release(state, mutant=mutant)['admitted']:
                    witnesses[mutant] = dict(owner_states=tags, predicates=dict(zip(fields, flags)))
            if wanted and tags == ('failed', 'cancelled'):
                examples[str((state['private_present'], state['failure_after_unlink']))] = result
    assert set(witnesses) == set(mutants)

    good = dict(zip(fields, [True, True, True, True, False, False]),
                selection=copy.deepcopy(SELECTION), receipts=receipts(('success', 'success')))
    rejected = []
    changes = [
        ('duplicate receipt', lambda x:x['receipts'].append(copy.deepcopy(x['receipts'][0]))),
        ('extra receipt', lambda x:x['receipts'].append(dict(x['receipts'][0], work_id='other'))),
        ('duplicate selection', lambda x:x['selection'].append(copy.deepcopy(x['selection'][0]))),
        ('reordered receipts', lambda x:x['receipts'].reverse()),
        ('reordered selection', lambda x:x['selection'].reverse()),
        ('missing selection', lambda x:x.update(selection=[])),
        ('owner token replaced', lambda x:x['receipts'][0].update(ownership_token='c'*64)),
        ('work role replaced', lambda x:x['receipts'][0].update(role='query')),
        ('boolean cleanup flag', lambda x:x['receipts'][0]['cleanup'].update(group_gone=True)),
        ('missing cleanup flag', lambda x:x['receipts'][0]['cleanup'].pop('leader_reaped')),
        ('unknown cleanup field', lambda x:x['receipts'][0]['cleanup'].update(pid_absent=True)),
        ('invalid scalar spelling', lambda x:x['receipts'][0]['cleanup'].update(group_gone='01')),
        ('unknown outcome', lambda x:x['receipts'][0].update(outcome='assumed')),
        ('legacy settled event', lambda x:x['receipts'][1].update(helper_stopped=False, helper_shutdown_owner='caller')),
    ]
    for name, change in changes:
        state = copy.deepcopy(good); change(state)
        assert not model.release(state)['admitted'], name
        if name == 'owner token replaced':
            assert model.release(state, mutant='ignore_owner_token')['admitted']
            witnesses['ignore_owner_token'] = dict(control=name)
        rejected.append(name)
    # Existing scalar string spellings remain accepted without conflating JSON
    # booleans or a successful exit status with complete cleanup.
    state = copy.deepcopy(good)
    for row in state['receipts']:
        row['cleanup'] = {key:str(value) for key,value in row['cleanup'].items()}
    assert model.release(state)['admitted']
    maximum = copy.deepcopy(good)
    maximum['selection'] = [dict(work_id='x'*62+f'{index:02d}',
                                 ownership_token=f'{index:064x}', role='capture')
                            for index in range(model.WORK_LIMIT)]
    maximum['receipts'] = [dict(row, outcome='completed',
                               cleanup=dict(leader_started=1, leader_reaped=1, group_gone=1))
                          for row in maximum['selection']]
    assert model.release(maximum)['admitted']
    excess = copy.deepcopy(maximum)
    excess['selection'].append(dict(excess['selection'][0], work_id='extra'))
    excess['receipts'].append(dict(excess['receipts'][0], work_id='extra'))
    assert not model.release(excess)['admitted']
    rejected.append('work roster exceeds selected envelope')
    excess = copy.deepcopy(maximum)
    for row in (excess['selection'][0], excess['receipts'][0]):
        row['work_id'] += 'x'
    assert not model.release(excess)['admitted']
    rejected.append('work ID exceeds selected envelope')
    report = dict(schema='fsmgen.inactive_observation_release_contract_audit.v1', success=True,
        inputs_unchanged=len(contract['inputs']), inherited_bounds=inherited,
        selected_inert_bounds=selected, source_example=source_example,
        abstract_scenarios=count, admitted_scenarios=admitted_count, returned_successfully=returned_count,
        rejected_record_controls=rejected, mutant_counterexamples=witnesses,
        maximum_model_roster=dict(entries=len(maximum['selection']), work_id_bytes=64,
                                  selection_bytes=len(model.canonical(maximum['selection']))),
        failed_cancelled_examples=examples,
        limits='This is a finite symbolic selection check with two declared work slots and supplied archive/hold predicates. It never allocates a fixture, opens an archive or hold, launches work, or establishes native ownership, loaded-image identity or transport completeness. File custody, concrete closed schemas and release errors need the owned implementation children. The structural work envelope is selected, not a measured production profile.')
    (LOG/'audit.json').write_text(json.dumps(report, indent=2, sort_keys=True)+'\n')
    print(json.dumps(dict(success=True, inputs=report['inputs_unchanged'],
                         scenarios=count, admitted=admitted_count, returned=returned_count,
                         mutants=len(witnesses), record_controls=len(rejected)), sort_keys=True))


if __name__ == '__main__':
    main()
