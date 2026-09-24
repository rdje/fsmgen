#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP ();
use Test::More;
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib";
use FSM::Test::SourceQueryCoverage qw(build_source_query_cohort);
use FSM::Test::SourceQueryRunner qw(run_source_query normalize_repository_paths);

my $loaded = eval { require FSM::Test::SourceQueryOracle; 1 };
ok($loaded, 'independent source-query semantic oracle exists');
if (!$loaded) { diag($@); done_testing(); exit 0 }
my $semantic = \&FSM::Test::SourceQueryOracle::source_query_semantic_errors;
my $envelope = \&FSM::Test::SourceQueryOracle::source_query_envelope_errors;
my $repo = abs_path("$FindBin::Bin/..");
chdir $repo or die $!;
my $json = JSON::PP->new->canonical->allow_nonref;
my %rows = map {$_->{source_id} => $_} @{build_source_query_cohort()};
my %cases;
my @selection = (
    ['storage', 'isf/storage_fields.isf', 'schedule'],
    ['observation', 'isf/verification_observation_metadata.isf', 'schedule'],
    ['direct', 't/corpus/direct_size_expression_widths.fsm', 'semantic'],
    ['composition', 't/corpus/composition_intent_integer_literals.fsm', 'semantic'],
    ['base', 'vial/ahb_subordinate_base_output_arbitration.vial', 'inspection'],
    ['v2', 'vial/ahb_subordinate_base_output_arbitration_v2.vial', 'inspection'],
    ['lifecycle', 'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial', 'inspection'],
);
sub clone {$json->decode($json->encode($_[0]))}
sub checked {
    my ($row, $kind, $diagnostic) = @_;
    my $r = run_source_query({repository_root => $repo, row => $row, query_kind => $kind});
    is($r->{native}{exit_code}, defined($diagnostic) ? 1 : 0, 'actual native source admission exit');
    is($r->{stdio}{exit_code}, 0, 'actual newline transport exits successfully');
    is($r->{native}{signal} + $r->{stdio}{signal}, 0, 'no process terminated by a signal');
    my $report = normalize_repository_paths($r->{native}{report}, $repo);
    my $api = $r->{adapter_result};
    is($json->encode($api->{structuredContent}{report}), $json->encode($report), 'complete typed native/API report equality');
    is($json->encode($r->{vial_api_report}), $json->encode($report), 'explicit VIAL file API preserves the full report')
        if $row->{file_kind} eq 'vial';
    is($json->encode($r->{stdio}{response}), $json->encode({jsonrpc => '2.0', id => 1, result => $api}),
        'complete typed newline/API response equality');
    is_deeply($envelope->({row => $row, query_kind => $kind, result => $api,
        expected_failure => defined($diagnostic) ? 1 : 0}), [], 'independent envelope oracle passes');
    my $args = {row => $row, query_kind => $kind, report => $report, source_sha256 => $r->{source_sha256_before},
        defined($diagnostic) ? (expected_diagnostic => $diagnostic) : ()};
    is_deeply($semantic->($args), [], 'independent authored/public report oracle passes');
    is($r->{source_sha256_after}, $r->{source_sha256_before}, 'source query preserves original bytes');
    return {args => $args, result => $api};
}
subtest 'actual producers satisfy independent authored feature witnesses' => sub {
    for my $selection (@selection) {
        my ($name, $source, $kind) = @$selection;
        $cases{$name} = checked($rows{$source}, $kind);
    }
};

subtest 'identical corrupted reports cannot satisfy independent semantics' => sub {
    my $p = '/inspection/packages/0';
    my $f = "$p/fixtures/0";
    my $nodes = "$p/intent_families/0/nodes";
    my @mutations = (
        ['storage', '/inferred_storage/0/fields', undef, qr/fields/],
        ['storage', '/inferred_storage/0/fields/0/msb', 6, qr/fields/],
        ['storage', '/inferred_storage/0/fields/0/enum/1/value', 4, qr/fields/],
        ['storage', '/inferred_storage/0/width', 7, qr/width/],
        ['observation', '/verification_observations/0/signals/2/width', 7, qr/verification_observations/],
        ['observation', '/verification_observations/0/signals', [], qr/verification_observations/],
        ['observation', '/verification_observations/0/role', 'active_driver', qr/verification_observations/],
        ['observation', '/verification_observations/0/reset/polarity', 'active_high', qr/verification_observations/],
        ['direct', '/semantic/module/name', 'wrong', qr/module\/name/],
        ['composition', '/semantic/module/name', 'wrong_top', qr/module\/name/],
        ['direct', '/normalized_semantic_schema_version', 99, qr/schema_version/],
        ['direct', '/success', 1, qr/success/],
        ['direct', '/producer/report_source', 'private.producer', qr/report_source/],
        ['direct', '/source/resolved_path', 'other.fsm', qr/resolved_path/],
        ['direct', '/semantic/forward_ir/intent_hir', undef, qr/intent_hir/],
        ['base', "$f/scenarios/0/actions/0/cycles", 2, qr/cycles/],
        ['base', "$f/scenarios/0/actions/0/cycles", '3', qr/cycles/],
        ['base', "$f/faults/0/transaction_binding_id", undef, qr/transaction_binding_id/],
        ['v2', "$p/models/0/rules/0/assignments/0/expression/op", '-', qr/expression\/op/],
        ['v2', "$f/instances/model_instances/1/name", 'accepts', qr/model_instances/],
        ['lifecycle', "$nodes/1/payload/condition/domain_id", 'other_domain', qr/condition/],
        ['lifecycle', "$nodes/2/payload/detail/cancellation", 'abandon', qr/cancellation/],
        ['lifecycle', "$nodes/3/payload/condition/operands", [], qr/condition/],
        ['lifecycle', "$nodes/9/payload/detail/max_cycles", 1023, qr/detail/],
        ['lifecycle', "$nodes/10/payload/detail/last_cycle_inclusive", JSON::PP::false, qr/detail/],
        ['lifecycle', "$nodes/11/payload/detail/cleanup", 'none', qr/detail/],
        ['lifecycle', "$p/intent_families/0/family_id", 'future_family', qr/family_id/],
        ['lifecycle', "$p/intent_families/0/revision", 2, qr/revision/],
        ['lifecycle', "$nodes/0/node_kind", 'future_kind', qr/node kinds/],
        ['lifecycle', '/inspection', undef, qr/inspection/],
    );
    for my $mutation (@mutations) {
        my ($name, $path, $value, $expected) = @$mutation;
        my $args = clone($cases{$name}{args});
        replace($args->{report}, $path, $value);
        my @transports = map {clone($args->{report})} 1..3;
        is_deeply($transports[0], $transports[1], "$name $path: ordinary report parity still passes");
        is_deeply($transports[1], $transports[2], 'all three transports share the corruption');
        my $before = $json->encode($args);
        like(join('\n', @{$semantic->($args)}), $expected, 'independent oracle catches the named loss or wrong value');
        is($json->encode($args), $before, 'oracle never repairs or mutates evidence');
    }
    for my $missing (undef, [], 'not a report', {}) {
        my $args = clone($cases{direct}{args}); $args->{report} = $missing;
        ok(@{$semantic->($args)}, 'missing or unrelated report cannot pass');
    }
    for my $change ([file_kind => 'future'], [language_version => 3], [source_id => 'vial/future.vial']) {
        my $args = clone($cases{lifecycle}{args}); $args->{row}{$change->[0]} = $change->[1];
        like(join('\n', @{$semantic->($args)}), qr/unregistered/, 'future source/version requires explicit oracle admission');
    }
};

subtest 'identity and provenance corruption cannot hide behind identical envelopes' => sub {
    for my $change (
        ['/structuredContent/source_id', 'other.fsm', qr/source_id/],
        ['/structuredContent/query_kind', 'execute', qr/query_kind/],
        ['/structuredContent/adapter_provenance/contract_source', 'private', qr/adapter_provenance/],
        ['/structuredContent/adapter_provenance/read_only', JSON::PP::false, qr/adapter_provenance/],
        ['/structuredContent/report', undef, qr/report/],
        ['/isError', JSON::PP::true, qr/isError/],
    ) {
        my ($path, $value, $expected) = @$change;
        my $result = clone($cases{direct}{result}); replace($result, $path, $value);
        $result->{content}[0]{text} = $json->encode($result->{structuredContent});
        my $same = clone($result);
        is_deeply($same, $result, 'transport and text equality cannot reveal shared corruption');
        like(join('\n', @{$envelope->({row => $cases{direct}{args}{row}, query_kind => 'semantic', result => $result})}),
            $expected, 'independent envelope oracle catches the corrupted contract');
    }
};

subtest 'actual failed sources retain full diagnostics without partial success' => sub {
    my $hardware = {source_id => 'fsm/mipicsi2_txccore_ulp.fsm', file_kind => 'fsm', source_kind => 'fsm',
        strict => JSON::PP::true, language_version => undef, query_kinds => [qw(check semantic)],
        search_path_relpaths => [], expectations => {}};
    for my $kind (qw(check semantic)) {
        my $case = checked($hardware, $kind, 'FSMGEN_STRICT_LEGACY_FSM_ROOT');
        failure_controls($case);
    }
    my $dir = tempdir('source-query-oracle-XXXXXXXX', DIR => "$repo/t", CLEANUP => 1);
    open my $fh, '>:raw', "$dir/invalid.vial" or die $!; print {$fh} '(' or die $!; close $fh or die $!;
    my $source = File::Spec->abs2rel("$dir/invalid.vial", $repo);
    my $vial = {source_id => $source, file_kind => 'vial', source_kind => 'vial', strict => JSON::PP::false,
        language_version => 2, query_kinds => [qw(check semantic inspection)], search_path_relpaths => []};
    for my $kind (qw(check inspection)) {
        my $case = checked($vial, $kind, 'VIAL_PARSE_ERROR');
        failure_controls($case);
    }
};
done_testing();

sub replace {
    my ($root, $path, $value) = @_;
    my @parts = split m{/}, substr($path, 1); my $last = pop @parts;
    for my $part (@parts) { $root = ref($root) eq 'ARRAY' ? $root->[$part] : $root->{$part} }
    if (ref($root) eq 'ARRAY') { $root->[$last] = $value } else { $root->{$last} = $value }
}
sub failure_controls {
    my ($case) = @_;
    my $args = clone($case->{args}); $args->{report}{success} = JSON::PP::true;
    like(join('\n', @{$semantic->($args)}), qr/success/, 'success on a refused source is detected');
    $args = clone($case->{args}); $args->{report}{diagnostics} = [];
    like(join('\n', @{$semantic->($args)}), qr/diagnostics/, 'lost original refusal diagnostic is detected');
    my $result = clone($case->{result}); $result->{isError} = JSON::PP::false;
    like(join('\n', @{$envelope->({row => $args->{row}, query_kind => $args->{query_kind},
        result => $result, expected_failure => 1})}), qr/isError/, 'refusal cannot be advertised as successful MCP tool output');
}
