#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Scalar::Util qw(refaddr);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::GenerationOrchestrator;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

subtest 'composition generation raw_ast result branch is a caller-owned snapshot' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_raw_ast_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_raw_ast_alias_top
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

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $composition_path,
        debug_level => 0,
    );
    my $source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($raw_ast);

    my $result = FSM::Composition::GenerationOrchestrator->generate_from_source(
        pipeline => new_pipeline(),
        raw_ast => $raw_ast,
        source_info => $source_info,
        fsm_file => $composition_path,
    );

    isnt(
        refaddr($result->{raw_ast}),
        refaddr($raw_ast),
        'returned raw_ast does not reuse the caller/parser AST array',
    );

    $result->{raw_ast}[0][0] = '?top:mutated_by_result';
    is(
        $raw_ast->[0][0],
        '?top:composition_raw_ast_alias_top',
        'mutating returned raw_ast does not contaminate the caller/parser AST',
    );

    $raw_ast->[0][0] = '?top:mutated_by_caller';
    is(
        $result->{raw_ast}[0][0],
        '?top:mutated_by_result',
        'mutating the caller/parser AST after generation does not contaminate returned raw_ast',
    );
};

done_testing();

sub new_pipeline {
    return FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
