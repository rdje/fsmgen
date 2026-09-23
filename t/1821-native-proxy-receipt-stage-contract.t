#!/usr/bin/env perl
use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
    *CORE::GLOBAL::kill = sub { ++$forbidden; die 'forbidden signal'; };
}
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../perl";
use lib "$FindBin::Bin/../docs/audits/native-proxy-receipt-admission-20260922";
use Test::More;
use Admission;

# Loading the runtime resolves tools but launches none. Do not consult a
# caller's toolchain paths; the request below is intercepted before execution.
{
    local $ENV{PATH} = '/usr/bin:/bin';
    require FSM::Test::RustParityRuntime;
}
my (@requests, $result);
my $sentinel = {ok => 0, status => 'nonzero_exit'};
my $argv = ['unused-rustup', 'which', 'cargo'];
{
    no warnings qw(redefine once);
    local *FSM::Test::RustParityRuntime::supervise_process = sub {
        push @requests, {@_};
        return $sentinel;
    };
    $result = FSM::Test::RustParityRuntime::_run('tool_resolution', $argv);
}
is(scalar @requests, 1, 'the real stage producer makes one intercepted request');
is($result, $sentinel, 'the producer returns the supervisor result unchanged');
is_deeply($requests[0]{argv}, $argv, 'tool-resolution arguments are preserved');
is($requests[0]{containment}, 'rust_parity_process_group',
    'the runtime owns the inner stage under the Rust parity policy');
is_deeply($requests[0]{bounds}, {timeout_seconds => 10, capture_limit_bytes => 1_048_576},
    'the runtime retains its existing inner-stage bounds');

my $roles = NativeProxyReceiptAdmission::required_roles();
is_deeply($roles, [
    {role => 'compiler', stage => 'compile_proxy', containment => 'rust_proxy_compiler_group'},
    {role => 'outer', stage => 'probe', containment => 'rust_tool_resolution_probe_group'},
    {role => 'inner', stage => 'tool_resolution', containment => $requests[0]{containment}},
], 'admission agrees with the actual inner producer and existing surrounding stages');
my $plan = {
    source_revision => 'b' x 40, execution => 'closed', permit => 'unissued',
    sealed_return => NativeProxyReceiptAdmission::sealed_return_name(),
    roles => $roles, private_fields => NativeProxyReceiptAdmission::required_private_fields(),
    replay_original => 0, replay_proxy => 0, live_collector => 0,
};
ok(NativeProxyReceiptAdmission::admitted($plan), 'the matching plan is admitted');
my $token = NativeProxyReceiptAdmission::issue_permit($plan);
ok($token, 'the matching plan issues its compiler-only permit');
ok(NativeProxyReceiptAdmission::consume_permit($plan, $token), 'the permit is consumed');

# Mutate each independent field from a fresh valid plan. In particular, the
# former inner policy must not silently regain prelaunch authority.
for my $index (0 .. 2) {
    for my $field (qw(role stage containment)) {
        my $bad = {%$plan, roles => [map { {%$_} } @$roles]};
        $bad->{roles}[$index]{$field} = $index == 2 && $field eq 'containment'
            ? 'rust_tool_resolution_probe_group' : 'substituted';
        ok(!NativeProxyReceiptAdmission::admitted($bad), "changed role $index $field rejects");
        ok(!NativeProxyReceiptAdmission::begin_compiler_capture($bad, $token),
            "changed role $index $field cannot grant a launch");
    }
}
ok(NativeProxyReceiptAdmission::begin_compiler_capture($plan, $token),
    'rejected plans leave the sole matching compiler grant available');
ok(!NativeProxyReceiptAdmission::begin_compiler_capture($plan, $token),
    'the compiler grant remains single-use');
is($forbidden, 0, 'no process or signal attempt');
done_testing;
