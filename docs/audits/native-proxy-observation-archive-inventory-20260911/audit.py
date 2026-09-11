"""Independently check the complete catalogue against Git and retained receipts."""
from __future__ import annotations

from collections import Counter
import copy
import json
import re

import inventory as I

BASE, ROOT, LOG = I.BASE, I.ROOT, I.LOG
REVISION = '5d58a61c26859c2c0e155c512b0781bcd25d430b'
EXPECTED = [
    ('records', '-records', 'pure'), ('files', '', 'filesystem'),
    ('boundaries', '-boundaries', 'boundaries'), ('ordinary-fresh', '-fresh-calls', 'calls'),
    ('ordinary-existing', '-existing-calls', 'calls'), ('equal-fresh', '-equal-fresh-calls', 'calls'),
    ('equal-existing', '-equal-existing-calls', 'calls'), ('partial-writes', '-partial-writes', 'writes'),
    ('close-reports', '-close-reports', 'closes'), ('omitted-closes', '-omitted-closes', 'closes'),
    ('close-join', '-close-join', 'join'), ('guards', '-guards', 'pure'),
    ('namespace', '-namespace-layouts', 'hostile'), ('replacements', '-replacements', 'hostile'),
    ('observer', '-lower-reader-seam', 'reader'), ('reader-failures', '-lower-reader-failures', 'reader'),
    ('reader-join', '-lower-reader-join', 'join'), ('replay', '-replay', 'replay'),
]
HANDOFF = 'docs/audits/native-proxy-descriptor-handoff-20260910'
NAMESPACE = 'docs/audits/native-proxy-observation-archive-namespace-layouts-20260911'


def plan_domain(plan):
    assert plan['schema'] == 'fsmgen.inactive_archive_complete_inventory_plan.v1'
    assert plan['source_revision'] == REVISION
    assert plan['owner'] == 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.4.3.1'
    assert plan['input_limits'] == dict(files=1024, file_bytes=33554432, total_bytes=536870912)
    assert [(row['name'], row['source'], row['kind']) for row in plan['domains']] == [
        (name, 'docs/audits/native-proxy-observation-archive' + suffix + '-20260911', kind)
        for name, suffix, kind in EXPECTED] + [('strict-handoff', HANDOFF, 'handoff-support')]
    assert plan['infrastructure'] == [I.SAFE_PATH]
    assert plan['extra_inputs'] == ['docs/audits/native-proxy-image-custody-20260910/vectors.json']
    assert len(plan['corrections']) == 1
    correction = plan['corrections'][0]
    assert correction['domain'] == 'namespace'
    assert (correction['canonical'], correction['original'], correction['postrun_pin']) == (
        NAMESPACE + '/audit.py', NAMESPACE + '/result/first-audit/audit.py.initial-source', NAMESPACE + '/postrun-audit-pin.json')
    assert plan['handoff_functions'] == [
        dict(path='t/lib/FSM/Test/RustProxyFixture.pm', function='_read_file'),
        dict(path='docs/audits/native-proxy-image-custody-20260910/ImageCustody.pm', function='_source'),
        dict(path='docs/audits/native-proxy-image-publication-20260910/Publication.pm', function='_write_payload')]


def reference(plan):
    """Build independent expectations from committed trees and source bytes.

    Never call the inventory producer. Every current file is authenticated
    against the fixed Git revision before its decoded data contributes facts.
    Historical originals are compared byte-for-byte, not only by saved hashes.
    """
    plan_domain(plan)
    raw_cache = {}; identities = {}
    def authenticated(path):
        if path not in raw_cache:
            raw, identity = I.read(path, plan['input_limits']['file_bytes'])
            assert raw == I.historical(REVISION, path)
            raw_cache[path] = raw; identities[path] = dict(path=path, **identity)
        return raw_cache[path]
    def document(path): return json.loads(authenticated(path))
    domains = []; epochs = []; prospective = []; recoveries = []; paths = set(plan['infrastructure'] + plan['extra_inputs'])
    for domain in plan['domains']:
        base, name = domain['source'], domain['name']
        entries = I.tree(domain['completed_revision'], base)
        assert entries == I.tree(REVISION, base) and entries == sorted(set(entries)) and entries
        assert all(path.startswith(base + '/') for path in entries)
        paths.update(entries)
        domains.append(dict(name=name, source=base, files=entries, completed_revision=domain['completed_revision']))
        for path in entries:
            assert authenticated(path) == I.historical(domain['completed_revision'], path)
        child = document(base + '/plan.json')
        assert child['source_revision'] == domain['source_epoch']
        for pin in child.get('inputs', []):
            path = pin['path']; paths.add(path); original = I.historical(domain['source_epoch'], path)
            assert original == authenticated(path)
            assert I.digest(original) == {key: pin[key] for key in ('size_bytes', 'sha256')}
            epochs.append(dict(domain=name, source_epoch=domain['source_epoch'], path=path, **I.digest(original)))
        if domain['kind'] == 'join':
            joined = document(base + '/result/source-inventory.json')
            for pin in joined['inputs']:
                paths.add(pin['path'])
                assert I.digest(authenticated(pin['path'])) == {key: pin[key] for key in ('size_bytes', 'sha256')}
        available = [path for path in [base + '/preflight-pins.json', base + '/result/preflight-pins.json'] if path in entries]
        if name == 'strict-handoff':
            assert available == []
        else:
            assert available
            assert len({authenticated(path) for path in available}) == 1
            declared = document(available[0]); assert len({pin['path'] for pin in declared}) == len(declared)
            for pin in declared:
                canonical = pin['path']; source = canonical
                if canonical == NAMESPACE + '/audit.py':
                    source = NAMESPACE + '/result/first-audit/audit.py.initial-source'
                assert source in paths
                original = authenticated(source)
                assert I.digest(original) == {key: pin[key] for key in ('size_bytes', 'sha256')}
                prospective.append(dict(domain=name, path=canonical, authenticated_path=source, **I.digest(original)))
                if source != canonical:
                    corrected = document(NAMESPACE + '/postrun-audit-pin.json')
                    assert corrected == dict(path=canonical, **I.digest(authenticated(canonical)))
                    assert original != authenticated(canonical)
                    prospective.append(dict(domain=name, path=canonical, authenticated_path=canonical,
                                            corrected=True, **I.digest(authenticated(canonical))))
        manifest = document(base + '/result/recovery-copies.json')
        assert manifest['all_copies_byte_exact'] is True
        destinations = [row['destination'] for row in manifest['files']]
        assert len(destinations) == len(set(destinations))
        for row in manifest['files']:
            destination = row['destination']
            assert destination in entries and destination.startswith(base + '/result/')
            local = destination[len(base + '/result/'):]
            assert row['source'] == '.artifacts/logs/' + base.rsplit('/', 1)[-1] + '/' + local
            assert I.digest(authenticated(destination)) == {key: row[key] for key in ('size_bytes', 'sha256')}
            recoveries.append(dict(domain=name, **row))
    for path in sorted(paths): authenticated(path)
    assert set(raw_cache) == paths
    assert len(paths) <= plan['input_limits']['files']
    functions = []
    for selected in plan['handoff_functions']:
        path, name = selected['path'], selected['function']
        current = I.body(authenticated(path), name)
        epoch = plan['domains'][-1]['completed_revision']
        assert epoch == '730b8b3a2bb1e918d24a03d23a19b0066d159508'
        assert current == I.body(I.historical(epoch, path), name)
        functions.append(dict(**selected, source_epoch=epoch, **I.digest(current)))
    result = dict(schema='fsmgen.inactive_archive_complete_inventory.v1', source_revision=REVISION,
                  domains=domains, inputs=[identities[path] for path in sorted(paths)], source_epochs=epochs,
                  prospective=prospective, recovery_receipts=recoveries, handoff_functions=functions,
                  total_bytes=sum(len(raw) for raw in raw_cache.values()))
    assert result['total_bytes'] <= plan['input_limits']['total_bytes']
    # Authentication preserves nonzero first outcomes; it does not turn them
    # into successful qualification merely because their digests match.
    exits = []
    for path in sorted(paths):
        if path.endswith('.exit'):
            raw = raw_cache[path]; assert re.fullmatch(rb'[0-9]+\n', raw)
            exits.append(dict(path=path, exit_code=int(raw)))
    assert dict((row['path'], row['exit_code']) for row in exits)[NAMESPACE + '/result/first-audit/audit.exit'] == 1
    return result, exits


def verify(observed, expected):
    assert set(observed) == set(expected)
    assert observed['schema'] == expected['schema'] and observed['source_revision'] == expected['source_revision']
    for key in ['domains', 'inputs', 'source_epochs', 'prospective', 'recovery_receipts', 'handoff_functions', 'total_bytes']:
        assert observed[key] == expected[key], key
    assert len({row['path'] for row in observed['inputs']}) == len(observed['inputs'])
    assert sum(row['size_bytes'] for row in observed['inputs']) == observed['total_bytes']


def reject(name, callback, rejected):
    try:
        callback()
    except (AssertionError, KeyError, IndexError, ValueError):
        rejected.append(name)
    else:
        raise AssertionError('complete inventory accepted falsifier: ' + name)


def main():
    pins = I.pins(); plan = I.document(str((BASE / 'plan.json').relative_to(ROOT)))
    expected, exits = reference(plan)
    observed = I.document(str((LOG / 'inventory.json').relative_to(ROOT)))
    verify(observed, expected)
    changes = [
        ('lost domain', lambda r: r['domains'].pop()),
        ('aliased domain', lambda r: r['domains'].__setitem__(1, r['domains'][0])),
        ('lost domain file', lambda r: r['domains'][0]['files'].pop()),
        ('wrong completion epoch', lambda r: r['domains'][0].update(completed_revision=REVISION)),
        ('lost input', lambda r: r['inputs'].pop()),
        ('extra input', lambda r: r['inputs'].append(copy.deepcopy(r['inputs'][0]))),
        ('changed bytes', lambda r: r['inputs'][0].update(sha256='0' * 64)),
        ('changed byte length', lambda r: r['inputs'][0].update(size_bytes=0)),
        ('changed native identity', lambda r: r['inputs'][0].update(inode=0)),
        ('foreign volume', lambda r: r['inputs'][0].update(device=0)),
        ('source mode changed', lambda r: r['inputs'][0].update(mode=0)),
        ('lost epoch', lambda r: r['source_epochs'].pop()),
        ('changed epoch source', lambda r: r['source_epochs'][0].update(source_epoch=REVISION)),
        ('lost prospective pin', lambda r: r['prospective'].pop()),
        ('first auditor relabeled current', lambda r: next(p for p in r['prospective'] if 'first-audit' in p['authenticated_path']).update(authenticated_path=NAMESPACE + '/audit.py')),
        ('lost corrected auditor', lambda r: r.update(prospective=[p for p in r['prospective'] if not p.get('corrected')])),
        ('lost raw receipt', lambda r: r['recovery_receipts'].pop()),
        ('foreign recovery origin', lambda r: r['recovery_receipts'][0].update(source='.artifacts/logs/foreign')),
        ('changed recovery digest', lambda r: r['recovery_receipts'][0].update(sha256='0' * 64)),
        ('lost handoff body', lambda r: r['handoff_functions'].pop()),
        ('changed handoff body', lambda r: r['handoff_functions'][0].update(sha256='0' * 64)),
        ('wrong total bytes', lambda r: r.update(total_bytes=r['total_bytes'] + 1)),
    ]
    rejected = []
    for name, mutate in changes:
        changed = copy.deepcopy(observed); mutate(changed)
        reject(name, lambda: verify(changed, expected), rejected)
    domain_changes = [
        ('missing planned domain', lambda p: p['domains'].pop()),
        ('aliased planned domain', lambda p: p['domains'].__setitem__(1, p['domains'][0])),
        ('missing correction', lambda p: p['corrections'].clear()),
        ('wrong corrected source', lambda p: p['corrections'][0].update(original=NAMESPACE + '/audit.py')),
        ('lost handoff function scope', lambda p: p['handoff_functions'].pop()),
        ('widened inventory envelope', lambda p: p['input_limits'].update(files=2048)),
    ]
    for name, mutate in domain_changes:
        changed = copy.deepcopy(plan); mutate(changed)
        reject(name, lambda: plan_domain(changed), rejected)
    I.pins()
    # Fresh identity/byte reads seal the actual source state after falsification.
    for row in observed['inputs']:
        _, identity = I.read(row['path'])
        assert dict(path=row['path'], **identity) == row
    counts = Counter(domain['kind'] for domain in plan['domains'])
    output = dict(schema='fsmgen.inactive_archive_complete_inventory_audit.v1', success=True,
                  domains=len(observed['domains']), domain_kinds=dict(counts), source_files=len(observed['inputs']),
                  source_bytes=observed['total_bytes'], source_epoch_comparisons=len(observed['source_epochs']),
                  prospective_bindings=len(observed['prospective']), corrected_auditors=sum(bool(p.get('corrected')) for p in observed['prospective']),
                  recovery_receipts=len(observed['recovery_receipts']), exact_handoff_bodies=len(observed['handoff_functions']),
                  exit_receipts=len(exits), nonzero_exit_receipts=[row for row in exits if row['exit_code']],
                  current_prospective_pins=len(pins), falsifiers=rejected,
                  source_semantics_join_pending=True, old_producers_invoked=False, limits=plan['limits'])
    with (LOG / 'audit.json').open('x') as stream:
        stream.write(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps({key: value for key, value in output.items() if key != 'falsifiers'}, sort_keys=True))


if __name__ == '__main__':
    main()
