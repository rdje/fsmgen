#!/usr/bin/env python3
"""Exercise code-only fact currency without mutating production source files."""
import hashlib
import json
from pathlib import Path
import tempfile

import verify_composition_dt as reader


def main():
    original_root = reader.ROOT
    original_base = reader.BASE
    packet = reader.read('composition-dt-qualified.json.gz')
    capture = reader.read('model-roots-qualified.json.gz')
    reader.capture_check(capture)
    reader.verify(packet, capture)
    snapshots = dict(packet['sources'])
    snapshots.update(packet['documents'])
    snapshots.update(packet['instruments'])
    production = {p: (original_root / p).read_bytes() for p in snapshots}
    local = original_root / '.artifacts/tmp'
    assert local.resolve().is_relative_to(original_root) and local.stat().st_dev == original_root.stat().st_dev
    cases = {}

    def rejected(label, **flags):
        try:
            reader.verify(packet, capture, **flags)
        except ValueError as error:
            cases[label] = str(error)
        else:
            raise AssertionError('Accepted currency counterfeit: ' + label)

    with tempfile.TemporaryDirectory(prefix='composition-dt-currency-', dir=local) as scratch:
        fixture = Path(scratch)
        for path, saved in snapshots.items():
            target = fixture / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(saved['text'])
        fixture_base = fixture / original_base.relative_to(original_root)
        fixture_base.mkdir(parents=True, exist_ok=True)
        for name in packet['inputs']:
            (fixture_base / name).write_bytes((original_base / name).read_bytes())
        reader.ROOT = fixture
        reader.BASE = fixture_base
        try:
            reader.verify(packet, capture, current=True)
            reader.verify(packet, capture, contracts_current=True)
            cases['baseline'] = 'full-current and code-current pass'
            pod = fixture / reader.POD
            original_pod = pod.read_bytes()
            assert b'\n__END__\n' in original_pod
            pod.write_bytes(original_pod + b'\nPOD currency intervention.\n')
            reader.verify(packet, capture, contracts_current=True)
            cases['pod_only_code_current'] = 'pass'
            rejected('pod_only_full_current', current=True)
            assert cases['pod_only_full_current'] == 'current source stale'
            pod.write_bytes(original_pod)
            book = fixture / reader.BOOK
            original_book = book.read_bytes()
            book.write_bytes(original_book + b'\nBook currency intervention.\n')
            reader.verify(packet, capture, contracts_current=True)
            cases['book_only_code_current'] = 'pass'
            rejected('book_only_full_current', current=True)
            assert cases['book_only_full_current'] == 'current document stale'
            book.write_bytes(original_book)
            builder = fixture / 'perl/FSM/Composition/ChildExportBuilder.pm'
            original_builder = builder.read_bytes()
            before = b'standalone_dt_enable_families => \\@enable_families'
            assert original_builder.count(before) == 1
            builder.write_bytes(original_builder.replace(before, b'standalone_dt_enable_families => {}'))
            rejected('builder_container_kind_change', contracts_current=True)
            assert cases['builder_container_kind_change'] == 'current contract/builder code stale'
            builder.write_bytes(original_builder)
            reader.verify(packet, capture, current=True)
            cases['restored_fixture'] = 'full-current pass'
        finally:
            reader.ROOT = original_root
            reader.BASE = original_base
    assert not fixture.exists()
    assert all((original_root / p).read_bytes() == raw for p, raw in production.items())
    print(json.dumps({'cases': cases, 'production_sources_unchanged': True,
        'owned_fixture_removed': True,
        'packet_sha256': hashlib.sha256((reader.BASE / 'composition-dt-qualified.json.gz').read_bytes()).hexdigest(),
        'reader_sha256': hashlib.sha256(Path(reader.__file__).read_bytes()).hexdigest(),
        'instrument_source': Path(__file__).read_text(),
        'scope': 'Static saved-data/current-file currency controls only; no compiler, source-query or backend epoch.'}, sort_keys=True))


if __name__ == '__main__':
    main()
