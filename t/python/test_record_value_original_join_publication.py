"""Reject borrowed, incomplete or promoted original-join publication authority."""
import copy
import gzip
import json
import re
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts'))
import record_value_original_join_fact as fact


class OriginalJoinPublicationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.candidate = fact.admission()

    def test_complete_review_preserves_questions_probes_and_capacity(self):
        candidate = self.candidate
        after = fact.published(candidate)
        self.assertEqual(len(after.encode()), len(candidate['before'].encode()))
        self.assertEqual(after.split('---\n', 2)[1], candidate['before'].split('---\n', 2)[1].replace(
            'date: 2026-10-11\n', 'date: 2026-10-12\n', 1))
        for line in candidate['before'].splitlines():
            if re.search(r'[0-9]', line) and not line.startswith('date: '):
                self.assertEqual(after.splitlines().count(line), candidate['before'].splitlines().count(line))
        self.assertIn('join all original context/cause/coordinate/typed\nconsumer operands/truth, never passed flags', after)
        self.assertIn('native/private/formatter/encoding/hidden-identity/address/external-framework coordinates stay unmeasured', after)
        self.assertEqual(fact.cards({fact.CARD: candidate['before']})[fact.CARD], after)
        with self.assertRaisesRegex(ValueError, '^whole predecessor original-join meanings and routes$'):
            fact.cards({fact.CARD: after})

    def test_changed_candidates_reach_their_own_refusal(self):
        cases = [
            (lambda r: r.update(unknown_native_authority=True), 'closed complete original-join candidate'),
            (lambda r: r.update(schema_version=True), 'exact admitted original-join source role'),
            (lambda r: r.update(schema_version=1.0), 'exact admitted original-join source role'),
            (lambda r: r.update(revision='later-live-code'), 'exact admitted original-join source role'),
            (lambda r: r.update(owner='borrowed-owner'), 'exact admitted original-join source role'),
            (lambda r: r.update(target='docs/knowledge/borrowed.md'), 'exact admitted original-join source role'),
            (lambda r: r.update(before=r['after']), 'whole original-join predecessor meanings and routes'),
            (lambda r: r['before_identity'].update(bytes=float(r['before_identity']['bytes'])),
             'whole original-join predecessor meanings and routes'),
            (lambda r: r.update(after=r['after'].replace('never passed flags', 'native passed flags supply truth')),
             'whole reviewed original-join meanings and correspondence'),
            (lambda r: r['after_identity'].update(bytes=True), 'whole reviewed original-join meanings and correspondence'),
            (lambda r: r['proposed'].update(bytes_total=r['previous']['bytes_total']+1), 'non-growing original-join capacity'),
            (lambda r: r['proposed'].update(files=float(r['proposed']['files'])), 'non-growing original-join capacity'),
            (lambda r: r['input_identities'].pop(next(iter(r['input_identities']))), 'every original-join source and parent contract'),
            (lambda r: r['contracts'].pop(next(iter(r['contracts']))), 'every original-join source and parent contract'),
            (lambda r: r['canonical_members'].pop(next(iter(r['canonical_members']))),
             'whole original-join authority source review and query custody'),
            (lambda r: r['queries']['direct'].update(status=False), 'whole original-join authority source review and query custody'),
            (lambda r: r['correspondence'][0].update(index=False), 'whole original-join authority source review and query custody'),
            (lambda r: r['review']['changes'].pop(), 'whole original-join authority source review and query custody'),
            (lambda r: r['authority']['transition']['max_growth'].update(files=999),
             'whole original-join authority source review and query custody'),
        ]
        for scope in self.candidate['scope']['assurance']:
            cases.append((lambda r, key=scope: r['scope']['assurance'].update({key: True}),
                          'whole original-join assumptions and native private boundaries'))
        for mutate, cause in cases:
            with self.subTest(cause=cause):
                changed = copy.deepcopy(self.candidate)
                mutate(changed)
                self.assertFalse(fact.same(changed, self.candidate))
                with self.assertRaisesRegex(ValueError, '^'+cause+'$'):
                    fact.published(changed)

    def test_first_admission_cannot_choose_its_own_schema_or_native_scope(self):
        for mutate in (lambda r: r.update(schema_version=True),
                       lambda r: r['scope']['assurance'].update(original_native_private=True)):
            changed = copy.deepcopy(self.candidate)
            mutate(changed)
            body = gzip.compress(fact.raw_fact.encoded(changed), mtime=0)
            with mock.patch.object(fact.finite, 'local', return_value=body):
                with self.assertRaisesRegex(ValueError, '^whole fixed original-join candidate before first admission$'):
                    fact.admission()

    def test_actual_success_and_first_failures_keep_distinct_typed_roles(self):
        for role in fact.ACTUALS:
            actual = json.loads((fact.PREPARATION/(role+'-actual.json')).read_bytes())
            fact.check_actual(actual, role)
            mutations = [
                (lambda r: r.update(status=False), 'exact typed original-join native outcome'),
                (lambda r: r.update(expected_status=False), 'exact typed original-join native outcome'),
                (lambda r: r['command'].append('--current'), 'exact original-join native command role'),
                (lambda r: r.update(stdout='PASS\n'), 'whole original-join native terminal'),
                (lambda r: r['programmes'].pop(next(iter(r['programmes']))),
                 'whole original-join native programme and source custody'),
            ]
            if actual['status']:
                mutations.append((lambda r: r.update(status=0), 'exact typed original-join native outcome'))
            for mutate, cause in mutations:
                with self.subTest(role=role, cause=cause):
                    changed=copy.deepcopy(actual);mutate(changed)
                    self.assertFalse(fact.same(changed,actual))
                    with self.assertRaisesRegex(ValueError,'^'+cause+'$'):
                        fact.check_actual(changed,role)

    def test_complete_preparation_and_dated_source_are_authenticated(self):
        admitted = fact.authenticate()
        self.assertEqual(admitted['candidate'], fact.CANDIDATE)
        self.assertEqual(set(admitted['actuals']), set(fact.ACTUALS))
        self.assertEqual(admitted['scope'], self.candidate['scope'])
        self.assertTrue(all(value is False for value in admitted['scope']['assurance'].values()))


if __name__=='__main__':
    unittest.main()
