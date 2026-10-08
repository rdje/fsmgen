"""Bounded immutable blob access and catalog continuity for selected gate products."""

import os
import re
import subprocess
from pathlib import Path

import decision_catalog as catalog_api

MAX_INVENTORY_BYTES = 4_194_304
# Every SHA-1 index record needs mode, object ID, stage, tab, a nonempty
# path and NUL. Committed trees use that same zero-stage representation.
# The default whole-inventory API counts every tracked entry. An explicit
# source scope uses the same cap for its complete selected metadata.
MIN_INVENTORY_RECORD_BYTES = len(b'100644 ' + b'0' * 40 + b' 0\ta\0')
MAX_TRACKED_PATHS = MAX_INVENTORY_BYTES // MIN_INVENTORY_RECORD_BYTES
REGULAR_MODES = ('100644', '100755')


class GitSnapshot:
    """Capture path/mode/object IDs once; never re-read a mutable index selector."""

    def __init__(self, root, selector, *, files=None, subtrees=()):
        self.root = Path(root).resolve(strict=True)
        top = self._git('rev-parse', '--show-toplevel', maximum=4096).decode('utf-8').strip()
        catalog_api.require(Path(top).resolve(strict=True) == self.root,
                            'selected Git root differs from requested repository')
        catalog_api.require(selector in ('index', 'HEAD', 'HEAD^')
                            or type(selector) is str and re.fullmatch(r'[0-9a-f]{40}', selector),
                            'unsafe or unsupported Git snapshot selector')
        self.objects = {}
        self.inventory_bytes = 0
        self._files = None
        if files is not None:
            self._set_scope(files, subtrees)
        else:
            catalog_api.require(not subtrees, 'subtrees require an explicit source scope')
        if selector == 'index':
            self.revision = None
        else:
            revision = self._git('rev-parse', '--verify', selector + '^{commit}', maximum=128).decode().strip()
            catalog_api.require(re.fullmatch(r'[0-9a-f]{40}', revision), 'unresolved Git snapshot revision')
            self.revision = revision
        if self._files is None:
            listing = (self._git('ls-files', '--stage', '-z', maximum=MAX_INVENTORY_BYTES)
                       if selector == 'index' else
                       self._git('ls-tree', '-r', '--full-tree', '-z', self.revision,
                                 maximum=MAX_INVENTORY_BYTES, tree_inventory=True))
            self._capture(listing, index=selector == 'index')
        else:
            self._capture_scope()
        self.root_paths = tuple(sorted(path for path in self.objects
                                       if re.fullmatch(r'docs/decisions/[^/]+\.md', path)))

    def _set_scope(self, files, subtrees):
        """Declare bounded sources and the metadata needed to reject ancestors."""
        for values in (files, subtrees):
            catalog_api.require(type(values) in (tuple, list)
                                and len(values) <= catalog_api.MAX_SOURCE_RECORDS,
                                'invalid bounded Git source scope')
        paths = list(files) + list(subtrees)
        catalog_api.require(paths and len(paths) <= catalog_api.MAX_SOURCE_RECORDS,
                            'invalid bounded Git source scope')
        parts = {}
        for path in paths:
            value = catalog_api.relative_parts(path)
            parts[path] = value
        catalog_api.require(sum(len(path.encode('utf-8')) + 1 for path in paths)
                            <= catalog_api.MAX_DOCUMENT_BYTES, 'Git source scope exceeds byte bound')
        self._files = frozenset(files)
        self._subtrees = tuple(sorted(path for path in set(subtrees)
                                      if not any(path.startswith(parent + '/')
                                                 for parent in subtrees if parent != path)))
        self._ancestors = frozenset('/'.join(value[:length])
                                    for value in parts.values() for length in range(1, len(value)))

    def _in_scope(self, path):
        return path in self._files or any(path == parent or path.startswith(parent + '/')
                                         for parent in self._subtrees)

    @staticmethod
    def _exact_index_pathspec(path):
        # Literal directory names recurse in ls-files. A forced byte class
        # selects only the exact tracked parent/file, including UTF-8 names.
        raw = path.encode('utf-8')
        first = bytes(raw[:1])
        if first in (b'!', b'^', b'-', b']', b'['):
            first = b'\\' + first
        tail = b''.join((b'\\' if byte in b'\\*?[]' else b'') + bytes([byte])
                        for byte in raw[1:])
        return b':(top,glob)[' + first + b']' + tail

    def _capture_scope(self):
        exact = sorted(path for path in self._files | self._ancestors
                       if not any(path == parent or path.startswith(parent + '/')
                                  for parent in self._subtrees))
        if self.revision is None:
            # One index enumeration captures all relevant objects atomically;
            # blob reads below never consult that mutable selector again.
            specs = [':(top,literal)' + path for path in self._subtrees]
            specs.extend(self._exact_index_pathspec(path) for path in exact)
            listing = self._git('ls-files', '--stage', '-z', '--', *specs,
                                maximum=MAX_INVENTORY_BYTES)
            self._capture(listing, index=True)
        else:
            if self._subtrees:
                listing = self._git('ls-tree', '-r', '--full-tree', '-z', self.revision,
                                    '--', *[':(top,literal)' + path for path in self._subtrees],
                                    maximum=MAX_INVENTORY_BYTES, tree_inventory=True)
                self._capture(listing, index=False)
            # ls-tree does not support glob magic. Overlapping parent arguments
            # broaden its output; query each exact path at the same resolved SHA.
            for path in exact:
                listing = self._git('ls-tree', '--full-tree', '-z', self.revision,
                                    '--', ':(top,literal)' + path,
                                    maximum=MAX_INVENTORY_BYTES, tree_inventory=True,
                                    directory_entries=True)
                self._capture(listing, index=False, exact=path)

    def _capture(self, listing, *, index, exact=None):
        records = listing.split(b'\0')
        catalog_api.require(records[-1] == b'' and len(records) - 1 <= MAX_TRACKED_PATHS,
                            'Git path inventory exceeds bound or is incomplete')
        for record in records[:-1]:
            header, path_bytes = record.split(b'\t', 1)
            path = path_bytes.decode('utf-8')
            fields = header.decode('ascii').split(' ')
            if index:
                catalog_api.require(len(fields) == 3 and fields[2] == '0', 'conflicting Git index stages')
                mode, object_id = fields[:2]
            else:
                catalog_api.require(len(fields) == 3 and fields[2] == '0',
                                    'malformed Git tree inventory')
                mode, object_id = fields[:2]
            catalog_api.require(re.fullmatch(r'[0-9a-f]{40}', object_id), 'malformed Git object identity')
            if exact is not None:
                catalog_api.require(path == exact, 'Git exact source inventory broadened')
                if mode == '040000':
                    continue  # Full recursive inventories also omit directories.
            if self._files is not None:
                catalog_api.require(self._in_scope(path) or path in self._ancestors,
                                    'Git inventory escapes declared source scope')
            catalog_api.require(path not in self.objects, 'duplicate Git inventory path')
            self.inventory_bytes += len(record) + 1
            catalog_api.require(self.inventory_bytes <= MAX_INVENTORY_BYTES,
                                'Git output exceeds selected snapshot bound')
            catalog_api.require(len(self.objects) < MAX_TRACKED_PATHS,
                                'Git path inventory exceeds bound or is incomplete')
            self.objects[path] = (mode, object_id)

    @staticmethod
    def _read_tree_inventory(stream, maximum, *, directory_entries=False):
        """Bound canonical metadata while preserving standard -z raw paths.

        Standard tree headers carry an object type instead of an index stage.
        Parse bounded chunks and retain the equivalent zero-stage encoding;
        custom Git formatters can quote paths even with -z.
        """
        output = bytearray()
        pending = b''
        while block := stream.read1(65_536):
            records = (pending + block).split(b'\0')
            pending = records.pop()
            for record in records:
                header, separator, path = record.partition(b'\t')
                fields = header.split(b' ')
                catalog_api.require(separator and path and len(fields) == 3,
                                    'malformed Git tree inventory')
                mode, kind, object_id = fields
                expected_kind = (b'tree' if directory_entries and mode == b'040000'
                                 else b'commit' if mode == b'160000' else b'blob')
                catalog_api.require(kind == expected_kind,
                                    'malformed Git tree inventory')
                canonical = mode + b' ' + object_id + b' 0\t' + path + b'\0'
                catalog_api.require(len(output) + len(canonical) <= maximum,
                                    'Git output exceeds selected snapshot bound')
                output.extend(canonical)
            # A commit header is at most five bytes longer than its canonical
            # counterpart. Bound even an incomplete or malformed wire record.
            catalog_api.require(len(output) + len(pending) <= maximum + 5,
                                'Git output exceeds selected snapshot bound')
        catalog_api.require(not pending, 'Git path inventory exceeds bound or is incomplete')
        return bytes(output)

    def _git(self, *arguments, maximum, tree_inventory=False, directory_entries=False):
        # Git metadata/blob commands never recurse into a gitlink. Merge the
        # diagnostic pipe to bound both streams; any successful warning would
        # invalidate the expected metadata or content rather than substitute it.
        environment = {**os.environ, 'GIT_NO_LAZY_FETCH': '1', 'GIT_OPTIONAL_LOCKS': '0'}
        process = subprocess.Popen(['git', '--no-replace-objects', '-C', str(self.root), *arguments],
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=environment)
        try:
            output = (self._read_tree_inventory(process.stdout, maximum,
                                               directory_entries=directory_entries) if tree_inventory
                      else process.stdout.read(maximum + 1))
            if len(output) > maximum:
                process.kill()
                catalog_api.require(False, 'Git output exceeds selected snapshot bound')
            status = process.wait()
            catalog_api.require(status == 0, 'selected Git object cannot be read')
            return output
        finally:
            process.stdout.close()
            if process.poll() is None:
                process.kill()
            process.wait()

    def read(self, path):
        parts = catalog_api.relative_parts(path)
        catalog_api.require(self._files is None or self._in_scope(path),
                            f'selected source is outside declared scope: {path}')
        catalog_api.require(not any('/'.join(parts[:length]) in self.objects
                                    for length in range(1, len(parts))),
                            f'selected source has a nondirectory ancestor: {path}')
        catalog_api.require(path in self.objects, f'unresolved selected source: {path}')
        mode, object_id = self.objects[path]
        catalog_api.require(mode in REGULAR_MODES, f'selected source is not a regular blob: {path}')
        size_bytes = self._git('cat-file', '-s', object_id, maximum=64)
        catalog_api.require(re.fullmatch(rb'[0-9]+\n', size_bytes), 'malformed selected blob size')
        size = int(size_bytes)
        catalog_api.require(size <= catalog_api.MAX_DOCUMENT_BYTES, f'selected source exceeds byte bound: {path}')
        data = self._git('cat-file', 'blob', object_id, maximum=catalog_api.MAX_DOCUMENT_BYTES)
        catalog_api.require(len(data) == size, 'selected blob size changed')
        return data


def verify_continuity(prior, current):
    """Preserve prior births/keys; snapshot authentication precedes this check."""
    for key in ('source_revision', 'source_sha256', 'original_index_sha256',
                'compatibility', 'originals', 'original_index', 'original_routes'):
        catalog_api.require(prior[key] == current[key], f'immutable store source changed: {key}')
    before, after = prior['current'], current['current']
    catalog_api.require(set(before) <= set(after), 'current catalog deleted a prior decision identity')
    for identity, old in before.items():
        new = after[identity]
        catalog_api.require(all(old[key] == new[key] for key in ('id', 'path', 'type')),
                            f'current catalog recycles a prior decision identity: {identity}')
        old_meta, new_meta = old['metadata'], new['metadata']
        catalog_api.require(old_meta['knowledge_id'] is None
                            or old_meta['knowledge_id'] == new_meta['knowledge_id'],
                            f'current catalog loses prior fact identity: {identity}')
        catalog_api.require(set(old_meta['questions']) <= set(new_meta['questions']),
                            f'current catalog loses prior question keys: {identity}')
    highest = max(set(before) | set(prior['compatibility']))
    catalog_api.require(all(identity > highest for identity in set(after) - set(before)),
                        'current catalog reuses earlier decision ID space')
