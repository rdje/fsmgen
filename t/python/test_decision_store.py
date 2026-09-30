"""Literal source/index/compatibility controls for authenticated future stores."""

import copy
import hashlib
import json
import sys
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import decision_store as store
import test_decision_catalog as fixtures

ORIGINAL_INDEX = '''# Decision records

| # | Title | Type | Summary |
| --- | --- | --- | --- |
| [0001](0001-first.md) | First | convention | Keep original policy. |
| [0051](0051-current.md) | Current | architecture | Keep original questions. |
| [0100](0100-verification.md) | Verification | verification architecture | Keep checking. |
'''
ROOT_INDEX = '''# Decision records

[Continuity](current/continuity/INDEX.md)
[Language/API](current/language-api/INDEX.md)
[Verification](current/verification/INDEX.md)

| # | Title | Type | Summary |
| --- | --- | --- | --- |
| [0001](0001-first.md) | First | convention | Keep original policy. |
| [0051](current/continuity/0051-current.md) | Current | architecture | Keep original questions. |
| [0100](current/verification/0100-verification.md) | Verification | verification architecture | Keep checking. |
'''
PART_PREFIX = '# Current decisions\n\n| # | Title | Type | Summary |\n| --- | --- | --- | --- |\n'
PART_ROWS = {
    'continuity': '| [0051](0051-current.md) | Current | architecture | Keep original questions. |\n',
    'language-api': '',
    'verification': '| [0100](0100-verification.md) | Verification | verification architecture | Keep checking. |\n',
}


def alias(identity, heading, target):
    # An independent literal template, not the renderer being qualified.
    return (heading + '\n\n'
            'This compatibility path is fixed; storage does not change decision authority.\n'
            '[Read the complete record](' + target + ').\n\n'
            'Retrieve exact captured original text from the repository root:\n\n'
            '```sh\nscripts/decision_records.py read ' + identity + '\n```\n\n'
            '## Decision\n\n[Read the complete record](' + target + ').\n')


class AuthenticatedDecisionStore(unittest.TestCase):
    def setUp(self):
        self.fixture = fixtures.DecisionCatalogPreparation()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)
        self.root = self.fixture.root
        self.source = copy.deepcopy(self.fixture.source)
        self.originals = copy.deepcopy(self.fixture.originals)
        self.catalog = copy.deepcopy(self.fixture.catalog)
        self.write_json(store.SOURCE, self.source)
        self.write_json(store.ORIGINALS, self.originals)
        self.write_json(store.CATALOG, self.catalog)
        self.write(store.ORIGINAL_INDEX, ORIGINAL_INDEX)
        self.write(store.INDEX, ROOT_INDEX)
        for part, row in PART_ROWS.items():
            self.write(f'docs/decisions/current/{part}/INDEX.md', PART_PREFIX + row)
        self.aliases = {
            'docs/decisions/0001-first.md': alias('0001', '# 0001 — First decision',
                                               'history/0001-0050.md#decision-0001'),
            'docs/decisions/0051-current.md': alias('0051', '# 0051 — Current decision',
                                                 'current/continuity/0051-current.md'),
            'docs/decisions/0100-verification.md': alias('0100', '# Decision 0100: Verification decision',
                                                      'current/verification/0100-verification.md'),
        }
        for path, text in self.aliases.items():
            self.write(path, text)
        self.write(store.SEALED_VIEW, '<a id="decision-0001"></a>\n\n' + fixtures.FIRST)
        self.source_digest = hashlib.sha256((self.root / store.SOURCE).read_bytes()).hexdigest()
        self.index_digest = hashlib.sha256(ORIGINAL_INDEX.encode('utf-8')).hexdigest()

    def write(self, relative, text):
        self.fixture.write(relative, text)

    def write_json(self, relative, value):
        self.write(relative, json.dumps(value, ensure_ascii=False, sort_keys=True) + '\n')

    def load(self):
        return store.load(self.root, self.source_digest, self.index_digest)

    def check(self):
        prepared = self.load()
        return prepared, store.verify(self.root, prepared)

    def test_complete_authenticated_products_exact_navigation_and_no_writes(self):
        before = {str(p.relative_to(self.root)): p.read_bytes() for p in self.root.rglob('*') if p.is_file()}
        prepared, routes = self.check()
        store.verify_transition(prepared, routes)
        self.assertEqual(prepared['original_index'], ORIGINAL_INDEX)
        self.assertEqual(prepared['originals']['0051'], fixtures.SECOND)
        self.assertEqual(routes['0051']['target'], 'current/continuity/0051-current.md')
        for row in self.source['records']:
            actual = store.compatibility_page(row)
            self.assertEqual(actual, self.aliases[row['path']])
            self.assertEqual([line for line in actual.splitlines() if line.startswith('#')], row['headings'])
        after = {str(p.relative_to(self.root)): p.read_bytes() for p in self.root.rglob('*') if p.is_file()}
        self.assertEqual(after, before)

    def test_source_and_original_index_must_match_independent_fingerprints(self):
        for relative, diagnostic in [(store.SOURCE, 'source census changed'),
                                     (store.ORIGINAL_INDEX, 'original decision index changed')]:
            path = self.root / relative
            original = path.read_bytes()
            path.write_bytes(original.replace(b'current', b'changed', 1))
            with self.assertRaisesRegex(ValueError, diagnostic):
                self.load()
            path.write_bytes(original)
        for source_digest, index_digest in [(None, self.index_digest), (self.source_digest, 'invalid')]:
            with self.assertRaisesRegex(ValueError, 'authority digest is required'):
                store.load(self.root, source_digest, index_digest)

    def test_complete_fresh_navigation_keeps_fixed_compatibility_and_original_index(self):
        row = {'id': '0115', 'path': 'docs/decisions/current/language-api/0115-fresh.md',
               'type': 'architecture', 'metadata': {**fixtures.EMPTY, 'authority_status': ['Status: proposed']},
               'content': fixtures.content(fixtures.FRESH)}
        self.catalog['records'].append(row)
        self.write_json(store.CATALOG, self.catalog)
        self.write(row['path'], fixtures.FRESH)
        self.write(store.INDEX, ROOT_INDEX +
                   '| [0115](current/language-api/0115-fresh.md) | Fresh | architecture | Later body. |\n')
        self.write('docs/decisions/current/language-api/INDEX.md', PART_PREFIX +
                   '| [0115](0115-fresh.md) | Fresh | architecture | Later body. |\n')
        prepared, routes = self.check()
        store.verify_transition(prepared, routes)
        self.assertEqual(prepared['original_index'], ORIGINAL_INDEX)
        self.assertEqual(list(prepared['compatibility']), ['0001', '0051', '0100'])
        self.assertEqual(routes['0115']['target'], 'current/language-api/0115-fresh.md')
        self.assertFalse((self.root / 'docs/decisions/0115-fresh.md').exists())

    def test_original_body_corruption_and_incomplete_current_catalog_refuse(self):
        self.originals['records'][0]['text'] = fixtures.FIRST.replace('Keep', 'Lose')
        self.write_json(store.ORIGINALS, self.originals)
        with self.assertRaisesRegex(ValueError, 'digest changed'):
            self.load()
        self.write_json(store.ORIGINALS, self.fixture.originals)
        self.catalog['records'].pop()
        self.write_json(store.CATALOG, self.catalog)
        with self.assertRaisesRegex(ValueError, 'omits transition identities'):
            self.load()

    def test_root_and_part_route_duplicate_substitution_escape_and_missing_controls(self):
        path = self.root / store.INDEX
        variants = [(ROOT_INDEX.replace('[0100]', '[0051]'), 'duplicates'),
                    (ROOT_INDEX.replace('[0100]', '[0101]'), 'substitutes'),
                    (ROOT_INDEX.replace('(current/verification/0100-verification.md)',
                                        '(../0100-verification.md)'), 'misroutes'),
                    (ROOT_INDEX.replace(ROOT_INDEX.splitlines()[-1] + '\n', ''), 'membership')]
        for text, diagnostic in variants:
            with self.subTest(diagnostic=diagnostic):
                path.write_text(text)
                with self.assertRaisesRegex(ValueError, diagnostic):
                    self.check()
        path.write_text(ROOT_INDEX)
        part = self.root / 'docs/decisions/current/continuity/INDEX.md'
        part.write_text(PART_PREFIX + PART_ROWS['continuity'].replace('(0051-current.md)',
                                                                     '(../../0051-current.md)'))
        with self.assertRaisesRegex(ValueError, 'misroutes'):
            self.check()

    def test_stale_alias_heading_and_extra_root_identity_controls(self):
        path = self.root / 'docs/decisions/0051-current.md'
        path.write_text(self.aliases['docs/decisions/0051-current.md'].replace('## Decision', '## Wrong heading'))
        with self.assertRaisesRegex(ValueError, 'page is stale or altered'):
            self.check()
        path.write_text(self.aliases['docs/decisions/0051-current.md'])
        self.write('docs/decisions/0115-stray.md', fixtures.FRESH)
        with self.assertRaisesRegex(ValueError, 'root membership differs'):
            self.check()

    def test_index_types_parts_and_sealed_destinations_are_not_optional(self):
        root = self.root / store.INDEX
        root.write_text(ROOT_INDEX.replace('| convention |', '| architecture |'))
        with self.assertRaisesRegex(ValueError, 'changes decision type'):
            self.check()
        root.write_text(ROOT_INDEX.replace('[Language/API](current/language-api/INDEX.md)\n', ''))
        with self.assertRaisesRegex(ValueError, 'omits semantic part'):
            self.check()
        root.write_text(ROOT_INDEX)
        (self.root / store.SEALED_VIEW).write_text('# Missing destination\n')
        with self.assertRaisesRegex(ValueError, 'omits decision destination'):
            self.check()

    def test_initial_index_values_are_exact_but_later_owned_updates_remain_possible(self):
        root = self.root / store.INDEX
        root.write_text(ROOT_INDEX.replace('Keep original questions.', 'Current owned summary.'))
        part = self.root / 'docs/decisions/current/continuity/INDEX.md'
        part.write_text(PART_PREFIX + PART_ROWS['continuity'].replace('Keep original questions.',
                                                                    'Current owned summary.'))
        prepared, routes = self.check()
        self.assertEqual(prepared['original_index'], ORIGINAL_INDEX)
        with self.assertRaisesRegex(ValueError, 'transition index values changed'):
            store.verify_transition(prepared, routes)
        part.write_text(PART_PREFIX + PART_ROWS['continuity'])
        with self.assertRaisesRegex(ValueError, 'part index metadata differs'):
            self.check()

    def test_malformed_and_fenced_rows_do_not_supply_membership(self):
        path = self.root / store.INDEX
        row = ROOT_INDEX.splitlines()[-1]
        path.write_text(ROOT_INDEX.replace(row, '```md\n' + row + '\n```'))
        with self.assertRaisesRegex(ValueError, 'membership'):
            self.check()
        path.write_text(ROOT_INDEX + '\n| [01150](current/language-api/01150-wrong.md) | malformed |\n')
        with self.assertRaisesRegex(ValueError, 'unsupported decision index row'):
            self.check()
        path.write_text(ROOT_INDEX + '\n```md\n```not-a-closer\n')
        with self.assertRaisesRegex(ValueError, 'unterminated'):
            self.check()

    def test_selected_snapshot_requires_and_uses_complete_inventory(self):
        captured = {str(path.relative_to(self.root)): path.read_bytes()
                    for path in self.root.rglob('*') if path.is_file()}
        prepared = store.load(self.root, self.source_digest, self.index_digest, reader=captured.__getitem__)
        with self.assertRaisesRegex(ValueError, 'complete root path inventory'):
            store.verify(self.root, prepared, reader=captured.__getitem__)
        paths = list(self.aliases) + [store.INDEX]
        (self.root / store.INDEX).write_text('# Ambient broken index\n')
        routes = store.verify(self.root, prepared, reader=captured.__getitem__, paths=paths)
        store.verify_transition(prepared, routes)
        with self.assertRaisesRegex(ValueError, 'root membership differs'):
            store.verify(self.root, prepared, reader=captured.__getitem__, paths=paths + [paths[0]])
        with self.assertRaisesRegex(ValueError, 'membership'):
            self.check()

    def test_missing_and_symlinked_source_index_and_catalog_products_refuse(self):
        for relative in (store.SOURCE, store.ORIGINALS, store.ORIGINAL_INDEX, store.CATALOG):
            with self.subTest(relative=relative):
                path = self.root / relative
                original = path.read_bytes()
                path.unlink()
                with self.assertRaisesRegex(ValueError, 'unresolved regular source'):
                    self.load()
                target = self.root / 'retained-source'
                target.write_bytes(original)
                path.symlink_to(target)
                with self.assertRaisesRegex(ValueError, 'symlink'):
                    self.load()
                path.unlink()
                path.write_bytes(original)
                target.unlink()


if __name__ == '__main__':
    unittest.main()
