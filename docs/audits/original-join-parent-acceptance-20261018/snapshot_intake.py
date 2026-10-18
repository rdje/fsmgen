"""Bind unchanged commands to whole historical or primary source namespaces."""
import argparse
import gzip
import json
from pathlib import Path

import execute
import historical_checkout as checkout
import prepare

REVISION = '340c5b5a4ad01296f48f9b72dd02a560fd5fd7f8'
PATH = execute.AUDIT / 'snapshot-intake.json.gz'
HISTORICAL = {'prerequisites', 'association'}
EVIDENCE = ('historical-checkout-manifest.json.gz', 'historical-checkout-prepared.json.gz',
            'historical-checkout-native.json.gz', 'historical-checkout-started.json.gz',
            'historical-checkout-preparer-source.json.gz',
            'historical-checkout-qualification-started.json.gz', 'historical-checkout-qualification-actual.json.gz',
            'historical-checkout-contract-correspondence.json.gz',
            'prerequisites-started.json.gz', 'prerequisites-actual.json.gz',
            'corrected-prerequisites-started.json.gz', 'corrected-prerequisites-actual.json.gz',
            'corrected-prerequisites-source-view.json.gz')


def fixed(name):
    path = execute.AUDIT / name
    body = execute.read(path)
    assert body == execute.command(['git', '--no-replace-objects', 'show', REVISION + ':' + str(path)])
    return body


def base_inventory():
    body = execute.read(execute.AUDIT / 'inventory.json.gz')
    assert body == execute.command(['git', '--no-replace-objects', 'show',
                                   'c40d67863302eebcfd1e1ff23fdd78abbc75d02b:' + str(execute.AUDIT / 'inventory.json.gz')])
    inventory = json.loads(gzip.decompress(body))
    assert prepare.validate(inventory)
    return body, inventory


def profile():
    body, inventory = base_inventory()
    evidence = {name: fixed(name) for name in EVIDENCE}
    qualification = json.loads(gzip.decompress(evidence['historical-checkout-qualification-actual.json.gz']))
    assert type(qualification['status']) is int and qualification['status'] == 0
    assert qualification['source_after'] == dict(value=qualification['source_before'], error=None)
    assert qualification['tools_after'] == dict(value=qualification['tools_before'], error=None)
    for name in ('prerequisites-actual.json.gz', 'corrected-prerequisites-actual.json.gz'):
        failed = json.loads(gzip.decompress(evidence[name]))
        assert type(failed['status']) is int and failed['status'] == 1, 'both first captures remain failed'
    image = json.loads(gzip.decompress(evidence['historical-checkout-manifest.json.gz']))
    assert image == checkout.manifest()
    return dict(schema='fsmgen.original_whole_checkout_intake.v3',
                owner=inventory['acceptance'] + '.2.2.3.3.1', original_inventory=prepare.identity(body),
                evidence={name: prepare.identity(value) for name, value in evidence.items()},
                snapshot_revision=checkout.REVISION, historical_cohorts=sorted(HISTORICAL),
                working_directories={label: str(checkout.FOLDER) if label in HISTORICAL else '.'
                                     for label in inventory['cohorts']},
                commands={label: row['command'] for label, row in inventory['cohorts'].items()},
                scope='Complete unchanged original contracts and commands. Historical saved readers use the complete '
                      'fixed physical checkout; frozen/current publication, tests and book use primary source. '
                      'Both failed intakes, all original dated/native/private/source-model premises and independent gates retain.')


def validate(value):
    assert value == profile(), 'closed whole-checkout command/source/cwd/contract intake'
    return True


def effective(value):
    assert validate(value)
    return base_inventory()[1]


def cwd(label, value):
    assert validate(value) and label in value['commands']
    return value['working_directories'][label]


def observe_snapshot():
    # Every physical member and index entry is checked; raw stat-cache bytes remain observations.
    actual = checkout.verify()
    body = fixed('historical-checkout-prepared.json.gz')
    assert actual == json.loads(gzip.decompress(body))
    pointer = actual['git']['pointer'][8:].strip()
    git_directory = (execute.ROOT / checkout.FOLDER / pointer).resolve(strict=True)
    raw_index = (git_directory / 'index').read_bytes()
    assert checkout.git_state() == actual['git']
    return dict(qualified_source=prepare.identity(body), index=prepare.blob(raw_index))


def validate_observation(label, value, specification):
    assert label in HISTORICAL and validate(specification)
    assert set(value) == {'qualified_source', 'index'}
    assert value['qualified_source'] == specification['evidence']['historical-checkout-prepared.json.gz']
    import verify_execution
    assert verify_execution.unblob(value['index'])
    return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = profile() if args.write else json.loads(gzip.decompress(execute.read(PATH)))
    assert validate(value)
    if args.write:
        execute.save(PATH, value)
    print('Closed whole-checkout intake preserves original commands/contracts and separate source/cwd roles; no semantic reader executes.')
