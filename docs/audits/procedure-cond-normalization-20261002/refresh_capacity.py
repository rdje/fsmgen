import json
import subprocess
from pathlib import Path

registry = Path('doctrine/live_document_size/surfaces.jsonl')
rows = [json.loads(line) for line in registry.read_text().splitlines()]

def members(patterns):
    own = sorted({str(p) for pattern in patterns for p in Path('.').glob(pattern) if p.is_file()})
    perl = subprocess.check_output(['perl', '-MFile::Glob=bsd_glob', '-MJSON::PP', '-e',
        'my $patterns=decode_json($ARGV[0]); my %seen; print encode_json([sort grep {-f $_ && !$seen{$_}++} map {bsd_glob($_)} @$patterns]);', json.dumps(patterns)])
    assert own == json.loads(perl), patterns
    return own

def dimensions(values):
    physical = [raw.split(b'\n')[:-1] if raw.endswith(b'\n') else raw.split(b'\n') for raw in values]
    physical = [lines if raw else [] for raw, lines in zip(values, physical)]
    return {'files': len(values), 'bytes_total': sum(map(len, values)),
        'bytes_each': max(map(len, values), default=0),
        'lines_total': sum(map(len, physical)), 'lines_each': max(map(len, physical), default=0),
        'line_bytes_each': max((len(line) for lines in physical for line in lines), default=0)}

measurements = {}
for row in rows:
    sid = row.get('surface_id')
    if sid not in {'root_documents', 'focused_documents', 'task_evidence', 'knowledge_cards', 'shipped_behavior', 'isf_reference', 'rationale'}:
        continue
    paths = members(row['targets'])
    current = dimensions([Path(path).read_bytes() for path in paths])
    measurements[sid] = current
    if sid in {'shipped_behavior', 'isf_reference'}:
        prior_bytes = [subprocess.check_output(['git', 'show', '518d99d288b6b1cf4fd2f8f38518d684d37740a6:' + path]) for path in paths]
        if prior_bytes == [Path(path).read_bytes() for path in paths]:
            continue
        prior = dimensions(prior_bytes)
        axes = ('files', 'bytes_total', 'lines_total')
        row['reference_contract']['aggregate_change'] = {
            'authority_id': 'PROCEDURE-COND-SAFETY-20261002-' + ('SHIPPED-BEHAVIOR' if sid == 'shipped_behavior' else 'ISF-REFERENCE'),
            'baseline': {key: prior[key] for key in axes},
            'delta': {key: current[key] - prior[key] for key in axes},
            'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.4.1',
            'rationale': 'Qualify unsafe new first-sample admission from a standalone inline-cond candidate and restore exact production. Synchronize explicit source-intent prerequisite before safe normalization, current refusal and call-site workaround in book/integration/feedback. No production, schema, routing, immutable evidence, ceiling or store-identity change.'}
        continue
    if row['baseline'] is None:
        continue
    for axis, actual in current.items():
        old = row['baseline'][axis] + row['transition']['max_growth'][axis]
        step = row['transition']['ratchet_step'][axis]
        if actual > old or old > actual + step:
            row['transition']['max_growth'][axis] = max(0, min(actual + step, row['enforcement_ceilings'][axis]) - row['baseline'][axis])
registry.write_text(''.join(json.dumps(row, sort_keys=True, separators=(',', ':')) + '\n' for row in rows))
Path('.artifacts/procedure-cond-normalization/capacity.json').write_text(json.dumps(measurements, indent=2, sort_keys=True) + '\n')
