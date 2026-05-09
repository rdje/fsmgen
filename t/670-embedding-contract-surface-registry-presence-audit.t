#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::EmbeddingContract qw(
    build_embedding_contract
    embedding_nested_presence_key_map
);
use FSM::Support::SerializablePlanReportContract qw(serializable_plan_report_public_top_level_keys);

subtest 'embedding contract advertises serializable surface_registry branch' => sub {
    my $contract = build_embedding_contract();
    my $expected = serializable_plan_report_public_top_level_keys();

    is_deeply(
        $contract->{nested_presence_key_map}{serializable_plan_reports},
        $expected,
        'embedding contract embeds serializable plan/report public key family',
    );
    ok(
        grep { $_ eq 'surface_registry' } @{$contract->{nested_presence_key_map}{serializable_plan_reports}},
        'embedding contract advertises surface_registry in the serializable plan/report child',
    );
    is_deeply(
        embedding_nested_presence_key_map()->{serializable_plan_reports},
        $expected,
        'embedding nested presence helper embeds the same key family',
    );
};

done_testing();
