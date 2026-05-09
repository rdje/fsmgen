#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh module_info containers per generation' => sub {
    my $fsm_path = write_direct_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $first->{module_info}{module_name},
        'stateful_module_info_alias_top',
        'first generation returns the expected module_info summary',
    );

    $first->{module_info}{module_name} = 'mutated_first_module_info';
    $first->{module_info}{signal_analysis}{outputs}[0]{name} = 'mutated_first_output';
    push @{$first->{module_info}{signal_names}}, 'mutated_first_signal';

    my $second = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $second->{module_info}{module_name},
        'stateful_module_info_alias_top',
        'later generation on the same facade does not inherit caller mutation of module_name',
    );
    is(
        $second->{module_info}{signal_analysis}{outputs}[0]{name},
        'OUT',
        'later generation on the same facade does not inherit caller mutation of nested signal_analysis',
    );
    is_deeply(
        $second->{module_info}{signal_names},
        ['OUT'],
        'later generation on the same facade does not inherit caller mutation of signal_names',
    );
};

done_testing();

sub write_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'stateful_module_info_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:stateful_module_info_alias_top
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
