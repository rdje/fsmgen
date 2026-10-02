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
        prior_bytes = [subprocess.check_output(['git', 'show', '9bf0bd4c8af8c8aab5ab6865e66f6729d9583b3c:' + path]) for path in paths]
        if prior_bytes == [Path(path).read_bytes() for path in paths]:
            continue
        prior = dimensions(prior_bytes)
        axes = ('files', 'bytes_total', 'lines_total')
        row['reference_contract']['aggregate_change'] = {
            'authority_id': 'CONDITIONAL-MACRO-INTENT-20261002-' + ('SHIPPED-BEHAVIOR' if sid == 'shipped_behavior' else 'ISF-REFERENCE'),
            'baseline': {key: prior[key] for key in axes},
            'delta': {key: current[key] - prior[key] for key in axes},
            'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.1',
            'rationale': 'Qualify actual existing ISF/IAL1 conditional macro placement and inline procedure cond normalization boundaries with complete actual source/products/phase evidence. Synchronize entry versus branch, source-intent and local-call execution limitations in book/integration/feedback. No production, schema, output routing, immutable evidence, ceiling or store-identity change.'}
        continue
    if row['baseline'] is None:
        continue
    for axis, actual in current.items():
        old = row['baseline'][axis] + row['transition']['max_growth'][axis]
        step = row['transition']['ratchet_step'][axis]
        if actual > old or old > actual + step:
            row['transition']['max_growth'][axis] = max(0, min(actual + step, row['enforcement_ceilings'][axis]) - row['baseline'][axis])
registry.write_text(''.join(json.dumps(row, sort_keys=True, separators=(',', ':')) + '\n' for row in rows))
Path('.artifacts/conditional-macro-intent/capacity.json').write_text(json.dumps(measurements, indent=2, sort_keys=True) + '\n')
