"""Qualify original concatenation carry across stable filtered resolver views."""
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
TEST = 't/2293-concatenation-filtered-projections.t'
OWNER = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm'
PROBE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
BEFORE = 'bbe2dd378'


def run(command, cwd=ROOT):
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
    return dict(command=command, cwd=str(cwd.relative_to(ROOT)) or '.', status=result.returncode,
                stdout=result.stdout, stderr=result.stderr)


def save(record):
    with gzip.GzipFile(filename=str(HERE / 'evidence.json.gz'), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())


def normalize(value):
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if isinstance(value, str):
        return re.sub(r'^// Date:.*\n', '// Date: <normalized>\n', value, flags=re.M)
    return value


def main():
    revision = subprocess.check_output(['git', 'rev-parse', BEFORE], cwd=ROOT, text=True).strip()
    archive = subprocess.check_output(['git', 'archive', '--format=tar', revision,
                                      'bin', 'perl', 'specs/Lispish.spec'], cwd=ROOT)
    original = subprocess.check_output(['git', 'show', f'{revision}:{OWNER}'], cwd=ROOT)
    paths = [OWNER, TEST, 't/2289-concatenation-policy-completion.t',
             't/2292-concatenation-completed-sums.t', PROBE,
             str(Path(__file__).relative_to(ROOT)), str((HERE / 'first-check.json.gz').relative_to(ROOT))]
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in paths}
    record = dict(schema_version=1, before_revision=revision, source_sha256=hashes,
                  archive_sha256=hashlib.sha256(archive).hexdigest(),
                  predecessor_owner_sha256=hashlib.sha256(original).hexdigest())
    with tempfile.TemporaryDirectory(prefix='concat-projection-', dir=ROOT / '.artifacts/tmp') as directory:
        work = Path(directory)
        assert work.stat().st_dev == ROOT.stat().st_dev
        with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
            stream.extractall(work, filter='data')
        assert (work / OWNER).read_bytes() == original
        (work / 't').mkdir()
        (work / TEST).write_bytes((ROOT / TEST).read_bytes())
        (work / PROBE).parent.mkdir(parents=True)
        (work / PROBE).write_bytes((ROOT / PROBE).read_bytes())
        record['predecessor'] = red = run(['prove', '-v', '-Iperl', TEST], work)
        save(record)
        assert red['status'] != 0 and 'original completed sum survives actual filtered declaration resolution' in red['stderr'], red
        assert f'loaded {OWNER} sha256={record["predecessor_owner_sha256"]}' in red['stderr']
        record['focused'] = focused = run(['prove', '-v', '-Iperl', TEST,
                                          't/2289-concatenation-policy-completion.t',
                                          't/2292-concatenation-completed-sums.t'])
        save(record)
        assert focused['status'] == 0 and 'All tests successful' in focused['stdout'], focused
        assert f'loaded {OWNER} sha256={hashes[OWNER]}' in focused['stderr']
        current = (ROOT / OWNER).read_text()
        final = '        && FSM::ConcatenationInferenceSupport::_same(\n            $self->_concatenation_resolver_projection($signal_name, $signal_info, $signal_registry), $concat_projection)\n'
        before_revision = '    ++$self->{_width_inference_revisions}{$signal_name} if $self->{_width_inference_epoch};'
        controls = {
            'missing_final_projection_check': (
                current.replace(final, '', 1),
                'late_remove changed projection/source cannot refresh original proof'),
            'refresh_projection_after_getters': (
                current.replace(before_revision, '    $concat_projection = $self->_concatenation_resolver_projection($signal_name, $signal_info, $signal_registry) if $concat_projection;\n' + before_revision, 1),
                'early_remove changed projection/source cannot refresh original proof'),
        }
        record['counterfactuals'] = {}
        for name, (source, needle) in controls.items():
            assert source != current
            (work / OWNER).write_text(source)
            result = run(['prove', '-v', '-Iperl', TEST], work)
            record['counterfactuals'][name] = dict(source=source, sha256=hashlib.sha256(source.encode()).hexdigest(), result=result)
            save(record)
            assert result['status'] != 0 and needle in result['stderr'], result
        # The saved native producer is unchanged and reads no private proof API.
        # Restore the exact native owner after isolated bad-owner controls.
        (work / OWNER).write_bytes(original)
        record['native_predecessor'] = old = run(['perl', '-Iperl', PROBE], work)
        record['native_current'] = new = run(['perl', '-Iperl', PROBE])
        save(record)
        assert old['status'] == new['status'] == 0, (old, new)
        assert normalize(json.loads(old['stdout'])) == normalize(json.loads(new['stdout']))
    changed = set(subprocess.check_output(['git', 'diff', '--name-only', revision, '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines())
    assert changed == {OWNER}, changed
    for path, digest in hashes.items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    record.update(
        rederive='Actual declaration rendering uses a distinct filtered map whose members alias canonical original rows. Held numeric events and completed sums now survive those real calls in both Verilog-family backends; numeric resolution still consumes the original supplied projection. Bounded complete projection identity/membership is frozen before all allocation getters and rechecked after every semantic callback with final canonical raw source/row proof.',
        falsify='Identical final T2293 reproduces actual native predecessor event loss. Two isolated current-owner controls omit the final projection comparison or refresh its snapshot after early getters; actual late and early member-removal assertions genuinely fail. Copied/foreign/missing/extra/oversized/non-map rows/views, absent proof, native metadata, late source/row/registry/proof-map changes, withheld callback authority, clean backend reuse and weak lifetime controls pass. Complete native caller/HDL/declaration/refusal products preserve under Date-only normalization.',
        durability='Tracked source/test/replay and complete predecessor/current/counterfactual/native sources, original streams, archive/input hashes and first failed harness snapshot. That lifetime harness retained its own canonical-map local; release it before asserting expiry. Current completion/join checks and unchanged producer hashes qualify the correction without attributing a compiler defect.',
        limits='Private held-event carry through bounded stable aliased subsets only. A distinct plain map of actual rows may qualify; this proves neither prepared-block producer origin nor physical target namespace membership. Canonical inference/source currentness and numeric resolver inputs remain unchanged; missing proof cannot mint through projections. Mutable target refusal, target range/declaration/expression/ledger work, unsized literal sizing, VHDL, external compiler/override/runtime and full6/publication remain open. No new source/API/report/MCP/corpus capability.',
    )
    save(record)
    print('Filtered declaration carry passes; native predecessor and early/late projection controls fail; native products preserve.')


if __name__ == '__main__':
    main()
