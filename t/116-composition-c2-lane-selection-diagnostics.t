#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);
my $composition_path = File::Spec->catfile($tempdir, 'single_generated_explicit_link_top.fsm');
my $output_path = File::Spec->catfile($tempdir, 'single_generated_explicit_link_top.sv');

write_file(
    $composition_path,
    <<'FSM'
(?top:single_generated_explicit_link_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?toplink:wiring
    /producer.output_data/result_data/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'3)
  )
  (+size
    (output_data 8)
  )
)
FSM
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

my $exception = eval {
    $pipeline->generate_hdl_from_file($composition_path);
    undef;
};
$exception = $@;

like(
    $exception,
    qr/recognized and parsed into typed composition IR, .*C2 lane selection is blocked because the current active C2 lane requires at least two generated child instances such as '\?fsmc' or '\?dtc'/s,
    'single generated child plus explicit toplink now says C2 lane selection is blocked',
);

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
);

ok(!$success, 'CLI rejects single generated child explicit-link tops that do not satisfy C2');
ok(!-e $output_path, 'CLI does not emit output for blocked C2 lane selection');

my $combined_output = join(
    '',
    @{ $stdout_buf || [] },
    @{ $stderr_buf || [] },
    ($error_message || ''),
);

like(
    $combined_output,
    qr/C2 lane selection is blocked because the current active C2 lane requires at least two generated child instances/s,
    'CLI surfaces the blocked C2 lane-selection diagnostic',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
