"""Independent future-store fixtures for the closed preparation boundary."""

import copy
import hashlib
import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('decision_catalog', ROOT / 'scripts/decision_catalog.py')
catalog_api = importlib.util.module_from_spec(spec)
spec.loader.exec_module(catalog_api)

REVISION = 'a' * 40
FIRST = '# 0001 — First decision\n\nStatus: accepted\n\n## Decision\n\nKeep this original.\n'
SECOND = ('---\nid: fixture-current\nanswers:\n  - "which fixture is current?"\n'
          'status: current\n---\n\n# 0051 — Current decision\n\n- Status: accepted\n\n'
          '## Decision\n\nCurrent body.\n\n```md\n# 9999 — example, not identity\n```\n')
THIRD = '# Decision 0100: Verification decision\n\n- **Status:** Accepted\n\n## Decision\n\nKeep checking.\n'
FRESH = '# 0115 — Fresh decision\n\nStatus: proposed\n\n## Decision\n\nLater body.\n'
EMPTY = {'knowledge_id': None, 'knowledge_status': None, 'questions': [], 'authority_status': []}


def content(text):
    data = text.encode('utf-8')
    return {'bytes': len(data), 'lines': text.count('\n'),
            'line_bytes': max(len(line.encode('utf-8')) for line in text.splitlines()),
            'sha256': hashlib.sha256(data).hexdigest()}


class DecisionCatalogPreparation(unittest.TestCase):
    def setUp(self):
        parent = ROOT / '.artifacts' / 'decision-catalog-tests'
        parent.mkdir(parents=True, exist_ok=True)
        workspace = tempfile.TemporaryDirectory(dir=parent)
        self.addCleanup(workspace.cleanup)
        self.root = Path(workspace.name)
        # Expected metadata/headings are literal and do not call the instrument.
        first_meta = {**EMPTY, 'authority_status': ['Status: accepted']}
        second_meta = {'knowledge_id': 'fixture-current', 'knowledge_status': 'current',
                       'questions': ['which fixture is current?'], 'authority_status': ['- Status: accepted']}
        third_meta = {**EMPTY, 'authority_status': ['- **Status:** Accepted']}
        definitions = [
            ('0001', 'first', 'sealed', 'convention', FIRST, first_meta,
             ['# 0001 — First decision', '## Decision'], None),
            ('0051', 'current', 'current', 'architecture', SECOND, second_meta,
             ['# 0051 — Current decision', '## Decision'], 'continuity'),
            ('0100', 'verification', 'current', 'verification architecture', THIRD, third_meta,
             ['# Decision 0100: Verification decision', '## Decision'], 'verification'),
        ]
        self.source = {'schema_version': 1, 'source_revision': REVISION, 'records': []}
        self.originals = {'schema_version': 1, 'source_revision': REVISION, 'records': []}
        self.catalog = {'schema_version': 1, 'source_revision': REVISION, 'records': []}
        for identity, slug, kind, category, text, metadata, headings, part in definitions:
            path = f'docs/decisions/{identity}-{slug}.md'
            self.source['records'].append({'id': identity, 'path': path, 'kind': kind, 'part': part, 'type': category,
                                          'metadata': metadata, 'headings': headings, 'content': content(text)})
            self.originals['records'].append({'id': identity, 'path': path, 'text': text})
            if part:
                current = f'docs/decisions/current/{part}/{identity}-{slug}.md'
                self.catalog['records'].append({'id': identity, 'path': current, 'type': category,
                                               'metadata': copy.deepcopy(metadata), 'content': content(text)})
                self.write(current, text)

    def write(self, relative, text):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(text.encode('utf-8'))

    def prepare(self):
        return catalog_api.prepare(self.root, self.source, self.originals, self.catalog)

    def test_exact_source_products_metadata_and_detached_caller(self):
        before = json.dumps([self.source, self.originals, self.catalog], sort_keys=True)
        prepared = self.prepare()
        catalog_api.verify_transition_metadata(prepared)
        self.assertEqual(prepared['originals'], {'0001': FIRST, '0051': SECOND, '0100': THIRD})
        self.assertEqual(prepared['current']['0051']['text'], SECOND)
        self.assertEqual(prepared['compatibility']['0051']['headings'],
                         ['# 0051 — Current decision', '## Decision'])
        self.assertEqual(prepared['current']['0051']['metadata']['questions'], ['which fixture is current?'])
        prepared['current']['0051']['metadata']['questions'].append('detached')
        prepared['compatibility']['0001']['headings'].clear()
        self.assertEqual(json.dumps([self.source, self.originals, self.catalog], sort_keys=True), before)

    def test_fresh_identity_does_not_extend_compatibility_cohort(self):
        row = {'id': '0115', 'path': 'docs/decisions/current/language-api/0115-fresh.md',
               'type': 'architecture', 'metadata': {**EMPTY, 'authority_status': ['Status: proposed']},
               'content': content(FRESH)}
        self.catalog['records'].append(row)
        self.write(row['path'], FRESH)
        prepared = self.prepare()
        self.assertEqual(list(prepared['compatibility']), ['0001', '0051', '0100'])
        self.assertEqual(list(prepared['current']), ['0051', '0100', '0115'])
        self.assertFalse((self.root / 'docs/decisions/0115-fresh.md').exists())

    def test_duplicate_substituted_missing_and_reordered_populations(self):
        for field in ('source', 'originals', 'catalog'):
            original = copy.deepcopy(getattr(self, field))
            rows = original['records']
            for replacement in (rows + [rows[0]], list(reversed(rows)), []):
                with self.subTest(field=field, replacement=replacement):
                    setattr(self, field, {**original, 'records': replacement})
                    with self.assertRaises(ValueError):
                        self.prepare()
            setattr(self, field, original)
        self.catalog['records'].pop()
        with self.assertRaisesRegex(ValueError, 'omits transition identities'):
            self.prepare()

    def test_canonical_path_grammar_and_borrowed_source_identity(self):
        row = self.catalog['records'][0]
        original = row['path']
        for path in ('docs/decisions/0051-current.md',
                     'docs/decisions/current/unknown/0051-current.md',
                     'docs/decisions/current/continuity/../0051-current.md',
                     'docs/decisions/current//continuity/0051-current.md',
                     '/docs/decisions/current/continuity/0051-current.md',
                     'docs/decisions/current/continuity/0052-current.md',
                     'docs/decisions/current/continuity/0051-substitute.md',
                     'docs\\decisions\\current\\continuity\\0051-current.md'):
            with self.subTest(path=path):
                row['path'] = path
                with self.assertRaises(ValueError):
                    self.prepare()
        row['path'] = original
        row['path'] = original.replace('/continuity/', '/verification/')
        with self.assertRaisesRegex(ValueError, 'misroutes source semantic partition'):
            self.prepare()
        row['path'] = original
        row['type'] = 'borrowed type'
        with self.assertRaisesRegex(ValueError, 'path/type substitutes'):
            self.prepare()

    def test_sealed_and_unused_transition_ids_cannot_be_borrowed(self):
        row = self.catalog['records'][0]
        row.update(id='0001', path='docs/decisions/current/continuity/0001-first.md')
        with self.assertRaisesRegex(ValueError, 'omits transition identities'):
            self.prepare()
        self.catalog['records'].insert(0, copy.deepcopy(row))
        self.catalog['records'][1] = {'id': '0051', 'path': 'docs/decisions/current/continuity/0051-current.md',
                                     'type': 'architecture', 'metadata': self.source['records'][1]['metadata'],
                                     'content': content(SECOND)}
        with self.assertRaisesRegex(ValueError, 'borrows sealed identity'):
            self.prepare()
        self.catalog['records'][0].update(id='0049', path='docs/decisions/current/continuity/0049-fresh.md')
        with self.assertRaisesRegex(ValueError, 'borrows transition ID space'):
            self.prepare()

    def test_source_revision_original_path_text_metadata_and_heading_controls(self):
        for field in ('source', 'originals', 'catalog'):
            original = getattr(self, field)['source_revision']
            getattr(self, field)['source_revision'] = 'b' * 40
            with self.assertRaisesRegex(ValueError, 'revision substitution'):
                self.prepare()
            getattr(self, field)['source_revision'] = original
        row = self.originals['records'][0]
        row['path'] = 'docs/decisions/0001-wrong.md'
        with self.assertRaisesRegex(ValueError, 'path/text substitution'):
            self.prepare()
        row['path'] = self.source['records'][0]['path']
        row['text'] = FIRST.replace('Keep', 'Lose')
        with self.assertRaisesRegex(ValueError, 'digest changed'):
            self.prepare()
        row['text'] = FIRST
        for key, value in [('metadata', EMPTY), ('headings', ['# wrong'])]:
            original = self.source['records'][0][key]
            self.source['records'][0][key] = value
            with self.assertRaisesRegex(ValueError, 'metadata/headings changed'):
                self.prepare()
            self.source['records'][0][key] = original

    def test_content_dimensions_digest_and_copied_metadata_are_not_authority(self):
        row = self.catalog['records'][0]
        for key, value in [('bytes', True), ('lines', '17'), ('line_bytes', 0),
                           ('sha256', 'f' * 64), ('sha256', 'invalid')]:
            original = row['content'][key]
            row['content'][key] = value
            with self.assertRaises(ValueError):
                self.prepare()
            row['content'][key] = original
        row['metadata']['knowledge_status'] = 'borrowed'
        with self.assertRaisesRegex(ValueError, 'metadata differs from record'):
            self.prepare()

    def test_substituted_body_identity_and_lost_questions_even_with_fresh_digest(self):
        row = self.catalog['records'][0]
        for bad, message in [(SECOND.replace('# 0051', '# 0052'), 'body borrows'),
                             (SECOND.replace('which fixture is current?', 'different question?'),
                              'loses source fact identity/questions')]:
            self.write(row['path'], bad)
            row['content'] = content(bad)
            if 'different question?' in bad:
                row['metadata']['questions'] = ['different question?']
            with self.assertRaisesRegex(ValueError, message):
                self.prepare()

    def test_later_status_changes_are_distinct_from_initial_transition_preservation(self):
        row = self.catalog['records'][0]
        changed = SECOND.replace('- Status: accepted', '- Status: superseded')
        self.write(row['path'], changed)
        row['content'] = content(changed)
        row['metadata']['authority_status'] = ['- Status: superseded']
        prepared = self.prepare()
        self.assertEqual(prepared['originals']['0051'], SECOND)
        with self.assertRaisesRegex(ValueError, 'transition metadata changed'):
            catalog_api.verify_transition_metadata(prepared)

    def test_unresolved_and_symlinked_sources_including_parent_component(self):
        row = self.catalog['records'][0]
        path = self.root / row['path']
        path.unlink()
        with self.assertRaisesRegex(ValueError, 'unresolved regular source'):
            self.prepare()
        target = self.root / 'retained.md'
        target.write_text(SECOND)
        path.symlink_to(target)
        with self.assertRaisesRegex(ValueError, 'symlink'):
            self.prepare()
        path.unlink()
        directory = path.parent
        directory.rmdir()
        elsewhere = self.root / 'elsewhere'
        elsewhere.mkdir()
        (elsewhere / path.name).write_text(SECOND)
        directory.symlink_to(elsewhere, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, 'symlink'):
            self.prepare()

    def test_selected_bytes_accessor_uses_the_same_identity_contract(self):
        captured = {self.catalog['records'][0]['path']: SECOND.encode(),
                    self.catalog['records'][1]['path']: THIRD.encode()}
        result = catalog_api.prepare(self.root, self.source, self.originals, self.catalog,
                                     reader=captured.__getitem__)
        self.assertEqual(result['current']['0100']['text'], THIRD)
        captured[self.catalog['records'][0]['path']] = THIRD.encode()
        with self.assertRaisesRegex(ValueError, 'dimensions or digest changed'):
            catalog_api.prepare(self.root, self.source, self.originals, self.catalog,
                                reader=captured.__getitem__)

    def test_closed_schema_and_document_and_record_bounds(self):
        for field in ('source', 'originals', 'catalog'):
            getattr(self, field)['extra'] = 'unknown'
            with self.assertRaisesRegex(ValueError, 'unexpected fields'):
                self.prepare()
            del getattr(self, field)['extra']
        with self.assertRaisesRegex(ValueError, 'duplicate JSON key'):
            catalog_api.decode_document(b'{"id":"0001","id":"0002"}')
        with self.assertRaisesRegex(ValueError, 'byte bound'):
            catalog_api.decode_document(b' ' * (catalog_api.MAX_DOCUMENT_BYTES + 1))
        row = self.catalog['records'][0]
        row['content']['bytes'] = catalog_api.MAX_RECORD_BYTES + 1
        with self.assertRaisesRegex(ValueError, 'invalid bytes dimension'):
            self.prepare()

    def test_failed_preparation_leaves_caller_kinds_and_values_unchanged(self):
        self.catalog['records'][0]['content']['bytes'] = True
        before = json.dumps([self.source, self.originals, self.catalog], sort_keys=True)
        with self.assertRaisesRegex(ValueError, 'invalid bytes dimension'):
            self.prepare()
        self.assertEqual(json.dumps([self.source, self.originals, self.catalog], sort_keys=True), before)
        self.assertIs(self.catalog['records'][0]['content']['bytes'], True)

    def test_population_schema_and_sealed_source_classification_are_closed(self):
        self.catalog['schema_version'] = True
        with self.assertRaisesRegex(ValueError, 'unsupported schema'):
            self.prepare()
        self.catalog['schema_version'] = 1
        self.source['records'][0]['kind'] = 'current'
        with self.assertRaisesRegex(ValueError, 'substitutes published sealed identity'):
            self.prepare()
        self.source['records'][0]['kind'] = 'sealed'
        self.catalog['records'] *= catalog_api.MAX_CURRENT_RECORDS
        with self.assertRaisesRegex(ValueError, 'invalid record population'):
            self.prepare()

    def test_link_status_normalization_inline_questions_and_duplicate_fact_id(self):
        text = ('---\nid: fixture\nanswers: ["which original?", "which current?"]\n'
                'status: current\n---\n# 0051 — Fixture\n\n'
                '- Status: superseded by [0100](0100-verification.md)\n')
        metadata, _ = catalog_api.record_facts(text, 'docs/decisions/0051-current.md', '0051')
        self.assertEqual(metadata['questions'], ['which original?', 'which current?'])
        self.assertEqual(metadata['authority_status'],
                         ['- Status: superseded by [0100](docs/decisions/0100-verification.md)'])
        relocated = text.replace('(0100-verification.md)', '(../../0100-verification.md)')
        moved, _ = catalog_api.record_facts(relocated, self.catalog['records'][0]['path'], '0051')
        self.assertEqual(moved, metadata)
        row = self.catalog['records'][1]
        bad = SECOND.replace('0051', '0100')
        self.write(row['path'], bad)
        row.update(content=content(bad), metadata=copy.deepcopy(self.catalog['records'][0]['metadata']))
        with self.assertRaisesRegex(ValueError, 'loses source fact identity/questions'):
            self.prepare()

    def test_equal_metadata_does_not_allow_a_fresh_record_to_borrow_a_fact_id(self):
        row = {'id': '0115', 'path': 'docs/decisions/current/language-api/0115-fresh.md',
               'type': 'architecture', 'metadata': copy.deepcopy(self.catalog['records'][0]['metadata']),
               'content': content(SECOND.replace('0051', '0115'))}
        self.catalog['records'].append(row)
        self.write(row['path'], SECOND.replace('0051', '0115'))
        with self.assertRaisesRegex(ValueError, 'duplicate current knowledge ID'):
            self.prepare()

    def test_fake_fence_closer_and_unterminated_examples_cannot_supply_headings(self):
        text = '# 0051 — Fixture\n\n```md\n```language\n# 9999 — still an example\n```\n\n  ## Actual heading\n'
        _, headings = catalog_api.record_facts(text, 'docs/decisions/0051-current.md', '0051')
        self.assertEqual(headings, ['# 0051 — Fixture', '  ## Actual heading'])
        self.assertEqual(list(catalog_api.visible_lines('```inline```\n\n```md\nignored\n```\t\nkept\n')),
                         ['```inline```', '', 'kept'])
        with self.assertRaisesRegex(ValueError, 'unterminated'):
            catalog_api.record_facts(text.replace('```\n\n  ##', '\n\n  ##'),
                                     'docs/decisions/0051-current.md', '0051')


if __name__ == '__main__':
    unittest.main()
