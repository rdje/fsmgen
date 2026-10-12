"""Retain complete native first refusals for genuinely changed associations."""
import argparse
import copy
from preparation_common import *
import controls
import reader


def qualify(candidate, prefix, current=False):
    rows = json.loads((BASE / (prefix + 'controls.json')).read_bytes())
    declarations = controls.declarations(candidate)
    need(len(rows) == len(declarations), 'complete native separating control population')
    for row, declaration in zip(rows, declarations):
        wanted = copy.deepcopy(candidate)
        controls.mutate(wanted, declaration)
        need((declaration['cause'] is None) == same(wanted, candidate), 'genuine separating complete candidate')
        name = prefix + 'control-' + declaration['label'] + '.json.gz'
        need(same(wanted, load_product(name)), 'whole intended native separating candidate')
        actual = json.loads((BASE / (prefix + 'control-' + declaration['label'] + '-actual.json')).read_bytes())
        need(type(actual['status']) is int and actual['status'] == declaration['status']
             and type(actual['expected_status']) is int and actual['expected_status'] == declaration['status']
             and actual['programmes'] == actual['programmes_after']
             and same(actual['candidate_inputs'], {str(BASE / name): pin((BASE / name).read_bytes())})
             and same(actual['candidate_inputs'], actual['candidate_inputs_after']),
             'actual intended native control status and complete source/input conservation')
        need((declaration['cause'] is None and actual['stdout'] == reader.SUCCESS and actual['stderr'].count('\n') == 1)
             or (declaration['cause'] is not None and actual['stdout'] == ''
                 and actual['stderr'].endswith('ValueError: ' + declaration['cause'] + '\n')),
             'intended actual native first control refusal')
        command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', name]
        need(actual['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
             and same(row, dict(declaration=declaration, candidate=name, identity=pin(canonical(wanted)),
                 native=pin(canonical(actual)), command=command)), 'whole native control source candidate and receipt association')
        if current:
            for name, value in actual['programmes'].items():
                body = value['body'].encode() if 'body' in value else bytes.fromhex(value['body_hex'])
                need(Path(name).read_bytes() == body, 'whole current control instrument and input epoch')
    return rows


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--development', action='store_true')
    parser.add_argument('--prefix', choices=('', 'v3-'), default='')
    args = parser.parse_args()
    need(not (args.development and args.prefix), 'one explicit native control source epoch')
    prefix = 'development-' if args.development else args.prefix
    candidate = load_product(prefix + 'candidate.json.gz')
    rows = []
    for declaration in controls.declarations(candidate):
        wanted = copy.deepcopy(candidate)
        controls.mutate(wanted, declaration)
        need((declaration['cause'] is None) == same(wanted, candidate), 'genuine complete native separating mutation')
        name = prefix + 'control-' + declaration['label'] + '.json.gz'
        save_product(name, wanted)
        label = prefix + 'control-' + declaration['label']
        command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', name]
        print('START ' + label, flush=True)
        result = subprocess.run(['python3', '-B', str(BASE / 'capture.py'), '--expect', str(declaration['status']), label, *command],
                                capture_output=True, text=True)
        need(result.returncode == 0 and result.stderr == ''
             and result.stdout == label + ' actual native status ' + str(declaration['status']) + '\n',
             'native control capture must reach intended actual declared status')
        actual = json.loads((BASE / (label + '-actual.json')).read_bytes())
        need((declaration['cause'] is None and actual['stdout'] == reader.SUCCESS and actual['stderr'].count('\n') == 1)
             or (declaration['cause'] is not None and actual['stdout'] == ''
                 and actual['stderr'].endswith('ValueError: ' + declaration['cause'] + '\n')),
             'complete intended first native separating cause: ' + declaration['label'])
        rows.append(dict(declaration=declaration, candidate=name, identity=pin(canonical(wanted)),
                         native=pin(canonical(actual)), command=command))
    save(prefix + 'controls.json', rows)
    qualify(candidate, prefix, True)
    print('PASS complete ' + prefix + 'native canonical original-join separating controls.')
