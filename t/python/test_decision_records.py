"""Exact retention, corruption rejection and navigation for sealed decisions."""

import importlib.util
import json
import posixpath
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('decision_records', ROOT / 'scripts/decision_records.py')
decisions = importlib.util.module_from_spec(spec)
spec.loader.exec_module(decisions)


class DecisionRecords(unittest.TestCase):
    def setUp(self):
        parent = ROOT / '.artifacts' / 'decision-record-tests'
        parent.mkdir(parents=True, exist_ok=True)
        self.workspace = tempfile.TemporaryDirectory(dir=parent)
        self.addCleanup(self.workspace.cleanup)
        self.root = Path(self.workspace.name)
        census = json.loads((ROOT / decisions.CENSUS).read_bytes())
        self.census = census
        paths = {decisions.CENSUS, decisions.ARCHIVE, decisions.VIEW, decisions.INDEX}
        paths.update(row['path'] for row in census['records'][:50])
        paths.update(row['path'] for row in census['body_or_identity_consumers']
                     if row['text'].startswith('reverify:'))
        paths.update(posixpath.normpath(posixpath.join('docs/decisions', row['target']))
                     for row in census['selected_links'])
        for relative in paths:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, target)

    def archive(self):
        return json.loads((self.root / decisions.ARCHIVE).read_bytes())

    def save(self, archive):
        (self.root / decisions.ARCHIVE).write_text(json.dumps(archive))

    def run_reader(self, *ids):
        return subprocess.run([sys.executable, str(ROOT / 'scripts/decision_records.py'),
                               '--root', str(self.root), 'read', *ids], capture_output=True)

    def test_complete_retention_and_exact_public_read(self):
        records = decisions.verify(self.root)
        for record in records:
            with self.subTest(record=record['id']):
                expected = subprocess.check_output(
                    ['git', 'show', self.census['source_revision'] + ':' + record['path']], cwd=ROOT)
                result = self.run_reader(record['id'])
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, expected)
        result = self.run_reader('0050', '0001')
        self.assertEqual(result.stdout, (records[-1]['text'] + records[0]['text']).encode())

    def test_changed_original_is_rejected_even_with_same_size(self):
        archive = self.archive()
        archive['records'][0]['text'] = archive['records'][0]['text'].replace('ISF', 'BAD', 1)
        self.save(archive)
        with self.assertRaisesRegex(ValueError, 'original text changed'):
            decisions.verify(self.root)

    def test_missing_duplicate_reordered_and_added_records(self):
        original = self.archive()
        variants = [original['records'][1:],
                    [original['records'][0]] * 50,
                    list(reversed(original['records'])),
                    original['records'] + [original['records'][0]]]
        for records in variants:
            with self.subTest(ids=[row['id'] for row in records][:3]):
                self.save({**original, 'records': records})
                with self.assertRaises(ValueError):
                    decisions.verify(self.root)

    def test_stale_view_and_changed_forwarder(self):
        for relative, diagnostic in [(decisions.VIEW, 'view is stale'),
                                     (self.census['records'][0]['path'], 'forwarding page changed')]:
            with self.subTest(path=relative):
                path = self.root / relative
                original = path.read_bytes()
                path.write_bytes(original + b'changed\n')
                with self.assertRaisesRegex(ValueError, diagnostic):
                    decisions.verify(self.root)
                path.write_bytes(original)

    def test_missing_index_route_and_link_destination(self):
        path = self.root / decisions.INDEX
        original = path.read_text()
        path.write_text(original.replace('](' + Path(self.census['records'][0]['path']).name + ')', '](missing.md)'))
        with self.assertRaisesRegex(ValueError, 'index omits'):
            decisions.verify(self.root)
        path.write_text(original)
        (self.root / 'README_POLICY.md').unlink()
        with self.assertRaises(FileNotFoundError):
            decisions.verify(self.root)

    def test_old_reverify_command_is_rejected(self):
        row = next(row for row in self.census['body_or_identity_consumers']
                   if row['text'].startswith('reverify:'))
        path = self.root / row['path']
        lines = path.read_text().splitlines()
        path.write_text('\n'.join(row['text'] if line.startswith('reverify:') else line
                                  for line in lines) + '\n')
        with self.assertRaisesRegex(ValueError, 'reverify omits exact record reader'):
            decisions.verify(self.root)

    def test_census_identity_and_duplicate_keys_fail_closed(self):
        path = self.root / decisions.CENSUS
        original = path.read_bytes()
        path.write_bytes(original + b' ')
        with self.assertRaisesRegex(ValueError, 'source census changed'):
            decisions.verify(self.root)
        path.write_bytes(original)
        archive = self.root / decisions.ARCHIVE
        archive.write_bytes(archive.read_bytes().replace(b'{', b'{"schema_version":1,', 1))
        with self.assertRaisesRegex(ValueError, 'duplicate JSON key'):
            decisions.verify(self.root)

    def test_noninteger_schema_version_is_not_integer_one(self):
        archive = self.archive()
        for version in (True, 1.0, '1', None, False, {}, []):
            with self.subTest(version=version):
                archive['schema_version'] = version
                self.save(archive)
                result = self.run_reader('0001')
                self.assertEqual(result.returncode, 1)
                self.assertEqual(result.stdout, b'')
                self.assertIn(b'unsupported archive schema', result.stderr)

    def test_unknown_id_is_atomic_and_symlink_and_oversize_are_rejected(self):
        result = self.run_reader('0001', '9999')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, b'')
        archive = self.root / decisions.ARCHIVE
        original = archive.read_bytes()
        archive.unlink()
        archive.symlink_to(ROOT / decisions.ARCHIVE)
        with self.assertRaisesRegex(ValueError, 'symlink'):
            decisions.verify(self.root)
        archive.unlink()
        archive.write_bytes(b' ' * (decisions.MAX_BYTES + 1))
        with self.assertRaisesRegex(ValueError, 'reader bound'):
            decisions.verify(self.root)
        archive.write_bytes(original)
        self.assertEqual(len(decisions.verify(self.root)), 50)

    def test_catalog_cannot_substitute_already_published_sealed_originals(self):
        archive = self.archive()
        prepared = {'originals': {row['id']: row['text'] for row in archive['records']}}
        self.assertEqual(len(decisions.verify(self.root, prepared)), 50)
        prepared['originals']['0001'] = prepared['originals']['0001'].replace('ISF', 'BAD', 1)
        with self.assertRaisesRegex(ValueError, 'substitutes published sealed original'):
            decisions.verify(self.root, prepared)

    def test_selected_legacy_reader_capsule_needs_no_store_helper_files(self):
        script = self.root / 'capsule/scripts/decision_records.py'
        script.parent.mkdir(parents=True)
        script.write_bytes((ROOT / 'scripts/decision_records.py').read_bytes())
        result = subprocess.run([sys.executable, '-B', str(script), '--root', str(self.root),
                                 'read', '0001'], capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, self.archive()['records'][0]['text'].encode())


if __name__ == '__main__':
    unittest.main()
