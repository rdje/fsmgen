#!/usr/bin/env python3
"""Verify zero-reason preservation, empty fallback and complete error conservation."""
import copy
import gzip
import json
from pathlib import Path
import sys

from verify_error_context import ADAPTER, PROBE, canonical, controls, expected_request, frames, source, verify

NAMES = ('callback_zero', 'callback_empty', 'callback_control_only')
AUTHORED = ('0\n', '\n', '\x00\n')
FALLBACK = 'FSMGen MCP adapter error'


def verify_zero(record, repaired):
    legacy = verify(record)
    assert not legacy['findings'], 'existing message defect remains'
    assert record['include_zero'] is True
    assert record['relocation']['owner'] == 'PERL-POD-API-REFERENCE.6.1.2.2.5.4'
    checked = []
    for run in record['runs']:
        assert [c['case'] for c in run['zero_stdio']] == list(NAMES), 'zero case population mismatch'
        for name, authored, row in zip(NAMES, AUTHORED, run['zero_stdio']):
            request = expected_request('callback_plain', 1)
            ping = expected_request('ping', 2)
            assert canonical(row['requests']) == canonical([request, ping]), 'zero request mismatch'
            frames(row['sent_utf8'], row['capture']['stdout_utf8'], row['requests'], row['responses'])
            assert row['capture']['exit_status'] == 0
            expected_message = '0' if repaired and name == 'callback_zero' else FALLBACK
            assert canonical(row['responses']) == canonical([
                {'jsonrpc': '2.0', 'id': 1, 'error': {'code': -32000, 'message': expected_message}},
                {'jsonrpc': '2.0', 'id': 2, 'result': {}}]), 'zero reason envelope/value mismatch'
            assert json.loads(row['capture']['stderr_utf8']) == {'probe_native_events': row['native_events']}
            assert len(row['native_events']) == 1
            event = row['native_events'][0]
            assert event['exception'] == authored, 'authored zero/empty exception changed'
            assert event['origin_file_label'] == run['implementation_root_label'] + '/' + PROBE
            assert type(event['origin_line']) is int and event['origin_line'] > 0
            assert type(event['input_record']) is int and event['input_record'] == 1
            checked.append({'root': run['root_kind'], 'case': name, 'responses': row['responses']})
    return legacy, checked


def compare(before, after):
    old, original_zero = verify_zero(before, False)
    new, repaired_zero = verify_zero(after, True)
    assert before['head'] == after['head']
    assert set(before['native_source_overrides']) == set()
    assert set(after['native_source_overrides']) == {ADAPTER}
    assert set(before['source_sha256']) == set(after['source_sha256'])
    for path, digest in before['source_sha256'].items():
        if path != ADAPTER:
            assert after['source_sha256'][path] == digest, 'unrelated selected source changed'
    old_runtime, new_runtime = [source(r, ADAPTER).decode().split('\n__END__', 1)[0] for r in (before, after)]
    original = "        return _jsonrpc_error_response($id, -32000, $error || 'FSMGen MCP adapter error');"
    replacement = "        $error = 'FSMGen MCP adapter error' unless length($error);\n        return _jsonrpc_error_response($id, -32000, $error);"
    assert old_runtime.count(original) == 1
    assert new_runtime == old_runtime.replace(original, replacement), 'unrelated runtime changed'
    for ro, rn in zip(before['runs'], after['runs']):
        assert ro['root_kind'] == rn['root_kind']
        assert canonical(ro['api']['cases']) == canonical(rn['api']['cases'])
        for go, gn in zip(ro['api']['groups'], rn['api']['groups']):
            assert go['context'] == gn['context']
            for o, n in zip(go['rows'], gn['rows']):
                assert o['request_before_json'] == n['request_before_json']
                assert canonical(o['response']) == canonical(n['response']), 'existing API response changed'
        assert canonical(ro['one_shot']) == canonical(rn['one_shot']), 'existing one-shot response changed'
        assert canonical(ro['persistent']) == canonical(rn['persistent']), 'existing persistent exchange changed'
        for o, n in zip(ro['custom_stdio'], rn['custom_stdio']):
            assert o['case'] == n['case'] and o['sent_utf8'] == n['sent_utf8']
            assert canonical(o['responses']) == canonical(n['responses']), 'existing custom response changed'
    conserved = new['checked_responses']
    changed = 0
    for o, n in zip(original_zero, repaired_zero):
        assert o['root'] == n['root'] and o['case'] == n['case']
        expected = copy.deepcopy(o['responses'])
        if o['case'] == 'callback_zero':
            expected[0]['error']['message'] = '0'
            changed += 1
        assert canonical(n['responses']) == canonical(expected)
        conserved += len(n['responses']) - (o['case'] == 'callback_zero')
    return {'selected_sources': new['selected_sources'], 'copied_files': new['copied_files'],
            'zero_reasons_repaired': changed, 'complete_responses_conserved': conserved,
            'zero_empty_controls': repaired_zero}


def repair_controls(before, after):
    rejected = []
    for name in ('restored_zero_loss', 'zero_number', 'overwritten_empty', 'borrowed_source'):
        bad = copy.deepcopy(after)
        row = bad['runs'][0]['zero_stdio'][1 if name == 'overwritten_empty' else 0]
        if name == 'borrowed_source':
            bad['source_sha256'][ADAPTER] = before['source_sha256'][ADAPTER]
            bad['native_source_overrides'][ADAPTER] = source(before, ADAPTER).decode()
            bad['relocation']['files'][ADAPTER] = copy.deepcopy(before['relocation']['files'][ADAPTER])
        else:
            row['responses'][0]['error']['message'] = {
                'restored_zero_loss': FALLBACK, 'zero_number': 0, 'overwritten_empty': '0'}[name]
            row['capture']['stdout_utf8'] = ''.join(json.dumps(r) + '\n' for r in row['responses'])
        try:
            compare(before, bad)
        except AssertionError as error:
            expected = 'unrelated runtime changed' if name == 'borrowed_source' else 'zero reason envelope/value mismatch'
            assert str(error) == expected, (name, str(error))
            rejected.append(name)
        else:
            raise AssertionError('Control accepted: ' + name)
    return rejected


def verify_legacy_route(after, legacy):
    result = verify(legacy)
    assert not result['findings'] and legacy['include_zero'] is False
    assert legacy['source_sha256'] == after['source_sha256']
    for old, new in zip(after['runs'], legacy['runs']):
        assert old['root_kind'] == new['root_kind'] and new['zero_stdio'] == []
        def public_responses(run):
            return [[r['response'] for g in run['api']['groups'] for r in g['rows']],
                    [r['response'] for r in run['one_shot']], run['persistent']['responses'],
                    [r['responses'] for r in run['custom_stdio']]]
        assert canonical(public_responses(old)) == canonical(public_responses(new)), 'legacy collector result changed'
    return {'checked_responses': result['checked_responses'], 'reader_controls': controls(legacy)}


if __name__ == '__main__':
    assert len(sys.argv) in (3, 4)
    before, after = [json.loads(gzip.decompress(Path(p).read_bytes())) for p in sys.argv[1:3]]
    result = compare(before, after)
    result['original_reader_controls'] = controls(before)
    result['repaired_reader_controls'] = controls(after)
    result['repair_controls'] = repair_controls(before, after)
    if len(sys.argv) == 4:
        legacy = json.loads(gzip.decompress(Path(sys.argv[3]).read_bytes()))
        result['legacy_route'] = verify_legacy_route(after, legacy)
    print(json.dumps(result, indent=2))
