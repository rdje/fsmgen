"""Closed successor intake; the first inventory and failed attempt stay immutable."""
import argparse
import copy
import gzip
import json

import execute
import historical_factory
import prepare

PATH = execute.AUDIT / 'corrected-intake.json.gz'
WRAPPER = str(execute.AUDIT / 'replay_historical.py')


def inventory():
    body = execute.read(execute.AUDIT / 'inventory.json.gz')
    committed = execute.command(['git', '--no-replace-objects', 'show',
                                 'c40d67863302eebcfd1e1ff23fdd78abbc75d02b:' + str(execute.AUDIT / 'inventory.json.gz')])
    assert body == committed, 'complete unchanged first intake'
    base = json.loads(gzip.decompress(body))
    assert prepare.validate(base)
    row = copy.deepcopy(base)
    row['schema'] = 'fsmgen.original_parent_corrected_inventory.v2'
    row['owner'] = row['acceptance'] + '.2.2.2.3'
    row['original_inventory'] = prepare.blob(body)
    image = historical_factory.inventory()
    row['historical_source_image'] = image
    for label in historical_factory.ROLES:
        cohort = row['cohorts'][label]
        cohort['original_command'] = cohort['command']
        cohort['command'] = ['python3', '-B', WRAPPER, label]
        cohort['source_role'] = 'Exact declared historical factory input; original default reader and every guard retained.'
    row['scope'] += (' Historical prerequisite/association readers use the complete committed historical source image. '
                     'All other commands and current publication obligations remain unchanged. '
                     'No failed first result or original native/private role is promoted.')
    return row


def validate(row):
    assert row == inventory(), 'complete closed corrected source/command/contract intake'
    assert all(type(value) is bool for value in row['limits'].values())
    return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    row = inventory() if args.write else json.loads(gzip.decompress(execute.read(PATH)))
    assert validate(row)
    if args.write:
        execute.save(PATH, row)
    print('Closed corrected intake preserves all original obligations; no acceptance cohort executes.')
