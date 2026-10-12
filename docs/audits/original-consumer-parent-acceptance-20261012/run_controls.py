"""Write genuine full controls and retain every native terminal and programme."""
import argparse
import copy
from parent_common import *
import controls
import native_probe

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--development', action='store_true')
    parser.add_argument('--development-tag', default='development')
    args = parser.parse_args()
    candidate = load_product('development-candidate.json.gz' if args.development else 'candidate.json.gz')
    need(re.fullmatch(r'development(?:-v(?:[2-9]|[1-9][0-9]+))?', args.development_tag) is not None
         and (args.development or args.development_tag == 'development'), 'explicit ordinary development attempt tag')
    prefix = args.development_tag + '-' if args.development else ''
    rows = []
    for role, label, status, cause in controls.declarations():
        original = native_probe.payload(candidate, role)
        wanted = copy.deepcopy(original)
        controls.mutate(role, label, wanted)
        need((cause is None and same(wanted, original)) or (cause is not None and not same(wanted, original)),
             'genuine complete native separating mutation')
        name = prefix + 'control-' + role + '-' + label + '.json.gz'
        save_product(name, wanted)
        command = ['python3', '-B', str(BASE / 'native_probe.py'), '--role', role, '--candidate', name]
        gate = prefix + 'control-' + role + '-' + label
        outer = subprocess.run(['python3', '-B', str(BASE / 'capture.py'), '--expect', str(status), gate, *command], capture_output=True, text=True)
        need(outer.returncode == 0 and outer.stderr == '' and outer.stdout == gate + ' actual native status ' + str(status) + '\n',
             'complete native separating capture succeeds with intended declared status')
        actual = json.loads((BASE / (gate + '-actual.json')).read_bytes())
        need(type(actual['status']) is int and actual['status'] == status
             and type(actual['expected_status']) is int and actual['expected_status'] == status,
             'actual typed native separating result')
        need((cause is None and actual['stdout'] == native_probe.SUCCESS[role] and actual['stderr'].count('\n') == 1)
             or (cause is not None and actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n')),
             'complete intended first native separating cause')
        rows.append(dict(role=role, label=label, status=status, cause=cause, candidate=name,
            identity=pin(canonical(wanted)), command=actual['command'], native=pin(canonical(actual)),
            outer=dict(command=outer.args, status=outer.returncode, stdout=outer.stdout, stderr=outer.stderr)))
    save(prefix + 'controls.json', rows)
    print('PASS ' + ('development-only ' if args.development else '') + 'complete original source, meaning and parent-link native separating controls.')
