"""Publish only the reviewed retention-proposal reader scope."""
import hashlib
import json
import runpy
import subprocess
from pathlib import Path

BASE = Path('docs/audits/public-boundary-retention-checks-20261006')
REVISION = '887d243bfdb1a46771fa512be33446db75f015b8'
CHAPTER = 'docs/book/src/13k-isf-feature-support-matrix.md'
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.5.4.2.1'


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def main():
    before = subprocess.check_output(['git', 'show', REVISION + ':' + CHAPTER]).decode()
    assert Path(CHAPTER).read_text() == before
    old = runpy.run_path('docs/audits/public-boundary-draft-checks-20261006/book.py')['GUIDE']
    guide = runpy.run_path(str(BASE / 'book.py'))['GUIDE']
    assert before.count(old) == 1
    historical = old.replace('A source-bound draft', 'At the draft checkpoint, a source-bound draft', 1)
    after = before.replace(old, historical + guide, 1)
    before_population = {}
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src'], text=True).splitlines()
    for path in paths:
        if Path(path).parent == Path('docs/book/src') and path.endswith('.md'):
            before_population[path] = subprocess.check_output(['git', 'show', REVISION + ':' + path])
    current = {str(p): p.read_bytes() for p in Path('docs/book/src').glob('*.md')}
    assert current == before_population
    survivor = {**before_population, CHAPTER: after.encode()}
    def metrics(population):
        return dict(files=len(population), lines_total=sum(b.count(b'\n') for b in population.values()),
                    bytes_total=sum(map(len, population.values())))
    baseline = metrics(before_population)
    delta = {k: metrics(survivor)[k] - baseline[k] for k in baseline}
    registry = Path(REGISTRY); lines = registry.read_text().splitlines()
    i = next(i for i, s in enumerate(lines) if json.loads(s).get('surface_id') == 'shipped_behavior')
    authority_before = json.loads(lines[i]); authority_after = json.loads(lines[i])
    authority_after['reference_contract']['aggregate_change'] = dict(
        authority_id='PUBLIC-BOUNDARY-RETENTION-20261006-SHIPPED-BEHAVIOR', owner=OWNER,
        baseline=baseline, delta=delta,
        rationale='Explain the complete reviewed retention proposal, source/counterexample qualification and separate pending current publication.')
    lines[i] = json.dumps(authority_after, sort_keys=True, separators=(',', ':'))
    proof = dict(revision=REVISION, before=before, after=after, authority_before=authority_before,
                 authority_after=authority_after, baseline=baseline, delta=delta,
                 before_members={p: identity(b) for p, b in before_population.items()},
                 after_members={p: identity(b) for p, b in survivor.items()},
                 role='Current guide about retained proposal only; no live card/current-query publication.')
    output = BASE / 'book-change.json'; assert not output.exists()
    output.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    Path(CHAPTER).write_text(after)
    registry.write_text('\n'.join(lines) + '\n')
    print('PASS complete scoped retention guide and exact aggregate authority; live card unchanged.')


if __name__ == '__main__':
    main()
