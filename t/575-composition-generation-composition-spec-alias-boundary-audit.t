#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'composition generation separates top-level composition_spec from source_info payloads' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_spec_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_spec_alias_top
  (?ports:public_io
    clk
    rstn
    output_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-idle
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    my $result = generate_result($composition_path);
    is(
        ref($result->{composition_spec}),
        'FSM::Composition::Spec',
        'top-level result carries a composition spec',
    );
    is(
        ref($result->{source_info}{composition_spec}),
        'FSM::Composition::Spec',
        'source_info payload carries its own composition spec',
    );

    $result->{composition_spec}{top}{name} = 'mutated_top_level_spec';
    is(
        $result->{source_info}{composition_spec}{top}{name},
        'composition_spec_alias_top',
        'mutating top-level composition_spec does not contaminate source_info composition_spec',
    );

    my $second_result = generate_result($composition_path);
    $second_result->{source_info}{composition_spec}{top}{name} = 'mutated_source_info_spec';
    is(
        $second_result->{composition_spec}{top}{name},
        'composition_spec_alias_top',
        'mutating source_info composition_spec does not contaminate top-level composition_spec',
    );
};

done_testing();

sub generate_result {
    my ($path) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    return $pipeline->generate_hdl_from_file($path);
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
