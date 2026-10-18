"""Post-result hostile controls; never imported by the native intake."""
import base64
import copy
import gzip
import hashlib
import importlib.util
import json
from pathlib import Path

AUDIT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('boundary_reader', AUDIT / 'verify.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)


def blob(body):
    return {'bytes': len(body), 'sha256': hashlib.sha256(body).hexdigest(),
            'body_base64': base64.b64encode(body).decode()}


def change_receipt(record, label, mutate):
    """Keep receipt/capture hashes valid while changing semantic content."""
    captures = record['captures']
    row = json.loads(reader.unblob(captures[label + '.json']))
    mutate(row)
    body = json.dumps(row, sort_keys=True).encode()
    captures[label + '.json'] = blob(body)
    summary = json.loads(reader.unblob(captures['summary.json']))
    matches = [item for item in summary['receipts'] if item['label'] == label]
    assert len(matches) == 1
    matches[0]['sha256'] = hashlib.sha256(body).hexdigest()
    captures['summary.json'] = blob(json.dumps(summary, sort_keys=True).encode())


record = json.loads(gzip.decompress((AUDIT / 'result.json.gz').read_bytes()))
assert reader.validate(record)
for name in ('source', 'primary_index', 'lost_capture', 'coverage', 'sibling_green', 'cleanup'):
    bad = copy.deepcopy(record)
    if name == 'source':
        path = next(iter(bad['sources_before']))
        changed = blob(reader.unblob(bad['sources_before'][path]) + b'\n# changed input\n')
        bad['sources_before'][path] = bad['sources_after'][path] = changed
    elif name == 'primary_index':
        bad['git_after']['index'] = blob(b'changed primary index')
    elif name == 'lost_capture':
        del bad['captures']['events.jsonl']
    elif name == 'coverage':
        summary = json.loads(reader.unblob(bad['captures']['summary.json']))
        summary['actual'] = [8, 90, 9]
        bad['captures']['summary.json'] = blob(json.dumps(summary).encode())
    elif name == 'sibling_green':
        def promote(row):
            row['result']['checker'].update(exit_code=0, ok=1)
        change_receipt(bad, 'case_a', promote)
        change_receipt(bad, 'stage_k', lambda row: row['result'].update(exit_code=0, ok=1))
    else:
        def unsettled(row):
            row['result']['stages'][0]['cleanup']['group_gone'] = 0
        change_receipt(bad, 'case_a', unsettled)
        change_receipt(bad, 'stage_a', lambda row: row['result']['cleanup'].update(group_gone=0))
    try:
        reader.validate(bad)
    except (AssertionError, KeyError, ValueError):
        print('Rejected hostile saved record:', name)
        continue
    raise AssertionError('hostile record admitted: ' + name)
print('Complete saved boundary record passes; semantic hostile controls reject without native execution.')
