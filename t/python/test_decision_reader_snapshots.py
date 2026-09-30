"""Published snapshot products and atomic prior-relative bindings on real Git fixtures."""

import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
import test_decision_store as stores
import test_decision_catalog as literals
import test_decision_store_git as git_fixtures

ROOT = Path(__file__).resolve().parents[2]
CLI = ROOT / 'scripts/decision_records.py'


class PublishedSelectedReader(unittest.TestCase):
    def setUp(self):
        self.git_fixture = git_fixtures.SelectedStoreAccess()
        self.git_fixture.setUp()
        self.addCleanup(self.git_fixture.doCleanups)
        self.fixture = self.git_fixture.fixture
        self.root = self.fixture.root
        self.git = self.git_fixture.git

    def run_reader(self, *arguments, snapshot='index', prior=None, cli=CLI, root=None):
        command = [sys.executable, '-B', str(cli), '--root', str(root or self.root),
                   '--source-sha256', self.fixture.source_digest,
                   '--index-sha256', self.fixture.index_digest, '--snapshot', snapshot]
        if prior is not None:
            command += ['--prior-snapshot', prior]
        return subprocess.run(command + list(arguments), capture_output=True)

    def failure(self, result, message):
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(result.stdout, b'')
        self.assertIn(message.encode(), result.stderr)

    def fresh(self):
        self.fixture.test_complete_fresh_navigation_keeps_fixed_compatibility_and_original_index()

    def test_actual_read_check_and_resolve_consume_selected_bytes_and_inventory(self):
        revision = self.git('rev-parse', 'HEAD').decode().strip()
        path = self.fixture.catalog['records'][0]['path']
        self.fixture.write(path, '# Wrong ambient body\n')
        self.fixture.write('docs/decisions/9999-ambient.md', '# Wrong ambient identity\n')
        for selector in ('index', 'HEAD', revision):
            with self.subTest(selector=selector):
                checked = self.run_reader('check', snapshot=selector)
                self.assertEqual(checked.returncode, 0, checked.stderr)
                read = self.run_reader('read-current', '0051', snapshot=selector)
                self.assertEqual(read.returncode, 0, read.stderr)
                self.assertEqual(read.stdout, literals.SECOND.encode())
                resolved = self.run_reader('resolve', path, snapshot=selector)
                self.assertEqual(resolved.returncode, 0, resolved.stderr)
                self.assertEqual(json.loads(resolved.stdout)['content_sha256'], literals.content(literals.SECOND)['sha256'])
        self.failure(self.run_reader('check', snapshot='worktree'), 'record dimensions or digest changed')
        self.git('add', 'docs/decisions/9999-ambient.md')
        self.failure(self.run_reader('check'), 'compatibility root membership differs')

    def test_atomic_change_exposes_exact_prior_relative_freshness_in_all_modes(self):
        self.fresh()
        fresh_path = self.fixture.catalog['records'][-1]['path']
        old_path = self.fixture.catalog['records'][0]['path']
        self.git('add', '.')
        for selector in ('index', 'worktree'):
            result = self.run_reader('check-continuity', fresh_path, old_path, snapshot=selector, prior='HEAD')
            self.assertEqual(result.returncode, 0, result.stderr)
            product = json.loads(result.stdout)
            self.assertEqual(product['fresh_ids'], ['0115'])
            self.assertTrue(product['catalog'])
            self.assertTrue(product['resolved'][0]['fresh_identity'])
            self.assertTrue(product['resolved'][0]['new_file'])
            self.assertEqual(product['resolved'][0]['text'], literals.FRESH)
            self.assertFalse(product['resolved'][1]['fresh_identity'])
            self.assertFalse(product['resolved'][1]['new_file'])
            self.assertTrue(product['resolved'][1]['transition_identity'])
        self.git('commit', '-q', '-m', 'fixture fresh catalog birth')
        committed = self.run_reader('check-continuity', fresh_path, snapshot='HEAD', prior='HEAD^')
        self.assertEqual(committed.returncode, 0, committed.stderr)
        self.assertEqual(json.loads(committed.stdout)['fresh_ids'], ['0115'])
        already_published = self.run_reader('check-continuity', fresh_path, snapshot='HEAD', prior='HEAD')
        self.assertEqual(already_published.returncode, 0, already_published.stderr)
        self.assertFalse(json.loads(already_published.stdout)['resolved'][0]['fresh_identity'])

    def test_control_digest_bindings_are_selected_and_requests_are_atomic(self):
        self.fresh()
        self.git('add', '.')
        self.fixture.write(stores.store.INDEX, '# Wrong ambient index\n')
        result = self.run_reader('--bind-file', stores.store.INDEX, 'check-continuity', prior='HEAD')
        self.assertEqual(result.returncode, 0, result.stderr)
        expected_current = stores.ROOT_INDEX + '| [0115](current/language-api/0115-fresh.md) | Fresh | architecture | Later body. |\n'
        self.assertEqual(json.loads(result.stdout)['file_bindings'], {
            stores.store.INDEX: {'prior': hashlib.sha256(stores.ROOT_INDEX.encode()).hexdigest(),
                                'current': hashlib.sha256(expected_current.encode()).hexdigest()}})
        self.failure(self.run_reader('--bind-file', '../bad.md', 'check-continuity', prior='HEAD'), 'unsafe path')
        self.failure(self.run_reader('--bind-file', stores.store.INDEX, '--bind-file', stores.store.INDEX,
                                     'check-continuity', prior='HEAD'), 'invalid bounded control-file')
        self.failure(self.run_reader('--bind-file', stores.store.INDEX, 'check'), 'requires check-continuity')

    def test_post_transition_deletion_and_catalog_removal_refuse_without_partial_output(self):
        self.fresh()
        self.git('add', '.')
        self.git('commit', '-q', '-m', 'fixture published fresh birth')
        removed = self.fixture.catalog['records'].pop()
        (self.root / removed['path']).unlink()
        self.fixture.write_json(stores.store.CATALOG, self.fixture.catalog)
        self.fixture.write(stores.store.INDEX, stores.ROOT_INDEX)
        self.fixture.write('docs/decisions/current/language-api/INDEX.md', stores.PART_PREFIX)
        self.git('add', '.')
        standalone = self.run_reader('check')
        self.assertEqual(standalone.returncode, 0, standalone.stderr)
        self.failure(self.run_reader('check-continuity', prior='HEAD'), 'deleted a prior decision identity')
        (self.root / stores.store.CATALOG).unlink()
        self.git('add', '.')
        self.failure(self.run_reader('check-continuity', prior='HEAD'), 'catalog store removed')

    def test_change_product_bounds_json_escaping_before_any_output(self):
        root_rows, part_rows, paths = [], [], []
        # Each record is admissibly bounded, but JSON escaping expands the
        # complete requested text beyond the separate public output budget.
        for number in range(115, 126):
            identity = f'{number:04d}'
            path = f'docs/decisions/current/language-api/{identity}-fresh.md'
            text = literals.FRESH.replace('0115', identity) + ('\t' * 1_000 + '\n') * 50
            self.fixture.catalog['records'].append({
                'id': identity, 'path': path, 'type': 'architecture',
                'metadata': {**literals.EMPTY, 'authority_status': ['Status: proposed']},
                'content': literals.content(text)})
            self.fixture.write(path, text)
            cells = 'Fresh | architecture | Later body. |\n'
            root_rows.append(f'| [{identity}](current/language-api/{identity}-fresh.md) | ' + cells)
            part_rows.append(f'| [{identity}]({identity}-fresh.md) | ' + cells)
            paths.append(path)
        self.fixture.write_json(stores.store.CATALOG, self.fixture.catalog)
        self.fixture.write(stores.store.INDEX, stores.ROOT_INDEX + ''.join(root_rows))
        self.fixture.write('docs/decisions/current/language-api/INDEX.md', stores.PART_PREFIX + ''.join(part_rows))
        self.failure(self.run_reader('check-continuity', *paths, snapshot='worktree', prior='HEAD'),
                     'change product output exceeds byte bound')

    def adoption(self):
        (self.root / stores.store.CATALOG).unlink()
        for row in self.fixture.originals['records']:
            self.fixture.write(row['path'], row['text'])
        self.fixture.write(stores.store.INDEX, stores.ORIGINAL_INDEX)
        self.fixture.write_json('docs/decisions/history/0001-0050.json', {
            'schema_version': 1, 'source_revision': literals.REVISION,
            'records': [self.fixture.originals['records'][0]]})
        self.git('add', '.')
        self.git('commit', '-q', '-m', 'fixture exact flat predecessor')
        revision = self.git('rev-parse', 'HEAD').decode().strip()
        for document in (self.fixture.source, self.fixture.originals, self.fixture.catalog):
            document['source_revision'] = revision
        self.fixture.write_json(stores.store.SOURCE, self.fixture.source)
        self.fixture.write_json(stores.store.ORIGINALS, self.fixture.originals)
        self.fixture.write_json(stores.store.CATALOG, self.fixture.catalog)
        self.fixture.source_digest = hashlib.sha256((self.root / stores.store.SOURCE).read_bytes()).hexdigest()
        self.fixture.write(stores.store.INDEX, stores.ROOT_INDEX)
        for path, text in self.fixture.aliases.items():
            self.fixture.write(path, text)
        self.git('add', '.')

    def test_first_adoption_matches_selected_predecessor_revision_index_and_complete_originals(self):
        self.adoption()
        result = self.run_reader('check-continuity', prior='HEAD')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)['fresh_ids'], [])
        self.failure(self.run_reader('check-continuity', prior='HEAD^'), 'source census changed')
        revision = self.fixture.source['source_revision']
        for relative, document in [(stores.store.SOURCE, self.fixture.source),
                                   (stores.store.ORIGINALS, self.fixture.originals),
                                   (stores.store.CATALOG, self.fixture.catalog)]:
            document['source_revision'] = literals.REVISION
            self.fixture.write_json(relative, document)
        self.fixture.source_digest = hashlib.sha256((self.root / stores.store.SOURCE).read_bytes()).hexdigest()
        self.git('add', '.')
        self.failure(self.run_reader('check-continuity', prior='HEAD'), 'not the selected predecessor revision')
        for relative, document in [(stores.store.SOURCE, self.fixture.source),
                                   (stores.store.ORIGINALS, self.fixture.originals),
                                   (stores.store.CATALOG, self.fixture.catalog)]:
            document['source_revision'] = revision
            self.fixture.write_json(relative, document)
        # Keep all current products self-consistent, but corrupt the preceding
        # flat canonical body and bind the census to that exact new revision.
        self.git('reset', '-q')
        self.fixture.write('docs/decisions/0051-current.md', literals.SECOND + 'Changed predecessor.\n')
        self.git('add', 'docs/decisions/0051-current.md')
        self.git('commit', '-q', '-m', 'fixture changed predecessor body')
        revision = self.git('rev-parse', 'HEAD').decode().strip()
        for relative, document in [(stores.store.SOURCE, self.fixture.source),
                                   (stores.store.ORIGINALS, self.fixture.originals),
                                   (stores.store.CATALOG, self.fixture.catalog)]:
            document['source_revision'] = revision
            self.fixture.write_json(relative, document)
        self.fixture.source_digest = hashlib.sha256((self.root / stores.store.SOURCE).read_bytes()).hexdigest()
        self.fixture.write('docs/decisions/0051-current.md', self.fixture.aliases['docs/decisions/0051-current.md'])
        self.git('add', '.')
        self.failure(self.run_reader('check-continuity', prior='HEAD'), 'substitutes predecessor current original')

    def test_request_selector_authority_and_atomic_output_controls(self):
        self.failure(self.run_reader('check-continuity'), 'requires --prior-snapshot')
        for selector in ('worktree', 'index'):
            self.failure(self.run_reader('check-continuity', prior=selector), 'resolved Git revision')
        self.failure(self.run_reader('check', prior='HEAD'), 'other operations do not accept')
        self.failure(self.run_reader('check', snapshot='HEAD:README.md'), 'unsupported Git snapshot selector')
        path = self.fixture.catalog['records'][0]['path']
        self.failure(self.run_reader('check-continuity', path, path, prior='HEAD'), 'invalid bounded canonical')
        self.failure(self.run_reader('check-continuity', path, '../bad.md', prior='HEAD'), 'not an exact current canonical')
        self.failure(self.run_reader('check', root=ROOT), 'cannot override the actual repository authority')
        capsule = self.root / 'scripts'
        capsule.mkdir()
        for name in ('decision_records.py', 'decision_catalog.py', 'decision_store.py', 'decision_store_git.py'):
            source = (ROOT / 'scripts' / name).read_text()
            if name == 'decision_records.py':
                source = source.replace('STORE_SOURCE_SHA256 = None',
                                        'STORE_SOURCE_SHA256 = ' + repr(self.fixture.source_digest))
                source = source.replace('STORE_INDEX_SHA256 = None',
                                        'STORE_INDEX_SHA256 = ' + repr(self.fixture.index_digest))
            (capsule / name).write_text(source)
        self.failure(self.run_reader('check', cli=capsule / 'decision_records.py'),
                     'cannot override the actual repository authority')
        self.assertFalse(any(self.root.rglob('__pycache__')))


if __name__ == '__main__':
    unittest.main()
