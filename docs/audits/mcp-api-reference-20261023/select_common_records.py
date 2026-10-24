#!/usr/bin/env python3
"""Reproduce the dated shared-record cohort selection without rerunning producers."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PREFIX = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.'
CAPTURE = BASE / 'model-roots-qualified.json.gz'
SELECTION = BASE / 'common-shell-selection.json'
OUTPUT = BASE / 'common-record-cohorts.json'

SECTION_PATHS = {
    '/backend_validation/section_contract', '/diagnostics/section_contract',
    '/documentation/section_contract', '/embedding/section_contract',
    '/language_surface/surface_contract', '/semantic_exports/section_contract',
}
ENRICHED_PATHS = {
    '/backend_validation/systemverilog_external', '/diagnostics/check_json',
    '/diagnostics/stable_code_registry', '/semantic_exports/normalized_semantic_json',
    '/semantic_introspection', '/semantic_introspection/section_contract',
    '/support_accounting', '/support_accounting/section_contract',
    '/verification_outputs', '/verification_outputs/section_contract',
}
PRIOR_PATHS = {'/manifest_contract', '/producer/section_contract'}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def at(value, path):
    for token in path.split('/')[1:]:
        value = value[token.replace('~1', '/').replace('~0', '~')]
    return value


def candidates(value, parent=''):
    """Independent expansion of the original explicit candidate predicate."""
    found = set()
    if type(value) is dict:
        if {'contract_source', 'schema_version', 'status'} <= value.keys():
            found.add(parent)
        for key, child in value.items():
            token = key.replace('~', '~0').replace('/', '~1')
            found.update(candidates(child, parent + '/' + token))
    elif type(value) is list:
        for index, child in enumerate(value):
            found.update(candidates(child, parent + '/' + str(index)))
    return found


def build():
    capture_bytes = CAPTURE.read_bytes()
    selection_bytes = SELECTION.read_bytes()
    selection = json.loads(selection_bytes)
    capture = json.loads(gzip.decompress(capture_bytes))
    manifest = capture['native_api']['manifest']
    paths = [row['pointer'] for row in selection['contract_records']]
    if len(set(paths)) != len(paths) or set(paths) != candidates(manifest):
        raise ValueError('Original selection differs from complete native candidates')
    if selection['capture_sha256'] != sha(capture_bytes):
        raise ValueError('Original capture custody mismatch')
    groups = {PREFIX + '1': [], **{PREFIX + '2.' + str(i): [] for i in range(2, 6)}}
    for row in selection['contract_records']:
        path = row['pointer']
        actual = at(manifest, path)
        if row['owner'] != actual['contract_source'] or row['status'] != actual['status']:
            raise ValueError('Original owner/status mismatch: ' + path)
        if row['entrypoint_labels'] != sorted(actual.get('entrypoints', {})):
            raise ValueError('Original entrypoint-label mismatch: ' + path)
        if path in PRIOR_PATHS:
            owner = PREFIX + '1'
        elif path in SECTION_PATHS:
            owner = PREFIX + '2.2'
        elif path in ENRICHED_PATHS:
            owner = PREFIX + '2.3'
        elif path.startswith('/embedding/'):
            owner = PREFIX + '2.4'
        elif path.startswith('/language_surface/') or '/contract_surface_map/vial_source_' in path:
            owner = PREFIX + '2.5'
        else:
            raise ValueError('Unclassified candidate: ' + path)
        groups[owner].append({**row, 'field_names': sorted(actual),
            'entrypoint_fields': {k: actual[k] for k in
                ('entrypoint', 'entrypoints', 'implementation_entrypoints') if k in actual},
            'guidance_present': 'guidance' in actual})
    for expected, owner in ((PRIOR_PATHS, PREFIX + '1'),
                            (SECTION_PATHS, PREFIX + '2.2'),
                            (ENRICHED_PATHS, PREFIX + '2.3')):
        if {row['pointer'] for row in groups[owner]} != expected:
            raise ValueError('Explicit cohort membership changed: ' + owner)
    return {'schema': 'fsmgen.common_record_cohorts.v1', 'owner': PREFIX + '2.1',
        'capture': CAPTURE.relative_to(ROOT).as_posix(), 'capture_sha256': sha(capture_bytes),
        'capture_head': capture['head'],
        'selection': SELECTION.relative_to(ROOT).as_posix(), 'selection_sha256': sha(selection_bytes),
        'cohorts': groups,
        'scope': 'Structural selection only. Each record occurs once, including prior root/producer exclusions. Common-field semantics remain the named successors; all remaining fields retain the parent metadata/report/VIAL owners.',
        'evidence_legs': {
            'rederive': 'Reproduce exact cohorts from the retained complete candidate list and native metadata capture.',
            'falsify': 'Independently traverse complete native objects using the explicit candidate predicate, then compare unique paths, per-path owner/status and actual entrypoint labels/values.',
            'durability': 'Tracked original capture/selection, this deterministic selector, exact per-record cohort data, task and Git. No new runtime or source epoch.'},
        'reverify': 'python3 -B docs/audits/mcp-api-reference-20261023/select_common_records.py --check'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    raw = (json.dumps(build(), sort_keys=True, indent=2) + '\n').encode()
    if args.check:
        if OUTPUT.read_bytes() != raw:
            raise SystemExit('Saved shared-record cohorts differ from their sources')
        print('Shared-record selection: exact complete per-path cohort join passes.')
    else:
        with OUTPUT.open('xb') as stream:
            stream.write(raw)
        print('Wrote shared-record selection; semantic census remains pending.')


if __name__ == '__main__':
    main()
