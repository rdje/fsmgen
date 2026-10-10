"""Retain complete dated beforeimages and reviewed prospective publication."""
import hashlib
import json
import runpy
import subprocess
from pathlib import Path

M = runpy.run_path('docs/audits/coordinate-current-preparation-20261010/model.py')
BASE, REVISION = M['BASE'], M['REVISION']


def pin(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'), 'sha256': hashlib.sha256(raw).hexdigest()}


def git(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    if result.returncode or result.stderr:
        raise ValueError('complete original Git source')
    return result.stdout


def main():
    if (BASE / 'proposal.json').exists():
        raise ValueError('preparation cannot overwrite retained proposal')
    cards = {}
    for path in M['PATHS']:
        original = git('show', REVISION + ':' + path)
        if Path(path).read_bytes() != original:
            raise ValueError('stable original live card before preparation')
        current = M['proposal'](path, original)
        front, paragraphs = M['parts'](original)
        _, proposed = M['parts'](current)
        locator = BASE / 'source' / (pin(original)['sha256'] + '.txt')
        locator.parent.mkdir(exist_ok=True)
        if locator.exists():
            raise ValueError('retained original source must be fresh')
        locator.write_bytes(original)
        cards[path] = {'original': pin(original), 'locator': str(locator),
            'proposal': pin(current), 'text': current.decode(),
            'original_metadata': front + '---\n',
            'paragraphs': [{'source': old, 'proposed': new,
                'review': 'Retains the original propositions and qualifiers; own coordinate progress is explicitly separated from dated local predicates and remaining private/external/address gaps.'}
                for old, new in zip(paragraphs, proposed)],
            'additions': proposed[len(paragraphs):]}
    totals = {role: {key: sum(row[role][key] for row in cards.values())
                    for key in ('bytes', 'lines')} for role in ('original', 'proposal')}
    if any(totals['proposal'][k] > totals['original'][k] for k in ('bytes', 'lines')):
        raise ValueError('non-growing complete proposal before publication')
    registry = git('show', REVISION + ':doctrine/live_document_size/surfaces.jsonl')
    surface = next(r for r in map(json.loads, registry.splitlines()) if r.get('surface_id') == 'knowledge_cards')
    receipt_path = 'docs/audits/coordinate-original-hostile-independent-checks-20261009/checks.json'
    receipts = git('show', REVISION + ':' + receipt_path)
    admitted = json.loads(receipts)['published-independent']
    if type(admitted['status']) is not int or admitted['status'] != 0:
        raise ValueError('committed complete original independent qualification required')
    product = {'revision': REVISION, 'owner': (BASE / 'scope.txt').read_text().strip(),
        'scope': 'Prospective retained source and reviewed mapping only; no current coordinate publication or fresh original recapture.',
        'cards': cards, 'totals': totals, 'authority': surface,
        'qualified_receipt': {'path': receipt_path, 'identity': pin(receipts),
                              'actual': admitted},
        'integration': {
            'current_route': M['CURRENT'], 'affected_cards': list(M['PATHS']),
            'parser_prior_route': 'python3 -B ' + M['PARSER_OLD'],
            'parser_snapshot_route': 'python3 -B ' + M['PARSER_SNAPSHOT'],
            'roles': {'historical': 'Unchanged sealed dated programmes, whole products, actual receipts and original inputs; snapshot success proves no live currency.',
                      'current': 'All four complete proposed cards, exact meanings/questions/probe/locality obligations; complete global direct/cache allocation, source membership, native copies and rendered scope.',
                      'borrowed': 'Reject stale target cards, old target queries, unrelated products, false statuses, foreign commands and substituted streams.',
                      'unrelated': 'Permit owned non-target progress within unchanged physical authority; derive global allocation from complete actual current canonical sources.'},
            'publication_requirements': ['Admit exact retained beforeimages under governed archive descriptors before card compaction.',
                'Extend the maintained current checker atomically to all four cards and preserve complete old class/frame, public recipe, expression and locality obligations.',
                'Route parser current facts to that maintained reader; keep its sealed earlier epoch-current programme and default snapshot unchanged.',
                'Qualify complete original coordinate result, current source/query/native scopes, historical/borrowed/unrelated controls and whole book delivery.',
                'Keep original private/provider/framework/formatter/toolchain/identity/address/alias/visual/HIAL/full-CI/push gaps owned.']},
        'legs': {'rederive': 'Independent binary Git objects, exact complete beforeimages, original metadata/questions, reviewed paragraph allocation and measured full working set.',
                 'falsify': 'Whole source/question/proposition/probe/scope/authority/type interventions through verify.py; actual over-budget drafts retain.',
                 'durability': 'Complete source copies, proposed full texts, ordered mapping, programmes, actual receipts and fixed Git revision committed before atomic publication.'}}
    (BASE / 'proposal.json').write_text(json.dumps(product, sort_keys=True, indent=2) + '\n')
    command = ['git', '--no-replace-objects', 'log', '-1', '--format=%H %s', '-S',
               'Full independent reconstruction now qualifies', '--', 'docs/book/src/90-reference-map.md']
    result = subprocess.run(command, capture_output=True, text=True)
    (BASE / 'root-cause.json').write_text(json.dumps({'command': command, 'status': result.returncode,
        'stdout': result.stdout, 'stderr': result.stderr}, sort_keys=True, indent=2) + '\n')
    if result.returncode or result.stderr or not result.stdout.startswith(REVISION):
        raise ValueError('complete qualification commit and remaining canonical admission locus')
    print('PASS complete original card retention, reviewed proposal and non-growing working set; current publication remains pending.')


if __name__ == '__main__':
    main()
