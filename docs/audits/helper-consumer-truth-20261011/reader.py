"""Derive own helper operands from source causes and evaluate flags independently."""
import argparse
from helper_common import *
import comparison
import helper_inputs as inputs

SUCCESS = 'PASS independent complete original refusal-helper consumer operands/truth; all nonhelper and higher scopes retain.\n'


def source_models(data):
    primary = inputs.module(inputs.PRIMARY + '/verify.py')
    models, parser_causes, helpers, products = primary['models']()
    source, contexts, consumers, source_products = primary['context']['source_models']()
    need(source == data['source'] and same(helpers, contexts), 'whole original source helper and consumer contexts')
    prepared = data['prepared']['assertions']
    need(same([row['context'] for row in prepared], consumers), 'complete committed assertion/context source allocation')
    result = {}
    for mi, mode in enumerate(inputs.MODES):
        meanings = {}
        for helper in helpers:
            failed = [row for row in models[mode] if row['index'] in helper['api_members'] and row['primary'] is not None]
            parsed = [index for index in helper['parse_members'] if parser_causes[index] is not None]
            need(bool(failed) != bool(parsed), 'source helper has one first failed API or parser family')
            if failed:
                first = sorted(failed, key=lambda row: row['index'])[0]
                record, first_source, message = [mode, 'api', first['index']], first, first['primary']
            else:
                index = min(parsed)
                record, message = [mode, 'parses', index], parser_causes[index]
                first_source = dict(context=data['contexts'][mi]['parsers'][index], primary=message)
            need(type(message) is str and message and message.isascii() and '\n' not in message,
                 'whole source-derived helper first diagnostic scalar')
            for index in helper['consumer_members']:
                assertion = prepared[index]
                context = assertion['context']
                need(context['helper'] == helper['index'] and same(assertion['helper'], helper),
                     'own complete prepared helper assertion contract')
                args = [row['body'] for row in assertion['assertion']['arguments']]
                if context['kind'] == 'ok':
                    need(args == ['!$ok', '"$name refuses"'], 'whole source negated eval helper assertion')
                    operand, truth, rule = dict(actual=int(bool(message))), int(bool(message)), 'observer_projected_negated_eval'
                else:
                    need(context['kind'] == 'like' and args ==
                         ['$diagnostic', '$pattern', '"$name names the cause in its diagnostic line"'],
                         'whole source first diagnostic line and helper regex assertion')
                    operand = dict(actual=message, expected=helper['pattern'])
                    truth = int(comparison.regex_search(helper['pattern'], message))
                    rule = 'ascii_first_line_regex_search'
                need(index not in meanings, 'unique own source helper assertion membership')
                meanings[index] = dict(source_assertion=assertion, source_helper=helper, first_record=record,
                    first_source=first_source, primary=message, operand=operand, outcome=truth, comparison=rule)
        result[mode] = meanings
    return result


def check(candidate):
    data = inputs.inputs()
    header = inputs.header(data)
    need(type(candidate) is dict and set(candidate) == set(header) | {'modes'}
         and type(candidate['schema_version']) is int, 'closed whole helper consumer meaning schema')
    need(same({key: candidate[key] for key in header}, header), 'complete original helper source/native/product/contract boundary custody')
    need(type(candidate['modes']) is list and len(candidate['modes']) == len(inputs.MODES), 'complete original helper consumer mode domain')
    expected = source_models(data)
    allocations = []
    for mode_row, mode in zip(candidate['modes'], inputs.MODES, strict=True):
        need(set(mode_row) == {'mode', 'consumers'} and mode_row['mode'] == mode
             and type(mode_row['consumers']) is list and len(mode_row['consumers']) == 125,
             'complete original consumer population including nonhelper observations')
        covered, opaque = [], []
        for index, (row, native) in enumerate(zip(mode_row['consumers'], data['native'][mode], strict=True)):
            context = data['prepared']['assertions'][index]['context']
            need(set(row) == {'index', 'source_context', 'native', 'meaning'} and type(row['index']) is int
                 and row['index'] == index and same(row['source_context'], context),
                 'whole own helper consumer source expression/context allocation')
            if context['helper'] is None:
                need(row['meaning'] is None and same(row['native'], native), 'whole nonhelper observation retains without truth promotion')
                opaque.append(index)
                continue
            # Calculate the assertion on its operands before authenticating the
            # observed flag or original body. A forced green flag must fail here.
            truth = comparison.observed(row['native'])
            source = expected[mode][index]
            need(same(row['meaning'], source), 'whole independently derived own helper source operands and outcome')
            need(same({key: row['native'][key] for key in source['operand']}, source['operand'])
                 and type(source['outcome']) is int and truth == source['outcome'],
                 'whole source-derived helper consumer operand and truth')
            need(same(row['native'], native), 'whole original helper consumer native observation custody')
            covered.append(index)
        need(set(covered) == set(expected[mode]) and len(covered) == 86 and len(opaque) == 39,
             'complete covered helper and separately open nonhelper domain')
        allocations.append(dict(mode=mode, covered=covered, nonhelper_observations=opaque,
            whole_native=pin(canonical(data['native'][mode])), meanings=pin(canonical(expected[mode]))))
    return dict(owner=PLAN['owner'], revision=PLAN['revision'], candidate=pin(canonical(candidate)),
        inputs=data['identities'], source_roles=data['source_roles'], allocations=allocations,
        boundary=PLAN['condition'],
        assumptions='Qualified original source/context/API/parser/cause model algorithms are shared prerequisites. New helper operand and comparison reconstruction uses no native passed flag as authority; all nonhelper observations and original native/private limits retain.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--candidate', default='candidate.json.gz')
    parser.add_argument('--save', action='store_true')
    args = parser.parse_args()
    need(Path(args.candidate).name == args.candidate and args.candidate.endswith('.json.gz'), 'ordinary own helper-consumer candidate route')
    result = check(load_product(args.candidate))
    if args.save:
        need(args.candidate == 'candidate.json.gz', 'only positive helper-consumer admission publishes')
        save('qualification.json', result)
    print(SUCCESS, end='')
