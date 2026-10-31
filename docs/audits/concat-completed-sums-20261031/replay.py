"""Qualify the original completed concatenation sum join, without target admission."""
import gzip
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
TEST = 't/2292-concatenation-completed-sums.t'
OWNER = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm'
BEFORE = '3b62093a4'


def run(command, cwd=ROOT):
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
    return dict(command=command, cwd=str(cwd.relative_to(ROOT)) or '.', status=result.returncode,
                stdout=result.stdout, stderr=result.stderr)


def save(record):
    with gzip.GzipFile(filename=str(HERE / 'evidence.json.gz'), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())


def main():
    revision = subprocess.check_output(['git', 'rev-parse', BEFORE], cwd=ROOT, text=True).strip()
    archive = subprocess.check_output(['git', 'archive', '--format=tar', revision,
                                      'bin', 'perl', 'specs/Lispish.spec'], cwd=ROOT)
    original = subprocess.check_output(['git', 'show', f'{revision}:{OWNER}'], cwd=ROOT)
    paths = [OWNER, TEST, 'perl/FSM/ConcatenationSourceWidthSupport.pm',
             'perl/FSM/ConcatenationGenerationSourceSupport.pm', 'perl/FSM/ConcatenationInferenceSupport.pm',
             str(Path(__file__).relative_to(ROOT)), str((HERE / 'first-check.json.gz').relative_to(ROOT))]
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in paths}
    record = dict(schema_version=1, before_revision=revision, source_sha256=hashes,
                  archive_sha256=hashlib.sha256(archive).hexdigest(),
                  predecessor_owner_sha256=hashlib.sha256(original).hexdigest())
    with tempfile.TemporaryDirectory(prefix='concat-completed-', dir=ROOT / '.artifacts/tmp') as directory:
        work = Path(directory)
        assert work.stat().st_dev == ROOT.stat().st_dev
        with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
            stream.extractall(work, filter='data')
        assert (work / OWNER).read_bytes() == original
        (work / 't').mkdir()
        (work / TEST).write_bytes((ROOT / TEST).read_bytes())
        record['predecessor'] = red = run(['prove', '-v', '-Iperl', TEST], work)
        save(record)
        assert red['status'] != 0 and 'separate original completed concatenation sum accessor exists' in red['stderr'], red
        assert f'loaded {OWNER} sha256={record["predecessor_owner_sha256"]}' in red['stderr']
        record['focused'] = focused = run(['prove', '-v', '-Iperl', TEST,
                                          't/2289-concatenation-policy-completion.t',
                                          't/2291-concatenation-source-sums.t'])
        save(record)
        assert focused['status'] == 0 and 'All tests successful' in focused['stdout'], focused
        assert f'loaded {OWNER} sha256={hashes[OWNER]}' in focused['stderr']
        current = (ROOT / OWNER).read_text()
        controls = {
            'missing_final_raw_barrier': (
                current.replace('            && FSM::ConcatenationInferenceSupport->live_usage_current_raw(%args, holder => $checkpoint);', ';', 1),
                'row final complete barrier withholds changed join'),
            'missing_numeric_agreement': (
                current.replace('            && $sum->{record}{width} eq FSM::IntermediateWidthAllocationSupport::_width($allocation->{selected_width});', ';', 1),
                'sum_width final complete barrier withholds changed join'),
        }
        record['counterfactuals'] = {}
        for name, (source, needle) in controls.items():
            assert source != current
            (work / OWNER).write_text(source)
            result = run(['prove', '-v', '-Iperl', TEST], work)
            record['counterfactuals'][name] = dict(source=source, sha256=hashlib.sha256(source.encode()).hexdigest(), result=result)
            save(record)
            assert result['status'] != 0 and needle in result['stderr'], result
    changed = set(subprocess.check_output(['git', 'diff', '--name-only', revision, '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines())
    assert changed == {OWNER}, changed
    for path, digest in hashes.items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    record.update(
        rederive='Actual original collection and prepared-block boundaries expose original numeric allocation and independently derived ordered source sum only after successful completion. Independent source-slot numeric/rank/literal and emitted-arithmetic override oracles qualify both Verilog-family backends and actual inline-RHS applicability.',
        falsify='Identical test rejects authenticated native predecessor missing accessor. Two isolated current-owner controls remove only the final raw barrier or selected-width agreement; actual late row mutation and incorrect sum width assertions genuinely fail. Missing/foreign/stale proof, late source/nonoperand/row/registry/holder/map/view/epoch/completion changes, failure/reset/reuse, detachment and weak lifetime controls pass.',
        durability='Tracked source/test/producer and complete predecessor/current/counterfactual sources, original streams, archive/input hashes and first successful test snapshot. Temporary predecessor fixture is isolated on the repository volume and removed only after evidence capture.',
        limits='Private derived completed join only; canonical shared source profile is systemverilog. No target filtered projection, namespace/physical declaration/expression or emitted-ledger proof, unsized literal admission, new source/API/report/MCP/corpus capability, VHDL, external compiler/override/runtime or full6/publication qualification.',
    )
    save(record)
    print('Original completed sums pass; native predecessor, missing raw barrier and missing numeric agreement controls fail.')


if __name__ == '__main__':
    main()
