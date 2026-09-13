use strict;
use warnings;
BEGIN {
    *CORE::GLOBAL::fork = sub { die 'forbidden real fork during source qualification'; };
    *CORE::GLOBAL::system = sub { die 'forbidden real system during source qualification'; };
    *CORE::GLOBAL::exec = sub { die 'forbidden real exec during source qualification'; };
    *CORE::GLOBAL::kill = sub { die 'forbidden real signal during source qualification'; };
}
use FindBin;
use lib $FindBin::Bin;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Scalar::Util qw(refaddr);
use Test::More;
use CompilerProfile;

my $JSON = JSON::PP->new->canonical;
my $clone = sub { $JSON->decode($JSON->encode($_[0])) };
my $root = '/model/repository';
my $workspace = '.artifacts/tmp/process-supervisor-tests/fsmgen-CompilerProfile20260913_nonzero';
my $selection = {implementation => 'native', compiler => '/model/toolchain/clang', sdk => '/model/toolchain/sdk'};
my $request = NativeProxyCompilerProfile::expected_request($root, $workspace, $selection);
my $environment = NativeProxyCompilerProfile::expected_environment($root, $workspace, $selection);
my $result = {ok => 1, status => 'success', exit_code => 0, signal => 0,
              cleanup => {leader_started => 1, leader_reaped => 1, group_gone => 1}};
my $state = {phase => 'finished', pid => 73, leader_reaped => 1, leader_status => 0, result => $result};
my ($start_calls, $invoke_calls) = (0, 0);
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::_start_supervision = sub {
    ++$start_calls;
    is_deeply($_[0], $request, 'original start receives the unchanged request');
    return $state;
};
my $invoke = sub {
    ++$invoke_calls;
    is_deeply({@_}, $request, 'original facade receives the unchanged request');
    my $observed = FSM::Support::ProcessSupervisor::_start_supervision({@_});
    is(refaddr($observed), refaddr($state), 'observer returns the exact original state reference');
    return $result;
};
my ($returned, $receipt) = NativeProxyCompilerProfile::observe(
    $invoke, $request, $environment, $root, $workspace, $selection);
is(refaddr($returned), refaddr($result), 'original result reference is unchanged');
is($start_calls, 1, 'original start called once');
is($invoke_calls, 1, 'original facade called once');
ok($receipt->{settled}, 'terminal direct-child state and matching result are required');
is($receipt->{pid}, 73, 'direct child PID is retained as model data');
is($receipt->{native_wait_status}, 0, 'original raw wait status is retained');

for my $case (
    ['argument', sub { $_[0]{argv}[-1] .= '.changed' }],
    ['deadline', sub { $_[0]{bounds}{timeout_seconds}++ }],
    ['capture', sub { $_[0]{bounds}{capture_limit_bytes}++ }],
    ['schema', sub { $_[0]{schema} .= '.changed' }],
    ['unknown field', sub { $_[0]{unowned} = 1 }],
) {
    my $changed = $clone->($request); $case->[1]->($changed);
    my $error = eval { NativeProxyCompilerProfile::observe($invoke, $changed, $environment,
        $root, $workspace, $selection); 1 } ? '' : $@;
    like($error, qr/request differs/, "$case->[0] rejects before invocation");
}
my $changed = {%$environment, HOME => '/model/unowned'};
eval { NativeProxyCompilerProfile::observe($invoke, $request, $changed, $root, $workspace, $selection) };
like($@, qr/environment differs/, 'unexpected environment rejects before invocation');
eval { NativeProxyCompilerProfile::observe($invoke, $request, $environment, $root, $workspace . '_extra', $selection) };
like($@, qr/fixed profile domain/, 'another workspace rejects before invocation');
eval { NativeProxyCompilerProfile::observe($invoke, $request, $environment, $root, $workspace,
    {%$selection, implementation => 'perl'}) };
like($@, qr/not native/, 'fallback selection rejects before invocation');
is($invoke_calls, 1, 'all request controls made no further facade call');

for my $case (
    ['unreaped', sub { $_[0]{leader_reaped} = 0 }],
    ['missing wait', sub { $_[0]{leader_status} = undef }],
    ['contradictory wait', sub { $_[0]{leader_status} = 2304 }],
    ['live phase', sub { $_[0]{phase} = 'capture' }],
    ['missing child', sub { $_[0]{pid} = undef }],
    ['changed result', sub { $_[0]{result}{status} = 'changed' }],
) {
    my $changed = $clone->($state); $case->[1]->($changed);
    ok(!NativeProxyCompilerProfile::state_receipt($changed, $result)->{settled},
        "$case->[0] cannot grant cleanup");
}
my $unsettled = $clone->($result); $unsettled->{cleanup}{group_gone} = 0;
ok(!NativeProxyCompilerProfile::state_receipt({%$state, result => $unsettled}, $unsettled)->{settled},
   'an extant compiler group cannot grant cleanup');
ok(!NativeProxyCompilerProfile::state_receipt(undef, $result)->{settled}, 'missing original state cannot grant cleanup');
my $failed = {%$result, ok => 0, status => 'nonzero_exit', exit_code => 9};
ok(NativeProxyCompilerProfile::state_receipt({%$state, leader_status => 2304, result => $failed}, $failed)->{settled},
   'a failed compiler may be process-settled; this does not qualify successful preparation');
open(my $projection_file, '<', "$FindBin::Bin/projection-model.json") or die $!;
my $projection_fixture = do { local $/; $JSON->decode(<$projection_file>) };
close($projection_file) or die $!;
my $projection_input = {nodes => $projection_fixture->{nodes}};
my $projection_before = $JSON->encode($projection_input);
is(sha256_hex(JSON::PP->new->canonical->ascii->encode(
    NativeProxyCompilerProfile::metadata_projection($projection_input))),
    $projection_fixture->{projection_sha256}, 'Perl projection transport matches independently derived Python digest');
is($JSON->encode($projection_input), $projection_before, 'projection hashing preserves the original capture');
done_testing();
