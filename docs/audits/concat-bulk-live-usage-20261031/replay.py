"""Qualify concat complete-view bulk live-usage carry with exact predecessor and native products."""
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
TEST = 't/2284-concatenation-bulk-live-usage.t'
WIDTH = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm'
HELPER = 'perl/FSM/ConcatenationInferenceSupport.pm'
RECOVERY = 'perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm'
CHANGED = {WIDTH, HELPER, RECOVERY}
BASE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
PRIOR = 'docs/audits/concat-dependency-events-20261031/evidence.json.gz'


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
    before = json.loads(gzip.decompress((HERE / 'before.json.gz').read_bytes()))
    assert 'Result: FAIL' in before['red_log']
    archive = subprocess.check_output(['git', 'archive', '--format=tar', before['revision'], 'bin', 'perl', 'specs/Lispish.spec'], cwd=ROOT)
    work = Path(tempfile.mkdtemp(prefix='concat-bulk-predecessor-', dir=ROOT / '.artifacts'))
    assert work.stat().st_dev == ROOT.stat().st_dev
    with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
        stream.extractall(work, filter='data')
    for path, digest in before['source_sha256'].items():
        assert hashlib.sha256((work / path).read_bytes()).hexdigest() == digest, path
        if path not in CHANGED:
            assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    grammar = 'specs/Lispish.spec'
    original_grammar = subprocess.check_output(['git', 'show', f'{before["revision"]}:{grammar}'], cwd=ROOT)
    assert (work / grammar).read_bytes() == original_grammar == (ROOT / grammar).read_bytes()
    (work / 't').mkdir()
    (work / TEST).write_bytes((ROOT / TEST).read_bytes())
    predecessor = run(['prove', '-v', '-Iperl', TEST], work)
    assert predecessor['status'] != 0 and 'Result: FAIL' in predecessor['stdout'], predecessor
    assert 'not ok 4 - actual multi-row bulk priming' in predecessor['stdout'], predecessor
    for path in CHANGED:
        assert f'loaded {path} sha256={before["source_sha256"][path]}' in predecessor['stdout']
    focused = run(['prove', '-v', '-Iperl', TEST, 't/2283-concatenation-dependency-events.t'])
    assert focused['status'] == 0 and 'All tests successful' in focused['stdout'], focused
    for path in CHANGED:
        digest = hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
        assert f'loaded {path} sha256={digest}' in focused['stdout']
    native = run(['perl', '-Iperl', BASE])
    assert native['status'] == 0, native
    prior = json.loads(gzip.decompress((ROOT / PRIOR).read_bytes()))
    assert normalize(json.loads(native['stdout'])) == normalize(json.loads(prior['native']['stdout']))
    paths = set(before['source_sha256']) | {TEST, BASE, PRIOR, grammar,
        str(Path(__file__).relative_to(ROOT)), str((HERE / 'before.json.gz').relative_to(ROOT))}
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in sorted(paths)}
    changed = set(subprocess.check_output(['git', 'diff', '--name-only', before['revision'], '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines())
    assert changed == CHANGED, changed
    record = dict(schema_version=1, before_revision=before['revision'], predecessor=predecessor,
        predecessor_archive_sha256=hashlib.sha256(archive).hexdigest(), focused=focused,
        native=native, source_sha256=hashes,
        rederive='Actual complete-view bulk priming removes every original holder before getters/traversal, binds exact installed row membership/identities, validates original state before writes, and admits only independently retained actual per-row annotations. Semantic passes finish with getter-free whole-view/source barriers before atomic restoration.',
        falsify='Identical final test fails on authenticated predecessor bin/perl and grammar. Current actual multi-row and independent substitution/final root populations distinguish every boolean pair and mixed cached rows. Hostile roots, overwritten metadata, source/container/registry/revision changes, missing/stale proof, copied/partial views, early cross-row getters, late changes to an earlier checked row and exceptions cannot refresh or remint. Complete native caller/HDL/declaration/refusal products equal prior receipt with Date-only normalization.',
        durability='Tracked source, exact final test/replay producer, original RED test/log and native predecessor hashes, final predecessor/current/native logs and complete input hashes. Original constructor harness correction retains separately; its positional call did not satisfy the named signal_name constructor contract. No production defect is attributed to that test correction.',
        limits='Private bulk live-usage annotations only. Single-row fallback, annotation join, registry replacement, completed collection, symbolic sum/range/emission, VHDL and full6/publication remain open. Trusted built-in point-in-time read observations retain restored-scalar-write limits. No external HDL execution or new public syntax/report/MCP/corpus capability.')
    with gzip.GzipFile(filename=str(HERE / 'evidence.json.gz'), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('Bulk live-usage carry passes; identical predecessor fails; complete native products preserve.')


if __name__ == '__main__':
    main()
