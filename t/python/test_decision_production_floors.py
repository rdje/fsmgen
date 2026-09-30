"""Current-consistent full production changes retain previously published keys."""

import copy
import json
import unittest
from pathlib import Path

import test_decision_production_growth as production
from test_decision_production_hostile import MODES, publish_birth

OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2.3'
CASES = {
    'identity deletion': b'deleted a prior decision identity',
    'equal-count identity replacement': b'deleted a prior decision identity',
    'path recycling': b'recycles a prior decision identity: 0115',
    'type recycling': b'recycles a prior decision identity: 0115',
    'fact deletion': b'loses prior fact identity: 0115',
    'equal-count fact replacement': b'loses prior fact identity: 0115',
    'question deletion': b'loses prior question keys: 0115',
    'equal-count question replacement': b'loses prior question keys: 0115',
}


def authored_body(knowledge_id='production-growth-fixture', questions=production.QUESTIONS,
                  status='proposed', extra=''):
    # Literal independent front matter and metadata, not the catalog producer.
    front = '' if knowledge_id is None else (
        '---\nid: ' + knowledge_id + '\ntitle: Fixture-only production-cohort decision\n'
        'answers: ' + json.dumps(questions) + '\ndate: 2026-09-30\nstatus: current\n'
        'tags: [qualification, fixture]\nevidence: t/2013-decision-production-floors.t\n'
        'reverify: python3 -B scripts/decision_records.py read-current 0115\n---\n')
    body = production.FRESH.split('\n---\n', 1)[1]
    text = front + body.replace('Status: proposed', 'Status: ' + status) + extra
    metadata = {'knowledge_id': knowledge_id,
        'knowledge_status': 'current' if knowledge_id is not None else None,
        'questions': list(questions) if knowledge_id is not None else [],
        'authority_status': ['Status: ' + status]}
    return text.encode(), metadata


class ProductionFloors(unittest.TestCase):
    def success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def refusal(self, result, diagnostic, public=True):
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        if public:
            self.assertEqual(result.stdout, b'')
        self.assertIn(diagnostic, result.stderr)

    def fixture(self):
        fixture = production.ProductionFixture()
        try:
            baseline = publish_birth(fixture, OWNER)
            self.success(fixture.public('check', selector='HEAD', installed=True))
            self.assertEqual(self.success(fixture.public('read-current', '0115', selector='HEAD')),
                             production.FRESH.encode())
            change = json.loads(self.success(fixture.public('check-continuity', selector='HEAD', prior='HEAD^')))
            self.assertEqual(change, {'catalog': True, 'fresh_ids': ['0115'], 'resolved': []})
            self.assertEqual(fixture.git('status', '--porcelain'), b'')
            return fixture, baseline
        except BaseException:
            fixture.close()
            raise

    def write_record(self, fixture, row, data, metadata):
        fixture.write(row['path'], data)
        row['content'] = production.descriptor(data)
        row['metadata'] = metadata

    def navigation(self, fixture):
        # Preserve every production row verbatim; independently author only
        # the fixture's current identity/path/type route and complete part row.
        fresh = [row for row in fixture.catalog['records'] if row['id'] >= '0115']
        root = fixture.original_products[production.INDEX].decode()
        parts = {part: fixture.original_products[f'docs/decisions/current/{part}/INDEX.md'].decode()
                 for part in ('continuity', 'language-api', 'verification')}
        for row in fresh:
            cells = 'Fixture-only production-cohort decision | ' + row['type'] + ' | Isolated fresh-growth proof. |\n'
            root += f'| [{row["id"]}](' + row['path'].removeprefix('docs/decisions/') + ') | ' + cells
            parts[Path(row['path']).parent.name] += f'| [{row["id"]}](' + Path(row['path']).name + ') | ' + cells
        fixture.catalog['records'].sort(key=lambda row: row['id'])
        fixture.write_catalog()
        fixture.write(production.INDEX, root)
        for part, text in parts.items():
            fixture.write(f'docs/decisions/current/{part}/INDEX.md', text)

    def mutate(self, fixture, case):
        row = fixture.catalog['records'][-1]
        old_path = row['path']
        if case == 'identity deletion':
            fixture.catalog['records'].remove(row)
            (fixture.root / old_path).unlink()
            expected = None
        else:
            data, metadata = authored_body()
            if case == 'equal-count identity replacement':
                row['id'] = '0116'
                row['path'] = old_path.replace('0115', '0116')
                data = data.replace(b'# 0115', b'# 0116').replace(b'read-current 0115', b'read-current 0116')
            elif case == 'path recycling':
                row['path'] = old_path.replace('/verification/', '/language-api/')
            elif case == 'type recycling':
                row['type'] = 'architecture / changed qualification'
                data = data.replace(b'Type: architecture / qualification', b'Type: architecture / changed qualification')
            elif case == 'fact deletion':
                data, metadata = authored_body(None)
            elif case == 'equal-count fact replacement':
                data, metadata = authored_body('different-fixture-fact')
            elif case == 'question deletion':
                data, metadata = authored_body(questions=production.QUESTIONS[:1])
            elif case == 'equal-count question replacement':
                data, metadata = authored_body(questions=[production.QUESTIONS[0], 'which unowned substituted key applies?'])
            elif case == 'owned additive evolution':
                data, metadata = authored_body(questions=production.QUESTIONS + ['which owned additive key applies?'],
                                               status='accepted', extra='\nOwned additional rationale.\n')
            else:
                self.fail('unknown independent floor mutation')
            self.write_record(fixture, row, data, metadata)
            if row['path'] != old_path:
                (fixture.root / old_path).unlink()
            expected = (row['id'], data)
        self.navigation(fixture)
        return expected

    def select(self, fixture, mode, baseline):
        if mode == 'staged':
            fixture.git('add', '.')
        elif mode == 'committed':
            fixture.git('commit', '-q', '-m', 'fixture select independently current-consistent floor change')
        staged = fixture.git('diff', '--cached', '--name-only', '--', 'docs/decisions')
        working = fixture.git('diff', '--name-only', '--', 'docs/decisions')
        if mode == 'worktree':
            self.assertEqual(staged, b'')
            self.assertNotEqual(working, b'')
        elif mode == 'staged':
            self.assertNotEqual(staged, b'')
            self.assertEqual(working, b'')
        else:
            self.assertEqual(staged + working, b'')
        parent = 'HEAD^' if mode == 'committed' else 'HEAD'
        self.assertEqual(fixture.git('rev-parse', parent).decode().strip(), baseline)

    def protected(self, fixture):
        return {path: (fixture.root / path).read_bytes() for path in (
            production.SOURCE, production.AUTHORITIES,
            'docs/decisions/history/transition-originals.json', 'docs/decisions/history/transition-index.md',
            'docs/decisions/history/0001-0050.json', 'docs/decisions/history/0001-0050.md')}

    def test_complete_current_authentication_precedes_prior_floor_refusal_in_every_mode(self):
        observed = set()
        for case, diagnostic in CASES.items():
            fixture, baseline = self.fixture()
            try:
                protected = self.protected(fixture)
                registry = (fixture.root / production.REGISTRY).read_bytes()
                expected = self.mutate(fixture, case)
                for mode, selector, prior in MODES:
                    with self.subTest(case=case, mode=mode):
                        self.select(fixture, mode, baseline)
                        self.success(fixture.public('check', selector=selector))
                        if expected is not None:
                            identity, data = expected
                            self.assertEqual(self.success(fixture.public('read-current', identity, selector=selector)), data)
                        self.refusal(fixture.public('check-continuity', selector=selector, prior=prior), diagnostic)
                        self.refusal(fixture.gate(), diagnostic, public=False)
                        for path, data in protected.items():
                            self.assertEqual((fixture.root / path).read_bytes(), data)
                        self.assertEqual((fixture.root / production.REGISTRY).read_bytes(), registry)
                        observed.add((case, mode))
                        print('production-floor: current authenticates; prior refuses ' + case + ' in ' + mode, flush=True)
            finally:
                fixture.close()
        self.assertEqual(observed, {(case, mode) for case in CASES for mode, _, _ in MODES})

    def test_owned_additive_content_status_and_questions_pass_all_modes(self):
        fixture, baseline = self.fixture()
        try:
            protected = self.protected(fixture)
            ceilings = {row['surface_id']: copy.deepcopy(row['enforcement_ceilings'])
                        for row in fixture.registry if 'surface_id' in row}
            identity, expected = self.mutate(fixture, 'owned additive evolution')
            surface = next(row for row in fixture.registry if row.get('surface_id') == 'rationale')
            _, actual = fixture.measure(surface['targets'])
            surface['transition']['max_growth'] = {
                axis: max(0, actual[axis] - surface['baseline'][axis]) for axis in actual}
            fixture.write(production.REGISTRY, ''.join(json.dumps(row, sort_keys=True) + '\n' for row in fixture.registry))
            self.assertEqual({row['surface_id']: row['enforcement_ceilings'] for row in fixture.registry if 'surface_id' in row}, ceilings)
            for mode, selector, prior in MODES:
                with self.subTest(mode=mode):
                    self.select(fixture, mode, baseline)
                    self.success(fixture.public('check', selector=selector))
                    self.assertEqual(self.success(fixture.public('read-current', identity, selector=selector)), expected)
                    change = json.loads(self.success(fixture.public('check-continuity', selector=selector, prior=prior)))
                    self.assertEqual(change, {'catalog': True, 'fresh_ids': [], 'resolved': []})
                    self.assertIn(f'0 increase(s), mode {mode}'.encode(), self.success(fixture.gate()))
                    for path, data in protected.items():
                        self.assertEqual((fixture.root / path).read_bytes(), data)
                    print('production-floor: owned additive evolution passes ' + mode, flush=True)
            self.assertEqual(fixture.git('status', '--porcelain'), b'')
        finally:
            fixture.close()


if __name__ == '__main__':
    unittest.main()
