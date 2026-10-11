"""Re-derive complete original prerequisite receipt roles without recapture."""
import copy
import json
from pathlib import Path
import sys

from capture import BASE, canonical, pin, save

PRIOR = Path('docs/audits/raw-stack-prerequisites-20261011')
sys.path.insert(0, str(PRIOR))
import replay
import predecessors
from common import REVISION
from predecessors import TASK, git

SUCCESS = 'PASS complete original prerequisite reader and predecessor contract roles; original source epochs retain.\n'


def main():
    declared = json.loads((PRIOR / 'readers.json').read_bytes())
    specs = replay.specifications()
    assert set(declared['readers']) == set(specs) and declared['revision'] == REVISION
    result = {}
    for name, spec in specs.items():
        entry = declared['readers'][name]
        path = Path(entry['receipt'])
        assert path.parent == PRIOR and path.name.startswith('actual-reader-')
        raw = path.read_bytes()
        actual = json.loads(raw)
        assert entry['specification'] == spec and entry['identity'] == pin(raw)
        replay.qualify(actual, spec)
        result[name] = dict(specification=spec, receipt=entry['receipt'], identity=pin(raw))
    contracts = json.loads((PRIOR / 'predecessors.json').read_bytes())
    predecessors.qualify_contracts(contracts['contracts'], git('show', REVISION + ':' + str(TASK)).decode())
    name = 'raw-inventory'
    actual = json.loads(Path(declared['readers'][name]['receipt']).read_bytes())
    controls = []
    for label, mutate, cause in (
        ('Boolean original native success', lambda row: row.update(status=False), 'actual integer prerequisite success'),
        ('borrowed original reader command', lambda row: row.update(command=['python3', '-B', 'borrowed.py']), 'exact whole prerequisite command'),
        ('short original native stream', lambda row: row.update(stdout='PASS\n'), 'whole declared prerequisite stdout role')):
        changed = copy.deepcopy(actual)
        mutate(changed)
        try:
            replay.qualify(changed, specs[name])
        except ValueError as error:
            assert str(error) == cause
            controls.append(dict(name=label, cause=str(error)))
        else:
            raise ValueError('changed original reader role accepted')
    save('prior-result.json', dict(revision=REVISION, readers=result, predecessors=pin(canonical(contracts)), controls=controls,
        condition='Complete original e428 prerequisite commands, bodies, streams and declared source/dated roles rederive from retained receipts. This is fresh metadata qualification, not recapture of original native observations or later historical-programme currency.'))
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
