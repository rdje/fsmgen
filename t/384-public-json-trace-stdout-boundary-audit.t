#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json encode_json);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

my $bad_path = File::Spec->catfile($tempdir, 'trace_json_bad_infix.fsm');
write_file(
    $bad_path,
    <<'FSM'
(?fsm:trace_json_bad_infix
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (SRC 8)
    (OUT 8)
  )
  (idle
    (OUT = SRC)
  )
)
FSM
);

subtest 'capability manifest keeps stdout JSON-only when trace flags are present' => sub {
    my $trace_path = File::Spec->catfile($tempdir, 'manifest.trace.log');
    my $decoded = run_machine_json_command(
        label => 'capability manifest with trace flags',
        expect_success => 1,
        command => [
            './bin/fsmgen',
            '--debug=4',
            "--trace-log=$trace_path",
            '--capability-manifest',
        ],
    );

    is($decoded->{manifest_schema_version}, 1, 'capability manifest keeps schema version');
    ok($decoded->{manifest_contract}, 'capability manifest keeps manifest_contract payload');
};

subtest 'check JSON success keeps stdout JSON-only while traces go to the trace file' => sub {
    my $trace_path = File::Spec->catfile($tempdir, 'check-success.trace.log');
    my $out_path = File::Spec->catfile($tempdir, 'check-success.sv');
    my $decoded = run_machine_json_command(
        label => 'check JSON success with trace flags',
        expect_success => 1,
        trace_path => $trace_path,
        output_path => $out_path,
        command => [
            './bin/fsmgen',
            '--strict',
            '--trace-verbosity=debug',
            "--trace-log=$trace_path",
            '--notrace-emojis',
            '--check-json',
            '-o',
            $out_path,
            repo_file('fsm/apb_requester.fsm'),
        ],
    );

    is($decoded->{check_schema_version}, 1, 'check JSON success keeps schema version');
    ok($decoded->{success}, 'check JSON success reports success');
    is($decoded->{command}{mode}, 'check', 'check JSON success records check mode');
    ok($decoded->{command}{json}, 'check JSON success records JSON mode');
    ok(!$decoded->{generated_output}{emitted}, 'check JSON success records no HDL emission');
};

subtest 'check JSON failure keeps stdout JSON-only while traces go to the trace file' => sub {
    my $trace_path = File::Spec->catfile($tempdir, 'check-failure.trace.log');
    my $out_path = File::Spec->catfile($tempdir, 'check-failure.sv');
    my $decoded = run_machine_json_command(
        label => 'check JSON failure with trace flags',
        expect_success => 0,
        trace_path => $trace_path,
        output_path => $out_path,
        command => [
            './bin/fsmgen',
            '--strict',
            '--debug=4',
            "--trace-log=$trace_path",
            '--check-json',
            '-o',
            $out_path,
            $bad_path,
        ],
    );

    is($decoded->{check_schema_version}, 1, 'check JSON failure keeps schema version');
    ok(!$decoded->{success}, 'check JSON failure reports failure');
    is($decoded->{command}{mode}, 'check', 'check JSON failure records check mode');
    is($decoded->{diagnostics}[0]{code}, 'FSMGEN_STRICT_INFIX_ASSIGNMENT',
        'check JSON failure keeps stable diagnostic code');
    ok(!$decoded->{generated_output}{emitted}, 'check JSON failure records no HDL emission');
};

subtest 'semantic JSON success keeps stdout JSON-only while traces go to the trace file' => sub {
    my $trace_path = File::Spec->catfile($tempdir, 'semantic-success.trace.log');
    my $out_path = File::Spec->catfile($tempdir, 'semantic-success.sv');
    my $decoded = run_machine_json_command(
        label => 'semantic JSON success with trace flags',
        expect_success => 1,
        trace_path => $trace_path,
        output_path => $out_path,
        command => [
            './bin/fsmgen',
            '--strict',
            '--debug=4',
            "--trace-log=$trace_path",
            '--emit-semantic-json',
            '-o',
            $out_path,
            repo_file('fsm/apb_requester.fsm'),
        ],
    );

    is($decoded->{normalized_semantic_schema_version}, 1,
        'semantic JSON success keeps schema version');
    ok($decoded->{success}, 'semantic JSON success reports success');
    is($decoded->{command}{mode}, 'semantic_export',
        'semantic JSON success records semantic export mode');
    ok($decoded->{command}{json}, 'semantic JSON success records JSON mode');
    ok($decoded->{semantic}, 'semantic JSON success keeps semantic payload');
    ok(!$decoded->{generated_output}{emitted}, 'semantic JSON success records no HDL emission');
};

subtest 'semantic JSON failure keeps stdout JSON-only while traces go to the trace file' => sub {
    my $trace_path = File::Spec->catfile($tempdir, 'semantic-failure.trace.log');
    my $out_path = File::Spec->catfile($tempdir, 'semantic-failure.sv');
    my $decoded = run_machine_json_command(
        label => 'semantic JSON failure with trace flags',
        expect_success => 0,
        trace_path => $trace_path,
        output_path => $out_path,
        command => [
            './bin/fsmgen',
            '--strict',
            '--trace-verbosity=debug',
            "--trace-log=$trace_path",
            '--notrace-emojis',
            '--emit-semantic-json',
            '-o',
            $out_path,
            $bad_path,
        ],
    );

    is($decoded->{normalized_semantic_schema_version}, 1,
        'semantic JSON failure keeps schema version');
    ok(!$decoded->{success}, 'semantic JSON failure reports failure');
    is($decoded->{command}{mode}, 'semantic_export',
        'semantic JSON failure records semantic export mode');
    is($decoded->{diagnostics}[0]{code}, 'FSMGEN_STRICT_INFIX_ASSIGNMENT',
        'semantic JSON failure keeps stable diagnostic code');
    ok(!exists $decoded->{semantic}, 'semantic JSON failure omits partial semantic payload');
    ok(!$decoded->{generated_output}{emitted}, 'semantic JSON failure records no HDL emission');
};

done_testing();

sub run_machine_json_command {
    my (%args) = @_;

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => $args{command},
    );
    is($success ? 1 : 0, $args{expect_success} ? 1 : 0, "$args{label}: exit status");

    my $stdout = join('', @{$stdout_buf || []});
    my $stderr = join('', @{$stderr_buf || []});
    is($stderr, '', "$args{label}: stderr stays clean");
    unlike($stdout, qr/=== FSM HDL Generator ===|Trace logging enabled|Generated SystemVerilog Code|Code Generation Summary/,
        "$args{label}: stdout has no human banner or HDL text");

    my $decoded = eval { decode_json($stdout) };
    ok($decoded, "$args{label}: stdout is exactly decodable JSON")
        or do {
            diag($error_message || 'machine JSON command failed without an IPC error message');
            diag($stderr);
            diag($stdout);
            return {};
        };
    ok(strict_json_encode_ok($decoded), "$args{label}: decoded payload re-encodes as JSON");

    ok(!-e $args{output_path}, "$args{label}: no HDL output file is written")
        if defined $args{output_path};
    ok(-e $args{trace_path}, "$args{label}: trace file is created")
        if defined $args{trace_path};

    return $decoded;
}

sub strict_json_encode_ok {
    my ($value) = @_;
    return eval {
        encode_json($value);
        1;
    } ? 1 : 0;
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents;
    close $fh or die "Cannot close $path: $!";
}
