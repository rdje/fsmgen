"""Retain actual superseded/current/snapshot roles and restored unrelated progress."""
import copy
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-tooling-current-reader-20261006')
CHECKS = Path('docs/audits/tooling-current-reader-checks-20261006')
ns = {'__name__': 'tooling_roles', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)


def run(command):
    result = subprocess.run(command, capture_output=True, text=True)
    return dict(command=command, status=result.returncode, stdout=result.stdout, stderr=result.stderr)


def main():
    output = CHECKS / 'roles.json'; assert not output.exists()
    chapter, registry = (Path(ns[k]) for k in ('CHAPTER', 'REGISTRY'))
    before = {str(p): p.read_text() for p in (chapter, registry)}
    record = dict(programme_identity=ns['identity'](Path(__file__).read_bytes()), source_before=before, restored=False)
    record['superseded_current'] = run(['python3', '-B', 'docs/audits/record-value-own-boundary-publication-20261005/verify.py', '--current'])
    record['snapshot'] = run(['python3', '-B', str(BASE / 'verify.py')])
    record['candidate_chapter'] = before[str(chapter)] + '\n<!-- Owned tooling-reader unrelated progress; restore before commit. -->\n'
    lines = before[str(registry)].splitlines()
    i = next(i for i, s in enumerate(lines) if json.loads(s).get('surface_id') == 'shipped_behavior')
    surface = json.loads(lines[i]); change = surface['reference_contract']['aggregate_change']
    public = ns['module'](ns['PUBLIC'] / 'verify.py')
    book = {str(p): p.read_bytes() for p in Path('docs/book/src').glob('*.md')}
    book[str(chapter)] = record['candidate_chapter'].encode()
    change['delta'] = {k: public['metrics'](book)[k] - change['baseline'][k] for k in change['baseline']}
    lines[i] = json.dumps(surface, sort_keys=True, separators=(',', ':'))
    record['candidate_registry'] = '\n'.join(lines) + '\n'
    intake = CHECKS / 'progress-restoration.json'; assert not intake.exists()
    intake.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    try:
        chapter.write_text(record['candidate_chapter']); registry.write_text(record['candidate_registry'])
        record['progress'] = run(['python3', '-B', str(BASE / 'verify.py'), '--current'])
    finally:
        for p, source in before.items(): Path(p).write_text(source)
        record['restored'] = all(Path(p).read_text() == source for p, source in before.items())
        output.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    ns['require'](record['restored'], 'exact unrelated-progress restoration')
    for role, status, token in (
        ('superseded_current', 1, 'whole current source/role/question/reader epoch'),
        ('snapshot', 0, ns['SUCCESS']), ('progress', 0, ns['CURRENT_SUCCESS']),
    ):
        receipt = record[role]
        ns['require'](type(receipt['status']) is int and receipt['status'] == status
            and token in receipt['stderr' if status else 'stdout'], 'actual tooling reader role: ' + role)
    print('PASS actual superseded refusal, snapshot and unrelated current progress; exact source bytes restored.')


if __name__ == '__main__':
    main()
