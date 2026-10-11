"""Run exact original coordinate/address readers without writing their archives."""
import json
from pathlib import Path
import subprocess
import sys

from capture import BASE, canonical, pin, save

PRIOR = Path('docs/audits/raw-stack-prerequisites-20261011')
_prior_import_path = sys.path[:]
try:
    sys.path.insert(0, str(PRIOR))
    import replay
finally:
    sys.path[:] = _prior_import_path

SUCCESS = 'PASS complete coordinate/address prerequisite readers in their declared source or dated roles.\n'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def selected():
    declared = json.loads((PRIOR / 'readers.json').read_bytes())['readers']
    derived = replay.specifications()
    names = sorted(name for name in derived if name.startswith('address-'))
    need(len(names) == 11, 'whole original coordinate/address reader population')
    for name in names:
        need(declared[name]['specification'] == derived[name], 'whole unchanged original prerequisite specification')
    return {name: derived[name] for name in names}


def qualify(actual, spec):
    need(type(actual['status']) is int and actual['status'] == 0, 'actual typed prerequisite success')
    need(actual['specification'] == spec and actual['command'] == spec['command'], 'whole exact source-role command')
    need(type(actual['stdout']) is str and actual['stderr'] == '', 'complete clean prerequisite streams')
    need(actual['stdout'] == spec['stdout'] if spec['match'] == 'whole' else actual['stdout'].endswith(spec['stdout']),
         'whole original prerequisite stdout role')
    need(actual['programme'] == actual['programme_after'], 'whole unchanged prerequisite programme epoch')
    need(pin(actual['programme']['body'].encode()) == actual['programme']['identity'], 'complete actual prerequisite programme body')


def main():
    result = {}
    for name, spec in selected().items():
        command = spec['command']
        path = Path(command[2])
        raw = path.read_bytes()
        programme = dict(body=raw.decode(), identity=pin(raw))
        child = subprocess.run(command, capture_output=True, text=True)
        after = path.read_bytes()
        actual = dict(specification=spec, command=command, programme=programme,
                      status=child.returncode, stdout=child.stdout, stderr=child.stderr,
                      programme_after=dict(body=after.decode(), identity=pin(after)))
        # Preserve every terminal before applying the unchanged semantic predicates.
        save(name + '-actual.json', actual)
        print(name, 'actual native status', child.returncode, flush=True)
        qualify(actual, spec)
        result[name] = pin(canonical(actual))
    save('prerequisites-result.json', dict(readers=result,
        condition='Fresh executions authenticate complete original finite source products and explicitly dated publication roles. Original native observations are not recaptured; no later original-programme currency or hidden/private identity is inferred.'))
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
