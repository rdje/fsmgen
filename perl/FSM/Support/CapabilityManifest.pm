package FSM::Support::CapabilityManifest;

use strict;
use warnings;

use Exporter 'import';
use File::Basename qw(dirname);
use File::Spec;
use JSON::PP ();
use FSM::Support::DiagnosticCodes qw(diagnostic_code_registry);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);

our @EXPORT_OK = qw(build_capability_manifest);

sub build_capability_manifest {
    my @entries = regression_corpus_entries();

    my %classifications = _count_by(\@entries, 'classification');
    my %coverage_buckets = _count_by(\@entries, 'coverage');
    my %families = _count_by(\@entries, 'family');
    my %source_kinds = _count_by(\@entries, 'source_kind');

    my @strict_supported_ids = map { $_->{id} } grep { $_->{strict_supported} } @entries;
    my @supported_ids = map { $_->{id} } grep { $_->{classification} eq 'supported_smoke' } @entries;
    my @expected_failure_ids = map { $_->{id} } grep { $_->{classification} eq 'expected_failure' } @entries;
    my $diagnostic_registry = diagnostic_code_registry();

    return {
        manifest_schema_version => 1,
        producer => {
            name => 'FSMGen',
            version => '0.1-dev',
            git_commit => _git_head_short() || 'unknown',
            contract_authority => JSON::PP::true,
            source => 'FSM::Support::CapabilityManifest',
        },
        support_accounting => {
            source => 'FSM::Support::RegressionCorpus',
            entry_count => scalar(@entries),
            classifications => \%classifications,
            coverage_buckets => \%coverage_buckets,
            families => \%families,
            source_kinds => \%source_kinds,
            supported_smoke_ids => \@supported_ids,
            strict_supported_ids => \@strict_supported_ids,
            expected_failure_ids => \@expected_failure_ids,
            catalog_entries => [
                map { _manifest_entry($_) } @entries,
            ],
        },
        diagnostics => {
            registry_source => 'FSM::Support::DiagnosticCodes',
            stable_codes => [
                map {
                    +{
                        code => $_,
                        %{$diagnostic_registry->{$_}},
                    }
                } sort keys %{$diagnostic_registry}
            ],
            check_json => {
                schema_version => 1,
                status => 'bounded_public',
                command_shape => './bin/fsmgen --strict --check --json path/to/file.fsm',
                alias => './bin/fsmgen --strict --check-json path/to/file.fsm',
                emits_stable_codes => JSON::PP::true,
                emits_hdl => JSON::PP::false,
                unclassified_failures_use_null_code => JSON::PP::true,
                emits_support_accounting_object => JSON::PP::true,
                emits_success_support_accounting_object => JSON::PP::true,
                supported_smoke_corpus_covered => JSON::PP::true,
                strict_supported_corpus_covered => JSON::PP::true,
                expected_failure_corpus_covered => JSON::PP::true,
                classifier_match_policy => 'most_specific_expected_error_pattern',
                success_match_policy => 'resolved_source_path_to_non_failure_corpus_entry',
                report_source => 'FSM::Support::CheckDiagnostics',
            },
        },
        semantic_exports => {
            normalized_semantic_json => {
                schema_version => 1,
                status => 'bounded_public',
                command_shape => './bin/fsmgen --strict --emit-semantic-json path/to/file.fsm',
                alias => './bin/fsmgen --strict --semantic-json path/to/file.fsm',
                emits_hdl => JSON::PP::false,
                emits_support_accounting_object => JSON::PP::true,
                success_match_policy => 'resolved_source_path_to_non_failure_corpus_entry',
                failure_diagnostics_reuse_stable_codes => JSON::PP::true,
                sanitizes_private_perl_objects => JSON::PP::true,
                public_layers => [qw(intent_hir lowered_rtl_ir structural_rtl_ir)],
                report_source => 'FSM::Support::NormalizedSemanticReport',
                full_export_stable => JSON::PP::false,
            },
        },
        language_surface => {
            strict_mode => {
                intended_for_generated_fsm => JSON::PP::true,
                compatibility_syntax_is_canonical => JSON::PP::false,
                canonical_direct_roots => [qw(?fsm ?dt ?mod)],
                canonical_composition_roots => [qw(?top ?rtlif ?pkg)],
                canonical_child_roots => [qw(?fsmc ?dtc ?rtl)],
            },
            default_mode_compatibility => {
                accepted_but_not_canonical_for_generated_output => [
                    '+fsm root family',
                    '?module direct root alias',
                    'empty (+size) section',
                    '(asreset rstn) reset spelling',
                    '(sreset rstn) reset spelling',
                    'compact (:= signal=value) init/default directive',
                    'infix assignment forms such as (OUT = SRC)',
                    'legacy child roots under ?fsmc / ?dtc',
                ],
            },
            assignments => {
                canonical_pair_forms => [qw(= <- <=)],
                canonical_lhs_pack_forms => [qw(concat cat)],
                canonical_rhs_pack_forms => [qw(concat cat)],
                compatibility_forms => ['infix assignment forms'],
            },
            system_contracts => {
                canonical_clock => '(clock clk)',
                canonical_synchronous_reset => '(sreset reset)',
                canonical_asynchronous_reset => '(areset rst_n)',
                legacy_or_misleading_reset_forms_rejected_in_strict => [
                    '(asreset rstn)',
                    '(sreset rstn)',
                ],
            },
            expressions => {
                scalar_constant_expression_operators => [qw(+ - * / % & | ^ add sub mul div mod and or xor)],
                runtime_expression_operators => [qw(+ - * / % & | ^ && || == != < <= > >= !)],
                literal_families => [
                    'decimal',
                    '0d decimal',
                    '0b binary',
                    '0o octal',
                    '0x hex',
                    'SystemVerilog based literals',
                ],
            },
            declarations => {
                scalar_and_aggregate_names => [qw(+constants +enums +params +types +define +import)],
                width_declarations => ['+size with positive integer literal or constant expression terms'],
                package_roots => ['?pkg reusable scalar/aggregate/type/enum declarations'],
            },
            composition => {
                top_root => '?top',
                generated_children => [qw(?fsmc ?dtc)],
                external_rtl_children => ['?rtl with ?rtlif sidecar or embedded metadata'],
                wiring => ['?ports', '?toplink', '=port connect-by-name'],
                lanes => [qw(C1 C2 C3 C4)],
            },
            intentionally_blocked_or_not_yet_public => [
                'VHDL backend generation',
                'unchecked annotations treated as enforced metadata',
                'full normalized semantic JSON export beyond the bounded public semantic JSON slice',
                'full check-only JSON diagnostic schema stabilization',
                'unbounded aggregate expression domains',
                'SPECFORGE PDF/prose IntentIR extraction',
            ],
        },
        documentation => {
            human_contract => [
                'docs/book/src/SUMMARY.md',
                'docs/USER_GUIDE.md',
                'docs/REGRESSION_CORPUS.md',
            ],
            downstream_alignment => [
                'docs/SPECFORGE_FEEDBACK_RESPONSE.md',
            ],
        },
    };
}

sub _manifest_entry {
    my ($entry) = @_;

    my %manifest = map { $_ => $entry->{$_} } grep { exists $entry->{$_} } qw(
        id
        relpath
        family
        classification
        coverage
        source_kind
        strict_supported
        expected_module_name
        expected_top_name
        expected_lane
        expected_instance_count
        diagnostic_code
    );

    $manifest{strict_supported} = $entry->{strict_supported} ? JSON::PP::true : JSON::PP::false;
    $manifest{expected_child_modules} = [@{$entry->{expected_child_modules}}]
        if ref($entry->{expected_child_modules}) eq 'ARRAY';
    $manifest{search_path_relpaths} = [@{$entry->{search_path_relpaths}}]
        if ref($entry->{search_path_relpaths}) eq 'ARRAY';
    $manifest{expected_hdl_pattern_count} = scalar(@{$entry->{expected_hdl_patterns}})
        if ref($entry->{expected_hdl_patterns}) eq 'ARRAY';
    $manifest{has_expected_error_pattern} = $entry->{expected_error_pattern}
        ? JSON::PP::true
        : JSON::PP::false;
    $manifest{has_expected_hint_pattern} = $entry->{expected_hint_pattern}
        ? JSON::PP::true
        : JSON::PP::false;

    return \%manifest;
}

sub _count_by {
    my ($entries, $field) = @_;

    my %counts;
    for my $entry (@{$entries}) {
        my $value = $entry->{$field};
        $value = 'unknown' unless defined $value && length $value;
        $counts{$value}++;
    }

    return %counts;
}

sub _git_head_short {
    my $repo_root = File::Spec->rel2abs(
        File::Spec->catdir(dirname(__FILE__), '..', '..', '..'),
    );
    my $git_dir = File::Spec->catdir($repo_root, '.git');
    my $head_path = File::Spec->catfile($git_dir, 'HEAD');
    return undef unless -f $head_path;

    open my $head_fh, '<', $head_path or return undef;
    my $head = <$head_fh>;
    close $head_fh or return undef;
    return undef unless defined $head;
    chomp $head;

    if ($head =~ /^ref:\s*(.+)$/) {
        my $ref_path = File::Spec->catfile($git_dir, split m{/}, $1);
        return undef unless -f $ref_path;
        open my $ref_fh, '<', $ref_path or return undef;
        my $commit = <$ref_fh>;
        close $ref_fh or return undef;
        return _short_commit($commit);
    }

    return _short_commit($head);
}

sub _short_commit {
    my ($commit) = @_;
    return undef unless defined $commit;
    chomp $commit;
    return undef unless $commit =~ /\A([0-9a-fA-F]{7,40})\z/;
    return substr(lc($1), 0, 12);
}

1;
