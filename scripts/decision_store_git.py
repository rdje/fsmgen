"""Bounded immutable blob access and catalog continuity, before gate wiring."""

import os
import re
import subprocess
from pathlib import Path

import decision_catalog as catalog_api

MAX_INVENTORY_BYTES = 4_194_304
MAX_TRACKED_PATHS = 20_000
REGULAR_MODES = ('100644', '100755')


class GitSnapshot:
    """Capture path/mode/object IDs once; never re-read a mutable index selector."""

    def __init__(self, root, selector):
        self.root = Path(root).resolve(strict=True)
        top = self._git('rev-parse', '--show-toplevel', maximum=4096).decode('utf-8').strip()
        catalog_api.require(Path(top).resolve(strict=True) == self.root,
                            'selected Git root differs from requested repository')
        catalog_api.require(selector in ('index', 'HEAD', 'HEAD^')
                            or type(selector) is str and re.fullmatch(r'[0-9a-f]{40}', selector),
                            'unsafe or unsupported Git snapshot selector')
        self.objects = {}
        if selector == 'index':
            self.revision = None
            listing = self._git('ls-files', '--stage', '-z', maximum=MAX_INVENTORY_BYTES)
        else:
            revision = self._git('rev-parse', '--verify', selector + '^{commit}', maximum=128).decode().strip()
            catalog_api.require(re.fullmatch(r'[0-9a-f]{40}', revision), 'unresolved Git snapshot revision')
            self.revision = revision
            listing = self._git('ls-tree', '-r', '--full-tree', '-z', revision,
                                maximum=MAX_INVENTORY_BYTES)
        records = listing.split(b'\0')
        catalog_api.require(records[-1] == b'' and len(records) - 1 <= MAX_TRACKED_PATHS,
                            'Git path inventory exceeds bound or is incomplete')
        for record in records[:-1]:
            header, path_bytes = record.split(b'\t', 1)
            path = path_bytes.decode('utf-8')
            fields = header.decode('ascii').split(' ')
            if selector == 'index':
                catalog_api.require(len(fields) == 3 and fields[2] == '0', 'conflicting Git index stages')
                mode, object_id = fields[:2]
            else:
                catalog_api.require(len(fields) == 3, 'malformed Git tree inventory')
                mode, _, object_id = fields
            catalog_api.require(re.fullmatch(r'[0-9a-f]{40}', object_id), 'malformed Git object identity')
            catalog_api.require(path not in self.objects, 'duplicate Git inventory path')
            self.objects[path] = (mode, object_id)
        self.root_paths = tuple(sorted(path for path in self.objects
                                       if re.fullmatch(r'docs/decisions/[^/]+\.md', path)))

    def _git(self, *arguments, maximum):
        # Git metadata/blob commands never recurse into a gitlink. Merge the
        # diagnostic pipe to bound both streams; any successful warning would
        # invalidate the expected metadata or content rather than substitute it.
        environment = {**os.environ, 'GIT_NO_LAZY_FETCH': '1', 'GIT_OPTIONAL_LOCKS': '0'}
        process = subprocess.Popen(['git', '--no-replace-objects', '-C', str(self.root), *arguments],
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=environment)
        try:
            output = process.stdout.read(maximum + 1)
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
