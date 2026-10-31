"""Qualify concat actual normalization live-usage join carry with exact predecessor and native products."""
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
TEST = 't/2286-concatenation-normalization-live-usage.t'
WIDTH = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm'
HELPER = 'perl/FSM/ConcatenationInferenceSupport.pm'
RECOVERY = 'perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm'
CHANGED = set()
BASE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
PRIOR = 'docs/audits/concat-fallback-live-usage-20261031/evidence.json.gz'


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


def main():
    before = json.loads(gzip.decompress((ROOT / 'docs/audits/concat-fallback-live-usage-20261031/before.json.gz').read_bytes()))
    assert 'Result: FAIL' in before['red_log']
    archive = subprocess.check_output(['git', 'archive', '--format=tar', before['revision'], 'bin', 'perl', 'specs/Lispish.spec'], cwd=ROOT)
    work = Path(tempfile.mkdtemp(prefix='concat-normalization-predecessor-', dir=ROOT / '.artifacts'))
    assert work.stat().st_dev == ROOT.stat().st_dev
    with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
        stream.extractall(work, filter='data')
    for path, digest in before['source_sha256'].items():
        assert hashlib.sha256((work / path).read_bytes()).hexdigest() == digest, path
    grammar = 'specs/Lispish.spec'
    original_grammar = subprocess.check_output(['git', 'show', f'{before["revision"]}:{grammar}'], cwd=ROOT)
    assert (work / grammar).read_bytes() == original_grammar == (ROOT / grammar).read_bytes()
    (work / 't').mkdir()
    (work / TEST).write_bytes((ROOT / TEST).read_bytes())
    predecessor = run(['prove', '-v', '-Iperl', TEST], work)
    assert predecessor['status'] != 0 and 'Result: FAIL' in predecessor['stdout'], predecessor
    assert 'not ok 3 - bulk fallback and mixed writers join' in predecessor['stdout'], predecessor
    assert f'loaded {RECOVERY} sha256={before["source_sha256"][RECOVERY]}' in predecessor['stdout']
    focused = run(['prove', '-v', '-Iperl', TEST, 't/2285-concatenation-fallback-live-usage.t'])
    assert focused['status'] == 0 and 'All tests successful' in focused['stdout'], focused
    for path in CHANGED:
        digest = hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
        assert f'loaded {path} sha256={digest}' in focused['stdout']
    native = run(['perl', '-Iperl', BASE])
    assert native['status'] == 0, native
    prior = json.loads(gzip.decompress((ROOT / PRIOR).read_bytes()))
    assert normalize(json.loads(native['stdout'])) == normalize(json.loads(prior['native']['stdout']))
    paths = set(before['source_sha256']) | {TEST, BASE, PRIOR, grammar,
        str(Path(__file__).relative_to(ROOT)), 'docs/audits/concat-fallback-live-usage-20261031/before.json.gz', str((HERE / 'first-check.json.gz').relative_to(ROOT))}
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in sorted(paths)}
    current_revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    changed = set(subprocess.check_output(['git', 'diff', '--name-only', current_revision, '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines())
    assert changed == CHANGED, changed
    record = dict(schema_version=1, before_revision=before['revision'], predecessor=predecessor,
        predecessor_archive_sha256=hashlib.sha256(archive).hexdigest(), focused=focused,
        native=native, source_sha256=hashes,
        rederive='Actual normalization runs bulk, fallback or fallback-then-bulk mixed writers through both metadata and public wrapper exits. Original intrinsic records, numeric sums, typed renders, intermediate-only dependencies, usage annotations and weak view lifetime preserve. Scalar/list/void contexts and fixed generation/mutable refusal preserve; no completed policy is granted.',
        falsify='Identical final integration test fails against authenticated88a625fea predecessor before fallback carry, while current committed writers pass. Late cached callbacks alter an earlier row or original source and withhold current events; missing proof stays absent. Wrapper failure clears all partial holders and rethrows original error; same backend clean generation obtains its own current events. Complete native caller/HDL/declaration/refusal products equal the committed fallback receipt with Date-only normalization. No new production algorithm is needed for this join.',
        durability='Tracked integration test/replay, complete first harness source/log with corrected contract expectations, authenticated predecessor/current/native streams and source hashes. Current bin/perl are unchanged from the recorded current revision; the older failing comparison qualifies prerequisite fallback carry, not a newly attributed production fix.',
        limits='Focused normalization join only. Complete annotation closure, registry replacement, completed collection, symbolic sum/range/emission, VHDL and full6/publication remain open. Trusted point-in-time observations retain restored-scalar-write limits. No external HDL execution or new public syntax/report/MCP/corpus capability.', current_revision=current_revision)
    with gzip.GzipFile(filename=str(HERE / 'evidence.json.gz'), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('Normalization live-usage join passes; identical predecessor fails; complete native products preserve.')


if __name__ == '__main__':
    main()
