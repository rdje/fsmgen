"""Exercise the real HTMLBatch path and deliberate delivery failures."""

import importlib.util
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('pod_reference', ROOT / 'scripts/generate_pod_reference.py')
api = importlib.util.module_from_spec(spec)
spec.loader.exec_module(api)


class PodReferenceTest(unittest.TestCase):
    def setUp(self):
        temporary = ROOT / '.artifacts/tmp'
        temporary.mkdir(parents=True, exist_ok=True)
        self.work = tempfile.TemporaryDirectory(prefix='pod-reference-test-', dir=temporary)
        self.addCleanup(self.work.cleanup)
        self.root = Path(self.work.name)
        for name in api.TOOLS:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        (self.root / 'docs/pod-api-entrypoints.json').write_text('{"FSM::Example":"Example facade"}\n')
        self.source = self.root / 'perl/FSM/Example.pm'
        self.source.parent.mkdir(parents=True)
        self.source.write_text('package FSM::Example;\ndie "Must never execute source";\n'
                               '=head1 NAME\n\nFSM::Example - example\n\n'
                               '=head1 METHODS\n\nL<FSM::Other/METHODS> and L<FSM::Undocumented>.\n\n=cut\n')
        (self.source.parent / 'Other.pm').write_text(
            '=head1 NAME\n\nFSM::Other - other\n\n=head1 METHODS\n\nOther methods.\n\n=cut\n')
        (self.source.parent / 'Undocumented.pm').write_text('package FSM::Undocumented;\n1;\n')
        manual = self.root / 'docs/book/src/11-extensions-and-embedding.md'
        manual.parent.mkdir(parents=True)
        manual.write_text('# Embedding\n')
        self.output = self.root / api.OUTPUT

    def build(self, **options):
        return api.generate(self.root, **options)

    def hashes(self):
        return {p.relative_to(self.output).as_posix(): api.digest(p.read_bytes())
                for p in self.output.rglob('*') if p.is_file()}

    def test_real_batch_links_coverage_and_no_module_execution(self):
        self.assertEqual(self.build(), 'generated')
        api.validate_links(self.output, self.root / 'docs/book/src')
        coverage = json.loads((self.output / 'coverage.json').read_text())
        self.assertEqual([(r['module'], r['pod'], r['role']) for r in coverage], [
            ('FSM::Example', True, 'selected_entry_point'),
            ('FSM::Other', True, 'implementation'), ('FSM::Undocumented', False, 'implementation')])
        self.assertIn('No POD is available', (self.output / 'FSM/Undocumented.html').read_text())
        self.assertIn('Other.html#METHODS', (self.output / 'FSM/Example.html').read_text())
        self.assertIn('Undocumented.html', (self.output / 'FSM/Example.html').read_text())

    def test_cache_writes_nothing_and_fresh_render_is_byte_identical(self):
        self.build()
        before = self.hashes()
        mtimes = {p: p.stat().st_mtime_ns for p in self.output.rglob('*')}
        self.assertEqual(self.build(), 'current')
        self.assertEqual(mtimes, {p: p.stat().st_mtime_ns for p in self.output.rglob('*')})
        shutil.rmtree(self.output)  # Exact test-owned generated fixture, not the project output.
        self.build()
        self.assertEqual(before, self.hashes())

    def test_source_change_requires_fresh_output(self):
        self.build()
        old = self.hashes()
        self.source.write_text(self.source.read_text().replace('example\n', 'changed example\n'))
        with self.assertRaisesRegex(api.ReferenceError, 'stale'):
            self.build(check=True)
        self.assertEqual(self.build(), 'generated')
        self.assertNotEqual(old, self.hashes())
        self.assertEqual(self.build(check=True), 'current')

    def test_python_runtime_identity_is_bound_and_stale_caches_are_refused(self):
        self.build()
        path = self.output / api.MARKER
        expected = {'implementation': sys.implementation.name,
                    'implementation_version': list(sys.implementation.version),
                    'language_version': list(sys.version_info)}
        manifest = json.loads(path.read_bytes())
        self.assertEqual(manifest['inputs']['versions']['python'], expected)
        original = self.hashes()
        for absent in (True, False):
            with self.subTest(missing_runtime=absent):
                saved = json.loads(path.read_bytes())
                if absent:
                    del saved['inputs']['versions']['python']
                else:
                    saved['inputs']['versions']['python']['language_version'][0] = -1
                path.write_bytes(api.encoded(saved))
                before = {p: (p.read_bytes(), p.stat().st_mtime_ns)
                          for p in self.output.rglob('*') if p.is_file()}
                with self.assertRaisesRegex(api.ReferenceError, 'stale'):
                    self.build(check=True)
                self.assertEqual(before, {p: (p.read_bytes(), p.stat().st_mtime_ns)
                                          for p in self.output.rglob('*') if p.is_file()})
                self.assertEqual(self.build(), 'generated')
                self.assertEqual(original, self.hashes())
                self.assertEqual(self.build(check=True), 'current')

    def test_checker_diagnostic_is_fatal_even_if_errata_flag_is_cleared(self):
        self.build()
        old = self.hashes()
        self.source.write_text('=head1 NAME\n\nBroken E<missing>\n')
        with self.assertRaisesRegex(api.ReferenceError, 'Unknown E content'):
            self.build()
        self.assertEqual(old, self.hashes())

    def test_missing_and_modified_owned_output_require_explicit_repair(self):
        self.build()
        old = self.hashes()
        (self.output / 'FSM/Example.html').unlink()
        with self.assertRaisesRegex(api.ReferenceError, 'incomplete'):
            self.build(check=True)
        with self.assertRaisesRegex(api.ReferenceError, '--repair'):
            self.build()
        self.build(repair=True)
        self.assertEqual(old, self.hashes())
        (self.output / 'reference.css').write_text('damaged')
        with self.assertRaisesRegex(api.ReferenceError, '--repair'):
            self.build()
        self.build(repair=True)
        self.assertEqual(old, self.hashes())

    def test_extra_files_and_directories_are_never_removed(self):
        self.build()
        extra = self.output / 'my-notes.txt'
        extra.write_text('retain this')
        with self.assertRaisesRegex(api.ReferenceError, 'Unowned extra files'):
            self.build(repair=True)
        self.assertEqual(extra.read_text(), 'retain this')
        extra.unlink()
        (self.output / 'my-directory').mkdir()
        with self.assertRaisesRegex(api.ReferenceError, 'Unowned extra directory'):
            self.build(repair=True)

    def test_broken_fragment_and_unknown_module_fail_before_publish(self):
        self.source.write_text('=head1 NAME\n\nFSM::Example\n\nL<FSM::Other/MISSING>\n')
        with self.assertRaisesRegex(api.ReferenceError, 'Broken fragment'):
            self.build()
        self.assertFalse(self.output.exists())
        self.source.write_text('=head1 NAME\n\nFSM::Example\n\nL<FSM::Unknown>\n')
        with self.assertRaisesRegex(api.ReferenceError, 'unknown FSM module'):
            self.build()
        self.assertFalse(self.output.exists())

    def test_source_symlink_and_nested_git_boundary_are_refused(self):
        alias = self.source.parent / 'Alias.pm'
        alias.symlink_to('Example.pm')
        with self.assertRaisesRegex(api.ReferenceError, 'Symlink'):
            self.build()
        alias.unlink()
        (self.source.parent / 'nested/.git').mkdir(parents=True)
        with self.assertRaisesRegex(api.ReferenceError, 'Nested Git'):
            self.build()

    def test_unowned_output_and_symlink_parent_are_refused(self):
        self.output.mkdir()
        with self.assertRaisesRegex(api.ReferenceError, 'unowned'):
            self.build()
        self.output.rmdir()
        self.output.symlink_to(self.source.parent)
        with self.assertRaisesRegex(api.ReferenceError, 'Symlink'):
            self.build()

    def test_unsafe_manifest_cannot_authorize_deletion(self):
        self.build()
        path = self.output / api.MARKER
        manifest = json.loads(path.read_text())
        manifest['outputs']['../outside.txt'] = '0' * 64
        path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(api.ReferenceError, 'Unsafe output membership'):
            self.build(repair=True)

    def test_lock_contention_fails_without_parallel_mutation(self):
        with api.generation_lock(self.root):
            with self.assertRaisesRegex(api.ReferenceError, 'Another POD'):
                self.build()

    def test_escaping_and_unsafe_links_are_refused(self):
        self.build()
        page = self.output / 'FSM/Example.html'
        for link in ('../../../../outside.html', 'javascript:alert(1)', '/absolute.html'):
            page.write_text(f'<a href="{link}">invalid</a>')
            with self.assertRaises(api.ReferenceError):
                api.validate_links(self.output, self.root / 'docs/book/src')


if __name__ == '__main__':
    unittest.main()
