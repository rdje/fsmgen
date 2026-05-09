#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(
    serializable_plan_report_raw_shell_replacement_keys
);

subtest 'manifest raw shell replacement keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};

    is_deeply(
        $contract->{raw_shell_replacement_keys},
        serializable_plan_report_raw_shell_replacement_keys(),
        'decoded manifest preserves canonical raw-shell replacement key list',
    );
};

subtest 'decoded manifest replacement map matches decoded key list' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};

    is_deeply(
        as_set([keys %{$contract->{raw_shell_replacement_map}}]),
        as_set($contract->{raw_shell_replacement_keys}),
        'decoded replacement map keys match decoded raw-shell family',
    );
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
