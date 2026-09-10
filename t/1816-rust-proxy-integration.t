#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use JSON::PP qw(decode_json encode_json);
use Test::More;
use lib 'perl', 't/lib';
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Test::ProjectDataLocality;

# Execute only the extracted construction/assertion/retirement control, with
# inert builder and process observations. No original test or compiler runs.
my $root = repository_root();
open my $source_fh, '<', 't/1669-task-acceptance-fixture-runtime.t' or die $!;
my $source = do { local $/; <$source_fh> };
close $source_fh or die $!;
my ($body) = $source =~ /(subtest 'Rust parity rejects unresolved.*?)(?=subtest 'legacy RAM-guard)/s;
my ($retire) = $source =~ /(sub retire_rust_proxy_workspace \{.*?)(?=sub capture_error)/s;
my ($writer) = $source =~ /(sub write_executable \{.*?)(?=sub slurp)/s;
die 'original integration boundaries are missing' unless $body && $retire && $writer;

{
    package RustProxyIntegrationModel;
    our ($root, $scenario, @assertions, @diagnostics, @preparations, @watchers, @workspaces,
         @prepared_results, @events);
    sub ok { push @assertions, [$_[0] ? 1 : 0, $_[1]]; return $_[0]; }
    sub is { return ok(defined($_[0]) && defined($_[1]) && $_[0] eq $_[1], $_[2]); }
    sub fail { return ok(0, $_[0]); }
    sub diag {
        push @diagnostics, @_;
        for my $message (@_) {
            next if ref($message) || $message !~ /^Rust proxy preparation: (.*)\z/s;
            my $receipt = eval { JSON::PP::decode_json($1) };
            my $mode = ref($receipt) eq 'HASH' ? $receipt->{mode} : 'invalid';
            push @events, ['receipt', $mode];
        }
    }
    sub explain { return @_; }
    sub subtest { $_[1]->(); }
    sub cleanup { return {leader_started => 1, leader_reaped => 1, group_gone => 1}; }
    sub prepare_rust_proxy {
        my ($workspace, $mode, @extra) = @_;
        die 'unexpected preparation arguments' if @extra || ref($workspace)
            || ($mode ne 'proxy_nonzero' && $mode ne 'proxy_decoy');
        push @preparations, [$workspace, $mode];
        push @workspaces, $workspace;
        push @events, ['prepare', $mode];
        my $result = {
            schema => 'fsmgen.test.rust_proxy_fixture.v1', ok => 0,
            status => 'timed_out', failure_stage => 'compile',
            diagnostic => "controlled preparation failure\n",
            implementation => $scenario eq 'perl' ? 'perl' : 'native',
            selection_reason => 'controlled_selection',
            executable => undef, sources => [], compilation => undef,
            compilation_argv => undef,
        };
        if ($scenario eq 'prepare_failure') {
            push @prepared_results, {mode => $mode, prepared => {%$result}};
            return $result;
        }
        my $bin = "$workspace/rust-tools";
        mkdir($bin, 0700) or die $!;
        open my $fh, '>', "$bin/rustup" or die $!;
        print {$fh} "inert $mode fixture\n" or die $!;
        close $fh or die $!;
        chmod 0500, "$bin/rustup" or die $!;
        $result->{ok} = 1;
        $result->{status} = 'success';
        $result->{failure_stage} = undef;
        $result->{diagnostic} = 'controlled fixture prepared';
        $result->{executable} = File::Spec->abs2rel("$bin/rustup", $root);
        # Opaque test identities exercise lossless transfer, not native custody.
        $result->{sources} = [{path => $result->{executable}, device => 7, inode => 11,
                              size_bytes => 23, sha256 => 'a' x 64}];
        if ($scenario ne 'perl') {
            $result->{compilation} = {ok => 1, status => 'success', cleanup => cleanup()};
            $result->{compilation_argv} = ['controlled-clang', '-o', $result->{executable}];
            $result->{compilation}{cleanup}{group_gone} = 0 if $scenario eq 'compiler_group';
        }
        push @prepared_results, JSON::PP::decode_json(JSON::PP::encode_json({mode => $mode, prepared => $result}));
        return $result;
    }
    sub supervise_process {
        my %args = @_;
        my ($perl, $include, $test_include, $probe, $bin) = @{$args{argv}};
        die 'changed wrapper argv' unless @{$args{argv}} == 5
            && $perl eq Cwd::abs_path($^X) && $include eq '-Iperl' && $test_include eq '-It/lib'
            && $probe eq File::Basename::dirname($bin) . '/rust-tool-resolution';
        die 'changed wrapper policy' unless $args{cwd} eq $root
            && $args{bounds}{timeout_seconds} == 20 && $args{bounds}{capture_limit_bytes} == 65_536
            && $args{schema} eq 'fsmgen.test.rust_tool_resolution_probe.v1'
            && $args{stage} eq 'probe' && $args{containment} eq 'rust_tool_resolution_probe_group';
        my $mode = -d "$bin/cargo" ? 'directory' : $preparations[-1][1];
        die 'proxy canonical identity changed' if $mode ne 'directory'
            && (!-l "$bin/cargo" || Cwd::abs_path("$bin/cargo") ne "$bin/rustup");
        push @watchers, [$mode, \%args];
        push @events, ['watcher', $mode];
        push @workspaces, File::Basename::dirname($bin);
        my $cleanup = cleanup();
        $cleanup->{leader_started} = 0 if $mode eq 'directory';
        $cleanup->{leader_reaped} = 0 if $mode eq 'directory';
        my $status = $mode eq 'proxy_nonzero' ? 'nonzero_exit' : 'invocation_error';
        my $stage = $mode eq 'proxy_decoy' ? 'tool_admission' : 'tool_resolution';
        my $result = {ok => 0, status => $status, failure_stage => $stage,
                      stages => [{stage => $stage, cleanup => $cleanup}]};
        my $outer = {ok => 1, cleanup => cleanup()};
        if ($mode ne 'directory') {
            $cleanup->{group_gone} = 0 if $scenario eq 'inner_group';
            $cleanup->{leader_reaped} = 0 if $scenario eq 'inner_unreaped';
            delete $cleanup->{leader_started} if $scenario eq 'missing_cleanup';
            $cleanup->{leader_started} = undef if $scenario eq 'undefined_cleanup';
            $cleanup->{group_gone} = 'unknown' if $scenario eq 'nonboolean_cleanup';
            $outer->{cleanup}{group_gone} = 0 if $scenario eq 'outer_group';
            $result->{stages} = [] if $scenario eq 'empty_stages';
            $result->{status} = 'success' if $scenario eq 'wrong_status';
            push @{$result->{stages}}, {stage => 'cargo_build', cleanup => cleanup()}
                if $scenario eq 'unexpected_build';
        }
        $outer->{stdout} = $scenario eq 'bad_json' && $mode ne 'directory'
            ? '{broken' : JSON::PP::encode_json($result);
        return $outer;
    }
}

my $case = 0;
for my $scenario (qw(native perl prepare_failure compiler_group inner_group inner_unreaped
                     missing_cleanup undefined_cleanup nonboolean_cleanup outer_group
                     empty_stages bad_json wrong_status unexpected_build)) {
    subtest $scenario => sub {
        $RustProxyIntegrationModel::root = $root;
        $RustProxyIntegrationModel::scenario = $scenario;
        @RustProxyIntegrationModel::assertions = ();
        @RustProxyIntegrationModel::diagnostics = ();
        @RustProxyIntegrationModel::preparations = ();
        @RustProxyIntegrationModel::watchers = ();
        @RustProxyIntegrationModel::workspaces = ();
        @RustProxyIntegrationModel::prepared_results = ();
        @RustProxyIntegrationModel::events = ();
        my $package = 'RustProxyIntegrationCase' . ++$case;
        my $aliases = join "\n", map { "*$_ = \\&RustProxyIntegrationModel::$_;" }
            qw(ok is fail diag explain subtest prepare_rust_proxy supervise_process);
        my $program = "package $package; BEGIN { $aliases }\n" . <<'PRELUDE';
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp ();
use JSON::PP qw(decode_json);
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir);
my $repo_root = $RustProxyIntegrationModel::root;
my $perl = abs_path($^X);
PRELUDE
        my $finished = eval "$program\n$body\n$retire\n$writer\n1;";
        my $error = $@;
        my %workspaces = map { $_ => 1 } @RustProxyIntegrationModel::workspaces;
        my @retained = grep { -d $_ } keys %workspaces;
        # These paths had only inert observations; this control owns their cleanup.
        remove_tree($_) for @retained;
        ok($finished, 'isolated original control executes') or diag $error;
        my @failed = grep { !$_->[0] } @RustProxyIntegrationModel::assertions;
        my $success = $scenario eq 'native' || $scenario eq 'perl';
        is(scalar(@failed) == 0 ? 1 : 0, $success ? 1 : 0, 'independent outcome distinguishes hostile inputs');
        my $retains = !$success && $scenario ne 'wrong_status' && $scenario ne 'unexpected_build';
        is(scalar(@retained), $retains ? 1 : 0, 'only unproved lifecycle retains its mode workspace');
        is(scalar(@RustProxyIntegrationModel::preparations), $retains ? 1 : 2,
            'each attempted proxy mode is prepared once without fallback or retry');
        is(scalar(@RustProxyIntegrationModel::watchers), $scenario eq 'prepare_failure' ? 1 : $retains ? 2 : 3,
            'preparation failure cannot launch its wrapper or advance to another mode');
        my @receipts = map { /^Rust proxy preparation: (.*)\z/s ? $1 : () }
            grep { !ref($_) } @RustProxyIntegrationModel::diagnostics;
        my @expected_receipts = map { JSON::PP->new->ascii->canonical->encode($_) }
            @RustProxyIntegrationModel::prepared_results;
        is_deeply(\@receipts, \@expected_receipts,
            'every preparation retains its complete canonical mode-linked receipt');
        my @expected_events = (['watcher', 'directory']);
        for my $mode ($retains ? ('proxy_nonzero') : qw(proxy_nonzero proxy_decoy)) {
            push @expected_events, ['prepare', $mode], ['receipt', $mode];
            push @expected_events, ['watcher', $mode] unless $scenario eq 'prepare_failure';
        }
        is_deeply(\@RustProxyIntegrationModel::events, \@expected_events,
            'receipt follows preparation and precedes any wrapper launch');
        ok(!grep(-e $_, keys %workspaces), 'controlled fixture cleanup leaves no workspace');
    };
}
done_testing();
