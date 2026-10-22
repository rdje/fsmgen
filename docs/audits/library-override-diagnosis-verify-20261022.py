#!/usr/bin/env python3
"""Verify retained first-touch shape/kind evidence; never execute a source probe."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import subprocess

PATH = 'docs/audits/library-override-diagnosis-20261022.json.gz'


def require(ok, message):
    if not ok:
        raise ValueError(message)


def validate(record):
    require(record['result'] == 'diagnosis qualified; production fix and private retention unqualified', 'scope changed')
    require(set(record['cases']) == {'parameter', 'literal', 'package', 'enum', 'enum_literal', 'nested'}, 'case membership')
    for data in record['inputs'].values():
        require(hashlib.sha256(data['text'].encode()).hexdigest() == data['sha256'], 'input identity')
    adapter = 'perl/FSM/Adapter/ISF/LispishAdapter.pm'
    require(subprocess.check_output(['git', 'show', record['baseline_revision'] + ':' + adapter]).decode()
            == record['inputs'][adapter]['text'], 'owned adapter differs from baseline Git')
    expected = {'parameter': '16', 'literal': '16', 'package': 16, 'enum': 1, 'enum_literal': '1'}
    for name, row in record['cases'].items():
        require(row['exit'] == 0, 'probe refused')
        data = json.loads(row['stdout']['text'])
        require(data['caller_unchanged'] is True, 'caller changed')
        require(data['minimal_source'] == '(params (TREE ((1 2) (3 4))))\n', 'minimal source changed')
        require(data['raw'] == [['params', [['TREE', [[['1', ['2']], [['3', ['4']]]]]]]]],
                'observed public raw shape changed')
        require(data['normalized'] == [['params', ['TREE', [['1', ['2']], ['3', '4']]]]], 'wrong original shape')
        require(data['head_recursion_counterfactual'] == [['params', ['TREE', [['1', '2'], ['3', '4']]]]],
                'counterfactual does not recover literal shape')
        if name != 'nested':
            value = data['actor']['uses'][0]['parameter_overrides'][0]['value']
            require(type(value) is type(expected[name]) and value == expected[name], 'first-touch primitive kind/value')
        else:
            for key in ('uses', 'library_uses'):
                before = data['actor'][key][0]['_parameter_override_sources'][0]['value']
                after = data['counterfactual_actor'][key][0]['_parameter_override_sources'][0]['value']
                require(before == [['LIMIT', ['ALIAS']], ['shared.LIMIT', '16']], 'actual wrong source shape')
                require(after == [['LIMIT', 'ALIAS'], ['shared.LIMIT', '16']], 'corrected source shape')


record = json.loads(gzip.decompress(Path(PATH).read_bytes()))
validate(record)
for mutation in ('raw-shape', 'original-shape', 'counterfactual-shape', 'primitive', 'caller', 'membership'):
    bad = copy.deepcopy(record)
    row = bad['cases']['package']['stdout']
    value = json.loads(row['text'])
    if mutation == 'raw-shape':
        value['raw'] = []
    elif mutation == 'original-shape':
        value['normalized'] = value['head_recursion_counterfactual']
    elif mutation == 'counterfactual-shape':
        value['head_recursion_counterfactual'] = value['normalized']
    elif mutation == 'primitive':
        value['actor']['uses'][0]['parameter_overrides'][0]['value'] = '16'
    elif mutation == 'caller':
        value['caller_unchanged'] = False
    else:
        del bad['cases']['nested']
    row['text'] = json.dumps(value)
    try:
        validate(bad)
    except (ValueError, KeyError):
        continue
    raise ValueError('hostile saved control accepted: ' + mutation)
print('library-override diagnosis: PASS; shape/kind/scope controls rejected')
