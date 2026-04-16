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

ok(@entries >= 7, 'regression corpus catalog starts with named entries across multiple classifications');
ok(@entries >= 46, 'regression corpus catalog now covers supported language-feature fixtures plus root-level, section-level, child-root, direct-generation, and composition-contract residue families');
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
    legacy_section_default_pipeline_cli
    legacy_child_root_default_pipeline_cli
    strict_root_rejection_pipeline_cli
    strict_section_rejection_pipeline_cli
    strict_child_root_rejection_pipeline_cli
    language_contract_rejection_pipeline_cli
    direct_generation_contract_rejection_pipeline_cli
    composition_contract_rejection_pipeline_cli
);

my %seen_ids;
my %seen_contracts;
my %by_id = map { $_->{id} => $_ } @entries;

for my $required_id (qw(
    protocol.apb_requester
    protocol.apb_completer
    protocol.amba_requester
    protocol.apb_tb
    feature.partial_lhs_with_size
    feature.partial_lhs_inferred_width
    feature.direct_rhs_concat_pack
    feature.direct_lhs_deconstruct_pack
    feature.direct_sreset_active_high
    feature.direct_areset_active_low
    feature.direct_canonical_init_directive
    feature.direct_size_expression_widths
    legacy.mipicsi2_txccore_ulp.default_compat
    legacy.mipicsi2_txccore_ulp.strict_rejection
    legacy.empty_size_noop.default_compat
    legacy.empty_size_noop.strict_rejection
    legacy.asreset_rstn.default_compat
    legacy.asreset_rstn.strict_rejection
    legacy.sreset_rstn.default_compat
    legacy.sreset_rstn.strict_rejection
    legacy.compact_init_directive.default_compat
    legacy.compact_init_directive.strict_rejection
    legacy.fsm_child_root.default_compat
    legacy.fsm_child_root.strict_rejection
    legacy.dt_child_root.default_compat
    legacy.dt_child_root.strict_rejection
    contract.language_contract_bad_size_entry
    contract.direct_size_expression_non_positive
    contract.direct_size_expression_unknown_symbol
    contract.direct_size_expression_aggregate_symbol
    contract.direct_size_expression_divide_by_zero
    contract.direct_lhs_deconstruct_width_mismatch
    contract.direct_rhs_concat_width_mismatch
    contract.direct_aggregate_contract_mismatch
    contract.missing_rtl_metadata_sidecar
    contract.missing_fsm_child_source
    contract.missing_dt_child_source
    contract.invalid_rtl_system_port_direction
    contract.duplicate_rtlif_port_declaration
    contract.invalid_rtlif_port_type
    contract.invalid_rtlif_port_token
    contract.invalid_rtlif_port_width
    contract.missing_rtlif_root
    contract.empty_rtlif_port_declaration
    contract.nested_rtlif_port_declaration
    contract.duplicate_embedded_rtlif_root
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
    if (ref($entry->{search_path_relpaths}) eq 'ARRAY') {
        for my $relpath (@{$entry->{search_path_relpaths}}) {
            my $search_path = File::Spec->catfile($repo_root, split m{/}, $relpath);
            ok(-d $search_path, "catalog entry '$entry->{id}' points at an existing search path '$relpath'");
        }
    }

    if ($entry->{classification} eq 'expected_failure') {
        ok($entry->{expected_error_pattern}, "expected-failure entry '$entry->{id}' records a boundary pattern");
        if ($entry->{expected_hint_pattern}) {
            ok($entry->{expected_hint_pattern}, "expected-failure entry '$entry->{id}' records a migration-hint pattern");
        }
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
    12,
    'catalog now keeps twelve named supported-smoke entries including the first language-feature fixtures',
);
is(
    scalar(grep { $_->{classification} eq 'legacy_out_of_scope' } @entries),
    7,
    'catalog now records seven explicit legacy-out-of-scope compatibility entries',
);
is(
    scalar(grep { $_->{classification} eq 'expected_failure' } @entries),
    27,
    'catalog now records twenty-seven explicit expected-failure entries',
);

done_testing();
