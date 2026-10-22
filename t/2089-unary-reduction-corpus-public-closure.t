use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use Cwd qw(abs_path);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use File::Temp qw(tempdir);
use JSON::PP;
use Storable qw(dclone);
use FSM::Test::ProjectDataLocality;
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::SemanticIntrospectionContract qw(semantic_introspection_source_query_kinds);
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Test::SourceQueryCoverage qw(build_source_query_cohort vial_source_versions);
use FSM::Test::SourceQueryRunner qw(run_source_query normalize_repository_paths);
use FSM::Test::SourceQueryOracle qw(source_query_semantic_errors source_query_envelope_errors);
use FSM::Test::UnaryReductionCorpusOracle qw(unary_reduction_ports unary_reduction_records unary_reduction_catalog);

# ISF-REDUCTION-DELIVERY.1.2.3.3.2: complete discovery/applicability is
# separate from actual maintained-source queries, generation and HDL execution.
my $root = abs_path('.');
my $json = JSON::PP->new->canonical->utf8;
my $source = 'isf/unary_reductions.isf';
my @catalog = regression_corpus_entries();
my $cohort = build_source_query_cohort();
my ($row) = grep {$_->{source_id} eq $source} @$cohort;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $manifest = build_capability_manifest();
my $capture_dir;
if (defined(my $epoch = $ENV{FSMGEN_UNARY_CORPUS_CAPTURE})) {
    die 'invalid corpus capture epoch' unless $epoch =~ /\A[a-zA-Z0-9_-]{1,64}\z/;
    $capture_dir = ".artifacts/tmp/unary-corpus-$epoch";
    mkdir $capture_dir or die "exclusive corpus capture directory: $!";
}
my %source_bytes = map {$_->{relpath} => read_file($_->{relpath})} @catalog;
preserve('allocation', {catalog => \@catalog, cohort => $cohort, manifest => $manifest,
    queries => semantic_introspection_source_query_kinds(), vial_versions => vial_source_versions(),
    source_bytes => \%source_bytes});

subtest 'literal maintained ownership and complete source/version/query allocation' => sub {
    my @entries = grep {$_->{relpath} eq $source} @catalog;
    same(\@entries, [unary_reduction_catalog()], 'one complete independently literal owner');
    ok($row, 'maintained source occurs in the actual cohort');
    same($row->{catalog_entries}, [{id => 'feature.isf_unary_reductions',
        family => 'language_feature_fixture', coverage => 'isf_pipeline_cli', required_capabilities => [],
        supported_phases => unary_reduction_catalog()->{supported_phases},
        explicit_nonclaims => unary_reduction_catalog()->{explicit_nonclaims}}], 'phase/nonclaim arrays survive selection');
    my $queries = {fsm => [qw(check semantic)], vial => [qw(check semantic inspection)],
        map {$_ => [qw(check semantic schedule)]} qw(isf ppif axi apb ahb)};
    same(semantic_introspection_source_query_kinds(), $queries, 'complete literal published query families');
    my (%entries, @order);
    for my $entry (@catalog) {
        next unless $entry->{classification} eq 'supported_smoke';
        push @order, $entry->{relpath} unless exists $entries{$entry->{relpath}};
        push @{$entries{$entry->{relpath}}}, $entry;
    }
    same([map {$_->{source_id}} @$cohort], \@order, 'every supported source in exact first-occurrence order');
    for my $actual (@$cohort) {
        my $path = $actual->{source_id};
        my ($suffix) = $path =~ /\.([^.]+)\z/;
        my @owned = @{$entries{$path}};
        my %buckets = map {$_->{coverage} => 1} @owned;
        my %expectations;
        for my $key (qw(expected_module_name expected_top_name expected_semantic_source_root_kind)) {
            $expectations{$key} = $owned[0]{$key} if exists $owned[0]{$key};
        }
        same($actual, {source_id => $path, file_kind => $suffix, source_kind => $owned[0]{source_kind},
            language_version => $suffix eq 'vial' ? vial_source_versions()->{$path} : undef,
            strict => $suffix eq 'vial' ? JSON::PP::false : JSON::PP::true,
            query_kinds => $queries->{$suffix}, expectations => \%expectations,
            search_path_relpaths => $owned[0]{search_path_relpaths} // [], coverage_buckets => [sort keys %buckets],
            catalog_entries => [map {my $entry = $_; +{id => $entry->{id}, family => $entry->{family},
                coverage => $entry->{coverage}, map {$_ => $entry->{$_} // []}
                    qw(required_capabilities supported_phases explicit_nonclaims)}} @owned]},
            "complete allocation $path");
    }
};

subtest 'whole discovery native API and actual newline products' => sub {
    my $native = capture([$^X, 'bin/fsmgen', '--capability-manifest']);
    preserve('native-discovery', $native);
    terminal($native, 0, 'native full discovery');
    same($json->decode($native->{stdout}), $manifest, 'whole native/in-process manifest equality');
    my $all = rpc('manifest', 'tools/call', {name => 'fsmgen_capability_query', arguments => {section => 'all'}});
    same($all->{result}{structuredContent}, $manifest, 'whole API/newline manifest equals native discovery');
    my $tools = rpc('tools', 'tools/list', {});
    ok(@{$tools->{result}{tools}}, 'complete published tool schemas retained');
    my $discovery = rpc('unary-source', 'tools/call', {name => 'fsmgen_discover_sources',
        arguments => {query => 'feature.isf_unary_reductions', limit => 100}});
    my $payload = $discovery->{result}{structuredContent};
    is($payload->{matched_count}, 1, 'exact unary discovery match without truncation');
    is($payload->{returned_count}, 1, 'one maintained unary discovery product');
    same($payload->{sources}, [{source_id => $source, source_path => $source, relpath => $source,
        file_kind => 'isf', source_kind => 'isf', available_query_kinds => [qw(check semantic schedule)],
        support => {id => 'feature.isf_unary_reductions', family => 'language_feature_fixture',
            classification => 'supported_smoke', coverage => 'isf_pipeline_cli',
            strict_supported => JSON::PP::true, expected_module_name => 'unary_reductions',
            has_expected_error_pattern => JSON::PP::false, has_expected_hint_pattern => JSON::PP::false}}],
        'complete literal sanitized source discovery; internal phase arrays are not new public fields');
    my $contract = $manifest->{semantic_exports}{normalized_semantic_json}{source_optional_fields}{reductions};
    same($contract->{operator_values}, ['^', '&', '|'], 'literal discovery operators');
    same($contract->{source_forms}, ['(^ X)', '(& X)', '(| X)'], 'literal discovery source forms');
    same($manifest->{embedding}{isf_public_interface}{schedule_report_reductions}, $contract,
        'whole schedule/source reduction contract identity');
};

my %args;
for my $kind (qw(check semantic schedule)) {
    subtest "actual maintained $kind native API and newline products" => sub {
        my $result = run_source_query({repository_root => $root, row => $row, query_kind => $kind});
        preserve("source-$kind", $result);
        terminal($result->{$_}, 0, $_) for qw(native stdio);
        my $report = normalize_repository_paths($result->{native}{report}, $root);
        my $tool = $result->{adapter_result};
        same($tool->{structuredContent}{report}, $report, 'whole typed native/API report equality');
        same($json->decode($tool->{content}[0]{text}), $tool->{structuredContent}, 'whole text/structured equality');
        same($result->{stdio}{response}, {jsonrpc => '2.0', id => 1, result => $tool}, 'whole actual API/newline envelope equality');
        same(source_query_envelope_errors({row => $row, query_kind => $kind, result => $tool}), [], 'independent public envelope');
        $args{$kind} = {row => $row, query_kind => $kind, report => $report};
        same(source_query_semantic_errors($args{$kind}), [], 'independent literal declarations and reduction semantics');
        is($result->{source_sha256_after}, $result->{source_sha256_before}, 'source bytes preserved');
        same($result->{producer_sha256_after}, $result->{producer_sha256_before}, 'public producer bytes preserved');
    };
}

subtest 'invalid operand keeps complete public failure and schedule RPC contracts' => sub {
    my $work = tempdir(CLEANUP => 1);
    my $path = "$work/invalid-unary.isf";
    my $text = $source_bytes{$source};
    $text =~ s/\(\^ data\)/(^ missing_operand)/ or die 'maintained source reduction not found';
    open my $fh, '>:raw', $path or die $!;
    print {$fh} $text or die $!;
    close $fh or die $!;
    $path =~ s/^\Q$root\E\///;
    my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)],
        schedule => ['--emit-schedule-json']);
    my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
    for my $kind (qw(check semantic schedule)) {
        my $native = capture([$^X, 'bin/fsmgen', @{$flags{$kind}}, $path]);
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call',
            params => {name => $tools{$kind}, arguments => {source_id => $path}}};
        my $response = $api->handle_jsonrpc_request($request);
        my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
        preserve("failure-$kind", {source_id => $path, source_bytes => $text,
            native => $native, request => $request, response => $response, wire => $wire});
        is($native->{exit_code}, $kind eq 'schedule' ? 255 : 1, 'invalid declared operand retains native refusal status');
        is($native->{signal}, 0, 'native refusal has no signal');
        terminal($wire, 0, 'failure newline transport');
        same($json->decode($wire->{stdout}), $response, 'whole failure API/actual newline equality');
        if ($kind eq 'schedule') {
            is($native->{stdout}, '', 'failed schedule emits no partial product');
            like($native->{stderr}, qr/missing_operand/, 'native schedule preserves operand context');
            ok($response->{error} && !$response->{result}, 'schedule preserves RPC error boundary');
            is($response->{error}{code}, -32000, 'existing schedule adapter-error code');
        } else {
            is($native->{stderr}, '', 'failed machine report keeps stderr clean');
            my $report = normalize_repository_paths($json->decode($native->{stdout}), $root);
            same($response->{result}{structuredContent}{report}, $report, 'whole failed native/API report equality');
            same($json->decode($response->{result}{content}[0]{text}), $response->{result}{structuredContent},
                'whole failure text/structured equality');
            ok(!$report->{success} && $response->{result}{isError}, 'actual failure flags');
            like($report->{diagnostics}[0]{message}, qr/missing_operand/, 'primary diagnostic identifies invalid operand');
            ok(!exists($report->{source}{reductions}) && !exists($report->{source}{interface_ports}),
                'no successful source snapshots invented on failure');
        }
        is(read_file($path), $text, 'failed transports preserve exact input bytes');
    }
};

subtest 'shared transport corruption cannot satisfy independent authored witnesses' => sub {
    for my $kind (qw(check semantic schedule)) {
        for my $change (
            sub {delete $_[0]{reductions}}, sub {pop @{$_[0]{reductions}}},
            sub {$_[0]{reductions}[0]{operator} = '&'},
            sub {$_[0]{reductions}[0]{operand_width} = '8'},
            sub {$_[0]{reductions}[0]{result_width} = JSON::PP::true},
            sub {@{$_[0]{reductions}} = reverse @{$_[0]{reductions}}},
            sub {$_[0]{interface_ports}[1]{direction} = 'output'},
            sub {$_[0]{interface_ports}[1]{width} = '8'},
        ) {
            my $bad = dclone($args{$kind});
            $change->($kind eq 'schedule' ? $bad->{report} : $bad->{report}{source});
            my @shared = map {dclone($bad->{report})} 1..3;
            same($shared[0], $shared[1], 'corrupted native/API equality can pass');
            same($shared[1], $shared[2], 'corrupted API/newline equality can pass');
            my $before = $json->encode($bad);
            ok(@{source_query_semantic_errors($bad)}, 'literal oracle rejects shared loss/operator/order/role/JSON-kind corruption');
            is($json->encode($bad), $before, 'oracle preserves exact evidence');
        }
    }
};

same({map {$_ => read_file($_)} keys %source_bytes}, \%source_bytes, 'all catalog source bytes preserved');
done_testing;

sub same {is($json->encode($_[0]), $json->encode($_[1]), $_[2])}
sub read_file {open my $fh, '<:raw', $_[0] or die "read $_[0]: $!"; local $/; return <$fh>}
sub capture {FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '')}
sub terminal {
    my ($result, $exit, $label) = @_;
    is($result->{exit_code}, $exit, "$label expected exit");
    is($result->{signal}, 0, "$label no signal");
    is($result->{stderr}, '', "$label clean stderr");
}
sub preserve {
    return unless defined $capture_dir;
    sysopen my $fh, "$capture_dir/$_[0].json", O_WRONLY|O_CREAT|O_EXCL or die $!;
    print {$fh} $json->encode(capture_value($_[1]))."\n" or die $!;
    close $fh or die $!;
}
sub capture_value {
    my ($value) = @_;
    # Catalog diagnostic patterns are Perl regex objects, not JSON data.
    # Preserve their exact string form and type explicitly rather than
    # silently dropping them with allow_blessed.
    return {perl_regexp => "$value"} if ref($value) eq 'Regexp';
    return {map {$_ => capture_value($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    return [map {capture_value($_)} @$value] if ref($value) eq 'ARRAY';
    return $value;
}
sub rpc {
    my ($label, $method, $params) = @_;
    my $request = {jsonrpc => '2.0', id => 1, method => $method, params => $params};
    my $response = $api->handle_jsonrpc_request($request);
    my $wire = capture([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
    preserve($label, {request => $request, response => $response, wire => $wire});
    terminal($wire, 0, "$label newline");
    ok(!$response->{error} && !$response->{result}{isError}, "$label API succeeds");
    like($wire->{stdout}, qr/\A[^\n]+\n\z/, "$label one compact actual newline response");
    same($json->decode($wire->{stdout}), $response, "$label whole typed API/newline equality");
    same($json->decode($response->{result}{content}[0]{text}), $response->{result}{structuredContent},
        "$label whole text/structured equality") if $method eq 'tools/call';
    return $response;
}
