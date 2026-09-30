"""Actual canonical-store authority gate fixtures, with explicit independent pins."""

import json
import os
import subprocess
import sys
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
import test_decision_store_git as selected
import test_decision_store as stores
import test_decision_catalog as literals

ROOT = Path(__file__).resolve().parents[2]
CHECKER = ROOT / 'scripts/check_live_document_ceiling_authority.pl'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
AUTHORITIES = 'doctrine/live_document_size/ceiling_increase_authorities.jsonl'


def header():
    return {'record_type': 'registry', 'schema_version': 1, 'max_records': 8,
            'max_bytes': 8192, 'max_record_bytes': 4096}


class CanonicalAuthorityGate(unittest.TestCase):
    def setUp(self):
        self.git_fixture = selected.SelectedStoreAccess()
        self.git_fixture.setUp()
        self.addCleanup(self.git_fixture.doCleanups)
        self.fixture = self.git_fixture.fixture
        self.root = self.fixture.root
        self.git = self.git_fixture.git
        self.registry = [header(), {'surface_id': 'guide', 'lifecycle': 'partitioned_canonical',
                                     'enforcement_ceilings': {'lines_each': 100},
                                     'baseline': {'lines_each': 80}}]
        self.authorities = [header()]
        self.write_registry()
        self.write_jsonl(AUTHORITIES, self.authorities)
        self.git('add', '.')
        self.git('commit', '-q', '-m', 'fixture authority baseline')

    def write_jsonl(self, path, rows):
        self.fixture.write(path, ''.join(json.dumps(row, sort_keys=True) + '\n' for row in rows))

    def write_registry(self):
        self.write_jsonl(REGISTRY, self.registry)

    def run_checker(self, trusted=True):
        arguments = ['perl', str(CHECKER), '--root', str(self.root)]
        if trusted:
            arguments += ['--source-sha256', self.fixture.source_digest,
                          '--index-sha256', self.fixture.index_digest]
        return subprocess.run(arguments, capture_output=True)

    def failure(self, result, message):
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn(message.encode(), result.stderr)

    def authority(self, path, fenced=False):
        self.registry[1]['enforcement_ceilings']['lines_each'] = 110
        self.write_registry()
        self.authorities.append({
            'record_type': 'ceiling_increase_authority', 'schema_version': 1,
            'authority_id': 'CEILING-CATALOG-001', 'surface_id': 'guide', 'dimension': 'lines_each',
            'previous': 100, 'new': 110, 'decision': path, 'approved_on': '2030-01-01'})
        self.write_jsonl(AUTHORITIES, self.authorities)
        markers = ('- Ceiling authority: `CEILING-CATALOG-001`\n- Surface: `guide`\n'
                   '- Dimension: `lines_each`\n- Change: `100 -> 110`\n')
        if fenced:
            markers = '```md\n' + markers + '```\n'
        row = next(row for row in self.fixture.catalog['records'] if row['path'] == path)
        text = (self.root / path).read_text() + '\n' + markers
        self.fixture.write(path, text)
        row['content'] = literals.content(text)
        self.fixture.write_json(stores.store.CATALOG, self.fixture.catalog)

    def birth(self):
        self.fixture.test_complete_fresh_navigation_keeps_fixed_compatibility_and_original_index()
        return self.fixture.catalog['records'][-1]['path']

    def test_fresh_canonical_authority_passes_worktree_staged_and_committed_modes(self):
        self.authority(self.birth())
        for mode in ('worktree', 'staged', 'committed'):
            if mode == 'staged':
                self.git('add', '.')
            elif mode == 'committed':
                self.git('commit', '-q', '-m', 'fixture canonical ceiling authority')
            result = self.run_checker()
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn(f'1 increase(s), mode {mode}'.encode(), result.stdout)

    def test_ordinary_growth_then_self_consistent_deletion_still_checks_continuity(self):
        self.birth()
        self.git('add', '.')
        result = self.run_checker()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(b'0 increase(s), mode staged', result.stdout)
        self.git('commit', '-q', '-m', 'fixture ordinary new identity')
        removed = self.fixture.catalog['records'].pop()
        (self.root / removed['path']).unlink()
        self.fixture.write_json(stores.store.CATALOG, self.fixture.catalog)
        self.fixture.write(stores.store.INDEX, stores.ROOT_INDEX)
        self.fixture.write('docs/decisions/current/language-api/INDEX.md', stores.PART_PREFIX)
        self.git('add', '.')
        self.failure(self.run_checker(), 'deleted a prior decision identity')

    def test_borrowed_transition_identity_and_fenced_authority_markers_refuse(self):
        self.authority(self.fixture.catalog['records'][0]['path'])
        self.git('add', '.')
        self.failure(self.run_checker(), 'requires a fresh canonical ID and file')
        # A distinct actual fixture isolates valid new identity/file admission
        # from marker text that is merely an example inside a code fence.
        other = CanonicalAuthorityGate()
        other.setUp()
        self.addCleanup(other.doCleanups)
        other.authority(other.birth(), fenced=True)
        other.git('add', '.')
        other.failure(other.run_checker(), 'decision lacks marker')

    def test_staged_control_disagreement_and_catalog_removal_refuse(self):
        path = self.birth()
        self.authority(path)
        self.git('add', '.')
        self.fixture.write(path, (self.root / path).read_text() + 'Unstaged candidate.\n')
        self.failure(self.run_checker(), 'controlled files differ between the staged index and worktree')
        self.git('restore', path)
        self.git('commit', '-q', '-m', 'fixture publish authority')
        (self.root / stores.store.CATALOG).unlink()
        self.git('add', '.')
        self.failure(self.run_checker(), 'catalog store removed')

    def test_independent_authority_and_source_products_are_not_optional(self):
        self.birth()
        self.git('add', '.')
        self.failure(self.run_checker(trusted=False), 'no installed independent authority')
        source = self.root / stores.store.SOURCE
        source.write_bytes(source.read_bytes() + b' ')
        self.git('add', stores.store.SOURCE)
        self.failure(self.run_checker(), 'source census changed')
        root_override = subprocess.run([
            'perl', str(CHECKER), '--root', str(ROOT), '--source-sha256', self.fixture.source_digest,
            '--index-sha256', self.fixture.index_digest], capture_output=True)
        self.failure(root_override, 'explicit other root')

    def test_control_file_fingerprints_refuse_index_changes_during_reader_dispatch(self):
        self.authority(self.birth())
        self.git('add', '.')
        tools = self.root / 'fixture-bin'
        tools.mkdir()
        shim = tools / 'dispatch.py'
        shim.write_text('''import json, os, subprocess, sys
from pathlib import Path
root = Path(os.environ['FSMGEN_FIXTURE_ROOT'])
relative = 'doctrine/live_document_size/surfaces.jsonl'
path = root / relative
rows = [json.loads(line) for line in path.read_text().splitlines()]
rows[1]['enforcement_ceilings']['lines_each'] = 999
path.write_text(''.join(json.dumps(row, sort_keys=True) + '\\n' for row in rows))
subprocess.run(['git', '-C', str(root), 'add', relative], check=True)
os.execv(sys.executable, [sys.executable, *sys.argv[1:]])
''')
        launcher = tools / 'python3'
        launcher.write_text('#!/bin/sh\nexec "$FSMGEN_FIXTURE_PYTHON" -B "$FSMGEN_FIXTURE_DISPATCH" "$@"\n')
        launcher.chmod(0o755)
        environment = {**os.environ, 'PATH': str(tools) + os.pathsep + os.environ['PATH'],
                       'FSMGEN_FIXTURE_ROOT': str(self.root), 'FSMGEN_FIXTURE_PYTHON': sys.executable,
                       'FSMGEN_FIXTURE_DISPATCH': str(shim)}
        result = subprocess.run(['perl', str(CHECKER), '--root', str(self.root),
                                 '--source-sha256', self.fixture.source_digest,
                                 '--index-sha256', self.fixture.index_digest],
                                capture_output=True, env=environment)
        self.failure(result, 'selected current control bytes differ from authenticated snapshot')

    def test_schema_booleans_refuse(self):
        # Isolate the legacy metadata parser from catalog authentication.
        (self.root / stores.store.CATALOG).unlink()
        self.git('add', '.')
        self.git('commit', '-q', '-m', 'fixture without catalog')
        self.registry[0]['schema_version'] = True
        self.write_registry()
        self.git('add', REGISTRY)
        result = self.run_checker(trusted=False)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn(b'unsupported schema_version', result.stderr)

    def test_authority_schema_booleans_refuse(self):
        self.authority(self.birth())
        for index in (0, 1):
            with self.subTest(index=index):
                self.authorities[index]['schema_version'] = True
                self.write_jsonl(AUTHORITIES, self.authorities)
                self.git('add', '.')
                self.failure(self.run_checker(), 'unsupported schema_version')
                self.authorities[index]['schema_version'] = 1


if __name__ == '__main__':
    unittest.main()
