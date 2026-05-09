#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh fsm_module objects per direct generation' => sub {
    my $fsm_path = write_direct_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $first->{fsm_module}->name,
        'stateful_fsm_module_alias_top',
        'first generation returns the expected fsm_module name',
    );

    $first->{fsm_module}{name} = 'mutated_first_module';
    $first->{fsm_module}->signals->{OUT}{name} = 'mutated_first_output';
    push @{$first->{fsm_module}->states}, $first->{fsm_module}->states->[0];

    my $second = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $second->{fsm_module}->name,
        'stateful_fsm_module_alias_top',
        'later generation on the same facade does not inherit caller mutation of module name',
    );
    is(
        $second->{fsm_module}->signals->{OUT}->name,
        'OUT',
        'later generation on the same facade does not inherit caller mutation of nested signal object',
    );
    is(
        scalar(@{$second->{fsm_module}->states}),
        1,
        'later generation on the same facade does not inherit caller mutation of states array',
    );
};

done_testing();

sub write_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'stateful_fsm_module_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:stateful_fsm_module_alias_top
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
