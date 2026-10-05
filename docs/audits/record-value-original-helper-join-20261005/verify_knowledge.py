"""Verify the exact atomic semantic partition of the established fact card."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-original-helper-join-20261005')


def validate(transform, source, destination):
    assert source == transform['source_after'], 'whole current source fact card'
    assert destination == transform['destination_after'], 'whole current destination fact card'
    for question in transform['moved_questions']:
        assert question not in source and destination.count(question) == 1, 'complete unique moved query routes'
    retained = transform['moved_body'].replace('Own\nobserver', 'Own observer')
    assert retained in destination, 'whole earlier observer/helper fact preservation'
    assert str(Path(transform['destination_path']).name) in source, 'direct canonical topic route'


def main():
    transform = json.loads((BASE / 'knowledge-transform.json').read_text())
    before = subprocess.check_output(['git', 'show', transform['revision'] + ':' + transform['source_path']], text=True)
    assert before == transform['source_before'], 'whole committed fact source'
    expected = before
    for question in transform['moved_questions']:
        assert expected.count(question + '\n') == 1
        expected = expected.replace(question + '\n', '')
    assert expected.count(transform['moved_body']) == 1
    expected = expected.replace(transform['moved_body'], 'Own observer and helper source meanings are canonical in the\n[observer/helper path card](record-value-original-observer-helper-paths.md).\n')
    expected = expected.replace('record-value-original-callback-paths-20261005', 'record-value-original-helper-join-20261005')
    assert expected == transform['source_after'], 'exact whole fact source partition recipe'
    source, destination = (Path(transform[key]).read_text() for key in ('source_path', 'destination_path'))
    validate(transform, source, destination)
    for bad_source, bad_destination, cause in (
        (source + 'borrowed\n', destination, 'whole current source fact card'),
        (source, destination.replace(transform['moved_questions'][0] + '\n', ''), 'whole current destination fact card'),
        (source, destination.replace('parser receiver role is declared', 'parser receiver identity is established'), 'whole current destination fact card'),
    ):
        assert (bad_source, bad_destination) != (source, destination), 'genuine fact corruption'
        try:
            validate(transform, bad_source, bad_destination)
        except AssertionError as error:
            assert str(error) == cause, 'intended fact partition control'
        else:
            raise AssertionError('false-green fact partition')
    print('PASS complete original fact/question preservation and exact semantic partition; actual source/member/identity corruptions reject.')


if __name__ == '__main__':
    main()
