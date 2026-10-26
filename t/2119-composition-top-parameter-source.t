use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Cwd qw(getcwd);
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::SourcePathResolver;
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Test::SourceQueryRunner qw(run_source_query normalize_repository_paths);

my $path = 't/corpus/composition_top_parameters_lowering_pending.fsm';
my $json = JSON::PP->new->canonical;
my %capture;
sub parse_and_resolve {
    my ($text) = @_;
    my $raw = Lispish::multi(\$text);
    my $before = $json->encode($raw);
    my $spec = FSM::Composition::Parser->new->parse_source($raw);
    my $pending = $spec->top->parameter_default_graph;
    FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
        fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
    is($json->encode($raw), $before, 'complete parsed caller stays unchanged');
    return ($spec, $pending);
}

subtest 'authored top blocks collect in order and resolve after real imports' => sub {
    open my $in, '<', $path or die $!;local $/;my $text = <$in>;close $in or die $!;
    my ($spec, $pending) = eval {parse_and_resolve($text)};
    ok($spec, 'actual top +params source parses and resolves') or do {diag($@);return};
    is($pending, undef, 'parser defers defaults until imports are available');
    my $top = $spec->top;my $graph = $top->parameter_default_graph;
    is_deeply($graph->{order}, [qw(BOUND WIDTH COPY LANE)], 'multiple authored blocks retain one declaration order');
    is_deeply({map {$_ => $graph->{parameters}{$_}{value_text}} @{$graph->{order}}},
        {BOUND => 16, WIDTH => 16, COPY => 4, LANE => "8'h3C"}, 'shared canonical scalar/static/aggregate defaults resolve');
    is_deeply($graph->{default_sources}{BOUND}{references}, [{parameter => 'WIDTH', token => 'WIDTH', suffix => ''}], 'alias records direct configurable identity');
    is_deeply($graph->{default_sources}{WIDTH}{expression}, ['shared.BASE'], 'package source expression remains authored');
    is($top->top_symbols->resolve_payload('WIDTH'), undef, 'parsed parameter never becomes a static constant');
    $capture{graph} = $json->decode($json->encode($graph));
    my $entries = $top->parameter_declarations;$entries->[0]{value_ast}[0] = 'WRONG';
    $graph->{default_sources}{BOUND}{expression}[0] = 'WRONG';
    is($top->parameter_declarations->[0]{value_ast}[0], 'WIDTH', 'authored declaration getter stays isolated');
    is($top->parameter_default_graph->{default_sources}{BOUND}{expression}[0], 'WIDTH', 'authored source getter stays isolated');
};

subtest 'malformed, conflicting and unresolved declaration graphs fail specifically' => sub {
    for my $case (
        ['empty', '(+params)', qr/non-empty list/],
        ['pair', '(+params A)', qr/pair/],
        ['missing value', '(+params (A))', qr/scalar or aggregate value/],
        ['identifier', '(+params (bad-name 8))', qr/HDL-identifier-compatible/],
        ['duplicate', '(+params (A 8)) (+params (A 16))', qr/at most once/],
        ['cycle', '(+params (A B) (B A))', qr/dependency cycles/],
        ['unknown', '(+params (A UNKNOWN))', qr/UNKNOWN/],
        ['constant root', '(+constants (A 8)) (+params (A 16))', qr/top parameter namespace is blocked.*static root/s],
        ['enum root', '(+enums (mode (IDLE 0))) (+params (mode 16))', qr/top parameter namespace is blocked.*static root/s],
        ['package root', '(+import shared) (+params (shared 16))', qr/top parameter namespace is blocked.*static root/s],
    ) {
        my ($name, $body, $expected) = @$case;
        my $ok = eval {parse_and_resolve("(?top:bad_parameters $body (?rtl:child))");1};my $error = $@;
        ok(!$ok, "$name refuses");like($error, $expected, "$name has the actual contract reason");
        $capture{refusals}{$name} = {ok => $ok ? 1 : 0, error => $error};
    }
};

subtest 'discovery and actual native/API/newline check expose unfinished lowering' => sub {
    my ($entry) = grep {$_->{relpath} eq $path} regression_corpus_entries();
    ok($entry, 'finite corpus owns the current lowering refusal');
    is($entry->{classification}, 'expected_failure', 'source is not advertised as supported HDL');
    my $manifest = build_capability_manifest();
    ok(grep(/composition top \+params.*symbolic lowering/, @{$manifest->{language_surface}{intentionally_blocked_or_not_yet_public}}), 'manifest exposes the precise current lowering boundary');
    my $r = run_source_query({repository_root => getcwd(), query_kind => 'check', row => {
        source_id => $path, query_kinds => ['check'], search_path_relpaths => [], strict => 1}});
    is($r->{native}{exit_code}, 1, 'native source check refuses');
    is($r->{stdio}{exit_code}, 0, 'newline protocol reports the source refusal normally');
    is($r->{stdio}{stderr}, '', 'newline protocol has clean stderr');
    ok(!$r->{native}{report}{success}, 'native report records source failure');
    is($r->{native}{report}{diagnostics}[0]{code}, 'FSMGEN_COMPOSITION_TOP_PARAMETER_LOWERING', 'classified diagnostic names pending lowering');
    like($r->{native}{report}{diagnostics}[0]{message}, qr/top parameter lowering is blocked because/, 'refusal reaches plan boundary after defaults');
    my $api = $r->{adapter_result};
    ok($api->{isError}, 'API keeps the expected source failure flag');
    is_deeply($api->{structuredContent}{report}, normalize_repository_paths($r->{native}{report}, getcwd()), 'complete native/API refusal equality');
    is_deeply($json->decode($api->{content}[0]{text}), $api->{structuredContent}, 'whole text/structured result equality');
    is_deeply($r->{stdio}{response}, {jsonrpc => '2.0', id => 1, result => $api}, 'complete actual newline/API equality');
    is($r->{source_sha256_after}, $r->{source_sha256_before}, 'public checks preserve source bytes');
    is_deeply($r->{producer_sha256_after}, $r->{producer_sha256_before}, 'public checks preserve selected producers');
    $capture{public} = normalize_repository_paths($r, getcwd());
};

if (my $out_path = $ENV{FSMGEN_TOP_SOURCE_CAPTURE}) {
    open my $out, '>', $out_path or die $!;print {$out} $json->encode(\%capture), "\n" or die $!;close $out or die $!;
}
done_testing();
