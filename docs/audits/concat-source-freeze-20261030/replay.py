"""Qualify the original generation source freeze with exact native controls."""
import gzip
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import tarfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
REVISION = '94a05fa40969cf18f6056a73a9503011e188c101'
TEST = 't/2279-concatenation-generation-sources.t'
BASE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
WIDTH = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm'
WORK = ROOT / '.artifacts/concat-source-freeze-predecessor'


def run(arguments, cwd=ROOT):
    result = subprocess.run(arguments, cwd=cwd, capture_output=True, text=True)
    return dict(command=arguments, cwd=str(cwd.relative_to(ROOT)) or '.', status=result.returncode,
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
    revision = subprocess.check_output(['git', 'rev-parse', REVISION], cwd=ROOT, text=True).strip()
    native = run(['perl', '-Iperl', BASE])
    assert native['status'] == 0, native
    prior_path = ROOT / 'docs/audits/concat-generation-boundaries-20261030/evidence.json.gz'
    prior = json.loads(gzip.decompress(prior_path.read_bytes()))
    assert normalize(json.loads(native['stdout'])) == normalize(json.loads(prior['baseline']['stdout']))
    WORK.mkdir(parents=True, exist_ok=True)
    assert WORK.stat().st_dev == ROOT.stat().st_dev
    archive = subprocess.check_output(['git', 'archive', '--format=tar', revision, 'bin', 'perl'], cwd=ROOT)
    with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
        stream.extractall(WORK, filter='data')
    assert not (WORK / 'perl/FSM/ConcatenationGenerationSourceSupport.pm').exists()
    expected = subprocess.check_output(['git', 'show', f'{revision}:{WIDTH}'], cwd=ROOT)
    assert (WORK / WIDTH).read_bytes() == expected
    loaded = run(['perl', '-Iperl', '-MFSM::HDL::FlattenedDT', '-MDigest::SHA=sha256_hex', '-e',
                  'my $p=$INC{"FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm"};'
                  'open my $f,"<",$p or die $!;binmode $f;local $/;print "$p\\n",sha256_hex(<$f>),"\\n";'], WORK)
    assert loaded['status'] == 0 and loaded['stdout'].splitlines() == [WIDTH, hashlib.sha256(expected).hexdigest()], loaded
    (WORK / 't').mkdir(exist_ok=True)
    (WORK / TEST).write_bytes((ROOT / TEST).read_bytes())
    predecessor = run(['prove', '-Iperl', TEST], WORK)
    assert predecessor['status'] != 0 and 'original generation source freeze exists' in predecessor['stderr'], predecessor
    paths = set(subprocess.check_output(['git', 'ls-files', '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines())
    paths.update([TEST, BASE, 'perl/FSM/ConcatenationGenerationSourceSupport.pm',
                  str(Path(__file__).relative_to(ROOT)), str(prior_path.relative_to(ROOT))])
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in sorted(paths)}
    changed = set(subprocess.check_output(['git', 'diff', '--name-only', revision, '--', 'bin', 'perl'],
                  cwd=ROOT, text=True).splitlines())
    changed.update(subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard', '--', 'bin', 'perl'],
                   cwd=ROOT, text=True).splitlines())
    assert changed == {WIDTH, 'perl/FSM/ConcatenationGenerationSourceSupport.pm'}, changed
    record = dict(schema_version=1, revision=revision, native=native, predecessor=predecessor,
                  loaded=loaded, predecessor_archive_sha256=hashlib.sha256(archive).hexdigest(), source_sha256=hashes,
                  focused_logs={str(path.relative_to(ROOT)): path.read_text() for path in sorted(
                      (ROOT / '.artifacts').glob('concat-source-freeze-*.log'))},
                  rederive='Actual installed normalization freezes complete original raw scopes before canonical getters. Focused tests exercise actual fixed/mutable guard generation, ordered source contracts and current getter bindings.',
                  falsify='Same settled regression fails with byte-exact predecessor production and an independently asserted loaded width module. Actual two-candidate getter mutation, cache/signed exclusion, copied/tampered/foreign holders, same-epoch rebind/abort, weak-view expiry and same-backend success/failure/recovery distinguish stale recapture from original source proof.',
                  durability='Tracked production/test/producer and complete exact source hashes, focused logs, original native products and native archive/loaded identities at the committed predecessor boundary.',
                  limits='Private source freeze only; no intrinsic event, selected sum proof, completed policy, generic range/emission, external/runtime, public/corpus or full .6/publication qualification. Initial registry replacement invalidates source frames; future event carry has separate ownership.')
    with gzip.GzipFile(filename=str(HERE / 'evidence.json.gz'), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('Original generation source freeze qualifies; complete native products preserve; exact predecessor lacks the freeze.')


if __name__ == '__main__':
    main()
