#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'malformed structured ?fsm roots fail through an explicit body boundary' => sub {
    my $empty_error = parse_failure(<<'FSM');
(?fsm:empty_root)
FSM
    like($empty_error, qr/Malformed top-level FSM body for source '\?fsm:empty_root'/, 'empty structured root gets a targeted body diagnostic');
    unlike($empty_error, qr/Not an ARRAY reference/, 'empty structured root no longer leaks raw Perl container errors');

    my $scalar_error = parse_failure(<<'FSM');
(?fsm:scalar_root BROKEN)
FSM
    like($scalar_error, qr/Malformed top-level FSM body item 'BROKEN' in source 'scalar_root'/, 'scalar top-level item gets a targeted body-item diagnostic');
};

subtest 'pipeline and CLI do not emit HDL for malformed structured ?fsm roots' => sub {
    my $fsm_path = write_fsm('scalar_root_cli.fsm', <<'FSM');
(?fsm:scalar_root BROKEN)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects malformed structured ?fsm root');
    like($pipeline_error, qr/Malformed top-level FSM body item 'BROKEN' in source 'scalar_root'/, 'pipeline surfaces the explicit body-item boundary');

    my $out_path = File::Spec->catfile($tempdir, 'scalar_root_cli.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects malformed structured ?fsm root');
    ok(!-e $out_path, 'CLI does not emit output for malformed structured ?fsm root');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Malformed top-level FSM body item 'BROKEN' in source 'scalar_root'/, 'CLI surfaces the explicit body-item boundary');
};

done_testing();

sub parse_failure {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_failure_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);

    my $error = eval {
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $error = $@ if !$error;
    ok($error, 'parse fails for generated fixture');
    return $error;
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
