"""Self-consistent post-transition changes still retain every previously published key."""

import copy
import json
import subprocess
import sys
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
import test_decision_ceiling_stores as gates
import test_decision_store as stores
import test_decision_catalog as literals

ROOT = Path(__file__).resolve().parents[2]
CLI = ROOT / 'scripts/decision_records.py'
QUESTIONS = ['which future fact applies?', 'why is the future identity retained?']


def fact_body(knowledge_id='future-fact', questions=QUESTIONS, status='proposed'):
    front = '' if knowledge_id is None else (
        '---\nid: ' + knowledge_id + '\nanswers: ' + json.dumps(questions) + '\nstatus: current\n---\n')
    return front + literals.FRESH.replace('Status: proposed', 'Status: ' + status)


def metadata(knowledge_id='future-fact', questions=QUESTIONS, status='proposed'):
    return {'knowledge_id': knowledge_id, 'knowledge_status': 'current' if knowledge_id else None,
            'questions': list(questions) if knowledge_id else [], 'authority_status': ['Status: ' + status]}


class PublishedIdentityModes(unittest.TestCase):
    def fixture(self):
        fixture = gates.CanonicalAuthorityGate()
        fixture.setUp()
        try:
            fixture.birth()
            row = fixture.fixture.catalog['records'][-1]
            self.write_body(fixture, row, fact_body(), metadata())
            fixture.git('add', '.')
            fixture.git('commit', '-q', '-m', 'fixture published post-transition fact and questions')
            return fixture
        except BaseException:
            fixture.doCleanups()
            raise

    def write_body(self, fixture, row, text, meta=None):
        fixture.fixture.write(row['path'], text)
        row['content'] = literals.content(text)
        if meta is not None:
            row['metadata'] = meta
        fixture.fixture.write_json(stores.store.CATALOG, fixture.fixture.catalog)

    def navigation(self, fixture):
        root_rows = []
        parts = {part: stores.PART_ROWS[part] for part in stores.PART_ROWS}
        for row in sorted(fixture.fixture.catalog['records'], key=lambda row: row['id']):
            if row['id'] in ('0051', '0100'):
                continue
            identity, path, category = row['id'], row['path'], row['type']
            cells = 'Fresh | ' + category + ' | Later body. |\n'
            root_rows.append(f'| [{identity}](' + path.removeprefix('docs/decisions/') + ') | ' + cells)
            part = Path(path).parent.name
            parts[part] += f'| [{identity}]({Path(path).name}) | ' + cells
        fixture.fixture.catalog['records'].sort(key=lambda row: row['id'])
        fixture.fixture.write_json(stores.store.CATALOG, fixture.fixture.catalog)
        fixture.fixture.write(stores.store.INDEX, stores.ROOT_INDEX + ''.join(root_rows))
        for part, rows in parts.items():
            fixture.fixture.write(f'docs/decisions/current/{part}/INDEX.md', stores.PART_PREFIX + rows)

    def select(self, fixture, mode):
        if mode != 'worktree':
            fixture.git('add', '.')
        if mode == 'committed':
            fixture.git('commit', '-q', '-m', 'fixture independently selected current mutation')
        return {'worktree': 'worktree', 'staged': 'index', 'committed': 'HEAD'}[mode]

    def current_check(self, fixture, selector):
        return subprocess.run([
            sys.executable, '-B', str(CLI), '--root', str(fixture.root),
            '--source-sha256', fixture.fixture.source_digest,
            '--index-sha256', fixture.fixture.index_digest,
            '--snapshot', selector, 'check'], capture_output=True)

    def mutate(self, fixture, case):
        row = fixture.fixture.catalog['records'][-1]
        if case == 'deletion':
            fixture.fixture.catalog['records'].remove(row)
            (fixture.root / row['path']).unlink()
        elif case == 'equal-count birth replacement':
            old = row['path']
            row['id'] = '0116'
            row['path'] = old.replace('0115', '0116')
            text = (fixture.root / old).read_text().replace('# 0115', '# 0116')
            (fixture.root / old).unlink()
            self.write_body(fixture, row, text)
        elif case == 'path recycling':
            old = row['path']
            row['path'] = old.replace('/language-api/', '/verification/')
            self.write_body(fixture, row, (fixture.root / old).read_text())
            (fixture.root / old).unlink()
        elif case == 'type recycling':
            row['type'] = 'verification architecture'
        elif case == 'fact deletion':
            self.write_body(fixture, row, fact_body(None), metadata(None))
        elif case == 'fact replacement':
            self.write_body(fixture, row, fact_body('different-fact'), metadata('different-fact'))
        elif case == 'question deletion':
            retained = QUESTIONS[:1]
            self.write_body(fixture, row, fact_body(questions=retained), metadata(questions=retained))
        elif case == 'equal-count question replacement':
            replaced = [QUESTIONS[0], 'which unowned replacement applies?']
            self.write_body(fixture, row, fact_body(questions=replaced), metadata(questions=replaced))
        elif case == 'earlier gap birth':
            new = copy.deepcopy(row)
            new.update(id='0110', path='docs/decisions/current/language-api/0110-gap.md')
            new['metadata'] = metadata(None)
            text = literals.FRESH.replace('0115', '0110')
            fixture.fixture.catalog['records'].append(new)
            self.write_body(fixture, new, text)
        else:
            self.fail('unknown independent mutation')
        self.navigation(fixture)

    def test_complete_current_products_cannot_delete_recycle_or_lose_prior_keys_in_any_mode(self):
        cases = {
            'deletion': 'deleted a prior decision identity',
            'equal-count birth replacement': 'deleted a prior decision identity',
            'path recycling': 'recycles a prior decision identity',
            'type recycling': 'recycles a prior decision identity',
            'fact deletion': 'loses prior fact identity',
            'fact replacement': 'loses prior fact identity',
            'question deletion': 'loses prior question keys',
            'equal-count question replacement': 'loses prior question keys',
            'earlier gap birth': 'reuses earlier decision ID space',
        }
        for mode in ('worktree', 'staged', 'committed'):
            for case, diagnostic in cases.items():
                with self.subTest(mode=mode, case=case):
                    fixture = self.fixture()
                    try:
                        self.mutate(fixture, case)
                        selector = self.select(fixture, mode)
                        current = self.current_check(fixture, selector)
                        self.assertEqual(current.returncode, 0, current.stdout + current.stderr)
                        fixture.failure(fixture.run_checker(), diagnostic)
                    finally:
                        fixture.doCleanups()

    def test_owned_content_status_summary_and_additive_questions_pass_every_mode(self):
        for mode in ('worktree', 'staged', 'committed'):
            with self.subTest(mode=mode):
                fixture = self.fixture()
                try:
                    row = fixture.fixture.catalog['records'][-1]
                    added = QUESTIONS + ['which additive owned explanation applies?']
                    body = fact_body(questions=added, status='accepted') + '\nOwned later rationale.\n'
                    self.write_body(fixture, row, body, metadata(questions=added, status='accepted'))
                    self.navigation(fixture)
                    for path in (stores.store.INDEX, 'docs/decisions/current/language-api/INDEX.md'):
                        text = (fixture.root / path).read_text().replace('Later body.', 'Owned later summary.')
                        fixture.fixture.write(path, text)
                    selector = self.select(fixture, mode)
                    current = self.current_check(fixture, selector)
                    self.assertEqual(current.returncode, 0, current.stdout + current.stderr)
                    result = fixture.run_checker()
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertIn(f'0 increase(s), mode {mode}'.encode(), result.stdout)
                finally:
                    fixture.doCleanups()


if __name__ == '__main__':
    unittest.main()
