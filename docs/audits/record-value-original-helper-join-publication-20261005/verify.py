"""Superseding fact publication; attempted topic partition stays historical."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-helper-join-publication-20261005')
PRIOR = Path('docs/audits/record-value-original-helper-join-20261005')


def check(record, actual):
    original = subprocess.check_output(['git', 'show', record['revision'] + ':' + record['path']], text=True)
    assert original == record['before'], 'whole committed original fact card'
    expected = original
    for old, new in record['replacements']:
        assert old in expected, 'declared whole source publication input'
        expected = expected.replace(old, new)
    assert expected == record['after'] == actual, 'whole current bounded fact publication'
    partition = json.loads((PRIOR / 'knowledge-transform.json').read_text())
    assert record['attempted_source'] == partition['source_after'], 'exact historical attempted source partition'
    assert record['attempted_destination'] == partition['destination_after'], 'exact historical attempted topic facts/questions'
    assert not Path(record['attempted_destination_path']).exists(), 'unpublished topic stays historical'
    # The only semantic addition is a signpost to the already qualified join.
    # Every existing paragraph and query survives the exact two replacements.
    assert len(actual.encode()) <= 6144, 'bounded current fact file'
    if (BASE / 'manifest.json').exists():
        declared = json.loads((BASE / 'manifest.json').read_text())
        actual_manifest = {p.name: {'bytes': len(p.read_bytes()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
                           for p in BASE.iterdir() if p.name != 'manifest.json'}
        assert declared == actual_manifest, 'whole sealed superseding publication identity'


def main():
    record = json.loads((BASE / 'knowledge-publication.json').read_text())
    actual = Path(record['path']).read_text()
    check(record, actual)
    changed = actual.replace('original classes were unmeasured', 'original classes were measured')
    assert changed != actual, 'genuine overstated fact mutation'
    try:
        check(record, changed)
    except AssertionError as error:
        assert str(error) == 'whole current bounded fact publication', 'intended whole fact corruption'
    else:
        raise AssertionError('false-green fact preservation')
    changed_record = copy.deepcopy(record)
    changed_record['attempted_destination'] += 'lost history\n'
    try:
        check(changed_record, actual)
    except AssertionError as error:
        assert str(error) == 'exact historical attempted topic facts/questions', 'intended historical partition corruption'
    else:
        raise AssertionError('false-green attempted partition identity')
    print('PASS whole original facts/questions and bounded helper-join signpost; attempted topic partition retains exactly as historical evidence, owned collection rollover remains open.')


if __name__ == '__main__':
    main()
