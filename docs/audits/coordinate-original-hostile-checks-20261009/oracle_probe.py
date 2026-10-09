"""Check independent geometry against original whole records before qualification."""
import json
import runpy
from pathlib import Path


def main():
    audits = Path('docs/audits')
    base = audits / 'coordinate-original-hostile-20261009'
    producer = runpy.run_path(str(base / 'mutations.py'))
    oracle = runpy.run_path(str(base / 'oracle.py'))
    raw = json.loads((producer['CLASS'] / 'raw-product.json').read_bytes())
    models = json.loads((producer['CLASS'] / 'source-models.json').read_bytes())
    proofs = json.loads((producer['CLASS'] / 'proofs.json').read_bytes())
    matched = json.loads((producer['MATCHING'] / 'matching.json').read_bytes())
    points = producer['points'](raw, matched)
    independent, bindings = oracle['points'](raw, matched, proofs)
    producer['need'](points == independent, 'complete independent point reconstruction')
    pairs = producer['forwarding'](models, raw)
    producer['need'](pairs == oracle['forwarding'](raw, proofs), 'complete independent forwarding reconstruction')
    selected = [
        points[0],
        next(p for p in points if p['kind'] == 'frame'),
        next(p for p in points if p['kind'] == 'load'),
        next(p for p in points if any(p['key'] == pair['parent'] and p['phase'] == 0 for pair in pairs)),
    ]
    results = []
    qualification = runpy.run_path(str(base / 'qualify.py'))
    for point in selected:
        for field, value in [('line', max(point['selection']['all_line_alternatives'].values()) + 1),
                             ('path', 'borrowed.pl')]:
            actual = producer['mutate'](raw, point, field, value, models)
            expected = oracle['construct'](raw, point, field, value, pairs)
            producer['need'](actual == expected, 'independent whole intervention and affected allocation')
            results.append({'point': point, 'field': field, 'whole_intervention': producer['stamp'](actual)})
        actual = qualification['borrow_source'](matched['source_phases'], matched, point, 'borrowed-recipe', raw)
        expected = oracle['borrow_source'](matched['source_phases'], point, 'borrowed-recipe', bindings)
        producer['need'](actual == expected, 'independent source binding intervention')
    print(json.dumps({'result': 'PASS complete independent original geometry and representative whole interventions',
                      'points': len(points), 'pairs': len(pairs), 'controls': results}, sort_keys=True))


if __name__ == '__main__':
    main()
