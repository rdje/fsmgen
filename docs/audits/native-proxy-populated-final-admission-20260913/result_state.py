"""Validate fixed operation results against original custody before advancing."""
import copy
import hashlib

from contract import CONTRACT, canonical
import records


def equal(value, expected, message):
    # Canonical bytes distinguish booleans from the protocol's integer flags.
    if canonical(value) != canonical(expected):
        raise ValueError(message)


def archive(value, acquired, activation):
    records.fields(value, 'schema runtime_authorized executable evidence_directory_identity archive_directory_identity observation_reference_key source_bindings')
    records.inactive(value, 'fsmgen.inactive_observation_archive.v1')
    records.directory(value['evidence_directory_identity'], activation['evidence'])
    directory = value['archive_directory_identity']
    records.directory(directory, dict(path=activation['evidence']['path'] + '/retained-sources',
        device=activation['evidence']['device'], inode=records.integer(directory['inode'])))
    if value['observation_reference_key'] != acquired['observation_reference']['record']['reference_key']:
        raise ValueError('archive names a different original observation')
    bindings = value['source_bindings']
    if not isinstance(bindings, list) or len(bindings) != 5:
        raise ValueError('archive lacks exact original source roles')
    original_archives = {}
    for binding, role, source in zip(bindings, ('wrapper', 'private_reference', 'global_reference', 'c', 'image'), acquired['target_sources']):
        records.fields(binding, 'role source archive')
        if binding['role'] != role or binding['source'] != source['identity']:
            raise ValueError('archive source role or original identity differs')
        identity = binding['archive']
        body = records.octets(source['bytes_hex'])
        path = directory['path'] + '/' + source['identity']['sha256'] + '.source'
        records.snapshot(dict(identity=identity, bytes_hex=body.hex()), path, directory['device'], body)
        if path in original_archives and original_archives[path] != identity:
            raise ValueError('duplicate source roles lost their shared archive identity')
        original_archives[path] = identity
    if len(original_archives) != len(records.archive_sources(acquired)):
        raise ValueError('archive has missing or extra retained octet strings')


def synthetic_settlement(case, acquired):
    # These inputs are fixed inactive work selections, not actual child receipts.
    entries = [dict(work_id='observer:' + role, role=role,
        ownership_token=hashlib.sha256(('inactive-populated:' + case['name'] + ':observer:' + role).encode()).hexdigest())
        for role in ('capture', 'helper', 'query')]
    receipts = [dict(**entry, outcome=outcome, cleanup=dict(leader_started=1, leader_reaped=1, group_gone=1))
        for entry, outcome in zip(entries, ('completed', 'failed', 'cancelled'))]
    return entries, receipts


class CaseState:
    def __init__(self, case, activation, permanent_lock):
        self.case, self.activation, self.lock = copy.deepcopy((case, activation, permanent_lock))
        self.images, self.runtimes, self.observations, self.archives = {}, {}, {}, {}
        self.retired, self.released = set(), set()
        self.original_runtime, self.original_observation = {}, None
        self.packets, self.results = {}, {}

    def expected_paths(self):
        case = self.case
        paths = {case['store'], case['store'] + '/images', case['store'] + '/references', case['store'] + '/coordination.lock'}
        for role, workspace in case['workspaces'].items():
            if role not in self.retired:
                paths.update((workspace, workspace + '/rust-tools', workspace + '/rust-tool-resolution'))
        for image in self.images.values():
            paths.add(case['store'] + '/images/' + image['key'])
            paths.update(source['identity']['path'] for source in image['snapshots'])
        for role, acquired in self.original_runtime.items():
            if role not in self.retired:
                paths.update(acquired['reference'][kind]['identity']['path'] for kind in ('global', 'private'))
        if self.original_observation is not None and not self.released:
            paths.add(self.original_observation['observation_reference']['source']['identity']['path'])
        if case['evidence']:
            paths.add(case['evidence'])
            for value in self.archives.values():
                paths.add(value['archive_directory_identity']['path'])
                paths.update(binding['archive']['path'] for binding in value['source_bindings'])
        return paths

    def check_snapshot(self, snapshot):
        if set(snapshot['nodes']) != self.expected_paths():
            raise ValueError('observed fixture closure differs from independently tracked original owners')
        absent = {path for role, path in self.case['workspaces'].items() if role in self.retired}
        if set(snapshot['absent_roots']) != absent:
            raise ValueError('absent fixture roots differ from completed retirements')

    def accept(self, role, step, response):
        records.fields(response, 'step operation value handoff synthetic_retirement_and_work_records')
        if (response['step'] != step['id'] or response['operation'] != step['operation']
                or type(response['synthetic_retirement_and_work_records']) is not int
                or response['synthetic_retirement_and_work_records'] != 1 or (role, step['id']) in self.results):
            raise ValueError('result differs from the single selected step')
        value, op = response['value'], step['operation']
        selected = records.payload(step['image'])
        # Validate the whole result before mutating any custody map.
        if op == 'publish':
            records.runtime(self.case, self.activation, role, value, self.lock)
            image = value['image']
            if value['created'] != int(image['key'] not in self.images) or role in self.original_runtime:
                raise ValueError('publication creation or owner differs')
            if image['key'] in self.images:
                equal(image, self.images[image['key']], 'equal publication replaced original image custody')
        elif op == 'observe':
            if self.original_observation is not None or self.case['observation_target'] in self.retired:
                raise ValueError('observation must acquire its original live target once')
            records.observation(self.case, self.activation, value, self.lock, self.original_runtime[self.case['observation_target']])
        elif op == 'retire':
            acquired = self.runtimes[role]
            original_role = next(name for name, original in self.original_runtime.items() if original == acquired)
            if original_role in self.retired:
                raise ValueError('runtime owner was already retired')
            equal(value, dict(schema='fsmgen.inactive_runtime_retirement.v1', runtime_authorized=0, executable=None,
                lock=self.lock, image=acquired['image'], released_reference=acquired['reference']['global']['identity']['path'],
                retired_workspace=acquired['reference']['record']['workspace'], removed_nodes=4), 'retirement changes original custody or fixed workspace closure')
        elif op == 'maintain_blocked':
            retained = {acquired['image']['key'] for name, acquired in self.original_runtime.items() if name not in self.retired}
            if self.original_observation is not None and not self.released:
                retained.add(self.original_observation['observation_reference']['record']['image_key'])
            if selected['key'] not in retained or selected['key'] not in self.images:
                raise ValueError('maintenance rejection has no remaining original owner')
            equal(value, dict(expected_rejection=CONTRACT['maintenance_rejection'], image_key=selected['key']), 'maintenance did not preserve its exact denial')
        elif op == 'maintain':
            if any(acquired['image']['key'] == selected['key'] for name, acquired in self.original_runtime.items() if name not in self.retired):
                raise ValueError('maintenance would remove a runtime-owned image')
            if self.original_observation is not None and not self.released and self.original_observation['observation_reference']['record']['image_key'] == selected['key']:
                raise ValueError('maintenance would remove an observation-owned image')
            equal(value, dict(schema='fsmgen.inactive_image_maintenance.v1', runtime_authorized=0, executable=None,
                lock=self.lock, removed_image=selected['key'], removed_sources=self.images[selected['key']]['snapshots']), 'maintenance removed different original sources')
        elif op == 'archive':
            acquired = self.observations[role]
            if set(self.retired) != set(self.case['workspaces']) or role in self.archives:
                raise ValueError('archive must preserve original sources after all workspaces retire')
            archive(value, acquired, self.activation)
        elif op == 'release':
            acquired = self.observations[role]
            records.fields(value, 'schema runtime_authorized executable success error unlink_attempted unlink_completed reference_absence_verified last_reference_check release')
            records.inactive(value, 'fsmgen.inactive_observation_release_attempt.v1')
            receipt = value['release']
            records.fields(receipt, 'schema runtime_authorized executable lock released_reference image archive settlement')
            records.inactive(receipt, 'fsmgen.inactive_observation_release.v1')
            key = acquired['observation_reference']['record']['image_key']
            equal({name: item for name, item in value.items() if name != 'release'},
                dict(schema='fsmgen.inactive_observation_release_attempt.v1', runtime_authorized=0, executable=None,
                    success=1, error='', unlink_attempted=1, unlink_completed=1, reference_absence_verified=1,
                    last_reference_check=dict(phase='finish', state='absent')), 'release lacks a successful original-reference absence receipt')
            equal({name: item for name, item in receipt.items() if name != 'settlement'},
                dict(schema='fsmgen.inactive_observation_release.v1', runtime_authorized=0, executable=None, lock=self.lock,
                    released_reference=acquired['observation_reference']['source']['identity']['path'],
                    image=self.images[key], archive=self.archives[role]), 'release receipt changes original custody')
            # Detailed fixed selection/settlement validation is supplied below;
            # the native child cancellation receipt belongs to the driver.
            validate_settlement(self.case, acquired, receipt['settlement'])
            if self.released:
                raise ValueError('observation was already released')
        elif op in ('adopt_runtime', 'adopt_observation'):
            kind = op.removeprefix('adopt_')
            packet = next(packet for packet in self.packets.values() if packet['kind'] == kind)
            equal(value, dict(adopted=kind, source_role=packet['source_role'], filesystem_reconstruction=0), 'adoption changed the original handoff source')
            if role in (self.runtimes if kind == 'runtime' else self.observations):
                raise ValueError('recovery peer already owns an acquisition')
        else:
            raise ValueError('a cancelled held inspection must never return an operation result')
        packet = None
        if op in ('publish', 'observe'):
            kind = 'runtime' if op == 'publish' else 'observation'
            packet = dict(schema='fsmgen.inactive_populated_handoff.v1', case=self.case['name'], source_role=role, kind=kind, acquired=value)
            if kind == 'observation':
                packet['request'] = dict(workspace_identity=self.activation['workspaces'][self.case['observation_target']],
                    evidence_directory_identity=self.activation['evidence'], observer_birth=self.activation['births']['observer'],
                    target_birth=self.activation['births'][self.case['observation_target']])
        equal(response['handoff'], packet, 'result handoff does not retain the exact original acquisition')
        if op == 'publish':
            self.images[value['image']['key']] = copy.deepcopy(value['image'])
            self.runtimes[role] = self.original_runtime[role] = copy.deepcopy(value)
        elif op == 'observe':
            self.observations[role] = self.original_observation = copy.deepcopy(value)
        elif op == 'retire':
            self.retired.add(original_role)
        elif op == 'maintain':
            del self.images[selected['key']]
        elif op == 'archive':
            self.archives[role] = copy.deepcopy(value)
        elif op == 'release':
            self.released.add(role)
        elif op.startswith('adopt_'):
            kind = op.removeprefix('adopt_')
            original = next(packet for packet in self.packets.values() if packet['kind'] == kind)
            (self.runtimes if kind == 'runtime' else self.observations)[role] = copy.deepcopy(original['acquired'])
        if packet is not None:
            self.packets[(role, step['id'])] = copy.deepcopy(packet)
        self.results[(role, step['id'])] = copy.deepcopy(response)
        return value


def validate_settlement(case, acquired, value):
    entries, receipts = synthetic_settlement(case, acquired)
    record = acquired['observation_reference']['record']
    selection = dict(schema='fsmgen.inactive_observation_work_selection.v1', runtime_authorized=0, executable=None,
        evidence_directory_identity=record['evidence_directory_identity'],
        observation_reference_key=record['reference_key'], entries=entries)
    equal(value, dict(schema='fsmgen.inactive_observation_work_settlement.v1', runtime_authorized=0, executable=None,
        selection=selection, selection_sealed=1, receipts=receipts), 'settlement differs from the fixed original synthetic selection and receipts')
