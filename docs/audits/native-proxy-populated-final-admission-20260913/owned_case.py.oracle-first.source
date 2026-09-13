"""Exact owned fixture allocation, bounded snapshots and conservative cleanup."""
import copy
import hashlib
import os
from pathlib import Path
import stat

from contract import CONTRACT, bounds
import local_files as files
import records


class UnresolvedTree(ValueError):
    def __init__(self, message, path, partial):
        super().__init__(message + ': ' + path)
        self.path, self.partial = path, copy.deepcopy(partial)


class OwnedCase:
    def __init__(self, case, journal):
        if case not in CONTRACT['cases']:
            raise ValueError('fixture case differs from the fixed worker contract')
        self.case, self.journal = copy.deepcopy(case), journal
        self.limits = bounds()
        self.roots = [case['store'], *case['workspaces'].values()] + ([case['evidence']] if case['evidence'] else [])
        self.initial, self.root_identities, self.allowed, self.retained = {}, {}, {}, {}
        self.retained_directories = {}
        self.allocation_started = False
        self.cleaned = False
        self._catalog()

    def _catalog(self):
        case = self.case
        directory = lambda path: self.allowed.update({path: dict(kind='directory', modes=[0o700], body=None)})
        regular = lambda path, modes, body: self.allowed.update({path: dict(kind='file', modes=modes, body=body)})
        for root in self.roots:
            directory(root)
        directory(case['store'] + '/images')
        directory(case['store'] + '/references')
        regular(case['store'] + '/coordination.lock', [0o600], b'')
        for kind in sorted({spec['image'] for spec in case['roles'].values()}):
            payload = records.payload(kind)
            base = case['store'] + '/images/' + payload['key']
            directory(base)
            for name, body in payload['sources'].items():
                regular(base + '/' + name, [0o400, 0o500] if name == 'rustup' else [0o400], body)
        for workspace in case['workspaces'].values():
            directory(workspace + '/rust-tools')
            regular(workspace + '/rust-tool-resolution', [0o600, 0o700], records.octets(CONTRACT['payloads']['wrapper_hex']))
            regular(workspace + '/rust-tools/image-reference.json', [0o400], None)
            regular(case['store'] + '/references/' + records.runtime_key(workspace) + '.json', [0o400], None)
        if case['evidence']:
            directory(case['evidence'] + '/retained-sources')

    def allocate(self):
        if self.allocation_started:
            raise ValueError('case allocation cannot be repeated')
        self.allocation_started = True
        entries = []
        for root in self.roots:
            entries.append((root, 'directory', None, 0o700))
            if root == self.case['store']:
                entries += [(root + '/images', 'directory', None, 0o700),
                            (root + '/references', 'directory', None, 0o700),
                            (root + '/coordination.lock', 'file', b'', 0o600)]
            elif root in self.case['workspaces'].values():
                entries += [(root + '/rust-tools', 'directory', None, 0o700),
                            (root + '/rust-tool-resolution', 'file', records.octets(CONTRACT['payloads']['wrapper_hex']), 0o700)]
        for path, kind, body, mode in entries:
            self.journal('allocation_intent', case=self.case['name'], path=path, kind=kind)
            if kind == 'directory':
                identity = files.make_directory(path)
                if path in self.roots:
                    self.root_identities[path] = identity
            else:
                files.write_bytes(path, body, mode, self.limits['owned_file_bytes'])
            self.initial[path] = self._node(path, recovery=False)
            self.journal('allocated', case=self.case['name'], node=self.initial[path])
        return dict(store=self.root_identities[self.case['store']],
            workspaces={role: self.root_identities[path] for role, path in self.case['workspaces'].items()},
            evidence=self.root_identities[self.case['evidence']] if self.case['evidence'] else None)

    def permanent_lock(self):
        identity = self.initial[self.case['store'] + '/coordination.lock']['identity']
        return {key: identity[key] for key in ('path', 'device', 'inode')}

    def allow_observation(self, activation):
        if not self.case['evidence']:
            raise ValueError('case has no observation role')
        key = records.observation_key(self.case['evidence'], activation['births']['observer'],
                                      activation['births'][self.case['observation_target']])
        self.allowed[self.case['store'] + '/references/' + key + '.json'] = dict(kind='file', modes=[0o400], body=None)

    def remember(self, acquired):
        """Only validated original acquisitions may extend the retained catalog."""
        allowed, retained = copy.deepcopy(self.allowed), copy.deepcopy(self.retained)
        if 'reference' in acquired:
            sources = [*acquired['image']['snapshots'], acquired['reference']['global'], acquired['reference']['private']]
        else:
            sources = [acquired['observation_reference']['source'], *acquired['target_sources']]
        for source in sources:
            path = source['identity']['path']
            body = records.octets(source['bytes_hex'])
            if path not in allowed or allowed[path]['kind'] != 'file':
                raise ValueError('acquisition names an undeclared fixture file')
            expected = allowed[path]['body']
            if expected is not None and expected != body:
                raise ValueError('acquisition changes selected fixture bytes')
            if path in retained and retained[path] != source:
                raise ValueError('acquisition replaces original retained identity')
            if path in self.initial:
                original = self.initial[path]['identity']
                if any(source['identity'][key] != original[key] for key in ('path', 'device', 'inode')):
                    raise ValueError('acquisition replaces a controller-created file')
            allowed[path]['body'] = body
            retained[path] = copy.deepcopy(source)
        if 'observation_reference' in acquired:
            for digest, body in records.archive_sources(acquired).items():
                path = self.case['evidence'] + '/retained-sources/' + digest + '.source'
                allowed[path] = dict(kind='file', modes=[0o400], body=body)
        self.allowed, self.retained = allowed, retained

    def remember_archive(self, archive, acquired):
        """Keep validated original archive identities, including shared roles."""
        retained = copy.deepcopy(self.retained)
        directory = archive['archive_directory_identity']
        path = self.case['evidence'] + '/retained-sources'
        if directory['path'] != path or (path in self.retained_directories and self.retained_directories[path] != directory):
            raise ValueError('archive directory replaces retained ownership')
        bodies = records.archive_sources(acquired)
        for binding in archive['source_bindings']:
            identity = binding['archive']
            name = identity['path']
            body = bodies[identity['sha256']]
            source = dict(identity=identity, bytes_hex=body.hex())
            if (name not in self.allowed or self.allowed[name]['body'] != body
                    or (name in retained and retained[name] != source)):
                raise ValueError('archive source replaces retained ownership')
            retained[name] = copy.deepcopy(source)
        self.retained = retained
        self.retained_directories[path] = copy.deepcopy(directory)

    def _node(self, path, recovery):
        expected = self.allowed.get(path)
        if expected is None:
            raise ValueError('unknown fixture path')
        before = files.direct(path)
        mode = stat.S_IMODE(before.st_mode)
        kind = 'directory' if stat.S_ISDIR(before.st_mode) else 'file' if stat.S_ISREG(before.st_mode) else 'unknown'
        if kind != expected['kind'] or mode not in expected['modes']:
            raise ValueError('fixture kind or mode differs')
        identity = dict(path=path, device=before.st_dev, inode=before.st_ino, mode=mode, uid=before.st_uid)
        node = dict(kind=kind, identity=identity)
        if kind == 'file':
            body = files.read_bytes(path, self.limits['owned_file_bytes'], mode)
            if files.identity(before) != files.identity(files.direct(path)):
                raise ValueError('fixture file changed during snapshot')
            known = expected['body']
            # Only an exact prefix of an already known intended payload may be
            # removed as partial fixture recovery. Unknown reference bytes stay
            # unresolved; normal success never accepts an incomplete payload.
            partial = known is not None and body != known and known.startswith(body) and mode in (0o400, 0o600)
            if known is None or (body != known and not (recovery and partial)):
                raise ValueError('fixture bytes are unknown or differ from retained custody')
            identity.update(size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest(), links=before.st_nlink)
            node.update(bytes_hex=body.hex(), partial_recovery=partial)
        original = self.initial.get(path)
        if original is not None and any(identity[key] != original['identity'][key] for key in ('path', 'device', 'inode', 'mode')):
            raise ValueError('controller-created fixture identity changed')
        retained = self.retained.get(path)
        if retained is not None:
            if mode != expected['modes'][-1] or any(identity[key] != retained['identity'][key]
                    for key in ('path', 'device', 'inode', 'size_bytes', 'sha256')):
                raise ValueError('original retained fixture identity, seal or complete bytes changed')
        directory = self.retained_directories.get(path)
        if directory is not None and any(identity[key] != directory[key] for key in ('path', 'device', 'inode')):
            raise ValueError('original archive directory identity changed')
        return node

    def snapshot(self, recovery=False):
        nodes, absent, total = {}, [], 0
        inspecting = None

        def names(path):
            directory = os.scandir(files.ROOT / path)
            primary = None
            found = []
            try:
                for entry in directory:
                    if len(found) >= self.limits['owned_tree_nodes']:
                        raise ValueError('owned directory membership bound exceeded')
                    files.relative(entry.name)
                    found.append(entry.name)
            except BaseException as error:
                primary = error
                raise
            finally:
                try:
                    directory.close()
                except OSError as error:
                    if primary is None:
                        raise
                    primary.add_note('Additional directory-close failure: ' + str(error))
            return sorted(found)

        def walk(path, depth):
            nonlocal total, inspecting
            inspecting = path
            if depth > self.limits['owned_tree_depth'] or len(nodes) >= self.limits['owned_tree_nodes']:
                raise ValueError('owned tree structure bound exceeded')
            node = self._node(path, recovery)
            nodes[path] = node
            if node['kind'] == 'file':
                total += node['identity']['size_bytes']
                if total > self.limits['owned_tree_bytes']:
                    raise ValueError('owned tree byte bound exceeded')
            else:
                members = names(path)
                for name in members:
                    walk(path + '/' + name, depth + 1)
                inspecting = path
                if self._node(path, recovery) != node or names(path) != members:
                    raise ValueError('owned directory identity or membership changed during snapshot')

        for root in self.roots:
            if root not in self.root_identities:
                if files.direct(root, absent_ok=True) is not None:
                    raise UnresolvedTree('unconfirmed allocation remains present', root, nodes)
                absent.append(root)
                continue
            if files.direct(root, absent_ok=True) is None:
                absent.append(root)
                continue
            try:
                inspecting = root
                if files.directory_identity(root) != self.root_identities[root]:
                    raise ValueError('owned root identity changed')
                walk(root, 0)
            except (OSError, ValueError) as error:
                raise UnresolvedTree(str(error), inspecting, nodes) from error
        return dict(nodes=nodes, absent_roots=absent, file_bytes=total)

    def cleanup(self, settled, recovery=False):
        if self.cleaned or settled is not True:
            raise ValueError('cleanup requires settled children and unused cleanup ownership')
        before = self.snapshot(recovery)
        self.journal('cleanup_snapshot', case=self.case['name'], recovery=recovery, snapshot=before)
        remaining = copy.deepcopy(before['nodes'])
        removed = []
        for path in sorted(remaining, key=lambda value: (len(Path(value).parts), value), reverse=True):
            current = self.snapshot(recovery)
            if current['nodes'] != remaining:
                raise ValueError('owned remaining tree changed before removal')
            node = remaining[path]
            self.journal('removal_intent', case=self.case['name'], node=node)
            if node['kind'] == 'directory':
                os.rmdir(files.ROOT / path)
            else:
                os.unlink(files.ROOT / path)
            if files.direct(path, absent_ok=True) is not None:
                raise ValueError('removed fixture node remains present')
            del remaining[path]
            removed.append(path)
            self.journal('removed', case=self.case['name'], path=path)
        final = self.snapshot(recovery)
        if final['nodes'] or set(final['absent_roots']) != set(self.roots):
            raise ValueError('owned fixture roots remain after cleanup')
        self.cleaned = True
        return dict(removed=removed, roots_absent=list(self.roots), recovery=recovery)
