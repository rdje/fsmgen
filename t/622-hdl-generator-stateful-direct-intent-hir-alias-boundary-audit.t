#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh direct intent_hir containers per generation' => sub {
    my $fsm_path = write_direct_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $first->{intent_hir}{module_name},
        'stateful_direct_intent_hir_alias_top',
        'first direct generation returns the expected intent_hir module name',
    );

    $first->{intent_hir}{module_name} = 'mutated_first_intent_hir';
    $first->{intent_hir}{signal_analysis}{outputs}[0]{name} = 'mutated_first_output';
    push @{$first->{intent_hir}{signal_names}}, 'mutated_first_signal';

    my $second = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $second->{intent_hir}{module_name},
        'stateful_direct_intent_hir_alias_top',
        'later generation on the same facade does not inherit caller mutation of direct intent_hir module name',
    );
    is(
        $second->{intent_hir}{signal_analysis}{outputs}[0]{name},
        'OUT',
        'later generation on the same facade does not inherit caller mutation of direct intent_hir signal analysis',
    );
    is_deeply(
        $second->{intent_hir}{signal_names},
        [qw(OUT)],
        'later generation on the same facade does not inherit caller mutation of direct intent_hir signal names',
    );
};

done_testing();

sub write_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'stateful_direct_intent_hir_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:stateful_direct_intent_hir_alias_top
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
