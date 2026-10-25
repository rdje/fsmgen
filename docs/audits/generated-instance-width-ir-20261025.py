#!/usr/bin/env python3
"""Capture the fixed constructor comparison, or verify its retained products."""
import argparse
import copy
import gzip
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
RECEIPT = Path('docs/audits/generated-instance-width-ir-20261025.json.gz')
SLOT = Path('.artifacts/generated-instance-width-ir-20261025-v2')
MODULES = ['perl/FSM/Scheduler/ISF/LoweringIR.pm', 'perl/FSM/Support/ISFWidthDeclarations.pm']
TEST = 't/2107-isf-reusable-width-ir.t'
INPUTS = MODULES + [TEST, 't/data/isf-reusable-width-ir/generated-instances.isf',
                   't/data/isf-reusable-width-ir/library.isf', 't/data/isf-reusable-width-ir/atl.isf',
                   'docs/audits/generated-instance-width-ir-20261025.py']


def digest(data):
    return hashlib.sha256(data).hexdigest()


def verify(record):
    for path, expected in record['inputs'].items():
        assert digest((ROOT / path).read_bytes()) == expected, f'changed input: {path}'
    for path, expected in record['predecessor_modules'].items():
        data = subprocess.check_output(['git', 'show', f"{record['revision']}:{path}"], cwd=ROOT)
        assert digest(data) == expected, f'changed predecessor: {path}'
    assert record['before']['status'] == 1 and record['after']['status'] == 0
    assert 'complete independently named spawn/do/repeat/conditional/rule selections' in record['before']['stderr']
    assert 'Result: PASS' in record['focused']['stdout'] and record['focused']['status'] == 0
    old = record['before']['products']
    new = copy.deepcopy(record['after']['products'])
    instances = new['generated']['ir']['_width_scopes'].pop('generated_instances')
    assert set(instances) == {'first', 'second', 'defaults', 'parent_worker_do_0',
                             'parent_worker_repeat_do_0', 'parent_worker_cond_do_0', 'kick_worker_trigger_0'}
    assert new == old, 'old complete actor/IR products changed beyond the new private scope'
    for epoch in ('before', 'after'):
        for module, path in record[epoch]['loaded_modules'].items():
            expected = (str(SLOT / 'predecessor' / 'perl' / module)
                        if epoch == 'before' else 'perl/' + module)
            assert path == expected, f'wrong loaded module: {epoch} {module}: {path}'
    control = record['initial_root_first']
    assert control['products']['before'] == control['products']['after']
    assert all(path.startswith('perl/') for path in control['loaded_modules'].values())
    return instances


def run(command, env):
    result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, timeout=60)
    return {'command': command, 'status': result.returncode,
            'stdout': result.stdout.decode(), 'stderr': result.stderr.decode()}


def capture():
    assert not (ROOT / RECEIPT).exists(), 'receipt is immutable; choose a new epoch'
    (ROOT / SLOT).mkdir(exist_ok=False)
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip()
    record = {'revision': revision, 'inputs': {p: digest((ROOT / p).read_bytes()) for p in INPUTS},
              'predecessor_modules': {}, 'limits': 'source-only; selected modules, not full historical dependency closure; full public/carrier qualification deferred'}
    initial = ROOT / '.artifacts/generated-instance-width-ir-20261025'
    record['initial_root_first'] = {
        'producer': (initial / 'producer.py').read_text(),
        'products': {epoch: json.loads((initial / f'{epoch}.json').read_bytes()) for epoch in ('before', 'after')},
        'loaded_modules': json.loads((initial / 'before-loaded.json').read_bytes()),
        'failure': 'comparison assertion refused: -Iperl precedes the predecessor root, loading current modules; original subprocess streams were not retained',
    }
    for path in MODULES:
        data = subprocess.check_output(['git', 'show', f'{revision}:{path}'], cwd=ROOT)
        target = ROOT / SLOT / 'predecessor' / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        record['predecessor_modules'][path] = digest(data)
    preload = ['-MFSM::Support::ISFWidthDeclarations', '-MFSM::Scheduler::ISF::LoweringIR']
    program = ('use JSON::PP; open my $f, ">", $ENV{FSMGEN_WIDTH_LOADED} or die $!; '
               'print {$f} JSON::PP->new->canonical->encode({map {$_ => $INC{$_}} '
               'qw(FSM/Support/ISFWidthDeclarations.pm FSM/Scheduler/ISF/LoweringIR.pm)}); '
               'close $f or die $!; do "./t/2107-isf-reusable-width-ir.t"; die $@ if $@;')
    for epoch in ('before', 'after'):
        env = dict(os.environ, FSMGEN_REUSABLE_WIDTH_CAPTURE=str(SLOT / f'{epoch}.json'),
                   FSMGEN_WIDTH_LOADED=str(SLOT / f'{epoch}-loaded.json'))
        command = ['perl']
        if epoch == 'before':
            command += ['-I' + str(SLOT / 'predecessor' / 'perl')]
        command += ['-Iperl']
        record[epoch] = run(command + preload + ['-e', program], env)
        record[epoch]['products'] = json.loads((ROOT / env['FSMGEN_REUSABLE_WIDTH_CAPTURE']).read_bytes())
        record[epoch]['loaded_modules'] = json.loads((ROOT / env['FSMGEN_WIDTH_LOADED']).read_bytes())
        (ROOT / SLOT / f'{epoch}-run.json').write_text(json.dumps(record[epoch], sort_keys=True))
    record['focused'] = run(['prove', '-Iperl', TEST, 't/2101-isf-generated-width-ir.t',
                             't/1215-isf-spawn-parameter-binding.t'], dict(os.environ))
    (ROOT / SLOT / 'capture.json').write_text(json.dumps(record, sort_keys=True))
    verify(record)
    (ROOT / RECEIPT).write_bytes(gzip.compress(json.dumps(record, sort_keys=True).encode(), mtime=0))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['capture', 'verify'])
    args = parser.parse_args()
    if args.mode == 'capture':
        capture()
    record = json.loads(gzip.decompress((ROOT / RECEIPT).read_bytes()))
    verify(record)
    print(record['focused']['stdout'].strip())
    print('generated-instance-width: exact selected-module RED/GREEN and complete old-product conservation verified')
