"""Bind unchanged acceptance commands to the qualified conjunctive source image."""
import argparse
import gzip
import hashlib
import json

import execute
import prepare
import qualify_selected_checkout
import selected_checkout as checkout
import snapshot_intake

REVISION = '732b7d6ba0175fe2d9c83ea104c9261fa8b8e01b'
PATH = execute.AUDIT / 'selected-intake.json.gz'
SUFFIX = '.2.2.3.3.2.3.2'
HISTORICAL = frozenset({'prerequisites', 'association'})
EVIDENCE = (
    'conjunctive-epoch-constraints.json.gz',
    'conjunctive-epoch-constraints-qualified.json.gz',
    'selected-checkout-manifest.json.gz', 'selected-checkout-prepared.json.gz',
    'selected-checkout-portable-qualification-started.json.gz',
    'selected-checkout-portable-qualification-actual.json.gz',
    'selected-index-portability-inputs.json.gz',
    'prerequisites-started.json.gz', 'prerequisites-actual.json.gz',
    'corrected-prerequisites-started.json.gz', 'corrected-prerequisites-actual.json.gz',
    'snapshot-prerequisites-started.json.gz', 'snapshot-prerequisites-actual.json.gz',
)
INSTRUMENTS = ('prepare.py', 'execute.py', 'snapshot_intake.py', 'historical_checkout.py',
               'qualify_selected_checkout.py', 'selected_checkout.py', 'epoch_constraints.py')


def fixed(name):
    path = execute.AUDIT / name
    body = execute.read(path)
    assert body == execute.command(['git', '--no-replace-objects', 'show', REVISION + ':' + str(path)])
    return body


def captured_instrument(name):
    """Read historical instrument data; never authorize its current execution."""
    assert name in INSTRUMENTS, 'closed captured instrument population'
    path = str(execute.AUDIT / name)
    entry = execute.command(['git', '--no-replace-objects', 'ls-tree', '--full-tree', '-l', '-z', REVISION, '--', path])
    assert entry.count(b'\0') == 1, 'one native captured instrument'
    header, member = entry[:-1].split(b'\t')
    mode, kind, oid, size = header.decode().split()
    assert mode == '100644' and kind == 'blob' and member.decode() == path
    body = execute.command(['git', '--no-replace-objects', 'show', REVISION + ':' + path])
    assert size.isdecimal() and len(body) == int(size)
    assert body == execute.command(['git', '--no-replace-objects', 'cat-file', 'blob', oid])
    assert hashlib.sha1(b'blob ' + str(len(body)).encode() + b'\0' + body).hexdigest() == oid
    return body


def exact(value, reference):
    assert type(value) is type(reference), 'exact selected intake primitive kind'
    if isinstance(reference, dict):
        assert value.keys() == reference.keys(), 'complete selected intake fields'
        for name in reference:
            exact(value[name], reference[name])
    elif isinstance(reference, list):
        assert len(value) == len(reference), 'complete selected intake array'
        for actual, expected in zip(value, reference):
            exact(actual, expected)
    else:
        assert value == reference, 'exact selected intake value'


def base_inventory():
    return snapshot_intake.base_inventory()


def profile(*, captured=False):
    assert type(captured) is bool, 'explicit captured instrument role'
    body, inventory = base_inventory()
    instrument = captured_instrument if captured else fixed
    instruments = {name: prepare.identity(instrument(name)) for name in INSTRUMENTS}
    evidence = {name: fixed(name) for name in EVIDENCE}
    qualification = json.loads(gzip.decompress(evidence['selected-checkout-portable-qualification-actual.json.gz']))
    started = json.loads(gzip.decompress(evidence['selected-checkout-portable-qualification-started.json.gz']))
    assert all(qualification[key] == value for key, value in started.items())
    assert qualification['source_after'] == dict(value=started['source_before'], error=None)
    assert qualification['tools_after'] == dict(value=started['tools_before'], error=None)
    assert qualification['primary_after']['error'] is None
    assert all(qualification['primary_after']['value'][key] == started['primary_before'][key]
               for key in ('head', 'entries'))
    assert len(qualification['results']) == len(qualify_selected_checkout.COMMANDS)
    for actual, (label, command, stdout) in zip(qualification['results'], qualify_selected_checkout.COMMANDS, strict=True):
        assert actual['label'] == label and actual['command'] == command
        assert type(actual['status']) is int and actual['status'] == 0
        assert prepare.unblob(actual['stdout']) == stdout
        stderr = prepare.unblob(actual['stderr'])
        assert stderr.startswith(b'ram-guard: PID ') and b'ram-guard: terminating PID tree' not in stderr
    for name in ('prerequisites-actual.json.gz', 'corrected-prerequisites-actual.json.gz',
                 'snapshot-prerequisites-actual.json.gz'):
        failed = json.loads(gzip.decompress(evidence[name]))
        assert type(failed['status']) is int and failed['status'] == 1, 'all three spent intakes stay failed'
    assert json.loads(gzip.decompress(evidence['selected-checkout-manifest.json.gz'])) == checkout.manifest()
    return dict(schema='fsmgen.original_selected_checkout_intake.v4',
                owner=inventory['acceptance'] + SUFFIX,
                original_inventory=prepare.identity(body),
                evidence_revision=REVISION,
                instruments=instruments,
                evidence={name: prepare.identity(value) for name, value in evidence.items()},
                snapshot_revision=checkout.constraints.REVISION,
                historical_cohorts=sorted(HISTORICAL),
                working_directories={label: str(checkout.FOLDER) if label in HISTORICAL else '.'
                                     for label in inventory['cohorts']},
                commands={label: row['command'] for label, row in inventory['cohorts'].items()},
                scope='Complete unchanged original commands/contracts. Historical saved readers use the '
                      'conjunctively selected whole physical source; current publication/tests/book use primary '
                      'source. Complete physical source/logical index and declared empty locality namespaces '
                      'qualify before and after each historical cohort. Every spent/unused old intake, original '
                      'source-model/shared/native/private limit and independent gate retains. No semantic execution.')


def validate(value, *, captured=False):
    exact(value, profile(captured=captured))
    return True


def effective(value):
    assert validate(value)
    return base_inventory()[1]


def cwd(label, value, *, captured=False):
    assert validate(value, captured=captured) and label in value['commands']
    return value['working_directories'][label]


def observe_snapshot():
    value = checkout.verify()
    expected = json.loads(gzip.decompress(fixed('selected-checkout-prepared.json.gz')))
    assert checkout.matches_prepared(value, expected)
    return value


def validate_observation(label, value, specification, *, captured=False):
    assert label in HISTORICAL and validate(specification, captured=captured)
    expected = json.loads(gzip.decompress(fixed('selected-checkout-prepared.json.gz')))
    assert checkout.matches_prepared(value, expected)
    return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--current', action='store_true', help='require unchanged live instrument bytes')
    args = parser.parse_args()
    value = profile() if args.write else json.loads(gzip.decompress(execute.read(PATH)))
    assert validate(value, captured=not (args.write or args.current))
    if args.write:
        execute.save(PATH, value)
    print('Closed selected-checkout intake preserves all original commands/contracts and three failed intakes; no semantic reader executes.')
