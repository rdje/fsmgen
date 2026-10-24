#!/usr/bin/env python3
"""Exercise the actual original/repaired T383 helper on isolated metadata controls."""
import argparse
import copy
import gzip
import hashlib
import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
TEST = 't/383-contract-family-map-integrity-audit.t'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.parent != BASE or output.exists():
        raise SystemExit('Output must be a new file in this audit directory')
    before_path = BASE / 'diagnostic-map-repair-before.json.gz'
    before = json.loads(gzip.decompress(before_path.read_bytes()))
    original = before['test_before']
    repaired = (ROOT / TEST).read_text()
    capture = json.loads(gzip.decompress((BASE / 'model-roots-qualified.json.gz').read_bytes()))
    canonical = capture['native_api']['manifest']['diagnostics']['check_json']['source_optional_fields']
    fixtures = {}
    for owner in ('CheckDiagnosticsContract', 'NormalizedSemanticReportContract'):
        fixtures['valid_' + owner] = ({'contract_source': 'FSM::Support::' + owner,
            'source_optional_fields': copy.deepcopy(canonical),
            'presence_key_family_map': {'source_optional_fields': copy.deepcopy(canonical)}}, True)
    seed = fixtures['valid_CheckDiagnosticsContract'][0]
    for label in ('wrong_owner', 'wrong_map_name', 'wrong_family_name', 'missing_member',
                  'extra_member', 'missing_sibling', 'changed_sibling', 'array_instead_of_object',
                  'generic_object'):
        obj = copy.deepcopy(seed)
        if label == 'wrong_owner':
            obj['contract_source'] = 'FSM::Support::ReportSourceContract'
        elif label == 'wrong_map_name':
            obj['nested_presence_key_map'] = obj.pop('presence_key_family_map')
        elif label in ('wrong_family_name', 'generic_object'):
            obj['presence_key_family_map']['unpublished_fields'] = obj['presence_key_family_map'].pop('source_optional_fields')
        elif label == 'missing_member':
            obj['presence_key_family_map']['source_optional_fields'].pop('reductions')
        elif label == 'extra_member':
            obj['presence_key_family_map']['source_optional_fields']['invented'] = {}
        elif label == 'missing_sibling':
            obj.pop('source_optional_fields')
        elif label == 'changed_sibling':
            obj['source_optional_fields'] = {}
        elif label == 'array_instead_of_object':
            obj['presence_key_family_map']['source_optional_fields'] = list(canonical)
        fixtures[label] = (obj, False)
    fixtures['ordinary_array'] = ({'command_presence_keys': ['mode'],
        'presence_key_family_map': {'command_presence_keys': ['mode']}}, True)
    fixtures['duplicate_array'] = ({'command_presence_keys': ['mode', 'mode'],
        'presence_key_family_map': {'command_presence_keys': ['mode', 'mode']}}, False)
    fixtures['nested_array_value'] = ({'command_presence_keys': [['mode']],
        'presence_key_family_map': {'command_presence_keys': [['mode']]}}, False)
    runs = {}
    temp_root = ROOT / '.artifacts/tmp'
    temp_root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='diagnostic-map-controls-', dir=temp_root) as tmp:
        env = dict(os.environ, TMPDIR=tmp, TMP=tmp, TEMP=tmp)
        for phase, test_source in (('before', original), ('after', repaired)):
            # Retain the complete original/repaired helper code. Replace only
            # the two production callers with this isolated actual invocation.
            start = test_source.index("subtest 'direct support contracts")
            end = test_source.index('done_testing();', start) + len('done_testing();')
            runs[phase] = {}
            for label, (fixture, intended) in fixtures.items():
                raw = json.dumps(fixture, sort_keys=True)
                literal = "'" + raw.replace('\\', '\\\\').replace("'", "\\'") + "'"
                call = 'assert_family_map_integrity(decode_json(' + literal + "), 'isolated fixture');\ndone_testing();"
                probe = test_source[:start] + call + test_source[end:]
                path = Path(tmp) / (phase + '-' + label + '.pl')
                path.write_text(probe)
                command = ['perl', '-Iperl', path.relative_to(ROOT).as_posix()]
                result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, timeout=30)
                expected = (intended if phase == 'after' else
                            label in ('ordinary_array', 'array_instead_of_object'))
                if (result.returncode == 0) != expected:
                    raise ValueError('Unexpected actual helper result: ' + phase + '/' + label)
                runs[phase][label] = {'fixture': fixture, 'intended_valid': intended,
                    'expected_success_at_phase': expected, 'command': command,
                    'probe_source': probe, 'exit_status': result.returncode,
                    'stdout': result.stdout, 'stderr': result.stderr}
    record = {'schema': 'fsmgen.diagnostic_map_repair.v1', 'owner': before['owner'],
        'before_sha256': sha(before_path.read_bytes()), 'test_path': TEST,
        'test_before': original, 'test_after': repaired, 'runs': runs,
        'contract_sources': before['contract_sources'],
        'producer_source': Path(__file__).read_text(),
        'producer_sha256': sha(Path(__file__).read_bytes()),
        'limits': 'Isolated actual audit-helper metadata cases, not source compilation or a platform matrix.'}
    output.write_bytes(gzip.compress((json.dumps(record, sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Actual original/repaired helper controls match the declared cases; packet retained.')


if __name__ == '__main__':
    main()
