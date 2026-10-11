"""Separate live source currency from immutable class/frame semantic custody."""

import copy
import json
import re
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

    def test_historical_admission_success_stream_remains_compatible(self):
        saved = json.loads(Path(
            'docs/audits/record-value-coordinate-admission-20261007/actual-current.json'
        ).read_bytes())
        self.assertEqual(type(saved['status']), int)
        self.assertEqual(saved['status'], 0)
        self.assertEqual(current.SUCCESS, saved['stdout'])

    def test_target_meanings_and_routes_remain_exact(self):
        core, observer, tooling = self.prior['PATHS']
        for path, old, new in (
            (core, 'classes were unmeasured', 'classes were measured'),
            (observer, 'operands remain opaque evidence', 'operands supply formatter evidence'),
            (tooling, 'replay/factory native copied-byte checks required;',
             'replay/factory native copied-byte checks are optional;'),
            (tooling, current.epoch_fact.QUESTION, 'borrowed historical epoch question?'),
            (tooling, 'same-volume committed-epoch', 'measured original private'),
            (tooling, 'Compiler/HDL unchanged', 'Compiler/HDL change'),
            (tooling, current.expression_fact.QUESTION, 'borrowed expression attribution question?'),
            (tooling, 'live guard predicate endings', 'all guard statement starts'),
            (tooling, current.public_reference_fact.QUESTION, 'borrowed public recipe question?'),
            (tooling, '../' + current.public_reference_fact.READER.removeprefix('docs/'), '../audits/borrowed-reader.py'),
            (tooling, 'alone leaves original coordinates/identities unmeasured', 'alone qualifies original coordinates/identities'),
            (core, current.coordinate_fact.QUESTION, 'borrowed coordinate question?'),
            (core, current.address_fact.QUESTION, 'borrowed address question?'),
            (core, 'cross-call/capture reuse stay opaque', 'cross-call/capture reuse proves native identity'),
            (core, 'address lifetimes remain unmeasured', 'address lifetimes are qualified'),
            (current.coordinate_fact.PARSER, 'receiver, normalized AST', 'qualified receiver identity and AST'),
            (current.coordinate_fact.PARSER, current.COMMAND, self.prior['model']['COMMAND']),
            (observer, current.COMMAND, self.prior['model']['COMMAND']),
            (observer, current.observer_fact.QUESTION, 'borrowed observer question?'),
            (observer, 'Qualified current literal/quote/escape/truncation/count grammar',
             'Measured original literal/quote/escape/truncation/count grammar'),
            (observer, 'original bytes without native identity', 'original bytes with qualified native identity'),
            (observer, 'Model/population/member/order/phase/role/kind/family/operand',
             'Selected prefix-only controls'),
            (core, '  - "what qualifies finite original exception classes?"\n', '')):
            with self.subTest(path=path, old=old):
                def mutate(record):
                    text, count = re.subn(r'\s+'.join(re.escape(p) for p in old.split()),
                                         lambda match: new, record['cards'][path], count=1,
                                         flags=re.I if old.startswith('receiver,') else 0)
                    self.assertEqual(count, 1, 'the intended original meaning must be present')
                    record['cards'][path] = text
                self.refuse(mutate,
                            'complete current target meanings questions metadata and replay routes')

    def test_complete_global_sources_queries_and_kinds(self):
        target_ids = {Path(p).stem for p in self.record['cards']}
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
        self.refuse(lambda r: r.update(chapter=r['chapter'].replace(current.coordinate_fact.PARSER_GUIDE, '')),
                    'complete current coordinate parser and tooling guidance')
        self.refuse(lambda r: r.update(tooling_chapter=r['tooling_chapter'].replace(current.address_fact.REFERENCE, '')),
                    'complete current finite address tooling guidance')
        self.refuse(lambda r: r['queries']['direct'].update(stdout='malformed\n'),
                    'complete current target question ownership')

    def test_borrowed_snapshot_cannot_claim_current_currency(self):
        saved = self.prior['load'](current.HISTORICAL / 'publication.json')['snapshot']
        self.prior['check_current'](saved)
        self.refuse(lambda r: r.update(queries=copy.deepcopy(saved['queries'])),
                    'complete current target question ownership')

    def test_public_reference_requires_complete_actual_success(self):
        expected = current.public_reference_fact.SUCCESS
        for status, stdout, stderr in ((0, expected, ''), (True, expected, ''),
                (0.0, expected, ''), (1, expected, ''), (0, expected + 'extra\n', ''),
                (0, expected, 'warning\n'), (0, '', '')):
            with self.subTest(status=status, stdout=stdout, stderr=stderr):
                actual = mock.Mock(returncode=status, stdout=stdout, stderr=stderr)
                with mock.patch.object(current.subprocess, 'run', return_value=actual) as run:
                    if type(status) is int and status == 0 and stdout == expected and not stderr:
                        current.check_public_reference()
                    else:
                        with self.assertRaisesRegex(ValueError, '^complete actual dated public reference qualification$'):
                            current.check_public_reference()
                    run.assert_called_once_with(['python3', '-B', current.public_reference_fact.READER],
                                                capture_output=True, text=True, cwd=current.ROOT)

    def test_unrelated_progress_is_checked_against_current_sources(self):
        canonical = dict(self.canonical)
        non_targets = [p for p in canonical if Path(p).parent == Path('docs/knowledge')
                       and p not in self.record['cards'] and self.prior['metadata']['metadata'](canonical[p])]
        path = max(non_targets, key=lambda p: len(canonical[p]))
        identifier = self.prior['metadata']['metadata'](canonical[path])[0]
        record = copy.deepcopy(self.record)
        # Exercise the valid initial source epoch at the exact byte allowance.
        # Padding is a scoped unit fixture, never a published card edit.
        limit = min(record['surface']['baseline']['bytes_total'] +
                    record['surface']['transition']['max_growth']['bytes_total'],
                    record['surface']['enforcement_ceilings']['bytes_total'])
        padding = limit - record['census']['bytes_total']
        self.assertGreaterEqual(padding, 0)
        dimensions = {key: min(record['surface']['baseline'][key] +
                               record['surface']['transition']['max_growth'][key],
                               record['surface']['enforcement_ceilings'][key])
                      for key in ('bytes_each', 'lines_each', 'line_bytes_each')}
        for member in non_targets:
            raw = canonical[member]
            while padding and len(raw) < dimensions['bytes_each'] and raw.count(b'\n') < dimensions['lines_each']:
                amount = min(padding, dimensions['bytes_each'] - len(raw), dimensions['line_bytes_each'] + 1)
                suffix = b' ' * (amount - 1) + b'\n' if raw.endswith(b'\n') else b'\n'
                raw += suffix; padding -= len(suffix)
            canonical[member] = raw
            if not padding:
                break
        self.assertEqual(padding, 0, 'fixture must reach capacity without exceeding another dimension')
        record['source_members'] = {p: current.identity(raw) for p, raw in canonical.items()}
        physical = {p: raw for p, raw in canonical.items() if Path(p).parent == Path('docs/knowledge')}
        record['census'] = self.prior['public']['metrics'](physical)
        self.assertEqual(record['census']['bytes_total'], limit)
        self.check(record, canonical)
        # The former append-only positive fixture is genuinely inadmissible.
        appended = dict(canonical); appended[path] += b'\nFixture.\n'
        invalid = copy.deepcopy(record)
        invalid['source_members'][path] = current.identity(appended[path])
        invalid['census'] = self.prior['public']['metrics']({p: raw for p, raw in appended.items()
                                                          if Path(p).parent == Path('docs/knowledge')})
        with self.assertRaisesRegex(ValueError, '^physical capacity kind/allowance: bytes_total$'):
            self.check(invalid, appended)
        # This synthetic non-target body reserves its own question space. The
        # current reader verifies source currency; content belongs to its owner.
        # The real admitted prose-equivalence update is separately native-tested.
        header, body = canonical[path].rsplit(b'---\n', 1)
        canonical[path] = header + b'---\n\nControlled non-target source fixture.\n'
        self.assertGreater(len(body), 128)
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
        extra = question + '\t' + identifier + '\t' + path
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
            blocks = (guide + current.coordinate_fact.PARSER_GUIDE).split('```bash\n')
            text = blocks[0]
            for block in blocks[1:]:
                code, rest = block.split('```\n', 1)
                text += '<code>' + code + '</code>' + rest
            return self.prior['book']['EPOCH'] + text.replace('`', '')
        valid = html(current.guide(self.prior))
        valid = valid.replace('$operation.', '<code>$operation</code>.')
        current.check_native(valid, self.prior)
        for old, new, cause in (
            (current.COMMAND, self.prior['book']['DEFAULT'], 'native distinct current build and historical commands'),
            ('It cannot establish current currency', 'It establishes current currency', 'native complete current retained scope and gaps'),
            ('unmeasured or separately owned', 'fully measured and qualified', 'native complete current retained scope and gaps'),
            ('Only the unchanged finite observer parent', 'All native and private parents', 'native complete current retained scope and gaps'),
            ('Authentication does not freshly reconstruct original executions.',
             'Authentication freshly reconstructs original executions.', 'native complete current retained scope and gaps')):
            with self.subTest(old=old):
                changed = valid.replace(old, new)
                self.assertNotEqual(valid, changed)
                with self.assertRaisesRegex(ValueError, '^' + cause + '$'):
                    current.check_native(changed, self.prior)

    def test_observer_authentication_requires_whole_same_volume_members(self):
        workspace = Path('.artifacts/observer-publication-tests')
        workspace.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=workspace) as name:
            root = Path(name).resolve()
            member = root / 'member.json'
            member.write_bytes(b'{"first":"unchanged","tail":"original"}\n')
            expected = current.observer_fact.identity(member.read_bytes())
            with mock.patch.object(current.plane, 'ROOT', root):
                self.assertEqual(current.observer_fact.fingerprint('member.json', expected), expected)
                changed = member.read_bytes().replace(b'original', b'borrowed')
                self.assertEqual(len(changed), expected['bytes'])
                member.write_bytes(changed)
                with self.assertRaisesRegex(ValueError, '^whole admitted observer bytes conserved$'):
                    current.observer_fact.fingerprint('member.json', expected)
                boolean = dict(expected, bytes=True)
                with self.assertRaisesRegex(ValueError, '^closed admitted observer identity$'):
                    current.observer_fact.fingerprint('member.json', boolean)
                link = root / 'borrowed.json'
                link.symlink_to('member.json')
                with self.assertRaisesRegex(ValueError, '^ordinary admitted observer input$'):
                    current.observer_fact.fingerprint('borrowed.json', expected)
                foreign = root / 'foreign'
                foreign.mkdir()
                (foreign / '.git').mkdir()
                (foreign / 'member.json').write_bytes(changed)
                with self.assertRaisesRegex(ValueError, '^no foreign repository endpoint$'):
                    current.observer_fact.fingerprint('foreign/member.json', expected)

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

    def test_original_coordinate_actual_result_requires_complete_typed_success(self):
        fact = current.coordinate_fact
        actual = json.loads(fact.local(fact.CHECKS, current.plane.SOURCE_BYTES))['published-independent']
        seal = json.loads(fact.local(fact.PRODUCT + '/seal.json', current.plane.SOURCE_BYTES))
        qualified = json.loads(fact.local(fact.PRODUCT + '/qualification.json', seal['qualification.json']['bytes']))
        fact.check_actual(actual, qualified)
        for mutate, cause in (
                (lambda r: r.update(status=True), 'actual independent coordinate integer success'),
                (lambda r: r.update(status=0.0), 'actual independent coordinate integer success'),
                (lambda r: r['command'].append('--foreign'), 'complete actual independent coordinate command'),
                (lambda r: r.update(stdout='{}'), 'complete independent coordinate result scope'),
                (lambda r: r.update(stdout=r['stdout'].replace('"points": 2943', '"points": true', 1)),
                 'complete typed independent coordinate coverage')):
            changed = copy.deepcopy(actual)
            mutate(changed)
            self.assertFalse(current.same(changed, actual))
            with self.assertRaisesRegex(ValueError, '^' + cause + '$'):
                fact.check_actual(changed, qualified)

    def test_address_admission_authenticates_complete_committed_evidence(self):
        fact = current.address_fact
        admitted = fact.authenticate()
        self.assertEqual(admitted['proposal'], fact.ADMITTED_MEMBERS[fact.PROPOSAL])
        self.assertEqual(admitted['definitive_proof'], fact.ADMITTED_MEMBERS[fact.PROOF])
        self.assertEqual(set(admitted['complete_members']), set(fact.ADMITTED_MEMBERS))
        self.assertIn('no fresh semantic recapture or native identity', admitted['scope'])

    def test_address_actual_roles_require_complete_typed_results(self):
        fact = current.address_fact
        checks = json.loads(Path(fact.PREPARATION, 'checks.json').read_bytes())
        for role in fact.ACTUAL_CONTRACTS:
            fact.check_actual(checks[role], role)
            for mutate, cause in (
                (lambda r: r.update(status=True), 'actual admitted address integer success'),
                (lambda r: r.update(status=0.0), 'actual admitted address integer success'),
                (lambda r: r.update(status=1), 'actual admitted address integer success'),
                (lambda r: r['command'].append('--borrowed'), 'complete admitted address actual command'),
                (lambda r: r.update(stdout='PASS\n'), 'complete admitted address actual stdout'),
                (lambda r: r.update(stderr=r['stderr'].replace('cutoff 88%', 'cutoff 99%')),
                 'complete admitted address guard stream'),
                (lambda r: r['instruments'].pop('scripts/run_with_ram_guard.sh'),
                 'complete admitted address actual instruments'),
                (lambda r: r.update(native_identity=True), 'closed complete admitted address actual result')):
                with self.subTest(role=role, cause=cause):
                    changed = copy.deepcopy(checks[role]); mutate(changed)
                    self.assertFalse(current.same(changed, checks[role]))
                    with self.assertRaisesRegex(ValueError, '^' + cause + '$'):
                        fact.check_actual(changed, role)

    def test_address_first_proof_cannot_replace_definitive_qualification(self):
        fact = current.address_fact
        original = current.plane.local_read
        borrowed = Path(fact.PREPARATION, 'proof.json').read_bytes()
        self.assertNotEqual(fact.pin(borrowed), fact.ADMITTED_MEMBERS[fact.PROOF])
        def read(path, maximum):
            return borrowed if path == current.ROOT / fact.PROOF else original(path, maximum)
        with mock.patch.object(current.plane, 'local_read', side_effect=read):
            with self.assertRaisesRegex(ValueError, '^complete admitted address member: ' + re.escape(fact.PROOF) + '$'):
                fact.authenticate()

    def test_address_proposed_native_field_cannot_define_its_own_schema(self):
        fact = current.address_fact
        original = current.plane.local_read
        changed = fact.proposal()
        changed['original_native_identity'] = 'unsubstantiated first-admission claim'
        raw = json.dumps(changed, sort_keys=True, indent=2).encode() + b'\n'
        self.assertNotEqual(fact.pin(raw), fact.ADMITTED_MEMBERS[fact.PROPOSAL])
        def read(path, maximum):
            return raw if path == current.ROOT / fact.PROPOSAL else original(path, maximum)
        with mock.patch.object(current.plane, 'local_read', side_effect=read):
            with self.assertRaisesRegex(ValueError, '^complete admitted address member: ' + re.escape(fact.PROPOSAL) + '$'):
                fact.proposal()

    def test_address_complete_dated_input_is_individually_authenticated(self):
        fact = current.address_fact
        original = current.plane.local_read
        member = 'docs/audits/address-source-integration-20261010/verify.py'
        raw = Path(member).read_bytes() + b'\n# changed complete dated reader\n'
        def read(path, maximum):
            return raw if path == current.ROOT / member else original(path, maximum)
        with mock.patch.object(current.plane, 'local_read', side_effect=read):
            with self.assertRaisesRegex(ValueError, '^complete admitted address member: ' + re.escape(member) + '$'):
                fact.authenticate()

    def test_native_tooling_preserves_address_limits_and_checkpoint_roles(self):
        blocks = current.coordinate_fact.REFERENCE + current.address_fact.REFERENCE
        html = blocks.replace('```sh\n', '').replace('```\n', '').replace('`', '')
        html = html.replace('final-proof.json.', '<code>final-proof.json</code>.')
        current.check_tooling_native(html, self.prior)
        for old, new in (
            ('Certificate authentication supplies no fresh semantic recapture.', 'Original executions recaptured.'),
            ('cross-call/capture\nreuse retain their explicit limits.', 'cross-call/capture reuse proves native identity.'),
            ('Full raw-stack joining is next;', 'All raw-stack acceptance is complete;')):
            with self.subTest(old=old):
                changed = html.replace(old, new)
                self.assertNotEqual(changed, html)
                with self.assertRaisesRegex(ValueError, '^native complete current tooling scope and gaps$'):
                    current.check_tooling_native(changed, self.prior)


if __name__ == '__main__':
    unittest.main()
