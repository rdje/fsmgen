"""Qualify intrinsic concatenation events against native and exact predecessor controls."""
import argparse
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
REVISION = '963a8143a791322b25c911aa63b46f296349f224'
TEST = 't/2280-concatenation-inference-events.t'
BASE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
WIDTH = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm'
HELPER = 'perl/FSM/ConcatenationInferenceSupport.pm'


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
    native = run(['perl', '-Iperl', BASE])
    assert native['status'] == 0, native
    prior_path = ROOT / 'docs/audits/concat-source-freeze-20261030/evidence.json.gz'
    prior = json.loads(gzip.decompress(prior_path.read_bytes()))
    assert normalize(json.loads(native['stdout'])) == normalize(json.loads(prior['native']['stdout']))
    for path, digest in prior['source_sha256'].items():
        if path.startswith(('bin/', 'perl/')) and path != WIDTH:
            assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    work = Path(tempfile.mkdtemp(prefix='concat-inference-predecessor-', dir=ROOT / '.artifacts'))
    assert work.stat().st_dev == ROOT.stat().st_dev
    archive = subprocess.check_output(['git', 'archive', '--format=tar', REVISION, 'bin', 'perl'], cwd=ROOT)
    with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
        stream.extractall(work, filter='data')
    assert not (work / HELPER).exists()
    expected = subprocess.check_output(['git', 'show', f'{REVISION}:{WIDTH}'], cwd=ROOT)
    assert (work / WIDTH).read_bytes() == expected
    loaded = run(['perl', '-Iperl', '-MFSM::HDL::FlattenedDT', '-MDigest::SHA=sha256_hex', '-e',
                  'my $p=$INC{"FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm"};'
                  'open my $f,"<",$p or die $!;binmode $f;local $/;print "$p\\n",sha256_hex(<$f>),"\\n";'], work)
    assert loaded['status'] == 0 and loaded['stdout'].splitlines() == [WIDTH, hashlib.sha256(expected).hexdigest()], loaded
    (work / 't').mkdir()
    (work / TEST).write_bytes((ROOT / TEST).read_bytes())
    predecessor = run(['prove', '-Iperl', TEST], work)
    assert predecessor['status'] != 0 and 'intrinsic concatenation event accessor exists' in predecessor['stderr'], predecessor
    parser = argparse.ArgumentParser()
    parser.add_argument('--focused-log', help='Consume the just-run focused check at a repository-relative path.')
    args = parser.parse_args()
    if args.focused_log:
        log = ROOT / args.focused_log
        assert not Path(args.focused_log).is_absolute() and '..' not in Path(args.focused_log).parts
        assert log.resolve().is_relative_to(ROOT) and log.stat().st_dev == ROOT.stat().st_dev
        focused = dict(log=args.focused_log, stdout=log.read_text())
    else:
        focused = run(['prove', '-Iperl', TEST, 't/2279-concatenation-generation-sources.t'])
        assert focused['status'] == 0, focused
    assert 'All tests successful' in focused['stdout'] and 'Result: PASS' in focused['stdout'], focused
    paths = set(subprocess.check_output(['git', 'ls-files', '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines())
    paths.update([TEST, BASE, HELPER, str(Path(__file__).relative_to(ROOT)), str(prior_path.relative_to(ROOT)),
                  str((HERE / 'first-attempt.json.gz').relative_to(ROOT))])
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in sorted(paths)}
    changed = set(subprocess.check_output(['git', 'diff', '--name-only', REVISION, '--', 'bin', 'perl'],
                  cwd=ROOT, text=True).splitlines())
    changed.update(subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard', '--', 'bin', 'perl'],
                   cwd=ROOT, text=True).splitlines())
    assert changed == {WIDTH, HELPER}, changed
    record = dict(schema_version=1, revision=REVISION, native=native, predecessor=predecessor,
                  loaded=loaded, predecessor_archive_sha256=hashlib.sha256(archive).hexdigest(),
                  source_sha256=hashes, focused=focused,
                  rederive='Actual installed first unresolved resolver branch joins original pre-callback source freeze, complete bounded rows and selected numeric sum. Fixed/mutable independent operands, reversed/repeated/nested slots and explicit literal widths remain separate.',
                  falsify='The identical settled regression fails against exact predecessor bin/perl with loaded width module path/hash asserted. Equal native/cache and scalar fallback controls, actual callback/row/source/revision/late-getter changes, wrong numeric sum, unknown original Core literal width, detached/foreign holders, publication invalidation, weak expiry and success/abort/failure/recovery distinguish real current first inference from numeric agreement.',
                  durability='Tracked production/test/producers and exact hashes; complete predecessor archive identity and loaded witness; complete current/prior native caller/HDL/declaration/contextual refusal products compared with Date-only normalization; original failed harness source/log retained separately.',
                  limits='Private intrinsic event only. Resolver repeats carry only a held current event. Allocator/registry publication intentionally invalidates until separately owned carry/completion. No generic symbolic sum/range/emission, external compiler/override/runtime or full .6/publication qualification.')
    with gzip.GzipFile(filename=str(HERE / 'evidence.json.gz'), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('Intrinsic event focused checks pass; complete native products preserve; exact predecessor lacks events.')


if __name__ == '__main__':
    main()
