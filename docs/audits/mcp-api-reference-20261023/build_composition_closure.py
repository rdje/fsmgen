#!/usr/bin/env python3
"""Bind completed composition cohorts to a new current source/document epoch."""
import argparse
import copy
import gzip
import json
import sys
from pathlib import Path

from build_diagnostic_families import sha, snapshot

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.2.1.2.3.2.2.4.4'
COHORTS = ('composition-shallow-qualified.json.gz', 'composition-overrides-qualified.json.gz',
           'composition-dt-qualified.json.gz')
INPUTS = ('model-roots-qualified.json.gz', 'normalized-composition-partition.json.gz') + COHORTS
INSTRUMENTS = (
    'build_composition_closure.py', 'verify_composition_closure.py',
    'build_composition_shallow.py', 'verify_composition_shallow.py',
    'build_composition_overrides.py', 'verify_composition_overrides.py',
    'build_composition_dt.py', 'verify_composition_dt.py',
    'partition_normalized_composition.py', 'build_diagnostic_families.py',
    'verify_error_context.py', 'verify_model_roots.py',
    'verify_normalized_symbols.py', 'verify_normalized_envelope.py')


def read(name):
    return json.loads(gzip.decompress((BASE / name).read_bytes()))


def build():
    originals = {name: read(name) for name in COHORTS}
    paths = {path for packet in originals.values() for path in packet['sources']}
    sources = {path: snapshot(path) for path in sorted(paths)}
    documents = {path: snapshot(path) for path in (
        'docs/book/src/11-extensions-and-embedding.md', 'perl/FSM/Support/CapabilityManifest.pm')}
    runtime = {'implementation': sys.implementation.name, 'version': list(sys.version_info)}
    cohorts = copy.deepcopy(originals)
    fields = {}
    for name, packet in cohorts.items():
        packet['sources']['perl/FSM/Support/CapabilityManifest.pm'] = documents['perl/FSM/Support/CapabilityManifest.pm']
        packet['documents'] = documents
        packet['python'] = runtime
        fields.update({key: {'cohort': name, **row} for key, row in packet['fields'].items()})
    native = read('model-roots-qualified.json.gz')['native_api']['manifest']['semantic_exports']['normalized_semantic_json']
    grouped = {
        'presence_key_family_map': {key: native['presence_key_family_map'][key] for key in fields},
        'semantic_presence_key_family_map': {key.removeprefix('success_'): native['semantic_presence_key_family_map'][key.removeprefix('success_')]
            for key in fields if key.removeprefix('success_') in native['semantic_presence_key_family_map']}}
    prefix = BASE.relative_to(ROOT).as_posix() + '/'
    return {'schema': 'fsmgen.composition_closure.v1', 'owner': OWNER,
        'inputs': {name: sha((BASE / name).read_bytes()) for name in INPUTS},
        'cohorts': cohorts, 'fields': fields, 'grouped': grouped,
        'remaining_composition': originals[COHORTS[-1]]['remaining_composition'],
        'remaining_fields': originals[COHORTS[-1]]['remaining_fields'],
        'sources': sources, 'documents': documents, 'python': runtime,
        'instruments': {prefix + name: snapshot(prefix + name) for name in INSTRUMENTS},
        'evidence_legs': {
            'rederive': 'Union original qualified fields/delegations with newly captured complete source/document identities and original selected native grouped values.',
            'falsify': 'Authenticate each old cohort unchanged, admit only explicit current POD/document/runtime replacements, separately join both map constructors and exact envelope absence, reject coherent field/cohort/value/owner/source/doc controls.',
            'durability': 'Retain old packets, new complete comparison views, inputs and instrument sources, independent saved/current/code-current replay, focused contracts and native rendered guides.'},
        'limits': 'Selected non-shared composition metadata only. Broader grouped maps, deeper models, source availability, original compiler/backend epochs and whole-book browser qualification remain owned separately.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    target = args.output.resolve()
    if target.parent != BASE or target.exists():
        raise SystemExit('Output must be a new audit-directory file')
    target.write_bytes(gzip.compress((json.dumps(build(), sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    print('Wrote composition closure; independent qualification required.')


if __name__ == '__main__':
    main()
