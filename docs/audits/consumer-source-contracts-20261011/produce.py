"""Propose every exact finite assertion expression and source operand role."""
from consumer_common import *
import assertions
import contract_inputs as inputs

data = inputs.inputs()
rows = []
for context in data['consumers']:
    assertion = assertions.call(data['source'], context)
    need(len(assertion['arguments']) == (2 if context['kind'] == 'ok' else 3), 'complete source assertion arity')
    helper = None if context['helper'] is None else data['helpers'][context['helper']]
    operation = assertion['start'] if helper is None else data['source'].index(helper['source_statement'])
    begin = data['source'].rfind("subtest '", 0, operation)
    finish = data['source'].find("\nsubtest '", operation)
    if finish < 0:
        finish = data['source'].index('\ndone_testing;', operation)
    need(begin >= 0, 'own complete authored consumer dataflow subtest')
    scope = dict(start=begin, end=finish, body=data['source'][begin:finish])
    rows.append(dict(context=context, assertion=assertion, operand_role=inputs.role(context), helper=helper,
                     source_scope=scope))
save_product('candidate.json.gz', dict(**inputs.candidate_header(data), assertions=rows))
print('Built complete source assertion/operand-role proposal; native operand and outcome truth remain open.')
