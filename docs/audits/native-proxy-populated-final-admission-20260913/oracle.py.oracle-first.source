"""Independent journal/stream/identity join; never launches or removes anything."""
import copy
import errno
import hashlib
import json
from pathlib import PurePosixPath
import signal

from contract import CONTRACT, OUTPUT, WORKER, bounds, canonical
import records


def require(condition, message):
    if not condition:
        raise ValueError(message)


def same(left, right):
    return canonical(left) == canonical(right)


def lines(body, byte_limit, row_limit, row_bytes=None):
    require(isinstance(body, bytes) and len(body) <= byte_limit and body.endswith(b'\n'), 'missing or unbounded canonical event stream')
    result = []
    for raw in body.splitlines(keepends=True):
        require(len(result) < row_limit, 'event row count exceeded')
        require(len(raw) <= (byte_limit if row_bytes is None else row_bytes), 'event row byte bound exceeded')
        value = json.loads(raw)
        require(raw == canonical(value) + b'\n', 'event bytes are not exact canonical JSON')
        result.append(value)
    return result


def journal_rows(body):
    limits = bounds()
    rows = lines(body, limits['journal_bytes'], limits['journal_events'])
    elapsed = 0
    for index, row in enumerate(rows):
        require(type(row.get('sequence')) is int and row['sequence'] == index, 'controller journal sequence is incomplete')
        require(type(row.get('elapsed_ns')) is int and row['elapsed_ns'] >= elapsed, 'controller journal clock regressed')
        elapsed = row['elapsed_ns']
        require(isinstance(row.get('event'), str), 'journal event name is absent')
    return rows


def one(rows, event, role=None):
    found = [row for row in rows if row['event'] == event and (role is None or row.get('role') == role)]
    require(len(found) == 1, 'missing or repeated ' + event + ' for ' + str(role))
    return found[0]


def expected_commands(case, activation_bytes, handoff_bytes):
    result = []
    digest = lambda body: hashlib.sha256(body).hexdigest()
    add = lambda role, name, value: result.append(dict(role=role, command=name, payload=value))
    for role in case['roles']:
        add(role, 'admit', dict(activation_sha256=digest(activation_bytes)))
    for action in case['actions']:
        if action['kind'] in ('run', 'cancel'):
            role = action['role']
            step = next(step for step in case['roles'][role]['steps'] if step['id'] == action['step'])
            payload = dict(id=step['id'])
            if step['operation'].startswith('adopt_'):
                require(handoff_bytes is not None, 'adoption lacks original handoff bytes')
                payload['handoff_sha256'] = digest(handoff_bytes)
            add(role, 'step', payload)
            if step['coordinated']:
                add(role, 'lock', dict(id=step['id']))
        elif action['kind'] == 'contend':
            for role in (action['holder'], action['contender']):
                add(role, 'step', dict(id=action['step']))
            for role in (action['holder'], action['contender']):
                add(role, 'lock', dict(id=action['step']))
            add(action['holder'], 'release', dict(id=action['step']))
        elif action['kind'] == 'finish':
            for role in action['roles']:
                add(role, 'finish', None)
        else:
            require(action['kind'] == 'handoff', 'undeclared action kind')
    return result


class Lifetime:
    """Reconstruct live objects from original acquisition and release records."""
    def __init__(self, case, activation, initial):
        self.case, self.activation = case, activation
        self.directories, self.files = {}, {}
        self.images, self.runtimes, self.holds, self.archives = {}, {}, {}, {}
        self.originals, self.observation = {}, None
        self.workspaces = set(case['workspaces'].values())
        expected = {case['store'], case['store'] + '/images', case['store'] + '/references', case['store'] + '/coordination.lock'}
        for path in self.workspaces:
            expected.update((path, path + '/rust-tools', path + '/rust-tool-resolution'))
        if case['evidence']:
            expected.add(case['evidence'])
        require(set(initial) == expected, 'controller allocation omits or adds fixture nodes')
        for path, node in initial.items():
            identity = node['identity']
            require(identity['path'] == path, 'allocated node names a different object')
            if node['kind'] == 'directory':
                self.directories[path] = copy.deepcopy(identity)
            else:
                body = b'' if path.endswith('/coordination.lock') else records.octets(CONTRACT['payloads']['wrapper_hex'])
                require(node['bytes_hex'] == body.hex(), 'controller allocation changes fixed inert payload bytes')
                self.files[path] = copy.deepcopy(node)
        self.lock = {key: initial[case['store'] + '/coordination.lock']['identity'][key] for key in ('path', 'device', 'inode')}
        for directory in [activation['store'], *activation['workspaces'].values()] + ([activation['evidence']] if activation['evidence'] else []):
            require(all(self.directories[directory['path']][key] == directory[key] for key in ('path', 'device', 'inode')),
                    'activation changed an allocated root identity')

    def source(self, snapshot, mode=0o400):
        identity = snapshot['identity']
        body = records.snapshot(snapshot, identity['path'], self.activation['store']['device'])
        node = dict(kind='file', identity=dict(identity, mode=mode, uid=self.activation['births'][next(iter(self.case['roles']))]['uid'], links=1),
                    bytes_hex=body.hex(), partial_recovery=False)
        path = identity['path']
        require(path not in self.files or same(self.files[path], node), 'existing original source identity was replaced')
        self.files[path] = node

    def operation(self, role, step, response):
        op, value = step['operation'], response['value']
        require(response['step'] == step['id'] and response['operation'] == op and type(response['synthetic_retirement_and_work_records']) is int
                and response['synthetic_retirement_and_work_records'] == 1, 'operation response loses its fixed synthetic-record boundary')
        if op == 'publish':
            records.runtime(self.case, self.activation, role, value, self.lock)
            key = value['image']['key']
            require(value['created'] == int(key not in self.images), 'publication creation flag disagrees with original image lifetime')
            require(role not in self.originals, 'runtime acquisition repeated')
            self.images[key] = copy.deepcopy(value['image'])
            self.originals[role] = copy.deepcopy(value)
            self.runtimes[value['reference']['record']['reference_key']] = key
            self.directories.setdefault(self.case['store'] + '/images/' + key, None)
            for source in value['image']['snapshots']:
                self.source(source, 0o500 if source['identity']['path'].endswith('/rustup') else 0o400)
            for kind in ('private', 'global'):
                self.source(value['reference'][kind])
        elif op == 'observe':
            require(self.observation is None, 'observation acquisition repeated')
            records.observation(self.case, self.activation, value, self.lock, self.originals[self.case['observation_target']])
            self.observation = copy.deepcopy(value)
            record = value['observation_reference']['record']
            self.holds[record['reference_key']] = record['image_key']
            self.source(value['observation_reference']['source'])
            for index, source in enumerate(value['target_sources']):
                self.source(source, 0o700 if index == 0 else 0o500 if index == 4 else 0o400)
        elif op == 'retire':
            original = self.originals[role] if role in self.originals else self.originals['publisher']
            reference, workspace = original['reference'], original['reference']['record']['workspace']
            require(workspace in self.workspaces and reference['record']['reference_key'] in self.runtimes, 'retirement lacks original live runtime custody')
            require(same(value, dict(schema='fsmgen.inactive_runtime_retirement.v1', runtime_authorized=0, executable=None,
                lock=self.lock, image=original['image'], released_reference=reference['global']['identity']['path'],
                retired_workspace=workspace, removed_nodes=4)), 'retirement receipt changes original sources or workspace closure')
            self.workspaces.remove(workspace)
            del self.runtimes[reference['record']['reference_key']]
            for path in (workspace, workspace + '/rust-tools'):
                del self.directories[path]
            for path in (workspace + '/rust-tool-resolution', reference['private']['identity']['path'], reference['global']['identity']['path']):
                del self.files[path]
        elif op == 'maintain_blocked':
            key = records.payload(step['image'])['key']
            require(key in set(self.runtimes.values()) | set(self.holds.values()), 'blocked maintenance has no unresolved original owner')
            require(same(value, dict(expected_rejection=CONTRACT['maintenance_rejection'], image_key=key)), 'maintenance refusal was normalized or changed')
        elif op == 'maintain':
            key = records.payload(step['image'])['key']
            require(key in self.images and key not in set(self.runtimes.values()) | set(self.holds.values()), 'maintenance removes a missing or retained image')
            require(same(value, dict(schema='fsmgen.inactive_image_maintenance.v1', runtime_authorized=0, executable=None,
                lock=self.lock, removed_image=key, removed_sources=self.images[key]['snapshots'])), 'maintenance receipt changes original source identities')
            for source in self.images.pop(key)['snapshots']:
                del self.files[source['identity']['path']]
            del self.directories[self.case['store'] + '/images/' + key]
        elif op == 'archive':
            require(not self.workspaces and self.observation is not None, 'archive precedes retirement or original observation')
            records.inactive(value, 'fsmgen.inactive_observation_archive.v1')
            key = self.observation['observation_reference']['record']['reference_key']
            require(key in self.holds and key not in self.archives and value['observation_reference_key'] == key, 'archive changes observation lifetime')
            require(value['evidence_directory_identity'] == self.activation['evidence'] and len(value['source_bindings']) == 5, 'archive loses original evidence or roles')
            directory = value['archive_directory_identity']
            require(directory['path'] == self.case['evidence'] + '/retained-sources' and directory['device'] == self.activation['store']['device'], 'archive directory escapes its original owner')
            self.directories[directory['path']] = dict(directory, mode=0o700, uid=self.activation['births']['observer']['uid'])
            for binding, role_name, source in zip(value['source_bindings'], ('wrapper', 'private_reference', 'global_reference', 'c', 'image'), self.observation['target_sources']):
                require(binding['role'] == role_name and binding['source'] == source['identity'], 'archive replaces an original source binding')
                require(binding['archive']['path'] == directory['path'] + '/' + source['identity']['sha256'] + '.source', 'archive does not retain the original digest path')
                self.source(dict(identity=binding['archive'], bytes_hex=source['bytes_hex']))
            self.archives[key] = copy.deepcopy(value)
        elif op == 'release':
            original = self.observation
            key = original['observation_reference']['record']['reference_key']
            require(key in self.holds and key in self.archives, 'release lacks original hold and retained archive')
            receipt = value['release']
            records.fields(receipt, 'schema runtime_authorized executable lock released_reference image archive settlement')
            records.inactive(receipt, 'fsmgen.inactive_observation_release.v1')
            require(same({name: item for name, item in value.items() if name != 'release'},
                dict(schema='fsmgen.inactive_observation_release_attempt.v1', runtime_authorized=0, executable=None,
                    success=1, error='', unlink_attempted=1, unlink_completed=1, reference_absence_verified=1,
                    last_reference_check=dict(phase='finish', state='absent'))), 'release lacks exact final original-reference absence')
            require(receipt['lock'] == self.lock and receipt['released_reference'] == original['observation_reference']['source']['identity']['path']
                and same(receipt['image'], self.images[self.holds[key]]) and same(receipt['archive'], self.archives[key]), 'release receipt replaced original custody')
            entries, receipts = [], []
            for name, outcome in zip(('capture', 'helper', 'query'), ('completed', 'failed', 'cancelled')):
                entry = dict(work_id='observer:' + name, role=name,
                    ownership_token=hashlib.sha256(('inactive-populated:' + self.case['name'] + ':observer:' + name).encode()).hexdigest())
                entries.append(entry)
                receipts.append(dict(entry, outcome=outcome, cleanup=dict(leader_started=1, leader_reaped=1, group_gone=1)))
            selection = dict(schema='fsmgen.inactive_observation_work_selection.v1', runtime_authorized=0, executable=None,
                evidence_directory_identity=self.activation['evidence'], observation_reference_key=key, entries=entries)
            require(same(receipt['settlement'], dict(schema='fsmgen.inactive_observation_work_settlement.v1', runtime_authorized=0,
                executable=None, selection=selection, selection_sealed=1, receipts=receipts)), 'release changes fixed original synthetic work receipts')
            del self.holds[key]
            del self.files[receipt['released_reference']]
        else:
            require(op in ('adopt_runtime', 'adopt_observation'), 'cancelled inspection produced an operation result')
            expected_role = 'publisher' if op == 'adopt_runtime' else 'observer'
            require(same(value, dict(adopted=op.removeprefix('adopt_'), source_role=expected_role, filesystem_reconstruction=0)), 'adoption reconstructed or changed original custody')
        expected_handoff = None
        if op in ('publish', 'observe'):
            expected_handoff = dict(schema='fsmgen.inactive_populated_handoff.v1', case=self.case['name'],
                source_role=role, kind='runtime' if op == 'publish' else 'observation', acquired=value)
            if op == 'observe':
                expected_handoff['request'] = dict(workspace_identity=self.activation['workspaces'][self.case['observation_target']],
                    evidence_directory_identity=self.activation['evidence'], observer_birth=self.activation['births']['observer'],
                    target_birth=self.activation['births'][self.case['observation_target']])
        require(same(response['handoff'], expected_handoff), 'worker handoff did not retain exact original acquisition bytes')

    def snapshot(self, value):
        require(set(value['nodes']) == set(self.directories) | set(self.files), 'observed tree differs from independently reconstructed original owners')
        require(set(value['absent_roots']) == set(self.case['workspaces'].values()) - self.workspaces, 'snapshot loses a retired or live original root')
        require(value['file_bytes'] == sum(node['identity']['size_bytes'] for node in self.files.values()), 'snapshot file total differs from exact original bytes')
        for path, node in self.files.items():
            require(same(value['nodes'][path], node), 'snapshot changed original file bytes, identity or final mode')
        for path, identity in self.directories.items():
            node = value['nodes'][path]
            records.fields(node, 'kind identity')
            observed = node['identity']
            records.fields(observed, 'path device inode mode uid')
            require(node['kind'] == 'directory' and observed['path'] == path and observed['mode'] == 0o700
                and observed['uid'] == self.activation['births'][next(iter(self.case['roles']))]['uid']
                and observed['device'] == self.activation['store']['device'] and records.integer(observed['inode']) > 0,
                'snapshot directory is not a direct private original-volume object')
            if identity is None:
                self.directories[path] = copy.deepcopy(observed)
            else:
                require(same(observed, identity), 'snapshot directory replaced its first original identity')


def check_case(case, activation_bytes, rows, streams, outcome, interpreter, handoff_bytes=None):
    activation = json.loads(activation_bytes)
    require(activation_bytes == canonical(activation), 'activation bytes are not sealed canonical data')
    require(outcome['success'] is True and outcome['first_error'] is None and not outcome['recovery_errors'], 'case reports failure or incomplete recovery')
    require(same(outcome['activation'], activation) and set(outcome['outcomes']) == set(case['roles']), 'case outcome loses original native activation or a selected role')
    selected = one(rows, 'case_activated')
    require(same(selected['activation'], activation) and selected['source'] == dict(path=case['activation_path'], **records.file_pin(activation_bytes)), 'activation journal loses its exact sealed file')
    commands = expected_commands(case, activation_bytes, handoff_bytes)
    for name in ('command_intent', 'command_sent'):
        observed = [{key: row[key] for key in ('role', 'command', 'payload')} for row in rows if row['event'] == name]
        require(same(observed, commands), 'controller command transcript differs from the fixed schedule')
    started = [row for row in rows if row['event'] == 'action_started']
    completed = [row for row in rows if row['event'] == 'action_completed']
    require([row['index'] for row in started] == [row['index'] for row in completed] == list(range(len(case['actions']))), 'case has missing or repeated action boundaries')
    for index, (begin, end, action) in enumerate(zip(started, completed, case['actions'])):
        require(begin['action'] == action and begin['sequence'] < end['sequence'], 'action differs from its selected source or completion order')
        if index:
            require(completed[index - 1]['sequence'] < begin['sequence'], 'case began a new action before the preceding one completed')
    actual_events, responses = {}, {}
    initial = {row['node']['identity']['path']: row['node'] for row in rows if row['event'] == 'allocated'}
    require(len(initial) == sum(row['event'] == 'allocated' for row in rows), 'allocation repeated an original object')
    lifetime = Lifetime(case, activation, initial)
    cancellation_roles = {action['role'] for action in case['actions'] if action['kind'] == 'cancel'}
    contenders = {(action['contender'], action['step']) for action in case['actions'] if action['kind'] == 'contend'}
    for role, specification in case['roles'].items():
        birth = activation['births'][role]
        native = one(rows, 'controller_native_owned', role)
        admitted = one(rows, 'controller_native_admitted', role)
        launched = one(rows, 'controller_launched', role)
        launch = one(rows, 'controller_launch_intent', role)
        require(launch['script'] == WORKER and launch['arguments'] == [case['name'], role]
            and launched['pid'] == birth['pid'] and native['identity'] == admitted['identity'] == birth,
            'native worker receipt loses the selected script, role or original birth')
        require(admitted['image'] == interpreter['native_image']['binary'], 'native worker executable differs from the selected interpreter bytes')
        require(launch['sequence'] < launched['sequence'] < native['sequence'] < admitted['sequence'] < selected['sequence'], 'worker mutation authority precedes complete native admission')
        raw = streams[role]['stdout']
        events = lines(raw, bounds()['worker_output_bytes'], bounds()['worker_events'], bounds()['worker_event_bytes'])
        require(streams[role]['stderr'] == b'', 'successful worker has unaccounted stderr')
        emitted = [row for row in rows if row['event'] == 'controller_worker_event' and row['role'] == role]
        require(same([row['value'] for row in emitted], events), 'journal changed, omitted or invented original worker stream bytes')
        require(all(type(event.get('pid')) is int and event['pid'] == birth['pid'] for event in events), 'worker stream lost its native owner')
        expected_events = [('ready', None)]
        for step in specification['steps']:
            if step['coordinated']:
                expected_events += [(name, step['id']) for name in ['opened'] + (['busy'] if (role, step['id']) in contenders else []) + ['locked'] + (['held'] if step['hold'] else [])]
            if step['operation'] != 'hold_inspect':
                expected_events.append(('result', step['id']))
        if specification['ending'] == 'finish':
            expected_events.append(('finished', None))
        require([(event['event'], event['result']['step'] if event['event'] == 'result' else event.get('step')) for event in events]
            == expected_events, 'worker event lifecycle differs from its fixed role')
        for event, row in zip(events, emitted):
            step_name = event['result']['step'] if event['event'] == 'result' else event.get('step')
            actual_events[(role, step_name, event['event'])] = row
            if event['event'] == 'result':
                records.fields(event, 'event pid result lock')
                records.fields(event['result'], 'step operation value handoff synthetic_retirement_and_work_records')
                records.fields(event['lock'], 'opened busy_count descriptor_closed')
                step = next(step for step in specification['steps'] if step['id'] == step_name)
                require(type(event['lock']['descriptor_closed']) is int and event['lock']['descriptor_closed'] == 1
                    and type(event['lock']['opened']) is int and event['lock']['opened'] == step['coordinated']
                    and (records.integer(event['lock']['busy_count']) > 0) == ((role, step_name) in contenders), 'result lacks original lock closure or contention')
                responses[(role, step_name)] = event['result']
            elif event['event'] == 'busy':
                records.fields(event, 'event pid step errno')
                require(type(event['errno']) is int and event['errno'] == errno.EWOULDBLOCK, 'busy event does not record selected lock contention')
            elif event['event'] == 'opened':
                records.fields(event, 'event pid step device inode descriptor_closed descriptor close_on_exec')
                records.integer(event['descriptor'])
                require(same({key: event[key] for key in ('device', 'inode', 'descriptor_closed', 'close_on_exec')},
                    dict(device=lifetime.lock['device'], inode=lifetime.lock['inode'], descriptor_closed=0, close_on_exec=1)),
                    'worker opened a different or unsealed permanent lock')
            elif event['event'] == 'finished':
                require(same(event, dict(event='finished', pid=birth['pid'], complete=1, completed_steps=len(specification['steps']),
                    runtime_authorized=0, forbidden_process_attempts=0)), 'worker finished without its complete inactive protocol')
            else:
                records.fields(event, 'event pid' if event['event'] == 'ready' else 'event pid step')
        receipt = outcome['outcomes'][role]
        require(all(receipt[key] is True for key in ('launched', 'leader_reaped', 'group_gone', 'native_admitted', 'cleanup_complete', 'journal_complete', 'output_complete')),
                'worker native settlement or terminal evidence is incomplete')
        require(not receipt['cleanup_errors'] and not receipt['abandoned'] and not receipt['failed_captures'] and not receipt['failed_capture_prefixes']
            and receipt['eof'] == ['stderr', 'stdout'] and receipt['discarded'] == dict(stdout=0, stderr=0), 'worker has discarded output or unresolved resources')
        require(receipt['retained_prefixes'] == {channel: records.file_pin(body) for channel, body in streams[role].items()}, 'terminal capture receipt differs from original saved bytes')
        planned = role in cancellation_roles
        require(receipt['separate_recovery'] is planned and receipt['healthy'] is (not planned), 'ordinary completion and separate recovery were conflated')
        requests = [row['signal'] for row in rows if row['event'] == 'controller_child_signal' and row['role'] == role]
        require(receipt['signals'] == requests, 'signal request transcript differs from terminal receipt')
        if planned:
            require(requests in ([signal.SIGTERM], [signal.SIGTERM, signal.SIGKILL]) and receipt['exit_code'] in (-signal.SIGTERM, -signal.SIGKILL)
                and -receipt['exit_code'] in requests, 'planned cancellation lacks a matching actual signal exit')
            require(receipt['first_failure'] == dict(phase='recovery', type='PlannedCancellation', message='fixed held cancellation: ' + role), 'planned cancellation masks an earlier failure')
        else:
            require(receipt['exit_code'] == 0 and receipt['first_failure'] is None and not requests, 'ordinary worker did not complete normally')
        consumed = one(rows, 'controller_consumed', role)
        for key in ('separate_recovery', 'exit_code', 'leader_reaped', 'group_gone', 'cleanup_complete'):
            require(same(consumed[key], receipt[key]), 'terminal controller receipt differs from saved outcome')
        terminal = one(rows, 'worker_outcome', role)
        require(same(terminal['outcome'], receipt) and terminal['planned_cancellation'] is planned
            and consumed['sequence'] < terminal['sequence'], 'worker outcome was promoted or replaced before consumption')
        require([row['command'] for row in rows if row['event'] == 'controller_command' and row['role'] == role]
            == [row['command'] for row in commands if row['role'] == role], 'owned child command attempts differ from controller delivery records')
    accepted, snapshots = set(), []
    for row in rows:
        if row['event'] == 'operation_accepted':
            key = (row['role'], row['step'])
            require(key in responses and key not in accepted and actual_events[(*key, 'result')]['sequence'] < row['sequence'], 'operation acceptance omits or repeats an original result')
            step = next(step for step in case['roles'][key[0]]['steps'] if step['id'] == key[1])
            lifetime.operation(key[0], step, responses[key])
            accepted.add(key)
        elif row['event'] == 'case_snapshot':
            lifetime.snapshot(row['snapshot'])
            snapshots.append(row)
    require(accepted == set(responses) and not lifetime.images and not lifetime.runtimes and not lifetime.holds and not lifetime.workspaces,
            'case ends with unjoined results or retained live owners')
    expected_phases = ['activated']
    for action in case['actions']:
        if action['kind'] == 'run':
            expected_phases.append(action['role'] + ':' + action['step'])
        elif action['kind'] == 'contend':
            expected_phases.append('contention_complete')
        elif action['kind'] == 'cancel':
            expected_phases += ['before_held_cancellation', 'after_held_cancellation']
    expected_phases.append('workers_settled')
    require([row['phase'] for row in snapshots] == expected_phases, 'case omitted or invented a required ownership snapshot')
    cleanup = one(rows, 'cleanup_snapshot')
    require(cleanup['recovery'] is False and same(cleanup['snapshot'], snapshots[-1]['snapshot']), 'cleanup changed the terminal settled snapshot')
    require(all(one(rows, 'worker_outcome', role)['sequence'] < cleanup['sequence'] for role in case['roles']), 'fixture removal precedes actual worker settlement')
    remaining = copy.deepcopy(cleanup['snapshot']['nodes'])
    removal_order = sorted(remaining, key=lambda path: (len(PurePosixPath(path).parts), path), reverse=True)
    intents = [row for row in rows if row['event'] == 'removal_intent']
    removed = [row for row in rows if row['event'] == 'removed']
    require([row['node']['identity']['path'] for row in intents] == [row['path'] for row in removed] == removal_order, 'cleanup omission or order differs from the exact remaining closure')
    preceding = cleanup['sequence']
    for intent, done, path in zip(intents, removed, removal_order):
        require(preceding < intent['sequence'] < done['sequence'] and same(intent['node'], remaining[path]), 'cleanup removed a different original node or lost effect ordering')
        del remaining[path]
        preceding = done['sequence']
    roots = [case['store'], *case['workspaces'].values()] + ([case['evidence']] if case['evidence'] else [])
    require(same(outcome['cleanup'], dict(removed=removal_order, roots_absent=roots, recovery=False)), 'cleanup outcome differs from exact retained removal records')
    for action in case['actions']:
        if action['kind'] == 'contend':
            holder, contender, step = action['holder'], action['contender'], action['step']
            held = actual_events[(holder, step, 'held')]['sequence']
            busy = actual_events[(contender, step, 'busy')]['sequence']
            release = next(row['sequence'] for row in rows if row['event'] == 'command_sent' and row['role'] == holder and row['command'] == 'release')
            require(held < busy < release < actual_events[(contender, step, 'locked')]['sequence'], 'contention release was not gated by actual busy observation')
        elif action['kind'] == 'handoff':
            sealed = one(rows, 'handoff_sealed')
            packet = responses[(action['source_role'], action['source_step'])]['handoff']
            require(handoff_bytes == canonical(packet) and sealed['source'] == dict(path=case['handoff_path'], **records.file_pin(handoff_bytes)), 'handoff file replaced original acquisition bytes')
            cancel = one(rows, 'held_cancellation_intent')
            require(sealed['sequence'] < cancel['sequence'], 'original acquisition was not sealed before cancellation')
            peer_adopt = next(row for row in rows if row['event'] == 'command_sent' and row['command'] == 'step' and row['payload']['id'] == 'adopt')
            require(one(rows, 'worker_outcome', action['source_role'])['sequence'] < peer_adopt['sequence'], 'peer adoption precedes actual original-owner settlement')
    return dict(case=case['name'], workers=len(case['roles']), completed_operations=len(accepted),
        commands=len(commands), snapshots=len(snapshots), cleanup_nodes=len(removal_order),
        cancelled_workers=len(cancellation_roles), retained_archives=len(lifetime.archives))
