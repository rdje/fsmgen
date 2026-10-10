"""Capture complete final current inputs without granting later currency."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from contracts import BASE, FEATURE, MODULE, REFERENCE, REGISTRY, ROLE, TASK, need, pin, read, root
sys.path.insert(0, str(Path('scripts').resolve()))
import check_record_value_publication as current


def main():
    root()
    need(not (BASE / 'snapshot-final.json').exists(), 'never overwrite complete dated capture')
    prior = current.historical(); canonical = current.sources()
    record = current.current_input(prior, canonical)
    current.check(record, canonical, prior, current.authority(prior))
    qualification = current.address_fact.authenticate()
    rows = current.plane.expected_rows(); current.plane.check(rows, 'docs/book/book')
    native, copied = {}, {}
    for chapter in (FEATURE, REFERENCE):
        raw = read('docs/book/book/' + Path(chapter).stem + '.html')
        destination = BASE / (Path(chapter).stem + '.final.html.txt')
        destination.write_bytes(raw); native[chapter] = {'path': str(destination), **pin(raw)}
    for row in rows:
        raw = current.plane.source_bytes(row['source'])
        need(raw == read('docs/book/book/' + row['asset']), 'whole actual final canonical copied source')
        copied[row['source']] = pin(raw)
    programmes = [MODULE, 'scripts/check_record_value_publication.py', 'scripts/record_value_coordinate_fact.py',
                  'scripts/book_source_references.py', 't/python/test_record_value_current_publication.py',
                  *[str(BASE / name) for name in ('checks.py', 'contracts.py', 'close.py', 'capture_final.py', 'verify.py', 'task_pressure_final.py', 'finish_tasks.py', 'reproduce_frontier_probe.py')]]
    (BASE / 'task-qualified-final.md.txt').write_bytes(read(TASK))
    result = {'role': ROLE, 'record': record, 'qualification': qualification, 'native': native,
              'routes': rows, 'copied_sources': copied, 'registry': read(REGISTRY).decode(),
              'navigation': read('MEMORY.md').decode(), 'task_index': read('docs/TASK_TREE.md').decode(),
              'programmes': {p: pin(read(p)) for p in programmes}}
    need(canonical == current.sources(), 'whole canonical capture epoch conserves')
    (BASE / 'snapshot-final.json').write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS complete dated final address source/query/history/native/copied-source capture; later currency remains the maintained reader responsibility.')


if __name__ == '__main__':
    main()
