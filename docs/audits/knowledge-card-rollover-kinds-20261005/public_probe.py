"""Compare the public schema domain with the private equivalent-value candidate."""
import copy
import json
import shutil
import subprocess
from pathlib import Path

BASE = Path('docs/audits/knowledge-card-rollover-kinds-20261005')
PRIOR = Path('docs/audits/knowledge-card-rollover-20261005')
SCRATCH = Path('.artifacts/knowledge-card-rollover-kinds')


def main():
    native = json.loads((PRIOR / 'native-archive-controls.json').read_text())[0]
    results = []
    for name, value in [('integer', 1), ('boolean', True), ('integral-float', 1.0)]:
        root = SCRATCH / 'public-fixtures' / name
        assert not root.exists(), 'fresh owned primitive fixture'
        root.mkdir(parents=True); (root / 'archive').mkdir()
        metadata = {'record_type': 'registry', 'schema_version': 1, 'max_records': 8, 'max_bytes': 8192, 'max_record_bytes': 2048}
        (root / 'surfaces.jsonl').write_text(json.dumps(metadata) + '\n' + json.dumps(native['surface']) + '\n')
        descriptors = copy.deepcopy(native['descriptors'])
        descriptors[1]['schema_version'] = value
        for row in descriptors[1:]:
            for field in ('retrieval_locator', 'current_pointer'):
                dest = root / row[field]; dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(row[field], dest)
        (root / 'archives.jsonl').write_text(''.join(json.dumps(row) + '\n' for row in descriptors))
        command = ['perl', 'live-document-size/scripts/check_live_document_size.pl', '--root', str(root), '--registry', 'surfaces.jsonl', '--archives', 'archives.jsonl']
        for flag in ('routes', 'ledgers', 'evidence-maps', 'retention-contracts', 'derived-state'):
            (root / (flag + '.jsonl')).write_text(json.dumps(metadata) + '\n')
            command.extend(['--' + flag, flag + '.jsonl'])
        run = subprocess.run(command, capture_output=True, text=True)
        results.append({'case': name, 'value': value, 'surface': native['surface'], 'descriptors': descriptors,
                        'result': {'command': command, 'status': run.returncode, 'stdout': run.stdout, 'stderr': run.stderr}})
    (BASE / 'public-probe.json').write_text(json.dumps(results, sort_keys=True, indent=2) + '\n')
    for row in results:
        print(row['case'], row['result']['status'], row['result']['stderr'].strip())


if __name__ == '__main__':
    main()
