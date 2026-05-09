#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh direct lowered_rtl_ir containers per generation' => sub {
    my $fsm_path = write_direct_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $first->{lowered_rtl_ir}{module_name},
        'stateful_direct_lowered_rtl_ir_alias_top',
        'first direct generation returns the expected lowered_rtl_ir module name',
    );

    $first->{lowered_rtl_ir}{module_name} = 'mutated_first_lowered_rtl_ir';
    $first->{lowered_rtl_ir}{output_drive_families}[0]{signal_name} = 'mutated_first_output';
    push @{$first->{lowered_rtl_ir}{internal_net_names}}, 'mutated_first_net';

    my $second = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $second->{lowered_rtl_ir}{module_name},
        'stateful_direct_lowered_rtl_ir_alias_top',
        'later generation on the same facade does not inherit caller mutation of direct lowered_rtl_ir module name',
    );
    is(
        $second->{lowered_rtl_ir}{output_drive_families}[0]{signal_name},
        'OUT',
        'later generation on the same facade does not inherit caller mutation of direct lowered_rtl_ir output drives',
    );
    ok(
        !exists $second->{lowered_rtl_ir}{internal_net_names},
        'later generation on the same facade does not inherit caller-created direct lowered_rtl_ir net names',
    );
};

done_testing();

sub write_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'stateful_direct_lowered_rtl_ir_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:stateful_direct_lowered_rtl_ir_alias_top
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 1)
  )
  (idle
    (<= (OUT> 1))
  )
)
FSM
    );
    return $fsm_path;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
