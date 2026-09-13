"""No-process schedule/recovery models over the committed Perl result traces."""
import copy
from contextlib import ExitStack
import errno
import hashlib
import json
from pathlib import PurePosixPath
import signal
from types import SimpleNamespace
from unittest.mock import patch

from contract import ROOT, WORKER_CONTRACT, canonical, cases, worker_sources
import driver
from qualify_result_state import activation_for
import records


class Machine:
    def __init__(self, case, previous, toolchains, fault=None, unresolved=(), recovery_exception=()):
        self.case, self.previous, self.toolchains = copy.deepcopy((case, previous, toolchains))
        self.fault, self.unresolved, self.recovery_exception = fault, set(unresolved), set(recovery_exception)
        self.activation, self.lock = activation_for(case, previous)
        offset = previous.get('native_model_offset', 0)
        self.activation['births'] = {role: dict(pid=1001 + index + offset * 10000, ppid=999, uid=501, ruid=501, start_sec=100 + offset, start_usec=1001 + index)
            for index, role in enumerate(sorted(case['roles']))}
        self.workers, self.documents, self.journal = {}, {}, []
        self.commands, self.recoveries, self.remembered, self.archived = [], [], [], []
        self.holder = self.waiter = None
        self.busy_delivered = False
        self.result_rows = [row for row in previous['trace'] if row['kind'] == 'result']
        self.next_result = 0
        self.state = dict(images=[], runtimes=[], holds=[], workspaces=sorted(case['workspaces'].values()), archives=[])
        self.fixture = None

    def log(self, event, **fields):
        self.journal.append(dict(event=event, **copy.deepcopy(fields)))

    def write_document(self, path, value, limit):
        body = canonical(value)
        if path in self.documents or len(body) > limit:
            raise ValueError('model document is not exclusive or bounded')
        self.documents[path] = copy.deepcopy(value)
        return dict(path=path, **records.file_pin(body))

    def fixture_factory(self, case, journal):
        self.fixture = Fixture(self)
        return self.fixture

    def worker_factory(self, spec, limits, reader, journal, deadline):
        worker = Worker(self, spec, journal)
        self.workers[worker.role] = worker
        return worker

    def locked(self, worker):
        if self.holder is not None:
            if self.waiter is not None or worker is self.holder:
                raise ValueError('model accepts only the declared single contender')
            self.waiter, worker.contended = worker, True
            worker.emit('busy', step=worker.step['id'], errno=errno.EWOULDBLOCK)
            return
        self.holder = worker
        worker.emit('locked', step=worker.step['id'])
        if worker.step['hold']:
            worker.emit('held', step=worker.step['id'])
        else:
            self.complete(worker)

    def complete(self, worker):
        row = self.result_rows[self.next_result]
        if (row['role'], row['step']) != (worker.role, worker.step['id']):
            raise ValueError('driver result order differs from the committed independent case trace')
        self.next_result += 1
        self.state = copy.deepcopy(row['state'])
        result = copy.deepcopy(row['result'])
        result['lock']['busy_count'] = int(worker.contended)
        if self.fault == ('release_receipt', worker.role) and worker.step['operation'] == 'release':
            result['result']['value']['release'] = None
        worker.emit('result', **result)
        if worker.step['coordinated']:
            if self.holder is not worker:
                raise ValueError('model result lacks its original permanent-lock owner')
            self.holder = None
            if self.waiter is not None:
                next_worker, self.waiter = self.waiter, None
                self.locked(next_worker)


class Fixture:
    """Topology comes from the prior independent Perl trace, never CaseState."""
    def __init__(self, machine):
        self.machine = machine
        self.cleaned = self.allocated = False
        self.cleanup_calls = []
        case = machine.case
        self.roots = [case['store'], *case['workspaces'].values()] + ([case['evidence']] if case['evidence'] else [])

    def allocate(self):
        if self.allocated:
            raise ValueError('modeled fixture allocation repeated')
        self.allocated = True
        for path, node in self.snapshot()['nodes'].items():
            self.machine.log('allocation_intent', case=self.machine.case['name'], path=path, kind=node['kind'])
            self.machine.log('allocated', case=self.machine.case['name'], node=node)
        return {key: copy.deepcopy(self.machine.activation[key]) for key in ('store', 'workspaces', 'evidence')}

    def permanent_lock(self):
        return self.machine.lock

    def allow_observation(self, activation):
        if activation['births'] != self.machine.activation['births']:
            raise ValueError('model activation changes its declared synthetic owners')

    def remember(self, value):
        expected = [row['result']['result']['value'] for row in self.machine.result_rows if row['operation'] in ('publish', 'observe')]
        if value not in expected:
            raise ValueError('model remembers a substituted original acquisition')
        self.machine.remembered.append(copy.deepcopy(value))

    def remember_archive(self, value, acquired):
        expected = next(row['result']['result']['value'] for row in self.machine.result_rows if row['operation'] == 'archive')
        original = next(row['result']['result']['value'] for row in self.machine.result_rows if row['operation'] == 'observe')
        if value != expected or acquired != original:
            raise ValueError('model archive custody differs from the original committed trace')
        self.machine.archived.append(copy.deepcopy(value))

    def snapshot(self):
        machine, case = self.machine, self.machine.case
        if self.cleaned:
            return dict(nodes={}, absent_roots=self.roots, file_bytes=0)
        paths = {case['store'], case['store'] + '/images', case['store'] + '/references', case['store'] + '/coordination.lock'}
        for workspace in machine.state['workspaces']:
            paths.update((workspace, workspace + '/rust-tools', workspace + '/rust-tool-resolution'))
        for key in machine.state['images']:
            base = case['store'] + '/images/' + key
            paths.update([base, *(base + '/' + name for name in ('rustup.c', 'rustup', 'image.json'))])
        for row in machine.result_rows:
            if row['operation'] == 'publish':
                reference = row['result']['result']['value']['reference']
                if reference['record']['reference_key'] in machine.state['runtimes']:
                    paths.update(reference[kind]['identity']['path'] for kind in ('private', 'global'))
            elif row['operation'] == 'observe':
                reference = row['result']['result']['value']['observation_reference']
                if reference['record']['reference_key'] in machine.state['holds']:
                    paths.add(reference['source']['identity']['path'])
            elif row['operation'] == 'archive' and machine.state['archives']:
                value = row['result']['result']['value']
                paths.add(value['archive_directory_identity']['path'])
                paths.update(binding['archive']['path'] for binding in value['source_bindings'])
        if case['evidence']:
            paths.add(case['evidence'])
        source_table, directory_table = {}, {}
        for directory in [machine.activation['store'], *machine.activation['workspaces'].values()] + ([machine.activation['evidence']] if machine.activation['evidence'] else []):
            directory_table[directory['path']] = directory
        for row in machine.result_rows:
            value = row['result']['result']['value']
            sources = []
            if row['operation'] == 'publish':
                sources = [*value['image']['snapshots'], value['reference']['private'], value['reference']['global']]
            elif row['operation'] == 'observe':
                sources = [value['observation_reference']['source'], *value['target_sources']]
            elif row['operation'] == 'archive':
                directory_table[value['archive_directory_identity']['path']] = value['archive_directory_identity']
                original = next(row['result']['result']['value'] for row in machine.result_rows if row['operation'] == 'observe')
                sources = [dict(identity=binding['archive'], bytes_hex=source['bytes_hex'])
                    for binding, source in zip(value['source_bindings'], original['target_sources'])]
            for source in sources:
                source_table[source['identity']['path']] = source
        nodes = {}
        for path in sorted(paths):
            if path.endswith('/coordination.lock'):
                source = dict(identity=dict(machine.lock, **records.file_pin(b'')), bytes_hex='')
                mode = 0o600
            elif path in source_table:
                source = source_table[path]
                mode = 0o700 if path.endswith('/rust-tool-resolution') else 0o500 if path.endswith('/rustup') else 0o400
            elif path.endswith('/rust-tool-resolution'):
                body = records.octets(driver.CONTRACT['payloads']['wrapper_hex'])
                source = dict(identity=dict(path=path, device=7, inode=20000 + sorted(case['workspaces'].values()).index(str(PurePosixPath(path).parent)), **records.file_pin(body)), bytes_hex=body.hex())
                mode = 0o700
            else:
                # Synthetic identities for model-only directories absent from
                # the retained API schemas; stable across every snapshot.
                inode = 30000 + int.from_bytes(hashlib.sha256(path.encode()).digest()[:4], 'big')
                identity = directory_table.get(path, dict(path=path, device=7, inode=inode))
                nodes[path] = dict(kind='directory', identity=dict(identity, mode=0o700, uid=501))
                continue
            nodes[path] = dict(kind='file', identity=dict(source['identity'], mode=mode, uid=501, links=1),
                bytes_hex=source['bytes_hex'], partial_recovery=False)
        return dict(nodes=nodes, absent_roots=sorted(set(case['workspaces'].values()) - set(machine.state['workspaces'])),
            file_bytes=sum(node['identity']['size_bytes'] for node in nodes.values() if node['kind'] == 'file'))

    def cleanup(self, settled, recovery=False):
        self.cleanup_calls.append((settled, recovery))
        if settled is not True or any(worker.outcome is None or not worker.outcome['cleanup_complete'] for worker in self.machine.workers.values()):
            raise ValueError('model detects fixture cleanup before every child settles')
        if self.machine.fault == ('cleanup', None):
            raise OSError('model cleanup remains unresolved')
        before = self.snapshot()
        self.machine.log('cleanup_snapshot', case=self.machine.case['name'], recovery=recovery, snapshot=before)
        removed = sorted(before['nodes'], key=lambda path: (len(PurePosixPath(path).parts), path), reverse=True)
        for path in removed:
            self.machine.log('removal_intent', case=self.machine.case['name'], node=before['nodes'][path])
            self.machine.log('removed', case=self.machine.case['name'], path=path)
        self.cleaned = True
        return dict(removed=removed, roots_absent=self.roots, recovery=recovery)


class Worker:
    def __init__(self, machine, spec, journal):
        self.machine, self.spec, self.journal = machine, spec, journal
        self.role = spec.arguments[1]
        self.native = copy.deepcopy(machine.activation['births'][self.role])
        self.process = self.outcome = None
        self.native_admitted = self.admitted = self.terminal = self.contended = False
        self.events, self.queue = [], []
        self.buffers = dict(stdout=bytearray(), stderr=bytearray())
        self.index, self.step = 0, None

    def emit(self, name, **fields):
        self.queue.append(dict(event=name, pid=self.native['pid'], **copy.deepcopy(fields)))

    def launch(self):
        self.journal('launch_intent', script=self.spec.script, arguments=list(self.spec.arguments))
        self.process = SimpleNamespace(pid=self.native['pid'])
        self.journal('launched', pid=self.native['pid'])
        if self.machine.fault == ('launch', self.role):
            raise OSError('model setup failed after child creation')
        self.journal('native_owned', identity=self.native)
        fields = dict(extra=1) if self.machine.fault == ('ready', self.role) else {}
        self.emit('ready', **fields)

    def pump(self):
        if self.queue:
            event = self.queue.pop(0)
            if event['event'] == 'ready':
                self.native_admitted = True
                self.journal('native_admitted', identity=self.native, image=self.spec.native_pin)
            elif event['event'] == 'busy':
                self.machine.busy_delivered = True
            self.events.append(event)
            self.buffers['stdout'].extend(canonical(event) + b'\n')
            self.journal('worker_event', value=event)

    def send(self, name, payload):
        self.machine.commands.append((self.role, name, copy.deepcopy(payload)))
        self.journal('command', command=name)
        if self.machine.fault == ('command', self.role) and name == 'step':
            raise OSError('model command failed without retry')
        if name == 'admit':
            value = self.machine.documents[self.machine.case['activation_path']]
            if records.file_pin(canonical(value))['sha256'] != payload['activation_sha256']:
                raise ValueError('model received substituted activation bytes')
            self.admitted = True
        elif name == 'step':
            if len(self.machine.workers) != len(self.machine.case['roles']) or not all(worker.admitted and worker.native_admitted for worker in self.machine.workers.values()):
                raise ValueError('model saw mutation before admission of every role')
            self.step = self.machine.case['roles'][self.role]['steps'][self.index]
            self.index += 1
            self.contended = False
            if payload['id'] != self.step['id']:
                raise ValueError('model received a different fixed step')
            if self.step['operation'].startswith('adopt_'):
                packet = self.machine.documents[self.machine.case['handoff_path']]
                original = self.machine.workers[packet['source_role']]
                if original.outcome is None or not original.outcome['cleanup_complete'] or payload['handoff_sha256'] != records.file_pin(canonical(packet))['sha256']:
                    raise ValueError('model adoption precedes exact original packet and owner settlement')
            if self.step['coordinated']:
                self.emit('opened', step=self.step['id'], device=self.machine.lock['device'],
                    inode=self.machine.lock['inode'] + int(self.machine.fault == ('lock_inode', self.role)),
                    descriptor=12, descriptor_closed=0, close_on_exec=1)
            else:
                self.machine.complete(self)
        elif name == 'lock':
            self.machine.locked(self)
        elif name == 'release':
            if self.machine.holder is not self or not self.machine.busy_delivered:
                raise ValueError('model release precedes original lock and contender busy observation')
            self.machine.complete(self)
        elif name == 'finish':
            if self.index != len(self.machine.case['roles'][self.role]['steps']) or self.machine.case['roles'][self.role]['ending'] != 'finish':
                raise ValueError('model rejects premature role completion')
            self.emit('finished', complete=1, completed_steps=self.index, runtime_authorized=0, forbidden_process_attempts=0)
            self.terminal = True
        else:
            raise ValueError('model rejects undeclared command')

    def finished(self):
        return self.terminal and not self.queue

    def terminal_outcome(self, recovery, error=None):
        value = dict(exit_code=-signal.SIGTERM if recovery else 0, launched=self.process is not None,
            leader_reaped=self.process is not None, group_gone=self.role not in self.machine.unresolved,
            native_admitted=self.native_admitted, cleanup_complete=self.role not in self.machine.unresolved,
            journal_complete=True, output_complete=True, cleanup_errors=[], abandoned=[], failed_captures=[],
            failed_capture_prefixes={}, eof=['stderr', 'stdout'],
            discarded=dict(stdout=0, stderr=0), healthy=not recovery, separate_recovery=recovery,
            signals=[signal.SIGTERM] if recovery else [],
            first_failure=dict(phase='recovery', type=type(error).__name__, message=str(error)) if recovery else None,
            retained_prefixes={channel: records.file_pin(body) for channel, body in self.buffers.items()})
        self.outcome = value
        self.journal('consumed', **{key: value[key] for key in ('separate_recovery', 'exit_code', 'leader_reaped', 'group_gone', 'cleanup_complete')})
        return value

    def finish(self):
        if not self.finished():
            raise ValueError('model terminal output is incomplete')
        return self.terminal_outcome(False)

    def recover(self, error):
        self.machine.recoveries.append(self.role)
        if self.role in self.machine.recovery_exception:
            raise OSError('model recovery raised before obtaining a receipt')
        self.queue.clear()
        self.terminal = True
        if self.machine.holder is self:
            self.machine.holder = None
        self.journal('child_signal', signal=signal.SIGTERM)
        value = self.terminal_outcome(True, error)
        if not value['cleanup_complete']:
            raise driver.C.RecoveryIncomplete(value)
        return value


def run_case(case, previous, toolchains, **options):
    machine = Machine(case, previous, toolchains, **options)
    with ExitStack() as stack:
        stack.enter_context(patch.object(driver.files, 'write_document', machine.write_document))
        # Native birth validation is explicitly assumed here; the frozen
        # controller has separate no-process identity/admission models, and
        # actual native receipts remain a later one-use execution obligation.
        stack.enter_context(patch.object(driver.installed_inputs, 'identity', lambda value, pid, ppid: copy.deepcopy(value)))
        runner = driver.CaseDriver(case, dict(toolchains=toolchains, worker_sources=worker_sources()), 'a' * 40,
            object(), machine.log, SimpleNamespace(check=lambda: None), 1000,
            worker_factory=machine.worker_factory, fixture_factory=machine.fixture_factory, now=lambda: 1)
        result = runner.run()
    return machine, result


def qualify():
    checks, rejected, completed = [], [], []
    prior = json.loads((ROOT / WORKER_CONTRACT).with_name('qualification.json').read_bytes())
    toolchains = json.loads((ROOT / 'docs/audits/native-proxy-populated-final-admission-20260913/installed-first.json').read_bytes())['result']['toolchains']

    def check(name, value):
        if not value or name in checks:
            raise AssertionError(name)
        checks.append(name)

    for case, previous in zip(cases(), prior['cases']):
        machine, result = run_case(case, previous, toolchains)
        check(case['name'] + ' completes its exact selected schedule', result['success'] and not result['recovery_errors'])
        check(case['name'] + ' joins every committed original operation', machine.next_result == len(machine.result_rows))
        check(case['name'] + ' remembers every original acquisition', len(machine.remembered) == sum(row['operation'] in ('publish', 'observe') for row in machine.result_rows))
        check(case['name'] + ' records original archive custody', len(machine.archived) == sum(row['operation'] == 'archive' for row in machine.result_rows))
        check(case['name'] + ' performs one settled fixture cleanup', machine.fixture.cleanup_calls == [(True, False)] and machine.fixture.cleaned)
        check(case['name'] + ' uses recovery only for declared held cancellation',
            machine.recoveries == [action['role'] for action in case['actions'] if action['kind'] == 'cancel'])
        completed.append(dict(case=case['name'], commands=len(machine.commands), completed_operations=machine.next_result,
            workers=len(machine.workers), declared_cancellations=len(machine.recoveries),
            snapshots=sum(row['event'] == 'case_snapshot' for row in machine.journal)))
    case, previous = cases()[2], prior['cases'][2]
    first = next(iter(case['roles']))
    for fault in [('launch', first), ('ready', first), ('command', first), ('lock_inode', 'publisher'), ('release_receipt', 'observer'), ('cleanup', None)]:
        machine, result = run_case(case, previous, toolchains, fault=fault)
        name = str(fault)
        check(name + ' stops on its first actual model failure', not result['success'] and result['first_error'] is not None)
        check(name + ' consumes every created worker outcome', set(result['outcomes']) == set(machine.workers))
        check(name + ' preserves the owned cleanup outcome', machine.fixture.cleaned if fault[0] != 'cleanup' else not machine.fixture.cleaned)
        rejected.append(dict(fault=list(fault), first_error=result['first_error'], recovered_roles=machine.recoveries))
    roles = list(case['roles'])
    machine, result = run_case(case, previous, toolchains, fault=('ready', first), unresolved=[roles[0]], recovery_exception=[roles[1]])
    check('incomplete recovery does not strand later roles', machine.recoveries == roles and roles[2] in result['outcomes'])
    check('incomplete recovery never starts fixture removal', not machine.fixture.cleanup_calls and not machine.fixture.cleaned)
    check('incomplete recovery preserves both missing and unresolved outcomes', roles[1] not in result['outcomes'] and not result['outcomes'][roles[0]]['cleanup_complete'] and len(result['recovery_errors']) == 2)
    rejected.append(dict(fault=['ready plus incomplete recovery', first], first_error=result['first_error'], recovered_roles=machine.recoveries))
    return dict(schema='fsmgen.inactive_populated_driver_models.v1', checks=checks, rejecting_cases=rejected,
        completed_cases=completed, actual_fixture_allocation=False, actual_worker_execution=False, actual_signals=False,
        native_ownership_assumed=True, filesystem_bytes_and_native_outcomes_qualified_separately=True,
        scope='Synthetic protocol scheduling and all-child recovery; actual native and filesystem evidence remains separate.')


if __name__ == '__main__':
    print(json.dumps(qualify(), sort_keys=True, indent=2))
