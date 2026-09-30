"""Independent retained bindings and Markdown destination controls."""

import copy
import json
import sys
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import audit_decision_store_consumer_closure as audit


class ConsumerClosure(unittest.TestCase):
    def test_fixed_production_report_is_reproducible(self):
        path = ROOT / 'docs/audits/decision-consumer-closure-20260930.json'
        report = json.loads(path.read_bytes())
        self.assertEqual(report['revision'], 'df7f692c8b94b083d2d078d62854d37869fbca6d')
        self.assertEqual(report['source_revision'], '585070c07bbcfa1af1497ff9701924a0f9b81e01')
        self.assertEqual(report, audit.audit(report['revision']))

    def test_literal_binding_loss_and_equal_count_substitution_refuse(self):
        old_path = 'docs/decisions/0051-contract.md'
        new_path = 'docs/decisions/current/language-api/0051-contract.md'
        old = ({('first?', 'contract', old_path), ('second?', 'contract', old_path)},
               {'contract': old_path}, ['one.md'])
        new = ({('first?', 'contract', new_path), ('second?', 'contract', new_path)},
               {'contract': new_path}, ['one.md'])
        route = {old_path: new_path}
        self.assertEqual(audit.verify_bindings(old, new, route)['answer_bindings'], 2)
        for bad in [
            ({('first?', 'contract', new_path)}, new[1], new[2]),
            ({('first?', 'contract', new_path), ('replacement?', 'contract', new_path)}, new[1], new[2]),
            ({('first?', 'other', new_path), ('second?', 'other', new_path)}, {'other': new_path}, new[2]),
            ({('first?', 'contract', old_path), ('second?', 'contract', old_path)}, {'contract': old_path}, new[2]),
            (new[0], {'contract': new_path, 'orphan': new_path}, new[2]),
        ]:
            with self.subTest(bad=bad), self.assertRaisesRegex(ValueError, 'bindings differ'):
                audit.verify_bindings(old, bad, route)

    def literal_navigation(self):
        old_path = 'docs/decisions/0051-contract.md'
        new_path = 'docs/decisions/current/language-api/0051-contract.md'
        original = '# 0051 — Contract\n\n## Details\n\n[Rule](../../README.md#rule)\n\n```md\n## Fake\n```\n'
        source = {'records': [{'id': '0051', 'path': old_path}]}
        originals = {'records': [{'id': '0051', 'text': original}]}
        catalog = {'records': [{'id': '0051', 'path': new_path}]}
        files = {
            old_path: b'# 0051 \xe2\x80\x94 Contract\n\n[Read the complete record](current/language-api/0051-contract.md).\n\n## Details\n\n[Read the complete record](current/language-api/0051-contract.md).\n',
            new_path: original.replace('../../README.md', '../../../../README.md').encode(),
        }
        return source, originals, catalog, files

    def test_literal_heading_routes_and_resolved_inline_destinations(self):
        source, originals, catalog, files = self.literal_navigation()
        result = audit.verify_navigation(source, originals, catalog, files.__getitem__)
        self.assertEqual(result[0]['heading_count'], 2)
        self.assertEqual(result[0]['retained_inline_destinations'], ['README.md#rule'])
        old_path, new_path = source['records'][0]['path'], catalog['records'][0]['path']
        controls = [
            (old_path, files[old_path].replace(b'## Details', b'## Replacement'), 'heading sequence'),
            (old_path, files[old_path].replace(b'current/language-api/', b'current/verification/'), 'heading misroutes'),
            (old_path, files[old_path].replace(b'[Read the complete record]', b'[Other]'), 'heading misroutes'),
            (new_path, files[new_path].replace(b'## Details', b'## Replacement'), 'lost original heading'),
            (new_path, files[new_path].replace(b'README.md#rule', b'README.md#wrong'), 'inline destination'),
            (new_path, files[new_path].replace(b'../../../../README.md', b'../../README.md'), 'inline destination'),
        ]
        for path, data, reason in controls:
            bad = copy.deepcopy(files)
            bad[path] = data
            with self.subTest(reason=reason), self.assertRaisesRegex(ValueError, reason):
                audit.verify_navigation(source, originals, catalog, bad.__getitem__)

    def test_fence_and_repository_escape_refuse(self):
        self.assertEqual(list(audit.visible('```md\n## Hidden\n````\n## Visible\n')), ['## Visible'])
        with self.assertRaisesRegex(ValueError, 'unterminated'):
            list(audit.visible('~~~\n## Hidden\n'))
        with self.assertRaisesRegex(ValueError, 'escapes repository'):
            audit.destination('docs/decisions/0051-contract.md', '../../../outside.md')

    def test_unreviewed_code_candidate_refuses(self):
        self.assertEqual(audit.interface_review(['scripts/decision_records.py']),
                         {'scripts/decision_records.py': 'authenticated_store_interfaces'})
        for path in ('scripts/unreviewed_reader.py', 'knowledge-map/unreviewed_reader.py',
                     't/python/test_decision_unreviewed.py'):
            with self.subTest(path=path), self.assertRaisesRegex(ValueError, 'needs explicit interface review'):
                audit.interface_review([path])


if __name__ == '__main__':
    unittest.main()
