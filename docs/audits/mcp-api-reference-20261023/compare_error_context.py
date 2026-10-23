#!/usr/bin/env python3
"""Qualify the bounded formatter repair against its complete original capture."""
import copy
import gzip
import json
from pathlib import Path
import sys

from verify_error_context import ADAPTER, COLLECTOR, canonical, controls, source, verify

LEGACY_CAPITALIZED = "Operator '[absolute-path-redacted]' while opening '[absolute-path-redacted]'"


def without_formatter(raw):
    text = raw.decode().split('\n__END__', 1)[0]
    left, right = text.split('\nsub _strip_perl_error_location {', 1)
    _, tail = right.split('\n}\n', 1)
    return (left + '\n' + tail).replace('        chomp $error;\n', '')


def compare(before, after):
    original, repaired = verify(before), verify(after)
    assert set(before['source_sha256']) == set(after['source_sha256'])
    assert set(before['native_source_overrides']) == set()
    assert set(after['native_source_overrides']) == {ADAPTER}
    for path, digest in before['source_sha256'].items():
        if path not in (ADAPTER, COLLECTOR):
            assert after['source_sha256'][path] == digest, 'unrelated selected source changed'
    assert without_formatter(source(before, ADAPTER)) == without_formatter(source(after, ADAPTER)), 'unrelated runtime changed'
    assert after['relocation']['owner'] == 'PERL-POD-API-REFERENCE.6.1.2.2.5.2'
    for finding in repaired['findings']:
        assert finding['case'] == 'callback_external_path' and finding['actual'] == LEGACY_CAPITALIZED, 'location/preservation defect remains'
    assert len(repaired['findings']) == 8, 'known capitalized-context population changed'
    for old, new in zip(before['runs'], after['runs']):
        assert old['root_kind'] == new['root_kind']
        assert canonical(old['api']['cases']) == canonical(new['api']['cases'])
        for go, gn in zip(old['api']['groups'], new['api']['groups']):
            assert go['context'] == gn['context']
            for ro, rn in zip(go['rows'], gn['rows']):
                assert ro['request_before_json'] == rn['request_before_json']
                if ro['case'] == 'ping' or ro['case'].startswith('callback_long_'):
                    assert canonical(ro['response']) == canonical(rn['response']), 'positive/bounded response changed'
        assert old['persistent']['sent_utf8'] == new['persistent']['sent_utf8']
    return {'original_findings': original['findings'], 'remaining_owned_capitalized_context': repaired['findings'],
            'checked_responses_per_capture': repaired['checked_responses'],
            'selected_sources': repaired['selected_sources'], 'copied_files': repaired['copied_files']}


def repair_controls(before, after):
    rejected = []
    for name in ('restored_location', 'stripped_authored_reason', 'lost_operator', 'wrong_error_code'):
        bad = copy.deepcopy(after)
        run = bad['runs'][0]
        index = 5 if name == 'stripped_authored_reason' else 4
        row = run['api']['groups'][1]['rows'][index]
        if name == 'restored_location':
            row['response'] = copy.deepcopy(before['runs'][0]['api']['groups'][1]['rows'][index]['response'])
        elif name == 'stripped_authored_reason':
            row['response']['error']['message'] = 'Authored diagnostic'
        elif name == 'lost_operator':
            row['response']['error']['message'] = "Callback rejected operator '[absolute-path-redacted]'"
        else:
            row['response']['error']['code'] = -32602
        run['api_capture']['stdout_utf8'] = json.dumps(run['api'])
        try:
            compare(before, bad)
        except AssertionError as error:
            expected = 'error class changed' if name == 'wrong_error_code' else 'location/preservation defect remains'
            assert str(error) == expected, (name, str(error))
            rejected.append(name)
        else:
            raise AssertionError('Control accepted: ' + name)
    return rejected


if __name__ == '__main__':
    assert len(sys.argv) == 3
    before, after = [json.loads(gzip.decompress(Path(p).read_bytes())) for p in sys.argv[1:]]
    result = compare(before, after)
    result['original_reader_controls'] = controls(before)
    result['repaired_reader_controls'] = controls(after)
    result['repair_controls'] = repair_controls(before, after)
    print(json.dumps(result, ensure_ascii=False, indent=2))
