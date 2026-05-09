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
use FSM::Support::SerializableCompositionPlanSnapshot qw(build_serializable_composition_plan_snapshot);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $fixture = File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm');

subtest 'composition plan snapshot remains plain data after JSON round trip' => sub {
    my $result = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
    )->generate_hdl_from_file($fixture);
    my $snapshot = build_serializable_composition_plan_snapshot(
        composition_plan => $result->{composition_plan},
    );

    ok(length(encode_json($snapshot)), 'snapshot encodes as JSON');
    my $decoded = decode_json(encode_json($snapshot));

    ok(!contains_blessed($decoded), 'decoded snapshot contains no unexpected blessed values');
    is($decoded->{top_name}, 'apb_tb', 'round-trip snapshot keeps top name');
    is($decoded->{summary}{instance_count}, 2, 'round-trip snapshot keeps instance count');
    is($decoded->{summary}{port_count}, scalar(@{$decoded->{top_ports}}), 'round-trip snapshot keeps port collection');
    is_deeply(
        [map { $_->{instance_name} } @{$decoded->{instances}}],
        [qw(requester completer)],
        'round-trip snapshot keeps child instance names',
    );
    ok(@{$decoded->{resolved_links}} > 0, 'round-trip snapshot keeps resolved links');
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
