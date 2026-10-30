"""Replay finite source observations and preserve complete native products."""
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
BASE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
PROBE = str((HERE / 'probe.pl').relative_to(ROOT))


def run(arguments):
    result = subprocess.run(arguments, cwd=ROOT, capture_output=True, text=True)
    return dict(command=arguments, status=result.returncode,
                stdout=result.stdout, stderr=result.stderr)


def normalize(value):
    if isinstance(value, str):
        return re.sub(r'^// Date:.*\n', '// Date: <normalized>\n', value, flags=re.M)
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    return value


def main():
    baseline = run(['perl', '-Iperl', BASE])
    observed = run(['perl', '-Iperl', PROBE])
    assert baseline['status'] == observed['status'] == 0, (baseline, observed)
    original = json.loads(baseline['stdout'])
    result = json.loads(observed['stdout'])
    assert normalize(original) == normalize(result['native']), 'observer changed complete native products'
    prior = json.loads(gzip.decompress((ROOT / 'docs/audits/concat-source-producer-selection-20261030/evidence.json.gz').read_bytes()))
    assert normalize(original) == normalize(json.loads(prior['baseline']['stdout'])), 'prior native products changed'
    assert len(result['observations']) == sum(len(case['backends']) for case in original['cases'])
    frames = [entry for collection in result['observations'] for entry in collection['frames']]
    assert frames, 'actual positive producer observation is required'
    for entry in frames:
        assert entry['current'] is True
        record = entry['frame']['record']
        assert record['kind'] == 'concatenation_source_observation'
        assert record['source_names'] in [['A', 'B'], ['B', 'A'], ['A', 'B', 'A']]
        for name in record['source_names']:
            assert record['source_signals'][name]['fields']['_declared_width_requirements']
    membership = subprocess.check_output(['git', 'ls-files', '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines()
    paths = set(membership) | {
        'perl/FSM/ConcatenationSourceObservationSupport.pm',
        't/2277-concatenation-source-observations.t', BASE, PROBE,
        str(Path(__file__).relative_to(ROOT)),
    }
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
              for path in sorted(paths) if (ROOT / path).is_file()}
    for path, digest in prior['source_sha256'].items():
        if path.startswith(('bin/', 'perl/')):
            assert hashes[path] == digest, f'pre-existing production owner changed: {path}'
    logs = {}
    for name in ['concat-source-observation-first.log', 'concat-source-observation-first-test.log',
                 'concat-source-observation-second-test.log', 'concat-source-observation-focused-final.log',
                 'concat-source-width-one-diagnosis.log', 'concat-source-width-one-diagnosis.json']:
        path = ROOT / '.artifacts' / name
        if path.is_file():
            logs[name] = path.read_text()
    preparation = ROOT / '.artifacts/tmp/concat-source-observation'
    first_sources = {name: (preparation / name).read_text() for name in
                     ['first-test.t', 'first-module.pm', 'second-test.t', 'diagnose.pl', 'width-one-native.pl']
                     if (preparation / name).is_file()}
    record = dict(schema_version=1,
                  revision=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                  source_sha256=hashes, baseline=baseline, observed=observed,
                  preparation_logs=logs, preparation_sources=first_sources,
                  preparation_corrections='Initial and repeated RHS tests wrongly demanded factorizer candidates for inline RHS profiles. Existing FactorizationPolicySupport feeds enables, conditions and flagged intermediate driving ASTs. The settled test proves actual guard frames and preserves inline RHS boundaries. A supplemental width-one diagnostic changed A without changing old expected DATA widths; its early validation failures are diagnostic-harness errors, not production defects. All original sources and failures are retained.',
                  rederive='Actual current factorizer/Core source observations plus complete native caller/HDL/declaration/refusal products; focused T2277 and T2276.',
                  falsify='Getter traps, stale/replaced/foreign source and complete nonoperand scope, malformed holders, exact scalar/depth/occurrence boundaries and owner lifetime controls; instrumented/uninstrumented/prior complete native products agree except Date banners.',
                  durability='Tracked source, regression, probe/replay, complete first failures and native products, exact producer hashes and Git capture boundary.',
                  limits='Private getter-free raw observations only. No canonical source eligibility, getter-versus-raw proof, persistent write history, generation completion, sum range/emission, generic override execution, VHDL, public/corpus or full .6 qualification.')
    with gzip.GzipFile(filename=str(HERE / 'evidence.json.gz'), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('Current native source observations and complete prior/uninstrumented products agree; raw/source-proof boundaries preserve.')


if __name__ == '__main__':
    main()
