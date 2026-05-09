#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(serializable_plan_report_contract_source);

subtest 'manifest embeds serializable plan/report identity metadata' => sub {
    my $manifest = build_capability_manifest();
    my $contract = $manifest->{embedding}{serializable_plan_reports};

    is($contract->{schema_version}, 1, 'manifest embeds schema version 1');
    is($contract->{status}, 'bounded_public', 'manifest embeds bounded_public status');
    is(
        $contract->{contract_source},
        serializable_plan_report_contract_source(),
        'manifest embeds canonical contract source',
    );
    ok(
        defined($contract->{purpose}) && !ref($contract->{purpose}) && length($contract->{purpose}),
        'manifest embeds non-empty scalar purpose',
    );
    like(
        $contract->{purpose},
        qr/JSON-safe plan\/report surfaces/,
        'manifest purpose describes JSON-safe plan/report surfaces',
    );
};

done_testing();
