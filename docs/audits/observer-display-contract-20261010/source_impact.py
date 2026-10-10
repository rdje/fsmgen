"""Correct the incomplete string-only query without making a global census claim."""
import hashlib
import json
import re
from pathlib import Path

BASE = Path('docs/audits/observer-display-contract-20261010')
SOURCE = Path('docs/audits/record-value-class-frame-join-20261006/source-models.json')


def main():
    raw = SOURCE.read_bytes()
    source = json.loads(raw)
    found, initial = [], []
    def walk(value, path):
        if isinstance(value, dict):
            v = value.get('value')
            if value.get('kind') == 'scalar' and type(v) in (str, int, float):
                spelling = str(v)
                if re.fullmatch(r'-?[0-9]+(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?', spelling):
                    found.append({'path': path, 'source_kind': type(v).__name__, 'value': v, 'spelling': spelling})
                if isinstance(v, str) and v.lstrip('-').isdigit():
                    initial.append(v)
            for key, child in value.items():
                walk(child, path + '/' + key)
        elif isinstance(value, list):
            for index, child in enumerate(value):
                walk(child, path + '/' + str(index))
    walk(source['modes'], '/modes')
    report = {'source': str(SOURCE), 'identity': {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()},
              'initial_string_only_max': max(map(len, initial), default=0),
              'initial_query_locus': 'The string-only selector omitted integer-valued scalar source fields; its zero is not evidence of absence.',
              'complete_selected_numeric_fields': found,
              'corrected_max': max((len(r['spelling']) for r in found), default=0),
              'scope': 'Only scalar numeric source fields in the complete qualified class/frame modes. No global input, native numeric identity, provider/settings or unmodeled-source absence claim.'}
    destination = BASE / 'source-impact.json'
    assert not destination.exists()
    destination.write_text(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print('PASS incomplete query reproduced and corrected with whole selected source fields; no global absence claim.')


if __name__ == '__main__':
    main()
