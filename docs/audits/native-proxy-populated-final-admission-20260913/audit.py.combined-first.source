"""Re-derive the source-only admission; no permit, worker or fixture is created."""
import argparse
import hashlib
import json

from build_plan import build
from contract import BASE, ROOT, OWNER, EXECUTION_OWNER, SCOPE, canonical, worker_sources
import qualify_records
import qualify_files
import qualify_owned_case
import qualify_result_state
import qualify_admission
import qualify_oracle
import qualify_envelope
import qualify_sources
import qualify_bounds
import source_inventory


def read(name):
    return json.loads((BASE / name).read_bytes())


def retained_sources():
    selected = {}
    for name in source_inventory.EVIDENCE:
        value = read(name)
        if name == 'worker-sources.json':
            if not isinstance(value, list):
                raise ValueError('worker source inventory lost its declared list shape')
            continue
        if not isinstance(value, dict):
            raise ValueError('retained evidence lost its object envelope: ' + name)
        for row in value.get('sources', []):
            body = (ROOT / row['path']).read_bytes()
            if len(body) != row['size_bytes'] or hashlib.sha256(body).hexdigest() != row['sha256']:
                raise ValueError('retained first source differs: ' + row['path'])
            if row['path'] in selected and selected[row['path']] != row:
                raise ValueError('first-source manifests disagree about original custody')
            selected[row['path']] = row
    for name, marker in [('owned-first.json', 'identical replacement does not inherit retained custody: unexpectedly accepted'),
                          ('owned-expanded.json', 'retained image cannot lose its final seal: unexpectedly accepted')]:
        value = read(name)
        if value['outputs']['exit'] != '1\n' or marker not in value['outputs']['stderr']:
            raise ValueError('first cleanup defect was omitted or normalized')
    inventory_failure = read('inventory-first.json')
    empty = inventory_failure['failed_output']
    if inventory_failure['first_result']['exit_code'] != 1 or (ROOT / empty['path']).read_bytes() != b'' or empty['size_bytes'] != 0:
        raise ValueError('first inventory-build failure or empty output was not retained')
    for name in ('records-first.json', 'files-first.json', 'owned-custody.json', 'owned-seals.json', 'owned-archives.json',
                 'state-first.json', 'admission-first.json', 'driver-first.json', 'oracle-first.json', 'envelope-first.json', 'git-first.json',
                 'sources-first.json', 'bounds-first.json'):
        value = read(name)
        if value['outputs']['exit'] != '0\n' or json.loads(value['outputs']['stdout']) != value['result']:
            raise ValueError('retained source-model result changed: ' + name)
    return sorted(selected)


def rederive():
    if read('plan.json') != build():
        raise ValueError('inactive plan no longer rederives from fixed scenarios and selected inputs')
    first_sources = retained_sources()
    inventory = read('compile-inventory-first.json')
    if inventory['worker_runtime_entered'] or not inventory['selected_project_source_closure_verified']:
        raise ValueError('compile-only inventory was promoted or lost its selected-source verification')
    if len(worker_sources()) != 25 or any(row['size_bytes'] > 65536 for row in worker_sources()):
        raise ValueError('worker source closure no longer fits its qualified reader')
    qualification = dict(records=qualify_records.qualify(), files=qualify_files.qualify(), owned_tree=qualify_owned_case.qualify(),
        lifetime_results=qualify_result_state.qualify(), admission=qualify_admission.qualify(),
        oracle=qualify_oracle.qualify(), envelope=qualify_envelope.qualify(),
        source_authentication=qualify_sources.qualify(), bounds=qualify_bounds.qualify())
    for name, value in qualification.items():
        if value['actual_worker_execution'] is not False or value['actual_fixture_allocation'] is not False:
            raise ValueError('source-only qualification promoted an actual fixture or worker: ' + name)
    summary = dict(owner=OWNER, next_owner=EXECUTION_OWNER, selected_prior_revision=SCOPE['source_revision'],
        source_pins_sha256=hashlib.sha256((BASE / 'execution-source-pins.json').read_bytes()).hexdigest(),
        qualification_sha256=hashlib.sha256(canonical(qualification)).hexdigest(),
        retained_first_sources=len(first_sources), repaired_first_cleanup_defects=2,
        counts=qualification['oracle']['counts'], prospective_geometry=qualification['bounds']['derived'],
        selected_worker_sources=len(worker_sources()), selected_installed_perl_modules=len(inventory['inventory']['installed_modules']),
        qualification_checks={name: len(value.get('checks', [])) for name, value in qualification.items()},
        rejecting_controls={name: len(value.get('rejecting_controls', value.get('rejected', []))) for name, value in qualification.items()},
        actual_worker_execution=False, actual_fixture_allocation=False, actual_permit_issued=False,
        synthetic_retirement_and_work_records=True, native_live_startup_qualification_open=True)
    return qualification, summary


def verify_saved():
    if source_inventory.pins() != read('execution-source-pins.json'):
        raise ValueError('selected execution or source-qualification input bytes changed')
    qualification, summary = rederive()
    if qualification != read('qualification.json') or summary != read('review.json'):
        raise ValueError('saved source admission does not reconstruct exactly')
    return summary


def save():
    if source_inventory.pins() != read('execution-source-pins.json'):
        raise ValueError('pin the complete selected source inputs before saving qualification')
    qualification, summary = rederive()
    for name, value in [('qualification.json', qualification), ('review.json', summary)]:
        with (BASE / name).open('x') as stream:
            json.dump(value, stream, sort_keys=True, indent=2)
            stream.write('\n')
    return summary


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument('--save', action='store_true')
    selection.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    print(json.dumps(save() if args.save else verify_saved(), sort_keys=True, indent=2))
