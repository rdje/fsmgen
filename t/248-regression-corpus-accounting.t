#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::DiagnosticCodes qw(
    diagnostic_code_ids
    diagnostic_code_metadata
    known_diagnostic_code
);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries protocol_fixture_entries);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my @entries = regression_corpus_entries();
my @protocol_entries = protocol_fixture_entries();

ok(@entries >= 7, 'regression corpus catalog starts with named entries across multiple classifications');
ok(@entries >= 50, 'regression corpus catalog now covers supported language-feature fixtures plus root-level, section-level, child-root, direct-generation, and composition-contract residue families');
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
    legacy_assignment_default_pipeline_cli
    legacy_child_root_default_pipeline_cli
    strict_root_rejection_pipeline_cli
    strict_section_rejection_pipeline_cli
    strict_assignment_rejection_pipeline_cli
    strict_child_root_rejection_pipeline_cli
    language_contract_rejection_pipeline_cli
    direct_generation_contract_rejection_pipeline_cli
    composition_contract_rejection_pipeline_cli
);

my %strict_rejection_coverages = map { $_ => 1 } qw(
    strict_root_rejection_pipeline_cli
    strict_section_rejection_pipeline_cli
    strict_assignment_rejection_pipeline_cli
    strict_child_root_rejection_pipeline_cli
);

my %coverage_classification = (
    direct_root_pipeline_cli => 'supported_smoke',
    composition_top_pipeline_cli => 'supported_smoke',
    legacy_root_default_pipeline_cli => 'legacy_out_of_scope',
    legacy_section_default_pipeline_cli => 'legacy_out_of_scope',
    legacy_assignment_default_pipeline_cli => 'legacy_out_of_scope',
    legacy_child_root_default_pipeline_cli => 'legacy_out_of_scope',
    strict_root_rejection_pipeline_cli => 'expected_failure',
    strict_section_rejection_pipeline_cli => 'expected_failure',
    strict_assignment_rejection_pipeline_cli => 'expected_failure',
    strict_child_root_rejection_pipeline_cli => 'expected_failure',
    language_contract_rejection_pipeline_cli => 'expected_failure',
    direct_generation_contract_rejection_pipeline_cli => 'expected_failure',
    composition_contract_rejection_pipeline_cli => 'expected_failure',
);

my %seen_ids;
my %seen_contracts;
my %seen_diagnostic_codes;
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
    feature.direct_runtime_div_mod
    feature.direct_assignment_pair_form
    feature.direct_intent_integer_literals
    feature.composition_intent_integer_literals
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
    legacy.infix_assignment.default_compat
    legacy.infix_assignment.strict_rejection
    legacy.lteplus_assignment.default_compat
    legacy.lteplus_assignment.strict_rejection
    legacy.fsm_child_root.default_compat
    legacy.fsm_child_root.strict_rejection
    legacy.dt_child_root.default_compat
    legacy.dt_child_root.strict_rejection
    contract.language_contract_bad_size_entry
    contract.direct_size_expression_non_positive
    contract.direct_size_expression_unknown_symbol
    contract.direct_size_expression_aggregate_symbol
    contract.direct_size_expression_divide_by_zero
    contract.direct_size_expression_modulo_by_zero
    contract.direct_size_expression_unsupported_operator
    contract.direct_size_expression_bad_arity
    contract.direct_lhs_deconstruct_width_mismatch
    contract.unsupported_top_level_define_source
    contract.unsupported_top_level_clock_directive
    contract.generic_placeholder_selector
    contract.generic_repeat_macro
    contract.generic_placeholder_token
    contract.bare_assignment_condition_suffix
    contract.bare_transition_condition_suffix
    contract.malformed_top_level_system_root
    contract.malformed_single_token_action
    contract.malformed_empty_guard
    contract.malformed_empty_test_branch
    contract.malformed_bare_symbolic_test_selector
    contract.malformed_bare_numeric_test_selector
    contract.system_incomplete_section
    contract.system_duplicate_clock_entry
    contract.system_duplicate_reset_declaration
    contract.system_malformed_entry_structure
    contract.system_bad_clock_identifier
    contract.system_bad_reset_identifier
    contract.malformed_fsm_source_name
    contract.malformed_top_source_name
    contract.malformed_state_name
    contract.malformed_standalone_dt_name
    contract.malformed_transition_target
    contract.unknown_transition_target
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
    is(
        $coverage_classification{$entry->{coverage}},
        $entry->{classification},
        "catalog entry '$entry->{id}' keeps classification and coverage aligned",
    );

    my $path = File::Spec->catfile($repo_root, split m{/}, $entry->{relpath});
    ok(-e $path, "catalog entry '$entry->{id}' points at an existing repo file");
    if (ref($entry->{search_path_relpaths}) eq 'ARRAY') {
        for my $relpath (@{$entry->{search_path_relpaths}}) {
            my $search_path = File::Spec->catfile($repo_root, split m{/}, $relpath);
            ok(-d $search_path, "catalog entry '$entry->{id}' points at an existing search path '$relpath'");
        }
    }

    if ($entry->{classification} eq 'expected_failure') {
        like(
            $entry->{diagnostic_code} || '',
            qr/\AFSMGEN_[A-Z0-9_]+\z/,
            "expected-failure entry '$entry->{id}' records a stable diagnostic code",
        );
        ok(
            known_diagnostic_code($entry->{diagnostic_code}),
            "expected-failure entry '$entry->{id}' uses a known diagnostic code",
        );
        my $diagnostic_metadata = diagnostic_code_metadata($entry->{diagnostic_code});
        is(
            $diagnostic_metadata->{severity},
            'error',
            "expected-failure entry '$entry->{id}' maps to an error diagnostic",
        ) if $diagnostic_metadata;
        is(
            $diagnostic_metadata->{stability},
            'stable',
            "expected-failure entry '$entry->{id}' maps to a stable diagnostic",
        ) if $diagnostic_metadata;
        $seen_diagnostic_codes{$entry->{diagnostic_code}}++ if $entry->{diagnostic_code};
        ok($entry->{expected_error_pattern}, "expected-failure entry '$entry->{id}' records a boundary pattern");
        ok(ref($entry->{expected_error_pattern}) eq 'Regexp',
            "expected-failure entry '$entry->{id}' records its boundary pattern as a compiled regex");
        if (exists $entry->{expected_hint_pattern}) {
            ok($entry->{expected_hint_pattern}, "expected-failure entry '$entry->{id}' records a migration-hint pattern");
            ok(ref($entry->{expected_hint_pattern}) eq 'Regexp',
                "expected-failure entry '$entry->{id}' records its migration-hint pattern as a compiled regex");
        }
        if ($strict_rejection_coverages{$entry->{coverage}}) {
            ok(
                ref($entry->{expected_hint_pattern}) eq 'Regexp',
                "strict-rejection entry '$entry->{id}' records a compiled migration-hint pattern",
            );
        }
    }
    elsif (exists $entry->{diagnostic_code}) {
        fail("non-failure catalog entry '$entry->{id}' must not reserve a diagnostic code");
    }
    elsif ($entry->{source_kind} eq 'fsm') {
        ok($entry->{expected_module_name}, "direct-root entry '$entry->{id}' records an expected module name");
    }
    elsif ($entry->{source_kind} eq 'composition') {
        ok($entry->{expected_top_name}, "composition entry '$entry->{id}' records an expected top name");
        ok($entry->{expected_lane}, "composition entry '$entry->{id}' records an expected composition lane");
        ok($entry->{expected_instance_count} >= 1, "composition entry '$entry->{id}' records a positive child count");
        ok(ref($entry->{expected_child_modules}) eq 'ARRAY',
            "composition entry '$entry->{id}' records expected child modules as an array");
    }
    else {
        fail("catalog entry '$entry->{id}' uses an unsupported source kind '$entry->{source_kind}'");
    }

    if (exists $entry->{expected_hdl_patterns}) {
        ok(ref($entry->{expected_hdl_patterns}) eq 'ARRAY',
            "catalog entry '$entry->{id}' records HDL-shape patterns as an array");
        if (ref($entry->{expected_hdl_patterns}) eq 'ARRAY') {
            my $pattern_index = 0;
            for my $pattern (@{$entry->{expected_hdl_patterns}}) {
                ok(ref($pattern) eq 'Regexp',
                    "catalog entry '$entry->{id}' HDL-shape pattern $pattern_index is a compiled regex");
                ++$pattern_index;
            }
        }
    }

    if (
        $entry->{family} eq 'language_feature_fixture'
            && $entry->{classification} eq 'supported_smoke'
            && $entry->{coverage} eq 'direct_root_pipeline_cli'
    ) {
        ok(
            ref($entry->{expected_hdl_patterns}) eq 'ARRAY'
                && @{$entry->{expected_hdl_patterns}},
            "supported direct language-feature fixture '$entry->{id}' records explicit HDL-shape patterns",
        );
    }

    if ($entry->{strict_supported}) {
        is($entry->{classification}, 'supported_smoke', "strict-supported entry '$entry->{id}' is a supported-smoke asset");
        is($entry->{source_kind}, 'fsm', "strict-supported direct entry '$entry->{id}' is an FSM-root corpus asset")
            if $entry->{coverage} eq 'direct_root_pipeline_cli';
        ok(
            $entry->{coverage} eq 'direct_root_pipeline_cli'
                || $entry->{coverage} eq 'composition_top_pipeline_cli',
            "strict-supported entry '$entry->{id}' keeps pipeline/CLI coverage",
        );
    }
}

is(
    scalar(grep { $_->{classification} eq 'supported_smoke' } @entries),
    16,
    'catalog now keeps sixteen named supported-smoke entries including direct and composition language-feature fixtures',
);
is(
    scalar(grep { $_->{classification} eq 'legacy_out_of_scope' } @entries),
    9,
    'catalog now records nine explicit legacy-out-of-scope compatibility entries',
);
is(
    scalar(grep { $_->{classification} eq 'expected_failure' } @entries),
    57,
    'catalog now records fifty-seven explicit expected-failure entries',
);
is(
    scalar(grep { $_->{strict_supported} } @entries),
    16,
    'catalog now records sixteen positive strict-mode supported-smoke acceptance entries',
);
for my $strict_supported_id (qw(
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
    feature.direct_runtime_div_mod
    feature.direct_assignment_pair_form
    feature.direct_intent_integer_literals
    feature.composition_intent_integer_literals
)) {
    ok($by_id{$strict_supported_id}->{strict_supported}, "canonical strict-supported fixture $strict_supported_id stays marked");
}

for my $diagnostic_code (diagnostic_code_ids()) {
    ok($seen_diagnostic_codes{$diagnostic_code}, "stable diagnostic code $diagnostic_code is exercised by the corpus");
}

for my $entry (
    grep {
        $_->{family} eq 'language_feature_fixture'
            && $_->{classification} eq 'supported_smoke'
    } @entries
) {
    ok($entry->{strict_supported}, "supported language-feature fixture '$entry->{id}' is strict-supported");
}

for my $entry (
    grep {
        $_->{family} eq 'protocol_fixture'
            && $_->{classification} eq 'supported_smoke'
    } @entries
) {
    ok($entry->{strict_supported}, "supported protocol fixture '$entry->{id}' is strict-supported");
}

done_testing();
