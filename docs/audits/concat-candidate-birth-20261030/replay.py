"""Focused source/target comparison; run from the repository under its RAM guard."""
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
REVISION = '1c08d7380'
MODULE = 'perl/FSM/HDL/ASTFactorization.pm'
TEST = 't/2276-concatenation-candidate-births.t'
PROBE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
WORK = ROOT / '.artifacts/concat-candidate-birth-replay'


def run(arguments):
    result = subprocess.run(arguments, cwd=ROOT, capture_output=True)
    return dict(command=arguments, status=result.returncode,
                stdout=result.stdout.decode(), stderr=result.stderr.decode())


def normalize(value):
    if isinstance(value, str):
        return re.sub(r'^// Date:.*\n', '// Date: <normalized>\n', value, flags=re.M)
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    return value


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    assert WORK.stat().st_dev == ROOT.stat().st_dev
    full_revision = subprocess.check_output(['git', 'rev-parse', REVISION], cwd=ROOT).decode().strip()
    original = subprocess.check_output(['git', 'show', f'{full_revision}:{MODULE}'], cwd=ROOT)
    capsule = WORK / 'ASTFactorization.pm'
    capsule.write_bytes(original)
    # Preload exact predecessor bytes before the test/probe's use lib 'perl'.
    # All other dependencies remain current. Assert loaded path and byte digest.
    relative = str(capsule.relative_to(ROOT))
    digest = hashlib.sha256(original).hexdigest()
    preload = ('use Digest::SHA qw(sha256_hex); '
               f'require "./{relative}"; '
               f'$INC{{"FSM/HDL/ASTFactorization.pm"}} = "{relative}"; '
               f'die "loaded path" unless $INC{{"FSM/HDL/ASTFactorization.pm"}} eq "{relative}"; '
               f'open my $fh, "<:raw", "{relative}" or die $!; '
               f'die "loaded bytes" unless do {{local $/; sha256_hex(<$fh>)}} eq "{digest}"; close $fh; ')
    current = run(['prove', '-Iperl', TEST])
    predecessor = run(['perl', '-Iperl', '-e', preload + f'do "./{TEST}"; die $@ if $@;'])
    current_probe = run(['perl', '-Iperl', PROBE])
    predecessor_probe = run(['perl', '-Iperl', '-e', preload + f'do "./{PROBE}"; die $@ if $@;'])
    assert current['status'] == 0, current
    # Test::More's END handler returns nonzero for the same missing producer API.
    assert predecessor['status'] != 0 and 'Failed test' in predecessor['stderr'], predecessor
    assert current_probe['status'] == predecessor_probe['status'] == 0
    actual = json.loads(current_probe['stdout'])
    prior = json.loads(predecessor_probe['stdout'])
    assert normalize(actual) == normalize(prior), 'complete native products differ beyond Date banners'
    for case in actual['cases']:
        assert case['caller_preserved'] is True
        for language, backend in case['backends'].items():
            if case['mutable'] and not case['rhs']:
                assert backend['hdl'] is None and backend['snapshot'] is None
                assert 'requires proved symbolic sum range' in backend['error']
            else:
                assert backend['error'] is None and backend['hdl'] and backend['snapshot'], (case['case'], language)
    paths = [MODULE, TEST, PROBE, 'perl/FSM/ConcatenationWidthBirthSupport.pm',
             str(Path(__file__).relative_to(ROOT))]
    first_logs = ['concat-birth-first-red.log', 'concat-birth-native-red.log',
                  'concat-birth-first-green.log', 'concat-birth-focused.log']
    record = dict(schema_version=1, predecessor_revision=full_revision,
                  producer_hashes={path: hashlib.sha256((ROOT/path).read_bytes()).hexdigest() for path in paths},
                  predecessor_module_sha256=digest, current=current, predecessor=predecessor,
                  current_probe=current_probe, predecessor_probe=predecessor_probe,
                  first_logs={path: (ROOT/'.artifacts'/path).read_text() for path in first_logs},
                  harness_corrections=[
                      'Initial guarded command could not inspect sessions in the sandbox; no test ran.',
                      'The indexed operand remains unfactored under the existing structural contract.',
                      'Native parser normalizes literal payload 0101 to 101 before allocation; raw Core constructors preserve 0101.',
                      'Capture actual assignment names directly in test scope, not a Test::More subroutine match.'],
                  rederive='Settled focused test against actual current allocator and native backend consumers.',
                  falsify='Same settled test with exact predecessor allocator preloaded; hostile ownership, raw literal, order and bounds controls.',
                  durability='Tracked module/test/producer and complete retained observations; Git retains exact predecessor.',
                  scope='Private candidate provenance only. Full native HDL/snapshot/error/caller products preserve with Date-only normalization. No source policy, generic range, VHDL or external execution qualification.')
    destination = Path(__file__).with_name('evidence.json.gz')
    with gzip.GzipFile(filename=str(destination), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('Current focused producer test passes; exact predecessor test fails; complete native products preserve.')


if __name__ == '__main__':
    main()
