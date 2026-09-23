#!/usr/bin/env perl
use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
    # The supervisor's indirect-object exec syntax cannot be overridden by a
    # Perl subroutine. Its child-only exec is unreachable when fork is denied.
    *CORE::GLOBAL::kill = sub { ++$forbidden; die 'forbidden signal'; };
}
use FindBin;
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib",
    "$FindBin::Bin/../docs/audits/native-proxy-receipt-capture-20260923",
    "$FindBin::Bin/../docs/audits/native-proxy-receipt-admission-20260922",
    "$FindBin::Bin/../docs/audits/native-proxy-receipt-adapter-20260922",
    "$FindBin::Bin/../docs/audits/native-proxy-compiler-census-policy-admission-20260913";
use File::Basename qw(basename);
use File::Path qw(remove_tree);
use File::Temp ();
use JSON::PP ();
use Scalar::Util qw(refaddr);
use Test::More;
use Capture;

my $root = FSM::ProjectDataLocality::repository_root();
my $parent = FSM::ProjectDataLocality::ensure_project_artifact_dir(qw(tmp process-supervisor-tests));
my $revision = 'b' x 40;
my $json = JSON::PP->new->canonical;
my $workspace;

sub read_record {
    my ($path) = @_;
    open(my $fh, '<:raw', $path) or die "read $path: $!";
    my $bytes = do { local $/; <$fh> };
    close $fh or die $!;
    unlike($bytes, qr/\Q$root\E/, 'record contains no checkout-specific path');
    return $json->decode($bytes);
}

sub model_job {
    my ($request, $kind) = @_;
    my $cleanup = {leader_started => 1, leader_reaped => 1,
        group_gone => $kind eq 'unsettled' ? 0 : 1, containment => $request->{containment}};
    my $code = $kind eq 'compiler_failure' ? 9 : 0;
    my $job = {
        phase => 'finished', stage => 'compile_proxy', pid => 23,
        birth_sec => 1_700_000_023, birth_usec => 23,
        leader_reaped => 1, leader_status => $code << 8, cleanup => $cleanup,
        result => {ok => $code ? 0 : 1, status => $code ? 'nonzero_exit' : 'success',
            diagnostic => 'model first result', stderr => 'model stderr',
            signal => 0, exit_code => $code, cleanup => {%$cleanup}},
    };
    $job->{receipt_observation} = FSM::Support::ProcessSupervisor::_receipt_observation($job);
    $job->{receipt_observation}{cleanup} = {%$cleanup} if $kind eq 'copied_cleanup';
    $job->{result}{exit_code} = 1 if $kind eq 'wait_mismatch';
    unless ($code) {
        open(my $fh, '>:raw', $request->{argv}[-1]) or die $!;
        print {$fh} pack('V8', 0xfeedfacf, 0x0100000c, 0, 2, 0, 0, 0, 0) or die $!;
        close $fh or die $!;
    }
    return $job;
}

for my $kind (qw(success refused compiler_failure copied_cleanup unsettled wait_mismatch)) {
    subtest $kind => sub {
        my $holder = File::Temp->newdir('fsmgen-ReceiptModelXXXXXXXX', DIR => $parent, CLEANUP => 1);
        my $name = basename("$holder");
        $workspace = ".artifacts/tmp/process-supervisor-tests/${name}_compiler";
        my $out = "$holder/evidence";
        my ($calls, $grants) = (0, 0);
        no warnings 'redefine';
        local *NativeProxyReceiptCapture::_output_parts = sub {
            return ('tmp', 'process-supervisor-tests', $name, 'evidence');
        };
        local *NativeProxyReceiptCapture::_workspace_relative = sub { return $workspace; };
        local *FSM::Test::RustProxyFixture::_selection = sub {
            return {implementation => 'native', compiler => '/controlled/compiler', sdk => '/controlled/sdk'};
        };
        # Success exercises the real permit lifecycle once. Other cases isolate
        # capture/error behavior without resetting that module's spent permit.
        my $issue = \&NativeProxyReceiptAdmission::issue_permit;
        my $consume = \&NativeProxyReceiptAdmission::consume_permit;
        my $begin = \&NativeProxyReceiptAdmission::begin_compiler_capture;
        my $review = \&NativeProxyReceiptAdmission::execution_allowed;
        local *NativeProxyReceiptAdmission::issue_permit = sub {
            return $kind eq 'success' ? $issue->(@_) : {source_revision => $revision};
        };
        local *NativeProxyReceiptAdmission::consume_permit = sub {
            return $kind eq 'success' ? $consume->(@_) : 1;
        };
        local *NativeProxyReceiptAdmission::begin_compiler_capture = sub {
            ++$grants;
            ok(-f "$out/attempt.json", 'persistent attempt exists before a grant');
            return $kind eq 'success' ? $begin->(@_) : $kind ne 'refused';
        };
        local *NativeProxyReceiptAdmission::execution_allowed = sub {
            return $kind eq 'success' ? $review->(@_) : 1;
        };
        local *FSM::Test::ProcessSupervisor::sealed_supervise_process = sub {
            my %request = @_;
            ++$calls;
            is($grants, 1, 'grant precedes the supervisor call');
            ok(-f "$out/launch.json", 'launch request is durable before the call');
            is_deeply($request{environment}, {%ENV}, 'closed fixture environment crosses the sealed boundary');
            return model_job(\%request, $kind);
        };
        my $first;
        my $ok = eval { $first = NativeProxyReceiptCapture::run_capture($revision); 1 };
        my $error = $@;
        is($ok ? 1 : 0, $kind eq 'success' ? 1 : 0, 'only the valid modeled capture succeeds');
        like($error, qr/first compiler capture failed/, 'failure remains terminal') unless $ok;
        is($calls, $kind eq 'refused' ? 0 : 1, 'fixed compiler attempt count');
        is($grants, 1, 'no grant retry');
        my $attempt = read_record("$out/attempt.json");
        is($attempt->{workspace}, $workspace, 'workspace is recorded relative to root');
        is($attempt->{plan}{source_revision}, $revision, 'caller revision is retained');
        my $prepared = read_record("$out/preparation.json");
        is($prepared->{ok} ? 1 : 0, $ok ? 1 : 0, 'public preparation preserves the outcome');
        if ($calls) {
            my $launch = read_record("$out/launch.json");
            is($launch->{request}{cwd}, '.', 'recorded compiler cwd is repository-relative');
            my $saved = read_record("$out/first-state.json");
            is($saved->{private_state}{pid}, 23, 'first private identity is retained');
            is($saved->{result}{stderr}, 'model stderr', 'first diagnostic survives failures');
            is($saved->{review}{original_cleanup_shared}, $kind eq 'copied_cleanup' ? 0 : 1,
                'copied cleanup cannot acquire ownership');
            is($saved->{review}{raw_wait_matches}, $kind eq 'wait_mismatch' ? 0 : 1,
                'native wait and public result are checked independently');
        } else {
            ok(!-e "$out/first-state.json", 'refused launch fabricates no private state');
        }
        my $before = read_record("$out/attempt.json");
        my $replay = eval { NativeProxyReceiptCapture::run_capture($revision); 1 };
        ok(!$replay, 'persistent marker rejects a second invocation');
        like($@, qr/exclusively create capture record/, 'replay stops at the marker');
        is($grants, 1, 'replay never reaches admission');
        is_deeply(read_record("$out/attempt.json"), $before, 'replay leaves first evidence untouched');
        remove_tree("$root/$workspace");
        ok(!-e "$root/$workspace", 'exact modeled workspace removed');
    };
}
is($forbidden, 0, 'no compiler, probe, proxy or other process attempt');
done_testing;
