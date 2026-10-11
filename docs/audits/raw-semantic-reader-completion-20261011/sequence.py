"""Run the declared core gates sequentially; each terminal writer stays outside its guard."""
import subprocess
import traceback
from common import *
import verify


def steps():
    result = [('intake-after', ['python3', '-B', str(BASE / 'intake.py'), '--after'])]
    result.extend(('before-' + role, ['python3', '-B', str(path)]) for role, path, _ in verify.defaults())
    result.append(('corpus', ['python3', '-B', str(BASE / 'verify.py'), '--corpus']))
    result.extend(('after-' + role, ['python3', '-B', str(path)]) for role, path, _ in verify.defaults())
    result.extend([('original-retention', verify.RETAIN_COMMAND),
                   ('checkpoint-core', ['python3', '-B', str(BASE / 'verify.py'), '--core'])])
    return result


def main():
    observed = load('observer-D-actual.json')
    need(type(observed['status']) is int and observed['status'] == 0
         and observed['observation_failure'] is None, 'complete original D result before core sequence')
    body = local(BASE / 'sequence.py').read_bytes()
    started = dict(owner=LEAF, steps=steps(), programmes=verify.instruments(),
        programme=dict(body=body.decode(), identity=pin(body)),
        original_D=identity(BASE / 'observer-D-actual.json'),
        condition='One declared sequential core qualification. Every heavy child has its own original standard guard and an external complete terminal writer. No publication or task closure occurs here; missing/nonzero steps never qualify.')
    save('core-sequence-started.json', started)
    outcomes = []
    failure = None
    try:
        for name, inner in steps():
            command = ['python3', '-B', str(BASE / 'checks.py'), name, *inner]
            result = subprocess.run(command, capture_output=True, text=True)
            outcome = dict(name=name, command=command, status=result.returncode,
                           stdout=result.stdout, stderr=result.stderr)
            outcomes.append(outcome)
            save('core-sequence-' + name + '-actual.json', outcome)
            print(name, 'terminal', result.returncode, flush=True)
            need(type(result.returncode) is int and result.returncode == 0,
                 'actual successful core sequence step: ' + name)
    except BaseException:
        failure = traceback.format_exc()
    actual = dict(**started, outcomes=outcomes, failure=failure,
        programme_after=pin(local(BASE / 'sequence.py').read_bytes()), programmes_after=verify.instruments())
    save('core-sequence-actual.json', actual)
    need(failure is None and len(outcomes) == len(steps())
         and actual['programmes'] == actual['programmes_after'] == load('qualification-plan.json')['programmes']
         and actual['programme_after'] == pin(body), 'complete actual unchanged ordered core sequence')
    print('PASS complete ordered original-reader checkpoint core gates; publication remains required.')


if __name__ == '__main__':
    main()
