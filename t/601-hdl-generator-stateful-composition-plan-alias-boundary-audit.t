#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh composition_plan objects per generation' => sub {
    my $composition_path = write_composition_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $first->{composition_plan}->top_name,
        'stateful_composition_plan_alias_top',
        'first generation returns the expected composition plan top name',
    );

    $first->{composition_plan}->{top_name} = 'mutated_first_plan_top_name';
    push @{$first->{composition_plan}->{ports}}, {
        name => 'mutated_first_plan_port',
    };

    my $second = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $second->{composition_plan}->top_name,
        'stateful_composition_plan_alias_top',
        'later generation on the same facade does not inherit caller mutation of composition plan top name',
    );
    is(
        scalar(@{$second->{composition_plan}->ports}),
        1,
        'later generation on the same facade does not inherit caller mutation of composition plan ports',
    );
};

done_testing();

sub write_composition_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'stateful_composition_plan_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:stateful_composition_plan_alias_top
  (+import shared_local)
  (?ports:public_io
    OUT>8
  )
  (?rtl:uart_tx)
  (?wiring:wiring
    /=shared_local.RESET_BYTE/OUT/
    /=shared_local.RESET_BYTE/uart_tx.data_in/
  )
)

(?pkg:shared_local
  (+constants
    (RESET_BYTE 8'hA5)
  )
)

(?rtlif:uart_tx
  data_in<8:data
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
