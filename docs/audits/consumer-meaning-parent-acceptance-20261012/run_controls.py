"""Execute every genuine complete parent mutation as an actual native reader."""
import copy
import subprocess
from acceptance_common import *
import controls
import reader

if __name__ == '__main__':
    good = load_product('candidate.json.gz')
    rows = []
    for label, mutate, status, cause in controls.CASES:
        value = copy.deepcopy(good)
        if mutate:
            mutate(value)
            need(not same(value, good), 'genuine complete parent separating candidate')
        name = 'control-' + label + '.json.gz'
        save_product(name, value)
        command = ['python3', '-B', str(BASE / 'reader.py'), '--candidate', name]
        outer = ['python3', '-B', str(BASE / 'capture.py'), '--expect', str(status), 'control-' + label, *command]
        result = subprocess.run(outer, capture_output=True, text=True)
        actual = json.loads((BASE / ('control-' + label + '-actual.json')).read_bytes())
        need(result.returncode == 0 and type(actual['status']) is int and actual['status'] == status
             and actual['expected_status'] == status and actual['programmes'] == actual['programmes_after'],
             'whole actual intended parent reader control status and programme epoch')
        need(actual['command'] == ['scripts/run_with_ram_guard.sh', '--', *command], 'whole exact native parent control command')
        if cause:
            need(actual['stdout'] == '' and actual['stderr'].endswith('ValueError: ' + cause + '\n'),
                 'first intended native parent control refusal: ' + label)
        else:
            need(actual['stdout'] == reader.SUCCESS and actual['stderr'].count('\n') == 1,
                 'whole positive native parent control terminal')
        need(same(value, load_product(name)), 'complete parent control candidate conservation')
        rows.append(dict(label=label, candidate=name, identity=pin(canonical(value)), command=actual['command'],
            status=status, cause=cause, native=pin(canonical(actual)),
            outer=dict(command=outer, status=result.returncode, stdout=result.stdout, stderr=result.stderr)))
    save('controls.json', rows)
    print('PASS complete genuine unchanged meaning-parent native separating controls.')
