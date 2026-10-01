"""Verify final public/cohort closure against independent fixed identities."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SOURCES = sorted(['isf/apb_requester.isf', 'isf/interface_port_metadata.isf',
                  'isf/record_input.isf', 'isf/record_input_children.isf',
                  'isf/storage_fields.isf', 'isf/storage_word_access.isf',
                  'isf/verification_observation_metadata.isf'])
DESCRIPTOR = {
    'entry_keys': ['name', 'direction', 'width'],
    'optional_entry_keys': ['type', 'type_kind', 'domain', 'fields'],
    'direction_values': ['input', 'output'],
    'type_kind_values': ['bit', 'bits', 'record'],
    'field_keys': ['path', 'width', 'lsb', 'msb', 'signed'],
    'optional_field_keys': ['state_model'],
    'field_signed_values': [0, 1],
    'field_state_model_values': ['two_state', 'four_state'],
    'shape': 'declared inputs in source order followed by declared outputs in source order; empty for a known empty interface; null when declaration metadata is unknown',
    'field_layout': 'record scalar leaves in authored traversal order; port-relative member/item paths; first leaf most significant; inclusive packed ranges',
    'meaning': 'declared ISF interface metadata; no inferred signals, private handoffs, source admission or hardware behavior is established by this projection',
}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'))


def contracts(rows, discovery):
    assert sorted(row['source_id'] for row in rows) == SOURCES
    for row in rows:
        assert row['file_kind'] == row['source_kind'] == 'isf'
        assert row['query_kinds'] == ['check', 'semantic', 'schedule']
        assert row['strict'] is True and row['language_version'] is None
        assert row['search_path_relpaths'] == []
    assert {'feature.isf_declared_interface_metadata', 'feature.isf_record_input',
            'feature.isf_record_input_children'} <= {entry['id'] for row in rows for entry in row['catalog_entries']}
    assert canonical(discovery['embedding']['isf_public_interface']['schedule_report_interface_ports']) == canonical(DESCRIPTOR)
    for surface in (discovery['diagnostics']['check_json'],
                    discovery['semantic_exports']['normalized_semantic_json']):
        assert canonical(surface['source_optional_fields']['interface_ports']) == canonical(DESCRIPTOR)
        assert canonical(surface['presence_key_family_map']['source_optional_fields']['interface_ports']) == canonical(DESCRIPTOR)


def rejected(rows, discovery):
    try:
        contracts(rows, discovery)
    except AssertionError:
        return
    raise AssertionError('incomplete cohort or corrupted discovery accepted')


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert manifest['schema'] == 'fsmgen.record_input_public_reconciliation.v1'
    assert manifest['baseline_revision'] == 'f69a464cfdcbe00128bb3923cbd6921a913887c4'
    files = {path.name for path in HERE.iterdir() if path.is_file() and path.name != 'manifest.json'}
    assert files == set(manifest['sha256'])
    for name, digest in manifest['sha256'].items():
        assert sha((HERE / name).read_bytes()) == digest
    for path, identity in manifest['producers'].items():
        blob = subprocess.check_output(['git', 'rev-parse', manifest['baseline_revision'] + ':' + path], cwd=ROOT).decode().strip()
        assert blob == identity['git_blob']
        assert sha(subprocess.check_output(['git', 'cat-file', 'blob', blob], cwd=ROOT)) == identity['sha256']
    for path, digest in manifest['prerequisites'].items():
        assert sha((ROOT / path).read_bytes()) == digest
        parent = json.loads((ROOT / path).read_bytes())
        for name, expected in parent['sha256'].items():
            assert sha((ROOT / path).parent.joinpath(name).read_bytes()) == expected
    equivalence = json.loads((HERE / 'source-equivalence.json').read_bytes())
    assert equivalence['baseline_revision'] == manifest['baseline_revision']
    assert equivalence['argv'] == ['git', 'diff', '--exit-code', manifest['baseline_revision'], '--', 'bin', 'perl', 't', 'isf']
    assert equivalence['exit_code'] == 0 and equivalence['stdout'] == equivalence['stderr'] == ''
    rows = json.loads((HERE / 'cohort.json').read_bytes())
    discovery = json.loads((HERE / 'discovery.json').read_bytes())
    contracts(rows, discovery)
    bad = copy.deepcopy(rows)
    bad.pop()
    rejected(bad, discovery)
    bad = copy.deepcopy(rows)
    bad[0]['query_kinds'].pop()
    rejected(bad, discovery)
    for field in ('field_keys', 'optional_field_keys', 'type_kind_values'):
        bad = copy.deepcopy(discovery)
        bad['embedding']['isf_public_interface']['schedule_report_interface_ports'][field].pop()
        rejected(rows, bad)
    bad = copy.deepcopy(discovery)
    bad['semantic_exports']['normalized_semantic_json']['source_optional_fields']['interface_ports']['field_signed_values'] = ['0', '1']
    rejected(rows, bad)
    bad = copy.deepcopy(discovery)
    bad['embedding']['isf_public_interface']['schedule_report_interface_ports']['field_signed_values'] = [False, True]
    rejected(rows, bad)
    receipt = (HERE / 'public.txt').read_text()
    assert 'All tests successful.' in receipt and 'Files=3, Tests=7214,' in receipt
    assert 'Result: PASS' in receipt and 'Result: FAIL' not in receipt
    for test in ('2017-isf-record-input-frontend-closure', '248-regression-corpus-accounting', '2018-semantic-public-json-scalar-kinds'):
        assert re.search(r't/' + re.escape(test) + r'\.t\s+\.+ ok', receipt)
    assert 'Complete scoped requirement crosswalk, exact baseline source objects and public/scalar/storage regression authenticated.' in (HERE / 'prior-saved.txt').read_text()
    assert (HERE / 'matrix-history.txt').read_text().startswith('aebe0037554eb9995c1d4fa67f4ec53f98364520 ')
    assert manifest['matrix_predecessor'] == manifest['producers']['docs/book/src/13k-isf-feature-support-matrix.md']
    old = subprocess.check_output(['git', 'cat-file', 'blob', manifest['matrix_predecessor']['git_blob']], cwd=ROOT).decode()
    current = (HERE / 'matrix.md.source').read_text()
    stale = 'Generated/domain contextual refusal and final prior-product closure, backend/native and consumer completion remain separately owned.'
    assert stale in old and stale not in current
    assert 'Final input signoff and full output/consumer delivery remain open; X/Z execution is unclaimed.' in current
    assert '| Packed record actor inputs | source admitted; qualification pending |' in old and '| Packed record actor inputs | source admitted; qualification pending |' in current
    assert 'Record outputs and their writer contracts remain open; root-list ports and variants are optional.' in current
    old_lines, new_lines = old.splitlines(), current.splitlines()
    assert len(old_lines) == len(new_lines)
    changed = [(a, b) for a, b in zip(old_lines, new_lines) if a != b]
    assert [a.split('|')[1].strip() for a, b in changed] == ['Record interface ports', 'Packed record actor inputs']
    print('Complete current ISF cohort and literal discovery descriptors authenticate; fresh supplied-source/all-discovery/catalog/JSON-kind checks and unchanged complete-cohort/prior evidence pass. Hostile membership/applicability/schema/kind controls reject. Only stale matrix rows change; final input signoff and output/consumer delivery remain open.')


if __name__ == '__main__':
    main()
