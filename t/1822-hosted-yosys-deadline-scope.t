#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use FSM::Test::HostedYosysDeadline qw(hosted_yosys_deadline_skip);

# GitHub documents GITHUB_ACTIONS=true for Actions steps. A generic CI marker
# or an ordinary local invocation is not that environment. Evaluate each call
# against a fresh environment so import-time state cannot hide a regression.
my @cases = (
    ['ordinary local invocation', {}, 0],
    ['generic CI', {CI => 'true'}, 0],
    ['Actions false', {GITHUB_ACTIONS => 'false'}, 0],
    ['Actions empty', {GITHUB_ACTIONS => ''}, 0],
    ['Actions numeric lookalike', {GITHUB_ACTIONS => '1'}, 0],
    ['Actions uppercase lookalike', {GITHUB_ACTIONS => 'TRUE'}, 0],
    ['GitHub Actions', {GITHUB_ACTIONS => 'true'}, 1],
    ['explicit hosted deadline check', {GITHUB_ACTIONS => 'true', FSMGEN_HOSTED_YOSYS_DEADLINE_CHECK => '1'}, 0],
    ['hosted override disabled', {GITHUB_ACTIONS => 'true', FSMGEN_HOSTED_YOSYS_DEADLINE_CHECK => '0'}, 1],
    ['hosted override lookalike', {GITHUB_ACTIONS => 'true', FSMGEN_HOSTED_YOSYS_DEADLINE_CHECK => 'true'}, 1],
    ['explicit local deadline check', {FSMGEN_HOSTED_YOSYS_DEADLINE_CHECK => '1'}, 0],
    ['local override disabled', {FSMGEN_HOSTED_YOSYS_DEADLINE_CHECK => '0'}, 0],
);
for my $case (@cases) {
    my ($name, $environment, $skip) = @$case;
    local %ENV = %$environment;
    my $reason = hosted_yosys_deadline_skip();
    is(defined($reason) ? 1 : 0, $skip, "$name selects the declared scope");
    like($reason, qr/hosted Yosys synthesis deadline.*120 seconds/,
        "$name preserves the recorded bounded limitation") if $skip;
}

# Exercise the real alias helper bodies with inert command execution. Merely
# checking the policy function misses Perl list-operator precedence at callers
# and Test::More's requirement that skip runs inside a SKIP block.
for my $id (1524, 1526, 1534, 1538, 1540) {
    my @files = glob "$FindBin::Bin/$id-*.t";
    die "expected one alias test for $id" unless @files == 1;
    open my $fh, '<', $files[0] or die $!;
    my $source = do { local $/; <$fh> };
    close $fh or die $!;
    my ($body) = $source =~ /(sub run_command_ok \{.*?)(?=\nsub |\z)/s;
    die "missing command helper in $id" unless defined $body;
    my $package = "HostedDeadlineAlias$id";
    my $loaded = eval "package $package; use strict; use warnings; use Test::More; "
        . 'use FSM::Test::HostedYosysDeadline qw(hosted_yosys_deadline_skip); '
        . 'our $runs = 0; sub run { ++$runs; return (1, undef, undef, [], []); } '
        . "$body\n1;";
    ok($loaded, "$id actual command helper loads with inert execution") or diag $@;
    next unless $loaded;
    my $call = $package->can('run_command_ok');
    for my $case (
        ['local verification', {}, '--verify-hdl', 1],
        ['hosted verification', {GITHUB_ACTIONS => 'true'}, '--verify-hdl', 0],
        ['hosted ordinary command', {GITHUB_ACTIONS => 'true'}, '--check', 1],
        ['forced hosted verification', {GITHUB_ACTIONS => 'true', FSMGEN_HOSTED_YOSYS_DEADLINE_CHECK => '1'}, '--verify-hdl', 1],
    ) {
        my ($name, $environment, $option, $expected_runs) = @$case;
        subtest "$id $name" => sub {
            local %ENV = %$environment;
            no strict 'refs';
            local ${"${package}::runs"} = 0;
            my $before = Test::More->builder->current_test;
            my $finished = eval { $call->(['./bin/fsmgen', $option, 'fixture.ahb'], 'controlled command'); 1 };
            my $error = $@;
            my $emitted = Test::More->builder->current_test - $before;
            ok($finished, 'the helper returns without invalid skip control flow') or diag $error;
            is(${"${package}::runs"}, $expected_runs, 'command dispatch matches policy');
            is($emitted, 2, 'the helper accounts for both TAP checks');
        };
    }
}
done_testing;
