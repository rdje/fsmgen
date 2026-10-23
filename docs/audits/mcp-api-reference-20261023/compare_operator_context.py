#!/usr/bin/env python3
"""Join the case-context repair to complete original and repaired public errors."""
import copy
import gzip
import json
from pathlib import Path
import sys

from compare_error_context import LEGACY_CAPITALIZED
from verify_error_context import ADAPTER, EXPECTED, NAMES, canonical, controls, source, verify


def compare(before, after):
    old, new = verify(before), verify(after)
    assert len(old['findings']) == 8 and all(f['case'] == 'callback_external_path'
        and f['actual'] == LEGACY_CAPITALIZED for f in old['findings']), 'incoming gap changed'
    assert not new['findings'], 'operator/location/preservation defect remains'
    assert set(before['source_sha256']) == set(after['source_sha256'])
    for path, digest in before['source_sha256'].items():
        if path != ADAPTER:
            assert after['source_sha256'][path] == digest, 'unrelated selected source changed'
    expected_runtime = source(before, ADAPTER).decode().split('\n__END__', 1)[0]
    for start in (r'my $operator_context = $prefix =~ /\boperator\s*\z/',
                  r'''|| $prefix =~ /\boperators(?:\s+currently)?\s+include\s+(?:(['"])[^'"\r\n]+\1,\s*)*\z/'''):
        assert expected_runtime.count(start) == 1
        expected_runtime = expected_runtime.replace(start, start + 'i')
    assert expected_runtime == source(after, ADAPTER).decode().split('\n__END__', 1)[0], 'unrelated runtime changed'
    assert after['relocation']['owner'] == 'PERL-POD-API-REFERENCE.6.1.2.2.5.3'
    affected, conserved = 0, 0

    def response(old_response, new_response, case):
        nonlocal affected, conserved
        expected = copy.deepcopy(old_response)
        if case == 'callback_external_path':
            expected['error']['message'] = EXPECTED[NAMES.index(case)]
            affected += 1
        else:
            conserved += 1
        assert canonical(new_response) == canonical(expected), 'complete response changed unexpectedly'

    for ro, rn in zip(before['runs'], after['runs']):
        assert ro['root_kind'] == rn['root_kind']
        assert canonical(ro['api']['cases']) == canonical(rn['api']['cases'])
        for go, gn in zip(ro['api']['groups'], rn['api']['groups']):
            assert go['context'] == gn['context']
            for old_row, new_row in zip(go['rows'], gn['rows']):
                assert old_row['request_before_json'] == new_row['request_before_json']
                response(old_row['response'], new_row['response'], old_row['case'])
        for i, (old_row, new_row) in enumerate(zip(ro['one_shot'], rn['one_shot'])):
            response(old_row['response'], new_row['response'], NAMES[i])
        assert ro['persistent']['sent_utf8'] == rn['persistent']['sent_utf8']
        assert ro['persistent']['received_utf8'] == rn['persistent']['received_utf8']
        for i, (o, n) in enumerate(zip(ro['persistent']['responses'], rn['persistent']['responses'])):
            response(o, n, (NAMES[:4] + ['ping'])[i])
        for old_row, new_row in zip(ro['custom_stdio'], rn['custom_stdio']):
            assert old_row['case'] == new_row['case']
            assert old_row['sent_utf8'] == new_row['sent_utf8']
            for o, n, name in zip(old_row['responses'], new_row['responses'], [old_row['case'], 'ping']):
                response(o, n, name)
    assert affected + conserved == new['checked_responses']
    return {'selected_sources': new['selected_sources'], 'copied_files': new['copied_files'],
            'repaired_context_responses': affected, 'complete_responses_conserved': conserved,
            'remaining_selected_findings': new['findings']}


def repair_controls(before, after):
    rejected = []
    for name in ('restored_capitalized_loss', 'unredacted_path', 'lost_authored_location', 'changed_ping'):
        bad = copy.deepcopy(after)
        run = bad['runs'][0]
        rows = run['api']['groups'][0]['rows']
        if name == 'restored_capitalized_loss':
            rows[9]['response']['error']['message'] = LEGACY_CAPITALIZED
        elif name == 'unredacted_path':
            rows[9]['response']['error']['message'] = "Operator '/' while opening '/outside/private dir/source.fsm'"
        elif name == 'lost_authored_location':
            rows[5]['response']['error']['message'] = 'Authored diagnostic'
        else:
            rows[-1]['response']['result'] = {'different': True}
        run['api_capture']['stdout_utf8'] = json.dumps(run['api'])
        try:
            compare(before, bad)
        except AssertionError as error:
            expected = 'ping changed' if name == 'changed_ping' else 'operator/location/preservation defect remains'
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
    print(json.dumps(result, indent=2))
