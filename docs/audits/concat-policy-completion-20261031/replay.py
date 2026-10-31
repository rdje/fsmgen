"""Qualify original concatenation policy at actual collection completion."""
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
TEST = 't/2289-concatenation-policy-completion.t'
PRIOR = 'docs/audits/concat-registry-carry-20261031/evidence.json.gz'
BASE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
CHANGED = {'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm'}


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
    first = json.loads(gzip.decompress((HERE / 'first-native-check.json.gz').read_bytes()))
    before = first['revision']
    archive = subprocess.check_output(['git', 'archive', '--format=tar', before,
                                      'bin', 'perl', 'specs/Lispish.spec'], cwd=ROOT)
    work = Path(tempfile.mkdtemp(prefix='concat-policy-predecessor-', dir=ROOT / '.artifacts'))
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
                  str(Path(__file__).relative_to(ROOT)), str((HERE / 'first-native-check.json.gz').relative_to(ROOT)),
                  str((HERE / 'retained-row-diagnostic.json.gz').relative_to(ROOT))})}
    record['source_sha256'] = hashes
    print('Authenticated predecessor rejects missing API; running focused lifecycle checks.', flush=True)
    focused = run(['prove', '-v', '-Iperl', TEST, 't/2288-concatenation-registry-carry.t',
                   't/2226-arithmetic-graph-policy-completion.t'])
    record['focused'] = focused
    save(record)
    assert focused['status'] == 0 and 'All tests successful' in focused['stdout'], focused
    for path in CHANGED:
        assert f'loaded {path} sha256={hashes[path]}' in focused['stdout'], path
    # Remove only the final raw barrier in an isolated current-native fixture.
    # The later-row semantic mutation must leave a stale earlier holder there.
    owner = next(iter(CHANGED))
    current = (ROOT / owner).read_text()
    start = current.index('    # A later candidate\'s semantic getter can invalidate an earlier candidate.')
    end = current.index('    $self->{_width_inference_complete} =', start)
    counterfactual = current[:start] + current[end:]
    (work / owner).write_text(counterfactual)
    record['counterfactual_source'] = counterfactual
    record['counterfactual_sha256'] = hashlib.sha256(counterfactual.encode()).hexdigest()
    hostile = run(['prove', '-v', '-Iperl', TEST], work)
    record['without_raw_barrier'] = hostile
    save(record)
    assert hostile['status'] != 0 and 'late original holder is pruned or remains absent' in hostile['stderr'], hostile
    print('Known-bad missing final barrier rejected.', flush=True)
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
        rederive='Actual collection and prepared-block boundaries expose the same original detached intrinsic concat records only after normalization, pruning and final registry reset, for fixed/mutable guards in both Verilog-family backends. Selected inline RHS profiles expose no candidates. Current fixed guard policy retains the actual weak-view lifetime; detached records/rows cannot retain the map.',
        falsify='The identical final regression fails against authenticated original native bin/perl plus grammar because the API is absent. An isolated current-native mutation removes only the final getter-free barrier and genuinely fails the later-row callback pruning assertion. Real stale row/registry/source, missing-event and removal controls withhold; original collection/rendering errors clear maps and fresh backend reuse recovers. Complete native caller/HDL/declaration/refusal products equal the prior committed receipt with Date-only normalization. The actual later declaration resolver filtered-map revocation is explicitly observed and remains owned by emission integration.',
        durability='Tracked source, final fixed regression and replay, initial sandbox refusal, actual original missing-API failure, first implemented harness source/failures, retained-row diagnostic and complete final predecessor/current/counterfactual/native streams. Exact Git/archive/source identities bind the declared native owner; all other bin/perl bytes preserve.',
        limits='Private current selected numeric collection policy only. Later declaration resolver calls still revoke concat proof through a filtered row map; target integration owns repair before symbolic range/emission. No source grammar/report/MCP/corpus or generic capability change. Symbolic sum/range/emission, VHDL, external HDL/override/runtime, full6 and publication remain open. Raw observation retains trusted built-in/restored-scalar-write limits.',
    )
    save(record)
    print('Completed policy passes; original and missing-barrier controls fail; native products preserve.')


if __name__ == '__main__':
    main()
