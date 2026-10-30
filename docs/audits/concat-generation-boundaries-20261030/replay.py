"""Observe finite native boundaries; independently check each transition.

Run under scripts/run_with_ram_guard.sh. --saved validates the committed capture
and producer identities without starting native generation or rewriting evidence.
"""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
PROBE = str((HERE / 'probe.pl').relative_to(ROOT))
BASE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
MODES = ('observe', 'native', 'cache', 'reread', 'recovery_mutation', 'metadata_mutation', 'late_mutation')


def run(arguments):
    result = subprocess.run(arguments, cwd=ROOT, capture_output=True, text=True)
    return dict(command=arguments, status=result.returncode, stdout=result.stdout, stderr=result.stderr)


def normalize(value):
    if isinstance(value, str):
        return re.sub(r'^// Date:.*\n', '// Date: <normalized>\n', value, flags=re.M)
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    return value


def one(trace, stage):
    rows = [row for row in trace if row['stage'] == stage]
    assert len(rows) == 1, (stage, len(rows))
    return rows[0]


def validate(record):
    assert record['baseline']['status'] == 0
    baseline = json.loads(record['baseline']['stdout'])
    # Independent population from the original finite source producer, rather
    # than accepting whatever the instrument happened to observe.
    assert [(c['case'], c['rhs'], c['mutable']) for c in baseline['cases']] == [
        (name, rhs, mutable) for rhs in (0, 1) for mutable in (0, 1)
        for name in ('concat', 'concat_reversed', 'concat_repeated')]
    for mode in MODES:
        run_record = record['runs'][mode]
        assert run_record['status'] == 0, (mode, run_record['stderr'])
        observed = json.loads(run_record['stdout'])
        assert observed['mode'] == mode
        assert len(observed['collections']) == len(baseline['cases']) * 2
        assert normalize(observed['native']) == normalize(baseline), (mode, 'native products changed')
        for collection, (case, language) in zip(observed['collections'], [
                (case, language) for case in baseline['cases'] for language in ('systemverilog', 'verilog')]):
            trace = collection['trace']
            if case['rhs']:
                assert trace == [] and collection['frozen'] == {} and collection['inference'] == []
                continue
            assert len(collection['frozen']) == 1
            name, frozen = next(iter(collection['frozen'].items()))
            expected_names = {'concat': ['A', 'B'], 'concat_reversed': ['B', 'A'],
                              'concat_repeated': ['A', 'B', 'A']}[case['case']]
            assert frozen['raw']['record']['source_names'] == expected_names
            assert frozen['canonical']['record']['source_names'] == expected_names
            assert [operand['width'] for operand in frozen['canonical']['record']['operands']] == [
                {'A': 8, 'B': 3}[source] for source in expected_names]
            start = one(trace, 'normalization_entry')
            bound = one(trace, 'epoch_bound')
            assert start['width'] is None and start['runtime'] is None
            assert start['allocator'] != start['row'] != start['registered'] != start['allocator']
            assert start['ast'] == start['allocator_ast']
            assert start['raw_current'] and start['canonical_current']
            assert bound['epoch'] == 1 and bound['row_view'] and bound['complete'] is None
            for row in trace:
                assert row['name'] == name and row['row'] == start['row']
                for key in ('module', 'backend', 'width_owner', 'allocator', 'ast', 'allocator_ast'):
                    assert row[key] == start[key], (mode, row['stage'], key)
            resolution = one(trace, 'resolve_after')
            expected_width = sum({'A': 8, 'B': 3}[source] for source in expected_names)
            assert resolution['width'] == expected_width
            assert resolution['width_source'] == {'native': 'native_signal_metadata', 'cache': 'cached_width'}.get(mode, 'substituted_ast')
            assert collection['inference'] == ([] if mode in ('native', 'cache') else [name])
            if mode == 'reread':
                again = one(trace, 'reread_after')
                assert again['revision'] == 2 and again['width_source'] == 'cached_width'
                assert again['width'] == expected_width
            before = one(trace, 'publication_before')
            after = one(trace, 'publication_after')
            assert before['allocator_width'] is None and before['registered_width'] is None
            assert after['width'] == after['allocator_width'] == after['registered_width'] == expected_width
            assert after['width_source'] == after['allocator_source'] == after['registered_source']
            old = one(trace, 'replacement_before')
            new = one(trace, 'replacement_after')
            assert old['registered'] != new['registered']
            assert old['row_view'] == new['row_view'] == bound['row_view']
            assert one(trace, 'completion_before')['complete'] is None
            complete = one(trace, 'completion_after')
            assert complete['complete'] == complete['epoch'] == 1
            assert one(trace, 'collection_return')['registered'] == new['registered']
            live = trace[trace.index(start):]
            if mode.endswith('_mutation'):
                phase = mode.removesuffix('_mutation')
                assert collection['mutated'] == phase, (mode, 'control was never reached')
                stale = next(i for i, row in enumerate(live) if not row['raw_current'])
                assert stale > 0
                assert all(not row['raw_current'] and not row['canonical_current'] for row in live[stale:])
                boundary = {'recovery': 'recovery_before', 'metadata': 'metadata_callback', 'late': 'intrinsic_after'}[phase]
                assert live[stale]['stage'] == boundary, (mode, live[stale]['stage'])
            else:
                assert collection['mutated'] is None
                assert all(row['raw_current'] and row['canonical_current'] for row in live)


def hostile_controls(record):
    # Mutate complete saved records: the independent checker must reject an
    # unexercised callback, lost source barrier or unchanged registry identity.
    for defect in ('lost_barrier', 'registry_copy', 'missing_callback', 'numeric_native_as_intrinsic'):
        changed = copy.deepcopy(record)
        mode = 'metadata_mutation' if defect == 'missing_callback' else 'observe'
        if defect == 'numeric_native_as_intrinsic':
            mode = 'native'
        observed = json.loads(changed['runs'][mode]['stdout'])
        collection = observed['collections'][0]
        trace = collection['trace']
        if defect == 'lost_barrier':
            one(trace, 'publication_after')['raw_current'] = False
        elif defect == 'registry_copy':
            one(trace, 'replacement_after')['registered'] = one(trace, 'replacement_before')['registered']
        elif defect == 'missing_callback':
            collection['mutated'] = None
        else:
            collection['inference'] = [trace[0]['name']]
        changed['runs'][mode]['stdout'] = json.dumps(observed)
        try:
            validate(changed)
        except AssertionError:
            continue
        raise AssertionError(f'checker accepted {defect}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--saved', action='store_true')
    options = parser.parse_args()
    evidence = HERE / 'evidence.json.gz'
    if options.saved:
        record = json.loads(gzip.decompress(evidence.read_bytes()))
        for path, digest in record['source_sha256'].items():
            assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    else:
        record = {'schema_version': 1, 'revision': subprocess.check_output(
            ['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
            'baseline': run(['perl', '-Iperl', BASE]),
            'runs': {mode: run(['perl', '-Iperl', PROBE, mode]) for mode in MODES}}
        paths = subprocess.check_output(['git', 'ls-files', '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines()
        paths += [BASE, PROBE, str(Path(__file__).relative_to(ROOT))]
        record['source_sha256'] = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in sorted(set(paths))}
        record['first_attempts'] = {str(path.relative_to(ROOT)): path.read_text() for path in sorted(
            (ROOT / '.artifacts').glob('concat-generation-*.log'))}
        record['rederive'] = 'Actual retained fixed/mutable guard/RHS collection, source frames, numeric inference and owned transitions; complete native products compare with unobserved producer.'
        record['falsify'] = 'Native/cache bypasses and repeated-read control distinguish intrinsic inference; actual recovery/metadata/late nonoperand changes revoke original barriers. Independent saved-record mutations must reject lost barrier, registry substitution, unexercised callback and native-as-intrinsic.'
        record['durability'] = 'Tracked instrument/checker and complete source hashes, native products, detached source frames and ordered boundary traces, at the exact native Git revision.'
        record['limits'] = 'Observation only; no new event, generic sum/range/emission, runtime, external tool or full verification. Restored scalar writes without surviving revision are outside the raw observation contract.'
        # Preserve a first failing observation before its diagnosis is corrected.
        with gzip.GzipFile(filename=str(evidence), mode='wb', mtime=0) as stream:
            stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    validate(record)
    hostile_controls(record)
    print('Original source barriers, actual generation boundaries and hostile controls pass; native products preserve.')


if __name__ == '__main__':
    main()
