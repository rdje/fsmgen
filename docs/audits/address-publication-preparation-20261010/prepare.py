"""Retain whole fixed sources, reviewed prospective cards and actual qualifications."""
import hashlib
import json
import runpy
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/address-publication-preparation-20261010')
sys.path.insert(0, str(Path(__file__).resolve().parents[3] / 'scripts'))
REVISION = 'a6c92162dd8d0cd7ec718423b9756c2f5a2d4193'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'), 'sha256': hashlib.sha256(raw).hexdigest()}


def git(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(result.returncode == 0 and result.stderr == b'', 'complete fixed preparation Git source')
    return result.stdout


def main():
    model = runpy.run_path(str(BASE / 'model.py'))
    need(not (BASE / 'proposal.json').exists(), 'retain first complete qualified proposal')
    paths = set(model['PATHS']) | {'scripts/check_record_value_publication.py',
        'scripts/record_value_coordinate_fact.py', 'scripts/record_value_epoch_fact.py',
        'scripts/record_value_public_reference_fact.py', 'scripts/record_value_expression_fact.py',
        'docs/book/src/13k-isf-feature-support-matrix.md', 'docs/book/src/90-reference-map.md',
        'doctrine/live_document_size/surfaces.jsonl'}
    parent = Path('docs/audits/address-parent-acceptance-20261010')
    paths.update(json.loads((parent / 'binding.json').read_bytes())['members'])
    for namespace in (parent, Path('docs/audits/address-source-integration-20261010')):
        committed = git('ls-tree', '-r', '--name-only', REVISION, '--', str(namespace)).decode().splitlines()
        need(committed == sorted(str(p) for p in namespace.rglob('*') if p.is_file() or p.is_symlink()), 'whole preparation prerequisite namespace')
        paths.update(committed)
    retained = {}; originals = {}
    source = BASE / 'source'; source.mkdir(exist_ok=True)
    for path in sorted(paths):
        raw = git('cat-file', 'blob', REVISION + ':' + str(path))
        need(Path(path).read_bytes() == raw and not Path(path).is_symlink(), 'whole live fixed preparation input')
        identity = pin(raw); retained[str(path)] = identity
        if path in model['PATHS'] or str(path).startswith('scripts/') or str(path).startswith('docs/book/src/') or str(path).startswith('doctrine/'):
            locator = source / (identity['sha256'] + '.txt')
            if locator.exists():
                need(locator.read_bytes() == raw, 'whole immutable retained partial beforeimage')
            else:
                locator.write_bytes(raw)
            originals[str(path)] = {'identity': identity, 'locator': str(locator)}
    cards = {}
    for path in model['PATHS']:
        raw = Path(path).read_bytes(); proposed = model['proposal'](path, raw)
        front, old = model['parts'](raw); new_front, new = model['parts'](proposed)
        cards[path] = {'original': originals[path], 'proposed_identity': pin(proposed), 'text': proposed.decode(),
            'original_metadata': front + '---\n', 'proposed_metadata': new_front + '---\n',
            'paragraphs': [{'source': a, 'proposed': b, 'review': 'Reviewed original propositions, scope, questions, probes and locality retain. Separately qualified finite source/numerical progress updates only prior source-address gaps; native limits remain. Tooling parser-current authority is also explicit in its complete current-check paragraph.'}
                           for a, b in zip(old, new)], 'additions': new[len(old):]}
    totals = {role: {key: sum((row['original']['identity'] if role == 'original' else row['proposed_identity'])[key]
                             for row in cards.values()) for key in ('bytes', 'lines')} for role in ('original', 'proposal')}
    need(all(totals['proposal'][k] <= totals['original'][k] for k in ('bytes', 'lines')), 'non-growing complete prospective working set')
    namespace = runpy.run_path('scripts/check_record_value_publication.py'); canonical = namespace['sources']()
    prior = namespace['historical'](); allocation = prior['metadata']['allocation'](canonical)
    actual_queries = prior['public']['queries']()
    for role, actual in actual_queries.items():
        need(type(actual['status']) is int and actual['status'] == 0 and actual['stdout'] == allocation['rows']
             and actual['stderr'] == '', 'complete actual original query allocation')
    registry = Path('doctrine/live_document_size/surfaces.jsonl').read_bytes()
    authority = next(r for r in map(json.loads, registry.splitlines()) if r.get('surface_id') == 'knowledge_cards')
    checks = json.loads((BASE / 'checks.json').read_bytes())
    actual = {k: checks[k] for k in ('prerequisite', 'source-model')}
    product = {'owner': (BASE / 'scope.txt').read_text().strip(), 'revision': REVISION,
        'scope': 'Prospective retained beforeimages, reviewed complete proposition correspondence and non-growing address publication only; no current canonical write or native recapture.',
        'fixed_members': retained, 'beforeimages': originals, 'cards': cards, 'totals': totals, 'authority': authority,
        'original_canonical_members': {p: pin(raw) for p, raw in canonical.items()}, 'original_queries': actual_queries,
        'actual_readers': actual,
        'integration': {'current_reader': model['CURRENT'], 'new_question': model['QUESTION'],
            'requirements': ['Admit all exact beforeimages through governed history before canonical compaction.',
                'Atomically admit exact full cards and maintained current-reader semantics; preserve old stdout and every original query/probe.',
                'Authenticate complete admitted original source/holder/numerical/parent products and actual results; authentication is not fresh semantic recapture.',
                'Derive complete current canonical membership, global direct/cache ownership, physical census and native source/book delivery; permit qualified unrelated progress.',
                'Retain distinct historical/current/borrowed/unrelated roles and native/provider/formatter/CODE/Regexp/reuse/heap/cold/visual/HIAL/full-CI/push gaps.',
                'Close publication/address parents only after complete unchanged acceptance qualifies in the final successor.']},
        'legs': {'rederive': 'Fixed Git sources, exact beforeimages, complete ordered paragraph/metadata correspondence and full measured prospective texts.',
                 'falsify': 'Independent fixed-source/global-query/metadata/probe/capacity reconstruction and genuine whole-proposal/actual-result interventions; full source and parent readers execute freshly.',
                 'durability': 'Complete original/current/proposed source records, first unadmitted drafts, programmes/actual outcomes and task/book/Git checkpoint before publication.'},
        'missing_legs': 'Natural-language proposition equivalence is a recorded review, not a universal automated proof. Atomic canonical/current/native publication and full address-container acceptance remain successors. Native object identity is unmeasured.'}
    (BASE / 'proposal.json').write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    print('PASS complete retained address beforeimages and reviewed non-growing proposal; current canonical publication remains pending.')


if __name__ == '__main__':
    main()
