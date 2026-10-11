"""Propose helper operands/truth from the qualified cause association, not flags."""
import re
from helper_common import *
import helper_inputs as inputs


def proposed(prepared, helper, cause, first_source):
    kind = prepared['context']['kind']
    primary = cause['primary']
    need(type(primary) is str and primary and primary.isascii() and '\n' not in primary,
         'source-derived whole helper first diagnostic line')
    if kind == 'ok':
        need([arg['body'] for arg in prepared['assertion']['arguments']] == ['!$ok', '"$name refuses"'],
             'exact helper source negated eval assertion')
        operand, truth, rule = dict(actual=1), 1, 'observer_projected_negated_eval'
    else:
        need(kind == 'like' and [arg['body'] for arg in prepared['assertion']['arguments']] ==
             ['$diagnostic', '$pattern', '"$name names the cause in its diagnostic line"'],
             'exact helper source first-line regex assertion')
        pattern = helper['pattern']
        need(pattern.startswith('(?^:') and pattern.endswith(')'), 'qualified original source regex display')
        operand = dict(actual=primary, expected=pattern)
        truth, rule = int(re.search(pattern[4:-1], primary) is not None), 'ascii_first_line_regex_search'
    return dict(source_assertion=prepared, source_helper=helper, first_record=cause['first_record'],
        first_source=first_source, primary=primary, operand=operand, outcome=truth, comparison=rule)


if __name__ == '__main__':
    data = inputs.inputs()
    modes = []
    for mi, mode in enumerate(inputs.MODES):
        association = data['association']['modes'][mi]
        need(association['mode'] == mode, 'own qualified cause source mode')
        rows = []
        for index, prepared in enumerate(data['prepared']['assertions']):
            context = prepared['context']
            meaning = None
            if context['helper'] is not None:
                cause = association['helpers'][context['helper']]
                _, domain, record = cause['first_record']
                source = association['domains'][domain]['records'][record]['source']
                if domain == 'parses':
                    source = dict(context=source, primary=cause['primary'])
                meaning = proposed(prepared, cause['source'], cause, source)
            rows.append(dict(index=index, source_context=context, native=data['native'][mode][index], meaning=meaning))
        modes.append(dict(mode=mode, consumers=rows))
    save_product('candidate.json.gz', dict(**inputs.header(data), modes=modes))
    print('Built all original consumer observations with source-derived refusal-helper operands/truth; nonhelper truth retains.')
