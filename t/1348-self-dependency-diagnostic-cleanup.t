#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $fixture_path = File::Spec->catfile(
    $repo_root,
    't',
    'corpus',
    'assignment_comb_self_dependency.fsm',
);
my $resolved_fixture_path = File::Spec->rel2abs($fixture_path);

subtest 'quiet CLI combinational self-dependency failures are stack-free' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', $fixture_path],
    );

    ok(!$success, 'quiet CLI rejects the illegal combinational self-dependency');

    my $combined_output = combined_output($error_message, $stdout_buf, $stderr_buf);
    assert_comb_self_dependency_diagnostic($combined_output, 'quiet CLI');
    unlike($combined_output, qr/=== FSM HDL Generator ===/s, 'quiet CLI does not print the interactive banner');
    unlike($combined_output, qr/Processing FSM file:/s, 'quiet CLI does not print the processing line');
};

subtest 'check JSON combinational self-dependency failures are stack-free' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--check-json', $fixture_path],
    );

    ok(!$success, 'check JSON rejects the illegal combinational self-dependency');
    is(join('', @{$stderr_buf || []}), '', 'check JSON failure stays on stdout only');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    ok(!$decoded->{success}, 'check JSON report marks failure');
    is($decoded->{source}{resolved_path}, $resolved_fixture_path, 'check JSON records the resolved source path');
    is(scalar(@{$decoded->{diagnostics}}), 1, 'check JSON carries one diagnostic');

    my $diagnostic = $decoded->{diagnostics}[0];
    is($diagnostic->{code}, 'FSMGEN_LANGUAGE_COMBINATIONAL_SELF_DEPENDENCY', 'check JSON keeps the stable diagnostic code');
    assert_comb_self_dependency_diagnostic($diagnostic->{message}, 'check JSON diagnostic');
};

subtest 'normalized semantic JSON combinational self-dependency failures are stack-free' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-semantic-json', $fixture_path],
    );

    ok(!$success, 'semantic JSON rejects the illegal combinational self-dependency');
    is(join('', @{$stderr_buf || []}), '', 'semantic JSON failure stays on stdout only');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    ok(!$decoded->{success}, 'semantic JSON report marks failure');
    is($decoded->{source}{resolved_path}, $resolved_fixture_path, 'semantic JSON records the resolved source path');
    is(scalar(@{$decoded->{diagnostics}}), 1, 'semantic JSON carries one diagnostic');

    my $diagnostic = $decoded->{diagnostics}[0];
    is($diagnostic->{code}, 'FSMGEN_LANGUAGE_COMBINATIONAL_SELF_DEPENDENCY', 'semantic JSON keeps the stable diagnostic code');
    assert_comb_self_dependency_diagnostic($diagnostic->{message}, 'semantic JSON diagnostic');
};

done_testing();

sub assert_comb_self_dependency_diagnostic {
    my ($message, $label) = @_;

    like($message, qr/Source file:\s+'.*assignment_comb_self_dependency\.fsm'/s, "$label keeps source file context");
    like($message, qr/Illegal combinational self-dependency/s, "$label explains the rejected assignment family");
    like($message, qr/RHS depends on LHS through combinational chain \(A -> A\)/s, "$label shows the dependency path");
    like($message, qr/use '<-' or rewrite expression/s, "$label gives a direct remediation");
    unlike($message, qr/\bcalled at\b/s, "$label does not expose Perl call-stack frames");
    unlike($message, qr/Parser\.pm/s, "$label does not expose parser implementation filenames");
    unlike($message, qr/validate_no_combinational_self_dependency/s, "$label does not expose parser routine names");
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
