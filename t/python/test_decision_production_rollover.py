"""Independent full-cohort original recovery through the production reader."""

import json
import subprocess
import sys
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import prepare_decision_store_rollover as producer


class ProductionRollover(unittest.TestCase):
    def setUp(self):
        self.source = json.loads((ROOT / 'docs/audits/decision-store-transition-census.json').read_bytes())
        self.catalog = json.loads((ROOT / 'docs/decisions/current/catalog.json').read_bytes())

    def public(self, *args):
        result = subprocess.run([sys.executable, '-B', str(ROOT / 'scripts/decision_records.py'), *args],
                                capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def public_cohort(self, operation, identities):
        # Exercise every record through bounded requests, preserving global order.
        return b''.join(self.public(operation, *identities[start:start + 32])
                        for start in range(0, len(identities), 32))

    def git_bytes(self, revision, path):
        return subprocess.check_output(['git', '--no-replace-objects', '-C', str(ROOT),
                                        'show', revision + ':' + path])

    def test_every_original_matches_independent_published_or_flat_git_source(self):
        sealed = json.loads(self.git_bytes(self.source['source_revision'], 'docs/decisions/history/0001-0050.json'))
        identities = [row['id'] for row in self.source['records']]
        self.assertEqual(identities, [f'{n:04}' for n in range(1, 115)])
        expected = []
        for row in self.source['records']:
            revision = sealed['source_revision'] if row['id'] <= '0050' else self.source['source_revision']
            expected.append(self.git_bytes(revision, row['path']))
        self.assertEqual(self.public_cohort('read-original', identities), b''.join(expected))
        self.assertEqual(self.public_cohort('read', identities), b''.join(expected))
        self.assertEqual((ROOT / 'docs/decisions/history/transition-index.md').read_bytes(),
                         self.git_bytes(self.source['source_revision'], 'docs/decisions/INDEX.md'))

    def test_current_products_and_fixed_root_identity_population_are_complete(self):
        identities = [row['id'] for row in self.catalog['records']]
        self.assertEqual(identities, sorted(set(identities)))
        self.assertTrue({f'{n:04}' for n in range(51, 115)} <= set(identities))
        paths = [row['path'] for row in self.catalog['records']]
        self.assertEqual(len(paths), len(set(paths)))
        self.assertEqual(self.public_cohort('read-current', identities), b''.join((ROOT / path).read_bytes() for path in paths))
        expected_root = {row['path'] for row in self.source['records']} | {'docs/decisions/INDEX.md'}
        self.assertEqual({str(path.relative_to(ROOT)) for path in (ROOT / 'docs/decisions').glob('*.md')}, expected_root)
        source_by_id = {row['id']: row for row in self.source['records']}
        for row in self.catalog['records']:
            original = source_by_id.get(row['id'])
            if original is not None:
                if original['metadata']['knowledge_id'] is not None:
                    self.assertEqual(row['metadata']['knowledge_id'], original['metadata']['knowledge_id'])
                self.assertTrue(set(original['metadata']['questions']) <= set(row['metadata']['questions']))
            else:
                self.assertGreater(row['id'], self.source['records'][-1]['id'])
        self.assertIn(b'authenticated originals', self.public('check'))

    def test_immutable_capture_reproduces_from_exact_predecessor(self):
        products = producer.prepare(self.source['source_revision'])
        for relative in ('docs/audits/decision-store-transition-census.json',
                         'docs/decisions/history/transition-originals.json',
                         'docs/decisions/history/transition-index.md'):
            self.assertEqual(products[relative], (ROOT / relative).read_bytes())
        with self.assertRaisesRegex(ValueError, 'exact source commit'):
            producer.prepare('HEAD')


if __name__ == '__main__':
    unittest.main()
