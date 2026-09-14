"""Re-read committed first worker results; never issue, execute or clean a fixture."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from unittest.mock import patch

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = '266e8a99f407b0cc1649c5791ee8c5c4edc3b50c'
ADMISSION = 'docs/audits/native-proxy-populated-final-admission-20260913'
sys.path.insert(0, str(ROOT / ADMISSION))
import review_run
import contract


def read(name):
    return json.loads((BASE / name).read_bytes())


def verify():
    retained = read('first-results.json')
    assert retained['admission_commit'] == REVISION
    assert retained['owner'] == contract.EXECUTION_OWNER and not retained['producer_reusable']
    for row in read('source-pins.json'):
        body = (ROOT / row['path']).read_bytes()
        assert len(body) == row['size_bytes'] and hashlib.sha256(body).hexdigest() == row['sha256']
        assert subprocess.check_output(['git', 'show', REVISION + ':' + row['path']], cwd=ROOT) == body
    outputs = {}
    for row in retained['first_results']:
        copied = row['copy']
        path = ROOT / copied['path']
        assert path.parent == BASE / 'first-results' and not path.is_symlink()
        assert row['original'] == contract.OUTPUT + '/' + path.name
        body = path.read_bytes()
        assert len(body) == copied['size_bytes'] and hashlib.sha256(body).hexdigest() == copied['sha256']
        mode = 0o600 if path.name == 'journal.jsonl' or path.name.endswith(('.stdout', '.stderr')) else 0o400
        assert row['original_mode'] == mode and row['original_inode'] > 0 and row['original_uid'] > 0
        assert path.name not in outputs
        outputs[path.name] = body
    assert set(outputs) == review_run.expected_files(True)
    assert {path.name for path in (BASE / 'first-results').iterdir()} == set(outputs)

    def retained_reader(review=False):
        assert review is True
        return dict(outputs)

    # Redirect only the saved-review byte reader to the exact tracked copies.
    # The committed original validator still checks every record and retained
    # absence receipt; no native query or constructed result replaces evidence.
    with patch.object(review_run, 'read_outputs', retained_reader):
        reviewed = review_run.verify(saved=True)
    for row in retained['raw_outputs'].values():
        assert row['exit'] == '0\n'
    failure = read('retention-first.json')
    source = (ROOT / failure['source_path']).read_bytes()
    assert hashlib.sha256(source).hexdigest() == failure['source_sha256']
    assert failure['outputs']['exit'] == '1\n'
    assert "unexpected keyword argument 'saved'" in failure['outputs']['stderr']
    assert source.replace(b'read_outputs(saved=True)', b'read_outputs(True)') == (BASE / 'retain.py').read_bytes()
    assert not failure['copy_directory_allocated'] and not failure['producer_replay']
    joined = reviewed['join']
    counts = {name: sum(case[name] for case in joined['cases']) for name in (
        'workers', 'commands', 'completed_operations', 'cancelled_workers',
        'cleanup_nodes', 'snapshots', 'retained_archives')}
    assert counts['workers'] == len(joined['workers'])
    return dict(owner=retained['owner'], next_owner=retained['next_owner'], admission_commit=REVISION,
        cases=len(joined['cases']), counts=counts, journal_rows=joined['journal_rows'],
        journal_bytes=joined['journal_bytes'], retained_files=len(outputs),
        retained_bytes=sum(map(len, outputs.values())), native_absence_receipts=len(reviewed['native_absence']),
        group_absence_receipts=len(reviewed['groups']), absent_roots=reviewed['absent_roots'],
        actual_selected_worker_execution_reviewed=True, producer_replayed=False,
        synthetic_retirement_and_work_records=True, compiler_execution=False,
        proxy_execution=False, live_collector_execution=False,
        final_cross_boundary_join_open=True, native_live_startup_qualification_open=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument('--save', action='store_true')
    selection.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    result = verify()
    if args.save:
        with (BASE / 'review.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        assert result == read('review.json')
    print(json.dumps(result, sort_keys=True, indent=2))
