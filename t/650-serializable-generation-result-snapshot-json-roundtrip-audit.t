#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::SerializableGenerationResultSnapshot qw(build_serializable_generation_result_snapshot);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $fixture = File::Spec->catfile($repo_root, 'fsm', 'apb_requester.fsm');

subtest 'generation result snapshot remains plain data after JSON round trip' => sub {
    my $result = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
    )->generate_hdl_from_file($fixture);
    my $snapshot = build_serializable_generation_result_snapshot(result => $result);

    ok(length(encode_json($snapshot)), 'snapshot encodes as JSON');
    my $decoded = decode_json(encode_json($snapshot));

    ok(!contains_blessed($decoded), 'decoded snapshot contains no unexpected blessed values');
    is($decoded->{summary}{module_name}, 'apb_requester', 'round-trip snapshot keeps module name');
    is($decoded->{summary}{source_root_kind}, 'fsm', 'round-trip snapshot keeps source root kind');
    ok($decoded->{summary}{hdl_code_length} > 0, 'round-trip snapshot keeps HDL size');
    ok(
        grep { $_ eq 'module_info' } @{$decoded->{top_level_keys}},
        'round-trip snapshot keeps top-level key list',
    );
    is($decoded->{raw_shell_presence}{raw_ast}{value_ref}, 'ARRAY', 'round-trip snapshot keeps raw shell metadata');
};

done_testing();

sub contains_blessed {
    my ($value) = @_;
    return 0 if blessed($value) && blessed($value) eq 'JSON::PP::Boolean';
    return 1 if blessed($value);
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        return 1 if grep { contains_blessed($_) } @$value;
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if grep { contains_blessed($_) } values %$value;
        return 0;
    }

    return 0;
}
