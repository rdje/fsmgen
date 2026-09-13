"""In-memory owned-tree models; no directory or worker is actually created."""
import copy
from contextlib import ExitStack
import errno
import json
from pathlib import PurePosixPath
import stat
from types import SimpleNamespace
from unittest.mock import patch

from contract import ROOT, WORKER_CONTRACT, cases
import owned_case as owned
from qualify_files import World
import records


class Scan:
    def __init__(self, world, path):
        self.world, self.path = world, path
        prefix = path + '/'
        self.entries = iter(sorted(name[len(prefix):] for name in world.nodes
            if name.startswith(prefix) and '/' not in name[len(prefix):]))

    def __iter__(self):
        return self

    def __next__(self):
        if self.world.scan_error:
            raise OSError(errno.EIO, 'model scan failure')
        return SimpleNamespace(name=next(self.entries))

    def close(self):
        self.world.scan_closed.append(self.path)
        if self.world.scan_close_error:
            raise OSError(errno.EIO, 'model scan close failure')


class TreeWorld(World):
    def __init__(self, case):
        super().__init__()
        self.scan_error = self.scan_close_error = False
        self.scan_closed, self.removals = [], []
        self.scan_hook = None
        roots = [case['store'], *case['workspaces'].values()]
        if case['evidence']:
            roots.append(case['evidence'])
        for root in roots:
            for parent in reversed(PurePosixPath(root).parents):
                name = str(parent)
                if name != '.' and name not in self.nodes:
                    self.add(name, stat.S_IFDIR | 0o700)

    def scandir(self, path):
        if self.scan_hook:
            self.scan_hook(path.path)
        return Scan(self, path.path)

    def unlink(self, path):
        name = path.path
        if stat.S_ISDIR(self.nodes[name]['st_mode']):
            raise IsADirectoryError(name)
        del self.nodes[name]
        self.removals.append(('file', name))

    def rmdir(self, path):
        name = path.path
        if not stat.S_ISDIR(self.nodes[name]['st_mode']):
            raise NotADirectoryError(name)
        if any(other.startswith(name + '/') for other in self.nodes):
            raise OSError(errno.ENOTEMPTY, name)
        del self.nodes[name]
        self.removals.append(('directory', name))

    def activate(self, stack):
        super().activate(stack)
        for name in ('scandir', 'unlink', 'rmdir'):
            stack.enter_context(patch.object(owned.os, name, getattr(self, name)))

    def install(self, source):
        """Place one already modeled source; retain its modeled source identity."""
        identity, body = source['identity'], records.octets(source['bytes_hex'])
        name = identity['path']
        parent = str(PurePosixPath(name).parent)
        if parent not in self.nodes:
            self.add(parent, stat.S_IFDIR | 0o700)
        self.add(name, stat.S_IFREG | (0o500 if name.endswith('/rustup') else 0o400), body)
        self.nodes[name].update(st_dev=identity['device'], st_ino=identity['inode'])


def qualify():
    checks, rejected, topologies = [], [], []

    def check(name, condition):
        if not condition or name in checks:
            raise AssertionError(name)
        checks.append(name)

    def reject(name, operation, expected=ValueError, contains=None):
        try:
            operation()
        except expected as error:
            if contains and contains not in str(error):
                raise AssertionError(name + ': wrong primary error') from error
            rejected.append(name)
            return error
        raise AssertionError(name + ': unexpectedly accepted')

    plans = cases()
    model = json.loads((ROOT / WORKER_CONTRACT).with_name('qualification.json').read_bytes())
    for case, prior in zip(plans, model['cases']):
        label = case['name'] + ': '
        world, journal = TreeWorld(case), []
        parents = copy.deepcopy(world.nodes)
        fixture = owned.OwnedCase(case, lambda event, **row: journal.append(dict(event=event, **row)))
        publications = {row['role']: copy.deepcopy(row['result']['result']['value']) for row in prior['trace']
            if row['kind'] == 'result' and row['operation'] == 'publish'}
        observations = [copy.deepcopy(row['result']['result']['value']) for row in prior['trace']
            if row['kind'] == 'result' and row['operation'] == 'observe']
        with ExitStack() as stack:
            world.activate(stack)
            activation = fixture.allocate()
            check(label + 'allocation has exact controller ownership',
                set(fixture.initial) == set(world.nodes) - set(parents)
                and set(fixture.root_identities) == set(fixture.roots))
            reject(label + 'allocation is one use', fixture.allocate)
            reject(label + 'cleanup requires explicit settled children', lambda: fixture.cleanup(1))
            for acquired in publications.values():
                sources = [*acquired['image']['snapshots'], acquired['reference']['global'], acquired['reference']['private']]
                for source in sources:
                    if source['identity']['path'] not in world.nodes:
                        world.install(source)
                fixture.remember(acquired)
            if observations:
                acquired = observations[0]
                record = acquired['observation_reference']['record']
                activation['births'] = {'observer': record['observer_birth'], case['observation_target']: record['target_birth']}
                fixture.allow_observation(activation)
                wrapper = acquired['target_sources'][0]
                # The source-only Perl model had its own wrapper inode. Bind it
                # to this independent memory filesystem's controller allocation.
                node = fixture.initial[wrapper['identity']['path']]['identity']
                wrapper['identity'].update({key: node[key] for key in ('device', 'inode')})
                world.install(acquired['observation_reference']['source'])
                fixture.remember(acquired)
                for digest, body in records.archive_sources(acquired).items():
                    directory = case['evidence'] + '/retained-sources'
                    if directory not in world.nodes:
                        world.add(directory, stat.S_IFDIR | 0o700)
                    world.add(directory + '/' + digest + '.source', stat.S_IFREG | 0o400, body)
                archived = copy.deepcopy(next(row['result']['result']['value'] for row in prior['trace']
                    if row['kind'] == 'result' and row['operation'] == 'archive'))
                archived['archive_directory_identity']['inode'] = world.nodes[directory]['st_ino']
                for binding in archived['source_bindings']:
                    binding['archive']['inode'] = world.nodes[binding['archive']['path']]['st_ino']
                fixture.remember_archive(archived, acquired)
                for path in (directory, archived['source_bindings'][0]['archive']['path']):
                    original_inode = world.nodes[path]['st_ino']
                    world.nodes[path]['st_ino'] += 100000
                    reject(label + 'archive original inode retained ' + path, fixture.snapshot, owned.UnresolvedTree)
                    world.nodes[path]['st_ino'] = original_inode
                original_catalog = copy.deepcopy((fixture.retained, fixture.retained_directories))
                altered = copy.deepcopy(archived)
                altered['source_bindings'][-1]['archive']['inode'] += 1
                reject(label + 'archive custody cannot be partly replaced', lambda: fixture.remember_archive(altered, acquired))
                check(label + 'archive replacement rejection is atomic', (fixture.retained, fixture.retained_directories) == original_catalog)
            populated = fixture.snapshot()
            check(label + 'populated inventory is exact', set(populated['nodes']) == set(world.nodes) - set(parents))
            check(label + 'all bounded read and scan handles close', not world.fds and bool(world.scan_closed))
            target = next(iter(publications.values()))['image']['snapshots'][0]['identity']['path']
            original_inode = world.nodes[target]['st_ino']
            world.nodes[target]['st_ino'] += 900000
            before = copy.deepcopy(world.nodes)
            reject(label + 'identical replacement does not inherit retained custody', lambda: fixture.cleanup(True), owned.UnresolvedTree)
            check(label + 'replacement rejection preserves every node', world.nodes == before and not world.removals)
            world.nodes[target]['st_ino'] = original_inode
            executable = next(iter(publications.values()))['image']['snapshots'][1]['identity']['path']
            old_mode = world.nodes[executable]['st_mode']
            world.nodes[executable]['st_mode'] = stat.S_IFREG | 0o400
            reject(label + 'retained image cannot lose its final seal', fixture.snapshot, owned.UnresolvedTree)
            world.nodes[executable]['st_mode'] = old_mode
            for field, value in [('st_mode', stat.S_IFREG | 0o600), ('st_nlink', 2), ('st_uid', 999999), ('st_dev', 99)]:
                saved = world.nodes[target][field]
                world.nodes[target][field] = value
                reject(label + 'retained file rejects changed ' + field, fixture.snapshot, owned.UnresolvedTree)
                world.nodes[target][field] = saved
            # Model the already qualified APIs' successful terminal topology:
            # retirement removes workspaces/references; release removes holds;
            # maintenance removes images; archives remain until owned cleanup.
            for name in list(world.nodes):
                if (any(name == root or name.startswith(root + '/') for root in case['workspaces'].values())
                        or name.startswith(case['store'] + '/images/')
                        or name.startswith(case['store'] + '/references/')):
                    del world.nodes[name]
            residual = fixture.snapshot()
            result = fixture.cleanup(True)
            check(label + 'cleanup removes exactly the residual owned nodes',
                set(result['removed']) == set(residual['nodes']) and world.nodes == parents)
            check(label + 'all roots absent after settled cleanup', set(result['roots_absent']) == set(fixture.roots))
            reject(label + 'cleanup is one use', lambda: fixture.cleanup(True))
            topologies.append(dict(case=case['name'], allocated_nodes=len(fixture.initial),
                populated_nodes=len(populated['nodes']), residual_nodes=len(residual['nodes']),
                residual_file_bytes=residual['file_bytes'], cleanup_nodes=len(result['removed'])))

    case = plans[0]
    for mutation, recovery, expected in [('partial', False, 'reject'), ('partial', True, 'accept'),
                                       ('unknown', True, 'reject'), ('symlink', True, 'reject')]:
        world = TreeWorld(case)
        fixture = owned.OwnedCase(case, lambda *args, **kwargs: None)
        with ExitStack() as stack:
            world.activate(stack)
            fixture.allocate()
            payload = records.payload('a')
            base = case['store'] + '/images/' + payload['key']
            world.add(base, stat.S_IFDIR | 0o700)
            path = base + '/rustup.c'
            if mutation == 'partial':
                world.add(path, stat.S_IFREG | 0o400, payload['sources']['rustup.c'][:2])
            elif mutation == 'unknown':
                path = case['store'] + '/references/' + records.runtime_key(next(iter(case['workspaces'].values()))) + '.json'
                world.add(path, stat.S_IFREG | 0o400, b'unknown reference bytes')
            else:
                world.add(path, stat.S_IFLNK | 0o777)
            if expected == 'reject':
                before = copy.deepcopy(world.nodes)
                reject(mutation + ' cleanup recovery=' + str(recovery), lambda: fixture.cleanup(True, recovery), owned.UnresolvedTree)
                check(mutation + ' rejection preserves all objects recovery=' + str(recovery), world.nodes == before and not world.removals)
            else:
                snapshot = fixture.snapshot(True)
                check('partial recovery explicitly identifies the known prefix', snapshot['nodes'][path]['partial_recovery'])
                fixture.cleanup(True, True)
                check('known unpublished prefix can be conservatively removed', path not in world.nodes)

    case = plans[2]
    world = TreeWorld(case)
    fixture = owned.OwnedCase(case, lambda *args, **kwargs: None)
    acquired = copy.deepcopy(next(row['result']['result']['value'] for row in model['cases'][2]['trace']
        if row['kind'] == 'result' and row['operation'] == 'observe'))
    with ExitStack() as stack:
        world.activate(stack)
        activation = fixture.allocate()
        record = acquired['observation_reference']['record']
        activation['births'] = {'observer': record['observer_birth'], case['observation_target']: record['target_birth']}
        fixture.allow_observation(activation)
        before = copy.deepcopy((fixture.allowed, fixture.retained))
        wrapper = acquired['target_sources'][0]
        wrapper['identity']['inode'] = fixture.initial[wrapper['identity']['path']]['identity']['inode'] + 100000
        reject('late acquisition failure rejects replaced controller wrapper', lambda: fixture.remember(acquired))
        check('late acquisition failure preserves the entire previous catalog', (fixture.allowed, fixture.retained) == before)
        wrapper['identity']['inode'] -= 100000
        fixture.remember(acquired)
        accepted = copy.deepcopy((fixture.allowed, fixture.retained))
        fixture.remember(acquired)
        check('remembering the identical original acquisition is idempotent', (fixture.allowed, fixture.retained) == accepted)
        acquired['target_sources'][-1]['identity']['inode'] += 1
        reject('repeated acquisition cannot replace a retained worker inode', lambda: fixture.remember(acquired))
        check('repeated acquisition rejection is atomic', (fixture.allowed, fixture.retained) == accepted)

    case = plans[0]
    for limit, value in [('owned_tree_nodes', 2), ('owned_tree_depth', 0), ('owned_file_bytes', 1), ('owned_tree_bytes', 1)]:
        world = TreeWorld(case)
        fixture = owned.OwnedCase(case, lambda *args, **kwargs: None)
        with ExitStack() as stack:
            world.activate(stack)
            fixture.allocate()
            fixture.limits[limit] = value
            before = copy.deepcopy(world.nodes)
            reject('bounded inventory rejects ' + limit, lambda: fixture.cleanup(True), owned.UnresolvedTree)
            check(limit + ' rejection does not remove objects', world.nodes == before and not world.removals)

    for primary in (False, True):
        world = TreeWorld(case)
        fixture = owned.OwnedCase(case, lambda *args, **kwargs: None)
        with ExitStack() as stack:
            world.activate(stack)
            fixture.allocate()
            world.scan_close_error = True
            world.scan_error = primary
            error = reject('directory close error primary=' + str(primary), fixture.snapshot,
                owned.UnresolvedTree, 'model scan failure' if primary else 'model scan close failure')
            check('failed directory scan closes once primary=' + str(primary), world.scan_closed == [case['store']])
            if primary:
                check('directory primary error retains the secondary close error',
                    'model scan close failure' in error.__cause__.__notes__[0])

    world = TreeWorld(case)
    fixture = owned.OwnedCase(case, lambda *args, **kwargs: None)
    with ExitStack() as stack:
        world.activate(stack)
        fixture.allocate()
        visits = []
        def change_membership(path):
            visits.append(path)
            if path == case['store'] and visits.count(path) == 2:
                world.add(path + '/unexpected', stat.S_IFREG | 0o400, b'unknown')
        world.scan_hook = change_membership
        reject('membership changed during census is unresolved', lambda: fixture.cleanup(True),
               owned.UnresolvedTree, 'membership changed')
        check('membership disagreement stops before deletion', not world.removals and case['store'] + '/unexpected' in world.nodes)

    world = TreeWorld(case)
    events = []
    def journal(event, **row):
        events.append(event)
        if event == 'cleanup_snapshot':
            world.nodes[case['store'] + '/coordination.lock']['st_ino'] += 1
    fixture = owned.OwnedCase(case, journal)
    with ExitStack() as stack:
        world.activate(stack)
        fixture.allocate()
        reject('identity changed between census and removal is unresolved', lambda: fixture.cleanup(True), owned.UnresolvedTree)
        check('pre-removal identity disagreement leaves all objects', not world.removals and 'removal_intent' not in events)

    for after_effect in (False, True):
        world = TreeWorld(case)
        fixture = owned.OwnedCase(case, lambda *args, **kwargs: None)
        with ExitStack() as stack:
            world.activate(stack)
            def fail_creation(path):
                if after_effect:
                    world.add(path, stat.S_IFDIR | 0o700)
                raise OSError(errno.EIO, 'model allocation failure')
            stack.enter_context(patch.object(owned.files, 'make_directory', fail_creation))
            reject('allocation failure after_effect=' + str(after_effect), fixture.allocate, OSError)
            if after_effect:
                reject('unconfirmed root cannot be adopted by cleanup', lambda: fixture.cleanup(True, True), owned.UnresolvedTree)
                check('unconfirmed allocation remains present', case['store'] in world.nodes and not world.removals)
            else:
                result = fixture.cleanup(True, True)
                check('failed allocation without effects has exact absent roots', not result['removed'] and set(result['roots_absent']) == set(fixture.roots))

    return dict(schema='fsmgen.inactive_populated_owned_tree_qualification.v1', checks=checks, rejected=rejected,
        topologies=topologies, actual_fixture_allocation=False, actual_worker_execution=False,
        scope='in-memory fixed fixture custody and settled cleanup; no arbitrary writer or power-loss claim')


if __name__ == '__main__':
    print(json.dumps(qualify(), sort_keys=True, indent=2))
