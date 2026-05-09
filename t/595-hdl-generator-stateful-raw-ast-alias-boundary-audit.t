#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh raw_ast snapshots per generation' => sub {
    my $fsm_path = write_direct_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $first->{raw_ast}[0][0],
        '?fsm:stateful_raw_ast_alias_top',
        'first generation returns the expected raw_ast root',
    );

    $first->{raw_ast}[0][0] = '?fsm:mutated_first_result';
    push @{$first->{raw_ast}}, ['?pkg:mutated_extra_root'];

    my $second = $pipeline->generate_hdl_from_file($fsm_path);
    is(
        $second->{raw_ast}[0][0],
        '?fsm:stateful_raw_ast_alias_top',
        'later generation on the same facade does not inherit caller mutation of raw_ast root',
    );
    is(
        scalar(@{$second->{raw_ast}}),
        1,
        'later generation on the same facade does not inherit caller-appended raw_ast roots',
    );
};

done_testing();

sub write_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'stateful_raw_ast_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:stateful_raw_ast_alias_top
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 1)
  )
  (idle
    (= (OUT 1))
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
