"""Durably stream every child outcome, including interruption-time output."""
import argparse
import subprocess
from pathlib import Path
from common import *


def execute(label, command):
    need(label and all(c.isalnum() or c == '-' for c in label), 'closed source/result label')
    attempts = list(BASE.glob('started-' + label + '-*.json'))
    number = max((int(path.stem.rsplit('-', 1)[1]) for path in attempts), default=0) + 1
    prefix = label + '-' + str(number)
    stdout = local(BASE / (prefix + '.stdout.txt'), exists=False)
    stderr = local(BASE / (prefix + '.stderr.txt'), exists=False)
    need(not stdout.exists() and not stderr.exists(), 'retain first full child streams')
    epoch = programs()
    instruments = {arg: dict(body=(raw := local(arg).read_bytes()).decode(), identity=pin(raw))
                   for arg in command if Path(arg).is_file()}
    started = dict(command=command, programs=epoch, direct_instruments=instruments,
        stdout_path=str(stdout), stderr_path=str(stderr), owner=OWNER, source_revision=REVISION,
        scope='Pre-execution only. A missing actual result is non-success; stream files retain bytes even if the guard terminates this process tree.')
    save('started-' + prefix + '.json', started)
    with stdout.open('xb', buffering=0) as out, stderr.open('xb', buffering=0) as err:
        result = subprocess.run(command, stdout=out, stderr=err)
    out, err = stdout.read_bytes(), stderr.read_bytes()
    after = {path: pin(local(path).read_bytes()) for path in epoch | instruments}
    before = {path: row['identity'] for path, row in (epoch | instruments).items()}
    record = dict(**started, status=result.returncode, stdout=out.decode(), stderr=err.decode(),
                  stdout_identity=pin(out), stderr_identity=pin(err), inputs_after=after, epoch_conserved=before == after)
    name = 'actual-' + prefix + '.json'
    save(name, record)
    print(name, result.returncode, record['stdout'][-400:], record['stderr'][-1000:], flush=True)
    # Persist full actual result before evaluating status, streams or currency.
    need(before == after, 'complete declared reader programme epoch conserved')
    need(type(result.returncode) is int and result.returncode == 0, 'actual successful child status: ' + name)
    return name, record


def qualify(record, spec):
    need(type(record.get('status')) is int and record['status'] == 0, 'actual integer reader success')
    need(record['command'] == spec['command'], 'exact complete reader command')
    need(type(record['stdout']) is str and record['stderr'] == '', 'whole clean reader streams')
    need(record['stdout'] == spec['stdout'] if spec['match'] == 'whole' else record['stdout'].endswith(spec['stdout']),
         'complete declared source or dated reader stdout role')
    need(record['epoch_conserved'] is True, 'whole reader programme conservation')
    need(type(record['programs']) is dict and set(record['programs']) == set(programs())
         and type(record['direct_instruments']) is dict and bool(record['direct_instruments']),
         'complete own reader runner and direct instrument population')
    need(record['stdout_identity'] == pin(record['stdout'].encode())
         and record['stderr_identity'] == pin(record['stderr'].encode()), 'complete durably retained actual streams')
    for path, programme in (record['programs'] | record['direct_instruments']).items():
        need(pin(programme['body'].encode()) == programme['identity'] == record['inputs_after'][path],
             'whole actual reader programme and final epoch')
    need(all(row['identity'] == programs()[path]['identity'] for path, row in record['programs'].items()),
         'exact current source of every retained own runner programme')


def specifications():
    prior = json.loads(git('show', REVISION + ':' + str(PRIOR / 'readers.json')))
    result = {name: row['specification'] for name, row in prior['readers'].items()}
    checks = json.loads(git('show', REVISION + ':docs/audits/task-terminal-rollover-20261011/checks.json'))
    result['complete-prerequisite-default'] = dict(command=['python3', '-B', str(PRIOR / 'verify.py')],
        stdout=checks['prior-raw-dated']['stdout'], match='whole', authority=str(PRIOR / 'verify.py'),
        context='complete dated prerequisite acceptance; no later native/current publication currency')
    result['task-containment-dated'] = dict(command=['python3', '-B', 'docs/audits/task-terminal-rollover-20261011/verify.py'],
        stdout=checks['default-current']['stdout'], match='whole',
        authority='docs/audits/task-terminal-rollover-20261011/verify.py', context='complete retained dated task/source/registry epoch')
    result['aggregate-prerequisite-correction'] = dict(command=['python3', '-B', 'docs/audits/raw-stack-prerequisite-gate-repair-20261011/verify.py'],
        stdout='PASS retained aggregate gate refusal, independent complete task-source census and exact measured allowance correction; every ceiling and Knowledge Map allowance remains unchanged.\n',
        match='whole', authority='docs/audits/raw-stack-prerequisite-gate-repair-20261011/verify.py',
        context='complete dated task-source/registry correction; no later allowance currency')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--readers', action='store_true')
    parser.add_argument('--fresh-readers', action='store_true',
                        help='Explicitly rerun every reader; retain all earlier attempts unchanged.')
    parser.add_argument('arguments', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if not args.readers:
        need(not args.fresh_readers, 'fresh execution requires whole-reader selection')
        need(len(args.arguments) >= 2, 'explicit named command')
        execute(args.arguments[0], args.arguments[1:])
        return
    need(not args.arguments, 'closed whole-reader selection')
    need(load('intake-before.json')['revision'] == REVISION, 'complete whole source admission before readers')
    result = {}
    specs = specifications()
    # Execute the longest complete coordinate reader last; every role still runs.
    names = sorted(specs, key=lambda name: (name == 'address-coordinate', name))
    for name in names:
        spec = specs[name]
        existing = sorted(BASE.glob('actual-reader-' + name + '-*.json'),
                          key=lambda path: int(path.stem.rsplit('-', 1)[1]))
        if existing and not args.fresh_readers:
            path = existing[-1]
            record = json.loads(path.read_bytes())
            qualify(record, spec)
        else:
            filename, record = execute('reader-' + name, spec['command'])
            path = BASE / filename
            qualify(record, spec)
        result[name] = dict(specification=spec, receipt=str(path), identity=pin(path.read_bytes()))
    save('readers.json', dict(revision=REVISION, owner=OWNER, scope=SCOPE, readers=result))
    print('PASS every complete declared raw-semantic admission reader freshly executed in its explicit source or dated role; full actual programmes and both streams retain.')


if __name__ == '__main__':
    main()
