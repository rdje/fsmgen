#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh composition lowered_rtl_ir containers per generation' => sub {
    my $composition_path = write_composition_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $first->{lowered_rtl_ir}{module_name},
        'stateful_composition_lowered_rtl_ir_alias_top',
        'first composition generation returns the expected lowered_rtl_ir module name',
    );

    $first->{lowered_rtl_ir}{module_name} = 'mutated_first_composition_lowered_rtl_ir';
    $first->{lowered_rtl_ir}{instance_names}[0] = 'mutated_first_instance';
    push @{$first->{lowered_rtl_ir}{internal_net_names}}, 'mutated_first_net';

    my $second = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $second->{lowered_rtl_ir}{module_name},
        'stateful_composition_lowered_rtl_ir_alias_top',
        'later generation on the same facade does not inherit caller mutation of composition lowered_rtl_ir module name',
    );
    is_deeply(
        $second->{lowered_rtl_ir}{instance_names},
        [qw(producer)],
        'later generation on the same facade does not inherit caller mutation of composition lowered_rtl_ir instance names',
    );
    is_deeply(
        $second->{lowered_rtl_ir}{internal_net_names},
        [],
        'later generation on the same facade does not inherit caller mutation of composition lowered net names',
    );
};

done_testing();

sub write_composition_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'stateful_composition_lowered_rtl_ir_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:stateful_composition_lowered_rtl_ir_alias_top
  (?ports:public_io
    clk
    rstn
    select
    output_data>8
  )
  (?fsmc:producer producer_src)
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (select 1)
    (output_data 8)
  )
  (IDLE
    (<select==1'b0
      (<= (output_data> 8'1))
    )
  )
)
FSM
    );
    return $composition_path;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
