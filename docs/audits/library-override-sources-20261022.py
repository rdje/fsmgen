#!/usr/bin/env python3
"""Capture fixed library source peers or verify retained products without replay."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path.cwd().resolve()
BASE = 'b84eb7d9246bb300dcbe925c0463b074df0d2434'
PARSER = 'perl/FSM/Adapter/ISF/Parser.pm'
TEST = 't/2097-isf-authored-library-overrides.t'
ORIGINAL = 'docs/audits/width-physical-sources-first-20261022.json.gz'
PREFIX = 'docs/audits/library-override-sources-'
PROBE = r'''
use strict; use warnings; use JSON::PP; use Digest::SHA qw(sha256_hex); use B;
use FSM::Adapter::ISF; use FSM::Scheduler::ISF;
my $json = JSON::PP->new->canonical;
my $path = $INC{'FSM/Adapter/ISF/Parser.pm'};
open my $p, '<:raw', $path or die $!;
my $bytes = do {local $/; <$p>}; close $p or die $!;
my %methods = map {$_ => B::svref_2object(FSM::Adapter::ISF::Parser->can($_))->GV->FILE}
    qw(_validate_use_params _resolve_library_uses _resolve_library_use_param_value);
open my $fh, '<:raw', $ARGV[0] or die $!;
my $text = do {local $/; <$fh>}; close $fh or die $!;
my $actor = FSM::Adapter::ISF->new->parse_source($text, 'width-source-peer.isf');
my $before = $json->encode($actor);
my $scheduler = FSM::Scheduler::ISF->new;
my $lower = $scheduler->lower($actor);
my $report = $json->decode($scheduler->report($actor));
print $json->encode({actor => $json->decode($before), lower => $lower, report => $report,
    caller_unchanged => $json->encode($actor) eq $before ? JSON::PP::true : JSON::PP::false,
    loaded => {path => $path, sha256 => sha256_hex($bytes), methods => \%methods}}), "\n";
'''


def sha(data):
    return hashlib.sha256(data).hexdigest()


def require(ok, message):
    if not ok:
        raise ValueError(message)


def unpack(path):
    return json.loads(gzip.decompress(Path(path).read_bytes()))


def pack(path, record):
    with Path(path).open('xb') as stream:
        with gzip.GzipFile(fileobj=stream, mode='wb', mtime=0) as packed:
            packed.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())


def run(argv):
    try:
        result = subprocess.run(argv, capture_output=True, timeout=60)
        status, streams = result.returncode, (result.stdout, result.stderr)
    except subprocess.TimeoutExpired as error:
        status, streams = 'timeout', (error.stdout or b'', error.stderr or b'')
    return {'argv': argv, 'exit': status, **{
        key: {'text': raw.decode().replace(str(ROOT), '<repo>'), 'raw_sha256': sha(raw), 'raw_bytes': len(raw)}
        for key, raw in zip(('stdout', 'stderr'), streams)}}


def capture(epoch):
    require(epoch in ('before', 'after'), 'unknown epoch')
    original = unpack(ORIGINAL)
    work = Path('.artifacts/library-override-sources-native-20261022')
    work.mkdir(exist_ok=True)
    record = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.1.2', 'schema_version': 1,
              'baseline_revision': BASE, 'epoch': epoch, 'probe': PROBE,
              'original_sha256': sha(Path(ORIGINAL).read_bytes()), 'cases': {},
              'inputs': {p: {'sha256': sha(Path(p).read_bytes()), 'text': Path(p).read_text()}
                         for p in (PARSER, TEST, __file__)},
              'source_diff': subprocess.check_output(['git', 'diff', BASE, '--', PARSER]).decode(),
              'limits': 'Fixed source-only peers; no HDL tools. Only exact checkout prefixes normalize to <repo>; original byte hashes/lengths retained, raw-root bytes and complete transitive process/environment footprints are not reconstructed.'}
    try:
        for name in ('library_named.isf', 'library_literal.isf'):
            source = original['cases'][name]['source']
            path = work / name
            path.write_text(source)
            row = {'source': source, 'source_sha256': sha(source.encode()), 'queries': {}}
            record['cases'][name] = row
            row['private'] = run(['perl', '-Iperl', '-e', PROBE, str(path)])
            require(row['private']['exit'] == 0, 'private query refused')
            for kind, flags in (('check', ['--check', '--json']), ('semantic', ['--emit-semantic-json']),
                                ('schedule', ['--emit-schedule-json'])):
                row['queries'][kind] = run(['perl', 'bin/fsmgen', '--quiet', '--strict', *flags, str(path)])
                require(row['queries'][kind]['exit'] == 0, 'native query refused: ' + kind)
        log = Path('.artifacts/library-override-sources-' + ('red' if epoch == 'before' else 'green') + '-20261022.log')
        record['regression'] = {'text': log.read_text().replace(str(ROOT), '<repo>'), 'sha256': sha(log.read_bytes())}
    except Exception as error:
        record['error'] = str(error).replace(str(ROOT), '<repo>')
        raise
    finally:
        pack(PREFIX + epoch + '-20261022.json.gz', record)
    print('captured', epoch)


def validate(before, after):
    original = unpack(ORIGINAL)
    require(before['inputs'][PARSER]['sha256'] == sha(subprocess.check_output(['git', 'show', BASE + ':' + PARSER])),
            'baseline parser differs from Git')
    require(before['inputs'][TEST] == after['inputs'][TEST], 'regression changed between RED and GREEN')
    for epoch in (before, after):
        require('error' not in epoch and set(epoch['cases']) == {'library_named.isf', 'library_literal.isf'}, 'capture incomplete')
        require(epoch['original_sha256'] == sha(Path(ORIGINAL).read_bytes()), 'original receipt changed')
        for data in epoch['inputs'].values():
            require(sha(data['text'].encode()) == data['sha256'], 'stored input digest')
    for name, token in (('library_named.isf', 'LIMIT'), ('library_literal.isf', '16')):
        old, new = before['cases'][name], after['cases'][name]
        require(old['source'] == new['source'] == original['cases'][name]['source'], 'source peer identity')
        require(old['source_sha256'] == new['source_sha256'] == sha(old['source'].encode()), 'source digest')
        a, b = [json.loads(row['private']['stdout']['text']) for row in (old, new)]
        for product, epoch, row in ((a, before, old), (b, after, new)):
            require(row['private']['exit'] == 0 and product['caller_unchanged'] is True, 'private success/caller')
            require(product.pop('loaded') == {'path': PARSER, 'sha256': epoch['inputs'][PARSER]['sha256'],
                    'methods': {m: PARSER for m in ('_validate_use_params', '_resolve_library_uses', '_resolve_library_use_param_value')}},
                    'loaded parser/method identity')
            require(set(row['queries']) == {'check', 'semantic', 'schedule'}, 'native membership')
            require(all(r['exit'] == 0 for r in row['queries'].values()), 'native query refused')
            for kind in ('check', 'semantic'):
                require(json.loads(row['queries'][kind]['stdout']['text'])['success'] is True, 'native failure')
        for key in ('uses', 'library_uses'):
            require(b['actor'][key][0].pop('_parameter_override_sources') ==
                    [{'name': 'W', 'value': token, 'owner': 'library_widths'}], 'wrong source/scope')
            require('_parameter_override_sources' not in b['actor'][key][1], 'invented default source')
        require(json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True), 'private/carrier/caller kind conservation')
        require(old['queries'] == new['queries'], 'complete native product conservation')
    require('Result: FAIL' in before['regression']['text'] and
            'multiple source entries retain authored order' in before['regression']['text'], 'original semantic RED absent')
    require('All tests successful.' in after['regression']['text'] and 'Result: PASS' in after['regression']['text'], 'GREEN absent')


def verify():
    before, after = [unpack(PREFIX + epoch + '-20261022.json.gz') for epoch in ('before', 'after')]
    validate(before, after)
    for mutation in ('value', 'owner', 'name', 'primitive', 'loaded', 'default-source'):
        bad = copy.deepcopy(after)
        row = bad['cases']['library_named.isf']['private']['stdout']
        product = json.loads(row['text'])
        if mutation in ('value', 'owner', 'name'):
            product['actor']['library_uses'][0]['_parameter_override_sources'][0][mutation] = 'wrong'
        elif mutation == 'primitive':
            product['actor']['uses'][0]['parameter_overrides'][0]['value'] = 16
        elif mutation == 'loaded':
            product['loaded']['sha256'] = '0' * 64
        else:
            product['actor']['library_uses'][1]['_parameter_override_sources'] = []
        row['text'] = json.dumps(product)
        try:
            validate(before, bad)
        except (ValueError, KeyError):
            continue
        raise ValueError('hostile control accepted: ' + mutation)
    print('library-override saved verification: PASS; hostile controls rejected')


if __name__ == '__main__':
    if sys.argv[1:] == ['verify']:
        verify()
    elif len(sys.argv) == 3 and sys.argv[1] == 'capture':
        capture(sys.argv[2])
    else:
        raise SystemExit('usage: library-override-sources-20261022.py capture before|after OR verify')
