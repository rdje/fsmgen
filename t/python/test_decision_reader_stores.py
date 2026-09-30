"""Actual published CLI controls for independent supplied future stores."""

import json
import subprocess
import sys
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
import test_decision_store as stores
import test_decision_catalog as fixtures
import decision_records as published

ROOT = Path(__file__).resolve().parents[2]
CLI = ROOT / 'scripts/decision_records.py'


class PublishedStoreReader(unittest.TestCase):
    def setUp(self):
        self.fixture = stores.AuthenticatedDecisionStore()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)
        self.root = self.fixture.root

    def run_reader(self, *arguments, authority=True, root=True):
        command = [sys.executable, '-B', str(CLI)]
        if root:
            command += ['--root', str(self.root)]
        if authority:
            command += ['--source-sha256', self.fixture.source_digest,
                        '--index-sha256', self.fixture.index_digest]
        return subprocess.run(command + list(arguments), capture_output=True)

    def assert_failure(self, result, diagnostic):
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(result.stdout, b'')
        self.assertIn(diagnostic.encode(), result.stderr)

    def test_actual_check_and_requested_original_current_products(self):
        checked = self.run_reader('check')
        self.assertEqual(checked.returncode, 0, checked.stderr)
        self.assertIn(b'authenticated originals, current records', checked.stdout)
        for operation, identities, expected in [
            ('read', ('0100', '0001'), fixtures.THIRD + fixtures.FIRST),
            ('read-original', ('0051', '0001'), fixtures.SECOND + fixtures.FIRST),
            ('read-current', ('0100', '0051'), fixtures.THIRD + fixtures.SECOND),
        ]:
            with self.subTest(operation=operation):
                result = self.run_reader(operation, *identities)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, expected.encode('utf-8'))
                self.assertEqual(result.stderr, b'')
        self.assertFalse(any(self.root.rglob('__pycache__')))

    def test_owned_current_status_and_summary_updates_do_not_rewrite_original_products(self):
        current = self.fixture.catalog['records'][0]
        changed = fixtures.SECOND.replace('- Status: accepted', '- Status: superseded')
        self.fixture.write(current['path'], changed)
        current.update(content=fixtures.content(changed))
        current['metadata']['authority_status'] = ['- Status: superseded']
        self.fixture.write_json(stores.store.CATALOG, self.fixture.catalog)
        original = self.run_reader('read-original', '0051')
        latest = self.run_reader('read-current', '0051')
        ordinary = self.run_reader('read', '0051')
        self.assertEqual(original.returncode, 0, original.stderr)
        self.assertEqual(latest.returncode, 0, latest.stderr)
        self.assertEqual(original.stdout, fixtures.SECOND.encode())
        self.assertEqual(ordinary.stdout, original.stdout)
        self.assertEqual(latest.stdout, changed.encode())

    def test_first_fact_indexing_preserves_original_absence_and_current_unique_keys(self):
        row = self.fixture.catalog['records'][1]
        body = ('---\nid: fixture-verification\nanswers: ["which verification applies?"]\n'
                'status: current\n---\n' + fixtures.THIRD)
        row['metadata'] = {'knowledge_id': 'fixture-verification', 'knowledge_status': 'current',
                           'questions': ['which verification applies?'],
                           'authority_status': ['- **Status:** Accepted']}
        row['content'] = fixtures.content(body)
        self.fixture.write(row['path'], body)
        self.fixture.write_json(stores.store.CATALOG, self.fixture.catalog)
        current = self.run_reader('read-current', '0100')
        original = self.run_reader('read-original', '0100')
        self.assertEqual(current.returncode, 0, current.stderr)
        self.assertEqual(current.stdout, body.encode())
        self.assertEqual(original.stdout, fixtures.THIRD.encode())
        prepared = self.fixture.load()
        with self.assertRaisesRegex(ValueError, 'transition metadata changed'):
            stores.store.verify_transition(prepared, stores.store.verify(self.root, prepared))

    def test_unknown_unavailable_malformed_and_oversized_requests_are_atomic(self):
        for arguments, message in [
            (('read', '0051', '9999'), 'unknown decision ID'),
            (('read-current', '0051', '0001'), 'unavailable read-current'),
            (('read-original', '0115'), 'unknown decision ID'),
            (('read', '0051', '../0100'), 'invalid decision ID'),
            (('read',), 'bounded nonempty'),
            (('read',) + ('0051',) * 51, 'bounded nonempty'),
            (('check', '0051'), 'check does not accept'),
            (('resolve',), 'one canonical'),
        ]:
            with self.subTest(arguments=arguments):
                self.assert_failure(self.run_reader(*arguments), message)

    def test_supplied_authority_is_explicit_and_missing_or_altered_products_refuse(self):
        self.assert_failure(self.run_reader('read', '0051', root=False), 'explicit --root')
        # After rollout, omitted fixture pins select installed production pins;
        # the independently different fixture must fail authentication instead.
        untrusted = ('no installed independent authority' if published.STORE_SOURCE_SHA256 is None
                     else 'independent transition source census changed')
        self.assert_failure(self.run_reader('read', '0051', authority=False), untrusted)
        partial = subprocess.run([sys.executable, '-B', str(CLI), '--root', str(self.root),
                                  '--source-sha256', self.fixture.source_digest, 'read', '0051'], capture_output=True)
        self.assert_failure(partial, 'both independent fingerprints')
        path = self.root / stores.store.SOURCE
        original = path.read_bytes()
        path.write_bytes(original + b' ')
        self.assert_failure(self.run_reader('read', '0051'), 'source census changed')
        path.write_bytes(original)
        (self.root / stores.store.CATALOG).unlink()
        self.assert_failure(self.run_reader('read', '0051'), 'unresolved regular source')

    def test_resolve_exposes_only_an_exact_authenticated_canonical_binding(self):
        result = self.run_reader('resolve', 'docs/decisions/current/continuity/0051-current.md')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {
            'id': '0051', 'path': 'docs/decisions/current/continuity/0051-current.md',
            'transition_source_revision': fixtures.REVISION, 'content_sha256': fixtures.content(fixtures.SECOND)['sha256'],
            'transition_identity': True,
        })
        for path in ('docs/decisions/0051-current.md',
                     'docs/decisions/current/verification/0051-current.md',
                     'docs/decisions/current/continuity/../0051-current.md'):
            self.assert_failure(self.run_reader('resolve', path), 'not an exact current canonical')

    def test_complete_fresh_reader_products_and_bounded_output(self):
        text = fixtures.FRESH + ('a' * 1_000 + '\n') * 50
        row = {'id': '0115', 'path': 'docs/decisions/current/language-api/0115-fresh.md',
               'type': 'architecture', 'metadata': {**fixtures.EMPTY, 'authority_status': ['Status: proposed']},
               'content': fixtures.content(text)}
        self.fixture.catalog['records'].append(row)
        self.fixture.write_json(stores.store.CATALOG, self.fixture.catalog)
        self.fixture.write(row['path'], text)
        self.fixture.write(stores.store.INDEX, stores.ROOT_INDEX +
                           '| [0115](current/language-api/0115-fresh.md) | Fresh | architecture | Later body. |\n')
        self.fixture.write('docs/decisions/current/language-api/INDEX.md', stores.PART_PREFIX +
                           '| [0115](0115-fresh.md) | Fresh | architecture | Later body. |\n')
        result = self.run_reader('read', '0115')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, text.encode())
        resolved = self.run_reader('resolve', row['path'])
        self.assertEqual(resolved.returncode, 0, resolved.stderr)
        self.assertFalse(json.loads(resolved.stdout)['transition_identity'])
        self.assert_failure(self.run_reader('read-original', '0115'), 'unavailable read-original')
        self.assert_failure(self.run_reader('read-current', *('0115',) * 50), 'output exceeds byte bound')
        self.assertFalse((self.root / 'docs/decisions/0115-fresh.md').exists())


if __name__ == '__main__':
    unittest.main()
