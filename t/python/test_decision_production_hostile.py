"""Malformed full production-cohort products refuse every selected mode."""

import json
import unittest

import test_decision_production_growth as production

ALIAS = 'docs/decisions/0113-isf-record-interface-ports-reuse-packed-type-and-writer-contracts.md'
CASES = {
    'missing compatibility heading': b'compatibility page is stale or altered: 0113',
    'wrong compatibility heading': b'compatibility page is stale or altered: 0113',
    'duplicate root route': b'index duplicates decision ID: 0115',
    'misrouted root route': b'index misroutes decision ID: 0115',
    'duplicate part route': b'index duplicates decision ID: 0115',
    'misrouted part route': b'index misroutes decision ID: 0115',
    'changed current body': b'record dimensions or digest changed',
    'missing current body': b'source',
}
MODES = [('worktree', 'worktree', 'HEAD'), ('staged', 'index', 'HEAD'),
         ('committed', 'HEAD', 'HEAD^')]


def publish_birth(fixture, owner):
    """Publish the literal positive population with honest fixture pressure."""
    surface = next(row for row in fixture.registry if row.get('surface_id') == 'rationale')
    _, before = fixture.measure(surface['targets'])
    fixture.birth()
    _, after = fixture.measure(surface['targets'])
    surface['state'] = 'warning_debt'
    surface['baseline'] = before
    surface['transition'] = {'owner': owner,
        'max_growth': {axis: max(0, after[axis] - before[axis]) for axis in before},
        'ratchet_step': {axis: 1 for axis in before}}
    fixture.write(production.REGISTRY, ''.join(json.dumps(row, sort_keys=True) + '\n' for row in fixture.registry))
    fixture.git('add', '.')
    fixture.git('commit', '-q', '-m', 'fixture publish authenticated literal production-cohort birth')
    return fixture.git('rev-parse', 'HEAD').decode().strip()


class ProductionHostile(unittest.TestCase):
    def success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def refusal(self, result, diagnostic, public=True):
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        if public:
            self.assertEqual(result.stdout, b'', 'no partial authenticated public product')
        self.assertIn(diagnostic, result.stderr)

    def mutate(self, fixture, case):
        if 'compatibility heading' in case:
            original = fixture.original_products[ALIAS]
            self.assertEqual(original.count(b'## Context\n'), 1)
            changed = original.replace(b'## Context\n', b'' if case.startswith('missing') else b'## Altered context\n')
            fixture.write(ALIAS, changed)
        elif 'route' in case:
            path = production.INDEX if 'root' in case else production.PART_INDEX
            raw = (fixture.root / path).read_bytes()
            rows = [line for line in raw.splitlines(keepends=True) if line.startswith(b'| [0115](')]
            self.assertEqual(len(rows), 1)
            row = rows[0]
            if case.startswith('duplicate'):
                changed = raw + row
            else:
                # A literal wrong destination retains the authored ID/type/cells.
                wrong = (b'current/verification/0116-unowned.md' if 'root' in case else b'0116-unowned.md')
                suffix = row[row.index(b') |'):]
                changed = raw.replace(row, b'| [0115](' + wrong + suffix)
            fixture.write(path, changed)
        elif case == 'changed current body':
            original = production.FRESH.encode()
            changed = original.replace(b'ordinary birth', b'altered  birth')
            self.assertNotEqual(changed, original)
            self.assertEqual(len(changed), len(original), 'equal-size body corruption cannot hide behind dimensions')
            fixture.write(production.FRESH_PATH, changed)
        elif case == 'missing current body':
            (fixture.root / production.FRESH_PATH).unlink()
        else:
            self.fail('unknown independent malformed product')

    def selected_state(self, fixture, mode, baseline):
        staged = fixture.git('diff', '--cached', '--name-only', '--', 'docs/decisions')
        working = fixture.git('diff', '--name-only', '--', 'docs/decisions')
        if mode == 'worktree':
            self.assertEqual(staged, b'')
            self.assertNotEqual(working, b'')
            self.assertEqual(fixture.git('rev-parse', 'HEAD').decode().strip(), baseline)
        elif mode == 'staged':
            self.assertNotEqual(staged, b'')
            self.assertEqual(working, b'')
            self.assertEqual(fixture.git('rev-parse', 'HEAD').decode().strip(), baseline)
        else:
            self.assertEqual(staged + working, b'')
            self.assertEqual(fixture.git('rev-parse', 'HEAD^').decode().strip(), baseline)

    def test_actual_production_alias_index_and_body_corruptions_refuse_all_modes(self):
        fixture = production.ProductionFixture()
        self.addCleanup(fixture.close)
        self.success(fixture.public('check', installed=True))
        baseline = publish_birth(fixture, 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2.2')
        self.success(fixture.public('check', selector='HEAD', installed=True))
        self.assertEqual(self.success(fixture.public('read-current', '0115', selector='HEAD')), production.FRESH.encode())
        birth = json.loads(self.success(fixture.public('check-continuity', selector='HEAD', prior='HEAD^')))
        self.assertEqual(birth, {'catalog': True, 'fresh_ids': ['0115'], 'resolved': []})
        self.assertIn(b'0 increase(s), mode committed', self.success(fixture.gate()))
        protected = {path: (fixture.root / path).read_bytes() for path in (
            production.SOURCE, production.REGISTRY, production.AUTHORITIES,
            production.CATALOG, 'docs/decisions/history/transition-originals.json',
            'docs/decisions/history/transition-index.md', 'docs/decisions/history/0001-0050.json',
            'docs/decisions/history/0001-0050.md')}
        observed = set()
        for case, diagnostic in CASES.items():
            try:
                fixture.git('reset', '--hard', baseline)  # Only this exclusively owned temporary test repository.
                self.assertEqual(fixture.git('status', '--porcelain'), b'')
                self.mutate(fixture, case)
                for mode, selector, prior in MODES:
                    with self.subTest(case=case, mode=mode):
                        if mode == 'staged':
                            fixture.git('add', '.')
                        elif mode == 'committed':
                            fixture.git('commit', '-q', '-m', 'fixture select independent malformed product')
                        self.selected_state(fixture, mode, baseline)
                        for operation, ids in [('check', ()), ('read-current', ('0115',))]:
                            self.refusal(fixture.public(operation, *ids, selector=selector), diagnostic)
                        self.refusal(fixture.public('check-continuity', selector=selector, prior=prior), diagnostic)
                        self.refusal(fixture.gate(), diagnostic, public=False)
                        for path, raw in protected.items():
                            self.assertEqual((fixture.root / path).read_bytes(), raw)
                        observed.add((case, mode))
                        print('production-hostile: refused ' + case + ' in ' + mode, flush=True)
            finally:
                fixture.git('reset', '--hard', baseline)
        self.assertEqual(observed, {(case, mode) for case in CASES for mode, _, _ in MODES})
        self.assertEqual(fixture.git('status', '--porcelain'), b'')
        self.success(fixture.public('check', selector='HEAD', installed=True))
        self.assertIn(b'0 increase(s), mode committed', self.success(fixture.gate()))


if __name__ == '__main__':
    unittest.main()
