#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh direct structural_rtl_ir containers per generation' => sub {
    my $fsm_path = write_direct_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $first->{structural_rtl_ir}{module_name},
        'stateful_direct_structural_rtl_ir_alias_top',
        'first direct generation returns the expected structural_rtl_ir module name',
    );

    $first->{structural_rtl_ir}{module_name} = 'mutated_first_structural_rtl_ir';
    $first->{structural_rtl_ir}{ports}[0]{name} = 'mutated_first_output';
    push @{$first->{structural_rtl_ir}{nets}}, { name => 'mutated_first_net' };

    my $second = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $second->{structural_rtl_ir}{module_name},
        'stateful_direct_structural_rtl_ir_alias_top',
        'later generation on the same facade does not inherit caller mutation of direct structural_rtl_ir module name',
    );
    is(
        $second->{structural_rtl_ir}{ports}[0]{name},
        'OUT',
        'later generation on the same facade does not inherit caller mutation of direct structural_rtl_ir ports',
    );
    is_deeply(
        $second->{structural_rtl_ir}{nets},
        [
            {
                name => 'OUT_q',
                source => undef,
                targets => [],
                width => 1,
                signed => 0,
            },
        ],
        'later generation on the same facade does not inherit caller mutation of direct structural_rtl_ir declaration nets',
    );
};

done_testing();

sub write_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'stateful_direct_structural_rtl_ir_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:stateful_direct_structural_rtl_ir_alias_top
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
