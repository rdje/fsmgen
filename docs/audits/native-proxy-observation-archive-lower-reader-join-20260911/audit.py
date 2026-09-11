"""Join saved callee custody and caller cleanup without executing old producers."""
from __future__ import annotations

import builtins
from collections import Counter
from contextlib import contextmanager
import copy
import importlib.util
import io
import json
from pathlib import Path
import re

import inventory as I

BASE, ROOT, LOG = I.BASE, I.ROOT, I.LOG
REVISION = 'deb2b6a7cfbd55a664e0127b5135a31fdb0b994b'
HANDOFF_REVISION = '730b8b3a2bb1e918d24a03d23a19b0066d159508'
BOUNDARY = 'docs/audits/native-proxy-observation-archive-boundaries-20260911'
READER = 't/lib/FSM/Test/RustProxyFixture.pm'
CUSTODY = 'docs/audits/native-proxy-image-custody-20260910/ImageCustody.pm'
PUBLICATION = 'docs/audits/native-proxy-image-publication-20260910/Publication.pm'
ARCHIVE = 'docs/audits/native-proxy-observation-archive-20260911/ObservationArchive.pm'
MATRICES = [
    ('filesystem', '', 'dd29e3bffdcdbcf737236e20086acb89bcc31771', 'ff71d28f1e47c6bf34db96029862f6be5fe96051'),
    ('ordinary-fresh', '-fresh-calls', 'cbb62267a741dd059132d745d429c12d86fc5967', 'ca3cd1940f035ece55144ab86f7f08cd9832bd52'),
    ('ordinary-existing', '-existing-calls', 'ca3cd1940f035ece55144ab86f7f08cd9832bd52', '83501699d4c9f45d0c5c43837453141f60d02e8b'),
    ('equal-fresh', '-equal-fresh-calls', '83501699d4c9f45d0c5c43837453141f60d02e8b', 'af76fe3c794dc020e4de71789d24a13eafcbca76'),
    ('equal-existing', '-equal-existing-calls', 'af76fe3c794dc020e4de71789d24a13eafcbca76', '698f99da3ca3dfe47b89fc17db142b3784f37907'),
    ('observer', '-lower-reader-seam', '94ba98609063049d44a46f1dddd19fd065e130cd', '05957842d584b6b3f434e2b2d20c65316e16e39c'),
    ('failures', '-lower-reader-failures', '05957842d584b6b3f434e2b2d20c65316e16e39c', REVISION),
]


def domain(plan):
    assert plan['schema'] == 'fsmgen.inactive_archive_lower_reader_join_plan.v1'
    assert plan['source_revision'] == REVISION
    assert plan['owner'] == 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.3.4.2.3.3'
    assert [(m['name'], m['source'], m['source_epoch'], m['completed_revision']) for m in plan['matrices']] == [
        (name, 'docs/audits/native-proxy-observation-archive' + suffix + '-20260911', epoch, completed)
        for name, suffix, epoch, completed in MATRICES]
    assert plan['input_limits'] == dict(files=256, file_bytes=33554432, total_bytes=268435456)
    assert plan['infrastructure'] == [I.SAFE_PATH]
    assert plan['handoff']['source'] == 'docs/audits/native-proxy-descriptor-handoff-20260910'
    assert plan['handoff']['completed_revision'] == HANDOFF_REVISION


def load(base, name):
    spec = importlib.util.spec_from_file_location('reader_join_' + name, ROOT / base / 'audit.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@contextmanager
def saved_only():
    originals = builtins.open, io.open
    def guarded(original):
        def call(path, *args, **kwargs):
            if isinstance(path, (str, bytes, Path)):
                candidate = Path(path).absolute()
                if candidate.is_relative_to(ROOT / '.artifacts') and not candidate.is_relative_to(LOG):
                    raise AssertionError('legacy artifact content is forbidden')
            return original(path, *args, **kwargs)
        return call
    builtins.open, io.open = map(guarded, originals)
    try:
        yield
    finally:
        builtins.open, io.open = originals


def receipts(matrix, manifest):
    assert manifest['all_copies_byte_exact'] is True
    assert [row['destination'] for row in manifest['files']] == matrix['receipts']
    assert len(matrix['receipts']) == len(set(matrix['receipts']))
    prefix = matrix['source'] + '/result/'
    for row in manifest['files']:
        assert row['destination'].startswith(prefix)
        name = row['destination'][len(prefix):]
        assert row['source'] == '.artifacts/logs/' + matrix['source'].rsplit('/', 1)[-1] + '/' + name
        raw = I.read(row['destination'])[0]
        assert I.digest(raw) == {key: row[key] for key in ('size_bytes', 'sha256')}
        if name.endswith('.exit'):
            assert raw == b'0\n'
    return len(manifest['files'])


def tap(raw):
    assert not re.search(r'^(?:not ok|Bail out!)|#\s*(?:SKIP|TODO)\b', raw, re.M | re.I)
    plans = re.findall(r'^1\.\.([0-9]+)$', raw, re.M)
    assert len(plans) == 1
    count = int(plans[0])
    assert re.findall(r'^ok ([0-9]+) - ', raw, re.M) == [str(n) for n in range(1, count + 1)]
    return count


def body(text, name):
    marker = 'sub ' + name + ' {'
    assert text.count(marker) == 1
    result = text[text.index(marker):].split('\nsub ', 1)[0]
    return result[:result.rindex('\n}') + 2] + '\n'


def ordered(text, fragments):
    position = 0
    for fragment in fragments:
        assert text.count(fragment) == 1, fragment
        position = text.index(fragment, position) + len(fragment)


def source_contract(texts):
    reader, custody, publication, archive, trace, original = texts
    ordered(body(reader, '_read_file'), ['sysopen(my $fh,', 'my @before = stat($fh);',
        'my $body =', 'my $count = sysread(', 'die "cannot read fixture bytes:',
        'my @after = stat($fh);', 'die "fixture changed during its bounded read',
        'close($fh) or die', 'return ($body, \\@before, $keep_open ? $fh : undef);'])
    ordered(body(custody, '_source'), ['my ($bytes, $metadata, $handle) = FSM::Test::RustProxyFixture::_read_file($path, 1);',
        'my $ok = eval {', 'die "invalid image source mode, links or size',
        'my $error = $@;', 'unless ($ok) {', 'close($handle);', 'die $error;', 'return {bytes =>'])
    ordered(body(publication, '_write_payload'), ['sysopen(my $writer,', 'my $source;', 'my $ok = eval {',
        '$source = NativeProxyImageCustody::_source(', 'my $error = $@;',
        'if ($source && !close($source->{handle}))', 'if (!close($writer))',
        'die $error unless $ok;', 'die $close_error if length($close_error);', 'return $sealed_identity;'])
    ordered(body(archive, 'archive_retained_sources'), ['my $state = {spec => $spec, sources => [],',
        'my $ok = eval {', '$written = NativeProxyImagePublication::_write_payload(',
        'push @{$state->{sources}}, NativeProxyImageCustody::_source(',
        'my $source = $state->{sources}[-1];', '_source_closure($state);',
        'my $error = $@;', 'my $close_error = _close_sources($state->{sources});',
        'die $error unless $ok;', 'die $close_error if length($close_error);', 'return $receipt;'])
    ordered(body(archive, '_source_closure'), ['for my $source (@{$state->{sources}})',
        'my $fresh = NativeProxyImageCustody::_source(', 'my $ok = eval {',
        'my $error = $@;', 'my $closed = close($fresh->{handle});', 'die $error unless $ok;'])
    ordered(body(archive, '_close_sources'), ['for my $source (@$sources)', 'unless close($source->{handle});', 'return $error;'])
    wrapper = trace.split('local *NativeProxyImageCustody::_source = sub {', 1)[1].split('\n    };', 1)[0]
    ordered(wrapper, ['_event("$label:before");', 'my $source = $original{source}->(@_);', '_handle($source->{handle},', 'return $source;'])
    # The original archive harness also observes only successful _source returns.
    wrapper = original.split('local *NativeProxyImageCustody::_source = sub {', 1)[1].split('\n        };', 1)[0]
    ordered(wrapper, ['my $source = $reader->(@_);', 'push @held,', 'return $source;'])


def select_archive(child, report, healthy):
    """Reconstruct each source-entry cut and already-owned unwind independently."""
    number = child['profile']['files']; fresh = child['route'] == 'fresh'
    ordinals = range(3 if fresh else 2)
    expected = {f'source:{index}:{ordinal}:before' for index in range(number) for ordinal in ordinals}
    selectors = [event for event in healthy if re.fullmatch(r'source:[0-9]+:[0-9]+:before', event)]
    assert set(selectors) == expected and len(selectors) == len(expected)
    rows = {row['selector']: row for row in report['cases']}
    selected = []; counts = Counter(); allocations = []
    for selector in selectors:
        row = rows[selector]; op = row['operation']; index, ordinal = map(int, selector.split(':')[1:3])
        role = 'payload' if fresh and ordinal == 0 else ('retained' if ordinal == int(fresh) else 'reread')
        prefix = healthy[:healthy.index(selector) + 1]
        owned = []
        for event in prefix:
            if event.startswith('opened:'):
                owned.append(event[7:])
            elif event.startswith('close:') and event.endswith(':after'):
                owned.remove(event[6:-6])
        retained = [f'source:{i}:{int(fresh)}' for i in range(number if role == 'reread' else index)]
        writer = [f'writer:{index}'] if role == 'payload' else []
        assert owned == retained + writer
        suffix = []
        for label in writer:
            suffix.extend([f'close:{label}:before', f'close:{label}:after'])
        suffix.append('close_sources:before')
        for label in retained:
            suffix.extend([f'close:{label}:before', f'close:{label}:after'])
        suffix.append('close_sources:after')
        assert op['events'] == prefix + suffix
        assert 'opened:' + selector[:-7] not in op['events']
        assert op['returned'] == 0 and op.get('result') is None
        assert op['error'] == 'injected archive call: ' + selector + '\n'
        assert row['injected_hits'] == row['inputs_unchanged'] == 1
        assert op['all_observed_handles_closed'] == 1
        closed = {h['label']: h for h in op['handles']}
        for label in owned:
            h = closed[label]
            assert h['actual_close_ok'] == h['closed_after_call'] == h['closed_at_return'] == 1
            assert h['actual_errno'] == 0
        operations = [op]
        if not fresh:
            preparation = row['preparation']
            assert preparation['returned'] == 1 and preparation['error'] == ''
            assert preparation['after'] == op['before'] == op['after']
            operations.insert(0, preparation)
            counts['preparations'] += 1
        counts['source_before_cases'] += 1; counts[role + '_cuts'] += 1
        counts['caller_cleanup_handles'] += len(owned)
        for operation in operations:
            counts['archive_operations'] += 1; counts['events'] += len(operation['events'])
            for handle in operation['handles']:
                assert handle['actual_close_ok'] == handle['closed_after_call'] == handle['closed_at_return'] == 1
                counts[handle['kind'] + '_handles'] += 1
        for kind in ('store', 'workspace', 'other_workspace', 'evidence'):
            allocations.append(dict(kind=kind, **row['context'][kind]))
        selected.append(dict(name=row['name'], selector=selector, role=role, already_owned=owned,
                             cleanup_events=suffix, preparation=not fresh))
    return selected, dict(counts), allocations


def absent(roots):
    paths = [row['path'] for row in roots]
    assert len(paths) == len(set(paths)), 'overlapping saved allocations'
    for name in paths:
        assert name.startswith('.artifacts/') and all(p not in ('', '.', '..') for p in name.split('/'))
        path = ROOT / name
        assert not path.exists() and not path.is_symlink()
        while path != ROOT:
            assert not path.is_symlink()
            if path.exists():
                assert path.stat().st_dev == ROOT.stat().st_dev
            path = path.parent


def reject(name, callback, rejected):
    try:
        callback()
    except (AssertionError, KeyError, IndexError, ValueError):
        rejected.append(name)
    else:
        raise AssertionError('join accepted falsifier: ' + name)


def main():
    pins = I.authenticate_pins(); plan = I.decoded(str((BASE / 'plan.json').relative_to(ROOT))); domain(plan)
    observed = I.decoded(str((LOG / 'source-inventory.json').relative_to(ROOT)))
    actual = I.census(plan)
    assert observed == actual
    baseline = I.decoded(BOUNDARY + '/result/qualification.json')
    children, reports, oracles, arguments, child_counts = {}, {}, {}, {}, {}
    rejected = []; raw_receipts = 0; assertions = 0; all_roots = []
    with saved_only():
        reject('legacy ignored content', lambda: (ROOT / '.artifacts/logs/forbidden-reader-join').read_bytes(), rejected)
        for matrix in plan['matrices']:
            name, base = matrix['name'], matrix['source']
            raw_receipts += receipts(matrix, I.decoded(base + '/result/recovery-copies.json'))
            oracle = load(base, name); child = I.decoded(base + '/plan.json'); report = I.decoded(base + '/result/qualification.json')
            if name == 'filesystem':
                args = ()
            elif name in ('observer', 'failures'):
                oracle.domain(child); args = ()
            else:
                flow = oracle.domain(child, baseline)
                args = flow if child['route'] == 'existing' else (flow,)
            counts = oracle.verify(child, report, *args)
            saved = I.decoded(base + '/result/audit.json')
            assert saved['success'] is saved['all_allocations_absent'] is True
            assert all(saved[key] == value for key, value in counts.items())
            assert saved['predecessor_inputs_unchanged'] == len(child['inputs'])
            assert saved['prospective_inputs_unchanged'] == len(matrix['sources'])
            count = tap(I.read(base + '/result/qualify.tap')[0].decode()); assert count == saved['tap_assertions']; assertions += count
            journal = [json.loads(line) for line in I.read(base + '/result/admission.jsonl')[0].splitlines()]
            assert journal == report['allocated']; all_roots.extend(journal)
            children[name], reports[name], oracles[name], arguments[name], child_counts[name] = child, report, oracle, args, counts
            reject(name + ': missing case', lambda: oracle.verify(child, dict(report, cases=report['cases'][:-1]), *args), rejected)
        handoff = plan['handoff']; base = handoff['source']; oracle = load(base, 'handoff')
        raw_receipts += receipts(handoff, I.decoded(base + '/result/recovery-copies.json'))
        handoff_plan = I.decoded(base + '/plan.json')
        assert I.digest(I.read(base + '/plan.json')[0])['sha256'] == oracle.PLAN_SHA
        oracle.LOG = ROOT / base / 'result'  # Only its exact tracked journal is needed by validate.
        handoff_counts = {}
        for phase in ['baseline', 'qualification']:
            report = I.decoded(base + '/result/' + phase + '.json')
            oracle.validate(report, handoff_plan, phase)
            count = tap(I.read(base + '/result/' + phase + '.tap')[0].decode())
            assert count == 2 * (len(report['cases']) + len(report['mutants'])) + 1
            assertions += count; all_roots.extend(report['allocated'])
            handoff_counts[phase] = dict(cases=len(report['cases']), mutants=len(report['mutants']), assertions=count)
            changed = copy.deepcopy(report); changed['cases'][0]['handles'][0]['closed_after_recovery'] = 0
            reject('handoff ' + phase + ': lost recovery', lambda: oracle.validate(changed, handoff_plan, phase), rejected)
        qualified = I.decoded(base + '/result/qualification.json')
        sources = [row for row in qualified['cases'] if row['operation'] == 'source']
        assert [row['name'] for row in sources] == ['source_success', 'source_mode', 'source_size', 'source_get_flags', 'source_set_flags', 'source_mode_close_error']
        strict = [row for row in sources if not row['returned']]
        assert all(row['handles'][0]['closed_before_recovery'] == 1 and row['handles'][0]['recovery_close_ok'] is None for row in strict)
        changed = copy.deepcopy(qualified); changed['cases'][1]['handles'][0]['closed_before_recovery'] = 0
        reject('strict source closure hidden', lambda: oracle.validate(changed, handoff_plan, 'qualification'), rejected)

    texts = [I.read(path)[0].decode() for path in [READER, CUSTODY, PUBLICATION, ARCHIVE,
             BOUNDARY + '/ArchiveTrace.pm', plan['matrices'][0]['source'] + '/qualify.t']]
    source_contract(texts)
    source_bodies = []
    for path, names in [(READER, ['_read_file']), (CUSTODY, ['_source']), (PUBLICATION, ['_write_payload'])]:
        historical = I.historical(HANDOFF_REVISION, path).decode(); current = I.read(path)[0].decode()
        for name in names:
            old, new = body(historical, name), body(current, name)
            assert old == new
            source_bodies.append(dict(path=path, function=name, source_epoch=HANDOFF_REVISION, **I.digest(new.encode())))
    oracles['observer'].source_proof(texts[0], I.read(plan['matrices'][5]['source'] + '/LowerReaderTrace.pm')[0].decode())
    oracles['failures'].source_proof(texts[0], I.read(plan['matrices'][5]['source'] + '/LowerReaderTrace.pm')[0].decode(),
                                     I.read(plan['matrices'][6]['source'] + '/LowerReadControls.pm')[0].decode())
    selections = {}; counts = Counter(); selected_roots = []
    for name in ['ordinary-fresh', 'ordinary-existing', 'equal-fresh', 'equal-existing']:
        selected, tally, roots = select_archive(children[name], reports[name], arguments[name][0])
        selections[name] = selected; counts.update(tally); selected_roots.extend(roots)
        for mutation in ['lost caller close', 'invented failed source handoff', 'primary replaced', 'lost case']:
            changed = dict(reports[name], cases=list(reports[name]['cases']))
            position = next(i for i, row in enumerate(changed['cases']) if row['selector'] == selected[-1]['selector'])
            changed['cases'][position] = copy.deepcopy(changed['cases'][position]); op = changed['cases'][position]['operation']
            if mutation == 'lost caller close': op['events'].remove(selected[-1]['cleanup_events'][1])
            elif mutation == 'invented failed source handoff': op['events'].insert(0, 'opened:' + selected[-1]['selector'][:-7])
            elif mutation == 'primary replaced': op['error'] = 'cleanup error\n'
            else: changed['cases'].pop(position)
            reject(name + ': ' + mutation, lambda: select_archive(children[name], changed, arguments[name][0]), rejected)
    # Original hostile archive controls reject before the tracer receives a handle.
    original_rejections = []
    for selection, row in zip(children['filesystem']['cases'], reports['filesystem']['cases'], strict=True):
        if selection['change'] in ('changed_mode', 'hardlink'):
            assert row['operation']['returned'] == 0 and row['operation']['descriptors'] == []
            assert 'invalid image source mode, links or size' in row['operation']['error']
            original_rejections.append(dict(name=row['name'], observed_failed_source_descriptors=0))
    assert len(original_rejections) == 2
    source_mutations = [
        (0, 'return ($body, \\@before, $keep_open ? $fh : undef);', 'return ();'),
        (1, 'close($handle);', '# omitted close'),
        (1, 'die $error;', 'return {};'),
        (2, 'if (!close($writer))', 'if (0)'),
        (3, 'push @{$state->{sources}}, NativeProxyImageCustody::_source(', 'my $unowned = NativeProxyImageCustody::_source('),
        (3, 'my $close_error = _close_sources($state->{sources});', "my $close_error = '';"),
        (3, 'my $fresh = NativeProxyImageCustody::_source(', 'my $fresh = ignored_source('),
        (4, '_event("$label:before");', '# lost cut'),
        (5, 'my $source = $reader->(@_);', 'my $source = {};'),
    ]
    for index, old, new in source_mutations:
        changed = texts[:]; assert old in changed[index]; changed[index] = changed[index].replace(old, new)
        reject('source contract: ' + old, lambda: source_contract(changed), rejected)
    for name, mutate in [('missing domain', lambda p: p['matrices'].pop()),
                         ('wrong epoch', lambda p: p['matrices'][0].update(source_epoch=REVISION)),
                         ('wrong handoff epoch', lambda p: p['handoff'].update(completed_revision=REVISION))]:
        changed = copy.deepcopy(plan); mutate(changed); reject(name, lambda: domain(changed), rejected)
    for matrix in [plan['matrices'][5], plan['handoff']]:
        manifest = I.decoded(matrix['source'] + '/result/recovery-copies.json')
        changed = copy.deepcopy(manifest); changed['files'][0]['sha256'] = '0' * 64
        reject(matrix['source'] + ': corrupted recovery', lambda: receipts(matrix, changed), rejected)
    for name, mutate in [('lost source', lambda r: r['inputs'].pop()),
                         ('changed identity', lambda r: r['inputs'][0].update(inode=0)),
                         ('lost epoch comparison', lambda r: r['applicability'].pop())]:
        changed = copy.deepcopy(observed); mutate(changed)
        def inventory_equal(): assert changed == actual
        reject(name, inventory_equal, rejected)
    absent(all_roots); absent(selected_roots)
    direct_roots = reports['observer']['allocated'] + reports['failures']['allocated']
    absent(selected_roots + direct_roots)
    I.authenticate_pins(); assert I.census(plan) == observed
    output = dict(schema='fsmgen.inactive_archive_lower_reader_join_audit.v1', success=True,
        child_counts=child_counts, handoff_counts=handoff_counts, strict_failed_source_closures=len(strict),
        selections=selections, selected_archive_counts=dict(counts), selected_archive_roots=len(selected_roots),
        direct_reader_cases=len(direct_roots), selected_archive_and_direct_roots=len(selected_roots + direct_roots),
        all_saved_roots=len(all_roots), all_saved_tap_assertions=assertions, all_allocations_absent=True,
        source_files=observed['source_files'], source_bytes=observed['total_bytes'], epoch_comparisons=observed['epoch_comparisons'],
        exact_handoff_function_bodies=source_bodies, original_strict_rejections=original_rejections,
        raw_receipts=raw_receipts, prospective_pins=len(pins), falsifiers=rejected,
        source_observation_gap_closed=True, limits=plan['limits'])
    with (LOG / 'audit.json').open('x') as stream:
        stream.write(json.dumps(output, indent=2, sort_keys=True) + '\n')
    print(json.dumps({key: value for key, value in output.items() if key not in ['selections', 'child_counts', 'exact_handoff_function_bodies', 'falsifiers']}, sort_keys=True))


if __name__ == '__main__':
    main()
