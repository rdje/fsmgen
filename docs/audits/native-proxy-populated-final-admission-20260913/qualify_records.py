"""Pure cross-language record and fixed-admission checks; no filesystem fixtures."""
import copy
import json

from contract import ROOT, WORKER_CONTRACT, cases, validate_fixed_contract, worker_sources
import records


def qualify():
    checks, rejected = [], []

    def check(name, value):
        if not value or name in checks:
            raise AssertionError(name)
        checks.append(name)

    def reject(name, operation):
        try:
            operation()
        except (ValueError, KeyError, TypeError):
            rejected.append(name)
        else:
            raise AssertionError('altered record accepted: ' + name)

    limits = validate_fixed_contract()
    check('fixed cases and worker count', limits['case_count'] == 6 and limits['workers'] == 15)
    check('fixed completed and cancelled steps', limits['declared_steps'] == 47 and limits['held_cancellations'] == 2)
    check('small source-bound commands', limits['largest_command_bytes'] <= limits['command_bytes'])
    pins = worker_sources()
    check('complete compile-derived source set fits worker envelope', len(pins) == 25
          and len({row['path'] for row in pins}) == len(pins) and all(row['size_bytes'] <= 65536 for row in pins))
    vector = json.loads((ROOT / 'docs/audits/native-proxy-image-custody-20260910/vectors.json').read_bytes())
    check('image key matches the committed Perl vector', records.image_key(bytes.fromhex(vector['generated_c_hex']), bytes.fromhex(vector['image_hex'])) == vector['key'])
    check('manifest matches the committed Perl vector', records.payload('a')['sources']['image.json'].decode() == vector['manifest'])
    check('runtime key matches the committed Perl vector', records.runtime_key(vector['workspace']) == vector['runtime_reference_key'])
    check('Unicode observation key matches the committed Perl vector', records.observation_key(vector['evidence_directory'], vector['observer_birth'], vector['target_birth']) == vector['observation_reference_key'])
    previous = json.loads((ROOT / WORKER_CONTRACT).with_name('qualification.json').read_bytes())
    counts = dict(runtime_acquisitions=0, observation_acquisitions=0)
    for plan, case in zip(cases(), previous['cases']):
        publications = {row['role']: row['result']['result']['value'] for row in case['trace']
                        if row['kind'] == 'result' and row['operation'] == 'publish'}
        activation = dict(store={'path': plan['store'], 'device': 7, 'inode': 101},
            workspaces={role: value['reference']['record']['workspace_identity'] for role, value in publications.items()})
        for role, acquired in publications.items():
            records.runtime(plan, activation, role, acquired, acquired['lock'])
            counts['runtime_acquisitions'] += 1
            for name, mutation in [
                    ('source octets', lambda value: value['image']['snapshots'][0].update(bytes_hex='00')),
                    ('manifest digest', lambda value: value['image']['snapshots'][2]['identity'].update(sha256='0' * 64)),
                    ('runtime authority', lambda value: value.update(runtime_authorized=1)),
                    ('runtime owner', lambda value: value['reference']['record']['workspace_identity'].update(inode=0)),
                    ('private reference bytes', lambda value: value['reference']['private'].update(bytes_hex='00'))]:
                bad = copy.deepcopy(acquired)
                mutation(bad)
                reject(case['name'] + ' ' + role + ' ' + name,
                       lambda bad=bad: records.runtime(plan, activation, role, bad, acquired['lock']))
        for row in case['trace']:
            if row['kind'] != 'result' or row['operation'] != 'observe':
                continue
            acquired = row['result']['result']['value']
            record = acquired['observation_reference']['record']
            activation.update(evidence=record['evidence_directory_identity'], births={
                'observer': record['observer_birth'], plan['observation_target']: record['target_birth']})
            target = publications[plan['observation_target']]
            records.observation(plan, activation, acquired, acquired['lock'], target)
            counts['observation_acquisitions'] += 1
            check(case['name'] + ' archive keeps four unique original octet strings', len(records.archive_sources(acquired)) == 4)
            for name, mutation in [
                    ('observer birth', lambda value: value['observation_reference']['record']['observer_birth'].update(start_usec=0)),
                    ('wrapper octets', lambda value: value['target_sources'][0].update(bytes_hex='00')),
                    ('original reference pair', lambda value: value['target_sources'].__setitem__(1, value['target_sources'][2])),
                    ('observation authority', lambda value: value.update(runtime_authorized=1))]:
                bad = copy.deepcopy(acquired)
                mutation(bad)
                reject(case['name'] + ' ' + name,
                       lambda bad=bad: records.observation(plan, activation, bad, acquired['lock'], target))
    check('all original model runtime acquisitions rederived', counts['runtime_acquisitions'] == 9)
    check('all original model observation acquisitions rederived', counts['observation_acquisitions'] == 3)
    for value in (True, -1, 1.5, '1', 9223372036854775808):
        reject('noncanonical integer ' + repr(value), lambda value=value: records.integer(value))
    for value in ('0', 'FF', 'gg', ['00']):
        reject('noncanonical octets ' + repr(value), lambda value=value: records.octets(value))
    return dict(schema='fsmgen.inactive_populated_record_qualification.v1', checks=checks, rejected=rejected,
        counts=counts, prospective_bounds=limits, actual_worker_execution=False, actual_fixture_allocation=False,
        scope='Independent fixed records and source bounds; driver, filesystem and actual native proof are separate obligations.')


if __name__ == '__main__':
    print(json.dumps(qualify(), sort_keys=True, indent=2))
