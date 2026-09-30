"""Actual malformed-store, authority and reader-dispatch refusal controls."""

import json
import re
import os
import subprocess
import sys
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
import test_decision_ceiling_stores as gates
import test_decision_store as stores

ROOT = Path(__file__).resolve().parents[2]
CLI = ROOT / 'scripts/decision_records.py'


class HostileDecisionBoundaries(unittest.TestCase):
    def fixture(self):
        fixture = gates.CanonicalAuthorityGate()
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        return fixture

    def select(self, fixture, mode):
        if mode != 'worktree':
            fixture.git('add', '.')
        if mode == 'committed':
            fixture.git('commit', '-q', '-m', 'fixture selected hostile product')

    def corrupt(self, fixture, case):
        data = fixture.fixture
        row = data.catalog['records'][0]
        if case == 'source':
            path = fixture.root / stores.store.SOURCE
            path.write_bytes(path.read_bytes() + b' ')
        elif case == 'original index':
            data.write(stores.store.ORIGINAL_INDEX, stores.ORIGINAL_INDEX + 'Altered authority.\n')
        elif case == 'original':
            data.originals['records'][0]['text'] += 'Altered original.\n'
            data.write_json(stores.store.ORIGINALS, data.originals)
        elif case == 'descriptor':
            row['content']['bytes'] += 1
            data.write_json(stores.store.CATALOG, data.catalog)
        elif case == 'schema':
            data.catalog['schema_version'] = True
            data.write_json(stores.store.CATALOG, data.catalog)
        elif case == 'duplicate JSON key':
            path = fixture.root / stores.store.CATALOG
            path.write_text(path.read_text().replace('"schema_version": 1', '"schema_version": 1, "schema_version": 1'))
        elif case == 'root row':
            data.write(stores.store.INDEX, stores.ROOT_INDEX.replace(stores.PART_ROWS['continuity'].replace(
                '(0051-current.md)', '(current/continuity/0051-current.md)'), ''))
        elif case == 'part row':
            data.write('docs/decisions/current/continuity/INDEX.md', stores.PART_PREFIX)
        elif case == 'compatibility':
            path = 'docs/decisions/0001-first.md'
            data.write(path, (fixture.root / path).read_text() + 'Altered alias.\n')
        elif case == 'extra root':
            data.write('docs/decisions/0115-extra.md', '# 0115 — Unexpected root member\n')
        elif case == 'missing body':
            (fixture.root / row['path']).unlink()
        elif case == 'symlink':
            path = fixture.root / row['path']
            retained = fixture.root / 'retained-body.md'
            retained.write_bytes(path.read_bytes())
            path.unlink()
            path.symlink_to(os.path.relpath(retained, path.parent))
        elif case == 'large blob':
            data.write(row['path'], 'x' * 1_048_577)
        else:
            self.fail('unknown independent product corruption')

    def test_malformed_current_store_products_refuse_every_mode_without_ceiling_changes(self):
        cases = {'source': 'source census changed', 'original index': 'original decision index changed',
                 'original': 'record dimensions or digest changed', 'descriptor': 'record dimensions or digest changed',
                 'schema': 'unsupported schema', 'duplicate JSON key': 'duplicate JSON key',
                 'root row': 'index membership differs', 'part row': 'index membership differs',
                 'compatibility': 'compatibility page is stale or altered',
                 'extra root': 'compatibility root membership differs', 'missing body': 'source',
                 'symlink': 'symlink', 'large blob': 'bound'}
        for mode in ('worktree', 'staged', 'committed'):
            for case, diagnostic in cases.items():
                with self.subTest(mode=mode, case=case):
                    fixture = self.fixture()
                    self.corrupt(fixture, case)
                    self.select(fixture, mode)
                    result = fixture.run_checker()
                    # Git selected modes report the inadmissible regular-blob
                    # kind instead of the filesystem's explicit symlink label.
                    if case == 'symlink' and mode != 'worktree':
                        diagnostic = 'not a regular blob'
                    fixture.failure(result, diagnostic)
                    fixture.doCleanups()

    def test_borrowed_prior_birth_orphan_reused_and_misrouted_authority_refuse_all_modes(self):
        for mode in ('worktree', 'staged', 'committed'):
            for case in ('prior birth', 'orphan', 'reused', 'wrong delta', 'unknown part'):
                with self.subTest(mode=mode, case=case):
                    fixture = self.fixture()
                    path = fixture.birth()
                    if case == 'prior birth':
                        fixture.git('add', '.')
                        fixture.git('commit', '-q', '-m', 'fixture already published birth')
                    fixture.authority(path)
                    if case == 'orphan':
                        fixture.registry[1]['enforcement_ceilings']['lines_each'] = 100
                        fixture.write_registry()
                        diagnostic = 'does not match a ceiling increase'
                    elif case == 'reused':
                        fixture.git('add', '.')
                        fixture.git('commit', '-q', '-m', 'fixture already used authority')
                        fixture.registry[1]['enforcement_ceilings']['lines_each'] = 120
                        fixture.write_registry()
                        diagnostic = 'unauthorized enforcement-ceiling increase'
                    elif case == 'wrong delta':
                        fixture.authorities[-1]['new'] = 111
                        fixture.write_jsonl(gates.AUTHORITIES, fixture.authorities)
                        diagnostic = 'unauthorized enforcement-ceiling increase'
                    elif case == 'unknown part':
                        fixture.authorities[-1]['decision'] = path.replace('/language-api/', '/unknown/')
                        fixture.write_jsonl(gates.AUTHORITIES, fixture.authorities)
                        diagnostic = 'decision must be a project-relative'
                    else:
                        diagnostic = 'requires a fresh canonical ID and file'
                    self.select(fixture, mode)
                    fixture.failure(fixture.run_checker(), diagnostic)
                    fixture.doCleanups()

    def test_conflicting_index_and_gitlink_sources_never_enter_the_regular_reader(self):
        fixture = self.fixture()
        path = fixture.fixture.catalog['records'][0]['path']
        first = fixture.git('hash-object', '-w', '--stdin', input=b'first\n').decode().strip()
        second = fixture.git('hash-object', '-w', '--stdin', input=b'second\n').decode().strip()
        stages = f'0 {"0" * 40}\t{path}\n100644 {first} 1\t{path}\n100644 {second} 2\t{path}\n'
        fixture.git('update-index', '--index-info', input=stages.encode())
        command = [sys.executable, '-B', str(CLI), '--root', str(fixture.root),
                   '--source-sha256', fixture.fixture.source_digest,
                   '--index-sha256', fixture.fixture.index_digest, '--snapshot', 'index', 'check']
        result = subprocess.run(command, capture_output=True)
        fixture.failure(result, 'conflicting Git index stages')
        fixture.failure(fixture.run_checker(), 'controlled files differ')
        fixture.git('reset', '-q')
        revision = fixture.git('rev-parse', 'HEAD').decode().strip()
        fixture.git('update-index', '--add', '--cacheinfo', f'160000,{revision},{path}')
        result = subprocess.run(command, capture_output=True)
        fixture.failure(result, 'not a regular blob')

    def dispatch(self, fixture, source):
        tools = fixture.root / 'fixture-bin'
        tools.mkdir()
        shim = tools / 'dispatch.py'
        shim.write_text(source)
        launcher = tools / 'python3'
        launcher.write_text('#!/bin/sh\nexec "$FSMGEN_FIXTURE_PYTHON" -B "$FSMGEN_FIXTURE_DISPATCH" "$@"\n')
        launcher.chmod(0o755)
        environment = {**os.environ, 'PATH': str(tools) + os.pathsep + os.environ['PATH'],
                       'FSMGEN_FIXTURE_PYTHON': sys.executable, 'FSMGEN_FIXTURE_DISPATCH': str(shim)}
        return subprocess.run(['perl', str(gates.CHECKER), '--root', str(fixture.root),
                               '--source-sha256', fixture.fixture.source_digest,
                               '--index-sha256', fixture.fixture.index_digest],
                              capture_output=True, env=environment, timeout=30)

    def test_bounded_dual_streams_malformed_products_and_signal_failure_refuse(self):
        cases = {
            'stdout': ("import sys\nsys.stdout.write('x' * 1_048_577)\nsys.stdout.flush()\n",
                       'reader output exceeds byte bound'),
            'stderr': ("import sys\nsys.stderr.write('x' * 65537)\nsys.stderr.flush()\n",
                       'reader diagnostic exceeds byte bound'),
            'malformed': ("print('{}')\n", 'change product is malformed'),
            'signal': ("import os, signal, subprocess, sys\n"
                       "result = subprocess.run([sys.executable, *sys.argv[1:]], capture_output=True, check=True)\n"
                       "sys.stdout.buffer.write(result.stdout)\nsys.stdout.flush()\n"
                       "os.kill(os.getpid(), signal.SIGTERM)\n", 'change check failed'),
        }
        for case, (source, diagnostic) in cases.items():
            with self.subTest(case=case):
                fixture = self.fixture()
                fixture.authority(fixture.birth())
                fixture.git('add', '.')
                golden = fixture.run_checker()
                self.assertEqual(golden.returncode, 0, golden.stdout + golden.stderr)
                fixture.failure(self.dispatch(fixture, source), diagnostic)
                fixture.doCleanups()

    def test_no_catalog_change_requests_still_validate_supplied_fingerprint_shapes(self):
        fixture = self.fixture()
        (fixture.root / stores.store.CATALOG).unlink()
        fixture.git('add', '.')
        fixture.git('commit', '-q', '-m', 'fixture no catalog')
        for digest in ('bad', 'g' * 64, 'a' * 63, 'a' * 65):
            with self.subTest(digest=digest):
                result = subprocess.run([sys.executable, '-B', str(CLI), '--root', str(fixture.root),
                                         '--source-sha256', digest,
                                         '--index-sha256', fixture.fixture.index_digest,
                                         '--snapshot', 'HEAD', '--prior-snapshot', 'HEAD',
                                         'check-continuity'], capture_output=True)
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                self.assertEqual(result.stdout, b'')
                self.assertIn(b'independent store authority digest', result.stderr)
        accepted = subprocess.run([sys.executable, '-B', str(CLI), '--root', str(fixture.root),
                                   '--source-sha256', fixture.fixture.source_digest,
                                   '--index-sha256', fixture.fixture.index_digest,
                                   '--snapshot', 'HEAD', '--prior-snapshot', 'HEAD',
                                   'check-continuity'], capture_output=True)
        self.assertEqual(accepted.returncode, 0, accepted.stderr)
        self.assertEqual(json.loads(accepted.stdout), {'catalog': False, 'fresh_ids': [], 'resolved': []})

    def test_installed_default_mode_preserves_published_sealed_prefix_and_pin_isolation(self):
        fixture = self.fixture()
        capsule = fixture.root / 'scripts'
        capsule.mkdir()
        for name in ('decision_records.py', 'decision_catalog.py', 'decision_store.py', 'decision_store_git.py',
                     'check_live_document_ceiling_authority.pl'):
            text = (ROOT / 'scripts' / name).read_text()
            if name == 'decision_records.py':
                text = re.sub(r'^STORE_SOURCE_SHA256 = .+$',
                                    'STORE_SOURCE_SHA256 = ' + repr(fixture.fixture.source_digest), text, flags=re.MULTILINE)
                text = re.sub(r'^STORE_INDEX_SHA256 = .+$',
                                    'STORE_INDEX_SHA256 = ' + repr(fixture.fixture.index_digest), text, flags=re.MULTILINE)
            (capsule / name).write_text(text)
        for relative in ('docs/audits/decision-record-rollover-census-20260927.json',
                         'docs/decisions/history/0001-0050.json', 'docs/decisions/history/0001-0050.md'):
            path = fixture.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes((ROOT / relative).read_bytes())
        fixture.git('add', '.')
        fixture.git('commit', '-q', '-m', 'fixture independently installed pins with original published archive')
        # Supplied-fixture loading accepts this small fictional source cohort;
        # installed default mode must additionally preserve the real sealed prefix.
        supplied = fixture.run_checker()
        self.assertEqual(supplied.returncode, 0, supplied.stdout + supplied.stderr)
        default = subprocess.run([sys.executable, '-B', str(capsule / 'decision_records.py'),
                                  '--snapshot', 'HEAD', 'check'], capture_output=True)
        fixture.failure(default, 'substitutes published sealed original')
        self.assertEqual(default.stdout, b'')
        default_gate = subprocess.run(['perl', str(capsule / 'check_live_document_ceiling_authority.pl'),
                                       '--root', str(fixture.root)], capture_output=True)
        fixture.failure(default_gate, 'substitutes published sealed original')
        override = subprocess.run(['perl', str(capsule / 'check_live_document_ceiling_authority.pl'),
                                   '--root', str(fixture.root),
                                   '--source-sha256', fixture.fixture.source_digest,
                                   '--index-sha256', fixture.fixture.index_digest], capture_output=True)
        fixture.failure(override, 'explicit other root')


if __name__ == '__main__':
    unittest.main()
