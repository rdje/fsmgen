"""Propose the complete original assertion-to-meaning join from whole child products."""
from join_common import *
import join_inputs as inputs

if __name__ == '__main__':
    data = inputs.inputs()
    result = inputs.header(data)
    modes = []
    for mi, mode in enumerate(inputs.MODES):
        consumers = []
        for index, assertion in enumerate(data['prepared']['assertions']):
            role = 'remaining' if assertion['context']['helper'] is None else 'helper'
            child = data['children'][role]['modes'][mi]['consumers'][index]
            need(child['meaning'] is not None and same(child['source_context'], assertion['context']),
                 'whole proposed own child meaning source allocation')
            consumers.append(dict(index=index, source_contract=assertion, role=role,
                native=data['native'][mode][index], meaning=child['meaning'], outcome=child['meaning']['outcome']))
        modes.append(dict(mode=mode, consumers=consumers))
    result['modes'] = modes
    save_product('candidate.json.gz', result)
    print('PASS proposed complete original source/meaning/typed operand/truth join; independent admission required.')
