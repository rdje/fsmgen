"""Qualify original concatenation proof across actual registry copies."""
import gzip
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
TEST = 't/2288-concatenation-registry-carry.t'
PRIOR = 'docs/audits/concat-annotation-closure-20261031/evidence.json.gz'
BASE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
CHANGED = {
    'perl/FSM/ConcatenationInferenceSupport.pm',
    'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm',
    'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm',
}


def run(command, cwd=ROOT):
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
    return dict(command=command, cwd=str(cwd.relative_to(ROOT)) or '.',
                status=result.returncode, stdout=result.stdout, stderr=result.stderr)


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
    first = json.loads(gzip.decompress((HERE / 'first-check.json.gz').read_bytes()))
    before = first['revision']
    archive = subprocess.check_output(['git', 'archive', '--format=tar', before,
                                      'bin', 'perl', 'specs/Lispish.spec'], cwd=ROOT)
    work = Path(tempfile.mkdtemp(prefix='concat-registry-predecessor-', dir=ROOT / '.artifacts'))
    assert work.stat().st_dev == ROOT.stat().st_dev
    with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
        stream.extractall(work, filter='data')
    previous_hashes = {}
    for path in sorted(CHANGED | {'specs/Lispish.spec'}):
        original = subprocess.check_output(['git', 'show', f'{before}:{path}'], cwd=ROOT)
        assert (work / path).read_bytes() == original
        previous_hashes[path] = hashlib.sha256(original).hexdigest()
    (work / 't').mkdir()
    (work / TEST).write_bytes((ROOT / TEST).read_bytes())
    record = dict(schema_version=1, before_revision=before, predecessor_sha256=previous_hashes,
                  archive_sha256=hashlib.sha256(archive).hexdigest())
    predecessor = run(['prove', '-v', '-Iperl', TEST], work)
    record['predecessor'] = predecessor
    save(record)
    assert predecessor['status'] != 0 and 'Result: FAIL' in predecessor['stdout'], predecessor
    for path in CHANGED:
        assert f'loaded {path} sha256={previous_hashes[path]}' in predecessor['stdout'], path
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
              for path in sorted(CHANGED | {TEST, BASE, PRIOR, 'specs/Lispish.spec',
                  str(Path(__file__).relative_to(ROOT)), str((HERE / 'first-check.json.gz').relative_to(ROOT)),
                  str((HERE / 'context-regression.json.gz').relative_to(ROOT))})}
    record['source_sha256'] = hashes
    focused = run(['prove', '-v', '-Iperl', TEST, 't/2287-concatenation-annotation-closure.t',
                   't/2206-factorizer-width-publication.t', 't/2224-arithmetic-graph-registry-publication.t'])
    record['focused'] = focused
    save(record)
    assert focused['status'] == 0 and 'All tests successful' in focused['stdout'], focused
    for path in CHANGED:
        assert f'loaded {path} sha256={hashes[path]}' in focused['stdout'], path
    context = json.loads(gzip.decompress((HERE / 'context-regression.json.gz').read_bytes()))
    result = subprocess.run(context['command'], cwd=ROOT, input=context['producer'],
                            capture_output=True, text=True)
    record['context_regression_after'] = dict(command=context['command'], input=context['producer'],
        status=result.returncode, stdout=result.stdout, stderr=result.stderr)
    save(record)
    assert result.returncode == 0, record['context_regression_after']
    native = run(['perl', '-Iperl', BASE])
    record['native'] = native
    save(record)
    assert native['status'] == 0, native
    prior = json.loads(gzip.decompress((ROOT / PRIOR).read_bytes()))
    assert normalize(json.loads(native['stdout'])) == normalize(json.loads(prior['native']['stdout']))
    changed = set(subprocess.check_output(['git', 'diff', '--name-only', before, '--', 'bin', 'perl'],
                                         cwd=ROOT, text=True).splitlines())
    assert changed == CHANGED, changed
    for path, digest in hashes.items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    record.update(
        rederive='Actual final registry reset and subsequent ordinary merge retain the same original detached source contracts and intrinsic records, exact installed map/row identities, complete existing/merged/name copies, ordinary fixed generation and mutable refusal in both Verilog-family backends. No completed allocation authority is added. Retained original holders/rows do not retain the weak view.',
        falsify='Identical final regression fails against authenticated original native bin/perl and grammar. During real graph-restoration callbacks, both source/event maps remain withheld; changed metadata, equal row/map substitutions, partial/extra membership, allocator/nonoperand source changes, equal nested arrays, proof-map replacements/inserts and later semantic getters all prevent any partial refresh. Original callback exceptions propagate and clean same-backend generations recover. The recorded introduced return/context regression fails before its correction and the identical probe passes afterward; injected/absent providers and directly affected binary/graph registry regressions preserve. Complete native caller/HDL/declaration/contextual-refusal products equal the committed annotation receipt under Date-only normalization.',
        durability='Tracked source, fixed regression/replay, first harness source/log with actual-LHS cleanup correction, exact original Git/archive/source identities, and complete final predecessor/current/native streams. Git diff enumerates the entire native bin/perl population and admits only the declared changed owners; every other production file remains byte-exact. Selected production hashes remain stable during the check.',
        limits='Paired original current source/intrinsic holders only. Source-only or spent/missing proof cannot infer a new event. Trusted built-in raw observation retains restored-scalar-write limits. Completed collection policy, symbolic sum/range/emission, arbitrary source/API/MCP/corpus qualification, VHDL, external HDL/overrides/runtime, full6 and publication remain open.',
    )
    save(record)
    print('Registry carry passes; identical predecessor fails; hostile callbacks withhold; native products preserve.')


if __name__ == '__main__':
    main()
