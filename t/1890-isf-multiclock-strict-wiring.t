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
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical->utf8;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my @cases;
for my $name (qw(clock_domain_event_crossing clock_domain_dual_event_crossing clock_domain_no_reset_event_crossing)) {
    open my $fh, '<', "isf/$name.isf" or die $!;
    my $text = do {local $/; <$fh>}; close $fh;
    # Use an already faithful reset carrier for syntax qualification. The
    # original synchronous active-low fixture behavior is owned by .32.1.3.2.
    $text =~ s/\(reset (\w+_n)\)/(reset ($1 async active_low))/g;
    push @cases, [$name, $text];
}
push @cases, ['activation_wiring', <<'ISF'];
(actor activation_wiring
  (clock-domains
    (domain core (clock clk) (reset (rst_n async active_low)) :default)
    (domain peripheral (clock bus_clk) (reset (bus_rst_n async active_low))))
  (crossings (activation worker (from core) (to peripheral)))
  (interface (input start (domain core)) (output done (domain core))
    (input work_ready (domain peripheral)) (output observed (domain peripheral)))
  (transaction parent (domain core) (on start) (do worker) (complete done))
  (transaction worker (domain peripheral) (await work_ready) (complete observed)))
ISF

for my $case (@cases) {
    my ($name, $text) = @$case;
    subtest "$name generated files and source queries are strict-admissible" => sub {
        my $path = "$work/$name.isf";
        write_file($path, $text);
        my $actor = FSM::Adapter::ISF->new->parse_file($path);
        my $lowered = FSM::Scheduler::ISF->new->lower($actor);
        my $dir = "$work/$name";
        mkdir $dir or die $!;
        write_file("$dir/$_", $lowered->{files}{$_}) for sort keys %{$lowered->{files}};
        for my $file (sort keys %{$lowered->{files}}) {
            my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', "$dir/$file"], '');
            is($r->{exit_code}, 0, "$file independently passes strict admission") or diag($r->{stdout});
            is($r->{stderr}, '', 'strict artifact check has no stderr');
        }
        my %hdl;
        for my $mode (qw(compat strict)) {
            my $output = "$dir/$mode.sv";
            my @flags = $mode eq 'strict' ? ('--strict') : ();
            my $r = $capture->([$^X, 'bin/fsmgen', @flags, '--quiet', '--output', $output, $path], '');
            is($r->{exit_code}, 0, "$mode emits complete HDL") or diag($r->{stderr});
            next unless -f $output;
            open my $fh, '<', $output or die $!;
            $hdl{$mode} = join '', grep { !m{^// Date: } } <$fh>; close $fh;
        }
        is($hdl{strict}, $hdl{compat}, 'strict and compatibility HDL match except date headers');
        my $relative = File::Spec->abs2rel($path, $root);
        for my $kind (qw(check semantic schedule)) {
            my %flags = (check => [qw(--strict --check --json)], semantic => ['--strict','--emit-semantic-json'], schedule => ['--emit-schedule-json']);
            my %tool = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
            my $r = $capture->([$^X, 'bin/fsmgen', @{$flags{$kind}}, $relative], '');
            is($r->{exit_code}, 0, "$kind native query succeeds");
            my $expected = $normalize->($json->decode($r->{stdout}), $root);
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tool{$kind}, arguments => {source_id => $relative}}};
            my $api = $adapter->handle_jsonrpc_request($request);
            ok(!$api->{result}{isError}, "$kind API query succeeds");
            is_deeply($api->{result}{structuredContent}{report}, $expected, 'entire native/API report agrees');
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, 'newline MCP process succeeds');
            is_deeply($json->decode($wire->{stdout}), $api, 'entire actual newline/API response agrees');
        }
    };
}

done_testing();
sub write_file {
    open my $fh, '>', $_[0] or die $!;
    print {$fh} $_[1] or die $!;
    close $fh or die $!;
}
