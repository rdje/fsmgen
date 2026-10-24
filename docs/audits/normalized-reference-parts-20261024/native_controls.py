#!/usr/bin/env python3
"""Reject actual missing/misrouted/corrupt native migration fixtures safely."""
import json
from pathlib import Path
import tempfile

import bridge


def main():
    build = bridge.ROOT / 'docs/book/book'
    paths = ('11-extensions-and-embedding.html', '11a-perl-api-reference.html',
             'perl-api/FSM/Support/CapabilityManifest.html')
    original = {path: (build / path).read_bytes() for path in paths}
    packet = bridge.read(bridge.BASE / 'migration-qualified.json.gz')
    results = {}
    with tempfile.TemporaryDirectory(prefix='reference-native-controls-', dir=bridge.ROOT / '.artifacts/tmp') as temporary:
        fixture = Path(temporary)
        for path, raw in original.items():
            target = fixture / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(raw)
        bridge.rendered(fixture, packet)
        for label in ('missing_part', 'missing_old_route', 'missing_new_anchor', 'corrupt_actual_table'):
            for path, raw in original.items():
                (fixture / path).write_bytes(raw)
            if label == 'missing_part':
                (fixture / paths[1]).unlink()
            elif label == 'missing_old_route':
                needle = b'href="11a-perl-api-reference.html#normalized-report-envelope-families"'
                bridge.require(original[paths[0]].count(needle) == 1, 'single actual original route')
                (fixture / paths[0]).write_bytes(original[paths[0]].replace(needle, b'href="#removed-route"'))
            elif label == 'missing_new_anchor':
                needle = b'id="normalized-report-envelope-families"'
                bridge.require(original[paths[1]].count(needle) == 1, 'single actual canonical anchor')
                (fixture / paths[1]).write_bytes(original[paths[1]].replace(needle, b'id="removed-anchor"'))
            else:
                needle = b'<td><code>public_top_level_presence_keys</code></td>'
                bridge.require(original[paths[1]].count(needle) == 1, 'single actual envelope field cell')
                (fixture / paths[1]).write_bytes(original[paths[1]].replace(needle, b'<td><code>invented_field</code></td>'))
            try:
                bridge.rendered(fixture, packet)
            except (OSError, ValueError) as error:
                results[label] = str(error).replace(str(fixture), 'owned-native-fixture')
            else:
                raise ValueError('Accepted damaged native fixture: ' + label)
    bridge.require(not fixture.exists(), 'owned native-control fixture removed')
    bridge.require(all((build / path).read_bytes() == raw for path, raw in original.items()), 'actual production build bytes conserved')
    print(json.dumps({'rejected_controls': results,
        'actual_build_sha256': {path: bridge.sha(raw) for path, raw in original.items()},
        'probe_sha256': bridge.sha(Path(__file__).read_bytes()),
        'limits': 'Owned native fixture interventions only; actual build and repository source files are unchanged. Selected content/routes, not whole-manual browser signoff.'}, sort_keys=True))


if __name__ == '__main__':
    main()
