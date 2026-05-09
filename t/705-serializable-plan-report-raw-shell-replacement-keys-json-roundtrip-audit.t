#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_raw_shell_replacement_keys
);

subtest 'serializable plan/report raw shell replacement keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_serializable_plan_report_contract()));

    is_deeply(
        $decoded->{raw_shell_replacement_keys},
        serializable_plan_report_raw_shell_replacement_keys(),
        'decoded contract preserves canonical raw-shell replacement key list',
    );
};

subtest 'decoded replacement map matches decoded key list' => sub {
    my $decoded = decode_json(encode_json(build_serializable_plan_report_contract()));

    is_deeply(
        as_set([keys %{$decoded->{raw_shell_replacement_map}}]),
        as_set($decoded->{raw_shell_replacement_keys}),
        'decoded replacement map keys match decoded raw-shell family',
    );
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
