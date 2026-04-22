#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::CompositionReportContract qw(
    build_composition_report_contract
    composition_report_collection_keys
    composition_report_contract_source
    composition_report_count_map_keys
    composition_report_example_map_keys
    composition_report_json_fragment_path
    composition_report_ordered_list_keys
    composition_report_presence_key_family_map
    composition_report_public_top_level_keys
    composition_report_raw_report_json_safe
    composition_report_raw_result_key
    composition_report_summary_keys
    sanitize_composition_report
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $contract = build_composition_report_contract();

subtest 'contract declares bounded serializable composition report surface' => sub {
    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public_json_fragment', 'contract marks report as bounded JSON fragment');
    is($contract->{contract_source}, composition_report_contract_source(), 'contract records its owner');
    is($contract->{report_builder}, 'FSM::Composition::ProvenanceReportBuilder', 'contract records report builder');
    is($contract->{raw_result_key}, composition_report_raw_result_key(), 'contract records raw result key');
    is(
        $contract->{json_fragment_path},
        composition_report_json_fragment_path(),
        'contract records normalized semantic JSON fragment path',
    );
    ok(!$contract->{raw_report_json_safe}, 'contract does not claim raw composition_report is JSON-safe');
    ok(!composition_report_raw_report_json_safe(), 'helper says raw composition_report is not JSON-safe');
    ok($contract->{sanitized_report_json_safe}, 'contract says sanitized report is JSON-safe');
    ok($contract->{sanitizes_private_perl_objects}, 'contract says private Perl objects are sanitized');
    ok(!$contract->{stable_nested_content}, 'contract does not overpromise every nested report branch as frozen');
    is_deeply(
        $contract->{summary_keys},
        composition_report_summary_keys(),
        'contract publishes the grouped composition-report summary key family',
    );
    is_deeply(
        $contract->{collection_keys},
        composition_report_collection_keys(),
        'contract publishes the grouped composition-report collection key family',
    );
    is_deeply(
        $contract->{count_map_keys},
        composition_report_count_map_keys(),
        'contract publishes the grouped composition-report count-map key family',
    );
    is_deeply(
        $contract->{example_map_keys},
        composition_report_example_map_keys(),
        'contract publishes the grouped composition-report example-map key family',
    );
    is_deeply(
        $contract->{ordered_list_keys},
        composition_report_ordered_list_keys(),
        'contract publishes the grouped composition-report ordered-list key family',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        composition_report_presence_key_family_map(),
        'contract publishes the grouped composition-report key-family map',
    );

    my %keys = map { $_ => 1 } @{$contract->{public_top_level_keys}};
    for my $key (qw(lane ports resolved_links override_events block_events ordered_port_origins)) {
        ok($keys{$key}, "contract includes public top-level key $key");
    }
};

subtest 'raw composition_report is sanitized into JSON-ready public fragment' => sub {
    my $result = generate_result('fsm/apb_tb.fsm');
    my $raw_report = $result->{composition_report};
    is(ref($raw_report), 'HASH', 'composition result carries raw composition_report hash');

    my $raw_json_ok = eval {
        encode_json($raw_report);
        1;
    };
    ok(!$raw_json_ok, 'raw composition_report is not treated as JSON-safe');

    my $sanitized = sanitize_composition_report($raw_report);
    is(ref($sanitized), 'HASH', 'sanitizer returns a hash');
    is_deeply(
        unknown_top_level_keys($sanitized),
        [],
        'sanitized report contains only declared public top-level keys',
    );
    ok(!contains_blessed($sanitized), 'sanitized report contains no blessed Perl objects');

    my $encoded = eval { encode_json($sanitized) };
    ok(defined($encoded) && length($encoded), 'sanitized report encodes as JSON');

    is($sanitized->{lane}, 'C4', 'sanitized report preserves composition lane');
    is($sanitized->{top_port_count}, 11, 'sanitized report preserves top port count');
    is($sanitized->{resolved_link_count}, 21, 'sanitized report preserves resolved-link count');
    is(ref($sanitized->{ports}), 'ARRAY', 'sanitized report preserves ports array');
    is(ref($sanitized->{resolved_links}), 'ARRAY', 'sanitized report preserves resolved links array');
    ok(@{$sanitized->{ports}}, 'sanitized report has port entries');
    ok(@{$sanitized->{resolved_links}}, 'sanitized report has resolved link entries');
};

subtest 'normalized semantic JSON exposes sanitized composition provenance report' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', repo_file('fsm/apb_tb.fsm')],
    );

    ok($success, 'semantic JSON export succeeds for APB composition fixture');
    is(join('', @{$stderr_buf || []}), '', 'semantic JSON export keeps stderr clean');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    my $report = $decoded->{semantic}{composition}{provenance_report};
    is(ref($report), 'HASH', 'semantic JSON contains composition provenance report');
    is($report->{lane}, 'C4', 'semantic JSON report preserves composition lane');
    is($report->{top_port_count}, 11, 'semantic JSON report preserves top port count');
    is($report->{resolved_link_count}, 21, 'semantic JSON report preserves resolved-link count');
    ok(!contains_blessed($report), 'decoded semantic JSON report contains no blessed objects');
    is_deeply(
        unknown_top_level_keys($report),
        [],
        'semantic JSON report contains only declared public top-level keys',
    );
};

done_testing();

sub generate_result {
    my ($relpath) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
    );
    return $pipeline->generate_hdl_from_file(repo_file($relpath));
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub unknown_top_level_keys {
    my ($report) = @_;
    my %known = map { $_ => 1 } @{composition_report_public_top_level_keys()};
    return [grep { !$known{$_} } sort keys %{$report || {}}];
}

sub contains_blessed {
    my ($value) = @_;
    return 0 unless ref($value);
    return 1 if blessed($value) && !JSON::PP::is_bool($value);
    if (ref($value) eq 'HASH') {
        for my $child (values %$value) {
            return 1 if contains_blessed($child);
        }
        return 0;
    }
    if (ref($value) eq 'ARRAY') {
        for my $child (@$value) {
            return 1 if contains_blessed($child);
        }
        return 0;
    }
    return 0;
}
