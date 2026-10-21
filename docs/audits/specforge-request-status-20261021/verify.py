"""Check the saved SPECFORGE handoff observations without rerunning the compiler."""
import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path


AUDIT = Path(__file__).resolve().parent
ROOT = AUDIT.parents[2]
REDUCTION = AUDIT.with_name('specforge-reduction-intake-20261021')
BASE = '15a9dceec64f26ba514102abbaf80bd9b367a7c4'
REFUSED = {'duration-units', 'frequency-declaration', 'named-timers'}
CASES = {
    'duration-baseline': 'specforge-duration-intake-20260930/baseline-good.isf',
    'duration-units': 'specforge-duration-intake-20260930/wait-in-ms.isf',
    'frequency-declaration': 'specforge-duration-intake-20260930/clock-frequency.isf',
    'timer-baseline': 'specforge-timer-intake-20260930/baseline-good.isf',
    'named-timers': 'specforge-timer-intake-20260930/named-timers.isf',
    'reset-omitted': 'specforge-unstated-reset-20260930/omitted-reset.isf',
    'reset-explicit': 'specforge-unstated-reset-20260930/baseline-good.isf',
    'reset-absent': 'specforge-unstated-reset-20260930/clock-domain-no-reset.isf',
    'record-input': 'isf/record_input.isf',
    'record-input-children': 'isf/record_input_children.isf',
    'record-output-source': 'isf/record_output.isf',
}
CASES = {name: path if path.startswith('isf/') else 'docs/audits/' + path
         for name, path in CASES.items()}
ORIGINS = {
    'reset-omitted': [{'domain': None, 'origin': 'legacy_default'}],
    'reset-explicit': [{'domain': None, 'origin': 'explicit'}],
    'reset-absent': [{'domain': 'link', 'origin': 'domain_absent'}],
}
ARITY = "Malformed expression operator '^' with 1 operand(s). This active form requires at least 2 operands."


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def load(path):
    return json.loads(path.read_bytes())


def report(row, source, expected):
    assert row['source'] == source, 'source path'
    assert row['argv'] == ['perl', 'bin/fsmgen', '--strict', '--check', '--json', source], 'command'
    assert type(row['status']) is int and row['status'] == (0 if expected else 1), 'integer outcome'
    assert row['expected_success'] is expected, 'independent expected outcome'
    assert row['stderr'] == '', 'clean machine-report stderr'
    value = json.loads(row['stdout'])
    assert value['success'] is expected, 'boolean report outcome'
    return value


def status(value):
    assert value['revision'] == BASE, 'native revision'
    assert set(value['cases']) == set(CASES), 'complete status cases'
    for name, source in CASES.items():
        row = value['cases'][name]
        body = subprocess.check_output(['git', 'show', BASE + ':' + source], cwd=ROOT)
        assert row['source_identity'] == identity(body), 'native source identity'
        result = report(row, source, name not in REFUSED)
        if name in ORIGINS:
            assert result['source']['reset_provenance'] == ORIGINS[name], 'literal reset origin'


def reductions(value, packet):
    assert value['revision'] == BASE, 'reduction native revision'
    names = {'baseline-good', 'reduction-over-slice', 'byte-parity-param-width'}
    assert set(value['cases']) == names, 'complete reduction cases'
    rows = {row['path']: row for row in packet['files']}
    assert len(rows) == len(packet['files']), 'unique packet members'
    for row in rows.values():
        assert identity(row['text'].encode()) == {key: row[key] for key in ('bytes', 'sha256')}, 'packet bytes'
    for name in names:
        source = str(REDUCTION.relative_to(ROOT) / (name + '.isf'))
        raw = rows['sources/fsmgen-input/' + name + '.isf']['text'].encode()
        assert (ROOT / source).read_bytes() == raw, 'exact retained caller source'
        row = value['cases'][name]
        assert row['source_identity'] == identity(raw), 'caller source identity'
        result = report(row, source, name == 'baseline-good')
        if name != 'baseline-good':
            assert ARITY in row['stdout'], 'exact unary-XOR refusal'
            assert result['diagnostics'], 'retained source diagnostic'


def derive():
    for directory in (AUDIT, REDUCTION):
        manifest = load(directory / 'manifest.json')
        entries = manifest.get('files', {key: value for key, value in manifest.items()
                                      if key.endswith('.json')})
        for name, expected in entries.items():
            assert identity((directory / name).read_bytes()) == expected, 'retained data identity'
    value, reduction = load(AUDIT / 'current-checks.json'), load(REDUCTION / 'current-checks.json')
    packet = load(REDUCTION / 'packet.json')
    status(value)
    reductions(reduction, packet)
    outcomes = []
    for label in ('accepted-success', 'refusal-status', 'boolean-status', 'source-identity',
                  'reset-origin', 'omitted-case', 'reduction-success', 'reduction-arity'):
        bad, other = copy.deepcopy(value), copy.deepcopy(reduction)
        if label == 'accepted-success':
            row = bad['cases']['record-input']
            product = json.loads(row['stdout'])
            product['success'] = False
            row['stdout'] = json.dumps(product)
        elif label == 'refusal-status':
            bad['cases']['named-timers']['status'] = 0
        elif label == 'boolean-status':
            bad['cases']['record-input']['status'] = False
        elif label == 'source-identity':
            bad['cases']['record-input']['source_identity']['sha256'] = '0' * 64
        elif label == 'reset-origin':
            row = bad['cases']['reset-omitted']
            product = json.loads(row['stdout'])
            product['source']['reset_provenance'][0]['origin'] = 'explicit'
            row['stdout'] = json.dumps(product)
        elif label == 'omitted-case':
            del bad['cases']['duration-units']
        elif label == 'reduction-success':
            other['cases']['byte-parity-param-width']['status'] = 0
        else:
            row = other['cases']['reduction-over-slice']
            row['stdout'] = row['stdout'].replace(ARITY, 'different refusal')
        try:
            status(bad)
            reductions(other, packet)
        except AssertionError as error:
            outcomes.append(dict(label=label, refusal=str(error)))
        else:
            raise AssertionError('changed handoff observation admitted: ' + label)
    return dict(revision=BASE, controls=outcomes,
                verifier=identity(Path(__file__).read_bytes()),
                scope='Saved source-check outcomes only; no compiler, HDL runtime or foreign code executes.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    result = derive()
    destination = AUDIT / 'verification.json'
    if args.write:
        with destination.open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        assert result == load(destination), 'complete saved verification'
    print('Saved SPECFORGE receipt/current source outcomes and independent refusal controls PASS; feature, publication and consumer boundaries remain distinct.')
