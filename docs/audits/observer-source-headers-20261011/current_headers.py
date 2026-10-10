"""Evaluate only fully known conditional headers; preserve every unresolved source slot."""
from common import BASE, SCOPE, load, need, save


def evaluate(product):
    result=[]
    table=product['current_construction_cases']
    for header in product['headers']:
        form=header['current_conditional_form'];tokens=[];unresolved=[]
        for slot in form['slots']:
            spellings=[]
            for identifier in slot['cases']:
                evidence=table[identifier]
                token=(evidence['case']['display_token'] if evidence['kind']=='predicate'
                       else evidence['case']['display']['token'])
                if token not in spellings:
                    spellings.append(token)
            if slot['unresolved_reference_token'] or len(spellings)!=1:
                unresolved.append(dict(argument_id=slot['argument_id'],qualified_current_alternatives=spellings,
                    reference_token_unmeasured=slot['unresolved_reference_token']))
            else:
                tokens.append(spellings[0])
        marker=header['expression']['kind']=='block_eval_source_marker'
        known=None
        if not unresolved and not marker:
            if form['remaining_arguments']:
                tokens.append('...')
            known=header['expression']['function']+'('+', '.join(tokens)+')'
        result.append(dict(header_id=header['id'],path=header['path'],profile=form['profile'],
            known_conditional_header=known,unresolved_slots=unresolved,source_eval_marker=marker,
            complete_source_argument_ids=header['source_argument_ids'],hidden_argument_ids=form['hidden_argument_ids'],
            meaning='Source-selected conditional public-grammar hypothesis only; unresolved slots are typed evidence boundaries and supply no encoded token or wildcard matcher.'))
    return dict(scope=SCOPE,headers=result,
        role='Generated known conditional header text and complete unresolved slot allocation only; no original or new native-header capture/comparison.')


if __name__=='__main__':
    need(not (BASE/'original-raw-intake.json').exists(),'known conditional headers before own original raw intake')
    save('current-headers.json',evaluate(load('headers.json')))
    print('PASS every fully known conditional header and complete unresolved/hidden argument allocation; original profile/native/private boundaries remain unmeasured.')
