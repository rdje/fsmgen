#!/usr/bin/env python3
"""Read the retained target-only source observation; never run source or HDL."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
RECEIPT = Path(__file__).with_name('receipt.json.gz')
MODULE = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/SourceLiteralWidthSupport.pm'
TEST = 't/2261-target-source-literal-width.t'


def digest(text):
    return hashlib.sha256(text.encode()).hexdigest()


def observation(record):
    assert record['kind'] == 'systemverilog_source_literal_width'
    assert record['selected_width'] == '32' and type(record['selected_width']) is str
    assert record['literal_floor'] == '32' and record['leaf_floor'] == '16'
    assert [row['source']['name'] for row in record['leaves']] == ['A', 'B']
    assert [row['source']['width'] for row in record['leaves']] == ['8', '16']
    assert len(record['literals']) == 1
    literal = record['literals'][0]
    assert literal['literal'] == {'value': 256, 'width': None, 'radix': 'decimal'}
    assert type(literal['literal']['value']) is int
    assert literal['width'] == '32' and literal['sizing'] == 'target_unsized'
    assert [row['width'] for row in record['helper_widths']] == ['32', '32']
    assert len(record['reference_widths']) == 1 and record['reference_widths'][0]['width'] == '32'
    state = json.loads(record['source_capsule']['state'])
    assert state['signal']['identity_token'] == record['source_identity']
    assert state['record'] == record['source_capsule']['record']
    edge = record['reference_widths'][0]
    assert edge['parent_identity'] == record['source_identity']
    assert edge['reference_identity'] == state['children'][0]['reference_identity']
    assert edge['signal_identity'] == state['children'][0]['signal_identity']
    assert state['children'][0]['phase'] == 'completed'
    assert state['record']['selected_width'] is None
    assert state['record']['expression_tree'] == ['^', ['|', ['signal', 'A'], ['literal', literal['literal']]], ['signal', 'B']]


def verify(record, current=False):
    assert record['schema'] == 'fsmgen.target_source_literal_width.v1'
    card = record['card_consolidation']
    for key in ('before', 'rejected', 'after', 'removed_duplicate'):
        assert digest(card[key]['text']) == card[key]['sha256']
    questions = lambda text: [line for line in text.splitlines() if line.startswith('  - "')]
    assert questions(card['before']['text']) == questions(card['after']['text'])
    assert card['removed_duplicate']['text'] in card['rejected']['text']
    assert card['canonical_path'] in card['after']['text']
    assert len(card['after']['text'].splitlines()) <= len(card['before']['text'].splitlines())
    if current:
        assert (ROOT / 'docs/knowledge/core-expression-width-inference.md').read_text() == card['after']['text']
    for collection in ('sources', 'artifacts', 'variants'):
        for path, item in record[collection].items():
            assert not Path(path).is_absolute() and '..' not in Path(path).parts
            assert digest(item['text']) == item['sha256'], path
            if current and collection == 'sources':
                assert (ROOT / path).read_bytes() == item['text'].encode(), path
    observation(json.loads(record['artifacts']['observation.json']['text']))
    source = record['sources'][MODULE]['text']
    for name, old, new in (
        ('bad-barrier', 'FSM::SourceLiteralWidthAllocationSupport::_unchanged($capture->{walk})', '1'),
        ('bad-floor', 'sub _unsized_literal_width { return 32 }', 'sub _unsized_literal_width { return 1 }'),
    ):
        assert source.count(old) == 1
        assert record['variants'][name]['text'] == source.replace(old, new)
        assert 'Result: FAIL' in record['artifacts'][name + '.log']['text']
    assert 'write to an earlier source during later target inference withholds' in record['artifacts']['bad-barrier.log']['text']
    assert 'actual completed fixed and mutable Parser and facade sources keep independent floors' in record['artifacts']['bad-floor.log']['text']
    assert 'All tests successful.' in record['artifacts']['final-focused.log']['text']
    assert 'Files=2, Tests=11' in record['artifacts']['final-focused.log']['text']
    assert 'Result: PASS' in record['artifacts']['final-focused.log']['text']
    assert 'SourceLiteralWidthSupport.pm' in record['artifacts']['corrected-red.log']['text']
    assert 'Result: FAIL' in record['artifacts']['corrected-red.log']['text']
    assert record['statuses'] == {'focused': 0, 'bad-barrier': 1, 'bad-floor': 1, 'book': 0}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true', help='check only the recorded producer identities')
    parser.add_argument('--qualify', action='store_true', help='reject hostile saved observation records')
    args = parser.parse_args()
    with gzip.open(RECEIPT, 'rt') as stream:
        record = json.load(stream)
    verify(record, args.current)
    if args.qualify:
        sample = json.loads(record['artifacts']['observation.json']['text'])
        for mutate in (lambda r: r.update(selected_width=True), lambda r: r.update(literal_floor='16'),
                       lambda r: r['literals'][0]['literal'].update(value='256')):
            wrong = copy.deepcopy(sample)
            mutate(wrong)
            try:
                observation(wrong)
            except AssertionError:
                continue
            raise AssertionError('hostile saved observation accepted')
    print('target-source-literal-width: retained source, target-only observation and distinguishing controls agree; no live HDL execution')


if __name__ == '__main__':
    main()
