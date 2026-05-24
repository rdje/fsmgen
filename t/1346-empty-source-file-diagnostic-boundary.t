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

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);
my $empty_path = File::Spec->catfile($tempdir, 'empty_source.fsm');
write_file($empty_path, q{});

subtest 'pipeline empty source failures are source-local and stack-free' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($empty_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    ok($pipeline_error, 'pipeline rejects an empty source file');
    assert_empty_source_diagnostic($pipeline_error, 'pipeline');
};

subtest 'CLI empty source failures are source-local and stack-free' => sub {
    my $out_path = File::Spec->catfile($tempdir, 'empty_source.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $out_path, $empty_path],
    );

    ok(!$success, 'CLI rejects an empty source file');
    ok(!-e $out_path, 'CLI does not emit HDL for an empty source file');

    my $combined_output = combined_output($error_message, $stdout_buf, $stderr_buf);
    assert_empty_source_diagnostic($combined_output, 'CLI');
};

subtest 'check JSON empty source failures keep the clean diagnostic' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--check-json', $empty_path],
    );

    ok(!$success, 'check JSON rejects an empty source file');
    is(join('', @{$stderr_buf || []}), '', 'check JSON failure stays on stdout only');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    ok(!$decoded->{success}, 'check JSON report marks failure');
    is($decoded->{source}{resolved_path}, File::Spec->rel2abs($empty_path), 'check JSON records the source path');
    is(scalar(@{$decoded->{diagnostics}}), 1, 'check JSON carries one diagnostic');
    assert_empty_source_diagnostic($decoded->{diagnostics}[0]{message}, 'check JSON diagnostic');
};

subtest 'normalized semantic JSON empty source failures keep the clean diagnostic' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-semantic-json', $empty_path],
    );

    ok(!$success, 'semantic JSON rejects an empty source file');
    is(join('', @{$stderr_buf || []}), '', 'semantic JSON failure stays on stdout only');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    ok(!$decoded->{success}, 'semantic JSON report marks failure');
    is($decoded->{source}{resolved_path}, File::Spec->rel2abs($empty_path), 'semantic JSON records the source path');
    is(scalar(@{$decoded->{diagnostics}}), 1, 'semantic JSON carries one diagnostic');
    assert_empty_source_diagnostic($decoded->{diagnostics}[0]{message}, 'semantic JSON diagnostic');
};

done_testing();

sub assert_empty_source_diagnostic {
    my ($message, $label) = @_;

    like($message, qr/Source file:\s+'\Q$empty_path\E'/s, "$label keeps the source file context");
    like($message, qr/Error: Source file '\Q$empty_path\E' is empty\./s, "$label explains that the source is empty");
    like($message, qr/Provide a non-empty FSMGen source file\./s, "$label gives a direct remediation");
    unlike($message, qr/Lispish::multi/s, "$label does not expose the old Lispish fallback");
    unlike($message, qr/does not exit/s, "$label does not expose the old typo");
    unlike($message, qr/\bcalled at\b/s, "$label does not expose Perl call-stack frames");
    unlike($message, qr/\bat \Q$0\E line \d+/s, "$label does not expose this test script boundary");
    unlike($message, qr/\bat \Q.\/bin\/fsmgen\E line \d+/s, "$label does not expose the CLI script boundary");
    unlike($message, qr/SourceFrontend\.pm line \d+/s, "$label does not expose the frontend implementation location");
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
