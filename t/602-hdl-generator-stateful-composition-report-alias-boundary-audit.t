#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh composition_report containers per generation' => sub {
    my $composition_path = write_composition_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $first->{composition_report}{port_origin_counts}{declared_explicit_port},
        4,
        'first generation returns the expected composition report count',
    );

    $first->{composition_report}{port_origin_counts}{declared_explicit_port} = 99;
    $first->{composition_report}{resolved_links}[0]{source_context}{endpoint} = 'mutated.first.link';

    my $second = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $second->{composition_report}{port_origin_counts}{declared_explicit_port},
        4,
        'later generation on the same facade does not inherit caller mutation of report counts',
    );
    is(
        $second->{composition_report}{resolved_links}[0]{source_context}{endpoint},
        'clk',
        'later generation on the same facade does not inherit caller mutation of nested link context',
    );
};

done_testing();

sub write_composition_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'stateful_composition_report_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:stateful_composition_report_alias_top
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
