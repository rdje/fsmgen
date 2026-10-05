"""Reproduce the private integer/Boolean collision without changing any source artifact."""
import copy
import importlib.util
import json
from pathlib import Path

BASE = Path('docs/audits/knowledge-card-rollover-kinds-20261005')
PRIOR = Path('docs/audits/knowledge-card-rollover-20261005')


def main():
    spec = importlib.util.spec_from_file_location('old_rollover_reader', PRIOR / 'verify.py')
    reader = importlib.util.module_from_spec(spec); spec.loader.exec_module(reader)
    source = json.loads((PRIOR / 'source.json').read_text())
    after = json.loads((PRIOR / 'after.json').read_text())
    descriptors = json.loads((PRIOR / 'descriptors.json').read_text())
    proposals = {name: (reader.SELECT / (name + '.proposed.txt')).read_bytes() for name in source['catalog']['sources']}
    reader.check(source, after, descriptors, proposals)
    results = []
    for value in (True, 1.0):
        changed_after = copy.deepcopy(after); changed_descriptors = copy.deepcopy(descriptors)
        changed_descriptors[0]['schema_version'] = value
        changed_after['doctrine/live_document_size/archive_descriptors.jsonl'] = source['before']['doctrine/live_document_size/archive_descriptors.jsonl'] + ''.join(json.dumps(r, sort_keys=True, separators=(',', ':')) + '\n' for r in changed_descriptors)
        try:
            reader.check(source, changed_after, changed_descriptors, proposals)
        except AssertionError as error:
            result = {'accepted': False, 'cause': str(error)}
        else:
            result = {'accepted': True}
        results.append({'primitive': type(value).__name__, 'value': value, 'result': result})
    output = {'scope': 'Private parameterized comparison only; published source data and production gate unchanged.', 'baseline': 'accepted', 'controls': results}
    recorded = json.dumps(output, sort_keys=True, indent=2) + '\n'
    path = BASE / 'first-private-probe.json'
    if path.exists():
        assert path.read_text() == recorded, 'whole original private probe freshly reproduces without overwriting'
    else:
        path.write_text(recorded)
    print(json.dumps(output))


if __name__ == '__main__':
    main()
