#!/usr/bin/env python3
"""Capture the combined shared-family join without rerunning source producers."""
import argparse
import copy
import gzip
import json
from pathlib import Path
import sys

from build_diagnostic_families import sha, snapshot

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.5.5'
API = 'docs/book/src/11a-perl-api-reference.md'
CORE = 'docs/book/src/11-extensions-and-embedding.md'
POD = 'perl/FSM/Support/CapabilityManifest.pm'
COHORTS = ('shared-candidate-qualified.json.gz', 'shared-drive-final-qualified.json.gz',
           'shared-aggregate-qualified.json.gz')
INPUTS = ('shared-datapath-partition.json.gz', 'model-roots-qualified.json.gz') + COHORTS
INSTRUMENTS = ('build_shared_closure.py', 'verify_shared_closure.py')


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def comparison(original, documents, runtime):
    """Old readers use saved-only views; actual canonical currency lives outside."""
    view = copy.deepcopy(original)
    book = API if API in original['documents'] else CORE
    view['documents'] = {book: documents[API], POD: documents[POD]}
    view['sources'][POD] = documents[POD]
    view['python'] = runtime
    return view


def build():
    originals = {name: read(name) for name in COHORTS}
    documents = {path: snapshot(path) for path in (CORE, API, POD)}
    runtime = {'implementation': sys.implementation.name, 'version': list(sys.version_info)}
    cohorts = {name: comparison(original, documents, runtime) for name, original in originals.items()}
    fields = {key: {'cohort': name, **row} for name, view in cohorts.items() for key, row in view['fields'].items()}
    native = read('model-roots-qualified.json.gz')['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    grouped = {
        'presence_key_family_map': {key: native['presence_key_family_map'][key] for key in fields},
        'semantic_presence_key_family_map': {key.removeprefix('success_'): native['semantic_presence_key_family_map'][key.removeprefix('success_')] for key in fields}}
    prefix = BASE.relative_to(ROOT).as_posix() + '/'
    return {'schema': 'fsmgen.shared_closure.v1', 'owner': OWNER,
        'inputs': {name: sha((BASE / name).read_bytes()) for name in INPUTS},
        'documents': documents, 'python': runtime, 'cohorts': cohorts,
        'comparison_roles': {name: {'mode': 'saved-only', 'kind': 'derived_semantic_comparison',
            'actual_source': API, 'logical_path': API if API in original['documents'] else CORE,
            'sha256': documents[API]['sha256']} for name, original in originals.items()},
        'sources': {path: snapshot(path) for path in sorted({path for original in originals.values() for path in original['sources']})},
        'fields': fields, 'grouped': grouped,
        'remaining_shared': originals[COHORTS[-1]]['remaining_shared'],
        'remaining_fields': originals[COHORTS[-1]]['remaining_fields'],
        'instruments': {prefix + name: snapshot(prefix + name) for name in INSTRUMENTS},
        'evidence_legs': {
            'rederive': 'Exact disjoint original native field union, selected native map values, current source/docs and explicit canonical comparison origins.',
            'falsify': 'Original independent cohort oracles plus separate actual canonical/currency and map-constructor joins; coherent field/owner/value/source/doc/role controls.',
            'durability': 'Retain complete original packets, source-bearing new views/instruments, saved/current/code-current replay and actual canonical native-content checks.'},
        'limits': 'Selected shared-family metadata and grouped entries only; full grouped maps, deeper models, source availability, hardware execution, HIAL, publication and whole-manual visual QA remain owned.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new audit-directory packet')
    target.write_bytes(gzip.compress((json.dumps(build(), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote shared closure; independent qualification required.')


if __name__ == '__main__':
    main()
