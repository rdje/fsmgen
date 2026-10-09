"""Qualify positive wrong-line construction for the complete representative domain."""
import json
import runpy
from pathlib import Path


def main():
    audits = Path('docs/audits')
    base = audits / 'coordinate-original-hostile-20261009'
    mutations = runpy.run_path(str(base / 'mutations.py'))
    oracle = runpy.run_path(str(base / 'oracle.py'))
    qualification = runpy.run_path(str(base / 'qualify.py'))
    raw = json.loads((mutations['CLASS'] / 'raw-product.json').read_bytes())
    models = json.loads((mutations['CLASS'] / 'source-models.json').read_bytes())
    proofs = json.loads((mutations['CLASS'] / 'proofs.json').read_bytes())
    matched = json.loads((mutations['MATCHING'] / 'matching.json').read_bytes())
    points = qualification['representatives'](mutations['points'](raw, matched))
    fallback = []
    for point in points:
        selection = point['selection']
        allowed = set(selection['all_line_alternatives'].values())
        lines = {line for row in matched['expression_alternatives']['candidates']
                 if selection['reported_filename'] in row['filename_alternatives']
                 for line in row['line_alternatives'].values()}
        value = min(lines - allowed or {max(allowed) + 1})
        mutations['need'](type(value) is int and value > 0 and value not in allowed,
                          'valid positive wrong-line construction for every representative')
        if lines <= allowed:
            fallback.append((point, value))
    census = json.loads((audits / 'coordinate-original-hostile-checks-20261009/line-control-census.json').read_bytes())
    mutations['need']([point for point, _ in fallback] == [row['point'] for row in census['gaps']],
                      'complete independently retained exhausted-line cohort')
    pairs = oracle['forwarding'](raw, proofs)
    procedures = [runpy.run_path(str(mutations['MATCHING'] / p))[name]
                  for p, name in [('match.py', 'derive'), ('verify.py', 'reconstruct')]]
    results = []
    for point, value in fallback:
        candidate, affected = mutations['mutate'](raw, point, 'line', value, models)
        mutations['need']((candidate, affected) == oracle['construct'](raw, point, 'line', value, pairs),
                          'independent whole fallback mutation')
        prior = mutations['prior'](models, candidate)
        observer = oracle['observer_epoch'](matched['observer_qualification'], candidate)
        errors = []
        for procedure in procedures:
            try:
                procedure(candidate, matched['source_phases'], prior, matched['expression_alternatives'], observer)
            except ValueError as error:
                errors.append(str(error))
            else:
                raise ValueError('false-green fallback line coordinate')
        mutations['need'](errors == ['declared own caller coordinate: facade-parse', 'independent declared caller line'],
                          'intended coordinate-specific fallback refusals after complete predecessor pass')
        results.append({'point': point, 'line': value, 'affected': affected, 'refusals': errors,
                        'whole_predecessor_result': mutations['stamp'](prior)})
    print(json.dumps({'result': 'PASS complete positive wrong-line construction and exhausted-facade controls',
                      'representatives': len(points), 'fallback': results}, sort_keys=True))


if __name__ == '__main__':
    main()
