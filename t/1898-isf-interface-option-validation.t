#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);

my @cases = (
    ['unknown', '(bogus-clause xyz)', qr/unsupported 'bogus-clause' option/],
    ['presence', '(present PROT_Present)', qr/unsupported 'present' option/],
    ['scalar', 'unexpected', qr/option must be a non-empty list/],
    ['empty', '()', qr/option must be a non-empty list/],
    ['nested', '((width) 8)', qr/option name must be a non-empty scalar/],
    ['width_arity', '(width 8 extra)', qr/width must be a positive integer/],
    ['width_shape', '(width (8))', qr/width must be a positive integer/],
    ['type_arity', '(type)', qr/type requires/],
    ['domain_arity', '(domain)', qr/domain/],
    ['duplicate', '(width 8) (width 9)', qr/duplicate 'width' option/],
    ['reset_arity', '(reset)', qr/reset requires/],
    ['default_shape', '(default (0))', qr/default requires/],
    ['input_reset', '(reset 0)', qr/cannot specify output 'reset' metadata/, 'input'],
);

for my $case (@cases) {
    my ($label, $options, $diagnostic, $direction) = @$case;
    $direction //= 'output';
    my $source = source("($direction data $options)");
    subtest "$label fails at the shared public parser" => sub {
        my $actor = eval { FSM::Adapter::ISF->new->parse_source($source, "$label.isf") };
        ok(!$actor, 'no partial actor escapes');
        like($@, $diagnostic, 'specific option diagnostic');
        like($@, qr/(?:port|input|output) 'data'/, 'diagnostic identifies the port');
    };
    # The newly rejected shapes traverse every actual public query surface.
    next unless $label =~ /\A(?:unknown|presence|scalar|empty|nested)\z/;
    my $path = write_source($label, $source);
    subtest "$label is refused by native, API and newline MCP" => sub {
        for my $kind (qw(check semantic schedule)) {
            my %flags = (check => [qw(--check --json)], semantic => ['--emit-semantic-json'], schedule => ['--emit-schedule-json']);
            my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
            my $strict_run;
            for my $strict (0, 1) {
                my $run = $capture->([$^X, 'bin/fsmgen', ($strict ? '--strict' : ()), @{$flags{$kind}}, $path], '');
                isnt($run->{exit_code}, 0, "$kind strict=$strict rejects source");
                like($run->{stdout} . $run->{stderr}, $diagnostic, "$kind strict=$strict retains reason");
                $strict_run = $run if $strict;
            }
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tools{$kind}, arguments => {source_id => $path}}};
            my $response = $api->handle_jsonrpc_request($request);
            ok($response->{error} || $response->{result}{isError}, "$kind API refuses source");
            if ($kind eq 'schedule') {
                is_deeply($response->{error}, {code => -32000,
                    message => 'FSMGen command failed without a matching public failure report'},
                    'schedule retains the documented message-only failure boundary');
            } else {
                like($json->encode($response), $diagnostic, "$kind API retains reason");
                is_deeply($response->{result}{structuredContent}{report},
                    $normalize->($json->decode($strict_run->{stdout}), $root),
                    "$kind complete native failure report survives API projection");
            }
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, "$kind transport completes");
            is_deeply($json->decode($wire->{stdout}), $response, "$kind complete newline/API responses agree");
            unlike($wire->{stdout}, qr/\Q$root\E/, "$kind does not leak repository root");
        }
    };
}

subtest 'supported options retain their independently specified values and reports' => sub {
    my $text = source('(output data (width 8) (reset 3) (default 5))');
    my $actor = FSM::Adapter::ISF->new->parse_source($text, 'valid.isf');
    my ($data) = grep { $_->{name} eq 'data' } @{$actor->{interface}{outputs}};
    is_deeply($data, {name => 'data', width => 8, reset_value => 3, default_value => 5}, 'supported metadata is not dropped or changed');
    my $path = write_source('valid', $text);
    for my $kind (qw(check semantic schedule)) {
        my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
        my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
        my $run = $capture->([$^X, 'bin/fsmgen', @{$flags{$kind}}, $path], '');
        is($run->{exit_code}, 0, "$kind valid native control succeeds") or diag($run->{stdout}, $run->{stderr});
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tools{$kind}, arguments => {source_id => $path}}};
        my $response = $api->handle_jsonrpc_request($request);
        ok(!$response->{error} && !$response->{result}{isError}, "$kind API valid control succeeds");
        is_deeply($response->{result}{structuredContent}{report}, $normalize->($json->decode($run->{stdout}), $root), "$kind native/API reports agree");
        my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
        is_deeply($json->decode($wire->{stdout}), $response, "$kind valid newline/API responses agree");
    }
};

sub source {
    my ($port) = @_;
    return "(actor port_options (clock clk) (reset rst_n)\n (interface (input start) (output done) $port)\n (transaction work (on start) (complete done)))\n";
}
sub write_source {
    my ($name, $text) = @_;
    my $path = "$work/$name.isf";
    open my $fh, '>', $path or die $!;
    print {$fh} $text;
    close $fh or die $!;
    return File::Spec->abs2rel($path, $root);
}
done_testing();
