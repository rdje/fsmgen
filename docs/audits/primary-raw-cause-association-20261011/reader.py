"""Independently rederive source causes and join whole qualified original records."""
import argparse

from cause_common import *

SUCCESS = 'PASS independent complete original primary/raw cause association; every prior scope and native/private unknown retains.\n'


def check(candidate):
    data, identities = inputs()
    primary = module(Path(PLAN['primary']) / 'verify.py')
    models, parser_causes, helpers, products = primary['models']()
    records = {mode: data[mode] for mode in MODES}
    derived = primary['check'](records, models, parser_causes, helpers)
    need(same(derived, data['primary']['proofs']), 'complete independently rederived original primary and acceptance proof')
    context = primary['context']
    source, source_helpers, consumers, source_products = context['source_models']()
    contexts = context['check'](records, data['execution'], source, source_helpers, consumers, source_products)
    need(same(contexts, data['contexts']['proofs']), 'complete independently rederived original source contexts')
    need(set(candidate) == {'schema_version', 'owner', 'revision', 'inputs', 'boundary', 'modes'}
         and type(candidate['schema_version']) is int and candidate['schema_version'] == 1
         and candidate['owner'] == PLAN['owner'] and candidate['revision'] == PLAN['revision'], 'closed owned cause product schema')
    need(same(candidate['inputs'], identities), 'whole original qualified cause input custody')
    need(same(candidate['boundary'], boundary(data)), 'whole inherited native and scope boundary')
    need([mode['mode'] for mode in candidate['modes']] == list(MODES), 'complete ordered original mode allocation')
    inventories = {mode['mode']: mode['domains'] for mode in data['raw']['inventories']}
    raw_rows = {(mode['mode'], domain, record['index']): record
                for mode in data['raw']['inventories'] for domain, group in mode['domains'].items()
                for record in group['nonempty']}
    links = {tuple(row['record']): row for row in data['semantic']['semantic_links']['records']}
    inherited = {tuple(row['record']): row for mode in data['semantic']['modes']
                 for domain in mode['domains'].values() for row in domain['records']}
    need(len(links) == len(data['semantic']['semantic_links']['records'])
         and links.keys() == raw_rows.keys() == inherited.keys(), 'complete unique qualified raw semantic membership')
    used, totals = set(), []
    for mi, mode in enumerate(MODES):
        actual_mode, native = candidate['modes'][mi], data[mode]
        need(set(actual_mode) == {'mode', 'domains', 'helpers'} and set(actual_mode['domains']) == set(DOMAINS),
             'complete closed source cause domains')
        counts = {}
        for domain in DOMAINS:
            group = actual_mode['domains'][domain]
            native_rows = native[domain] if domain != 'test_run' else [native['test_run']]
            original = inventories[mode][domain]
            empty = [index for index, row in enumerate(native_rows) if row['error'] == '']
            nonempty = [index for index, row in enumerate(native_rows) if row['error'] != '']
            empty_set = set(empty)
            need(set(group) == {'population', 'empty', 'nonempty', 'records'}
                 and type(group['population']) is int and group['population'] == len(native_rows) == original['population']
                 and same(group['empty'], empty) and same(empty, original['empty_string_members'])
                 and same(group['nonempty'], nonempty) and same(nonempty, [row['index'] for row in original['nonempty']])
                 and same([row['record'] for row in group['records']], [[mode, domain, i] for i in range(len(native_rows))]),
                 'whole ordered nonempty and empty operation allocation')
            for index, (row, observation) in enumerate(zip(group['records'], native_rows, strict=True)):
                key = mode, domain, index
                need(set(row) == {'record', 'source', 'primary', 'observed_primary', 'status', 'native', 'product', 'raw', 'semantic'},
                     'closed complete cause association row')
                expected_source = (models[mode][index] if domain == 'api' else contexts[mi]['parsers'][index] if domain == 'parses' else None)
                message = (models[mode][index]['primary'] if domain == 'api' else parser_causes[index] if domain == 'parses' else None)
                need(same(row['source'], expected_source), 'whole own source argument/helper/parser/caller association')
                need(same(row['primary'], message) and same(row['observed_primary'], observation.get('primary'))
                     and (observation['error'].splitlines()[0] if observation['error'] else None) == message,
                     'whole independently derived own first cause')
                field = 'completed' if domain == 'test_run' else 'accepted'
                authority = 'source_first_cause' if domain in ('api', 'parses') else 'qualified_prior_observation'
                need(same(row['status'], dict(field=field, value=observation[field], authority=authority))
                     and type(row['status']['value']) is int
                     and (authority != 'source_first_cause' or row['status']['value'] == int(message is None)),
                     'typed own source-derived acceptance or retained observation')
                need(same(row['native'], pin(canonical(observation)))
                     and same(row['product'], pin(canonical(observation.get('result')))), 'whole own original native and product association')
                if index in empty_set:
                    need(row['raw'] is None and row['semantic'] is None and key not in raw_rows,
                         'complete empty error has no borrowed raw or semantic member')
                    continue
                used.add(key)
                raw, link, old = raw_rows[key], links[key], inherited[key]
                need(same(row['raw'], raw) and same(old['original'], raw)
                     and raw['body'] == observation['error'] and raw['body_identity'] == pin(observation['error'].encode())
                     and raw['body'].encode() == b''.join(segment['raw'].encode() for segment in raw['segments'])
                     and same(raw['context'], {name: observation[name] for name in ('kind', 'caller', 'helper', 'parse') if name in observation}),
                     'whole own raw body context segments and address lexemes')
                proposed = row['semantic']
                need(isinstance(proposed, dict) and same(proposed['record'], list(key))
                     and proposed['first_cause']['domain'] == domain and type(proposed['first_cause']['index']) is int
                     and proposed['first_cause']['index'] == index and proposed['first_cause']['primary'] == message
                     and same(proposed['context'], raw['context']) and proposed['stack']['body'] == raw['body_identity'],
                     'whole own semantic record cause and raw context')
                forwarding = proposed['forwarding']
                if link['forwarding'] is not None:
                    inner = tuple(link['forwarding']['inner_record'])
                    child = records[inner[0]][inner[1]][inner[2]]
                    relation = link['forwarding']['source_relation']
                    prefix = link['phases'][-1]['classification']['guard_source']['prefix'] + relation['context'] + ' has invalid resolved type: ' + child['error'] + '\n'
                    need(isinstance(forwarding, dict) and same(forwarding, link['forwarding'])
                         and inner[0] == mode and inner[1] == 'api' and same(forwarding['outer_record'], list(key))
                         and forwarding['whole_inner_body'] == child['error'] and raw['body'].startswith(prefix)
                         and forwarding['whole_outer_prefix'] == prefix and relation['inner_body'] == pin(child['error'].encode())
                         and relation['entire_outer_prefix'] == pin(prefix.encode())
                         and forwarding['whole_new_outer_trace'] == raw['body'][len(prefix):]
                         and relation['new_outer_trace'] == pin(raw['body'][len(prefix):].encode()),
                         'whole nested own inner operand outer prefix and new trace')
                else:
                    need(forwarding is None, 'absent nested cause cannot borrow forwarding')
                need(same(proposed, link), 'whole qualified ordered class frame coordinate address and opaque role join')
            counts[domain] = dict(population=len(native_rows), empty=len(empty), nonempty=len(nonempty))
        helper_rows = actual_mode['helpers']
        need(len(helper_rows) == len(source_helpers), 'complete source helper population')
        for source_helper, row, observation in zip(source_helpers, helper_rows, native['helpers'], strict=True):
            index = source_helper['index']
            api = [i for i in source_helper['api_members'] if models[mode][i]['primary'] is not None]
            parses = [i for i in source_helper['parse_members'] if parser_causes[i] is not None]
            need(bool(api) != bool(parses), 'own helper has one failed operation family')
            domain, first = ('api', min(api)) if api else ('parses', parses[0])
            message = models[mode][first]['primary'] if api else parser_causes[first]
            need(set(row) == {'source', 'primary', 'first_record', 'failing_api_members', 'failing_parse_members', 'native'}
                 and same(row['source'], source_helper) and same(row['native'], pin(canonical(observation)))
                 and row['primary'] == message and same(row['first_record'], [mode, domain, first])
                 and same(row['failing_api_members'], api) and same(row['failing_parse_members'], parses),
                 'whole own helper source membership and first failed operation')
            need(index == helper_rows.index(row), 'ordered source helper allocation')
        totals.append(dict(mode=mode, domains=counts, helpers=len(helper_rows)))
    need(used == set(raw_rows), 'every complete original raw semantic cause is consumed exactly once')
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], product=pin(canonical(candidate)), inputs=identities,
                allocation=totals, complete_primary=pin(canonical(derived)), complete_contexts=pin(canonical(contexts)),
                boundary=boundary(data))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', type=Path, default=BASE / 'candidate.json.gz')
    parser.add_argument('--save', action='store_true')
    args = parser.parse_args()
    need(args.candidate.parent == BASE and not args.candidate.is_symlink(), 'ordinary own complete association candidate')
    result = check(product(args.candidate))
    if args.save:
        need(args.candidate == BASE / 'candidate.json.gz', 'only positive native qualification may publish')
        save('association.json', result)
    print(SUCCESS, end='')
