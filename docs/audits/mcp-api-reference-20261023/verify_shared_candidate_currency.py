#!/usr/bin/env python3
"""Exercise candidate source/document currency in an isolated local fixture."""
import gzip
import json
import tempfile
from pathlib import Path

import verify_shared_candidate as reader
from verify_normalized_envelope import require, sha


def refused(packet, capture, **mode):
    try:
        reader.verify(packet, capture, **mode)
    except ValueError as error:
        return str(error)
    raise ValueError('Expected current-file refusal')


def main():
    original_root, original_base = reader.ROOT, reader.BASE
    packet = reader.read('shared-candidate-qualified.json.gz')
    capture = reader.read('model-roots-qualified.json.gz')
    watched = set(packet['sources']) | set(packet['documents']) | set(packet['instruments'])
    original = {path: (original_root / path).read_bytes() for path in watched}
    results = {}
    try:
        with tempfile.TemporaryDirectory(prefix='shared-candidate-currency-', dir=original_root / '.artifacts/tmp') as temporary:
            fixture = Path(temporary)
            reader.ROOT = fixture
            reader.BASE = fixture / original_base.relative_to(original_root)
            reader.BASE.mkdir(parents=True)
            for name in packet['inputs']:
                (reader.BASE / name).write_bytes((original_base / name).read_bytes())
            for path, raw in original.items():
                target = fixture / path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(raw)
            reader.verify(packet, capture, current=True)
            reader.verify(packet, capture, contracts_current=True)
            results['baseline'] = 'full-current and code-current pass'
            for path in (reader.BOOK, reader.POD):
                (fixture / path).write_bytes(original[path] + b'\nfixture documentation change\n')
            reader.verify(packet, capture, contracts_current=True)
            results['documentation_only'] = 'code-current passes'
            results['full_documentation_refusal'] = refused(packet, capture, current=True)
            for path in (reader.BOOK, reader.POD):
                (fixture / path).write_bytes(original[path])
            path = 'perl/FSM/Composition/SharedDatapathCandidateBuilder.pm'
            before = original[path]
            needle = b'$contributor->{declared_type_name} = $declared_type_name if defined $declared_type_name;'
            require(before.count(needle) == 1, 'single real conditional projection')
            changed = before.replace(needle, b'$contributor->{declared_type_name} = $declared_type_name;')
            (fixture / path).write_bytes(changed)
            results['conditional_projection_refusal'] = refused(packet, capture, contracts_current=True)
            (fixture / path).write_bytes(before)
            reader.verify(packet, capture, current=True)
            results['restored'] = 'full-current passes'
    finally:
        reader.ROOT, reader.BASE = original_root, original_base
    require(not fixture.exists(), 'fixture cleanup')
    require(all((original_root / path).read_bytes() == raw for path, raw in original.items()), 'production bytes conserved')
    print(json.dumps({'controls': results, 'production_sha256': {path: sha(raw) for path, raw in original.items()},
        'probe_sha256': sha(Path(__file__).read_bytes()),
        'limits': 'Fixture source-only interventions; no production source mutation, compiler/source/backend epoch or additional runtime behavior claim.'}, sort_keys=True))


if __name__ == '__main__':
    main()
