#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Test::RegressionCorpus qw(regression_corpus_entries protocol_fixture_entries);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my @entries = regression_corpus_entries();
my @protocol_entries = protocol_fixture_entries();

ok(@entries >= 6, 'regression corpus catalog starts with named entries across multiple classifications');
is(scalar(@protocol_entries), 4, 'first visible corpus slice contains the four named protocol fixtures');

my %allowed_classifications = map { $_ => 1 } qw(
    supported_smoke
    expected_failure
    legacy_out_of_scope
);

my %allowed_coverages = map { $_ => 1 } qw(
    direct_root_pipeline_cli
    composition_top_pipeline_cli
    legacy_root_default_pipeline_cli
    strict_root_rejection_pipeline_cli
);

my %seen_ids;
my %seen_contracts;
my %by_id = map { $_->{id} => $_ } @entries;

for my $required_id (qw(
    protocol.apb_requester
    protocol.apb_completer
    protocol.amba_requester
    protocol.apb_tb
    legacy.mipicsi2_txccore_ulp.default_compat
    legacy.mipicsi2_txccore_ulp.strict_rejection
)) {
    ok($by_id{$required_id}, "catalog keeps required entry $required_id");
}

for my $entry (@entries) {
    ok(!$seen_ids{$entry->{id}}++, "catalog entry id '$entry->{id}' is unique");
    my $contract_key = join "\0", $entry->{relpath}, $entry->{classification}, $entry->{coverage};
    ok(!$seen_contracts{$contract_key}++, "catalog contract for '$entry->{id}' is unique");
    ok($allowed_classifications{$entry->{classification}}, "catalog entry '$entry->{id}' uses a known classification");
    ok($allowed_coverages{$entry->{coverage}}, "catalog entry '$entry->{id}' uses a known coverage bucket");

    my $path = File::Spec->catfile($repo_root, split m{/}, $entry->{relpath});
    ok(-e $path, "catalog entry '$entry->{id}' points at an existing repo file");

    if ($entry->{classification} eq 'expected_failure') {
        ok($entry->{expected_error_pattern}, "expected-failure entry '$entry->{id}' records a boundary pattern");
        ok($entry->{expected_hint_pattern}, "expected-failure entry '$entry->{id}' records a migration-hint pattern");
    }
    elsif ($entry->{source_kind} eq 'fsm') {
        ok($entry->{expected_module_name}, "direct-root entry '$entry->{id}' records an expected module name");
    }
    elsif ($entry->{source_kind} eq 'composition') {
        ok($entry->{expected_top_name}, "composition entry '$entry->{id}' records an expected top name");
        ok($entry->{expected_lane}, "composition entry '$entry->{id}' records an expected composition lane");
        ok($entry->{expected_instance_count} >= 1, "composition entry '$entry->{id}' records a positive child count");
        ok(ref($entry->{expected_child_modules}) eq 'ARRAY' && @{$entry->{expected_child_modules}},
            "composition entry '$entry->{id}' records expected child modules");
    }
    else {
        fail("catalog entry '$entry->{id}' uses an unsupported source kind '$entry->{source_kind}'");
    }
}

is(
    scalar(grep { $_->{classification} eq 'supported_smoke' } @entries),
    4,
    'catalog keeps the four named supported-smoke protocol entries',
);
is(
    scalar(grep { $_->{classification} eq 'legacy_out_of_scope' } @entries),
    1,
    'catalog now also records one explicit legacy-out-of-scope compatibility entry',
);
is(
    scalar(grep { $_->{classification} eq 'expected_failure' } @entries),
    1,
    'catalog now also records one explicit expected-failure entry',
);

done_testing();
