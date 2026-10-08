"""Selected object IDs and post-transition births cannot borrow ambient state."""

import copy
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import decision_store_git as selected
import decision_records as published
import test_decision_store as fixtures
import test_decision_catalog as literals
from test_decision_production_growth import ProductionFixture, SOURCE, REGISTRY, AUTHORITIES


class SelectedStoreAccess(unittest.TestCase):
    def setUp(self):
        self.fixture = fixtures.AuthenticatedDecisionStore()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)
        self.root = self.fixture.root
        self.git('init', '-q')
        self.git('add', '.')
        self.git('commit', '-q', '-m', 'fixture initial store')

    def git(self, *arguments, input=None):
        result = subprocess.run(['git', '-C', str(self.root),
                                 '-c', 'user.name=Decision Store Fixture',
                                 '-c', 'user.email=fixture@example.invalid',
                                 '-c', 'commit.gpgsign=false', '-c', 'core.hooksPath=.fixture-hooks',
                                 *arguments], input=input, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def load(self, snapshot):
        store = fixtures.store.load(self.root, self.fixture.source_digest, self.fixture.index_digest,
                                    reader=snapshot.read)
        routes = fixtures.store.verify(self.root, store, reader=snapshot.read, paths=snapshot.root_paths)
        fixtures.store.verify_transition(store, routes)
        return store

    def test_index_and_resolved_revision_use_exact_regular_blob_products(self):
        expected = self.git('rev-parse', 'HEAD').decode().strip()
        for selector in ('index', 'HEAD', expected):
            with self.subTest(selector=selector):
                snapshot = selected.GitSnapshot(self.root, selector)
                prepared = self.load(snapshot)
                self.assertEqual(prepared['original_index'], fixtures.ORIGINAL_INDEX)
                self.assertEqual(snapshot.read(fixtures.store.INDEX), fixtures.ROOT_INDEX.encode())
                self.assertEqual(snapshot.revision, None if selector == 'index' else expected)

    def test_captured_index_and_head_survive_later_index_commit_and_worktree_changes(self):
        index = selected.GitSnapshot(self.root, 'index')
        head = selected.GitSnapshot(self.root, 'HEAD')
        self.fixture.write(fixtures.store.INDEX, '# Later wrong index\n')
        self.git('add', fixtures.store.INDEX)
        self.git('commit', '-q', '-m', 'fixture changed index')
        self.assertEqual(index.read(fixtures.store.INDEX), fixtures.ROOT_INDEX.encode())
        self.assertEqual(head.read(fixtures.store.INDEX), fixtures.ROOT_INDEX.encode())
        self.load(index)
        self.load(head)
        current = selected.GitSnapshot(self.root, 'HEAD')
        with self.assertRaisesRegex(ValueError, 'membership'):
            self.load(current)

    def test_unstaged_data_cannot_replace_a_selected_blob(self):
        snapshot = selected.GitSnapshot(self.root, 'index')
        path = self.fixture.catalog['records'][0]['path']
        self.fixture.write(path, '# Wrong ambient body\n')
        self.assertEqual(snapshot.read(path), literals.SECOND.encode())
        self.load(snapshot)

    def test_replace_refs_cannot_change_captured_object_identity(self):
        snapshot = selected.GitSnapshot(self.root, 'HEAD')
        original = snapshot.objects[fixtures.store.INDEX][1]
        replacement = self.git('hash-object', '-w', '--stdin', input=b'wrong replacement\n').decode().strip()
        self.git('replace', original, replacement)
        self.assertEqual(self.git('cat-file', 'blob', original), b'wrong replacement\n')
        self.assertEqual(snapshot.read(fixtures.store.INDEX), fixtures.ROOT_INDEX.encode())
        self.load(snapshot)

    def test_symlink_and_gitlink_are_never_regular_sources(self):
        path = self.root / self.fixture.catalog['records'][0]['path']
        original = path.read_bytes()
        path.unlink()
        retained = self.root / 'retained-source'
        retained.write_bytes(original)
        path.symlink_to(retained)
        self.git('add', str(path.relative_to(self.root)))
        snapshot = selected.GitSnapshot(self.root, 'index')
        with self.assertRaisesRegex(ValueError, 'not a regular blob'):
            snapshot.read(str(path.relative_to(self.root)))
        revision = self.git('rev-parse', 'HEAD').decode().strip()
        self.git('update-index', '--add', '--cacheinfo', f'160000,{revision},docs/decisions/external.md')
        snapshot = selected.GitSnapshot(self.root, 'index')
        with self.assertRaisesRegex(ValueError, 'not a regular blob'):
            snapshot.read('docs/decisions/external.md')

    def test_conflicting_stages_are_refused_before_reading(self):
        path = 'docs/decisions/INDEX.md'
        first = self.git('hash-object', '-w', '--stdin', input=b'first\n').decode().strip()
        second = self.git('hash-object', '-w', '--stdin', input=b'second\n').decode().strip()
        records = f'0 {"0" * 40}\t{path}\n100644 {first} 1\t{path}\n100644 {second} 2\t{path}\n'
        self.git('update-index', '--index-info', input=records.encode())
        with self.assertRaisesRegex(ValueError, 'conflicting Git index stages'):
            selected.GitSnapshot(self.root, 'index')

    def test_complete_repository_growth_uses_existing_byte_budget(self):
        # Actual index/tree products cross the retired arbitrary count, while
        # independent literal record sizes stay inside the unchanged byte cap.
        self.assertEqual(selected.MAX_INVENTORY_BYTES, 4_194_304)
        count = 20_001
        object_id = self.git('hash-object', '-w', '--stdin', input=b'retained unrelated data\n').decode().strip()
        paths = [f'unrelated/f{i:05}.bin' for i in range(count)]
        records = ''.join(f'100644 {object_id}\t{path}\n' for path in paths).encode()
        self.git('update-index', '--index-info', input=records)
        self.git('commit', '-q', '-m', 'fixture unrelated repository growth')
        for selector, command in [('index', ('ls-files', '--stage', '-z')),
                                  ('HEAD', ('ls-tree', '-r', '--full-tree', '-z', 'HEAD'))]:
            with self.subTest(selector=selector):
                listing = self.git(*command)
                self.assertGreater(len(listing.split(b'\0')) - 1, count)
                self.assertLess(len(listing), 4_194_304)
                snapshot = selected.GitSnapshot(self.root, selector)
                self.assertEqual(set(snapshot.objects), {record.split(b'\t', 1)[1].decode()
                                  for record in listing.split(b'\0')[:-1]})
                self.assertEqual(snapshot.read(paths[-1]), b'retained unrelated data\n')
                self.load(snapshot)
        # Real Git output, rather than a mocked accessor, crosses the original
        # byte budget; neither selector may truncate or accept that inventory.
        long_paths = [f'overflow/{"x" * 160}{i:05}.bin' for i in range(count)]
        self.git('update-index', '--index-info', input=''.join(
            f'100644 {object_id}\t{path}\n' for path in long_paths).encode())
        self.git('commit', '-q', '-m', 'fixture byte overflow')
        for selector, command in [('index', ('ls-files', '--stage', '-z')),
                                  ('HEAD', ('ls-tree', '-r', '--full-tree', '-z', 'HEAD'))]:
            with self.subTest(overflow_selector=selector):
                self.assertGreater(len(self.git(*command)), 4_194_304)
                with self.assertRaisesRegex(ValueError, 'Git output exceeds selected snapshot bound'):
                    selected.GitSnapshot(self.root, selector)

    def test_equivalent_tree_and_index_fit_the_same_exact_byte_boundary(self):
        # Include path bytes which a text-oriented or quoted inventory could
        # silently change, and nonregular modes which must remain visible.
        names = ['ordinary.bin', 'spaces and \u03bb.bin', 'tab\tnewline\n.bin']
        for name in names:
            self.fixture.write(name, 'retained payload\n')
        (self.root / 'linked.bin').symlink_to('ordinary.bin')
        self.git('add', '.')
        revision = self.git('rev-parse', 'HEAD').decode().strip()
        self.git('update-index', '--add', '--cacheinfo', f'160000,{revision},external')
        self.git('commit', '-q', '-m', 'fixture complete mode and raw path inventory')
        index_bytes = self.git('ls-files', '--stage', '-z')
        tree_bytes = self.git('ls-tree', '-r', '--full-tree', '-z', 'HEAD')
        self.assertGreater(len(tree_bytes), len(index_bytes))
        # The standard tree enumeration is the independent allocation oracle;
        # this does not borrow the production --format expression.
        expected = {}
        for record in tree_bytes.split(b'\0')[:-1]:
            header, path = record.split(b'\t', 1)
            mode, kind, object_id = header.decode('ascii').split()
            self.assertIn(kind, ('blob', 'commit'))
            expected[path.decode('utf-8')] = (mode, object_id)
        with patch.object(selected, 'MAX_INVENTORY_BYTES', len(index_bytes)):
            # The old tree producer fails at this same population/bound.
            snapshot = selected.GitSnapshot(self.root, 'index')
            with self.assertRaisesRegex(ValueError, 'Git output exceeds selected snapshot bound'):
                snapshot._git('ls-tree', '-r', '--full-tree', '-z', 'HEAD',
                              maximum=len(index_bytes))
            for selector in ('index', 'HEAD'):
                with self.subTest(selector=selector):
                    snapshot = selected.GitSnapshot(self.root, selector)
                    self.assertEqual(snapshot.objects, expected)
                    self.load(snapshot)
                    for name in names[:2]:
                        self.assertEqual(snapshot.read(name), b'retained payload\n')
                    with self.assertRaisesRegex(ValueError, 'file path: invalid string'):
                        snapshot.read(names[2])
                    for name in ('linked.bin', 'external'):
                        with self.assertRaisesRegex(ValueError, 'not a regular blob'):
                            snapshot.read(name)
        with patch.object(selected, 'MAX_INVENTORY_BYTES', len(index_bytes) - 1):
            for selector in ('index', 'HEAD'):
                with self.subTest(overflow_selector=selector):
                    with self.assertRaisesRegex(ValueError, 'Git output exceeds selected snapshot bound'):
                        selected.GitSnapshot(self.root, selector)

    def test_unsafe_missing_unbounded_selectors_paths_and_blobs_refuse(self):
        for selector in ('HEAD:docs/decisions/INDEX.md', '--help', '../HEAD', 'HEAD~99'):
            with self.subTest(selector=selector):
                with self.assertRaisesRegex(ValueError, 'snapshot selector'):
                    selected.GitSnapshot(self.root, selector)
        snapshot = selected.GitSnapshot(self.root, 'HEAD')
        for path, message in [('../README.md', 'unsafe path'), ('docs//decisions/INDEX.md', 'unsafe path'),
                              ('missing.md', 'unresolved selected source'),
                              ('docs/decisions', 'unresolved selected source')]:
            with self.subTest(path=path):
                with self.assertRaisesRegex(ValueError, message):
                    snapshot.read(path)
        self.fixture.write('large.bin', 'a' * (selected.catalog_api.MAX_DOCUMENT_BYTES + 1))
        self.git('add', 'large.bin')
        large = selected.GitSnapshot(self.root, 'index')
        with self.assertRaisesRegex(ValueError, 'exceeds byte bound'):
            large.read('large.bin')
        object_id = snapshot.objects[fixtures.store.INDEX][1]
        with self.assertRaisesRegex(ValueError, 'output exceeds selected snapshot bound'):
            snapshot._git('cat-file', 'blob', object_id, maximum=1)


class ScopedStoreAccess(unittest.TestCase):
    """The same store oracle checks finite scope and independent native data."""

    setUp = SelectedStoreAccess.setUp
    git = SelectedStoreAccess.git
    load = SelectedStoreAccess.load

    def scoped(self, selector='index', *, files=(SOURCE,), subtrees=('docs/decisions',)):
        return selected.GitSnapshot(self.root, selector, files=files, subtrees=subtrees)

    def test_scope_preserves_captured_blobs_and_complete_decision_membership(self):
        snapshots = [self.scoped(selector) for selector in ('index', 'HEAD')]
        for snapshot in snapshots:
            self.load(snapshot)
            self.assertEqual(snapshot.root_paths, selected.GitSnapshot(self.root, 'HEAD').root_paths)
        self.fixture.write(fixtures.store.INDEX, '# Wrong later index\n')
        self.git('add', fixtures.store.INDEX)
        self.git('commit', '-q', '-m', 'fixture later scoped source')
        for snapshot in snapshots:
            self.assertEqual(snapshot.read(fixtures.store.INDEX), fixtures.ROOT_INDEX.encode())
            self.load(snapshot)

    def test_exact_ancestor_pathspec_preserves_special_utf8_bytes_without_descendants(self):
        names = ('!parent', '^parent', '-parent', ']parent', '[parent', '*parent', '?parent',
                 'λ', 'plain[*?]λ', 'parent]tag')
        oid = self.git('hash-object', '-w', '--stdin', input=b'opaque parent\n').decode().strip()
        self.git('update-index', '--index-info', input=''.join(
            f'100644 {oid}\t{name}\n' for name in names).encode())
        self.fixture.write('near/source/opaque.txt', 'unselected descendant\n')
        self.git('add', 'near')
        self.git('commit', '-q', '-m', 'fixture exact ancestor metadata')
        files = tuple(name + '/source.json' for name in names) + ('near/source',)
        for selector in ('index', 'HEAD'):
            with self.subTest(selector=selector):
                snapshot = self.scoped(selector, files=files, subtrees=())
                self.assertEqual(snapshot.objects, {name: ('100644', oid) for name in names})
                for name in names:
                    with self.assertRaisesRegex(ValueError, 'nondirectory ancestor'):
                        snapshot.read(name + '/source.json')
                    with self.assertRaisesRegex(ValueError, 'outside declared scope'):
                        snapshot.read(name)
                with self.assertRaisesRegex(ValueError, 'unresolved selected source'):
                    snapshot.read('near/source')

    def test_scoped_conflicts_modes_missing_and_oversized_sources_still_refuse(self):
        path = 'docs/decisions/INDEX.md'
        oid = self.git('hash-object', '-w', '--stdin', input=b'conflicting source\n').decode().strip()
        self.git('update-index', '--index-info', input=(
            f'0 {"0" * 40}\t{path}\n100644 {oid} 1\t{path}\n100644 {oid} 2\t{path}\n').encode())
        with self.assertRaisesRegex(ValueError, 'conflicting Git index stages'):
            self.scoped()
        self.git('reset', '-q', 'HEAD', '--', path)
        revision = self.git('rev-parse', 'HEAD').decode().strip()
        self.git('update-index', '--add', '--cacheinfo', f'160000,{revision},external')
        self.git('update-index', '--add', '--cacheinfo', f'120000,{oid},linked')
        self.fixture.write('large.bin', 'x' * (selected.catalog_api.MAX_DOCUMENT_BYTES + 1))
        self.git('add', 'large.bin')
        self.git('commit', '-q', '-m', 'fixture scoped refusal modes')
        for selector in ('index', 'HEAD'):
            snapshot = self.scoped(selector, files=('external', 'linked', 'large.bin', 'missing'), subtrees=())
            for name in ('external', 'linked'):
                with self.assertRaisesRegex(ValueError, 'not a regular blob'):
                    snapshot.read(name)
            with self.assertRaisesRegex(ValueError, 'exceeds byte bound'):
                snapshot.read('large.bin')
            with self.assertRaisesRegex(ValueError, 'unresolved selected source'):
                snapshot.read('missing')

    def test_scope_declarations_are_closed_and_bounded(self):
        for files in (True, (), (True,), ([],), ('../outside',), ('a' * 513,),
                      tuple('a' for _ in range(selected.catalog_api.MAX_SOURCE_RECORDS + 1))):
            with self.subTest(files=repr(files)[:80]):
                with self.assertRaises(ValueError):
                    self.scoped(files=files, subtrees=())
        with self.assertRaisesRegex(ValueError, 'explicit source scope'):
            selected.GitSnapshot(self.root, 'index', subtrees=('docs/decisions',))

    def test_separate_exact_tree_queries_share_one_aggregate_byte_budget(self):
        for name in ('first', 'second'):
            self.fixture.write(name, 'bounded source\n')
        self.git('add', 'first', 'second')
        self.git('commit', '-q', '-m', 'fixture separate exact source queries')
        baseline = self.scoped(files=('first', 'second'), subtrees=())
        with patch.object(selected, 'MAX_INVENTORY_BYTES', baseline.inventory_bytes - 1):
            for selector in ('index', 'HEAD'):
                with self.subTest(selector=selector):
                    with self.assertRaisesRegex(ValueError, 'output exceeds selected snapshot bound'):
                        self.scoped(selector, files=('first', 'second'), subtrees=())


class InstalledSourceScope(unittest.TestCase):
    def setUp(self):
        self.fixture = ProductionFixture()
        self.addCleanup(self.fixture.close)
        self.root = self.fixture.root
        for name in ('decision_records', 'decision_store_git', 'decision_store', 'decision_catalog'):
            self.fixture.write(f'scripts/{name}.py', (ROOT / f'scripts/{name}.py').read_bytes())
        self.fixture.git('add', 'scripts')
        self.fixture.git('commit', '-q', '-m', 'fixture current public reader')

    def store(self, snapshot):
        return published.selected_store(self.root, snapshot, False,
                                        published.STORE_SOURCE_SHA256, published.STORE_INDEX_SHA256)

    def grow(self, prefix):
        def git_input(*arguments, data):
            result = subprocess.run(['git', '-C', str(self.root), *arguments], input=data,
                                    capture_output=True, timeout=60)
            self.assertEqual(result.returncode, 0, result.stderr)
            return result.stdout

        oid = git_input('hash-object', '-w', '--stdin', data=b'opaque unrelated data\n').decode().strip()
        names = [prefix + '/' + 'x' * 160 + f'{i:05}.bin' for i in range(20_001)]
        git_input('update-index', '--index-info', data=''.join(
            f'100644 {oid}\t{name}\n' for name in names).encode())
        self.fixture.git('commit', '-q', '-m', 'fixture real native byte overflow')

    def test_unrelated_overflow_authenticates_identical_installed_products(self):
        bindings = (REGISTRY, AUTHORITIES)
        baseline = published.selected_snapshot(self.root, 'index', bindings=bindings)
        prepared = self.store(baseline)
        self.grow('unrelated')
        revision = self.fixture.git('rev-parse', 'HEAD').decode().strip()
        for selector in ('index', 'HEAD', revision):
            with self.subTest(selector=selector):
                with self.assertRaisesRegex(ValueError, 'output exceeds selected snapshot bound'):
                    selected.GitSnapshot(self.root, selector)
                snapshot = published.selected_snapshot(self.root, selector, bindings=bindings)
                self.assertEqual(snapshot.objects, baseline.objects)
                self.assertEqual(snapshot.inventory_bytes, baseline.inventory_bytes)
                self.assertEqual(self.store(snapshot), prepared)
                result = self.fixture.public('check', selector=selector, installed=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, b'decision-records: authenticated originals, current records, compatibility and indexes verified\n')
                self.assertEqual(result.stderr, b'')
                with self.assertRaisesRegex(ValueError, 'outside declared scope'):
                    snapshot.read('unrelated/' + 'x' * 160 + '00000.bin')

    def test_relevant_native_overflow_keeps_the_original_budget(self):
        self.grow('docs/decisions/opaque')
        for selector in ('index', 'HEAD'):
            with self.subTest(selector=selector):
                with self.assertRaisesRegex(ValueError, 'output exceeds selected snapshot bound'):
                    published.selected_snapshot(self.root, selector)

    def test_bootstrap_and_final_index_census_modes_and_objects_must_join(self):
        original = selected.GitSnapshot
        fixture = self.fixture
        events = []

        initial = original(self.root, 'index', files=(published.CENSUS,)).objects[published.CENSUS]
        other = self.root / 'other-census.json'
        other.write_text('{}\n')
        replacement = fixture.git('hash-object', '-w', 'other-census.json').decode().strip()
        for mode, object_id in (('100755', initial[1]), (initial[0], replacement)):
            with self.subTest(mode=mode, object_id=object_id):
                events.clear()

                class ChangingIndex(original):
                    def __init__(self, root, selector, **scope):
                        super().__init__(root, selector, **scope)
                        events.append((selector, scope))
                        if published.CENSUS in scope.get('files', ()) and not scope.get('subtrees'):
                            fixture.git('update-index', '--cacheinfo', f'{mode},{object_id},{published.CENSUS}')

                with patch.object(selected, 'GitSnapshot', ChangingIndex):
                    with self.assertRaisesRegex(ValueError, 'census object changed between source captures'):
                        published.selected_snapshot(self.root, 'index')
                self.assertEqual(len(events), 2)
                self.assertEqual(events[1][0], 'index')
                fixture.git('update-index', '--cacheinfo', f'{initial[0]},{initial[1]},{published.CENSUS}')

    def test_head_advance_cannot_retarget_final_source_capture(self):
        revision = self.fixture.git('rev-parse', 'HEAD').decode().strip()
        original = selected.GitSnapshot
        fixture = self.fixture
        events = []

        class AdvancingHead(original):
            def __init__(self, root, selector, **scope):
                super().__init__(root, selector, **scope)
                events.append((selector, scope))
                if published.CENSUS in scope.get('files', ()) and not scope.get('subtrees'):
                    fixture.write(published.CENSUS, '{}\n')
                    fixture.git('add', published.CENSUS)
                    fixture.git('commit', '-q', '-m', 'fixture changed later census')

        with patch.object(selected, 'GitSnapshot', AdvancingHead):
            snapshot = published.selected_snapshot(self.root, 'HEAD')
        self.assertNotEqual(self.fixture.git('rev-parse', 'HEAD').decode().strip(), revision)
        self.assertEqual(snapshot.revision, revision)
        self.assertEqual(events[1][0], revision)
        self.store(snapshot)

    def test_untrusted_census_is_refused_before_dependency_selection(self):
        self.fixture.write(published.CENSUS, '{}\n')
        self.fixture.git('add', published.CENSUS)
        with self.assertRaisesRegex(ValueError, 'independent source census changed'):
            published.selected_snapshot(self.root, 'index')

    def test_link_targets_consumers_and_control_files_are_real_selected_inputs(self):
        snapshot = published.selected_snapshot(self.root, 'index', bindings=(REGISTRY, AUTHORITIES))
        for name in ('README_POLICY.md', REGISTRY, AUTHORITIES):
            self.assertEqual(snapshot.read(name), self.fixture.original_products[name])
        census = published.json.loads(snapshot.read(published.CENSUS))
        path = next(row['path'] for row in census['body_or_identity_consumers']
                    if row['text'].startswith('reverify:'))
        self.fixture.write(path, 'reverify: obsolete forwarding-page search\n')
        self.fixture.git('add', path)
        self.store(snapshot)  # The saved reader remains detached from the index.
        with self.assertRaisesRegex(ValueError, 'reverify omits exact record reader'):
            self.store(published.selected_snapshot(self.root, 'index'))

    def test_complete_flat_compatibility_membership_still_refuses_a_missing_root(self):
        snapshot = published.selected_snapshot(self.root, 'index')
        path = next(path for path in snapshot.root_paths if path != published.INDEX)
        self.fixture.git('update-index', '--force-remove', path)
        with self.assertRaisesRegex(ValueError, 'compatibility root membership differs'):
            self.store(published.selected_snapshot(self.root, 'index'))


class PriorCurrentContinuity(unittest.TestCase):
    def setUp(self):
        self.fixture = fixtures.AuthenticatedDecisionStore()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)
        self.fixture.test_complete_fresh_navigation_keeps_fixed_compatibility_and_original_index()
        self.prior, _ = self.fixture.check()
        self.current = copy.deepcopy(self.prior)

    def test_content_status_summary_and_additive_fact_changes_remain_current(self):
        self.current['current']['0115']['text'] += 'Owned later rationale.\n'
        self.current['current']['0115']['metadata']['knowledge_id'] = 'new-first-fact'
        self.current['current']['0115']['metadata']['questions'] = ['which new fact?']
        selected.verify_continuity(self.prior, self.current)
        self.assertIsNone(self.prior['current']['0115']['metadata']['knowledge_id'])

    def test_actual_self_consistent_post_transition_deletion_is_now_refused(self):
        self.fixture.catalog['records'].pop()
        self.fixture.write_json(fixtures.store.CATALOG, self.fixture.catalog)
        self.fixture.write(fixtures.store.INDEX, fixtures.ROOT_INDEX)
        self.fixture.write('docs/decisions/current/language-api/INDEX.md', fixtures.PART_PREFIX)
        (self.fixture.root / 'docs/decisions/current/language-api/0115-fresh.md').unlink()
        current, _ = self.fixture.check()
        with self.assertRaisesRegex(ValueError, 'deleted a prior decision identity'):
            selected.verify_continuity(self.prior, current)

    def test_originals_source_index_and_equal_count_id_or_path_recycling_refuse(self):
        for key in ('source_revision', 'source_sha256', 'original_index_sha256',
                    'compatibility', 'originals', 'original_index', 'original_routes'):
            with self.subTest(key=key):
                current = copy.deepcopy(self.prior)
                current[key] = 'substitution'
                with self.assertRaisesRegex(ValueError, 'immutable store source changed'):
                    selected.verify_continuity(self.prior, current)
        for key, value in [('path', 'docs/decisions/current/language-api/0115-recycled.md'),
                           ('type', 'borrowed type')]:
            current = copy.deepcopy(self.prior)
            current['current']['0115'][key] = value
            with self.assertRaisesRegex(ValueError, 'recycles a prior decision identity'):
                selected.verify_continuity(self.prior, current)
        current = copy.deepcopy(self.prior)
        current['current']['0116'] = current['current'].pop('0115')
        with self.assertRaisesRegex(ValueError, 'deleted a prior decision identity'):
            selected.verify_continuity(self.prior, current)

    def test_post_transition_fact_ids_and_question_keys_are_retained(self):
        prior = copy.deepcopy(self.prior)
        prior['current']['0115']['metadata'].update(knowledge_id='born-fact', questions=['born question?'])
        for change, message in [({'knowledge_id': None}, 'loses prior fact identity'),
                                ({'knowledge_id': 'substitute'}, 'loses prior fact identity'),
                                ({'questions': []}, 'loses prior question keys')]:
            current = copy.deepcopy(prior)
            current['current']['0115']['metadata'].update(change)
            with self.assertRaisesRegex(ValueError, message):
                selected.verify_continuity(prior, current)

    def test_new_births_follow_the_prior_highest_identity(self):
        for identity, accepted in [('0110', False), ('0116', True)]:
            current = copy.deepcopy(self.prior)
            current['current'][identity] = {'id': identity}
            if accepted:
                selected.verify_continuity(self.prior, current)
            else:
                with self.assertRaisesRegex(ValueError, 'earlier decision ID space'):
                    selected.verify_continuity(self.prior, current)


if __name__ == '__main__':
    unittest.main()
