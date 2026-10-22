#!/usr/bin/env python3
"""Fixed source-only capture and saved-only verification for the .1.2.3 slice."""
import copy
import gzip
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
os.chdir(ROOT)
BASE = 'a51f16ec439d96ec067ce31d56e2eb9568ecb6b1'
PARSER = 'perl/FSM/Adapter/ISF/Parser.pm'
ADAPTER = 'perl/FSM/Adapter/ISF/LispishAdapter.pm'
TEST = 't/2098-isf-authored-library-override-sources.t'
RECIPE = 'docs/audits/library-source-retention-20261022.py'
PREFIX = 'docs/audits/library-source-retention-'
WORK = Path('.artifacts/library-source-retention-qualified-20261022')
CASES = {
    'parameter': (['W'], ['LIMIT'], ['16']),
    'alias': (['W'], ['ALIAS'], ['16']),
    'equal_default': (['W'], ['OTHER'], ['16']),
    'constant': (['W'], ['FIXED'], ['16']),
    'package': (['W'], ['shared.LIMIT'], [16]),
    'enum': (['W'], ['mode.BUSY'], [1]),
    'package_enum': (['W'], ['shared.mode.BUSY'], [1]),
    'literal': (['W'], ['16'], ['16']),
    'exact_width': (['W'], ["5'd16"], ["5'd16"]),
    'list': (['PAIR'], [['mode.BUSY', 'shared.mode.IDLE']], [[1, 0]]),
    'nested': (['TREE'], [[['LIMIT', 'ALIAS'], ['shared.LIMIT', '16']]], [[['16', '16'], [16, '16']]]),
    'multiple': (['W', 'TREE', 'PAIR'], ['ALIAS', [['LIMIT', 'ALIAS'], ['shared.LIMIT', '16']], ['1', '0']],
                 ['16', [['16', '16'], [16, '16']], ['1', '0']]),
    'defaults': ([], [], []),
}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def require(ok, message):
    if not ok:
        raise ValueError(message)


def canonical(value):
    # JSON distinguishes strings, numbers and Booleans where Python equality does not.
    return json.dumps(value, sort_keys=True, separators=(',', ':'))


def pack(path, value):
    with Path(path).open('xb') as stream:
        with gzip.GzipFile(fileobj=stream, mode='wb', mtime=0) as compressed:
            compressed.write((json.dumps(value, sort_keys=True, indent=2) + '\n').encode())


def read(epoch):
    return json.loads(gzip.decompress(Path(PREFIX + epoch + '-20261022.json.gz').read_bytes()))


def qualification_pair():
    """Join a missing product; never relabel the interrupted stored epoch green."""
    before, interrupted = read('before'), read('after')
    diagnostic_path = Path('docs/audits/library-source-interruption-20261022.json.gz')
    diagnostic = json.loads(gzip.decompress(diagnostic_path.read_bytes()))
    control = json.loads(gzip.decompress(Path('docs/audits/library-source-timeout-control-20261022.json.gz').read_bytes()))
    require(control.get('qualified') is True and 'error' not in control, 'timeout glue control unqualified')
    require(diagnostic.get('error') == 'timeout stream/reaping control failed', 'unexpected diagnostic programme outcome')
    require('defaults.isf' in interrupted.get('error', '') and 'timed out after 60 seconds' in interrupted['error'], 'unknown interrupted capture')
    require(set(interrupted['cases']['defaults']['queries']) == {'check', 'semantic'}, 'unexpected interrupted membership')
    require(all(set(row['queries']) == {'check', 'semantic', 'schedule'} for name, row in interrupted['cases'].items() if name != 'defaults'), 'another native product is missing')
    native = diagnostic['results']['native_diagnostic']
    source_path = str(WORK / 'defaults.isf')
    require(native['argv'] == ['perl', 'bin/fsmgen', '--quiet', '--strict', '--trace-verbosity=debug',
            '--trace-log=.artifacts/library-source-defaults-diagnostic-20261022.trace', '--emit-schedule-json', source_path], 'diagnostic invocation identity')
    require(native['exit'] == 0 and native['reaped_returncode'] == 0 and native['bound_seconds'] == 60, 'diagnostic native stage did not pass')
    require(diagnostic['inputs'][source_path]['sha256'] == interrupted['cases']['defaults']['source_sha256'], 'diagnostic source differs')
    require(diagnostic['inputs'][PARSER]['sha256'] == interrupted['inputs'][PARSER]['sha256'], 'diagnostic parser differs')
    after = copy.deepcopy(interrupted)
    # This is a derived comparison view, not a rewritten receipt. Its attached
    # boundary retains the failed programme and the separately observed product.
    after['_qualification_join'] = {'interrupted_error': after.pop('error'),
        'interrupted_sha256': sha(Path(PREFIX + 'after-20261022.json.gz').read_bytes()),
        'diagnostic_sha256': sha(diagnostic_path.read_bytes()),
        'historical_cause': 'unattributed; prepublication owner ISF-REDUCTION-DELIVERY.16'}
    after['cases']['defaults']['queries']['schedule'] = copy.deepcopy(native)
    return before, after


def run(argv, env=None):
    try:
        result = subprocess.run(argv, capture_output=True, timeout=60, env=env)
        status, stdout, stderr = result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired as error:
        status, stdout, stderr = 'timeout', error.stdout or b'', error.stderr or b''
    return {'argv': argv, 'exit': status, **{
        name: {'text': data.decode().replace(str(ROOT), '<repo>'), 'raw_sha256': sha(data), 'raw_bytes': len(data)}
        for name, data in (('stdout', stdout), ('stderr', stderr))}}


def capture(epoch):
    require(epoch in ('before', 'after'), 'unknown epoch')
    if epoch == 'before':
        require(Path(PARSER).read_bytes() == subprocess.check_output(['git', 'show', BASE + ':' + PARSER]), 'baseline parser drift')
    directory = WORK / epoch
    directory.mkdir(parents=True, exist_ok=False)
    record = {'schema_version': 1, 'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.1.2.3',
              'epoch': epoch, 'baseline_revision': BASE, 'cases': {},
              'inputs': {path: {'sha256': sha(Path(path).read_bytes()), 'text': Path(path).read_text()}
                         for path in (PARSER, ADAPTER, TEST, RECIPE)},
              'source_diff': subprocess.check_output(['git', 'diff', BASE, '--', PARSER]).decode(),
              'limits': 'Fixed repaired-normalizer source-only baseline. No HDL execution. Test workspace and exact checkout prefixes normalize in saved projections; original stream hashes/lengths retain but raw-root reconstruction and full transitive process/environment footprints are absent. Public API/newline preservation uses the separately recorded existing qualification cohort.'}
    try:
        env = dict(os.environ, FSMGEN_LIBRARY_SOURCE_CAPTURE=str(directory))
        record['regression'] = run(['prove', '-Iperl', TEST], env)
        expected_exit = 1 if epoch == 'before' else 0
        require(record['regression']['exit'] == expected_exit, 'unexpected regression exit')
        require({p.stem for p in directory.glob('*.json')} == set(CASES), 'capture membership')
        WORK.mkdir(exist_ok=True)
        (WORK / 'shared.fsm').write_text('(?pkg:shared (+constants (LIMIT 16)) (+enums (mode (IDLE 0) (BUSY 1))))')
        for name in CASES:
            product = json.loads((directory / (name + '.json')).read_bytes())
            source = product['source']
            path = WORK / (name + '.isf')
            path.write_text(source)
            row = {'private': product, 'source_sha256': sha(source.encode()), 'queries': {}}
            record['cases'][name] = row
            for kind, flags in (('check', ['--check', '--json']), ('semantic', ['--emit-semantic-json']), ('schedule', ['--emit-schedule-json'])):
                query = run(['perl', 'bin/fsmgen', '--quiet', '--strict', *flags, str(path)])
                row['queries'][kind] = query
                require(query['exit'] == 0, name + ': native ' + kind + ' refused')
    except BaseException as error:
        record['error'] = str(error).replace(str(ROOT), '<repo>')
        raise
    finally:
        pack(PREFIX + epoch + '-20261022.json.gz', record)
    print('library source capture:', epoch, 'complete')


def validate(before, after):
    for epoch, label in ((before, 'before'), (after, 'after')):
        require('error' not in epoch and epoch['epoch'] == label and epoch['baseline_revision'] == BASE, 'epoch boundary')
        require(set(epoch['cases']) == set(CASES), 'case membership')
        require(set(epoch['inputs']) == {PARSER, ADAPTER, TEST, RECIPE}, 'input membership')
        for path, data in epoch['inputs'].items():
            require(sha(data['text'].encode()) == data['sha256'], 'stored input digest: ' + path)
        for name, row in epoch['cases'].items():
            product = row['private']
            require(product['caller_unchanged'] is True, 'caller changed')
            require(product['loaded'] == {'path': PARSER, 'sha256': epoch['inputs'][PARSER]['sha256'], 'methods': {
                method: PARSER for method in ('_validate_use_params', '_resolve_library_uses', '_resolve_library_use_param_value')}}, 'loaded parser/method identity')
            require(sha(product['source'].encode()) == row['source_sha256'], 'source identity')
            require(set(row['queries']) == {'check', 'semantic', 'schedule'}, 'native membership')
            for kind, query in row['queries'].items():
                require(query['exit'] == 0, 'native refusal')
                output = json.loads(query['stdout']['text'])
                require(kind == 'schedule' or output['success'] is True, 'native failure')
            names, authored, resolved = CASES[name]
            for key in ('uses', 'library_uses'):
                use, sibling = product['actor'][key]
                require(canonical(use['parameter_overrides']) == canonical([
                    {'name': n, 'value': v} for n, v in zip(names, resolved)]), 'resolved original kinds/membership')
                expected = [{'name': n, 'value': v, 'owner': 'library_sources'} for n, v in zip(names, authored)]
                if label == 'after' and expected:
                    require(canonical(use.get('_parameter_override_sources')) == canonical(expected), 'authored name/tree/kind/owner')
                else:
                    require('_parameter_override_sources' not in use, 'invented source')
                require('_parameter_override_sources' not in sibling, 'invented default sibling source')
    require(before['inputs'][PARSER]['sha256'] == sha(subprocess.check_output(['git', 'show', BASE + ':' + PARSER])), 'baseline Git identity')
    require(before['inputs'][ADAPTER]['sha256'] == sha(subprocess.check_output(['git', 'show', BASE + ':' + ADAPTER])), 'repaired adapter baseline')
    for path in (ADAPTER, TEST, RECIPE):
        require(before['inputs'][path] == after['inputs'][path], 'fixed comparison input changed: ' + path)
    red, green = before['regression'], after['regression']
    require(red['exit'] == 1 and 'Result: FAIL' in red['stdout']['text'] and 'authored tree retains order' in red['stderr']['text'], 'genuine semantic RED')
    require(green['exit'] == 0 and 'All tests successful.' in green['stdout']['text'], 'GREEN')
    for name in CASES:
        old, new = before['cases'][name], after['cases'][name]
        require(old['source_sha256'] == new['source_sha256'], 'changed source')
        for kind in ('check', 'semantic', 'schedule'):
            a_query, b_query = old['queries'][kind], new['queries'][kind]
            require(all(a_query[key] == b_query[key] for key in ('exit', 'stdout', 'stderr')), 'complete native product conservation')
            if name != 'defaults' or kind != 'schedule':
                require(a_query['argv'] == b_query['argv'], 'native invocation changed')
        a, b = copy.deepcopy(old['private']), copy.deepcopy(new['private'])
        del a['loaded'], b['loaded']
        for key in ('uses', 'library_uses'):
            for use in b['actor'][key]:
                use.pop('_parameter_override_sources', None)
        require(canonical(a) == canonical(b), 'complete per-source actor/lower/report conservation')


def verify():
    before, after = qualification_pair()
    validate(before, after)
    for mutation in ('name', 'value', 'owner', 'kind', 'resolved-kind', 'default', 'loaded', 'case', 'caller', 'carrier'):
        bad = copy.deepcopy(after)
        product = bad['cases']['nested']['private']
        entry = product['actor']['library_uses'][0]['_parameter_override_sources'][0]
        if mutation in ('name', 'value', 'owner'):
            entry[mutation] = 'wrong'
        elif mutation == 'kind':
            entry['value'][1][1] = 16
        elif mutation == 'resolved-kind':
            product['actor']['uses'][0]['parameter_overrides'][0]['value'][1][0] = '16'
        elif mutation == 'default':
            product['actor']['uses'][1]['_parameter_override_sources'] = []
        elif mutation == 'loaded':
            product['loaded']['methods'].pop('_validate_use_params')
        elif mutation == 'case':
            del bad['cases']['package_enum']
        elif mutation == 'caller':
            product['caller_unchanged'] = 1
        else:
            product['lower']['files']['wrong.fsm'] = 'wrong'
        try:
            validate(before, bad)
        except (ValueError, KeyError, TypeError):
            continue
        raise ValueError('hostile control accepted: ' + mutation)
    print('library source retained verification: PASS; hostile controls rejected')


if __name__ == '__main__':
    if sys.argv[1:] == ['verify']:
        verify()
    elif len(sys.argv) == 3 and sys.argv[1] == 'capture':
        capture(sys.argv[2])
    else:
        raise SystemExit('usage: library-source-retention-20261022.py capture before|after OR verify')
