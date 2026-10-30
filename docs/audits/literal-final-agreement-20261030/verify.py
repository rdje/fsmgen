#!/usr/bin/env python3
"""Capture/read bounded final literal agreement checks; no HDL execution."""
import argparse
import base64
import copy
import gzip
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
DIRECT = 'perl/FSM/DirectDeclaredWidthSupport.pm'
TEST = 't/2269-literal-final-declaration-agreement.t'


def pack(raw):
    return dict(data_base64=base64.b64encode(raw).decode(), bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def unpack(item):
    raw = base64.b64decode(item['data_base64'], validate=True)
    assert type(item['bytes']) is int and len(raw) == item['bytes']
    assert hashlib.sha256(raw).hexdigest() == item['sha256']
    return raw


def without_fence(raw):
    start = raw.index(b'    # No source getters follow this whole-set barrier:')
    end = raw.index(b'    return $json->decode', start)
    return raw[:start] + b'    # counterfactual: omit final literal source barrier\n' + raw[end:]


def capture(attempt):
    receipt = HERE / 'receipt.json.gz'
    assert not receipt.exists()
    slot = '.artifacts/literal-final-20261030/qualification-' + str(attempt)
    (ROOT / slot).mkdir(parents=True, exist_ok=False)
    paths = [DIRECT, TEST, 't/2173-direct-width-target-plans.t', 't/2268-target-source-literal-emission.t',
             't/2267-target-source-literal-declarations.t',
             'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/SourceLiteralWidthSupport.pm',
             'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm',
             str(Path(__file__).relative_to(ROOT))]
    sources = {p: pack((ROOT / p).read_bytes()) for p in paths}
    native = subprocess.check_output(['git', 'show', 'ce02b1cb8:' + DIRECT], cwd=ROOT)
    variant = without_fence(unpack(sources[DIRECT]))
    for name, raw in [('native', native), ('no-raw-barrier', variant)]:
        p = ROOT / slot / name / 'FSM/DirectDeclaredWidthSupport.pm'
        p.parent.mkdir(parents=True)
        p.write_bytes(raw)
    script = ('my $p=$INC{"FSM/DirectDeclaredWidthSupport.pm"}; open my $fh,"<",$p or die $!;'
              'binmode $fh; print "loaded=$p sha256=",Digest::SHA->new(256)->addfile($fh)'
              '->hexdigest,"\\n"; do "./' + TEST + '"; die $@ if $@;')
    commands = {'current': ['prove', '-Iperl', TEST, 't/2173-direct-width-target-plans.t']}
    for name in ('native', 'no-raw-barrier'):
        commands[name] = ['perl', '-I' + slot + '/' + name, '-Iperl',
                          '-MFSM::DirectDeclaredWidthSupport', '-MDigest::SHA', '-e', script]
    runs = {}
    for name in ('native', 'current', 'no-raw-barrier'):
        result = subprocess.run(commands[name], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        raw = result.stdout.replace(str(ROOT).encode(), b'<repo>')
        (ROOT / slot / (name + '.log')).write_bytes(raw)
        runs[name] = dict(command=commands[name], status=result.returncode, log=pack(raw))
        print(name, 'status', result.returncode, flush=True)
    history = {p: pack((ROOT / '.artifacts/literal-final-20261030' / p).read_bytes())
               for p in ('red.log', 'first.log', 'focused.log', 'retry.log', 'target-corrected.log')}
    record = dict(kind='literal_final_agreement_20261030', sources=sources, native=pack(native),
                  no_raw_barrier=pack(variant), runs=runs, history=history,
                  prior_attempt=pack((HERE / 'first-attempt.json.gz').read_bytes()),
                  baseline=subprocess.check_output(['git', 'rev-parse', 'ce02b1cb8'], cwd=ROOT).decode().strip(),
                  environment=dict(perl=subprocess.check_output(['perl', '-V:version'], cwd=ROOT).decode()),
                  gaps=['Named sources are not a complete historical environment or dependency capsule.',
                        'Earlier diagnostics lack exact per-run source snapshots; the focused host-memory stop is not a test pass.',
                        'No external compiler/override/runtime, full feature, corpus/API/MCP or publication qualification.',
                        'Saved current identity checking is not an unconditional behavior watcher.'])
    for p, item in sources.items():
        assert (ROOT / p).read_bytes() == unpack(item), 'source changed during capture: ' + p
    receipt.write_bytes(gzip.compress(json.dumps(record, sort_keys=True).encode(), mtime=0))
    return record


def verify(record, current=False):
    assert record['kind'] == 'literal_final_agreement_20261030' and record['gaps']
    for path, item in record['sources'].items():
        assert not Path(path).is_absolute() and '..' not in Path(path).parts
        raw = unpack(item)
        if current:
            assert (ROOT / path).read_bytes() == raw
    assert unpack(record['no_raw_barrier']) == without_fence(unpack(record['sources'][DIRECT]))
    assert b'my @literal_sources;' not in unpack(record['native'])
    for name, status in {'native': None, 'current': 0, 'no-raw-barrier': 1}.items():
        run = record['runs'][name]
        assert type(run['status']) is int
        assert (run['status'] > 0 if status is None else run['status'] == status)
        log = unpack(run['log']).decode()
        if name == 'current':
            assert 'All tests successful.' in log and 'Files=2, Tests=9' in log
        else:
            item = record['native'] if name == 'native' else record['no_raw_barrier']
            assert 'sha256=' + item['sha256'] in log and 'loaded=.artifacts/literal-final-' in log
    bad = unpack(record['runs']['no-raw-barrier']['log']).decode()
    assert "Failed test 'late mutation returns no final agreement'" in bad
    assert "Failed test 'whole-set raw barrier catches the late earlier-source write'" in bad
    assert "Failed test 'actual unknown Core widths" not in bad
    native = unpack(record['runs']['native']['log']).decode()
    assert "Failed test 'actual final generation succeeds'" in native
    assert "Failed test 'invalid actual width/profile cannot borrow literal authority'" in native
    assert '1..3\n# Looks like you failed' in native
    history = {p: unpack(v).decode() for p, v in record['history'].items()}
    assert 'host memory 89.2% reached cutoff 88%' in history['focused.log']
    assert "Failed test 'mutated source still returns no qualified HDL'" in history['retry.log']
    assert 'All tests successful.' in history['target-corrected.log']
    prior = json.loads(gzip.decompress(unpack(record['prior_attempt'])))
    assert {p:r['status'] for p,r in prior['runs'].items()} == {'native':2,'current':0,'no-raw-barrier':1}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capture', action='store_true')
    parser.add_argument('--attempt', type=int, default=1)
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--qualify', action='store_true')
    args = parser.parse_args()
    assert 1 <= args.attempt <= 16
    record = capture(args.attempt) if args.capture else json.loads(gzip.decompress((HERE / 'receipt.json.gz').read_bytes()))
    verify(record, args.current)
    if args.qualify:
        for mutation in ('status', 'boolean', 'erased'):
            bad = copy.deepcopy(record)
            if mutation == 'status':
                bad['runs']['no-raw-barrier']['status'] = 0
            elif mutation == 'boolean':
                bad['runs']['current']['status'] = False
            else:
                run = bad['runs']['no-raw-barrier']
                run['log'] = pack(unpack(run['log']).replace(b"Failed test 'late mutation", b"Erased test 'late mutation"))
            try:
                verify(bad)
            except AssertionError:
                continue
            raise AssertionError('hostile saved evidence accepted: ' + mutation)
        print('altered-status, Boolean-status and rehashed erased-failure controls rejected')
    print('saved final literal agreement/source/barrier evidence authenticated; no HDL execution')


if __name__ == '__main__':
    main()
