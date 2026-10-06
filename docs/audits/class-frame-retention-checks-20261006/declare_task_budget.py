"""Declare this slice's measured task bytes under the existing local procedure."""
import hashlib
import io
import json
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/class-frame-retention-checks-20261006')
REVISION = 'd6ff9248c452ae55ed7379d411128606c96e4f51'
REGISTRY = Path('doctrine/live_document_size/surfaces.jsonl')
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'


def main():
    paths = sorted(list(Path('docs/tasks').glob('*.md')) + list(Path('docs/tasks/segments').glob('*/*.md')))
    root = Path.cwd()
    assert all(p.is_file() and not p.is_symlink() and p.stat().st_dev == root.stat().st_dev for p in paths)
    actual = {str(p): p.read_bytes() for p in paths}
    archive = subprocess.check_output(['git', 'archive', REVISION, 'docs/tasks'])
    with tarfile.open(fileobj=io.BytesIO(archive)) as t:
        captured = {m.name: t.extractfile(m).read() for m in t.getmembers() if m.isfile() and m.name in actual}
    assert set(captured) == set(actual)
    assert all(raw == captured[p] for p, raw in actual.items() if p != TASK)
    byte_total = sum(map(len, actual.values()))
    # The exact original population plus only the owned replacement gives an
    # independently source-bound census, rather than a copied total.
    original_total = sum(map(len, captured.values()))
    assert original_total - len(captured[TASK]) + len(actual[TASK]) == byte_total
    lines = REGISTRY.read_text().splitlines()
    i = next(i for i, line in enumerate(lines) if json.loads(line).get('surface_id') == 'task_evidence')
    before, after = json.loads(lines[i]), json.loads(lines[i])
    old_allowance = before['baseline']['bytes_total'] + before['transition']['max_growth']['bytes_total']
    assert after['state'] == 'warning_debt' and byte_total > old_allowance
    new_allowance = min(byte_total + before['transition']['ratchet_step']['bytes_total'], before['enforcement_ceilings']['bytes_total'])
    assert new_allowance >= byte_total
    after['transition']['max_growth']['bytes_total'] = new_allowance - before['baseline']['bytes_total']
    assert after['baseline'] == before['baseline'] and after['enforcement_ceilings'] == before['enforcement_ceilings']
    output = BASE / 'task-budget.json'; assert not output.exists()
    proof = dict(revision=REVISION, before=before, after=after, original_bytes_total=original_total,
        actual_bytes_total=byte_total, predecessor_allowance=old_allowance, new_allowance=new_allowance,
        complete_members={p: dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()) for p, raw in actual.items()},
        legs=dict(rederive='complete same-volume regular task-file population byte census',
                  falsify='predecessor allowance rejects the actual; fixed-Git member conservation permits only the owned replacement',
                  durability='tracked producer, complete member pins, exact original revision and unconditional common pressure checker'))
    output.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    lines[i] = json.dumps(after, sort_keys=True, separators=(',', ':'))
    REGISTRY.write_text('\n'.join(lines) + '\n')
    print('PASS measured task byte declaration; baseline/ceilings and card authority unchanged.')


if __name__ == '__main__':
    main()
