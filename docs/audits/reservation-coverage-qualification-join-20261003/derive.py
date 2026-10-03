"""Derive the complete initial/current copy-to-cohort handoff, without semantics."""
import argparse
import json
from pathlib import Path

BASE = Path('docs/audits/reservation-coverage-qualification-join-20261003')
parser = argparse.ArgumentParser()
parser.add_argument('--write', action='store_true')
options = parser.parse_args()
binding = json.loads((BASE / 'bindings.json').read_text())
ordinary = json.loads(Path('docs/audits/reservation-coverage-snapshot-capture-20261003/ordinary.json').read_text())
initial = json.loads(Path('docs/audits/reservation-coverage-helper-causes-20261003/initial-observations-unqualified.json').read_text())
prefix = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.2.4.3'
owners = {site: prefix + suffix for suffix, sites in (
    ('.2', ('authored_actor', 'physical_actor')),
    ('.3', ('captured_module',)),
    ('.4', ('success_snapshot', 'refusal_snapshot', 'unexpected_module_seed', 'module_mutation_seed', 'allocation_mutation_seed')),
) for site in sites}
literals = {
    "    my $actor = ref($source) eq 'HASH' ? dclone($source)": 'authored_actor',
    '    my $physical = dclone($p->{actor});': 'physical_actor',
    '            $modules{$ir->{actor_name}} = dclone($ir);': 'captured_module',
    '    my $before = dclone([$p, $plan, \\%modules]);': 'success_snapshot',
    '    my $before = dclone([$p, $allocation, $actual]);': 'refusal_snapshot',
    '        [sub {$_[0]{extra} = dclone($_[0]{coverage})},': 'unexpected_module_seed',
    r"        [sub {$_[0]{extra} = dclone($_[0]{coverage})}, qr/incomplete parent\/domain modules/, 'unexpected module'],": 'unexpected_module_seed',
    '        my $actual = dclone($modules); $case->[0]->($actual);': 'module_mutation_seed',
    '    my $bad_plan = dclone($plan); $bad_plan->{formals}{main}{payload}{physical_name} = \'isf_port_main_payload\';': 'allocation_mutation_seed',
}
sites = {label: {str(i): literals[line] for i, line in enumerate(row['body'].splitlines(), 1) if line in literals}
    for label, row in binding['sources'].items()}
assert all(len(mapping) == 8 for mapping in sites.values())


def delta(a, b, path=''):
    if type(a) is not type(b): return [[path, type(a).__name__, type(b).__name__, a, b]]
    if isinstance(a, dict):
        assert a.keys() == b.keys(), path
        return [d for k in sorted(a) for d in delta(a[k], b[k], path + '/' + k)]
    if isinstance(a, list):
        assert len(a) == len(b), path
        return [d for i, (x, y) in enumerate(zip(a, b)) for d in delta(x, y, path + '/' + str(i))]
    assert a == b, path
    return []


rows = []
assert len(initial['clones']) == len(ordinary['copies']) == 62
for ordinal, (old, now) in enumerate(zip(initial['clones'], ordinary['copies'])):
    site = sites['initial'][str(old['line'])]
    assert sites['current'][str(now['line'])] == now['site'] == site
    assert delta(old['before'], now['before']) == delta(old['clone'], now['copy']) == delta(old['after'], now['after']) == []
    rows.append(dict(ordinal=ordinal, site=site, initial_line=old['line'], current_line=now['line'], owner=owners[site], differences=delta(now['before'], now['copy'])))
text = json.dumps(dict(sites=sites, copies=rows),indent=2,sort_keys=True)+'\n'
if options.write: (BASE / 'handoff.json').write_text(text)
else: assert (BASE / 'handoff.json').read_text() == text
print('PASS complete initial/current copy-site and typed-difference handoff derived; semantic owners are independently qualified by the cold join reader.')
