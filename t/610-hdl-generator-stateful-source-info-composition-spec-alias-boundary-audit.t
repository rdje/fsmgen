#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'stateful facade reuse returns fresh source_info composition_spec objects per generation' => sub {
    my $composition_path = write_composition_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $first = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $first->{source_info}{composition_spec}->top->name,
        'stateful_source_info_composition_spec_alias_top',
        'first generation returns the expected source_info composition spec top name',
    );

    $first->{source_info}{composition_spec}{top}{name} = 'mutated_first_source_info_top';
    push @{$first->{source_info}{composition_spec}{top}{package_imports}}, 'mutated_first_import';

    my $second = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $second->{source_info}{composition_spec}->top->name,
        'stateful_source_info_composition_spec_alias_top',
        'later generation on the same facade does not inherit caller mutation of source_info composition top name',
    );
    is_deeply(
        $second->{source_info}{composition_spec}->top->package_imports,
        [qw(shared_local)],
        'later generation on the same facade does not inherit caller mutation of source_info composition package imports',
    );
};

done_testing();

sub write_composition_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'stateful_source_info_composition_spec_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:stateful_source_info_composition_spec_alias_top
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
