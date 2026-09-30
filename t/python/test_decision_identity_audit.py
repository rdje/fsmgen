"""Identity-preserving row counts must still reject duplicate or wrong routes."""

import importlib.util
import sys
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    'decision_identity_audit', ROOT / 'scripts/audit_decision_identity_capacity.py')
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class DecisionIndexIdentity(unittest.TestCase):
    def setUp(self):
        self.records = {'0001': 'docs/decisions/0001-first.md',
                        '0100': 'docs/decisions/0100-later.md'}
        self.index = '| [0001](0001-first.md) | first |\n| [0100](0100-later.md) | later |\n'

    def test_exact_identity_and_destination(self):
        self.assertEqual(audit.index_paths(self.index, self.records),
                         [{'id': '0001', 'path': 'docs/decisions/0001-first.md'},
                          {'id': '0100', 'path': 'docs/decisions/0100-later.md'}])

    def test_equal_count_duplicate_and_substitution(self):
        for index, diagnostic in [
            (self.index.replace('[0100]', '[0001]'), 'duplicates'),
            (self.index.replace('[0100]', '[0101]'), 'membership'),
            (self.index.replace('0100-later.md', '0001-first.md'), 'misroutes'),
        ]:
            with self.subTest(index=index):
                with self.assertRaisesRegex(ValueError, diagnostic):
                    audit.index_paths(index, self.records)

    def test_missing_and_escaping_routes(self):
        with self.assertRaisesRegex(ValueError, 'membership'):
            audit.index_paths(self.index.splitlines()[0], self.records)
        with self.assertRaisesRegex(ValueError, 'unsupported destination'):
            audit.index_paths(self.index.replace('0100-later.md', '../0100-later.md'), self.records)


if __name__ == '__main__':
    unittest.main()
