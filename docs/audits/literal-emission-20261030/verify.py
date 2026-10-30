#!/usr/bin/env python3
"""Capture or read the bounded literal-emission checks; never execute HDL."""
import argparse
import base64
import copy
import gzip
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
WIDTH = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/SourceLiteralWidthSupport.pm'
ASSEMBLY = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm'
TEST = 't/2268-target-source-literal-emission.t'
BASELINE = 'e527114cc'
SLOT = '.artifacts/literal-emission-20261030/qualification'


def pack(raw):
    return dict(data_base64=base64.b64encode(raw).decode(), bytes=len(raw),
                sha256=hashlib.sha256(raw).hexdigest())


def unpack(item):
    raw = base64.b64decode(item['data_base64'], validate=True)
    assert type(item['bytes']) is int and len(raw) == item['bytes']
    assert hashlib.sha256(raw).hexdigest() == item['sha256']
    return raw


def capture():
    receipt = HERE / 'receipt.json.gz'
    assert not receipt.exists(), 'never overwrite retained evidence'
    slot = ROOT / SLOT
    slot.mkdir(parents=True, exist_ok=False)
    names = [WIDTH, ASSEMBLY, TEST, str(Path(__file__).relative_to(ROOT)),
             'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm',
             'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm',
             'perl/FSM/Synthesis/EnableGraph/ASTSupport.pm',
             't/2267-target-source-literal-declarations.t',
             't/2248-source-tree-symbolic-range-emission.t']
    sources = {name: pack((ROOT / name).read_bytes()) for name in names}
    native = subprocess.check_output(['git', 'show', BASELINE + ':' + WIDTH], cwd=ROOT)
    module = WIDTH.removeprefix('perl/')
    target = slot / 'native' / module
    target.parent.mkdir(parents=True)
    target.write_bytes(native)
    marker = b'        $literal_fence->();'
    assembly = unpack(sources[ASSEMBLY])
    assert assembly.count(marker) == 1
    variant = assembly.replace(marker, b'        # counterfactual: omit final literal generation fence')
    module = ASSEMBLY.removeprefix('perl/')
    target = slot / 'no-generation-fence' / module
    target.parent.mkdir(parents=True)
    target.write_bytes(variant)
    preload = ('my $p=$INC{$ARGV[0]}; shift @ARGV; open my $fh,"<",$p or die $!;'
               'binmode $fh; print "loaded=$p sha256=",Digest::SHA->new(256)'
               '->addfile($fh)->hexdigest,"\\n"; do "./' + TEST + '"; die $@ if $@;')
    commands = {
        'native-red': ['perl', '-I' + SLOT + '/native', '-Iperl', '-M' + WIDTH[5:-3].replace('/', '::'),
                       '-MDigest::SHA', '-e', preload, WIDTH[5:]],
        'focused': ['prove', '-Iperl', TEST, 't/2267-target-source-literal-declarations.t',
                    't/2248-source-tree-symbolic-range-emission.t'],
        'no-generation-fence': ['perl', '-I' + SLOT + '/no-generation-fence', '-Iperl',
                                '-M' + ASSEMBLY[5:-3].replace('/', '::'),
                                '-MDigest::SHA', '-e', preload, ASSEMBLY[5:]],
    }
    runs = {}
    for name, command in commands.items():
        result = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        raw = result.stdout.replace(str(ROOT).encode(), b'<repo>')
        (slot / (name + '.log')).write_bytes(raw)
        runs[name] = dict(command=command, status=result.returncode, log=pack(raw))
        print(name, 'status', result.returncode, flush=True)
    historical = {}
    for name in ('red.log', 'first.log', 'first-admitted.log', 'focused.log',
                 'final-focused.log', 'one-bit-repaired.log', 'before-one-bit-repair.json'):
        path = ROOT / '.artifacts/literal-emission-20261030' / name
        historical[name] = pack(path.read_bytes().replace(str(ROOT).encode(), b'<repo>'))
    record = dict(kind='literal_emission_20261030',
                  baseline=subprocess.check_output(['git', 'rev-parse', BASELINE], cwd=ROOT).decode().strip(),
                  scope='Native literal emission ledgers, one-bit rank, atomic refusal and reuse; no HDL execution.',
                  environment=dict(python=sys.version, perl=subprocess.check_output(
                      ['perl', '-V:version'], cwd=ROOT).decode(),
                      system_dependency='Installed read-only operating-system Perl and Test::More; no external repository writes.'),
                  sources=sources, native=pack(native), no_generation_fence=pack(variant), runs=runs,
                  historical=historical,
                  gaps=['Named sources are not a complete historical dependency or environment capsule.',
                        'Earlier diagnostic logs have no exact per-run loaded test/dependency snapshot.',
                        'Source/target full Core agreement for unsized mutable literals remains separately owned.',
                        'No compiler, external override/runtime, full feature, corpus/API/MCP or publication qualification.',
                        'Saved identity checking is not an unconditional future behavior watcher.'])
    for name, item in sources.items():
        assert (ROOT / name).read_bytes() == unpack(item), 'source changed during capture: ' + name
    receipt.write_bytes(gzip.compress(json.dumps(record, sort_keys=True).encode(), mtime=0))
    return record


def verify(record, current=False):
    assert record['kind'] == 'literal_emission_20261030' and record['gaps']
    assert record['scope'].startswith('Native literal emission ledgers,')
    for path, item in record['sources'].items():
        assert not Path(path).is_absolute() and '..' not in Path(path).parts
        raw = unpack(item)
        if current:
            assert (ROOT / path).read_bytes() == raw, path
    native = unpack(record['native'])
    assert b'sub prepare_emission {' not in native
    assembly = unpack(record['sources'][ASSEMBLY])
    assert unpack(record['no_generation_fence']) == assembly.replace(
        b'        $literal_fence->();', b'        # counterfactual: omit final literal generation fence')
    expected = {'native-red': 1, 'focused': 0, 'no-generation-fence': 1}
    assert set(record['runs']) == set(expected)
    for name, status in expected.items():
        run = record['runs'][name]
        assert type(run['status']) is int and run['status'] == status
        log = unpack(run['log']).decode()
        if name == 'focused':
            assert 'All tests successful.' in log and 'Files=3, Tests=14' in log
        else:
            variant = record['native'] if name == 'native-red' else record['no_generation_fence']
            assert 'sha256=' + variant['sha256'] in log and 'loaded=' + SLOT + '/' in log
    native_log = unpack(record['runs']['native-red']['log']).decode()
    assert "Failed test 'literal declaration and assignment emission ledger exists'" in native_log
    bad = unpack(record['runs']['no-generation-fence']['log']).decode()
    assert "Failed test 'final raw generation fence catches an earlier root changed after its last proof'" in bad
    assert bad.count("Failed test 'failure returns no HDL'") == 4
    assert bad.count("Failed test 'failure invalidates complete capture'") == 4
    assert "Failed test 'actual fixed and mutable" not in bad
    for item in record['historical'].values():
        unpack(item)
    assert b'session inspection is unavailable' in unpack(record['historical']['red.log'])
    assert b'Result: FAIL' in unpack(record['historical']['final-focused.log'])
    assert b'All tests successful.' in unpack(record['historical']['one-bit-repaired.log'])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture', action='store_true', help='run only the bounded checks under the repository RAM guard')
    parser.add_argument('--current', action='store_true', help='compare named current source identities only')
    parser.add_argument('--qualify', action='store_true', help='reject altered saved statuses and erased failures')
    args = parser.parse_args()
    record = capture() if args.capture else json.loads(gzip.decompress((HERE / 'receipt.json.gz').read_bytes()))
    verify(record, args.current)
    if args.qualify:
        for mutation in ('status', 'boolean', 'erased'):
            bad = copy.deepcopy(record)
            run = bad['runs']['no-generation-fence']
            if mutation == 'status':
                run['status'] = 0
            elif mutation == 'boolean':
                bad['runs']['focused']['status'] = False
            else:
                run['log'] = pack(unpack(run['log']).replace(b"Failed test 'failure returns", b"Erased test 'failure returns"))
            try:
                verify(bad)
            except AssertionError:
                continue
            raise AssertionError('hostile saved evidence accepted: ' + mutation)
        print('altered-status, Boolean-status and rehashed erased-failure records rejected')
    print('saved literal-emission source/ledger/fence evidence authenticated; no HDL execution')


if __name__ == '__main__':
    main()
