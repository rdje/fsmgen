#!/usr/bin/env python3
"""Capture first-touch public-parser/owned-normalizer diagnosis, without HDL."""
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path.cwd().resolve()
TEST = 't/2097-isf-authored-library-overrides.t'
PARSER = 'perl/FSM/Adapter/ISF/Parser.pm'
ADAPTER = 'perl/FSM/Adapter/ISF/LispishAdapter.pm'
OUTPUT = 'docs/audits/library-override-diagnosis-20261022.json.gz'
probe = r'''
use strict; use warnings; use JSON::PP; use Lispish;
use FSM::Adapter::ISF; use FSM::Adapter::ISF::LispishAdapter;
my $json = JSON::PP->new->canonical;
open my $fh, '<:raw', $ARGV[0] or die $!;
my $source = do {local $/; <$fh>}; close $fh or die $!;
my $actor = FSM::Adapter::ISF->new->parse_source($source, $ARGV[0]);
my $before = $json->encode($actor);
my $minimal = "(params (TREE ((1 2) (3 4))))\n";
my $raw = Lispish::multi(\$minimal);
my $adapter = FSM::Adapter::ISF::LispishAdapter->new;
my $normalized = $adapter->normalize_multi($raw);
my ($patched, $patched_actor);
my $original = FSM::Adapter::ISF::LispishAdapter->can('normalize_form');
{
    no warnings 'redefine';
    local *FSM::Adapter::ISF::LispishAdapter::normalize_form = sub {
        my ($self, $form, @rest) = @_;
        my @copy = @$form;
        $copy[0] = $self->normalize_form($copy[0], @rest) if ref($copy[0]) eq 'ARRAY';
        return $original->($self, \@copy, @rest);
    };
    $patched = $adapter->normalize_multi($raw);
    $patched_actor = FSM::Adapter::ISF->new->parse_source($source, $ARGV[0]);
}
print $json->encode({minimal_source => $minimal, raw => $raw, normalized => $normalized,
    head_recursion_counterfactual => $patched, actor => $json->decode($before),
    counterfactual_actor => $patched_actor,
    caller_unchanged => $json->encode($actor) eq $before ? JSON::PP::true : JSON::PP::false}), "\n";
'''


def sha(data):
    return hashlib.sha256(data).hexdigest()


def require(ok, message):
    if not ok:
        raise ValueError(message)


template = re.search(r'return <<"ISF";\n(.*?)\nISF', Path(TEST).read_text(), re.S).group(1) + '\n'
work = Path('.artifacts/library-override-diagnosis-20261022')
work.mkdir(exist_ok=True)
(work / 'shared.fsm').write_text('(?pkg:shared (+constants (LIMIT 16)) (+enums (mode (IDLE 0) (BUSY 1))))\n')
record = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.1.2.1', 'schema_version': 1,
          'probe': probe, 'baseline_revision': subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(),
          'inputs': {p: {'sha256': sha(Path(p).read_bytes()), 'text': Path(p).read_text()} for p in (PARSER, ADAPTER, TEST, __file__)},
          'cases': {}, 'limits': 'Source-only first-touch observation and local scoped method counterfactual; no dependency implementation inspection or production patch. No HDL/runtime qualification. Only exact checkout roots normalize; raw stream hashes retained.'}
try:
    for name, clause in (('parameter', '(W LIMIT)'), ('literal', '(W 16)'),
                         ('package', '(W shared.LIMIT)'), ('enum', '(W mode.BUSY)'),
                         ('enum_literal', '(W 1)'), ('nested', '(TREE ((LIMIT ALIAS) (shared.LIMIT 16)))')):
        source = template.replace('$overrides', clause)
        path = work / (name + '.isf')
        path.write_text(source)
        result = subprocess.run(['perl', '-Iperl', '-e', probe, str(path)], capture_output=True, timeout=60)
        row = {'source': source, 'exit': result.returncode, **{
            key: {'raw_sha256': sha(raw), 'text': raw.decode().replace(str(ROOT), '<repo>')}
            for key, raw in (('stdout', result.stdout), ('stderr', result.stderr))}}
        record['cases'][name] = row
        require(result.returncode == 0, 'public probe refused: ' + name)
        data = json.loads(row['stdout']['text'])
        require(data['caller_unchanged'] is True, 'probe mutated original actor')
        require(data['normalized'] == [['params', ['TREE', [['1', ['2']], ['3', '4']]]]], 'unexpected original normalization')
        require(data['head_recursion_counterfactual'] == [['params', ['TREE', [['1', '2'], ['3', '4']]]]], 'literal counterfactual oracle')
        if name == 'nested':
            original = data['actor']['uses'][0]['_parameter_override_sources'][0]['value']
            corrected = data['counterfactual_actor']['uses'][0]['_parameter_override_sources'][0]['value']
            require(original == [['LIMIT', ['ALIAS']], ['shared.LIMIT', '16']], 'original nested source shape')
            require(corrected == [['LIMIT', 'ALIAS'], ['shared.LIMIT', '16']], 'actor counterfactual source shape')
        print(name, json.dumps(data['actor']['uses'][0]['parameter_overrides']), flush=True)
    record['result'] = 'diagnosis qualified; production fix and private retention unqualified'
finally:
    with Path(OUTPUT).open('xb') as stream:
        with gzip.GzipFile(fileobj=stream, mode='wb', mtime=0) as packed:
            packed.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
