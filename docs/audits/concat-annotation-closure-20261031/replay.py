"""Check actual concatenation annotation closure without external HDL execution."""
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
TEST = 't/2287-concatenation-annotation-closure.t'
BASE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
PRIOR = 'docs/audits/concat-normalization-live-usage-20261031/evidence.json.gz'


def run(command):
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    return dict(command=command, cwd='.', status=result.returncode,
                stdout=result.stdout, stderr=result.stderr)


def normalize(value):
    if isinstance(value, str):
        return re.sub(r'^// Date:.*\n', '// Date: <normalized>\n', value, flags=re.M)
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    return value


def save(record):
    with gzip.GzipFile(filename=str(HERE / 'evidence.json.gz'), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())


def main():
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    record = dict(schema_version=1, revision=revision)
    paths = subprocess.check_output(['git', 'ls-files', '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines()
    # Membership comes from Git, with each actual byte string independently
    # compared to its committed blob. No dependency/submodule source is opened.
    source_hashes = {}
    for path in paths:
        data = (ROOT / path).read_bytes()
        original = subprocess.check_output(['git', 'show', f'{revision}:{path}'], cwd=ROOT)
        assert data == original, path
        source_hashes[path] = hashlib.sha256(data).hexdigest()
    record['unchanged_production_sha256'] = source_hashes
    record['source_sha256'] = {
        path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
        for path in [TEST, BASE, PRIOR, 'specs/Lispish.spec',
                     str(Path(__file__).relative_to(ROOT)), str((HERE / 'first-check.json.gz').relative_to(ROOT))]
    }
    focused = run(['prove', '-v', '-Iperl', TEST, 't/2286-concatenation-normalization-live-usage.t'])
    record['focused'] = focused
    save(record)
    assert focused['status'] == 0 and 'All tests successful' in focused['stdout'], focused
    for path in [
        'perl/FSM/ConcatenationInferenceSupport.pm',
        'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm',
        'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm',
    ]:
        assert f'loaded {path} sha256={source_hashes[path]}' in focused['stdout'], path
    native = run(['perl', '-Iperl', BASE])
    record['native'] = native
    save(record)
    assert native['status'] == 0, native
    prior = json.loads(gzip.decompress((ROOT / PRIOR).read_bytes()))
    assert normalize(json.loads(native['stdout'])) == normalize(json.loads(prior['native']['stdout']))
    for path, digest in source_hashes.items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    assert subprocess.check_output(['git', 'diff', '--name-only', revision, '--', 'bin', 'perl'],
                                   cwd=ROOT, text=True) == ''
    record.update(
        rederive='Actual first intrinsic events are joined through the complete real normalization sequence. Independently authored source sums, order, repeated operands, literal nesting, source widths and width-one rank qualify fixed/mutable guard applicability in both Verilog backends. Selected inline RHS sources expose no concat candidate. Original merged/allocator/initial-registry/source identities and same complete event records preserve at the real normalization exit; no completed allocation or maximum policy is granted.',
        falsify='Actual renderer callbacks change unknown metadata, fallback tags, allocator/registered rows or original source state: later normalizer annotations cannot restore held proof. Exact original callback error aborts all partial events; clean backend reuse recovers. Neighbor T2286 retains late cached callback, failure and both-exit/context coverage. Complete native caller/HDL/declaration/contextual-refusal products match the committed prior receipt under Date-only normalization. The initial harness scope/error-text mistakes are retained, not attributed to production.',
        durability='Tracked fixed source expectations, regression, replay, original failed harness and complete final focused/native streams, committed production membership/blob equality, all source hashes and Git. Production code is unchanged; this is focused integration qualification rather than a newly attributed compiler fix.',
        limits='Only the selected direct guard and inline RHS source profiles and point-in-time observation contract qualify. No arbitrary RHS population, restored-scalar-write detection, registry replacement, completed concat policy, symbolic sum/range/emission, VHDL, external HDL execution, override, full6 or publication success.',
    )
    save(record)
    print('Annotation closure passes; hostile callbacks withhold; complete native products preserve.')


if __name__ == '__main__':
    main()
