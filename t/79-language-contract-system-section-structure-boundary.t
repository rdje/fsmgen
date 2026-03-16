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

subtest 'malformed +system entry structures are rejected explicitly' => sub {
    my $scalar_error = parse_failure(<<'FSM');
(?fsm:bad_system_scalar_entry
  (+system
    BROKEN
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (A = 1)
  )
)
FSM

    like($scalar_error, qr/Unsupported '\+system' entry structure/, 'scalar +system entry gets a targeted structure diagnostic');

    my $arity_error = parse_failure(<<'FSM');
(?fsm:bad_system_arity_entry
  (+system
    (clock clk extra)
    (sreset rstn)
  )
  (-dt
    (A = 1)
  )
)
FSM

    like($arity_error, qr/Unsupported '\+system' entry structure/, 'wrong-arity +system entry gets a targeted structure diagnostic');
};

subtest 'pipeline and CLI do not emit HDL for malformed +system entry structures' => sub {
    my $fsm_path = write_fsm('bad_system_structure_cli.fsm', <<'FSM');
(?fsm:bad_system_structure_cli
  (+system
    BROKEN
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (A = 1)
  )
)
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
    ok($pipeline_error, 'pipeline rejects malformed +system entry structure');
    like($pipeline_error, qr/Unsupported '\+system' entry structure/, 'pipeline surfaces the explicit +system structure boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bad_system_structure_cli.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, 'CLI rejects malformed +system entry structure');
    ok(!-e $out_path, 'CLI does not emit output for malformed +system entry structure');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );
    like($combined_output, qr/Unsupported '\+system' entry structure/, 'CLI surfaces the explicit +system structure boundary');
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
    ok($error, 'parse failed as expected');
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
