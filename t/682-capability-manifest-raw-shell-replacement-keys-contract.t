#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(
    serializable_plan_report_raw_shell_replacement_keys
);

subtest 'manifest embeds advertised raw shell replacement keys' => sub {
    my $manifest = build_capability_manifest();

    is_deeply(
        $manifest->{embedding}{serializable_plan_reports}{raw_shell_replacement_keys},
        serializable_plan_report_raw_shell_replacement_keys(),
        'manifest embeds canonical raw-shell replacement key list',
    );
};

subtest 'manifest replacement map matches the embedded key list' => sub {
    my $manifest = build_capability_manifest();
    my $contract = $manifest->{embedding}{serializable_plan_reports};

    is_deeply(
        as_set([keys %{$contract->{raw_shell_replacement_map}}]),
        as_set($contract->{raw_shell_replacement_keys}),
        'manifest replacement map keys match embedded raw-shell family',
    );
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
