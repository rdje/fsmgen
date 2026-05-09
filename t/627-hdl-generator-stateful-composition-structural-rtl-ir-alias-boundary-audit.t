#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh composition structural_rtl_ir containers per generation' => sub {
    my $composition_path = write_composition_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $first->{structural_rtl_ir}{module_name},
        'stateful_composition_structural_rtl_ir_alias_top',
        'first composition generation returns the expected structural_rtl_ir module name',
    );

    $first->{structural_rtl_ir}{module_name} = 'mutated_first_composition_structural_rtl_ir';
    $first->{structural_rtl_ir}{ports}[0]{name} = 'mutated_first_port';
    $first->{structural_rtl_ir}{instances}[0]{instance_name} = 'mutated_first_instance';
    $first->{structural_rtl_ir}{resolved_links}[0]{source} = 'mutated_first_source';

    my $second = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $second->{structural_rtl_ir}{module_name},
        'stateful_composition_structural_rtl_ir_alias_top',
        'later generation on the same facade does not inherit caller mutation of composition structural_rtl_ir module name',
    );
    is(
        $second->{structural_rtl_ir}{ports}[0]{name},
        'clk',
        'later generation on the same facade does not inherit caller mutation of composition structural ports',
    );
    is(
        $second->{structural_rtl_ir}{instances}[0]{instance_name},
        'producer',
        'later generation on the same facade does not inherit caller mutation of composition structural instances',
    );
    is(
        $second->{structural_rtl_ir}{resolved_links}[0]{source},
        'clk',
        'later generation on the same facade does not inherit caller mutation of composition structural resolved links',
    );
};

done_testing();

sub write_composition_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'stateful_composition_structural_rtl_ir_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:stateful_composition_structural_rtl_ir_alias_top
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
