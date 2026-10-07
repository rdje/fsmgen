"""Separate live source currency from immutable class/frame semantic custody."""

import copy
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts'))
import check_record_value_publication as current


class CurrentPublicationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.prior = current.historical()
        cls.declared = current.authority(cls.prior)
        cls.canonical = current.sources()
        cls.record = current.current_input(cls.prior, cls.canonical)

    def check(self, record, canonical=None):
        current.check(record, self.canonical if canonical is None else canonical, self.prior, self.declared)

    def refuse(self, mutate, cause):
        changed = copy.deepcopy(self.record)
        mutate(changed)
        self.assertFalse(current.same(changed, self.record), 'a real input change is required')
        with self.assertRaisesRegex(ValueError, '^' + cause + '$'):
            self.check(changed)

    def test_complete_actual_current_input(self):
        self.check(self.record)

    def test_target_meanings_and_routes_remain_exact(self):
        core, observer, tooling = self.prior['PATHS']
        for path, old, new in (
            (core, 'classes were unmeasured', 'classes were measured'),
            (observer, 'opaque retained evidence', 'formatter evidence'),
            (tooling, 'destination-locality replay and factory native copied-byte checks remain required;',
             'destination-locality replay and factory native copied-byte checks are optional;'),
            (observer, current.COMMAND, self.prior['model']['COMMAND']),
            (core, '  - "what qualifies finite original exception classes?"\n', '')):
            with self.subTest(path=path, old=old):
                self.refuse(lambda r: r['cards'].update({path: r['cards'][path].replace(old, new, 1)}),
                            'complete current target meanings questions metadata and replay routes')

    def test_complete_global_sources_queries_and_kinds(self):
        target_ids = {Path(p).stem for p in self.prior['PATHS']}
        non_target = next(line for line in self.record['queries']['direct']['stdout'].splitlines()
                         if not target_ids.intersection(line.split('\t')[1].split(',')))
        for role in ('direct', 'cached'):
            with self.subTest(role=role):
                self.refuse(lambda r: r['queries'][role].update(stdout=r['queries'][role]['stdout'].replace(non_target + '\n', '', 1)),
                            'complete source-derived current global query allocation')
                self.refuse(lambda r: r['queries'][role].update(stdout=r['queries'][role]['stdout'].replace(
                    '\tmdbook-build-destination-locality\t', '\tborrowed-tooling\t')),
                    'complete current target question ownership')
                for status in (True, 0.0, 1):
                    self.refuse(lambda r: r['queries'][role].update(status=status), 'actual current query integer success')
        self.refuse(lambda r: r['queries']['direct'].update(command=r['queries']['cached']['command']),
                    'distinct actual current query command and streams')
        self.refuse(lambda r: r['source_members'].pop(next(iter(r['source_members']))),
                    'complete independently enumerated current source members')
        self.refuse(lambda r: next(iter(r['source_members'].values())).update(bytes=True), 'current source member identity kinds')
        self.refuse(lambda r: next(iter(r['source_members'].values())).update(sha256='borrowed'),
                    'complete independently enumerated current source members')
        self.refuse(lambda r: r['census'].update(files=True), 'physical capacity kind/allowance: files')
        self.refuse(lambda r: r['census'].update(files=r['census']['files'] - 1), 'complete current physical census')
        self.refuse(lambda r: r['census'].pop('bytes_total'), 'complete physical capacity dimensions')
        self.refuse(lambda r: r['surface']['transition']['max_growth'].update(files=999), 'whole unchanged physical card authority')
        self.refuse(lambda r: r['source_budget']['targets'].clear(), 'unchanged current canonical source budget')
        self.refuse(lambda r: r.update(chapter=r['chapter'].replace(current.COMMAND, self.prior['book']['DEFAULT'])),
                    'unique complete current and retained publication guidance')

    def test_borrowed_snapshot_cannot_claim_current_currency(self):
        saved = self.prior['load'](current.HISTORICAL / 'publication.json')['snapshot']
        self.prior['check_current'](saved)
        self.refuse(lambda r: r.update(queries=copy.deepcopy(saved['queries'])),
                    'complete current target question ownership')

    def test_unrelated_progress_is_checked_against_current_sources(self):
        path = 'docs/knowledge/decision-record-exact-retrieval.md'
        canonical = dict(self.canonical)
        canonical[path] += b'\nFixture.\n'
        record = copy.deepcopy(self.record)
        record['source_members'][path] = current.identity(canonical[path])
        physical = {p: raw for p, raw in canonical.items() if Path(p).parent == Path('docs/knowledge')}
        record['census'] = self.prior['public']['metrics'](physical)
        self.check(record, canonical)
        # Add a new unrelated question with an independently spelled expected row.
        question = 'zz controlled question?'
        canonical[path] = canonical[path].replace(b'answers:\n', b'answers:\n  - "' + question.encode() + b'"\n', 1)
        record['source_members'][path] = current.identity(canonical[path])
        record['census'] = self.prior['public']['metrics']({p: raw for p, raw in canonical.items()
                                                        if Path(p).parent == Path('docs/knowledge')})
        extra = question + '\tdecision-record-exact-retrieval\t' + path
        for role in record['queries']:
            record['queries'][role]['stdout'] = '\n'.join(sorted([*record['queries'][role]['stdout'].splitlines(), extra])) + '\n'
        self.check(record, canonical)
        record['queries']['direct']['stdout'] = self.record['queries']['direct']['stdout']
        with self.assertRaisesRegex(ValueError, '^complete source-derived current global query allocation$'):
            self.check(record, canonical)

    def test_native_scope_and_role_controls(self):
        # This small HTML fixture isolates the parser; the actual whole native
        # build and every copied source are verified separately by the CLI.
        def html(guide):
            blocks = guide.split('```bash\n')
            text = blocks[0]
            for block in blocks[1:]:
                code, rest = block.split('```\n', 1)
                text += '<code>' + code + '</code>' + rest
            return self.prior['book']['EPOCH'] + text
        valid = html(current.guide(self.prior))
        current.check_native(valid, self.prior)
        for old, new, cause in (
            (current.COMMAND, self.prior['book']['DEFAULT'], 'native distinct current build and historical commands'),
            ('It cannot establish current currency', 'It establishes current currency', 'native complete current retained scope and gaps'),
            ('unmeasured or separately owned', 'fully measured and qualified', 'native complete current retained scope and gaps')):
            with self.subTest(old=old):
                changed = valid.replace(old, new)
                self.assertNotEqual(valid, changed)
                with self.assertRaisesRegex(ValueError, '^' + cause + '$'):
                    current.check_native(changed, self.prior)

    def test_source_enumerator_refuses_nonlocal_and_oversized_inputs(self):
        workspace = Path('.artifacts/record-value-current-tests')
        workspace.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=workspace) as name:
            root = Path(name).resolve()
            (root / 'docs/knowledge').mkdir(parents=True)
            (root / 'docs/decisions').mkdir()
            regular = root / 'docs/knowledge/valid.md'
            regular.write_text('valid source\n')
            with mock.patch.object(current, 'ROOT', root), mock.patch.object(current.plane, 'ROOT', root):
                self.assertEqual(current.sources(), {'docs/knowledge/valid.md': b'valid source\n'})
                regular.write_bytes(b'x' * (current.plane.SOURCE_BYTES + 1))
                with self.assertRaisesRegex(ValueError, '^bounded same-volume input before read$'):
                    current.sources()
                regular.write_text('valid source\n')
                alias = regular.with_name('alias.md'); alias.symlink_to('valid.md')
                with self.assertRaisesRegex(ValueError, '^local regular bounded input$'):
                    current.sources()
                alias.unlink()
                foreign = root / 'docs/knowledge/foreign'; foreign.mkdir(); (foreign / '.git').mkdir()
                with self.assertRaisesRegex(ValueError, '^no foreign repository endpoint$'):
                    current.sources()


if __name__ == '__main__':
    unittest.main()
