#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename);
use FindBin;
use JSON::PP ();
use Test::More;
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib";
use FSM::Test::SourceQueryCoverage qw(build_source_query_cohort select_source_query_cohort);
use FSM::Test::HostedCorpusShard qw(hosted_corpus_list_only select_hosted_corpus_entries);

my $repo = abs_path("$FindBin::Bin/..");
chdir $repo or die "chdir repository: $!";
my $json = JSON::PP->new->canonical;
my @focus = qw(
    t/corpus/direct_size_expression_widths.fsm
    t/corpus/composition_intent_integer_literals.fsm
    isf/storage_fields.isf
    isf/verification_observation_metadata.isf
    ppif/axi_aw_valid_ready.ppif
    ppif/apb_requester_transfer.apb
    vial/ahb_subordinate_base_output_arbitration.vial
    vial/ahb_subordinate_base_output_arbitration_v2.vial
    vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial
);
my $all = $ENV{FSMGEN_SOURCE_QUERY_ALL} // '0';
die "FSMGEN_SOURCE_QUERY_ALL must be 0 or 1\n" unless $all =~ /\A[01]\z/;
die "all-source and focused-source selectors are mutually exclusive\n"
    if $all && exists $ENV{FSMGEN_SOURCE_QUERY_SOURCES};
my $cohort = build_source_query_cohort();
my $selected = select_source_query_cohort({cohort => $cohort,
    $all ? () : (source_ids => exists($ENV{FSMGEN_SOURCE_QUERY_SOURCES})
        ? $json->decode($ENV{FSMGEN_SOURCE_QUERY_SOURCES}) : \@focus)});
$selected = select_hosted_corpus_entries(entries => $selected);
if (hosted_corpus_list_only()) {
    for my $row (@$selected) { print "$_:$row->{source_id}\n" for @{$row->{query_kinds}} }
    exit 0;
}

my $loaded = eval { require FSM::Test::SourceQueryRunner; 1 };
ok($loaded, 'actual source-query runner exists');
if (!$loaded) { diag($@); done_testing(); exit 0 }
my $run = \&FSM::Test::SourceQueryRunner::run_source_query;
my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my @receipts;

subtest 'normalization is limited to the repository prefix' => sub {
    my $value = {path => "$repo/fsm/example.fsm", root => $repo, outside => '/elsewhere/x',
        embedded => "in $repo/fsm/example.fsm: failed", semantic => '/packages/0/actions/1',
        values => [0, 1, '1', undef, JSON::PP::true, JSON::PP::false], diagnostics => ['kept']};
    my $before = $json->encode($value);
    my $expected = $json->decode($before);
    @$expected{qw(path root embedded)} = ('fsm/example.fsm', '.', 'in fsm/example.fsm: failed');
    is($json->encode($normalize->($value, $repo)), $json->encode($expected),
        'all fields, order, scalar types, semantic paths and non-repository paths survive');
    is($json->encode($value), $before, 'normalization does not modify the input');
};

subtest 'subprocess capture drains both pipes and preserves refusal status' => sub {
    my $r = FSM::Test::SourceQueryRunner::_capture([$^X, '-e',
        'local $/; my $s=<STDIN>; print STDERR "e" x 131072; print STDOUT $s, "o" x 131072; exit 7'], "request\n");
    is($r->{stdout}, "request\n".('o' x 131072), 'complete large stdout after stdin EOF');
    is($r->{stderr}, 'e' x 131072, 'complete simultaneous stderr');
    is($r->{exit_code}, 7, 'nonzero exit retained');
    is($r->{signal}, 0, 'ordinary exit distinguished from a signal');
};

for my $row (@$selected) {
    for my $kind (@{$row->{query_kinds}}) {
        subtest "$kind $row->{source_id}" => sub {
            my $receipt = eval {$run->({repository_root => $repo, row => $row, query_kind => $kind})};
            ok($receipt, 'actual native/API/newline query completes') or do { diag($@); return };
            for my $transport (qw(native stdio)) {
                is($receipt->{$transport}{exit_code}, 0, "$transport succeeds");
                is($receipt->{$transport}{signal}, 0, "$transport has no terminating signal");
                is($receipt->{$transport}{stderr}, '', "$transport has no stderr");
            }
            is($receipt->{source_sha256_after}, $receipt->{source_sha256_before}, 'source bytes unchanged');
            is_deeply($receipt->{producer_sha256_after}, $receipt->{producer_sha256_before},
                'repository-bound public producers unchanged');
            like($receipt->{stdio}{stdout}, qr/\A[^\n]+\n\z/, 'one compact JSON response per newline');
            my $api = $receipt->{adapter_result};
            is_deeply($receipt->{stdio}{response}, {jsonrpc => '2.0', id => 1, result => $api},
                'complete actual newline response equals public adapter result');
            ok(!$api->{isError}, 'supported source is not a tool error');
            my $payload = $api->{structuredContent};
            is_deeply($json->decode($api->{content}[0]{text}), $payload, 'complete text/structured equality');
            my $report = $normalize->($receipt->{native}{report}, $repo);
            is_deeply($payload->{report}, $report, 'complete native/MCP report equality');
            is($payload->{source_id}, $row->{source_id}, 'source identity retained');
            is($payload->{source_path}, $row->{source_id}, 'source path remains relative');
            is($payload->{query_kind}, $kind, 'query identity retained');
            provenance($payload, $row, $kind);
            report_contract($report, $row, $kind, $receipt);
            push @receipts, {
                source_id => $row->{source_id}, query_kind => $kind,
                catalog_ids => [map {$_->{id}} @{$row->{catalog_entries}}],
                source_sha256 => $receipt->{source_sha256_before},
                producer_sha256 => $receipt->{producer_sha256_before},
                native_report_sha256 => sha256_hex($json->encode($report)),
                adapter_report_sha256 => sha256_hex($json->encode($payload->{report})),
                stdio_report_sha256 => sha256_hex($json->encode($receipt->{stdio}{response}{result}{structuredContent}{report})),
                public_vial_api_report_sha256 => defined($receipt->{vial_api_report})
                    ? sha256_hex($json->encode($receipt->{vial_api_report})) : undef,
            };
        };
    }
}
if (exists $ENV{FSMGEN_SOURCE_QUERY_RECEIPT}) {
    my $name = $ENV{FSMGEN_SOURCE_QUERY_RECEIPT};
    die "receipt name must be a simple JSON basename\n" unless $name =~ /\A[a-z0-9_-]+\.json\z/;
    my $directory = "$repo/.artifacts/mcp-feature-coverage";
    my $resolved = abs_path($directory);
    die "receipt directory must exist on the repository volume\n"
        unless defined($resolved) && index($resolved, "$repo/") == 0
            && (stat($resolved))[0] == (stat($repo))[0];
    die "receipt must not replace a symlink\n" if -l "$directory/$name";
    open my $fh, '>:raw', "$directory/$name" or die "open receipt: $!";
    print {$fh} $json->pretty->encode({schema => 'fsmgen.source_query_execution_receipt.v1',
        passing => Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false,
        selected_sources => [map {$_->{source_id}} @$selected], queries => \@receipts}) or die "write receipt: $!";
    close $fh or die "close receipt: $!";
}
done_testing();

sub provenance {
    my ($payload, $row, $kind) = @_;
    my %shape = (check => 'bin/fsmgen --strict --check --json <source>',
        semantic => 'bin/fsmgen --strict --emit-semantic-json <source>',
        schedule => 'bin/fsmgen --emit-schedule-json <source>');
    my $expected = {contract_source => 'FSM::Support::SemanticIntrospectionMCPAdapter',
        transport => 'jsonrpc_stdio', read_only => JSON::PP::true, shell_access => JSON::PP::false,
        workspace_root_policy => 'caller_configured_root_not_returned', source_identity => 'workspace_relative',
        command_shape => $shape{$kind}};
    my $paths = {machine_local_absolute_paths => 'workspace_or_repo_absolute_paths_return_relative_else_redacted'};
    if ($row->{file_kind} eq 'vial') {
        $expected->{command_shape} = undef;
        $expected->{api_entrypoint} = 'FSM::VIAL::Tool::'.($kind eq 'inspection' ? 'inspect' : 'check').'_vial_source_file';
        $expected->{language_version} = $row->{language_version};
        $paths = {machine_local_absolute_paths => 'public_vial_relative_source_contract',
            semantic_paths => 'preserved_public_semantic_paths'};
    }
    is_deeply($payload->{adapter_provenance}, $expected, 'complete adapter provenance matches public invocation');
    is_deeply($payload->{path_sanitization}, $paths, 'path policy matches this source family');
}

sub report_contract {
    my ($report, $row, $kind, $receipt) = @_;
    if ($row->{file_kind} eq 'vial') {
        is_deeply($receipt->{vial_api_report}, $report, 'explicit public VIAL API equals complete native report');
        my $checked = $report;
        if ($kind eq 'inspection') {
            is($report->{schema}, 'fsmgen.vial_source_inspection.v1', 'independent inspection schema');
            is($report->{schema_version}, 1, 'inspection schema version');
            ok($report->{success}, 'outer inspection succeeded');
            is_deeply($report->{diagnostics}, [], 'no outer inspection diagnostics');
            $checked = $report->{check_result};
            is($report->{inspection}{language_version}, $row->{language_version}, 'detail language version');
            is($report->{inspection}{root_source}{source_name}, $row->{source_id}, 'detail source identity');
            is($report->{inspection}{root_source}{content_sha256}, $receipt->{source_sha256_before}, 'detail exact source bytes');
        }
        is($checked->{schema}, "fsmgen.vial_tool_result.v$row->{language_version}", 'versioned VIAL check schema');
        is($checked->{schema_version}, $row->{language_version}, 'native VIAL schema version');
        is($checked->{action}, 'check', 'VIAL source admission action');
        ok($checked->{success}, 'native VIAL admission succeeded');
        is($checked->{status}, 'checked', 'VIAL source checked without execution');
        is_deeply($checked->{diagnostics}, [], 'VIAL has no diagnostics');
        is($checked->{source_identities}[0]{source_name}, $row->{source_id}, 'check source identity');
        is($checked->{source_identities}[0]{content_sha256}, $receipt->{source_sha256_before}, 'check exact source bytes');
        return;
    }
    if ($kind eq 'schedule') {
        if (exists $report->{schema}) {
            like($report->{schema}, qr/\Afsmgen\.ial2\.[a-z0-9_.]+\.v1\z/, 'public IAL2 protocol report schema');
            is(ref($report->{source_object}), 'HASH', 'protocol report retains source-object provenance');
            ok(length($report->{source_object}{id} // ''), 'protocol source-object identity is present');
        } else {
            is($report->{schema_version}, 1, 'public ISF schedule schema version');
            is($report->{source}, basename($row->{source_id}), 'schedule source basename');
            ok(defined($report->{scheduled_fsm}) && !ref($report->{scheduled_fsm})
                && $report->{scheduled_fsm} =~ /\.fsm\z/, 'schedule names its public FSM artifact');
        }
        return;
    }
    my $semantic = $kind eq 'semantic';
    is($report->{$semantic ? 'normalized_semantic_schema_version' : 'check_schema_version'}, 1, 'public report schema');
    ok($report->{success}, 'native hardware admission succeeded');
    is($report->{command}{mode}, $semantic ? 'semantic_export' : 'check', 'public producer mode');
    ok($report->{command}{json} && $report->{command}{strict_mode}, 'JSON and strict admission');
    is($report->{source}{resolved_path}, $row->{source_id}, 'native resolved source matches selection');
    is_deeply($report->{diagnostics}, [], 'supported source has no diagnostics');
    ok(!$report->{generated_output}{emitted}, 'query has no HDL emission');
    my $account = $report->{support_accounting};
    my ($entry) = grep {$_->{id} eq ($account->{entry_id} // '')} @{$row->{catalog_entries}};
    ok($account->{matched} && $entry, 'native representative belongs to retained catalog membership');
    if ($entry) {
        is($account->{$_}, $entry->{$_}, "native catalog $_ matches its exact entry") for qw(family coverage);
    }
    is($account->{classification}, 'supported_smoke', 'native support classification');
    is($account->{source_kind}, $row->{source_kind}, 'native source-kind provenance');
    ok($account->{strict_supported}, 'native strict support');
    my $module = $row->{expectations}{expected_top_name} // $row->{expectations}{expected_module_name};
    ok(defined($module), 'catalog supplies an independent module expectation');
    is($semantic ? $report->{semantic}{module}{name} : $report->{result}{module_name}, $module,
        'native module/top matches catalog');
    if ($semantic) {
        my $root_kind = $row->{expectations}{expected_semantic_source_root_kind}
            // ($row->{source_kind} eq 'composition' ? 'top' : $row->{source_kind});
        is($report->{semantic}{module}{source_root_kind}, $root_kind, 'semantic root kind matches catalog');
        ok(!exists($report->{raw_ast}) && !exists($report->{hdl_code}), 'private AST and generated HDL are absent');
    }
}
