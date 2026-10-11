"""Admit one exact original default under lower observed resources; retain its terminal."""
import argparse
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, 'docs/audits/raw-semantic-reader-completion-20261011')
from common import *
import verify as first
import observe

OUT = Path('docs/audits/raw-semantic-reader-checkpoint-20261011')


def record(name, value):
    path = local(OUT / name, exists=False)
    need(not path.exists(), 'retain first separate continuation record')
    path.write_bytes(canonical(value))


def main(role):
    plan = json.loads(local(OUT / 'plan.json').read_bytes())
    choices = {r: ['python3', '-B', str(p)] for r, p, _ in first.defaults()
               if r in ('construction', 'layout', 'custody', 'semantic')}
    choices['retention'] = first.RETAIN_COMMAND
    logical = 'original-retention' if role == 'retention' else 'after-' + role
    name = plan['selection'][logical]
    body = local(OUT / 'continue.py').read_bytes()
    memory = observe.memory()
    started = dict(owner=LEAF, logical=logical, name=name,
        command=['python3', '-B', str(BASE / 'checks.py'), name, *choices[role]],
        programme=dict(body=body.decode(), identity=pin(body)), programmes=first.instruments(),
        admission=memory, plan=identity(OUT / 'plan.json'),
        condition='One original default only, no retry loop. This writer and the first gate writer both remain outside the unchanged child guard. Admission observations are not continuous or peak memory measurements.')
    record(name + '-started.json', started)
    need(memory['occupied_percent'] <= plan['admission_ceiling_percent']
         and first.instruments() == plan['first_programmes'],
         'lower observed resource admission and complete unchanged first instruments before native execution')
    stdout = local(OUT / (name + '.stdout.txt'), exists=False)
    stderr = local(OUT / (name + '.stderr.txt'), exists=False)
    with stdout.open('xb', buffering=0) as out, stderr.open('xb', buffering=0) as err:
        result = subprocess.run(started['command'], stdout=out, stderr=err)
    actual = dict(**started, status=result.returncode, stdout_path=str(stdout), stderr_path=str(stderr),
        stdout=stdout.read_text(), stderr=stderr.read_text(), programmes_after=first.instruments(),
        programme_after=pin(local(OUT / 'continue.py').read_bytes()))
    record(name + '-actual.json', actual)
    print(name, 'separate continuation status', result.returncode, flush=True)
    need(type(result.returncode) is int and result.returncode == 0
         and actual['programmes'] == actual['programmes_after'] == plan['first_programmes']
         and actual['programme_after'] == pin(body), 'actual successful unchanged separate original default continuation')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--role', choices=['construction', 'layout', 'custody', 'semantic', 'retention'], required=True)
    main(parser.parse_args().role)
