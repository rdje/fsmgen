#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);
my $rhs_fixture_path = File::Spec->catfile(
    $repo_root,
    't',
    'corpus',
    'assignment_d_input_self_dependency.fsm',
);
my $guard_fixture_path = File::Spec->catfile($tempdir, 'd_input_guard_self_dependency.fsm');

write_file(
    $guard_fixture_path,
    <<'FSM'
(?fsm:d_input_guard_self_dependency
  (+system
    (clock clk)
    (sreset rstn)
  )
  (idle
    (A <= B <A)
  )
  (+size
    (A 8)
    (B 8)
  )
)
FSM
);

for my $case (
    {
        label => 'RHS expression',
        path => $rhs_fixture_path,
        role_pattern => qr/RHS expression/s,
        operator_pattern => qr/using '<='/s,
    },
    {
        label => 'guard expression',
        path => $guard_fixture_path,
        role_pattern => qr/guard condition/s,
        operator_pattern => qr/using '<='/s,
    },
) {
    subtest "$case->{label} quiet CLI D-input self-dependency failures are stack-free" => sub {
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--quiet', $case->{path}],
        );

        ok(!$success, "quiet CLI rejects $case->{label} D-input self-dependency");

        my $combined_output = combined_output($error_message, $stdout_buf, $stderr_buf);
        assert_d_input_self_dependency_diagnostic($combined_output, "quiet CLI $case->{label}", $case);
        unlike($combined_output, qr/=== FSM HDL Generator ===/s, "quiet CLI $case->{label} does not print the interactive banner");
        unlike($combined_output, qr/Processing FSM file:/s, "quiet CLI $case->{label} does not print the processing line");
    };

    subtest "$case->{label} check JSON D-input self-dependency failures are stack-free" => sub {
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--check-json', $case->{path}],
        );

        ok(!$success, "check JSON rejects $case->{label} D-input self-dependency");
        is(join('', @{$stderr_buf || []}), '', "check JSON $case->{label} failure stays on stdout only");

        my $decoded = decode_json(join('', @{$stdout_buf || []}));
        ok(!$decoded->{success}, "check JSON $case->{label} report marks failure");
        is($decoded->{source}{resolved_path}, File::Spec->rel2abs($case->{path}), "check JSON $case->{label} records the resolved source path");
        is(scalar(@{$decoded->{diagnostics}}), 1, "check JSON $case->{label} carries one diagnostic");

        my $diagnostic = $decoded->{diagnostics}[0];
        is($diagnostic->{code}, 'FSMGEN_LANGUAGE_D_INPUT_SELF_DEPENDENCY', "check JSON $case->{label} keeps the stable diagnostic code");
        assert_d_input_self_dependency_diagnostic($diagnostic->{message}, "check JSON $case->{label} diagnostic", $case);
    };

    subtest "$case->{label} normalized semantic JSON D-input self-dependency failures are stack-free" => sub {
        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--emit-semantic-json', $case->{path}],
        );

        ok(!$success, "semantic JSON rejects $case->{label} D-input self-dependency");
        is(join('', @{$stderr_buf || []}), '', "semantic JSON $case->{label} failure stays on stdout only");

        my $decoded = decode_json(join('', @{$stdout_buf || []}));
        ok(!$decoded->{success}, "semantic JSON $case->{label} report marks failure");
        is($decoded->{source}{resolved_path}, File::Spec->rel2abs($case->{path}), "semantic JSON $case->{label} records the resolved source path");
        is(scalar(@{$decoded->{diagnostics}}), 1, "semantic JSON $case->{label} carries one diagnostic");

        my $diagnostic = $decoded->{diagnostics}[0];
        is($diagnostic->{code}, 'FSMGEN_LANGUAGE_D_INPUT_SELF_DEPENDENCY', "semantic JSON $case->{label} keeps the stable diagnostic code");
        assert_d_input_self_dependency_diagnostic($diagnostic->{message}, "semantic JSON $case->{label} diagnostic", $case);
    };
}

done_testing();

sub assert_d_input_self_dependency_diagnostic {
    my ($message, $label, $case) = @_;
    my $source_basename = (File::Spec->splitpath($case->{path}))[2];

    like($message, qr/Source file:\s+'.*\Q$source_basename\E'/s, "$label keeps source file context");
    like($message, qr/Illegal D-input self-dependency/s, "$label explains the rejected assignment family");
    like($message, $case->{operator_pattern}, "$label shows the rejected operator");
    like($message, $case->{role_pattern}, "$label identifies the offending expression role");
    like($message, qr/references 'A'.*same D-input-named LHS/s, "$label identifies the self-dependent signal");
    like($message, qr/use '<-' for Q\/output-named synchronous feedback/s, "$label gives the Q/output remediation");
    like($message, qr/read the generated '<signal>_r' Q mirror/s, "$label gives the D-input mirror remediation");
    unlike($message, qr/\bcalled at\b/s, "$label does not expose Perl call-stack frames");
    unlike($message, qr/Parser\.pm/s, "$label does not expose parser implementation filenames");
    unlike($message, qr/validate_no_register_input_self_dependency/s, "$label does not expose parser routine names");
}

sub combined_output {
    my ($error_message, $stdout_buf, $stderr_buf) = @_;
    return join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
