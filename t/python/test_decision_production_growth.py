"""Fresh growth from fixed actual production products, never fictional publication."""

import hashlib
import json
import posixpath
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
from decision_store_git import GitSnapshot
import decision_records as published

REVISION = '5ef1133c59f6d1814ebe7d1bf95373bdd77cbbc8'
SOURCE_PIN = 'a1f17aad2176c7edc1383e3bc064ebefb633767365e29404ba210302e1c231e3'
INDEX_PIN = '1a3675cd78a00b931968a051a8f561564dac9db74f673246a9234fd6a50659fa'
SOURCE = 'docs/audits/decision-store-transition-census.json'
CATALOG = 'docs/decisions/current/catalog.json'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
AUTHORITIES = 'doctrine/live_document_size/ceiling_increase_authorities.jsonl'
INDEX = 'docs/decisions/INDEX.md'
PART_INDEX = 'docs/decisions/current/verification/INDEX.md'
FRESH_PATH = 'docs/decisions/current/verification/0115-production-growth-fixture.md'
QUESTIONS = ['which fixture decision survives publication?', 'how are production fixture question keys retained?']
FRESH = '''---
id: production-growth-fixture
title: Fixture-only production-cohort decision
answers: ["which fixture decision survives publication?", "how are production fixture question keys retained?"]
date: 2026-09-30
status: current
tags: [qualification, fixture]
evidence: t/2010-decision-production-growth.t
reverify: python3 -B scripts/decision_records.py read-current 0115
---

# 0115 — Fixture-only production-cohort decision

Type: architecture / qualification
Status: proposed

This literal belongs only to a project-owned qualification fixture.
It exercises ordinary birth from the installed complete production cohort.
It is never published as a project decision or ceiling authority.
'''


def descriptor(data):
    lines = data.splitlines()
    return {'bytes': len(data), 'lines': len(lines), 'line_bytes': max(map(len, lines), default=0),
            'sha256': hashlib.sha256(data).hexdigest()}


class ProductionFixture:
    def __init__(self):
        parent = ROOT / '.artifacts/test/decision-production-growth'
        parent.mkdir(parents=True, exist_ok=True)
        self.workspace = tempfile.TemporaryDirectory(dir=parent)
        self.root = Path(self.workspace.name)
        try:
            snapshot = GitSnapshot(ROOT, REVISION)
            extra = {SOURCE, 'docs/audits/decision-record-rollover-census-20260927.json',
                     'docs/audits/decision-store-pre-transition-capacity.json', REGISTRY, AUTHORITIES}
            census = json.loads(snapshot.read('docs/audits/decision-record-rollover-census-20260927.json'))
            extra.update(posixpath.normpath(posixpath.join('docs/decisions', link['target']))
                         for link in census['selected_links'])
            extra.update(row['path'] for row in census['body_or_identity_consumers']
                         if row['text'].startswith('reverify:'))
            helpers = {f'scripts/{name}.py' for name in
                       ('decision_records', 'decision_catalog', 'decision_store', 'decision_store_git')}
            paths = sorted(path for path in snapshot.objects
                           if path.startswith('docs/decisions/') or path in extra | helpers)
            self.original_products = {path: snapshot.read(path) for path in paths}
            for path, data in self.original_products.items():
                self.write(path, data)
            if hashlib.sha256(self.original_products[SOURCE]).hexdigest() != SOURCE_PIN:
                raise ValueError('independent production source fingerprint differs')
            if hashlib.sha256(self.original_products['docs/decisions/history/transition-index.md']).hexdigest() != INDEX_PIN:
                raise ValueError('independent production index fingerprint differs')
            self.catalog = json.loads(self.original_products[CATALOG])
            self.registry = [json.loads(line) for line in self.original_products[REGISTRY].splitlines()]
            self.git('init', '-q')
            self.git('add', '.')
            self.git('commit', '-q', '-m', 'fixture authenticated production predecessor')
        except BaseException:
            self.close()
            raise

    def close(self):
        self.workspace.cleanup()

    def write(self, path, data):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data if type(data) is bytes else data.encode('utf-8'))

    def write_catalog(self):
        self.write(CATALOG, json.dumps(self.catalog, ensure_ascii=False, indent=2, sort_keys=True) + '\n')

    def git(self, *args):
        result = subprocess.run(['git', '-C', str(self.root), '-c', 'user.name=Production Growth Fixture',
                                 '-c', 'user.email=fixture@example.invalid', '-c', 'commit.gpgsign=false',
                                 '-c', 'core.hooksPath=.fixture-hooks', *args], capture_output=True, timeout=60)
        if result.returncode:
            raise ValueError(result.stderr.decode(errors='replace'))
        return result.stdout

    def public(self, operation, *ids, selector='worktree', prior=None, installed=False):
        cli = (self.root if installed else ROOT) / 'scripts/decision_records.py'
        arguments = [sys.executable, '-B', str(cli)]
        if not installed:
            arguments += ['--root', str(self.root), '--source-sha256', SOURCE_PIN, '--index-sha256', INDEX_PIN]
        arguments += ['--snapshot', selector]
        if prior is not None:
            arguments += ['--prior-snapshot', prior]
        return subprocess.run(arguments + [operation, *ids], capture_output=True, timeout=60)

    def gate(self):
        return subprocess.run(['perl', str(ROOT / 'scripts/check_live_document_ceiling_authority.pl'),
                               '--root', str(self.root), '--source-sha256', SOURCE_PIN, '--index-sha256', INDEX_PIN],
                              capture_output=True, timeout=120)

    def measure(self, patterns):
        paths = sorted({str(path.relative_to(self.root)) for pattern in patterns
                        for path in self.root.glob(pattern) if path.is_file()})
        raw = [(self.root / path).read_bytes() for path in paths]
        dimensions = {'files': len(raw), 'bytes_total': sum(map(len, raw)),
                      'lines_total': sum(len(data.splitlines()) for data in raw),
                      'bytes_each': max(map(len, raw)), 'lines_each': max(len(data.splitlines()) for data in raw),
                      'line_bytes_each': max(len(line) for data in raw for line in data.splitlines())}
        # File::Glob uses direct segment semantics; it does not traverse slash
        # descendants as fnmatch can. Dimensions are independently byte-counted.
        oracle = subprocess.run(['perl', '-MFile::Glob=bsd_glob', '-MJSON::PP', '-e', '''
my @paths = sort map { bsd_glob($_) } @ARGV;
my %seen; @paths = grep { -f $_ && !$seen{$_}++ } @paths;
my %d = (files=>scalar(@paths), bytes_total=>0, lines_total=>0, bytes_each=>0, lines_each=>0, line_bytes_each=>0);
for my $p (@paths) {
    open my $f, '<:raw', $p or die $!; local $/; my $b=<$f>; close $f;
    my @lines=split /\\n/, $b, -1; pop @lines if substr($b,-1) eq "\\n"; @lines=() if $b eq '';
    my $bytes=length($b); my $lines=scalar(@lines);
    $d{bytes_total}+=$bytes; $d{lines_total}+=$lines;
    $d{bytes_each}=$bytes if $bytes>$d{bytes_each}; $d{lines_each}=$lines if $lines>$d{lines_each};
    for my $line (@lines) { my $n=length($line); $d{line_bytes_each}=$n if $n>$d{line_bytes_each}; }
}
print JSON::PP->new->canonical(1)->encode({paths=>\\@paths, dimensions=>\\%d});
''', *patterns], cwd=self.root, capture_output=True, timeout=30)
        if oracle.returncode:
            raise ValueError(oracle.stderr.decode(errors='replace'))
        if json.loads(oracle.stdout) != {'paths': paths, 'dimensions': dimensions}:
            raise ValueError('independent direct-glob census differs')
        return paths, dimensions

    def birth(self):
        data = FRESH.encode('utf-8')
        row = {'id': '0115', 'path': FRESH_PATH, 'type': 'architecture / qualification',
               'content': descriptor(data), 'metadata': {'knowledge_id': 'production-growth-fixture',
               'knowledge_status': 'current', 'questions': list(QUESTIONS), 'authority_status': ['Status: proposed']}}
        self.catalog['records'].append(row)
        self.write(FRESH_PATH, data)
        self.write_catalog()
        cells = 'Fixture-only production-cohort decision | architecture / qualification | Isolated fresh-growth proof. |\n'
        self.write(INDEX, self.original_products[INDEX].decode() + '| [0115](current/verification/'
                   + Path(FRESH_PATH).name + ') | ' + cells)
        self.write(PART_INDEX, self.original_products[PART_INDEX].decode() + '| [0115]('
                   + Path(FRESH_PATH).name + ') | ' + cells)


class ProductionGrowth(unittest.TestCase):
    def success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def test_actual_production_birth_and_unchanged_capacity_pass_every_mode(self):
        self.assertEqual(published.STORE_SOURCE_SHA256, SOURCE_PIN)
        self.assertEqual(published.STORE_INDEX_SHA256, INDEX_PIN)
        fixture = ProductionFixture()
        self.addCleanup(fixture.close)
        self.success(fixture.public('check', installed=True))
        current_surface = next(row for row in fixture.registry if row.get('surface_id') == 'rationale')
        compatibility = next(row for row in fixture.registry if row.get('surface_id') == 'decision_compatibility')
        before_current, before_dimensions = fixture.measure(current_surface['targets'])
        before_compatibility, _ = fixture.measure(compatibility['targets'])
        aliases = {path: data for path, data in fixture.original_products.items()
                   if path.startswith('docs/decisions/') and path.count('/') == 2 and path != INDEX}
        fixture.birth()
        after_current, dimensions = fixture.measure(current_surface['targets'])
        after_compatibility, compatibility_dimensions = fixture.measure(compatibility['targets'])
        self.assertEqual(set(after_current) - set(before_current), {FRESH_PATH})
        self.assertEqual(set(before_current) - set(after_current), set())
        self.assertEqual(after_compatibility, before_compatibility)
        self.assertEqual(len(aliases), 114)
        for path, data in aliases.items():
            self.assertEqual((fixture.root / path).read_bytes(), data)
        for actual, surface in ((dimensions, current_surface), (compatibility_dimensions, compatibility)):
            for key, value in actual.items():
                self.assertLessEqual(value, surface['enforcement_ceilings'][key])
        # This real cohort is near its aggregate warning target. Record the
        # fixture's resulting warning honestly, while retaining every ceiling.
        self.assertGreaterEqual(dimensions['lines_total'] * 100,
                                current_surface['health_targets']['lines_total'] * current_surface['milestones']['warning_pct'])
        current_surface['state'] = 'warning_debt'
        current_surface['baseline'] = before_dimensions
        current_surface['transition'] = {'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.3.3.2.1',
            'max_growth': {key: max(0, dimensions[key] - before_dimensions[key]) for key in dimensions},
            'ratchet_step': {key: 1 for key in dimensions}}
        fixture.write(REGISTRY, ''.join(json.dumps(row, sort_keys=True) + '\n' for row in fixture.registry))
        old_registry = [json.loads(line) for line in fixture.original_products[REGISTRY].splitlines()]
        self.assertEqual({row['surface_id']: row['enforcement_ceilings'] for row in old_registry if 'surface_id' in row},
                         {row['surface_id']: row['enforcement_ceilings'] for row in fixture.registry if 'surface_id' in row})
        originals = {row['id']: row['text'].encode() for row in json.loads(
            fixture.original_products['docs/decisions/history/transition-originals.json'])['records']}
        for mode, selector, prior in [('worktree', 'worktree', 'HEAD'), ('staged', 'index', 'HEAD'),
                                     ('committed', 'HEAD', 'HEAD^')]:
            with self.subTest(mode=mode):
                if mode == 'staged':
                    fixture.git('add', '.')
                elif mode == 'committed':
                    fixture.git('commit', '-q', '-m', 'fixture publish ordinary fact-bearing birth')
                self.success(fixture.public('check', selector=selector))
                change = json.loads(self.success(fixture.public('check-continuity', selector=selector, prior=prior)))
                self.assertEqual(change, {'catalog': True, 'fresh_ids': ['0115'], 'resolved': []})
                for operation in ('read', 'read-current'):
                    self.assertEqual(self.success(fixture.public(operation, '0115', selector=selector)), FRESH.encode())
                missing = fixture.public('read-original', '0115', selector=selector)
                self.assertEqual(missing.returncode, 1)
                self.assertEqual(missing.stdout, b'')
                self.assertIn(b'unavailable read-original product', missing.stderr)
                self.assertEqual(self.success(fixture.public('read-original', '0113', selector=selector)), originals['0113'])
                self.assertEqual(self.success(fixture.public('read', '0113', selector=selector)), originals['0113'])
                old_current = next(row['path'] for row in fixture.catalog['records'] if row['id'] == '0113')
                self.assertEqual(self.success(fixture.public('read-current', '0113', selector=selector)),
                                 fixture.original_products[old_current])
                self.assertIn(f'0 increase(s), mode {mode}'.encode(), self.success(fixture.gate()))
        for path in (SOURCE, 'docs/decisions/history/transition-originals.json',
                     'docs/decisions/history/transition-index.md', 'docs/decisions/history/0001-0050.json',
                     'docs/decisions/history/0001-0050.md', AUTHORITIES):
            self.assertEqual((fixture.root / path).read_bytes(), fixture.original_products[path])
        self.assertEqual(fixture.git('status', '--porcelain'), b'')
        print('production-growth: all worktree/index/committed products pass; '
              f'current membership {len(before_current)} -> {len(after_current)}; fixed aliases {len(aliases)}; '
              f'current lines {before_dimensions["lines_total"]} -> {dimensions["lines_total"]}; '
              'compatibility membership unchanged; warning recorded; ceilings unchanged')


if __name__ == '__main__':
    unittest.main()
